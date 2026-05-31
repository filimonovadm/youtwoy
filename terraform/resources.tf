# ============================================================
# Service Account
# ============================================================
resource "yandex_iam_service_account" "youtwoy_sa" {
  name        = "youtwoy-sa"
  description = "YouTwoY Telegram bot service account"
  folder_id   = var.folder_id
}

resource "yandex_resourcemanager_folder_iam_member" "sa_storage_editor" {
  folder_id = var.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.youtwoy_sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "sa_registry_puller" {
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.youtwoy_sa.id}"
}

# CI/CD: push images to the registry and deploy new container revisions.
resource "yandex_resourcemanager_folder_iam_member" "sa_registry_pusher" {
  folder_id = var.folder_id
  role      = "container-registry.images.pusher"
  member    = "serviceAccount:${yandex_iam_service_account.youtwoy_sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "sa_containers_editor" {
  folder_id = var.folder_id
  role      = "serverless.containers.editor"
  member    = "serviceAccount:${yandex_iam_service_account.youtwoy_sa.id}"
}

# serverless.containers.editor cannot bind Lockbox secrets to a revision;
# functions.editor carries that permission (Yandex Cloud IAM quirk).
resource "yandex_resourcemanager_folder_iam_member" "sa_functions_editor" {
  folder_id = var.folder_id
  role      = "functions.editor"
  member    = "serviceAccount:${yandex_iam_service_account.youtwoy_sa.id}"
}

# Required to deploy with --service-account-id (use the SA as a resource),
# even when the deployer and runtime SA are the same account.
resource "yandex_iam_service_account_iam_member" "sa_self_user" {
  service_account_id = yandex_iam_service_account.youtwoy_sa.id
  role               = "iam.serviceAccounts.user"
  member             = "serviceAccount:${yandex_iam_service_account.youtwoy_sa.id}"
}

# ============================================================
# Lockbox access for the bot SA (token + webhook secret)
# ============================================================
resource "yandex_lockbox_secret_iam_member" "sa_payload_viewer" {
  secret_id = var.lockbox_secret_id
  role      = "lockbox.payloadViewer"
  member    = "serviceAccount:${yandex_iam_service_account.youtwoy_sa.id}"
}

# ============================================================
# Serverless Container (bot webhook receiver)
# ============================================================
resource "yandex_serverless_container" "bot" {
  name               = "youtwoy-bot"
  folder_id          = var.folder_id
  memory             = 512
  cores              = 1
  execution_timeout  = "120s"
  concurrency        = 4
  service_account_id = yandex_iam_service_account.youtwoy_sa.id

  image {
    url = "cr.yandex/${var.registry_id}/youtwoy:${var.image_tag}"
  }

  secrets {
    id                   = var.lockbox_secret_id
    version_id           = var.lockbox_version_id
    key                  = "token"
    environment_variable = "BOT_TOKEN"
  }

  secrets {
    id                   = var.lockbox_secret_id
    version_id           = var.lockbox_version_id
    key                  = "webhook-secret"
    environment_variable = "WEBHOOK_SECRET"
  }
}

# Public HTTPS endpoint: Telegram posts webhook updates directly.
# Security is enforced by the X-Telegram-Bot-Api-Secret-Token header.
resource "yandex_serverless_container_iam_binding" "public_invoke" {
  container_id = yandex_serverless_container.bot.id
  role         = "serverless-containers.containerInvoker"
  members      = ["system:allUsers"]
}
