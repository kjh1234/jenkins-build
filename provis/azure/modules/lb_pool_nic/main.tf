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

# Create network interface
resource "azurerm_network_interface" "main" {
  count = length(var.pool_names)
  
  name                = "${var.prefix}-nic-${element(var.pool_names, count.index)}"
  location            = "${var.location}"
  resource_group_name = "${var.app_resource_group_name}"

  ip_configuration {
    name                          = "${element(var.pool_names, count.index)}-configuration"
    subnet_id                     = "${var.subnet_id}"
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "main" {
  count = length(var.pool_names)
  
  network_interface_id    = "${azurerm_network_interface.main.id}"
  ip_configuration_name   = "${element(var.pool_names, count.index)}-configuration"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.main.id}"
}

resource "azurerm_network_interface_security_group_association" "main" {
  count = length(var.pool_names)
  
  network_interface_id          = "${azurerm_network_interface.main[count.index].id}"
  network_security_group_id     = "${var.nsg_id}"
}
