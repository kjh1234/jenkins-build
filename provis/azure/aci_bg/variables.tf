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
  default     = "aks-tf-jenkins"
}

variable "location" {
  description = "The location where resources are created"
  default     = "koreacentral"
}

variable "prefix" {
    default = "aci"
}

variable "registry_url" {
    default = ""
}

variable "registory_username" {
    default = ""
}

variable "registory_password" {
    default = ""
}
