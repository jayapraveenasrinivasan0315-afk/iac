resource "google_sql_database_instance" "main" {
  name             = var.sql_instance_name
  database_version = var.db_version
  region           = var.region
  
  lifecycle {
    prevent_destroy = true
  }
   
  settings {
    tier = "db-f1-micro"
    
    ip_configuration {
      ipv4_enabled   = false
      private_network = var.vpc_network
    }
    
    backup_configuration {
      enabled = true
      start_time = "00:00"
      point_in_time_recovery_enabled = true
      backup_retention_settings {
        retained_backups = 7
        retention_unit = "COUNT"
      }
    }
  }
}

resource "google_sql_database" "myapp" {
  name     = var.database_name
  instance = google_sql_database_instance.main.name
}

resource "google_sql_user" "myapp" {
  name     = var.database_user
  instance = google_sql_database_instance.main.name
  password = var.secure_password
}
