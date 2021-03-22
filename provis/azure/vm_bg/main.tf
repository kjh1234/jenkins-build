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
  name                = "vm-vnet"
  resource_group_name = "${azurerm_resource_group.main.name}"
  location            = "${azurerm_resource_group.main.location}"
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "main" {
  name                 = "vm-subnet"
  virtual_network_name = "${azurerm_virtual_network.main.name}"
  resource_group_name  = "${azurerm_resource_group.main.name}"
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "main" {
  name                 = "vm-pip"
  location             = "${azurerm_resource_group.main.location}"
  resource_group_name  = "${azurerm_resource_group.main.name}"
  allocation_method    = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "main" {
  name                = "vm-nsg"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"

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

# Create network interface

resource "azurerm_network_interface" "main" {
  name                = "vm-nic"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = "${azurerm_subnet.main.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.main.id}"
  }
}
# Create (and display) an SSH key
resource "tls_private_key" "main" {
  algorithm = "RSA"
  rsa_bits = 4096
}
output "tls_private_key" { 
  value = tls_private_key.main.private_key_pem
 }

resource "azurerm_linux_virtual_machine" "main" {
  name                = "vm-blue"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  network_interface_ids = [azurerm_network_interface.main.id]
  size             = "Standard_DS1_v2"

  computer_name  = "todo-vm"
  admin_username       = "${var.admin_id}"
  disable_password_authentication = true
  custom_data          = base64encode(file("cloud-init.yml"))

  admin_ssh_key {
    username   = "${var.admin_id}"
    public_key = "${var.public_key}"
    # public_key     = tls_private_key.main.private_key_pem

  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

output "public_ip_address" {
  value = azurerm_public_ip.main.*.ip_address
}
