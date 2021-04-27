data "aws_vpc" "main" {
  cidr_block       = "172.31.0.0/16"
}

data "aws_subnet" "main" {
  filter {
    name = "tag:Name"
    values = ["${var.prefix}-subnet-${pool_name}"]
  }
}


data "aws_security_group" "main" {
  filter {
    name = "tag:Name"
    values = ["${var.prefix}-nsg"]
  }
}
