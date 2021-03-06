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
  default     = "test_vm"
}

variable "vpc-name" {
  default     = "doss-vpc"
}

variable "public_key" {
    default = ""
}

variable "subnet_cidr" {
    default = "172.31.64.0/20"
}

variable "frontend_port" {
    description = "The frontend port of the external Load Balancer"
    default     = 80
}

variable "application_port" {
    description = "The backend port where the application can be accessed"
    default     = 8080
}
