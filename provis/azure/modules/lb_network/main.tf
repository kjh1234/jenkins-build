resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-vnet"
  resource_group_name = "${var.app_resource_group_name}"
  location            = "${var.location}"
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "main" {
  name                 = "${var.prefix}-subnet"
  virtual_network_name = "${azurerm_virtual_network.main.name}"
  resource_group_name  = "${var.app_resource_group_name}"
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "main" {
  name                 = "${var.prefix}-pip"
  location             = "${var.location}"
  resource_group_name  = "${var.app_resource_group_name}"
  allocation_method            = "Static"
  sku                          = "standard"
}

# Create public IPs
resource "azurerm_public_ip" "jumpbox" {
  name                 = "${var.prefix}-jumpbox-pip"
  location             = "${var.location}"
  resource_group_name  = "${var.app_resource_group_name}"
  allocation_method            = "Static"
  sku                          = "standard"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-nsg"
  location            = "${var.location}"
  resource_group_name = "${var.app_resource_group_name}"

  security_rule {
    name                       = "allow-public-access"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "22-55000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
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
