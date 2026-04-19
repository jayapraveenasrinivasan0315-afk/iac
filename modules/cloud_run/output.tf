output "service_id" {
  description = "Cloud Run service ID"
  value       = google_cloud_run_v2_service.backend.id
}

output "service_name" {
  description = "Cloud Run service name"
  value       = google_cloud_run_v2_service.backend.name
}

output "service_uri" {
  description = "Cloud Run service URI"
  value       = google_cloud_run_v2_service.backend.uri
}

output "service_account_email" {
  description = "Service account email for Cloud Run"
  value       = data.google_service_account.cloud_run_sa.email
}

output "service_account_id" {
  description = "Service account ID for Cloud Run"
  value       = data.google_service_account.cloud_run_sa.id
}
