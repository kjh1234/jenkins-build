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

module "lb_pool" {
  source = "../modules/lb_pool"
  
  app_resource_group_name  = "${azurerm_resource_group.main.name}"
  location                 = "${azurerm_resource_group.main.location}"
  
  prefix                   = "vm"
  pool_names               = ["blue", "green"]
  
  lb_id                    = "${module.lb_network.lb_id}"
}

module "blue_vm" {
  source = "../modules/vm_tomcat_image"
  
  app_resource_group_name  = "${azurerm_resource_group.main.name}"
  location                 = "${azurerm_resource_group.main.location}"
  
  prefix                   = "vm"
  pool_name                = "blue"
  vm_instances             = "2"
  image_version            = "7"
  admin_id                 = "${var.admin_id}"
  public_key               = "${var.public_key}"
  
  nsg_id                   = "${module.lb_network.nsg_id}"
  subnet_id                = "${module.lb_network.subnet_id}"
  lb_backend_address_pool_id = "${module.lb_pool_nic.lb_backend_address_pool_ids[0]}"
}

module "green_vm" {
  source = "../modules/vm_tomcat_image"
  
  app_resource_group_name  = "${azurerm_resource_group.main.name}"
  location                 = "${azurerm_resource_group.main.location}"
  
  prefix                   = "vm"
  pool_name                = "green"
  vm_instances             = "2"
  image_version            = "8"
  admin_id                 = "${var.admin_id}"
  public_key               = "${var.public_key}"
  
  nsg_id                   = "${module.lb_network.nsg_id}"
  subnet_id                = "${module.lb_network.subnet_id}"
  lb_backend_address_pool_id = "${module.lb_pool_nic.lb_backend_address_pool_ids[1]}"
}

module "lb_rule_prod" {
  source = "../modules/lb_rule"
  
  app_resource_group_name  = "${azurerm_resource_group.main.name}"

  system_type              = "prod"
  application_port         = "8080"
  frontend_port            = "80"
  
  lb_id                    = "${module.lb_network.lb_id}"
  lb_backend_address_pool_id = "${module.lb_pool_nic.lb_backend_address_pool_ids[0]}"
  lb_probe_id              = "${module.lb_pool_nic.lb_probe_ids[0]}"
}

module "lb_rule_stage" {
  source = "../modules/lb_rule"
  
  app_resource_group_name  = "${azurerm_resource_group.main.name}"

  system_type              = "stage"
  application_port         = "8080"
  frontend_port            = "8080"
  
  lb_id                    = "${module.lb_network.lb_id}"
  lb_backend_address_pool_id = "${module.lb_pool_nic.lb_backend_address_pool_ids[1]}"
  lb_probe_id              = "${module.lb_pool_nic.lb_probe_ids[1]}"
}
