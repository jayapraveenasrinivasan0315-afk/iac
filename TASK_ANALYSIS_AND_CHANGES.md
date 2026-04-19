# Terraform Infrastructure Analysis: Task 2 & Task 3

**Date**: April 18, 2026  
**Project**: GCP Infrastructure as Code  
**Status**: Analysis Complete - Changes Required

---

## Executive Summary

Your Terraform configuration is **partially complete** for Task 3 (Networking) but **needs significant work** for Task 2 (Cloud Run, GCS, Load Balancer). This document outlines what exists, what's missing, what's broken, and all required changes.

---

## Task 3: Provision GCP Networking Stack ✅ (70% Complete)

### ✅ What's Already There

| Component | Status | Location |
|-----------|--------|----------|
| Custom VPC (no default subnet) | ✅ Complete | `modules/vpc/main.tf` |
| Backend Subnet with Private Google Access | ✅ Complete | `modules/vpc/main.tf` |
| Serverless VPC Access Connector | ✅ Complete | `modules/vpc/main.tf` |
| Cloud Router | ✅ Complete | `modules/vpc/main.tf` |
| Cloud NAT | ✅ Complete | `modules/vpc/main.tf` |
| Module structure | ✅ Complete | `modules/vpc/` |

### ❌ What's Missing/Broken

#### 1. **VPC Module - BROKEN router configuration**
```
ISSUE: Line in modules/vpc/main.tf
  region = google_compute_router.router.region  ❌ WRONG
```
**Current Code** (BROKEN):
```hcl
resource "google_compute_router" "router" {
  name    = var.router_name
  region  = google_compute_subnetwork.network-with-private  ❌ WRONG TYPE
  network = google_compute_network.vpc_network.id
  bgp {
    asn = 64514
  }
}
```

**Should Be**:
```hcl
resource "google_compute_router" "router" {
  name    = var.router_name
  region  = var.region  ✅ CORRECT
  network = google_compute_network.vpc_network.id
  bgp {
    asn = 64514
  }
}
```

#### 2. **Missing Outputs in VPC Module**
The `modules/vpc/outputs.tf` has incorrect references. It should output IDs, not module references.

**Current** (BROKEN):
```hcl
output "vpc_network"{
    description = "VPC network"
    value = modules.vpc.vpc_network  ❌ WRONG
}
```

**Should Be**:
```hcl
output "vpc_id" {
    description = "VPC network ID"
    value = google_compute_network.vpc_network.id
    sensitive = false
}

output "subnet_id" {
    description = "Subnet ID"
    value = google_compute_subnetwork.network-with-private.id
    sensitive = false
}

output "connector_id" {
    description = "Serverless VPC Access Connector ID"
    value = google_vpc_access_connector.connector.id
    sensitive = false
}

output "vpc_name" {
    description = "VPC network name"
    value = google_compute_network.vpc_network.name
    sensitive = false
}

output "subnet_name" {
    description = "Subnet name"
    value = google_compute_subnetwork.network-with-private.name
    sensitive = false
}

output "connector_name" {
    description = "Connector name"
    value = google_vpc_access_connector.connector.name
    sensitive = false
}
```

#### 3. **Missing Provider Region in VPC Connector**
The VPC connector doesn't specify the region.

**Add to VPC Connector**:
```hcl
resource "google_vpc_access_connector" "connector" {
  name          = var.connector_name
  ip_cidr_range = var.connector_ip_cidr_range
  network       = google_compute_network.vpc_network.name
  region        = var.region  ✅ ADD THIS
  min_instances = var.connector_min_instances
  max_instances = var.connector_max_instances
}
```

#### 4. **Missing Subnetwork Reference in Router NAT**
The router NAT should reference the subnet explicitly.

**Improve to**:
```hcl
resource "google_compute_router_nat" "nat" {
  name                               = var.nat_name
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"  ✅ CHANGE THIS
  subnetworks {
    name                    = google_compute_subnetwork.network-with-private.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
  
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
```

