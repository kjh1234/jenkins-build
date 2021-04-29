provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.location}"
}

data "aws_vpc" "main" {
  cidr_block       = "172.31.0.0/16"
}

data "aws_subnet" "blue" {
//  cidr_block       = "172.31.128.0/20"
  filter {
    name = "tag:Name"
    values = ["vmss-bg-subnet-blue"]
  }
}

data "aws_subnet" "green" {
//  cidr_block       = "172.31.144.0/20"
  filter {
    name = "tag:Name"
    values = ["vmss-bg-subnet-green"]
  }
}

data "aws_security_group" "main" {
//  name       = "${var.prefix}-nsg"
  filter {
    name = "tag:Name"
    values = ["vmss-bg-nsg"]
  }
}