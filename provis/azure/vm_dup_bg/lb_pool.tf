provider "azurerm" {
  features {}
  subscription_id = "${var.subscription_id}"
  client_id = "${var.client_id}"
  client_secret = "${var.client_secret}"
  tenant_id = "${var.tenant_id}"
}

resource "azurerm_lb_backend_address_pool" "main" {
  resource_group_name = "${azurerm_resource_group.main.name}"
  loadbalancer_id     = "${azurerm_lb.main.id}"
  name                = "${pool_name}-bepool"
}

resource "azurerm_lb_probe" "main" {
  resource_group_name = "${azurerm_resource_group.main.name}"
  loadbalancer_id     = "${azurerm_lb.main.id}"
  name                = "${pool_name}-tomcat"
  port                = "${var.application_port}"
}

# Create network interface
resource "azurerm_network_interface" "main" {
  name                = "vm-nic-${pool_name}"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"

  ip_configuration {
    name                          = "${pool_name}configuration"
    subnet_id                     = "${azurerm_subnet.main.id}"
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "main" {
  network_interface_id    = "${azurerm_network_interface.main.id}"
  ip_configuration_name   = "${pool_name}configuration1"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.main.id}"
}

resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id          = "${azurerm_network_interface.main.id}"
  network_security_group_id     = "${azurerm_network_security_group.main.id}"
}

