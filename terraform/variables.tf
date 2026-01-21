variable "active_provider" {
  type    = string
  default = "az" # or "do"
}

variable "do_config" {
  type = object({
    api_token        = string
    pub_ssh_key_file = string
    region           = optional(string, "blr1")
    size             = optional(string, "s-1vcpu-1gb")
    image            = optional(string, "ubuntu-25-04-x64")
  })
}

variable "az_config" {
  type = object({
    subscription_id  = string
    pub_ssh_key_file = string
    region           = optional(string, "centralindia")
    size             = optional(string, "Standard_B1ms")
  })
}

variable "cf_config" {
  type = object({
    api_token = string
    zone_id   = string
    is_dev    = optional(bool, true)
  })
}

variable "ssh_port" {
  type      = string
  sensitive = true
}

variable "target_env" {
  type      = string
}
