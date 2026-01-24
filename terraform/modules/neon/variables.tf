variable "neon_api_key" {
  type        = string
  description = "Neon API key for resource management"
  sensitive   = true
}

variable "neon_org_id" {
  type        = string
  description = "Neon organization ID"
  sensitive   = true
}

variable "neon_pg_version" {
  type        = number
  description = "PostgreSQL version"
  default     = 16
}

variable "neon_region" {
  type        = string
  description = "Region for the Neon project"
  default     = "aws-ap-southeast-1"
}

variable "target_env" {
  type        = string
  description = "Target environment (e.g., dev, stage, prod)"
}
