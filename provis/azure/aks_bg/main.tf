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

resource "azurerm_kubernetes_cluster" "k8s" {
    name                = "${var.cluster_name}"
    location            = "${azurerm_resource_group.main.location}"
    resource_group_name = "${azurerm_resource_group.main.name}"
    dns_prefix          = "dns"
    kubernetes_version  = "1.18.14"

    # linux_profile {
    #     admin_username = "ubuntu"
    #     ssh_key {
    #         key_data = "${file(var.public_key)}"
    #     }
    # }

    default_node_pool {
        name            = "agentpool"
        node_count      = "${var.node_count}"
        vm_size         = "Standard_D2_v2"
    }

    # service_principal {
    #     client_id     = "${var.client_id}"
    #     client_secret = "${var.client_secret}"
    # }

    # network_profile {
    #   load_balancer_sku = "Basic"
    #   network_plugin = "kubenet"
    # }

    # tags = {
    #     Environment = "Development"
    # }
}
