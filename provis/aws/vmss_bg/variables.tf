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
  default     = "vmss-bg-gr"
}

variable "location" {
  description = "The location where resources are created"
  default     = "ap-northeast-2"
}

variable "prefix" {
  default     = "vmss-bg"
}

variable "vpc-name" {
  default     = ""
}

variable "public_key" {
    default = ""
}

variable "subnet_cidr" {
    default = "10.0.3.0/24"
}