output "lb_probe_ids" {
  value = azurerm_lb_probe.main.*.id
}

output "lb_backend_address_pool_ids" {
  value = azurerm_lb_backend_address_pool.main.*.id
}

output "nic_ids" {
  value = azurerm_network_interface.main.*.id
}
