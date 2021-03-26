#     resource variables     #
variable "app_resource_group_name" {
  description = "Resource Group name, must be lowercase alphanumeric with hyphens as its used as domain_name_label as well"
  default     = "vm-tf-jenkins"
}

variable "lb_id" {
  default     = ""
}

variable "lb_backend_address_pool_id" {
  default     = ""
}

variable "system_type" {
  default     = "dev"
}

variable "lb_probe_id" {
  default     = ""
}

variable "application_port" {
  default     = "8080"
}

variable "frontend_port" {
  default     = "8080"
}
