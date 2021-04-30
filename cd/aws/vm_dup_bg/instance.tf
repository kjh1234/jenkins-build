data "aws_ami" "main" {
#  owner_id = "${var.owner_id}"
  owners           = ["self"]
  most_recent      = true
  filter {
    name = "tag:Name"
    values = ["todo-app-${var.app_version}"]
  }
}
data "aws_ami" "ubuntu" {
    most_recent = true
    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    }
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
    owners = ["099720109477"]
}

resource "aws_instance" "main" {
  count = 2

  instance_type          = "t2.micro"
  subnet_id              = "${data.aws_subnet.main.id}"
  vpc_security_group_ids = ["${data.aws_security_group.main.id}"]
  key_name               = "test-key1"
#  ami = "ami-05e9bd7595a88caf3"
#  ami = "${data.aws_ami.main.id}"
  ami = "${data.aws_ami.ubuntu.id}"


  tags = {
    Name = "${var.prefix}-ec2-${var.pool_name}-${count.index}"
    group = "${var.app_resource_group_name}"
  }
}

resource "aws_lb_target_group_attachment" "main" {
  count = 2

  target_group_arn = "${aws_lb_target_group.main.arn}"
#  target_id        = "${element(aws_instance[${pool_name}], count.index).id}"
  target_id        = "${aws_instance.main[count.index].id}"
  port             = 8080
}

resource "aws_instance" "jumpbox" {

  instance_type          = "t2.micro"
  subnet_id              = "${data.aws_subnet.main.id}"
  vpc_security_group_ids = ["${data.aws_security_group.main.id}"]
  key_name               = "test-key1"
  ami = "${data.aws_ami.ubuntu.id}"

  tags = {
    Name = "${var.prefix}-ec2-jumpbox"
    group = "${var.app_resource_group_name}"
  }
}

resource "aws_eip" "jumpbox" {
  vpc = true
  instance                  = aws_instance.jumpbox.id
}
