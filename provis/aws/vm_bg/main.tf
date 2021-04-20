provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.location}"
}

resource "aws_resourcegroups_group" "resourcegroups_group" {
  name = "${var.app_resource_group_name}"

  resource_query {
    query = <<-JSON
      {
        "ResourceTypeFilters": [
          "AWS::AllSupported"
        ],
        "TagFilters": [
          {
            "Key": "ResourceGroup",
            "Values": ["${var.app_resource_group_name}"]
          }
        ]
      }
    JSON
  }
}

data "aws_vpc" "main" {
  cidr_block       = "172.31.0.0/16"
}

resource "aws_subnet" "blue" {
  vpc_id = "${data.aws_vpc.main.id}"
  cidr_block = "172.31.96.0/20"
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "${var.prefix}_subnet-blue"
    group = "${var.app_resource_group_name}"
  }
}

resource "aws_subnet" "green" {
  vpc_id = "${data.aws_vpc.main.id}"
  cidr_block = "172.31.112.0/20"
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "${var.prefix}-subnet-green"
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
    Name = "${var.prefix}_nsg"
    group = "${var.app_resource_group_name}"
  }
}


locals {
  user_data0 = <<EOF
    #cloud-config
    runcmd:
    - sudo apt install openjdk-11-jre-headless
    - curl -o todo-app-java-on-azure-1.0.0.jar -L -u '${var.nexus_id}:${var.nexus_pw}' -X GET '${var.nexus_api}/search/assets/download?repository=maven-releases&group=com.microsoft.azure.sample&name=todo-app-java-on-azure&version=1.0.0&maven.extension=jar'
    - java -jar todo-app-java-on-azure-1.0.0.jar &>/dev/null &
  EOF

  user_data1 = <<EOF
    #cloud-config
    runcmd:
    - sudo apt install openjdk-11-jre-headless
    - curl -o todo-app-java-on-azure-1.0.1.jar -L -u '${var.nexus_id}:${var.nexus_pw}' -X GET '${var.nexus_api}/search/assets/download?repository=maven-releases&group=com.microsoft.azure.sample&name=todo-app-java-on-azure&version=1.0.1&maven.extension=jar'
    - java -jar todo-app-java-on-azure-1.0.1.jar &>/dev/null &
  EOF
}

resource "aws_instance" "blue" {
  count                  = 1
  ami                    = "ami-baa236c2"
  instance_type          = "t2.micro"
  subnet_id              = "${aws_subnet.blue.id}"
  vpc_security_group_ids = ["${aws_security_group.main.id}"]
  key_name               = "test-key1"

  user_data = "${local.user_data0}"

  tags = {
    Name = "${var.prefix}_ec2_blue"
    group = "${var.app_resource_group_name}"
  }
}

resource "aws_instance" "green" {
  count                  = 1
  ami                    = "ami-baa236c2"
  instance_type          = "t2.micro"
  subnet_id              = "${aws_subnet.green.id}"
  vpc_security_group_ids = ["${aws_security_group.main.id}"]
  key_name               = "test-key1"

  user_data = "${local.user_data1}"

  tags = {
    Name = "${var.prefix}_ec2_green"
    group = "${var.app_resource_group_name}"
  }
}

resource "aws_elb" "main" {
  name            = "${var.prefix}_elb"
  subnets         = ["${aws_subnet.blue.id}"]
  security_groups = ["${aws_security_group.main.id}"]

  listener {
    instance_port     = 8080
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  listener {
    instance_port     = 8080
    instance_protocol = "http"
    lb_port           = 8080
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  tags = {
    Name = "${var.prefix}_elb"
    group = "${var.app_resource_group_name}"
  }
}

resource "aws_lb_target_group" "prod" {
  name   = "${var.prefix}_lb_prod_target"
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
    Name = "${var.prefix}_lb_prod_target"
    group = "${var.app_resource_group_name}"
  }
}

resource "aws_lb_target_group" "stage" {
  name   = "${var.prefix}_lb_stage_target"
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
    Name = "${var.prefix}_lb_stage_target"
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
