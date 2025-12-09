output "vm_name" {
  description = "Virtual machine name"
  value       = data.azurerm_virtual_machine.main.name
}

output "vm_id" {
  description = "ID of the existing VM"
  value       = data.azurerm_virtual_machine.main.id
}

output "resource_group_name" {
  description = "Resource group name"
  value       = data.azurerm_resource_group.main.name
}

output "public_ip" {
  description = "Public IP address"
  value       = data.azurerm_public_ip.main.ip_address
}

output "vnet_name" {
  description = "Virtual network name"
  value       = data.azurerm_virtual_network.main.name
}

output "subnet_name" {
  description = "Subnet name"
  value       = data.azurerm_subnet.main.name
}

output "nsg_name" {
  description = "Network security group name"
  value       = data.azurerm_network_security_group.main.name
}

output "ansible_inventory_path" {
  description = "Path to generated Ansible inventory"
  value       = local_file.ansible_inventory.filename
}

output "ssh_command" {
  description = "SSH command to connect to VM"
  value       = "ssh ${var.vm_admin_username}@${data.azurerm_public_ip.main.ip_address}"
}

output "domain_name" {
  description = "DNS zone configured"
  value       = var.domain_name
}
