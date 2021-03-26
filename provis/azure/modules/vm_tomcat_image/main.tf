# Locate the existing custom/golden image
data "azurerm_image" "main" {
  name                = "tomcat-${var.image_version}"
  resource_group_name = "vmss-bg-image-gr"
}

resource "azurerm_virtual_machine" "main" {
  count                 = "${var.vm_instances}"

  name                  = "${var.prefix}-${var.pool_name}-${count.index}"
  location              = "${var.location}"
  resource_group_name   = "${var.app_resource_group_name}"
  vm_size               = "Standard_DS1_v2"
  network_interface_ids = ["${var.nic_id}"]
#   network_interface_ids = [azurerm_network_interface.main.id]

  storage_image_reference {
    id = "${data.azurerm_image.main.id}"
  }

  storage_os_disk {
    name              = "osdisk-${var.pool_name}-${count.index}"
    caching       = "ReadWrite"
    managed_disk_type = "Standard_LRS"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "tomcat-${var.prefix}-${var.pool_name}-${count.index}"
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

resource "azurerm_lb_rule" "lbnatrule" {
  resource_group_name            = "${var.app_resource_group_name}"
  loadbalancer_id                = "${var.lb_id}"
  name                           = "${var.system_type}-rule"
  protocol                       = "Tcp"
  frontend_port                  = "${var.frontend_port}"
  backend_port                   = "${var.application_port}"
  backend_address_pool_id        = "${var.lb_backend_address_pool_id}"
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = "${var.lb_probe_id}"
}
