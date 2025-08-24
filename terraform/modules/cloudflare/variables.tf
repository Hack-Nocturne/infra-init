variable "cf_api_token" {
  type        = string
  description = "Cloudflare API token for resource management"
  sensitive   = true
}

variable "cf_zone_id" {
  type        = string
  description = "Zone specific ID for resource management"
}

variable "cf_api_server_ipv4" {
  type        = string
  description = "API server IPv4 address"
}

variable "cf_is_dev" {
  type        = bool
  description = "Indicates if the resource is for development or testing"
  default     = true
}
