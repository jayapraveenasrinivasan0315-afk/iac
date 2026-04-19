variable "bucket_name" {
  type        = string
  description = "Frontend bucket name (must be globally unique in GCS)"
}

variable "region" {
  type        = string
  description = "Region for the bucket"
}

variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "enable_versioning" {
  type        = bool
  default     = false
  description = "Enable versioning for the bucket"
}