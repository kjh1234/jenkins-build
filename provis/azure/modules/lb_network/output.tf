output "public_ip_address" {
  value = azurerm_public_ip.main.*.ip_address
}

output "nsg_id" {
  value = azurerm_network_security_group.main.id
}