---

## Task 2: Provision Cloud Run, Frontend Storage, HTTPS Load Balancer ❌ (5% Complete)

### ✅ What's Partially There

| Component | Status | Location |
|-----------|--------|----------|
| GCS Frontend Bucket | ⚠️ Incomplete | `modules/gcs/main.tf` |
| Cloud Run Service | ⚠️ Incomplete | `modules/cloud_run/main.tf` |
| Service Account | ⚠️ Incomplete | `modules/service_account/main.tf` |
| Load Balancer | ❌ Missing | `modules/load_balancer/main.tf` (EMPTY) |

### ❌ Critical Issues

#### 1. **GCS Module - BROKEN location variable**
**Current** (BROKEN):
```hcl
location = "var.region"  ❌ STRING LITERAL, NOT VARIABLE
```

**Should Be**:
```hcl
location = var.region  ✅ CORRECT
```

#### 2. **GCS Module - MISSING Lifecycle Rules**
Task 2 requires lifecycle rules. Add:

```hcl
lifecycle_rule {
  condition {
    age = 30
  }
  action {
    type = "Delete"
  }
}

lifecycle_rule {
  condition {
    is_live = false
  }
  action {
    type = "Delete"
  }
}
```

#### 3. **Cloud Run Service - INCOMPLETE Configuration**

**Missing Issues**:
- ❌ No service account assignment
- ❌ No IAM role bindings for Cloud Run service account
- ❌ Hard-coded image hash (not practical)
- ❌ Hard-coded location (not parametrized)
- ❌ Missing environment variables
- ❌ Missing Cloud SQL client role
- ❌ Missing Secret Manager accessor role
- ❌ No dependencies/outputs

**Complete Cloud Run Module**:

Create `modules/cloud_run/main.tf`:
```hcl
resource "google_service_account" "cloud_run_sa" {
  account_id   = var.service_account_id
  display_name = "Cloud Run Service Account"
  description  = "Service account for Cloud Run backend service"
}

# Cloud SQL Client Role
resource "google_project_iam_member" "cloud_sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Secret Manager Accessor Role
resource "google_project_iam_member" "secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

resource "google_cloud_run_v2_service" "backend" {
  name     = var.cloud_run_service_name
  location = var.region
  deletion_protection = false
  
  ingress = "INTERNAL_ONLY"  # ✅ FIX: Was ONLY_INTERNAL

  scaling {
    max_instance_count = var.max_instances
    min_instance_count = var.min_instances
  }

  template {
    service_account = google_service_account.cloud_run_sa.email
    
    containers {
      image = var.container_image
      ports {
        container_port = var.container_port
      }
      
      env {
        name  = "ENVIRONMENT"
        value = var.environment
      }
    }
    
    vpc_access {
      connector = var.vpc_connector_id
      egress    = "ALL_TRAFFIC"
    }
  }
}
```

**Create `modules/cloud_run/variables.tf`**:
```hcl
variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "service_account_id" {
  type = string
}

variable "cloud_run_service_name" {
  type = string
}

variable "vpc_connector_id" {
  type = string
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
  type = string
}
```

**Create `modules/cloud_run/outputs.tf`**:
```hcl
output "service_id" {
  description = "Cloud Run service ID"
  value       = google_cloud_run_v2_service.backend.id
}

output "service_name" {
  description = "Cloud Run service name"
  value       = google_cloud_run_v2_service.backend.name
}

output "service_uri" {
  description = "Cloud Run service URI"
  value       = google_cloud_run_v2_service.backend.uri
}

output "service_account_email" {
  description = "Service account email"
  value       = google_service_account.cloud_run_sa.email
}
```

#### 4. **GCS Module - COMPLETE Configuration**

**Create `modules/gcs/variables.tf`**:
```hcl
variable "bucket_name" {
  type        = string
  description = "Frontend bucket name (must be globally unique)"
}

variable "region" {
  type        = string
  description = "Region for the bucket"
}

variable "project_id" {
  type = string
}

variable "enable_versioning" {
  type        = bool
  default     = false
  description = "Enable versioning for the bucket"
}
```

