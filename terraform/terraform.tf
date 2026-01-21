terraform {
  required_version = ">= 1.12.0"

  backend "s3" {
    bucket = "terraform-state"

    region                      = "auto"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true

    endpoints = { s3 = "https://4b612799ee232923f8e7025f0f8af8ff.r2.cloudflarestorage.com" }
  }

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.60.0"
    }

    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.54.0"
    }
  }
}

provider "azurerm" {
  features {}
  use_oidc = true
  subscription_id = var.az_config.subscription_id
}

provider "digitalocean" {
  token = var.do_config.api_token
}
