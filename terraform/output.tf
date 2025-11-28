output "instance_ip" {
  value = azurerm_public_ip.HNG_stage4_ip.ip_address
}

output "domain" {
  value = var.domain_name
}

output "application_url" {
  value = "https://${var.domain_name}"
}