**Update `modules/gcs/main.tf`**:
```hcl
resource "google_storage_bucket" "frontend_bucket" {
  project       = var.project_id
  name          = var.bucket_name
  location      = var.region  # ✅ FIX: Was "var.region" (string)
  force_destroy = true

  uniform_bucket_level_access = true

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
  
  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
  
  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 90
    }
  }
  
  versioning {
    enabled = var.enable_versioning
  }
}

# Public access to bucket (for frontend)
resource "google_storage_bucket_iam_binding" "public_read" {
  bucket = google_storage_bucket.frontend_bucket.name
  role   = "roles/storage.objectViewer"
  members = [
    "allUsers"
  ]
}
```

**Create `modules/gcs/outputs.tf`**:
```hcl
output "bucket_name" {
  description = "GCS bucket name"
  value       = google_storage_bucket.frontend_bucket.name
}

output "bucket_url" {
  description = "GCS bucket URL"
  value       = google_storage_bucket.frontend_bucket.url
}

output "bucket_id" {
  description = "GCS bucket ID"
  value       = google_storage_bucket.frontend_bucket.id
}

output "website_url" {
  description = "Website URL for the frontend bucket"
  value       = "https://${google_storage_bucket.frontend_bucket.name}/index.html"
}
```

#### 5. **Load Balancer Module - COMPLETELY MISSING** ❌

This is the most critical missing piece. Create the complete module:

**Create `modules/load_balancer/main.tf`**:
```hcl
# Reserve a static IP for the load balancer
resource "google_compute_address" "static_ip" {
  name         = var.static_ip_name
  address_type = "EXTERNAL"
  region       = var.region
  
  lifecycle {
    prevent_destroy = true  # ✅ As per Task 2 requirement
  }
}

# SSL Certificate (Google-managed)
resource "google_compute_managed_ssl_certificate" "ssl_cert" {
  name = var.ssl_certificate_name
  
  managed {
    domains = var.domains
  }
  
  lifecycle {
    prevent_destroy = true  # ✅ As per Task 2 requirement
  }
}

# Backend service for Cloud Run
resource "google_compute_backend_service" "cloud_run_backend" {
  name            = var.cloud_run_backend_name
  load_balancing_scheme = "EXTERNAL"
  protocol        = "HTTPS"
  health_checks   = [google_compute_health_check.cloud_run_health.id]
  
  backend {
    group = google_compute_network_endpoint_group.cloud_run_neg.id
  }
  
  session_affinity = "NONE"
  timeout_sec     = 30
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

# Backend service for GCS
resource "google_compute_backend_bucket" "gcs_backend" {
  name            = var.gcs_backend_name
  bucket_name     = var.gcs_bucket_name
  enable_cdn      = true
  
  cdn_policy {
    cache_mode        = "CACHE_ALL_STATIC"
    client_ttl        = 3600
    default_ttl       = 3600
    max_ttl           = 86400
    negative_caching  = true
    negative_caching_ttl = 120
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
}

# HTTPS Proxy
resource "google_compute_target_https_proxy" "https_proxy" {
  name             = var.https_proxy_name
  url_map          = google_compute_url_map.https_lb_url_map.id
  ssl_certificates = [google_compute_managed_ssl_certificate.ssl_cert.id]
  
  depends_on = [
    google_compute_managed_ssl_certificate.ssl_cert
  ]
}

# Global forwarding rule
resource "google_compute_global_forwarding_rule" "https_lb_rule" {
  name                  = var.forwarding_rule_name
  load_balancing_scheme = "EXTERNAL"
  address               = google_compute_address.static_ip.address
  target                = google_compute_target_https_proxy.https_proxy.id
  port_range            = "443"
}

# HTTP to HTTPS redirect
resource "google_compute_url_map" "http_redirect" {
  name = var.http_redirect_url_map_name
  
  default_url_redirect {
    redirect_code = "301"
    https_redirect = true
    strip_query    = false
  }
}

resource "google_compute_target_http_proxy" "http_proxy" {
  name    = var.http_proxy_name
  url_map = google_compute_url_map.http_redirect.id
}

resource "google_compute_global_forwarding_rule" "http_rule" {
  name                  = var.http_forwarding_rule_name
  load_balancing_scheme = "EXTERNAL"
  address               = google_compute_address.static_ip.address
  target                = google_compute_target_http_proxy.http_proxy.id
  port_range            = "80"
}
```

