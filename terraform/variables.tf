variable "folder_id" {
  description = "Yandex Cloud folder ID"
  type        = string
}

variable "sa_key_file" {
  description = "Path to service account key JSON file"
  type        = string
  default     = "../sa-key.json"
  sensitive   = true
}

variable "registry_id" {
  description = "Existing shared Container Registry ID"
  type        = string
}

variable "lockbox_secret_id" {
  description = "Existing Lockbox secret ID holding bot token and webhook secret"
  type        = string
}

variable "lockbox_version_id" {
  description = "Lockbox secret version ID pinned into the container revision"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}
