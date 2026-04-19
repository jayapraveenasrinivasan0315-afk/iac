locals {
  labels = {
    environment = var.environment
    team        = var.team
    managed-by  = "terraform"
  }
}