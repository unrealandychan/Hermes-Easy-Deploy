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
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = false
    }
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "hermes" {
  name     = "hermes-rg"
  location = var.location

  tags = {
    Project = "hermes-deploy"
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

  # System-assigned Managed Identity — used to pull secrets from Key Vault at boot
  identity {
    type = "SystemAssigned"
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

  # bootstrap.sh is a Terraform templatefile. The VM pulls API keys from Key Vault
  # via its Managed Identity at boot — no secrets in custom_data.
  custom_data = base64encode(templatefile("${path.module}/bootstrap.sh", {
    HERMES_CLOUD  = "azure"
    AWS_REGION    = ""
    SSM_PREFIX    = ""
    AZURE_KV_NAME = var.key_vault_name
    GCP_PROJECT   = ""
  }))

  lifecycle {
    ignore_changes = [custom_data]
  }

  tags = {
    Project = "hermes-deploy"
  }
}
