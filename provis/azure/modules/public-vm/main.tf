# Create network interface
resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-${var.pool_name}-nic"
  location            = "${var.location}"
  resource_group_name = "${var.app_resource_group_name}"

  ip_configuration {
    name                          = "${var.pool_name}-configuration"
    subnet_id                     = "${var.subnet_id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${var.pip_id}"
  }
}

resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id          = "${azurerm_network_interface.main.id}"
  network_security_group_id     = "${var.nsg_id}"
}

# VM Create
resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}-${var.pool_name}"
  location              = "${var.location}"
  resource_group_name   = "${var.app_resource_group_name}"
  vm_size               = "Standard_DS1_v2"
  network_interface_ids = ["${azurerm_network_interface.main.id}"]

  storage_image_reference {
      publisher = "Canonical"
      offer     = "UbuntuServer"
      sku       = "18.04-LTS"
      version   = "latest"
  }

  storage_os_disk {
    name              = "osdisk-${var.pool_name}"
    caching       = "ReadWrite"
    managed_disk_type = "Standard_LRS"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "tomcat-${var.prefix}-${var.pool_name}"
    admin_username = "${var.admin_id}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_id}/.ssh/authorized_keys"
      key_data = "${var.public_key}"
    }
  }
}

