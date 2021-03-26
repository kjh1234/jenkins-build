#     resource variables     #
variable "app_resource_group_name" {
  description = "Resource Group name, must be lowercase alphanumeric with hyphens as its used as domain_name_label as well"
  default     = "vm-tf-jenkins"
}

variable "location" {
  description = "The location where resources are created"
  default     = "koreacentral"
}

variable "subnet_id" {
  default     = ""
}

variable "nsg_id" {
  default     = ""
}

variable "lb_id" {
  default     = ""
}

variable "prefix" {
  default     = "default"
}

variable "pool_name" {
  default     = "default"
}
