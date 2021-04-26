resource "aws_instance" "blue" {
  count = 2

  instance_type          = "t2.micro"
  subnet_id              = "${data.aws_subnet.blue.id}"
  vpc_security_group_ids = ["${data.aws_security_group.main.id}"]
  key_name               = "test-key1"
  ami = "ami-03bae193f36bb386d"

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
  ami = "ami-05e9bd7595a88caf3"

  tags = {
    Name = "${var.prefix}-ec2-green-${count.index}"
    group = "${var.app_resource_group_name}"
  }
}

resource "aws_lb_target_group_attachment" "prod" {
  count = 2

  target_group_arn = "${aws_lb_target_group.prod.arn}"
  target_id        = "${element(aws_instance.blue, count.index)}"
  port             = 8080
}

resource "aws_lb_target_group_attachment" "stage" {
  count = 2

  target_group_arn = "${aws_lb_target_group.stage.arn}"
  target_id        = "${element(aws_instance.green, count.index)}"
  port             = 8080
}
