terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "hermes" {
  name     = "hermes-rg"
  location = var.location

  tags = {
    Project = "Hermes-Agent-Cloud"
  }
}

resource "azurerm_linux_virtual_machine" "hermes" {
  name                            = "hermes-instance"
  resource_group_name             = azurerm_resource_group.hermes.name
  location                        = azurerm_resource_group.hermes.location
  size                            = var.vm_size
  admin_username                  = "azureuser"
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.hermes.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 50
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  tags = {
    Project = "Hermes-Agent-Cloud"
  }
}
