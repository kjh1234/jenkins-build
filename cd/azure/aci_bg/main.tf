  provider "azurerm" {
  features {}
  subscription_id = "${var.subscription_id}"
  client_id = "${var.client_id}"
  client_secret = "${var.client_secret}"
  tenant_id = "${var.tenant_id}"
}


data "azurerm_resource_group" "main" {
  name     = "${var.app_resource_group_name}"
  location = "${var.location}"
}

data "azurerm_virtual_network" "main" {
  name                = "aci-vnet"
  resource_group_name = "${var.app_resource_group_name}"
}

data "azurerm_subnet" "main" {
  name                 = "aci-subnet"
  virtual_network_name = "${data.azurerm_virtual_network.main.name}"
  resource_group_name  = "${var.app_resource_group_name}"
}

data "azurerm_lb" "main" {
  name                = "${var.prefix}-lb"
  resource_group_name = "${var.app_resource_group_name}"
}

# Create public IPs
resource "azurerm_public_ip" "main" {
  name                 = "${var.prefix}-pip"
  resource_group_name = "${azurerm_resource_group.main.name}"
  location            = "${azurerm_resource_group.main.location}"
  allocation_method            = "Static"
  sku                          = "standard"
}

resource "azurerm_lb_backend_address_pool" "main" {
  resource_group_name = "${azurerm_resource_group.main.name}"
  loadbalancer_id     = "${azurerm_lb.main.id}"
  name                = "blue-bepool"
}


resource "azurerm_lb_backend_address_pool" "main" {
  resource_group_name = "${data.azurerm_resource_group.main.name}"
  loadbalancer_id     = "${data.azurerm_lb.main.id}"
  name                = "${pool_name}-bepool"
}

resource "azurerm_lb_probe" "main" {
  resource_group_name = "${data.azurerm_resource_group.main.name}"
  loadbalancer_id     = "${data.azurerm_lb.main.id}"
  name                = "stage-probe"
  port                = "${var.application_port}"
}

resource "azurerm_lb_rule" "main" {
  resource_group_name            = "${data.azurerm_resource_group.main.name}"
  loadbalancer_id                = "${data.azurerm_lb.main.id}"
  name                           = "stage-rule"
  protocol                       = "Tcp"
  frontend_port                  = "8080"
  backend_port                   = "${var.application_port}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.main.id}"
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = "${azurerm_lb_probe.main.id}"
}

resource "azurerm_network_profile" "main" {
  name                = "${var.prefix}-${pool_name}-net-profile"
  resource_group_name = "${data.azurerm_resource_group.main.name}"
  location            = "${data.azurerm_resource_group.main.location}"

  container_network_interface {
    name = "${var.prefix}-${pool_name}-nic"

    ip_configuration {
      name      = "${var.prefix}-${pool_name}-nic-config"
      subnet_id = "${data.azurerm_subnet.main.id}"
    }
  }
}

resource "azurerm_container_group" "main" {
  name                = "${var.prefix}-${pool_name}-ci"
  location            = "${data.azurerm_resource_group.main.location}"
  resource_group_name = "${data.azurerm_resource_group.main.name}"
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
    image  = "innoregi.azurecr.io/todo-app:${tag_version}"
    cpu    = "0.5"
    memory = "1.5"
    ports {
      port     = 8080
      protocol = "TCP"
    }
  }

}

resource "azurerm_lb_backend_address_pool_address" "green" {
  name                    = "${pool_name}-bepool-addr"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.main.id}"
  virtual_network_id      = "${data.azurerm_virtual_network.main.id}"
  ip_address              = "${azurerm_container_group.main.ip_address}"
}
