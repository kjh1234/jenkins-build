data "aws_ami" "main" {
#  owner_id = "${var.owner_id}"
  owners           = ["self"]
  most_recent      = true
  filter {
    name = "tag:Name"
    values = ["todo-app-${var.app_version}"]
  }
}

resource "aws_launch_template" "main" {
  name_prefix   = "todo-app-${var.app_version}"
  image_id      = "${data.aws_ami.main.id}"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${data.aws_security_group.main.id}"]

  tags = {
    group = "${var.app_resource_group_name}"
  }
}

resource "aws_autoscaling_group" "main" {
  availability_zones = ["ap-northeast-2${var.pool_name == "blue" ? "a": "c"}"]
  desired_capacity   = 2
  min_size           = 2
  max_size           = 5

  launch_template {
    id      = aws_launch_template.main.id
  }

  tags = [
    {
      "key"                 = "group"
      "value"               = "${var.app_resource_group_name}"
      "propagate_at_launch" = true
    },
    {
      "key"                 = "Name"
      "value"               = "${var.prefix}-${var.pool_name}"
      "propagate_at_launch" = true
    }
  ]
}

resource "aws_autoscaling_attachment" "stage" {
  autoscaling_group_name = "${aws_autoscaling_group.main.id}"
  alb_target_group_arn   = "${aws_lb_target_group.main.arn}"
}
