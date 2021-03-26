resource "azurerm_lb_rule" "main" {
  resource_group_name            = "${var.app_resource_group_name}"
  loadbalancer_id                = "${var.lb_id}"
  name                           = "${var.system_type}-rule"
  protocol                       = "Tcp"
  frontend_port                  = "${var.frontend_port}"
  backend_port                   = "${var.application_port}"
  backend_address_pool_id        = "${var.lb_backend_address_pool_id}"
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = "${var.lb_probe_id}"
}
