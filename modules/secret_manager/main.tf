# Generate secure random password
resource "random_password" "db_password" {
  length  = 32
  special = true
}

# Data source to get Cloud SQL instance info
data "google_sql_database_instance" "main" {
  name     = var.sql_instance_name
  project  = var.project_id
}

# Store database password in Secret Manager
resource "google_secret_manager_secret" "db_password" {
  project   = var.project_id
  secret_id = "${var.environment}-db-password"

  replication {
    auto {}
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}

# Store database URL in Secret Manager
resource "google_secret_manager_secret" "db_url" {
  project   = var.project_id
  secret_id = "${var.environment}-db-url"

  replication {
    auto {}
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_secret_manager_secret_version" "db_url" {
  secret      = google_secret_manager_secret.db_url.id
  secret_data = "postgresql://${var.database_user}:${random_password.db_password.result}@${data.google_sql_database_instance.main.private_ip_address}:5432/${var.database_name}"
}

# Store JWT secret in Secret Manager
resource "random_password" "jwt_secret" {
  length  = 64
  special = false
}

resource "google_secret_manager_secret" "jwt_secret" {
  project   = var.project_id
  secret_id = "${var.environment}-jwt-secret"

  replication {
    auto {}
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_secret_manager_secret_version" "jwt_secret" {
  secret      = google_secret_manager_secret.jwt_secret.id
  secret_data = random_password.jwt_secret.result
}

# Store API keys in Secret Manager
resource "random_password" "api_key" {
  length  = 32
  special = false
}

resource "google_secret_manager_secret" "api_key" {
  project   = var.project_id
  secret_id = "${var.environment}-api-key"

  replication {
    auto {}
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_secret_manager_secret_version" "api_key" {
  secret      = google_secret_manager_secret.api_key.id
  secret_data = random_password.api_key.result
}

# Grant secret access to Cloud Run service account
resource "google_secret_manager_secret_iam_member" "db_password_access" {
  secret_id = google_secret_manager_secret.db_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.service_account_email}"
}

resource "google_secret_manager_secret_iam_member" "db_url_access" {
  secret_id = google_secret_manager_secret.db_url.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.service_account_email}"
}

resource "google_secret_manager_secret_iam_member" "jwt_secret_access" {
  secret_id = google_secret_manager_secret.jwt_secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.service_account_email}"
}

resource "google_secret_manager_secret_iam_member" "api_key_access" {
  secret_id = google_secret_manager_secret.api_key.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.service_account_email}"
}
