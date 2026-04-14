output "rds_endpoint" {
  value = aws_db_instance.wordpress_db.endpoint
}

output "rds_sg_id" {
  value = aws_security_group.rds_sg.id
}

output "db_password_secret_arn" {
  value = aws_secretsmanager_secret.db_password.arn
}

output "db_password_secret_name" {
  value = aws_secretsmanager_secret.db_password.name
}