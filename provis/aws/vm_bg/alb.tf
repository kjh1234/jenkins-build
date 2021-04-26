resource "aws_lb_target_group" "prod" {
  name   = "${var.prefix}-lb-prod-target"
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
