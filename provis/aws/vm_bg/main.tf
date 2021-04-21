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

resource "aws_subnet" "blue" {
  vpc_id = "${data.aws_vpc.main.id}"
  cidr_block = "172.31.96.0/20"
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "${var.prefix}-subnet-blue"
    group = "${var.app_resource_group_name}"
  }
}

resource "aws_subnet" "green" {
  vpc_id = "${data.aws_vpc.main.id}"
  cidr_block = "172.31.112.0/20"
  availability_zone = "ap-northeast-2c"
  tags = {
    Name = "${var.prefix}-subnet-green"
    group = "${var.app_resource_group_name}"
  }
}

resource "aws_security_group" "main" {
  name = "${var.prefix}-nsg"
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
    Name = "${var.prefix}_nsg"
    group = "${var.app_resource_group_name}"
  }
}


locals {
  user_data0 = <<EOF
    #!/bin/bash
    sudo apt install openjdk-11-jre-headless
    curl -o todo-app-java-on-azure-1.0.0.jar -L -u '${var.nexus_id}:${var.nexus_pw}' -X GET '${var.nexus_api}/search/assets/download?repository=maven-releases&group=com.microsoft.azure.sample&name=todo-app-java-on-azure&version=1.0.0&maven.extension=jar'
    java -jar todo-app-java-on-azure-1.0.0.jar &>/dev/null &
  EOF

  user_data1 = <<EOF
    #!/bin/bash
    sudo apt install openjdk-11-jre-headless
    curl -o todo-app-java-on-azure-1.0.1.jar -L -u '${var.nexus_id}:${var.nexus_pw}' -X GET '${var.nexus_api}/search/assets/download?repository=maven-releases&group=com.microsoft.azure.sample&name=todo-app-java-on-azure&version=1.0.1&maven.extension=jar'
    java -jar todo-app-java-on-azure-1.0.1.jar &>/dev/null &
  EOF
}

resource "aws_instance" "blue" {
  instance_type          = "t2.micro"
  subnet_id              = "${aws_subnet.blue.id}"
  vpc_security_group_ids = ["${aws_security_group.main.id}"]
  key_name               = "test-key1"
  ami = "${data.aws_ami.ubuntu.id}"

  user_data = "${local.user_data0}"

  tags = {
    Name = "${var.prefix}-ec2-blue"
    group = "${var.app_resource_group_name}"
  }
}

resource "aws_instance" "green" {
  instance_type          = "t2.micro"
  subnet_id              = "${aws_subnet.green.id}"
  vpc_security_group_ids = ["${aws_security_group.main.id}"]
  key_name               = "test-key1"
  ami = "${data.aws_ami.ubuntu.id}"

  user_data = "${local.user_data1}"

  tags = {
    Name = "${var.prefix}-ec2-green"
    group = "${var.app_resource_group_name}"
  }
}

resource "aws_lb" "main" {
  name               = "${var.prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups = ["${aws_security_group.main.id}"]
  subnets = ["${aws_subnet.blue.id}", "${aws_subnet.green.id}"]
//  enable_deletion_protection = true

  tags = {
    Name = "${var.prefix}-alb"
    group = "${var.app_resource_group_name}"
  }
}

resource "aws_lb_target_group" "prod" {
  name   = "${var.prefix}-lb-prod-target"
  vpc_id = "${data.aws_vpc.main.id}"
  port = "80"
  protocol = "HTTP"
  target_type = "instance"
  deregistration_delay = "300"
  slow_start = "0"
  health_check {
    path = "/"
    healthy_threshold = "5"
    unhealthy_threshold = "2"
    timeout = "5"
    interval = "30"
    matcher = "200"
    port = "traffic-port"
    protocol = "HTTP"
  }

  tags = {
    group = "${var.app_resource_group_name}"
  }
}

resource "aws_lb_target_group" "stage" {
  name   = "${var.prefix}-lb-stage-target"
  vpc_id = "${data.aws_vpc.main.id}"
  port = "8080"
  protocol = "HTTP"
  target_type = "instance"
  deregistration_delay = "300"
  slow_start = "0"
  health_check {
    path = "/"
    healthy_threshold = "5"
    unhealthy_threshold = "2"
    timeout = "5"
    interval = "30"
    matcher = "200"
    port = "traffic-port"
    protocol = "HTTP"
  }

  tags = {
    group = "${var.app_resource_group_name}"
  }
}

resource "aws_lb_target_group_attachment" "prod" {
  target_group_arn = "${aws_lb_target_group.prod.arn}"
  target_id        = "${aws_instance.blue.id}"
  port             = 8080
}

resource "aws_lb_target_group_attachment" "stage" {
  target_group_arn = "${aws_lb_target_group.stage.arn}"
  target_id        = "${aws_instance.green.id}"
  port             = 8080
}


resource "aws_lb_listener" "prod" {
  load_balancer_arn = "${aws_lb.main.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.prod.arn}"
  }
}

resource "aws_lb_listener" "stage" {
  load_balancer_arn = "${aws_lb.main.arn}"
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.stage.arn}"
  }
}
