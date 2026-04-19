output "static_ip_address" {
  description = "Static IP address for the load balancer"
  value       = google_compute_global_address.static_ip.address
}

output "static_ip_id" {
  description = "Static IP address ID"
  value       = google_compute_global_address.static_ip.id
}

output "https_proxy_id" {
  description = "HTTPS proxy ID"
  value       = google_compute_target_https_proxy.https_proxy.id
}

output "url_map_id" {
  description = "URL map ID"
  value       = google_compute_url_map.https_lb_url_map.id
}

output "forwarding_rule_id" {
  description = "HTTPS forwarding rule ID"
  value       = google_compute_global_forwarding_rule.https_forwarding_rule.id
}

output "ssl_certificate_id" {
  description = "SSL certificate ID"
  value       = google_compute_managed_ssl_certificate.ssl_cert.id
}

output "backend_service_id" {
  description = "Cloud Run backend service ID"
  value       = google_compute_backend_service.cloud_run_backend.id
}

output "gcs_backend_id" {
  description = "GCS backend bucket ID"
  value       = google_compute_backend_bucket.gcs_backend.id
}
