resource "google_storage_bucket" "frontend_bucket" {
  project       = var.project_id
  name          = var.bucket_name
  location      = var.region
  force_destroy = true

  uniform_bucket_level_access = true

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }

  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 90
    }
  }

  versioning {
    enabled = var.enable_versioning
  }
}

# Make bucket publicly readable for frontend files
resource "google_storage_bucket_iam_binding" "public_read" {
  bucket = google_storage_bucket.frontend_bucket.name
  role   = "roles/storage.objectViewer"
  members = [
    "allUsers"
  ]
}

# Upload frontend files to GCS
resource "google_storage_bucket_object" "frontend_files" {
  for_each = fileset("${path.module}/../../github_tasks/frontend", "**")
  
  bucket = google_storage_bucket.frontend_bucket.name
  name   = each.value
  source = "${path.module}/../../github_tasks/frontend/${each.value}"
}