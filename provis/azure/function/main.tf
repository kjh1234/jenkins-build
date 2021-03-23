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

resource "azurerm_storage_account" "main" {
  name                     = "funcStorageAccount"
  resource_group_name      = "${azurerm_resource_group.main.name}"
  location                 = "${azurerm_resource_group.main.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_app_service_plan" "main" {
  name                = "func-service-plan"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_function_app" "main" {
  name                       = "az-func"
  location                   = "${azurerm_resource_group.main.location}"
  resource_group_name        = "${azurerm_resource_group.main.name}"
  app_service_plan_id        = "${azurerm_app_service_plan.main.id}"
  storage_account_name       = "${azurerm_storage_account.main.name}"
  storage_account_access_key = "${azurerm_storage_account.main.primary_access_key}"
}
