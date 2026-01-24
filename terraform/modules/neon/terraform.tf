terraform {
  required_providers {
    neon = {
      source  = "kislerdm/neon"
      version = "0.13.0"
    }
  }
}

provider "neon" {
  api_key = var.neon_api_key
}
