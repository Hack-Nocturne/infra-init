output "active_ipv4" {
  value       = local.active_ipv4
  description = "Active VM public IPv4 based on selected provider"
  sensitive   = true
}

output "active_username" {
  value       = local.active_username
  description = "Active VM username based on selected provider"
}

output "neon_db_host" {
  value = module.neon.db_host
  sensitive = true
}

output "neon_db_user" {
  value = module.neon.db_user
  sensitive = true
}

output "neon_db_password" {
  value = module.neon.db_password
  sensitive = true
}

output "neon_db_name" {
  value = module.neon.db_name
}
