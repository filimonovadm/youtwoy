import os


def _required(name: str) -> str:
    value = os.environ.get(name)
    if not value:
        raise RuntimeError(f"Обязательная переменная окружения не задана: {name}")
    return value


# Инжектится из Yandex Lockbox (payload key: token) при деплое ревизии.
BOT_TOKEN: str = _required("BOT_TOKEN")

# Инжектится из Lockbox (payload key: webhook-secret); сверяется с заголовком
# X-Telegram-Bot-Api-Secret-Token на каждом входящем апдейте.
WEBHOOK_SECRET: str = _required("WEBHOOK_SECRET")

BASE_WEBHOOK_URL: str = os.environ.get("BASE_WEBHOOK_URL", "")

WEBHOOK_PATH: str = "/webhook"

MAX_FILE_SIZE_BYTES: int = 50 * 1024 * 1024

_allowed_raw = os.environ.get("ALLOWED_USER_IDS", "").strip()
ALLOWED_USER_IDS: set[int] = (
    {int(x) for x in _allowed_raw.split(",") if x.strip().isdigit()}
    if _allowed_raw
    else set()
)
