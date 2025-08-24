variable "do_api_token" {
  type        = string
  description = "DigitalOcean API token for resource management"
  sensitive   = true
}

variable "do_pub_ssh_key_file" {
  type        = string
  description = "Path to the public SSH key file"
  sensitive   = true
}

variable "do_droplet_size" {
  type        = string
  description = "Size of the DigitalOcean droplet"
}

variable "do_droplet_region" {
  type        = string
  description = "Region for the DigitalOcean droplet"
}

variable "do_droplet_image" {
  type        = string
  description = "Image for the DigitalOcean droplet"
}
