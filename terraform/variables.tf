variable "folder_id" {
  description = "Yandex Cloud folder ID"
  type        = string
  default     = "b1g7scs6lgrf9ijk4dff"
}

variable "sa_key_file" {
  description = "Path to service account key JSON file"
  type        = string
  default     = "../sa-key.json"
  sensitive   = true
}

variable "registry_id" {
  description = "Existing shared Container Registry ID (heroleague-registry)"
  type        = string
  default     = "crpdhn2sdv42n950jo8l"
}

variable "lockbox_secret_id" {
  description = "Existing Lockbox secret ID holding bot token and webhook secret"
  type        = string
  default     = "e6qknf8t938ldnctsl3j"
}

variable "lockbox_version_id" {
  description = "Lockbox secret version ID pinned into the container revision"
  type        = string
  default     = "e6q6712n9i2c1p2vts7e"
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}
