# resource "aws_instance" "web" {
#   ami           = var.ami_id
#   instance_type = var.instance_type

#   subnet_id     = var.public_subnet_id
#   vpc_security_group_ids = [aws_security_group.ec2_sg.id]
#   associate_public_ip_address = true

#   key_name = var.key_name

#   tags = {
#     Name = "WP_WebServer"
#   }
# }

resource "aws_security_group" "ec2_sg" {
  name        = "ec2_sg"
  description = "Allow HTTP and SSH traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["67.70.90.79/32"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
