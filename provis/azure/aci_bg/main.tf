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

resource "azurerm_virtual_network" "main" {
  name                = "aci-vnet"
  resource_group_name = "${azurerm_resource_group.main.name}"
  location            = "${azurerm_resource_group.main.location}"
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "main" {
  name                 = "aci-subnet"
  virtual_network_name = "${azurerm_virtual_network.main.name}"
  resource_group_name  = "${azurerm_resource_group.main.name}"
  address_prefixes     = ["10.1.0.0/24"]

  delegation {
    name = "delegation"

    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_network_profile" "main" {
  name                = "aci-net-profile"
  resource_group_name = "${azurerm_resource_group.main.name}"
  location            = "${azurerm_resource_group.main.location}"

  container_network_interface {
    name = "aci-blue-nic"

    ip_configuration {
      name      = "exampleipconfig"
      subnet_id = "${azurerm_subnet.main.id}"
    }
  }
}

resource "azurerm_container_group" "main" {
  name                = "${var.prefix}-ctn-grp"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  ip_address_type     = "Private"
  network_profile_id  = "${azurerm_network_profile.main.id}"
  os_type             = "Linux"

  image_registry_credential {
    server   = "${var.registory_url}"
    username = "${var.registory_username}"
    password = "${var.registory_password}"
  }

  container {
    name   = "hello-world"
    image  = "innoregi.azurecr.io/todo-app:1.0.0"
    cpu    = "0.5"
    memory = "1.5"
    ports {
      port     = 8080
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
