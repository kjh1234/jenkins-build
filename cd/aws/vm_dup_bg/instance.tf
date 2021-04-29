data "aws_ami" "main" {
  filter {
    name = "tag:Name"
    values = ["todo-app-${var.app_version}"]
  }
}

resource "aws_instance" "main" {
  count = 2

  instance_type          = "t2.micro"
  subnet_id              = "${data.aws_subnet.main.id}"
  vpc_security_group_ids = ["${data.aws_security_group.main.id}"]
  key_name               = "test-key1"
#  ami = "ami-05e9bd7595a88caf3"
  ami = "${aws_ami.main.id}"


  tags = {
    Name = "${var.prefix}-ec2-${pool_name}-${count.index}"
    group = "${var.app_resource_group_name}"
  }
}

resource "aws_lb_target_group_attachment" "main" {
  count = 2

  target_group_arn = "${aws_lb_target_group.stage.arn}"
#  target_id        = "${element(aws_instance[${pool_name}], count.index).id}"
  target_id        = "${aws_instance.main.id}"
  port             = 8080
}
