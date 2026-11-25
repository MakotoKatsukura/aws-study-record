output "app_public_ip" {
  description = "Public IP used by GitHub Actions to connect with SSH"
  value       = aws_instance.app.public_ip
}

output "app_security_group_id" {
  description = "Security group where GitHub Actions temporarily adds SSH access"
  value       = aws_security_group.app.id
}

output "alb_dns_name" {
  description = "Public address of the Hello AWS application"
  value       = aws_lb.app.dns_name
}
