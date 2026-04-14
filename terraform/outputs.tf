output "alb_dns_name" {
	value = module.alb.alb_dns_name
}

output "rds_endpoint" {
	value = module.rds.rds_endpoint
}

output "db_password_secret_name" {
	value = module.rds.db_password_secret_name
}

output "web_public_ips" {
	value = data.aws_instances.wordpress_asg.public_ips
}
