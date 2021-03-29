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
  virtual_network_name = "vm-vnet"
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
  loadbalancer_id     = "${data.azurerm_lb.main.id}"
  name                = "${var.pool_name}-bepool"
}

data "azurerm_lb_probe" "main" {
  loadbalancer_id     = "${data.azurerm_lb.main.id}"
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

  nsg_id                   = "${data.azurerm_network_security_group.main.id}"
  subnet_id                = "${data.azurerm_subnet.main.id}"
  lb_backend_address_pool_id = "${data.azurerm_lb_backend_address_pool.main.id}"
}

module "lb_rule_stage" {
  source = "../../../provis/azure/modules/lb_rule"

  app_resource_group_name  = "${var.app_resource_group_name}"

  system_type              = "stage"
  application_port         = "8080"
  frontend_port            = "8080"

  lb_id                    = "${data.azurerm_lb.main.id}"
  lb_backend_address_pool_id = "${data.azurerm_lb_backend_address_pool.main.id}"
  lb_probe_id              = "${data.azurerm_lb_probe.main.id}"
}
