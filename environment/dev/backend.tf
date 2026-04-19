terraform {
  backend "gcs" {
    bucket = "my-terraform-state-bucket"  # Replace with your actual state bucket name
    prefix = "terraform/state/dev"
  }
}