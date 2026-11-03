run "verify_infrastructure_settings" {
  command = plan

  assert {
    condition     = aws_vpc.main.cidr_block == "10.0.0.0/16"
    error_message = "VPCのCIDRが想定値と異なります。"
  }

  assert {
    condition     = aws_subnet.public_az1.cidr_block == "10.0.10.0/24"
    error_message = "Public Subnet AZ1のCIDRが想定値と異なります。"
  }

  assert {
    condition     = aws_subnet.public_az1.availability_zone != aws_subnet.public_az2.availability_zone
    error_message = "2つのPublic Subnetが異なるAZに配置されていません。"
  }

  assert {
    condition     = aws_instance.app.instance_type == "t2.micro"
    error_message = "EC2のインスタンスタイプがt2.microではありません。"
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.alb_http.from_port == 80 && aws_vpc_security_group_ingress_rule.alb_http.to_port == 80
    error_message = "ALBのHTTP受信ポートが80番ではありません。"
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.rds_mysql_from_ec2.from_port == 3306 && aws_vpc_security_group_ingress_rule.rds_mysql_from_ec2.to_port == 3306
    error_message = "RDSのMySQL受信ポートが3306番ではありません。"
  }
}
