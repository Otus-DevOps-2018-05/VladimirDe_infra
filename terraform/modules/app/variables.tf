variable zone {
  description = "Zone"
  default     = "europe-west1-b"
}

variable public_key_path {
  description = "Path to the public key used for ssh access"
}

variable private_key_path {
  description = "Path to the private key used for ssh access"
}

variable "app_disk_image" {
  description = "Disk image for reddit app"
  default     = "reddit-app-base"
}

variable "app_port" {
  description = "Reddit app port"
  default     = "9292"
}

variable "db_address" {
  description = "Mongodb address"
  default     = "localhost"
}

variable "app_provision_enabled" {
  description = "Enable/disable reddit app provision switch"
  default     = true
}
