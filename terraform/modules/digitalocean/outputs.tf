output "droplet_ip" {
  value = digitalocean_droplet.api.ipv4_address
}
