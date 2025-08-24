variable "do_config" {
  type = object({
    api_token        = string
    pub_ssh_key_file = string
    region           = optional(string, "blr1")
    size             = optional(string, "s-1vcpu-1gb")
    image            = optional(string, "ubuntu-25-04-x64")
  })
}
