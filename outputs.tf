output "static_ip_address" {
  description = "Static IP address of the load balancer"
  value       = module.load_balancer.static_ip_address
}

output "nip_io_domain" {
  description = "NIP.IO domain that should be used in terraform.tfvars"
  value       = "${replace(module.load_balancer.static_ip_address, ".", "-")}.nip.io"
}
