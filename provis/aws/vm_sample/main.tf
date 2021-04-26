provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.location}"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

// resource "aws_resourcegroups_group" "resourcegroups_group" {
//   name = "${var.app_resource_group_name}"
//
//   resource_query {
//     query = <<-JSON
//       {
//         "ResourceTypeFilters": [
//           "AWS::AllSupported"
//         ],
//         "TagFilters": [
//           {
//             "Key": "group",
//             "Values": ["${var.app_resource_group_name}"]
//           }
//         ]
//       }
//     JSON
//   }
// }

data "aws_vpc" "main" {
  cidr_block       = "172.31.0.0/16"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

# resource "aws_key_pair" "main" {
#   key_name = "test-key1"
#   public_key = "${var.public_key}"
#   tags = {
#     group = "${var.app_resource_group_name}"
#   }
# }

resource "aws_subnet" "main" {
  vpc_id = "${data.aws_vpc.main.id}"
  cidr_block = "${var.subnet_cidr}"
#  availability_zone = "${var.location}"
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "${var.prefix}_subnet"
    group = "${var.app_resource_group_name}"
  }
}

resource "aws_security_group" "main" {
  name = "${var.prefix}_nsg"
  description = "Allow all inbound traffic"
  vpc_id = "${data.aws_vpc.main.id}"

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    group = "${var.app_resource_group_name}"
  }
}

locals {
  user_data0 = <<EOF
#!/bin/bash
sudo apt-get update -y
sudo apt install openjdk-11-jre-headless -y
curl -o todo-app-java-on-azure-1.0.0.jar -L -u '${var.nexus_id}:${var.nexus_pw}'      -X GET '${var.nexus_api}/search/assets/download?repository=maven-releases&group=com.microsoft.azure.sample&name=todo-app-java-on-azure&version=1.0.0&maven.extension=jar'
java -jar todo-app-java-on-azure-1.0.0.jar &>/dev/null &
EOF

  user_data1 = <<EOF
#!/bin/bash
sudo apt-get update -y
sudo apt install openjdk-11-jre-headless -y
curl -o todo-app-java-on-azure-1.0.1.jar -L -u '${var.nexus_id}:${var.nexus_pw}'      -X GET '${var.nexus_api}/search/assets/download?repository=maven-releases&group=com.microsoft.azure.sample&name=todo-app-java-on-azure&version=1.0.1&maven.extension=jar'
java -jar todo-app-java-on-azure-1.0.1.jar &>/dev/null &
EOF
}

resource "aws_instance" "main" {
  ami = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.main.id}"
  vpc_security_group_ids = ["${aws_security_group.main.id}"]
  key_name = "test-key1"
  availability_zone = "ap-northeast-2a"

  count = 1
  tags = {
    Name = "${var.prefix}_ec2"
    group = "${var.app_resource_group_name}"
  }
}
