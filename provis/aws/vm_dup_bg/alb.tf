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

resource "aws_lb_target_group" "blue" {
  name   = "${var.prefix}-lb-blue-target"
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
    pool_name = "blue"
  }
}

resource "aws_lb_target_group" "green" {
  name   = "${var.prefix}-lb-green-target"
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
    pool_name = "blue"
  }
}

resource "aws_lb_listener" "prod" {
  load_balancer_arn = "${aws_lb.main.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.blue.arn}"
  }
}

resource "aws_lb_listener" "stage" {
  load_balancer_arn = "${aws_lb.main.arn}"
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.green.arn}"
  }
}
