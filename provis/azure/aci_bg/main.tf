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

resource "azurerm_container_group" "main" {
  name                = "${var.prefix}-ctn-grp"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  ip_address_type     = "public"
  dns_name_label      = "aci-label"
  os_type             = "Linux"

  image_registry_credential {
    server   = "${var.registory_url}"
    username = "${var.registory_username}"
    password = "${var.registory_password}"
  }

  container {
    name   = "hello-world"
    image  = "innoregi.azurecr.io/todo-app:1.0.1"
    cpu    = "0.5"
    memory = "1.5"
    ports {
      port     = 80
      protocol = "TCP"
    }
  }

#   container {
#     name   = "sidecar"
#     image  = "microsoft/aci-tutorial-sidecar"
#     cpu    = "0.5"
#     memory = "1.5"
#   }
}
