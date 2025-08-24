module "digitalocean" {
  source = "./modules/digitalocean"

  do_api_token        = var.do_config.api_token
  do_pub_ssh_key_file = var.do_config.pub_ssh_key_file
  do_droplet_size     = var.do_config.size
  do_droplet_region   = var.do_config.region
  do_droplet_image    = var.do_config.image
}
