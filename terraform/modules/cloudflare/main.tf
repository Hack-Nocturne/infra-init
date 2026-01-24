locals {
  envl = lower(substr(var.target_env, 0, 1))
  record_name = "${local.envl == "p" ? "api" : "${local.envl}api"}.hack-nocturne.in"
}

resource "cloudflare_dns_record" "api" {
  zone_id = var.cf_zone_id
  name    = local.record_name
  content = var.cf_api_server_ipv4
  type    = "A"
  ttl     = 1
  proxied = true
}
