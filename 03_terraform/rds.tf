# ================================================
# RDS DB Subnet Group
# ================================================
# RDSを配置するSubnetを指定する。Private Subnetに限定してDBを公開ネットワークから分離する。

resource "aws_db_subnet_group" "main" {
  name        = "${var.project_name}-${var.environment}-db-subnet-group"
  description = "Private subnets for RDS"

  subnet_ids = [
    aws_subnet.private_az1.id,
    aws_subnet.private_az2.id
  ]

  tags = {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  }
}

# ================================================
# RDS MySQL Instance
# ================================================
# アプリケーションデータを保存するMySQLを作成する。学習用に小さな構成とし、公開アクセスは無効にする。

resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-${var.environment}-database"
  engine         = "mysql"
  instance_class = var.db_instance_class

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_master_username

  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  port                   = 3306

  multi_az                = false
  backup_retention_period = 0

  deletion_protection = false
  skip_final_snapshot = true

  tags = {
    Name = "${var.project_name}-${var.environment}-database"
  }
}
