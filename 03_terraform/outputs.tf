# Terraform apply後にALBの接続先を表示できるよう、DNS名を出力する。
output "alb_dns_name" {
  description = "ALBのDNS名"
  value       = aws_lb.main.dns_name
}
