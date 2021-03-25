provider "azurerm" {
  features {}
  subscription_id = "${var.subscription_id}"
  client_id = "${var.client_id}"
  client_secret = "${var.client_secret}"
  tenant_id = "${var.tenant_id}"
}

# Locate the existing custom/golden image
data "azurerm_image" "blue" {
  name                = "tomcat-7"
  resource_group_name = "vmss-bg-image-gr"
}

# Locate the existing custom/golden image
data "azurerm_image" "green" {
  name                = "tomcat-8"
  resource_group_name = "vmss-bg-image-gr"
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
  allocation_method            = "Static"
  sku                          = "standard"
}

resource "azurerm_lb" "main" {
  name                = "vm-lb"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  sku                 = "standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = "${azurerm_public_ip.main.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "main" {
  resource_group_name = "${azurerm_resource_group.main.name}"
  loadbalancer_id     = "${azurerm_lb.main.id}"
  name                = "blue-bepool"
}

resource "azurerm_lb_backend_address_pool" "green" {
  resource_group_name = "${azurerm_resource_group.main.name}"
  loadbalancer_id     = "${azurerm_lb.main.id}"
  name                = "green-bepool"
}

resource "azurerm_lb_probe" "main" {
  resource_group_name = "${azurerm_resource_group.main.name}"
  loadbalancer_id     = "${azurerm_lb.main.id}"
  name                = "tomcat"
  port                = "${var.application_port}"
}

resource "azurerm_lb_probe" "green" {
  resource_group_name = "${azurerm_resource_group.main.name}"
  loadbalancer_id     = "${azurerm_lb.main.id}"
  name                = "tomcat-test"
  port                = "${var.application_port}"
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
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "main" {
  network_interface_id    = "${azurerm_network_interface.main.id}"
  ip_configuration_name   = "testconfiguration1"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.main.id}"
}

resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id          = "${azurerm_network_interface.main.id}"
  network_security_group_id     = "${azurerm_network_security_group.main.id}"
}

resource "azurerm_virtual_machine" "vm" {
  name                  = "vm-blue"
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
    id = "${data.azurerm_image.blue.id}"
  }

  storage_os_disk {
    name              = "myosdisk1"
    caching       = "ReadWrite"
    managed_disk_type = "Standard_LRS"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "todo-vm"
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

resource "azurerm_lb_rule" "lbnatrule" {
  resource_group_name            = "${var.app_resource_group_name}"
  loadbalancer_id                = "${azurerm_lb.main.id}"
  name                           = "tomcat"
  protocol                       = "Tcp"
  frontend_port                  = "${var.frontend_port}"
  backend_port                   = "${var.application_port}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.main.id}"
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = "${azurerm_lb_probe.main.id}"
}



# green vm

# Create network interface
resource "azurerm_network_interface" "green" {
  name                = "vm-nic-green"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"

  ip_configuration {
    name                          = "testconfiguration2"
    subnet_id                     = "${azurerm_subnet.main.id}"
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "green" {
  network_interface_id    = "${azurerm_network_interface.green.id}"
  ip_configuration_name   = "testconfiguration1"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.green.id}"
}

resource "azurerm_network_interface_security_group_association" "green" {
  network_interface_id          = "${azurerm_network_interface.green.id}"
  network_security_group_id     = "${azurerm_network_security_group.green.id}"
}

resource "azurerm_virtual_machine" "vm" {
  name                  = "vm-blue"
  location              = "${azurerm_resource_group.main.location}"
  resource_group_name   = "${azurerm_resource_group.main.name}"
  vm_size               = "Standard_DS1_v2"
  network_interface_ids = [azurerm_network_interface.green.id]

#   storage_image_reference {
#     publisher = "Canonical"
#     offer     = "UbuntuServer"
#     sku       = "16.04-LTS"
#     version   = "latest"
#   }
  storage_image_reference {
    id = "${data.azurerm_image.green.id}"
  }

  storage_os_disk {
    name              = "myosdisk1"
    caching       = "ReadWrite"
    managed_disk_type = "Standard_LRS"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "todo-vm"
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

resource "azurerm_lb_rule" "lbnatrule" {
  resource_group_name            = "${var.app_resource_group_name}"
  loadbalancer_id                = "${azurerm_lb.main.id}"
  name                           = "tomcat-test"
  protocol                       = "Tcp"
  frontend_port                  = "${var.application_port}"
  backend_port                   = "${var.application_port}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.green.id}"
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = "${azurerm_lb_probe.main.id}"
}






output "public_ip_address" {
  value = azurerm_public_ip.main.*.ip_address
}
