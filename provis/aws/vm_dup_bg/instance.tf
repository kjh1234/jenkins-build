resource "aws_instance" "blue" {
  count = 2

  instance_type          = "t2.micro"
  subnet_id              = "${data.aws_subnet.blue.id}"
  vpc_security_group_ids = ["${data.aws_security_group.main.id}"]
  key_name               = "test-key1"
  ami = "ami-04012241a2c8306de"

  tags = {
    Name = "${var.prefix}-ec2-blue-${count.index}"
    group = "${var.app_resource_group_name}"
  }
}

resource "aws_instance" "green" {
  count = 2

  instance_type          = "t2.micro"
  subnet_id              = "${data.aws_subnet.green.id}"
  vpc_security_group_ids = ["${data.aws_security_group.main.id}"]
  key_name               = "test-key1"
  ami = "ami-003c63cc36f639181"

  tags = {
    Name = "${var.prefix}-ec2-green-${count.index}"
    group = "${var.app_resource_group_name}"
  }
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
