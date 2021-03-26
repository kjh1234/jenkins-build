#     resource variables     #
variable "app_resource_group_name" {
  description = "Resource Group name, must be lowercase alphanumeric with hyphens as its used as domain_name_label as well"
  default     = "vm-tf-jenkins"
}

variable "location" {
  description = "The location where resources are created"
  default     = "koreacentral"
}

variable "nsg_id" {
  default     = ""
}

variable "subnet_id" {
  default     = ""
}

variable "lb_id" {
  default     = ""
}

variable "lb_backend_address_pool_id" {
  default     = ""
}

variable "lb_probe_id" {
  default     = ""
}

variable "nic_id" {
  default     = ""
}

variable "prefix" {
  default     = "default"
}

variable "pool_name" {
  default     = "default"
}

variable "vm_instances" {
  default     = "2"
}

variable "admin_id" {
    description = "Default password for azureuser"
    default = "azureuser"
}

variable "admin_password" {
    description = "Default password for azureuser"
    default = "dlatl!1234"
}

variable "public_key" {
    default = "~/.ssh/id_rsa.pub"
}

variable "image_version" {
  default     = "7"
}

variable "application_port" {
  default     = "8080"
}

variable "frontend_port" {
  default     = "8080"
}
