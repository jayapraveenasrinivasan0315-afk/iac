variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  description = "Region for Cloud Run service"
}

variable "service_account_id" {
  type        = string
  description = "Service account ID for Cloud Run"
}

variable "cloud_run_service_name" {
  type        = string
  description = "Name of the Cloud Run service"
}

variable "vpc_connector_id" {
  type        = string
  description = "VPC Connector ID for Cloud Run"
}

variable "container_image" {
  type        = string
  description = "Container image URI for Cloud Run service"
}

variable "container_port" {
  type        = number
  default     = 8080
  description = "Port exposed by the container"
}

variable "min_instances" {
  type        = number
  default     = 1
  description = "Minimum number of Cloud Run instances"
}

variable "max_instances" {
  type        = number
  default     = 100
  description = "Maximum number of Cloud Run instances"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
}

variable "db_url_secret_id" {
  description = "Secret Manager ID for DB URL"
  type        = string
}
