variable "sql_instance_name" {
  type = string
}

variable "db_version" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_network" {
  type = string
}

variable "database_name" {
  type = string
}

variable "database_user" {
  type = string
}

variable "psa_connection" {
  description = "Private Service Access connection dependency"
  type        = string
}

