terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone = "ru-central1-d"
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  service_account_key_file = file("authorized_key.json")
}