**Create `modules/load_balancer/variables.tf`**:
```hcl
variable "region" {
  type = string
}

variable "static_ip_name" {
  type = string
}

variable "ssl_certificate_name" {
  type = string
}

variable "domains" {
  type        = list(string)
  description = "List of domains for SSL certificate"
}

variable "cloud_run_backend_name" {
  type = string
}

variable "cloud_run_neg_name" {
  type = string
}

variable "cloud_run_service_name" {
  type = string
}

variable "gcs_backend_name" {
  type = string
}

variable "gcs_bucket_name" {
  type = string
}

variable "health_check_name" {
  type = string
}

variable "url_map_name" {
  type = string
}

variable "https_proxy_name" {
  type = string
}

variable "forwarding_rule_name" {
  type = string
}

variable "http_redirect_url_map_name" {
  type = string
}

variable "http_proxy_name" {
  type = string
}

variable "http_forwarding_rule_name" {
  type = string
}
```

**Create `modules/load_balancer/outputs.tf`**:
```hcl
output "static_ip_address" {
  description = "Static IP address for load balancer"
  value       = google_compute_address.static_ip.address
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
  description = "Forwarding rule ID"
  value       = google_compute_global_forwarding_rule.https_lb_rule.id
}
```

#### 6. **Service Account Module - INCOMPLETE**

**Update `modules/service_account/main.tf`**:
```hcl
resource "google_service_account" "main" {
  account_id   = var.account_id
  display_name = var.display_name
  description  = "Service account for Cloud Run and database access"
}
```

**Create `modules/service_account/outputs.tf`**:
```hcl
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
```

#### 7. **Root main.tf - BROKEN Module Calls**

**Current** (BROKEN):
```hcl
module "vpc" {
  source = "./vpc"  ❌ Should be "./modules/vpc"
  ...
}
```

**Fixed `main.tf`**:
```hcl
module "vpc" {
  source = "./modules/vpc"
  
  project_id                  = var.project_id
  region                      = var.region
  name                        = var.name
  subnet_name                 = var.subnet_name
  subnet_ip_cidr_range        = var.subnet_ip_cidr_range
  connector_name              = var.connector_name
  connector_ip_cidr_range     = var.connector_ip_cidr_range
  connector_min_instances     = var.connector_min_instances
  connector_max_instances     = var.connector_max_instances
  router_name                 = var.router_name
  nat_name                    = var.nat_name
}

module "service_account" {
  source = "./modules/service_account"
  
  account_id   = "cloud-run-backend"
  display_name = "Cloud Run Backend Service Account"
}

module "cloud_run" {
  source = "./modules/cloud_run"
  
  project_id              = var.project_id
  region                  = var.region
  service_account_id      = "cloud-run-backend"
  cloud_run_service_name  = var.cloud_run_service_name
  vpc_connector_id        = module.vpc.connector_id
  container_image         = var.container_image
  container_port          = var.container_port
  min_instances           = var.min_instances
  max_instances           = var.max_instances
  environment             = var.environment
}

module "gcs" {
  source = "./modules/gcs"
  
  project_id              = var.project_id
  bucket_name             = var.gcs_frontend_bucket_name
  region                  = var.region
  enable_versioning       = false
}

module "load_balancer" {
  source = "./modules/load_balancer"
  
  region                      = var.region
  static_ip_name              = "app-static-ip"
  ssl_certificate_name        = var.ssl_certificate_name
  domains                     = var.domains
  cloud_run_backend_name      = "cloud-run-backend"
  cloud_run_neg_name          = "cloud-run-neg"
  cloud_run_service_name      = var.cloud_run_service_name
  gcs_backend_name            = "gcs-backend"
  gcs_bucket_name             = var.gcs_frontend_bucket_name
  health_check_name           = "cloud-run-health-check"
  url_map_name                = "https-lb-url-map"
  https_proxy_name            = "https-proxy"
  forwarding_rule_name        = "https-lb-rule"
  http_redirect_url_map_name  = "http-redirect"
  http_proxy_name             = "http-proxy"
  http_forwarding_rule_name   = "http-rule"
}
```

