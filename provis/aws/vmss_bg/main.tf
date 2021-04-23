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

resource "aws_launch_template" "blue" {
  name_prefix   = "todo-app-1.0.0"
  image_id      = "ami-04012241a2c8306de"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${data.aws_security_group.main.id}"]

  tags = {
    group = "${var.app_resource_group_name}"
  }
}

resource "aws_launch_template" "green" {
  name_prefix   = "todo-app-1.0.1"
  image_id      = "ami-003c63cc36f639181"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${data.aws_security_group.main.id}"]

  tags = {
    group = "${var.app_resource_group_name}"
  }
}

resource "aws_autoscaling_group" "blue" {
  availability_zones = ["ap-northeast-2a"]
  desired_capacity   = 2
  min_size           = 2
  max_size           = 5

  launch_template {
    id      = aws_launch_template.blue.id
  }
  
  tags = [
    {
      "key"                 = "group"
      "value"               = "${var.app_resource_group_name}"
      "propagate_at_launch" = true
    }
  ]
}

resource "aws_autoscaling_group" "green" {
  availability_zones = ["ap-northeast-2c"]
  desired_capacity   = 2
  min_size           = 2
  max_size           = 5

  launch_template {
    id      = aws_launch_template.green.id
  }
  
  tags = [
    {
      "key"                 = "group"
      "value"               = "${var.app_resource_group_name}"
      "propagate_at_launch" = true
    }
  ]
}

resource "aws_lb" "main" {
  name               = "${var.prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups = ["${data.aws_security_group.main.id}"]
  subnets = ["${data.aws_subnet.blue.id}", "${data.aws_subnet.green.id}"]
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

resource "aws_autoscaling_attachment" "prod" {
  autoscaling_group_name = "${aws_autoscaling_group.blue.id}"
  alb_target_group_arn   = "${aws_lb_target_group.prod.arn}"
}

resource "aws_autoscaling_attachment" "stage" {
  autoscaling_group_name = "${aws_autoscaling_group.green.id}"
  alb_target_group_arn   = "${aws_lb_target_group.stage.arn}"
}

// resource "aws_lb_target_group_attachment" "prod" {
//   target_group_arn = "${aws_lb_target_group.prod.arn}"
//   target_id        = "${aws_autoscaling_group.blue.id}"
//   port             = 8080
// }
// 
// resource "aws_lb_target_group_attachment" "stage" {
//   target_group_arn = "${aws_lb_target_group.stage.arn}"
//   target_id        = "${aws_autoscaling_group.green.id}"
//   port             = 8080
// }

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
