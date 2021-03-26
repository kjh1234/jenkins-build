output "lb_backend_address_pool_id" {
  value = azurerm_lb_backend_address_pool.main.*.id
}

output "network_interface_id" {
  value = azurerm_network_interface.main.*.id
}
