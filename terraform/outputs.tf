output "bot_url" {
  value = "https://${yandex_serverless_container.bot.id}.containers.yandexcloud.net"
}

output "container_id" {
  value = yandex_serverless_container.bot.id
}

output "service_account_id" {
  value = yandex_iam_service_account.youtwoy_sa.id
}

output "registry_id" {
  value = var.registry_id
}

output "lockbox_secret_id" {
  value = var.lockbox_secret_id
}
