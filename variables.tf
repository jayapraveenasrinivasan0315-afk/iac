variable "project_id" {
  description = "The project ID to manage resources in"
  type        = string
}

variable "region" {
  description = "The region to deploy resources"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "team" {
  description = "Team name"
  type        = string
  default     = "platform"
}

variable "name" {
  description = "VPC network name"
  type        = string
}

variable "subnet_name" {
  description = "Subnet name"
  type        = string
}

variable "subnet_ip_cidr_range" {
  description = "Subnet IP CIDR range"
  type        = string
}

variable "connector_name" {
  description = "VPC Access Connector name"
  type        = string
}

variable "connector_ip_cidr_range" {
  description = "Connector IP CIDR range"
  type        = string
}

variable "connector_min_instances" {
  description = "Connector minimum instances"
  type        = number
}

variable "connector_max_instances" {
  description = "Connector maximum instances"
  type        = number
}

variable "router_name" {
  description = "Cloud Router name"
  type        = string
}

variable "nat_name" {
  description = "Cloud NAT name"
  type        = string
}

variable "ssl_certificate_name" {
  description = "SSL certificate name"
  type        = string
}

variable "gcs_frontend_bucket_name" {
  description = "GCS frontend bucket name"
  type        = string
}

variable "cloud_run_service_name" {
  description = "Cloud Run service name"
  type        = string
}

variable "container_image" {
  description = "Container image URI for Cloud Run"
  type        = string
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 8080
}

variable "min_instances" {
  description = "Minimum instances for Cloud Run"
  type        = number
  default     = 1
}

variable "max_instances" {
  description = "Maximum instances for Cloud Run"
  type        = number
  default     = 100
}

variable "domains" {
  description = "Domains for SSL certificate and routing"
  type        = list(string)
}