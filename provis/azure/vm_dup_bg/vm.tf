

# Locate the existing custom/golden image
data "azurerm_image" "main" {
  name                = "tomcat-${image_version}"
  resource_group_name = "vmss-bg-image-gr"
}

resource "azurerm_virtual_machine" "main" {
  name                  = "vm-${pool_name}-COUNT"
  location              = "${azurerm_resource_group.main.location}"
  resource_group_name   = "${azurerm_resource_group.main.name}"
  vm_size               = "Standard_DS1_v2"
  network_interface_ids = [azurerm_network_interface.main.id]

#   storage_image_reference {
#     publisher = "Canonical"
#     offer     = "UbuntuServer"
#     sku       = "16.04-LTS"
#     version   = "latest"
#   }
  storage_image_reference {
    id = "${data.azurerm_image.main.id}"
  }

  storage_os_disk {
    name              = "myosdisk-${pool_name}-COUNT"
    caching       = "ReadWrite"
    managed_disk_type = "Standard_LRS"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "todo-vm-${pool_name}-COUNT"
    admin_username = "${var.admin_id}"
    admin_password = "${var.admin_password}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_id}/.ssh/authorized_keys"
      key_data = "${var.public_key}"
    }
  }
}
