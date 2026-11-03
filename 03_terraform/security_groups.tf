# ================================================
# ALB Security Group
# ================================================
# 通信制御を入口(ALB)に適用し、Webアクセスを受ける範囲をここで定義する。
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Allow HTTP traffic from the internet to ALB"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-sg"
  }
}

# ================================================
# EC2 Security Group
# ================================================
# EC2はALBからのHTTPだけを受ける設計にし、インターネットからの直接接続を避ける。
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-${var.environment}-ec2-sg"
  description = "Allow HTTP traffic from ALB to EC2"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-sg"
  }
}

# ================================================
# RDS Security Group
# ================================================
# DBはアプリ用EC2からのMySQL通信だけを許可する境界として使う。
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-${var.environment}-rds-sg"
  description = "Allow MySQL traffic from EC2 to RDS"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-rds-sg"
  }
}

# ================================================
# Ingress Rules
# ================================================
# ALBの受信許可：HTTP 80番をインターネットから受ける。学習用であり本番ではHTTPS化を検討する。
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "HTTP from internet"
}

# EC2の受信許可：送信元をALBのSecurity Groupに限定し、HTTPだけ通す。
resource "aws_vpc_security_group_ingress_rule" "ec2_http_from_alb" {
  security_group_id            = aws_security_group.ec2.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  description                  = "HTTP from ALB"
}

# RDSの受信許可：送信元をEC2のSecurity Groupに限定し、MySQLポートだけ通す。
resource "aws_vpc_security_group_ingress_rule" "rds_mysql_from_ec2" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.ec2.id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
  description                  = "MySQL from EC2"
}

# ================================================
# Egress Rules
# ================================================
# ALBの送信許可：応答やTarget Groupへの転送を可能にするため、外向き通信を許可する。
resource "aws_vpc_security_group_egress_rule" "alb_all_ipv4" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# EC2の送信許可：パッケージ取得やSystems Manager接続などの外向き通信に使う。
resource "aws_vpc_security_group_egress_rule" "ec2_all_ipv4" {
  security_group_id = aws_security_group.ec2.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# RDSの送信許可：学習環境では既定相当の全IPv4向け送信を明示。最小権限では用途別に絞る。
resource "aws_vpc_security_group_egress_rule" "rds_all_ipv4" {
  security_group_id = aws_security_group.rds.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