#### 8. **variables.tf - MISSING VARIABLES**

**Add to `variables.tf`**:
```hcl
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
  description = "Domains for SSL certificate"
  type        = list(string)
}
```

#### 9. **terraform.tfvars - MISSING VALUES**

**Add to `environment/dev/terraform.tfvars`**:
```hcl
load_balancer_name = "https-lb"
ssl_certificate_name = "app-ssl-cert"
cloud_run_service_name = "backend-service"
gcs_frontend_bucket_name = "my-app-frontend-bucket"
container_image = "gcr.io/gw-devops-internship/backend:latest"
container_port = 8080
min_instances = 1
max_instances = 100
domains = ["yourdomain.com", "www.yourdomain.com"]
```

---

## Required GCP Permissions (Service Account IAM Roles)

For Terraform to create all these resources, the service account needs these roles:

### Networking Permissions
- `roles/compute.networkAdmin` - Create/manage VPCs, subnets, routers, NAT
- `roles/compute.vpnAdmin` - Manage VPC Access Connectors

### Cloud Run Permissions
- `roles/run.admin` - Manage Cloud Run services
- `roles/iam.securityAdmin` - Create service accounts and assign roles
- `roles/iam.serviceAccountAdmin` - Manage service accounts

### Load Balancer Permissions
- `roles/compute.loadBalancerAdmin` - Manage load balancers
- `roles/compute.networkAdmin` - Manage network endpoint groups
- `roles/compute.securityAdmin` - Manage SSL certificates

### Storage Permissions
- `roles/storage.admin` - Create and manage GCS buckets

### Database (MongoDB - if using MongoDB Atlas via Google Cloud Marketplace)
- `roles/cloudresourcemanager.projectEditor` - For any supplementary GCP resources
- Direct permissions granted through MongoDB Atlas integration

### Recommended Service Account Roles

Create a Terraform service account with these roles:
```
roles/compute.networkAdmin
roles/compute.loadBalancerAdmin
roles/compute.securityAdmin
roles/run.admin
roles/iam.securityAdmin
roles/iam.serviceAccountAdmin
roles/storage.admin
roles/secretmanager.secretAccessor  (for Cloud Run to access secrets)
roles/cloudsql.client  (for potential Cloud SQL integration)
```

Or use custom role with specific permissions:
```
compute.networks.create
compute.networks.get
compute.networks.list
compute.networks.update
compute.networks.delete
compute.subnetworks.create
compute.subnetworks.get
compute.subnetworks.update
compute.subnetworks.delete
compute.vpnGateways.create
compute.vpnGateways.delete
compute.routers.create
compute.routers.delete
compute.routers.get
compute.routers.update
compute.routes.create
compute.routes.delete
compute.routes.list
run.services.create
run.services.delete
run.services.get
run.services.update
storage.buckets.create
storage.buckets.delete
storage.buckets.get
storage.buckets.update
compute.targetHttpsProxies.create
compute.targetHttpsProxies.delete
compute.targetHttpsProxies.get
compute.targetHttpsProxies.update
compute.targetHttpProxies.create
compute.targetHttpProxies.delete
compute.targetHttpProxies.get
compute.targetHttpProxies.update
compute.sslCertificates.create
compute.sslCertificates.delete
compute.sslCertificates.get
compute.sslCertificates.list
compute.addresses.create
compute.addresses.delete
compute.addresses.get
compute.addresses.list
compute.globalForwardingRules.create
compute.globalForwardingRules.delete
compute.globalForwardingRules.get
compute.globalForwardingRules.list
compute.globalForwardingRules.update
compute.backendBuckets.create
compute.backendBuckets.delete
compute.backendBuckets.get
compute.backendBuckets.update
compute.backendServices.create
compute.backendServices.delete
compute.backendServices.get
compute.backendServices.update
iam.serviceAccounts.create
iam.serviceAccounts.delete
iam.serviceAccounts.get
iam.roles.create
iam.roles.delete
```

