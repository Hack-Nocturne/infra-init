locals {
  active_ipv4 = var.active_provider == "az" ? module.azure[0].vm_ipv4 : module.digitalocean[0].droplet_ipv4
}

module "digitalocean" {
  count  = var.active_provider == "do" ? 1 : 0
  source = "./modules/digitalocean"

  do_api_token        = var.do_config.api_token
  do_pub_ssh_key_file = var.do_config.pub_ssh_key_file
  do_droplet_size     = var.do_config.size
  do_droplet_region   = var.do_config.region
  do_droplet_image    = var.do_config.image
}

module "azure" {
  count = var.active_provider == "az" ? 1 : 0
  source = "./modules/azure"

  az_subscription_id  = var.az_config.subscription_id
  az_pub_ssh_key_file = var.az_config.pub_ssh_key_file
  az_region           = var.az_config.region
  az_vm_size          = var.az_config.size
}

module "cloudflare" {
  source = "./modules/cloudflare"

  cf_api_token       = var.cf_config.api_token
  cf_zone_id         = var.cf_config.zone_id
  cf_is_dev          = var.cf_config.is_dev
  cf_api_server_ipv4 = local.active_ipv4
}
