terraform {
  required_version = ">= 1.12.0"

  backend "s3" {
    bucket = "terraform-state"
    key    = "terraform.tfstate"

    region                      = "auto"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true

    endpoints = { s3 = "https://4b612799ee232923f8e7025f0f8af8ff.r2.cloudflarestorage.com" }
  }
}
