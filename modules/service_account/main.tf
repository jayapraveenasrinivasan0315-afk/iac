resource "google_service_account" "main" {
  account_id   = var.account_id
  display_name = var.display_name
  description  = "Service account for Cloud Run and database access"
}
