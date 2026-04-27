output "sql_instance_name" {
  value = google_sql_database_instance.main.name
}

output "database_name" {
  value = google_sql_database.myapp.name
}

output "database_user" {
  value = google_sql_user.myapp.name
}

output "sql_instance_connection_name" {
  description = "SQL instance connection name for Cloud Run"
  value       = google_sql_database_instance.main.connection_name
}

output "generated_password" {
  description = "Generated database password"
  value       = random_password.db_password.result
  sensitive   = true
}

output "instance_private_ip" {
  description = "Cloud SQL instance private IP"
  value       = google_sql_database_instance.main.private_ip_address
}
