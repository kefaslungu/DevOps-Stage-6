# infra/terraform/variables.tf

variable "existing_subnet_name" {
  description = "Name of existing Subnet in HNG-13-vnet"
  type        = string
  default     = "default"  # Common default, update if different
}

variable "vm_admin_username" {
  description = "Admin username for the VM"
  type        = string
default     = "kefaslungu"
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "kefaslungu.name.ng"
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key"
  type        = string
  default     = "~/.ssh/id_rsa"
}

