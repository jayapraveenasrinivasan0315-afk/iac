variable "region" {
  type        = string
  description = "Region for the resources"
}

variable "static_ip_name" {
  type        = string
  description = "Name for the static IP address"
}

variable "ssl_certificate_name" {
  type        = string
  description = "Name for the SSL certificate"
}

variable "domains" {
  type        = list(string)
  description = "List of domains for SSL certificate and routing"
}

variable "cloud_run_backend_name" {
  type        = string
  description = "Name for the Cloud Run backend service"
}

variable "cloud_run_neg_name" {
  type        = string
  description = "Name for the Cloud Run Network Endpoint Group"
}

variable "cloud_run_service_name" {
  type        = string
  description = "Name of the Cloud Run service"
}

variable "gcs_backend_name" {
  type        = string
  description = "Name for the GCS backend bucket"
}

variable "gcs_bucket_name" {
  type        = string
  description = "Name of the GCS bucket for frontend"
}

variable "health_check_name" {
  type        = string
  description = "Name for the health check"
}

variable "url_map_name" {
  type        = string
  description = "Name for the URL map"
}

variable "https_proxy_name" {
  type        = string
  description = "Name for the HTTPS proxy"
}

variable "forwarding_rule_name" {
  type        = string
  description = "Name for the HTTPS forwarding rule"
}

variable "http_redirect_url_map_name" {
  type        = string
  description = "Name for the HTTP redirect URL map"
}

variable "http_proxy_name" {
  type        = string
  description = "Name for the HTTP proxy"
}

variable "http_forwarding_rule_name" {
  type        = string
  description = "Name for the HTTP forwarding rule"
}
