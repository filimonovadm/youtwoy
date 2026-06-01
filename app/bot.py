import logging

from aiogram import Bot, Dispatcher, Router
from aiogram.client.default import DefaultBotProperties
from aiogram.enums import ParseMode
from aiogram.filters import CommandStart
from aiogram.types import FSInputFile, Message

from app.config import ALLOWED_USER_IDS, BOT_TOKEN
from app.downloader import (
    DownloadError,
    TooLargeError,
    download,
    extract_youtube_url,
)

logger = logging.getLogger("youtwoy.bot")

bot = Bot(token=BOT_TOKEN, default=DefaultBotProperties(parse_mode=ParseMode.HTML))
dp = Dispatcher()
router = Router()
dp.include_router(router)


def _is_allowed(user_id: int) -> bool:
    return not ALLOWED_USER_IDS or user_id in ALLOWED_USER_IDS


@router.message(CommandStart())
async def cmd_start(message: Message) -> None:
    if not _is_allowed(message.from_user.id):
        return
    await message.answer(
        "Привет! Пришли ссылку на видео с YouTube — скачаю и пришлю файлом.\n"
        "Если видео больше 50 МБ, оно может прийти в пониженном качестве "
        "или не пройти лимит Telegram."
    )


@router.message()
async def handle_link(message: Message) -> None:
    if not _is_allowed(message.from_user.id):
        return

    url = extract_youtube_url(message.text or "")
    if not url:
        await message.answer("Пришли ссылку на YouTube-видео.")
        return

    status = await message.answer("Скачиваю видео…")
    tmp = None
    try:
        result, tmp = await download(url)
        await status.edit_text(f"Отправляю «{result.title}»…")
        await message.answer_video(
            video=FSInputFile(result.path),
            caption=result.title,
            width=result.width or None,
            height=result.height or None,
            duration=result.duration or None,
            thumbnail=FSInputFile(result.thumbnail) if result.thumbnail else None,
            supports_streaming=True,
        )
        await status.delete()
    except TooLargeError as exc:
        logger.warning("too large: %s", exc)
        await status.edit_text(
            "Видео слишком большое для отправки через Telegram (лимит 50 МБ)."
        )
    except DownloadError as exc:
        logger.error("download failed: %s", exc)
        await status.edit_text("Не удалось скачать видео. Проверь ссылку.")
    except Exception:
        logger.exception("unexpected error")
        await status.edit_text("Произошла ошибка при обработке видео.")
    finally:
        if tmp is not None:
            tmp.cleanup()
