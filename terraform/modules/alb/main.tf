resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_lb_target_group" "wp_tg" {
  name     = "wp-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path = "/"
    port = "traffic-port"
  }
}


resource "aws_lb" "wp_alb" {
  name               = "wp-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnet_ids
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.wp_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wp_tg.arn
  }
}

resource "aws_launch_template" "wp_lt" {
  name_prefix   = "wp-template"
  image_id      = var.ami_id
  key_name      = "wp-key"
  instance_type = "t3.micro"

  iam_instance_profile {
    name = var.instance_profile_name
  }

  vpc_security_group_ids = [var.app_sg_id]

  user_data = base64encode(templatefile("${path.module}/userdata.sh", {}))

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "wordpress-instance"
    }
  }
}

resource "aws_autoscaling_group" "wp_asg" {
  desired_capacity = 2
  max_size         = 2
  min_size         = 1

  vpc_zone_identifier = var.public_subnet_ids

  launch_template {
    id      = aws_launch_template.wp_lt.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.wp_tg.arn]

  tag {
    key                 = "Name"
    value               = "wordpress-asg-instance"
    propagate_at_launch = true
  }
}
