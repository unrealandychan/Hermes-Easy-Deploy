resource "azurerm_key_vault" "hermes" {
  name                       = var.key_vault_name
  location                   = azurerm_resource_group.hermes.location
  resource_group_name        = azurerm_resource_group.hermes.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  # Deployer's service principal can manage secrets
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = ["Set", "Get", "Delete", "List", "Purge", "Recover"]
  }

  tags = {
    Project = "hermes-deploy"
  }
}

# Grant the VM's Managed Identity read access to Key Vault secrets
resource "azurerm_key_vault_access_policy" "vm_identity" {
  key_vault_id = azurerm_key_vault.hermes.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_virtual_machine.hermes.identity[0].principal_id

  secret_permissions = ["Get", "List"]
}

resource "azurerm_key_vault_secret" "openrouter_api_key" {
  count        = var.openrouter_api_key != "" ? 1 : 0
  name         = "openrouter-api-key"
  value        = var.openrouter_api_key
  key_vault_id = azurerm_key_vault.hermes.id

  depends_on = [azurerm_key_vault_access_policy.vm_identity]

  tags = {
    Project = "hermes-deploy"
  }
}

resource "azurerm_key_vault_secret" "openai_api_key" {
  count        = var.openai_api_key != "" ? 1 : 0
  name         = "openai-api-key"
  value        = var.openai_api_key
  key_vault_id = azurerm_key_vault.hermes.id

  depends_on = [azurerm_key_vault_access_policy.vm_identity]

  tags = {
    Project = "hermes-deploy"
  }
}

resource "azurerm_key_vault_secret" "anthropic_api_key" {
  count        = var.anthropic_api_key != "" ? 1 : 0
  name         = "anthropic-api-key"
  value        = var.anthropic_api_key
  key_vault_id = azurerm_key_vault.hermes.id

  depends_on = [azurerm_key_vault_access_policy.vm_identity]

  tags = {
    Project = "hermes-deploy"
  }
}

resource "azurerm_key_vault_secret" "gemini_api_key" {
  count        = var.gemini_api_key != "" ? 1 : 0
  name         = "gemini-api-key"
  value        = var.gemini_api_key
  key_vault_id = azurerm_key_vault.hermes.id

  depends_on = [azurerm_key_vault_access_policy.vm_identity]

  tags = {
    Project = "hermes-deploy"
  }
}
