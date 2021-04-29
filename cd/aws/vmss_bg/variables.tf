#     Credential variables     #
variable "access_key" {
  description = "Should be on the credentials file if not you must generate it."
}

variable "secret_key" {
  description = "Should be on the credentials file if not you must generate it."
}

#     resource variables     #
variable "app_resource_group_name" {
  description = "Resource Group name, must be lowercase alphanumeric with hyphens as its used as domain_name_label as well"
  default     = "test_vm"
}

variable "location" {
  description = "The location where resources are created"
  default     = "ap-northeast-2"
}

variable "prefix" {
  default     = "vmss-bg"
}

variable "vpc-name" {
  default     = "doss-vpc"
}

variable "public_key" {
    default = ""
}

variable "pool_name" {
    default = ""
}

variable "app_version" {
    default = ""
}
