output "project_id" {
  value = neon_project.hn.id
}

output "db_host" {
  description = "Database host endpoint"
  value       = neon_project.hn.database_host_pooler
  sensitive   = true
}

output "db_password" {
  value = neon_project.hn.database_password
  sensitive = true
}

output "db_user" {
  value = neon_project.hn.database_user
  sensitive = true
}

output "db_name" {
  value = neon_project.hn.database_name
}
