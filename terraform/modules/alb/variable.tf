variable "ami_id" {
  type = string
}

variable "app_sg_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "rds_endpoint" {
  type = string
}

variable "db_password_secret_name" {
  type = string
}

variable "region" {
  type = string
}

variable "instance_profile_name" {
  type = string
}

variable "uploads_bucket_name" {
  type = string
}