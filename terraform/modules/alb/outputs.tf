output "alb_dns_name" {
  value = aws_lb.wp_alb.dns_name
}

output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}

output "alb_zone_id" {
  value = aws_lb.wp_alb.zone_id
}

