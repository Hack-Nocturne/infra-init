resource "digitalocean_ssh_key" "ssh_pub_key" {
  name       = "ssh-pub-key"
  public_key = sensitive(file(var.do_pub_ssh_key_file))
}

resource "digitalocean_droplet" "api" {
  name          = "api-server"
  region        = var.do_droplet_region
  size          = var.do_droplet_size
  image         = var.do_droplet_image
  ssh_keys      = [digitalocean_ssh_key.ssh_pub_key.id]
  droplet_agent = false
  monitoring    = false
}
