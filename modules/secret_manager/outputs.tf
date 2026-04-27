output "db_password_secret_id" {
  description = "Database password secret ID"
  value       = google_secret_manager_secret.db_password.id
}

output "db_url_secret_id" {
  description = "Database URL secret ID"
  value       = google_secret_manager_secret.db_url.id
}

output "jwt_secret_secret_id" {
  description = "JWT secret secret ID"
  value       = google_secret_manager_secret.jwt_secret.id
}

output "api_key_secret_id" {
  description = "API key secret ID"
  value       = google_secret_manager_secret.api_key.id
}

output "db_password_secret_version" {
  description = "Database password secret version"
  value       = google_secret_manager_secret_version.db_password.id
}

output "db_url_secret_version" {
  description = "Database URL secret version"
  value       = google_secret_manager_secret_version.db_url.id
}

output "jwt_secret_secret_version" {
  description = "JWT secret secret version"
  value       = google_secret_manager_secret_version.jwt_secret.id
}

output "api_key_secret_version" {
  description = "API key secret version"
  value       = google_secret_manager_secret_version.api_key.id
}
