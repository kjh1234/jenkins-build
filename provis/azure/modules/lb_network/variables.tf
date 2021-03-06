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
