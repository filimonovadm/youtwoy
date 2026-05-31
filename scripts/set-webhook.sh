#!/usr/bin/env bash
# Регистрирует Telegram webhook на публичный URL Serverless Container.
# Запускать после деплоя новой ревизии ИЛИ после ротации webhook-secret в Lockbox:
# при смене webhook-secret контейнер начнёт отвечать 401 на апдейты Telegram,
# пока webhook не перерегистрирован этим скриптом с новым значением secret.
set -euo pipefail

SECRET_ID="${SECRET_ID:-e6qknf8t938ldnctsl3j}"
CONTAINER_URL="${CONTAINER_URL:-https://bbaph33gp6gjmcq62tqi.containers.yandexcloud.net}"

BOT_TOKEN=$(yc lockbox payload get --id "$SECRET_ID" --format json | jq -r '.entries[]|select(.key=="token").text_value')
WEBHOOK_SECRET=$(yc lockbox payload get --id "$SECRET_ID" --format json | jq -r '.entries[]|select(.key=="webhook-secret").text_value')

curl -sS -X POST "https://api.telegram.org/bot${BOT_TOKEN}/setWebhook" \
  --data-urlencode "url=${CONTAINER_URL}/webhook" \
  --data-urlencode "secret_token=${WEBHOOK_SECRET}" \
  --data-urlencode "drop_pending_updates=true" \
  --data-urlencode 'allowed_updates=["message"]'
echo

curl -sS "https://api.telegram.org/bot${BOT_TOKEN}/getWebhookInfo" \
  | jq '.result | {url, pending_update_count, last_error_message}'
