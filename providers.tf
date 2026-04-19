provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_storage_bucket" "tf_state" {
  name     = "my-terraform-state-bucket"
  location = "ASIA-SOUTH1"

  versioning {
    enabled = true
  }

  uniform_bucket_level_access = true
  labels = merge(local.labels, {
    managed-by = "terraform"
  })
}
