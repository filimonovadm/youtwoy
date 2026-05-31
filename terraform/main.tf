terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.120"
    }
  }
  required_version = ">= 1.4"
}

provider "yandex" {
  service_account_key_file = var.sa_key_file
  folder_id                = var.folder_id
  zone                     = "ru-central1-a"
}
