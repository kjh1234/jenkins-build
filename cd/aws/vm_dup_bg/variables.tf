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
  default     = "vm-dup-bg"
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

variable "subnet_cidr" {
    default = "10.0.3.0/24"
}

variable "frontend_port" {
    description = "The frontend port of the external Load Balancer"
    default     = 80
}

variable "application_port" {
    description = "The backend port where the application can be accessed"
    default     = 8080
}

variable "nexus_id" {
    default = ""
}

variable "nexus_pw" {
    default = ""
}

variable "nexus_api" {
    default = ""
}
