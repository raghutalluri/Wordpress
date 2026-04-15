resource "aws_key_pair" "wp_key" {
  key_name   = "wp-key"
  public_key = file("~/.ssh/wp-key.pub")
}

module "vpc" {
    source = "./modules/vpc"
}

module "iam" {
  source = "./modules/iam"
  uploads_bucket_arn = module.s3.bucket_arn
}

module "ec2" {
    source = "./modules/ec2"
    ami_id = "ami-04d7457c43c292911" 
    instance_type = "t3.micro"
    key_name = "wp-key"
    vpc_id = module.vpc.vpc_id
    public_subnet_id = module.vpc.public_subnet_id
    alb_sg_id = module.alb.alb_sg_id
}

module "rds" {
  source = "./modules/rds"

  vpc_id = module.vpc.vpc_id

  private_subnet_ids = [
    module.vpc.private_subnet_1_id,
    module.vpc.private_subnet_2_id
  ]

  app_sg_id = module.ec2.ec2_sg_id
}

module "alb" {
  source = "./modules/alb"

  ami_id = "ami-04d7457c43c292911" 

  app_sg_id = module.ec2.ec2_sg_id
  vpc_id    = module.vpc.vpc_id

  public_subnet_ids = module.vpc.public_subnet_ids
  rds_endpoint = module.rds.rds_endpoint
  db_password_secret_name = module.rds.db_password_secret_name
  region = var.region
  instance_profile_name = module.iam.instance_profile_name
  uploads_bucket_name = module.s3.bucket_name
}

module "cdn" {
  source = "./modules/cdn"

  alb_dns_name = module.alb.alb_dns_name
  alb_zone_id  = module.alb.alb_zone_id
}

module "s3" {
  source = "./modules/s3"

  bucket_name_prefix = "wordpress-uploads"
  region             = var.region
}

data "aws_instances" "wordpress_asg" {
  instance_tags = {
    Name = "wordpress-asg-instance"
  }

  instance_state_names = ["pending", "running"]

  filter {
    name   = "vpc-id"
    values = [module.vpc.vpc_id]
  }

  depends_on = [module.alb]
}
