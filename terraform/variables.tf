variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Name of the Azure resource group to create"
  type        = string
  default     = "HNG_stage4_rg"
}

variable "instance_size" {
  description = "Size of the Azure VM"
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "HNG_kefas"
}

variable "ssh_public_key_path" {
  description = "Path to your SSH public key (e.g., ../key/HNG_key.pub)"
  type        = string
  default     = "../key/HNG_key.pub"
}

variable "ssh_private_key_path" {
  description = "Path to your SSH private key (e.g., ../key/HNG_key)"
  type        = string
  default     = "../key/HNG_key"
}

variable "admin_email" {
  description = "Admin email for notifications and Let's Encrypt certificates"
  type        = string
  default     = "jameskefaslungu@gmail.com"
}

variable "domain_name" {
  description = "Domain name for the DNS zone"
  type        = string
  default     = "kefaslungu.name.ng"
}

variable "git_repo_url" {
  description = "Git repository URL for the application code"
  type        = string
  default     = "https://github.com/kefaslungu/DevOps-Stage-4.git"
}

variable "git_branch" {
  description = "Git branch to checkout for the application repository"
  type        = string
  default     = "main"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_prefix" {
  description = "Address prefix for the subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
}

variable "client_id" {
  description = "Azure Client ID (Service Principal)"
  type        = string
}

variable "client_secret" {
  description = "Azure Client Secret (Service Principal)"
  type        = string
  sensitive   = true
}
