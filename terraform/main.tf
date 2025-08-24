module "digitalocean" {
  source = "./modules/digitalocean"

  do_api_token        = var.do_config.api_token
  do_pub_ssh_key_file = var.do_config.pub_ssh_key_file
  do_droplet_size     = var.do_config.size
  do_droplet_region   = var.do_config.region
  do_droplet_image    = var.do_config.image
}

module "cloudflare" {
  source = "./modules/cloudflare"

  cf_api_token       = var.cf_config.api_token
  cf_zone_id         = var.cf_config.zone_id
  cf_is_dev          = var.cf_config.is_dev
  cf_api_server_ipv4 = module.digitalocean.droplet_ipv4
}