---

## Summary of Changes Required

### ✅ COMPLETE (Already Done)
1. VPC Network structure
2. Subnet with Private Google Access
3. VPC Connector
4. Cloud Router and NAT

### 🔧 NEED FIXING (Errors in Existing Code)
1. **modules/vpc/main.tf** - Fix router region configuration (Line ~25)
2. **modules/vpc/main.tf** - Add region to VPC connector
3. **modules/vpc/main.tf** - Fix NAT configuration for subnetworks
4. **modules/vpc/outputs.tf** - Fix all output references (currently broken)
5. **modules/gcs/main.tf** - Fix location variable syntax (Line ~4)
6. **providers.tf** - Remove reference to undefined `common_labels`
7. **main.tf** - Fix module source path (./vpc → ./modules/vpc)

### ❌ NEED CREATING (Missing Files/Content)
1. **modules/cloud_run/variables.tf** - Currently empty
2. **modules/cloud_run/outputs.tf** - Currently empty
3. **modules/cloud_run/main.tf** - Rewrite with service account & IAM roles
4. **modules/gcs/outputs.tf** - Currently empty
5. **modules/gcs/variables.tf** - Needs project_id variable
6. **modules/load_balancer/main.tf** - COMPLETELY MISSING
7. **modules/load_balancer/variables.tf** - COMPLETELY MISSING
8. **modules/load_balancer/outputs.tf** - COMPLETELY MISSING
9. **modules/service_account/outputs.tf** - Currently empty
10. **variables.tf** - Add container_image, container_port, min_instances, max_instances, domains variables
11. **environment/dev/terraform.tfvars** - Add missing variable values

---

## How to Implement These Changes

### Phase 1: Fix Existing Code (30 min)
1. Fix VPC module errors
2. Fix GCS module location syntax
3. Fix providers.tf
4. Update outputs

### Phase 2: Complete Modules (1-2 hours)
1. Complete cloud_run module with IAM roles
2. Complete gcs module with lifecycle rules
3. Create load_balancer module (most complex)
4. Complete service_account module

### Phase 3: Update Root Configuration (30 min)
1. Update main.tf with all module calls
2. Update variables.tf with new variables
3. Update terraform.tfvars with values

### Phase 4: Validation (15 min)
```bash
terraform init
terraform validate
terraform plan
```

---

## MongoDB Integration Notes

Since you mentioned MongoDB:

**Option 1: MongoDB Atlas (Cloud-Native)**
- Use MongoDB Atlas provider or create via GCP Marketplace
- Terraform module: `hashicorp/kubernetes` + MongoDB Helm chart
- Connection string stored in Google Secret Manager
- Cloud Run accesses via Secret Manager role

**Option 2: Cloud Firestore**
- Google-native alternative to MongoDB
- Can be provisioned via Terraform: `google_firestore_document`
- No additional permissions needed beyond existing roles

**Option 3: Self-Hosted on Compute Engine**
- Terraform can provision Compute instances
- Would need additional networking (allow port 27017)

---

## Next Steps

1. ✅ Review this analysis document
2. 🔧 Apply all fixes listed in "NEED FIXING" section
3. ❌ Create all missing files in "NEED CREATING" section
4. ✅ Test with `terraform plan`
5. ✅ Deploy infrastructure

---

**End of Analysis Document**
