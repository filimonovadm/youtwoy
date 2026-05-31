import logging
import secrets
from contextlib import asynccontextmanager
from typing import Any

from aiogram.types import Update
from fastapi import FastAPI, HTTPException, Request, status
from fastapi.responses import JSONResponse

from app.bot import bot, dp
from app.config import BASE_WEBHOOK_URL, WEBHOOK_PATH, WEBHOOK_SECRET

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("youtwoy.main")


@asynccontextmanager
async def lifespan(app: FastAPI):
    if BASE_WEBHOOK_URL:
        await bot.set_webhook(
            url=f"{BASE_WEBHOOK_URL}{WEBHOOK_PATH}",
            secret_token=WEBHOOK_SECRET,
            drop_pending_updates=True,
            allowed_updates=["message"],
        )
        logger.info("webhook set to %s%s", BASE_WEBHOOK_URL, WEBHOOK_PATH)
    yield
    await bot.session.close()


app = FastAPI(lifespan=lifespan)


@app.get("/")
async def health() -> JSONResponse:
    return JSONResponse({"status": "ok"})


@app.post(WEBHOOK_PATH)
async def telegram_webhook(request: Request) -> JSONResponse:
    header_token = request.headers.get("X-Telegram-Bot-Api-Secret-Token", "")
    if not secrets.compare_digest(header_token, WEBHOOK_SECRET):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED)

    try:
        payload: Any = await request.json()
    except Exception as exc:
        raise HTTPException(status_code=400, detail="invalid_json") from exc

    try:
        update = Update.model_validate(payload, context={"bot": bot})
    except Exception as exc:
        raise HTTPException(status_code=400, detail="invalid_update") from exc

    # Webhook ДОЛЖЕН возвращать 200, иначе Telegram бесконечно ретраит апдейт.
    # Ошибки обработки логируем, но наружу отдаём ok.
    try:
        await dp.feed_update(bot, update)
    except Exception:
        logger.exception("update handling failed (update_id=%s)", update.update_id)
    return JSONResponse({"ok": True})
