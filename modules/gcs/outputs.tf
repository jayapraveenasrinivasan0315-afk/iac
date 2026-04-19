output "bucket_name" {
  description = "GCS bucket name"
  value       = google_storage_bucket.frontend_bucket.name
}

output "bucket_url" {
  description = "GCS bucket URL"
  value       = google_storage_bucket.frontend_bucket.url
}

output "bucket_id" {
  description = "GCS bucket ID"
  value       = google_storage_bucket.frontend_bucket.id
}

output "website_url" {
  description = "Website URL for the frontend bucket"
  value       = "https://${google_storage_bucket.frontend_bucket.name}/index.html"
}

output "self_link" {
  description = "Self link of the bucket"
  value       = google_storage_bucket.frontend_bucket.self_link
}
