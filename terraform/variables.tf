variable project {
  description = "Project ID"
}

variable region {
  description = "Region"
  default     = "europe-west1"
}

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

# variable public_key_path2 {
#   description = "Path to the public key2 used for ssh access"
# }

# variable private_key_path2 {
#  description = "Path to the private key2 used for ssh access"
# }

# variable public_key_path3 {
#   description = "Path to the public key3 used for ssh access"
# }

# variable private_key_path3 {
#  description = "Path to the private key3 used for ssh access"
#}

variable disk_image {
  description = "Disk image"
}

variable "app_backend_port" {
  description = "Reddit application backend port"
  default     = 9292
}

variable "count" {
  description = "Count of instance"
  default     = 1
}
