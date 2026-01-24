locals {
  envlw = lower(var.target_env)
}

resource "neon_project" "hn" {
  name                      = "hn-${local.envlw}-project"
  history_retention_seconds = 21600 # free account hard limit (6 hours)
  pg_version                = var.neon_pg_version
  region_id                 = var.neon_region
  org_id                    = var.neon_org_id

  # Default branch settings
  branch {
    name          = "main"
    database_name = "hnt_fleet_db_${local.envlw}"
    role_name     = "fleet_admin"
  }

  # Default endpoint settings
  default_endpoint_settings {
    autoscaling_limit_min_cu = 1.0
    autoscaling_limit_max_cu = 2.0
  }
}
