resource "azurerm_lb_backend_address_pool" "main" {
  count = length(var.pool_names)
  
  resource_group_name = "${var.app_resource_group_name}"
  loadbalancer_id     = "${var.lb_id}"
  name                = "${element(var.pool_names, count.index)}-bepool"
}

resource "azurerm_lb_probe" "main" {
  count = length(var.pool_names)
  
  resource_group_name = "${var.app_resource_group_name}"
  loadbalancer_id     = "${var.lb_id}"
  name                = "${element(var.pool_names, count.index)}-tomcat"
  port                = "${var.application_port}"
}
