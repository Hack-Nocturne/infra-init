variable "az_subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}

variable "az_region" {
  type        = string
  description = "Azure Region"
  default     = "centralindia"
}

variable "az_vm_size" {
  type        = string
  description = "Azure VM Size"
  default     = "Standard_B1ms"
}

variable "az_pub_ssh_key_file" {
  type        = string
  description = "Path to the public SSH key file"
}

variable "az_resource_group_name" {
  type        = string
  description = "Name of the Resource Group"
  default     = "hnt-rg"
}

variable "az_vm_name" {
  type        = string
  description = "Name of the Virtual Machine"
  default     = "fleet-server"
}
