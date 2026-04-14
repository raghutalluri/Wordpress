variable "ami_id" {
  description = "AMI ID for EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "vpc_id"{}
variable "public_subnet_id" {}

variable "key_name" {
  type = string
}

variable "alb_sg_id" {
  type = string
}
