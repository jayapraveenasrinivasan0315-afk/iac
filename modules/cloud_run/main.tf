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
  name                   = var.cloud_run_service_name
  location               = var.region
  deletion_protection    = false
  ingress                = "INTERNAL_ONLY"

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

  depends_on = [
    google_service_account.cloud_run_sa,
    google_project_iam_member.cloud_sql_client,
    google_project_iam_member.secret_accessor
  ]
}