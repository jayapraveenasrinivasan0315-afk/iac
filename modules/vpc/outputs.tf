output "vpc_id" {
  description = "VPC network ID"
  value       = google_compute_network.vpc_network.id
}

output "vpc_name" {
  description = "VPC network name"
  value       = google_compute_network.vpc_network.name
}

output "subnet_id" {
  description = "Subnet ID"
  value       = google_compute_subnetwork.network-with-private.id
}

output "subnet_name" {
  description = "Subnet name"
  value       = google_compute_subnetwork.network-with-private.name
}

output "connector_id" {
  description = "Serverless VPC Access Connector ID"
  value       = google_vpc_access_connector.connector.id
}

output "connector_name" {
  description = "Connector name"
  value       = google_vpc_access_connector.connector.name
}

output "router_id" {
  description = "Cloud Router ID"
  value       = google_compute_router.router.id
}

output "nat_name" {
  description = "Cloud NAT name"
  value       = google_compute_router_nat.nat.name
}

output "vpc_network_self_link" {
  description = "VPC network self link"
  value       = google_compute_network.vpc_network.self_link
}

output "private_vpc_connection" {
  description = "Private Service Access connection"
  value       = google_service_networking_connection.private_vpc_connection
}
