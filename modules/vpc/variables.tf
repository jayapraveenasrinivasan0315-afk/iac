variable "project_id" {
  type = string
}

variable "name" {
  type = string
}

variable "subnet_name" {
  type = string
}

variable "subnet_ip_cidr_range" {
  type = string
}

variable "region" {
  type = string
}
variable "connector_name"{
  type = string
}
variable "connector_ip_cidr_range"{
  type = string
}
variable "connector_min_instances"{
  type = number
}
variable "connector_max_instances"{
  type = number
}
variable "router_name"{
  type = string
}
variable "nat_name"{
  type = string
}

