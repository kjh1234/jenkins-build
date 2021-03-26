#     Credential variables     #
variable "subscription_id" {
  description = "Should be on the credentials file if not you must generate it."
}

variable "client_id" {
  description = "Should be on the credentials file if not you must generate it."
}

variable "client_secret" {
  description = "Should be on the credentials file if not you must generate it."
}

variable "tenant_id" {
  description = "Should be on the credentials file if not you must generate it."
}

#     resource variables     #
variable "app_resource_group_name" {
  description = "Resource Group name, must be lowercase alphanumeric with hyphens as its used as domain_name_label as well"
  default     = "vm-tf-jenkins"
}

variable "location" {
  description = "The location where resources are created"
  default     = "koreacentral"
}

variable "prefix" {
  default     = "default"
}

variable "pool_name" {
  default     = "default"
}

variable "vm_instances" {
  type        = number
  default     = 2
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
