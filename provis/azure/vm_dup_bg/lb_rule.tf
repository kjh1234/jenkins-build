

resource "azurerm_lb_rule" "lbnatrule" {
  resource_group_name            = "${var.app_resource_group_name}"
  loadbalancer_id                = "${azurerm_lb.main.id}"
  name                           = "tomcat"
  protocol                       = "Tcp"
  frontend_port                  = "${var.frontend_port}"
  backend_port                   = "${var.application_port}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.main.id}"
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = "${azurerm_lb_probe.main.id}"
}
