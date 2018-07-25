terraform {
  backend "gcs" {
    bucket = "infra-208603-prod"
    prefix = "terraform/state"
  }
}
