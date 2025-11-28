# Resource Group
resource "azurerm_resource_group" "HNG13_stage6_rg" {
  name     = var.resource_group_name
  location = var.location
}

# Virtual Network
resource "azurerm_virtual_network" "HNG13_stage6_vnet" {
  name                = "HNG13_stage6-vnet"
  resource_group_name = azurerm_resource_group.HNG13_stage6_rg.name
  location            = var.location
  address_space       = ["10.0.0.0/16"]
}

# Subnet
resource "azurerm_subnet" "HNG13_stage6_subnet" {
  name                 = "HNG13_stage6-subnet"
  resource_group_name  = azurerm_resource_group.HNG13_stage6_rg.name
  virtual_network_name = azurerm_virtual_network.HNG13_stage6_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Network Security Group with Ingress Rules
resource "azurerm_network_security_group" "HNG13_stage6_nsg" {
  name                = "HNG13_stage6-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.HNG13_stage6_rg.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "*"
  source_port_range      = "*"
  destination_address_prefix = "*"
    destination_port_range     = 22
  }

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "*"
  source_port_range      = "*"
  destination_address_prefix = "*"
    destination_port_range     = 80
  }

  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "*"
  source_port_range      = "*"
  destination_address_prefix = "*"
    destination_port_range     = 443
  }

  security_rule {
    name                       = "Allow-Traefik"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "*"
  source_port_range      = "*"
  destination_address_prefix = "*"
    destination_port_range     = 8080
  }
}

# Public IP
resource "azurerm_public_ip" "HNG13_stage6_ip" {
  name                = "HNG13_stage6-public-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.HNG13_stage6_rg.name
  allocation_method   = "Static"
  sku                 = "Basic"
}

# Network Interface
resource "azurerm_network_interface" "HNG13_stage6_nic" {
  name                = "HNG13_stage6-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.HNG13_stage6_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.HNG13_stage6_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.HNG13_stage6_ip.id
  }
}

# Associate NSG with NIC
resource "azurerm_network_interface_security_group_association" "stage4_nic_assoc" {
  network_interface_id      = azurerm_network_interface.HNG13_stage6_nic.id
  network_security_group_id = azurerm_network_security_group.HNG13_stage6_nsg.id
}

# Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "HNG13_stage6_VM" {
  name                  = "HNG13_stage6-vm"
  resource_group_name   = azurerm_resource_group.HNG13_stage6_rg.name
  location              = var.location
  size                  = var.instance_size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.HNG13_stage6_nic.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 16
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  computer_name                   = "HNG13-stage6-VM"
  disable_password_authentication = true

  tags = {
    Name = "HNG13_stage6_VM"
  }

  # Wait for the instance to be fully available before proceeding
  provisioner "remote-exec" {
    inline = ["echo 'Server is ready!'"]
    connection {
      type        = "ssh"
      user        = var.admin_username
      private_key = file(var.ssh_private_key_path)
      host        = azurerm_public_ip.HNG13_stage6_ip.ip_address
    }
  }
}

# Azure DNS Zone
resource "azurerm_dns_zone" "HNG13_stage6_zone" {
  name                = var.domain_name
  resource_group_name = azurerm_resource_group.HNG13_stage6_rg.name
}

# DNS A Record for Domain
resource "azurerm_dns_a_record" "domain" {
  name                = "@"
  zone_name           = azurerm_dns_zone.HNG13_stage6_zone.name
  resource_group_name = azurerm_resource_group.HNG13_stage6_rg.name
  ttl                 = 300
  records             = [azurerm_public_ip.HNG13_stage6_ip.ip_address]
}

# DNS A Records for Subdomains
resource "azurerm_dns_a_record" "auth_subdomain" {
  name                = "auth"
  zone_name           = azurerm_dns_zone.HNG13_stage6_zone.name
  resource_group_name = azurerm_resource_group.HNG13_stage6_rg.name
  ttl                 = 300
  records             = [azurerm_public_ip.HNG13_stage6_ip.ip_address]
}

resource "azurerm_dns_a_record" "todos_subdomain" {
  name                = "todos"
  zone_name           = azurerm_dns_zone.HNG_13stage6_zone.name
  resource_group_name = azurerm_resource_group.HNG13_stage6_rg.name
  ttl                 = 300
  records             = [azurerm_public_ip.HNG13_stage6_ip.ip_address]
}

resource "azurerm_dns_a_record" "users_subdomain" {
  name                = "users"
  zone_name           = azurerm_dns_zone.HNG13_stage6_zone.name
  resource_group_name = azurerm_resource_group.HNG13_stage6_rg.name
  ttl                 = 300
  records             = [azurerm_public_ip.HNG13_stage6_ip.ip_address]
}

# Generate Ansible Inventory File
resource "local_file" "ansible_inventory" {
  content = templatefile("../ansible/templates/inventory.tmpl", {
    ip_address   = azurerm_public_ip.HNG13_stage6_ip.ip_address
    ssh_user     = var.admin_username
    ssh_key_file = var.ssh_private_key_path
    domain_name  = var.domain_name
    admin_email  = var.admin_email
  })
  filename = "../ansible/inventory/hosts.yml"
  depends_on = [azurerm_linux_virtual_machine.HNG13_stage6_VM, null_resource.create_ansible_dirs]
}

# Generate Ansible Variables File
resource "local_file" "ansible_vars" {
  content = templatefile("../ansible/templates/vars.tmpl", {
    domain_name  = var.domain_name
    admin_email  = var.admin_email
    git_repo_url = var.git_repo_url
    git_branch   = var.git_branch
  })
  filename = "../ansible/vars/main.yml"
  depends_on = [azurerm_linux_virtual_machine.HNG13_stage6_VM, null_resource.create_ansible_dirs]
}

# Create Ansible Directories if Not Present
resource "null_resource" "create_ansible_dirs" {
  provisioner "local-exec" {
    command = <<EOT
      mkdir -p ../ansible/inventory
      mkdir -p ../ansible/vars
    EOT
  }
}

# Run Ansible Playbook
resource "null_resource" "ansible_provisioner" {
  triggers = {
    instance_id = azurerm_linux_virtual_machine.HNG13_stage6_VM.id
  }

  provisioner "local-exec" {
    command = "cd ../ansible && ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory/hosts.yml playbook.yml -vvv"
  }

  depends_on = [local_file.ansible_inventory, local_file.ansible_vars]
}
