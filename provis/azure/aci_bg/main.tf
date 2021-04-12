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

# Create public IPs
resource "azurerm_public_ip" "main" {
  name                 = "${var.prefix}-pip"
  location             = "${var.location}"
  resource_group_name  = "${var.app_resource_group_name}"
  allocation_method            = "Static"
  sku                          = "standard"
}

resource "azurerm_lb" "main" {
  name                = "${var.prefix}-lb"
  location            = "${var.location}"
  resource_group_name = "${var.app_resource_group_name}"
  sku                 = "standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = "${azurerm_public_ip.main.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "main" {
  resource_group_name = "${var.app_resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.main.id}"
  name                = "blue-bepool"
}

resource "azurerm_lb_probe" "main" {
  resource_group_name = "${var.app_resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.main.id}"
  name                = "prod-probe"
  port                = "${var.application_port}"
}

resource "azurerm_lb_rule" "main" {
  resource_group_name            = "${var.app_resource_group_name}"
  loadbalancer_id                = "${azurerm_lb.main.id}"
  name                           = "prod-rule"
  protocol                       = "Tcp"
  frontend_port                  = "${var.frontend_port}"
  backend_port                   = "${var.application_port}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.main.id}"
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = "${var.lb_probe_id}"
}

resource "azurerm_network_profile" "main" {
  name                = "${var.prefix}-blue-net-profile"
  resource_group_name = "${azurerm_resource_group.main.name}"
  location            = "${azurerm_resource_group.main.location}"

  container_network_interface {
    name = "${var.prefix}-blue-nic"

    ip_configuration {
      name      = "${var.prefix}-blue-nic-config"
      subnet_id = "${azurerm_subnet.main.id}"
    }
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "example" {
  network_interface_id    = "${azurerm_network_profile.main.container_network_interface.id}"
  ip_configuration_name   = "${var.prefix}-blue-nic-config"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.main.id}"
}

resource "azurerm_container_group" "main" {
  name                = "${var.prefix}-blue-ci"
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
    name   = "todo-app"
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
