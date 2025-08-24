terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.60.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_api_token
}
