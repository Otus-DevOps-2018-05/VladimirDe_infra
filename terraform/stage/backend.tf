terraform {
  backend "gcs" {
    bucket = "infra-208603-stage"
    prefix = "terraform/state"
  }
}
