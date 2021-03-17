variable "app_resource_group_name" {
  description = "Resource Group name, must be lowercase alphanumeric with hyphens as its used as domain_name_label as well"
  default     = "vmss-tf-test"
}

variable "location" {
  description = "The location where resources are created"
  default     = "koreacentral"
}

variable "admin_id" {
    description = "Default password for azureuser"
    default = "azureuser"
}

variable "admin_password" {
    description = "Default password for azureuser"
    default = "dlatl!1234"
}

variable "frontend_port" {
    description = "The frontend port of the external Load Balancer"
    default     = 80
}

variable "application_port" {
    description = "The backend port where the application can be accessed"
    default     = 8080
}

variable "image_resource_group_name" {
  description = "Resource Group name for packer images"
  default     = "vmss-bg-image-gr"
}

variable "image_name" {
  description = "The name of OS image to use"
  default     = "tomcat-7"
}