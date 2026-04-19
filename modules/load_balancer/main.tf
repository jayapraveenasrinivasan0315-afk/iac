# Reserve a static IP for the load balancer
resource "google_compute_address" "static_ip" {
  name         = var.static_ip_name
  address_type = "EXTERNAL"
  region       = var.region

  lifecycle {
    prevent_destroy = true
  }
}

# SSL Certificate (Google-managed)
resource "google_compute_managed_ssl_certificate" "ssl_cert" {
  name = var.ssl_certificate_name

  managed {
    domains = var.domains
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Network Endpoint Group for Cloud Run
resource "google_compute_network_endpoint_group" "cloud_run_neg" {
  name                  = var.cloud_run_neg_name
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    service = var.cloud_run_service_name
  }
}

# Health check for Cloud Run
resource "google_compute_health_check" "cloud_run_health" {
  name = var.health_check_name

  https_health_check {
    port           = "443"
    request_path   = "/health"
    proxy_header   = "NONE"
  }

  check_interval_sec = 10
  timeout_sec        = 5
}

# Backend service for Cloud Run
resource "google_compute_backend_service" "cloud_run_backend" {
  name              = var.cloud_run_backend_name
  load_balancing_scheme = "EXTERNAL"
  protocol          = "HTTPS"
  health_checks     = [google_compute_health_check.cloud_run_health.id]

  backend {
    group = google_compute_network_endpoint_group.cloud_run_neg.id
  }

  session_affinity = "NONE"
  timeout_sec      = 30

  depends_on = [
    google_compute_network_endpoint_group.cloud_run_neg,
    google_compute_health_check.cloud_run_health
  ]
}

# Backend bucket for GCS
resource "google_compute_backend_bucket" "gcs_backend" {
  name        = var.gcs_backend_name
  bucket_name = var.gcs_bucket_name
  enable_cdn  = true

  cdn_policy {
    cache_mode       = "CACHE_ALL_STATIC"
    client_ttl       = 3600
    default_ttl      = 3600
    max_ttl          = 86400
    negative_caching = true
  }
}

# URL Map for routing rules
resource "google_compute_url_map" "https_lb_url_map" {
  name            = var.url_map_name
  default_service = google_compute_backend_bucket.gcs_backend.id

  host_rule {
    hosts        = var.domains
    path_matcher = "api-paths"
  }

  path_matcher {
    name            = "api-paths"
    default_service = google_compute_backend_bucket.gcs_backend.id

    path_rule {
      paths   = ["/api/*"]
      service = google_compute_backend_service.cloud_run_backend.id
    }
  }

  depends_on = [
    google_compute_backend_service.cloud_run_backend,
    google_compute_backend_bucket.gcs_backend
  ]
}

# HTTPS Proxy
resource "google_compute_target_https_proxy" "https_proxy" {
  name             = var.https_proxy_name
  url_map          = google_compute_url_map.https_lb_url_map.id
  ssl_certificates = [google_compute_managed_ssl_certificate.ssl_cert.id]

  depends_on = [
    google_compute_managed_ssl_certificate.ssl_cert,
    google_compute_url_map.https_lb_url_map
  ]
}

# Global forwarding rule for HTTPS
resource "google_compute_global_forwarding_rule" "https_lb_rule" {
  name                  = var.forwarding_rule_name
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_address.static_ip.address
  target                = google_compute_target_https_proxy.https_proxy.id
  port_range            = "443"

  depends_on = [
    google_compute_address.static_ip,
    google_compute_target_https_proxy.https_proxy
  ]
}

# URL Map for HTTP to HTTPS redirect
resource "google_compute_url_map" "http_redirect" {
  name = var.http_redirect_url_map_name

  default_url_redirect {
    https_redirect = true
    strip_query    = false
  }
}

# HTTP Proxy
resource "google_compute_target_http_proxy" "http_proxy" {
  name    = var.http_proxy_name
  url_map = google_compute_url_map.http_redirect.id
}

# Global forwarding rule for HTTP
resource "google_compute_global_forwarding_rule" "http_rule" {
  name                  = var.http_forwarding_rule_name
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_address.static_ip.address
  target                = google_compute_target_http_proxy.http_proxy.id
  port_range            = "80"

  depends_on = [
    google_compute_address.static_ip,
    google_compute_target_http_proxy.http_proxy
  ]
}
