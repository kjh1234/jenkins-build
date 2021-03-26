provider "azurerm" {
  features {}
  subscription_id = "${var.subscription_id}"
  client_id = "${var.client_id}"
  client_secret = "${var.client_secret}"
  tenant_id = "${var.tenant_id}"
}

resource "azurerm_resource_group" "main" {
  name     = "${var.app_resource_group_name}"
  location = "${var.location}"
}

module "lb_network" {
  source = "../modules/lb_network"
  
  app_resource_group_name  = "${azurerm_resource_group.main.name}"
  location                 = "${azurerm_resource_group.main.location}"
  prefix                   = "vm"
}

module "lb_pool_nic" {
  source = "../modules/lb_pool_nic"
  
  app_resource_group_name  = "${azurerm_resource_group.main.name}"
  location                 = "${azurerm_resource_group.main.location}"
  
  prefix                   = "vm"
  pool_names               = ["blue", "green"]
  
  nsg_id                   = "${module.lb_network.nsg_id}"
  subnet_id                = "${module.lb_network.subnet_id}"
  lb_id                    = "${module.lb_network.lb_id}"
}
