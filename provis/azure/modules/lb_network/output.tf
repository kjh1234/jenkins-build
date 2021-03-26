output "public_ip_address" {
  value = azurerm_public_ip.main.*.ip_address
}

output "subnet_id" {
  value = azurerm_subnet.main.id
}

output "nsg_id" {
  value = azurerm_network_security_group.main.id
}

output "lb_id" {
  value = azurerm_lb.main.id
}
