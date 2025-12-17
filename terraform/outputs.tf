output "active_ipv4" {
  value       = local.active_ipv4
  description = "Active VM public IPv4 based on selected provider"
  sensitive   = true
}

output "active_username" {
  value       = local.active_username
  description = "Active VM username based on selected provider"
}
