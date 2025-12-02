terraform {
  required_version = ">= 1.0"
  
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstatedevopsstage6"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}
