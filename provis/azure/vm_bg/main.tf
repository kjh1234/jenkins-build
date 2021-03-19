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

resource "azurerm_network_interface" "main" {
  name                = "vm-nic"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "main" {
  name                = "vm-blue"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size             = "Standard_DS1_v2"

  os_profile {
    computer_name 		 = "todo-vm"
    admin_username       = "${var.admin_id}"
    admin_password       = "${var.admin_password}"
  }
  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}
