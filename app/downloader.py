import asyncio
import re
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path

import yt_dlp

from app.config import MAX_FILE_SIZE_BYTES

_YOUTUBE_RE = re.compile(
    r"(https?://)?(www\.)?(youtube\.com/(watch\?v=|shorts/|live/)|youtu\.be/)[\w\-]+",
    re.IGNORECASE,
)


def extract_youtube_url(text: str) -> str | None:
    match = _YOUTUBE_RE.search(text or "")
    return match.group(0) if match else None


class DownloadError(Exception):
    pass


class TooLargeError(DownloadError):
    pass


@dataclass
class DownloadResult:
    path: Path
    title: str
    size_bytes: int
    width: int
    height: int
    duration: int
    thumbnail: Path | None


# Лимит Bot API (50 МБ) минус запас на контейнер mp4 и погрешность мультиплексора.
_TARGET_BYTES = MAX_FILE_SIZE_BYTES - 2 * 1024 * 1024

# Принудительно H.264 (avc1): YouTube отдаёт "best mp4" как AV1/VP9, который
# Telegram-клиенты не декодируют → чёрный экран со звуком. avc1 играет везде.
_FORMAT = (
    f"bestvideo[vcodec^=avc1][height<=720][filesize<{_TARGET_BYTES}]+bestaudio[ext=m4a]"
    f"/best[vcodec^=avc1][ext=mp4][filesize<{_TARGET_BYTES}]"
    f"/best[ext=mp4][height<=480]"
    f"/best[height<=480]/best"
)


def _make_thumbnail(video: Path, duration: int) -> Path | None:
    thumb = video.with_name(video.stem + "_thumb.jpg")
    # Кадр из середины ролика: начало YouTube-видео часто чёрный фейд,
    # из-за которого Telegram показывает чёрное превью. -2 фильтр scale:
    # ширина 320, высота кратна 2 (требование JPEG-кодека).
    seek = max(duration // 2, 0)
    cmd = [
        "ffmpeg", "-y", "-loglevel", "error",
        "-ss", str(seek), "-i", str(video),
        "-frames:v", "1", "-vf", "scale=320:-2", "-q:v", "4",
        str(thumb),
    ]
    try:
        subprocess.run(cmd, check=True, capture_output=True, timeout=30)
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired, FileNotFoundError):
        return None
    if thumb.exists() and thumb.stat().st_size > 0:
        return thumb
    return None


def _blocking_download(url: str, out_dir: str) -> DownloadResult:
    opts = {
        "format": _FORMAT,
        "outtmpl": str(Path(out_dir) / "%(id)s.%(ext)s"),
        "merge_output_format": "mp4",
        "noplaylist": True,
        "quiet": True,
        "no_warnings": True,
        "max_filesize": MAX_FILE_SIZE_BYTES,
        "retries": 3,
        "socket_timeout": 20,
    }
    try:
        with yt_dlp.YoutubeDL(opts) as ydl:
            info = ydl.extract_info(url, download=True)
            filename = ydl.prepare_filename(info)
    except yt_dlp.utils.DownloadError as exc:
        raise DownloadError(str(exc)) from exc

    path = Path(filename)
    if not path.exists():
        mp4 = path.with_suffix(".mp4")
        if mp4.exists():
            path = mp4
        else:
            raise DownloadError("Файл не найден после скачивания")

    size = path.stat().st_size
    if size > MAX_FILE_SIZE_BYTES:
        raise TooLargeError(
            f"Видео {size // (1024 * 1024)} МБ превышает лимит Telegram 50 МБ"
        )

    duration = int(info.get("duration") or 0)

    return DownloadResult(
        path=path,
        title=str(info.get("title") or path.stem),
        size_bytes=size,
        width=int(info.get("width") or 0),
        height=int(info.get("height") or 0),
        duration=duration,
        thumbnail=_make_thumbnail(path, duration),
    )


async def download(url: str) -> tuple[DownloadResult, tempfile.TemporaryDirectory]:
    tmp = tempfile.TemporaryDirectory(prefix="youtwoy-")
    try:
        result = await asyncio.to_thread(_blocking_download, url, tmp.name)
    except BaseException:
        tmp.cleanup()
        raise
    return result, tmp
