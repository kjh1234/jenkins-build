#     resource variables     #
variable "app_resource_group_name" {
  description = "Resource Group name, must be lowercase alphanumeric with hyphens as its used as domain_name_label as well"
  default     = "vm-tf-jenkins"
}

variable "location" {
  description = "The location where resources are created"
  default     = "koreacentral"
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
