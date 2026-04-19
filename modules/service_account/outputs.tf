output "service_account_email" {
  description = "Service account email"
  value       = google_service_account.main.email
}

output "service_account_id" {
  description = "Service account ID"
  value       = google_service_account.main.id
}

output "service_account_name" {
  description = "Service account name"
  value       = google_service_account.main.name
}

output "service_account_unique_id" {
  description = "Service account unique ID"
  value       = google_service_account.main.unique_id
}
