variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "app_sg_id" {
  type = string
}

variable "db_name" {
  default = "wordpress"
}

variable "db_username" {
  default = "admin"
}