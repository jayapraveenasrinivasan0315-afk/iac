variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "database_user" {
  description = "Database username"
  type        = string
}

variable "database_name" {
  description = "Database name"
  type        = string
}

variable "service_account_email" {
  description = "Service account email for Cloud Run"
  type        = string
}

variable "sql_instance_name" {
  description = "Cloud SQL instance name"
  type        = string
}
