provider "azurerm" {
  features {}
  subscription_id = "${var.subscription_id}"
  client_id = "${var.client_id}"
  client_secret = "${var.client_secret}"
  tenant_id = "${var.tenant_id}"
}

data "azurerm_subnet" "main" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = "${var.app_resource_group_name}"
}

data "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-nsg"
  resource_group_name = "${var.app_resource_group_name}"
}

data "azurerm_lb" "main" {
  name                = "${var.prefix}-lb"
  resource_group_name = "${var.app_resource_group_name}"
}

data "azurerm_lb_backend_address_pool" "main" {
  resource_group_name = "${var.app_resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.main.id}"
  name                = "${var.pool_name}-bepool"
}

resource "azurerm_lb_probe" "main" {
  resource_group_name = "${var.app_resource_group_name}"
  loadbalancer_id     = "${var.lb_id}"
  name                = "${var.pool_name}-tomcat"
}

module "vm_stage" {
  source = "../../../provis/azure/modules/vm_tomcat_image"

  app_resource_group_name  = "${var.app_resource_group_name}"
  location                 = "${var.location}"

  prefix                   = "vm"
  pool_name                = "${var.pool_name}"
  vm_instances             = "2"
  image_version            = "${var.image_version}"
  admin_id                 = "${var.admin_id}"
  public_key               = "${var.public_key}"

  nsg_id                   = "${azurerm_network_security_group.main.id}"
  subnet_id                = "${azurerm_subnet.main.id}"
  lb_backend_address_pool_id = "${azurerm_lb_backend_address_pool.main.id}"
}

module "lb_rule_stage" {
  source = "../../../provis/azure/modules/lb_rule"

  app_resource_group_name  = "${azurerm_resource_group.main.name}"

  system_type              = "stage"
  application_port         = "8080"
  frontend_port            = "8080"

  lb_id                    = "${azurerm_lb_backend_address_pool.main.id}"
  lb_backend_address_pool_id = "${azurerm_lb_backend_address_pool.main.id}"
  lb_probe_id              = "${azurerm_lb_probe.main.id}"
}
