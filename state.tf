# state.tf
resource "google_storage_bucket" "tf_state" {
  name                        = "my-terraform-state-bucket-01"
  location                    = "ASIA-SOUTH1"
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  labels = merge(local.labels, {
    managed-by = "terraform"
  })

  lifecycle {
    prevent_destroy = true
  }
}