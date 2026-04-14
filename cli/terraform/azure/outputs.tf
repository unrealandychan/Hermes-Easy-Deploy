output "public_ip" {
  description = "Public IP address of the Hermes instance"
  value       = azurerm_public_ip.hermes.ip_address
}

output "instance_id" {
  description = "VM name"
  value       = azurerm_linux_virtual_machine.hermes.name
}

output "ssh_command" {
  description = "Direct SSH command"
  value       = "ssh azureuser@${azurerm_public_ip.hermes.ip_address}"
}

output "az_ssh_command" {
  description = "Azure CLI SSH command (no open port needed)"
  value       = "az ssh vm --name hermes-instance --resource-group hermes-rg"
}

output "gateway_url" {
  description = "Hermes gateway URL"
  value       = "http://${azurerm_public_ip.hermes.ip_address}:8080"
}
