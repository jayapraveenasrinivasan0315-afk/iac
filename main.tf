terraform {
  required_version = ">= 1.9.0"
  backend "gcs" {}
}

module "vpc" {
  source = "./modules/vpc"

  project_id              = var.project_id
  region                  = var.region
  name                    = var.name
  subnet_name             = var.subnet_name
  subnet_ip_cidr_range    = var.subnet_ip_cidr_range
  connector_name          = var.connector_name
  connector_ip_cidr_range = var.connector_ip_cidr_range
  connector_min_instances = var.connector_min_instances
  connector_max_instances = var.connector_max_instances
  router_name             = var.router_name
  nat_name                = var.nat_name
}

module "service_account" {
  source = "./modules/service_account"

  account_id   = "cloud-run-backend"
  display_name = "Cloud Run Backend Service Account"
}

module "cloud_run" {
  source = "./modules/cloud_run"

  project_id             = var.project_id
  region                 = var.region
  service_account_id     = "cloud-run-backend"
  cloud_run_service_name = var.cloud_run_service_name
  vpc_connector_id       = module.vpc.connector_id
  container_image        = var.container_image
  container_port         = var.container_port
  min_instances          = var.min_instances
  max_instances          = var.max_instances
  environment            = var.environment
  db_url_secret_id       = var.db_url_secret_id

  depends_on = [
    module.vpc,
    module.service_account
  ]
}

module "gcs" {
  source = "./modules/gcs"

  project_id          = var.project_id
  bucket_name         = var.gcs_frontend_bucket_name
  region              = var.region
  enable_versioning   = false
}

module "load_balancer" {
  source = "./modules/load_balancer"

  region                     = var.region
  static_ip_name             = "app-static-ip"
  ssl_certificate_name       = var.ssl_certificate_name
  domains                    = var.domains
  cloud_run_backend_name     = "cloud-run-backend"
  cloud_run_neg_name         = "cloud-run-neg"
  cloud_run_service_name     = var.cloud_run_service_name
  gcs_backend_name           = "gcs-backend"
  gcs_bucket_name            = var.gcs_frontend_bucket_name
  health_check_name          = "cloud-run-health-check"
  url_map_name               = "https-lb-url-map"
  https_proxy_name           = "https-proxy"
  forwarding_rule_name       = "https-lb-rule"
  http_redirect_url_map_name = "http-redirect"
  http_proxy_name            = "http-proxy"
  http_forwarding_rule_name  = "http-rule"

  depends_on = [
    module.cloud_run,
    module.gcs
  ]
}

# GitHub Actions Service Account Permissions
resource "google_project_iam_member" "github_actions_artifact_registry_admin" {
  project = var.project_id
  role    = "roles/artifactregistry.admin"
  member  = "serviceAccount:github-action-cicdsa-482@${var.project_id}.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "github_actions_artifact_registry_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:github-action-cicdsa-482@${var.project_id}.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "github_actions_run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:github-action-cicdsa-482@${var.project_id}.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "github_actions_token_creator" {
  project = var.project_id
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:github-action-cicdsa-482@${var.project_id}.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "github_actions_sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:github-action-cicdsa-482@${var.project_id}.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "github_actions_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:github-action-cicdsa-482@${var.project_id}.iam.gserviceaccount.com"
}
