#!/usr/bin/env bash
# Регистрирует Telegram webhook.
#
# Если задан WEBHOOK_URL — используется он (прокси-режим, адрес деталь приватной инфры).
# Иначе — прямой URL контейнера.
#
# Запускать после деплоя новой ревизии ИЛИ после ротации webhook-secret в Lockbox:
# при смене webhook-secret контейнер начнёт отвечать 401 на апдейты Telegram,
# пока webhook не перерегистрирован этим скриптом с новым значением secret.
#
# Пример (прямой):
#   bash scripts/set-webhook.sh
#
# Пример (через прокси):
#   WEBHOOK_URL=https://<proxy-ip>:8443/<container-id>/webhook \
#   WEBHOOK_CERT=scripts/webhook.crt \
#   bash scripts/set-webhook.sh
set -euo pipefail

SECRET_ID="${SECRET_ID:-e6qknf8t938ldnctsl3j}"
CONTAINER_ID="bbaph33gp6gjmcq62tqi"

BOT_TOKEN=$(yc lockbox payload get --id "$SECRET_ID" --format json | jq -r '.entries[]|select(.key=="token").text_value')
WEBHOOK_SECRET=$(yc lockbox payload get --id "$SECRET_ID" --format json | jq -r '.entries[]|select(.key=="webhook-secret").text_value')

# WEBHOOK_URL: передать явно для прокси-режима (адрес прокси не хранится в репо)
WEBHOOK_URL="${WEBHOOK_URL:-https://${CONTAINER_ID}.containers.yandexcloud.net/webhook}"

CURL_ARGS=(
  -sS -X POST "https://api.telegram.org/bot${BOT_TOKEN}/setWebhook"
  --data-urlencode "url=${WEBHOOK_URL}"
  --data-urlencode "secret_token=${WEBHOOK_SECRET}"
  --data-urlencode "drop_pending_updates=true"
  --data-urlencode 'allowed_updates=["message"]'
)

# Кастомный сертификат нужен только при self-signed TLS (прокси с IP-сертом)
if [[ -n "${WEBHOOK_CERT:-}" ]]; then
  CURL_ARGS+=(-F "certificate=@${WEBHOOK_CERT}")
fi

curl "${CURL_ARGS[@]}"
echo

curl -sS "https://api.telegram.org/bot${BOT_TOKEN}/getWebhookInfo" \
  | jq '.result | {url, has_custom_certificate, pending_update_count, last_error_message}'
