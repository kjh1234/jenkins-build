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

module "network" {
  source = "./azure/modules/network.tf"
}

output "public_ip_address" {
  value = azurerm_public_ip.main.*.ip_address
}
