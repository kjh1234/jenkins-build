resource "aws_launch_template" "blue" {
  name_prefix   = "todo-app-1.0.0"
  image_id      = "ami-03bae193f36bb386d"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${data.aws_security_group.main.id}"]

  tags = {
    group = "${var.app_resource_group_name}"
  }
}

resource "aws_launch_template" "green" {
  name_prefix   = "todo-app-1.0.1"
  image_id      = "ami-05e9bd7595a88caf3"
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
    },
    {
      "key"                 = "Name"
      "value"               = "${var.prefix}-blue"
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
    },
    {
      "key"                 = "Name"
      "value"               = "${var.prefix}-green"
      "propagate_at_launch" = true
    }
  ]
}

resource "aws_autoscaling_attachment" "blue" {
  autoscaling_group_name = "${aws_autoscaling_group.blue.id}"
  alb_target_group_arn   = "${aws_lb_target_group.blue.arn}"
}

resource "aws_autoscaling_attachment" "green" {
  autoscaling_group_name = "${aws_autoscaling_group.green.id}"
  alb_target_group_arn   = "${aws_lb_target_group.green.arn}"
}
