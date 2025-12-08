# infra/terraform/main.tf
terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstatexxxxx"  # Update with your storage account
    container_name       = "tfstate"
    key                  = "todo-app.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# Reference existing Resource Group
data "azurerm_resource_group" "main" {
  name = "Hng-13(RG)"
}

# Reference existing Virtual Network
data "azurerm_virtual_network" "main" {
  name                = "HNG-13-vnet"
  resource_group_name = data.azurerm_resource_group.main.name
}

data "azurerm_subnet" "main" {
  name                 = var.existing_subnet_name  # Get this from the command above
  virtual_network_name = data.azurerm_virtual_network.main.name
  resource_group_name  = data.azurerm_resource_group.main.name
}

data "azurerm_public_ip" "main" {
  name                = "HNG-13-ip"
  resource_group_name = data.azurerm_resource_group.main.name
}

data "azurerm_network_security_group" "main" {
  name                = "HNG-13-nsg"
  resource_group_name = data.azurerm_resource_group.main.name
}

data "azurerm_network_interface" "main" {
  name                = "hng-13337"
  resource_group_name = data.azurerm_resource_group.main.name
}

data "azurerm_linux_virtual_machine" "main" {
  name                = "HNG-13"
  resource_group_name = data.azurerm_resource_group.main.name
}

# Generate Ansible Inventory using existing resources
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    server_ip = data.azurerm_public_ip.main.ip_address
    ssh_user  = var.vm_admin_username
    ssh_key   = var.ssh_private_key_path
  })
  filename = "${path.module}/../ansible/inventory.ini"
}

# Null resource to trigger Ansible
resource "null_resource" "run_ansible" {
  triggers = {
    vm_id      = data.azurerm_linux_virtual_machine.main.id
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Using existing VM: ${data.azurerm_linux_virtual_machine.main.name}"
      echo "Public IP: ${data.azurerm_public_ip.main.ip_address}"
      echo "Waiting for VM to be ready..."
      timeout /t 10
      cd ${path.module}/../ansible
      set ANSIBLE_HOST_KEY_CHECKING=False
      ansible-playbook -i inventory.ini playbook.yml
    EOT
    interpreter = ["cmd", "/c"]
  }

  depends_on = [local_file.ansible_inventory]
}
