# ================================================
# EC2用 IAM Role
# ================================================
# EC2にAWS上の操作権限を持たせるための役割を用意する。認証情報をインスタンスへ直接置かずに済む。

resource "aws_iam_role" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2-role"

  # EC2サービスがこのRoleを引き受けることを許可する
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-role"
  }
}

# ================================================
# Session Manager用ポリシー
# ================================================
# Systems Manager経由でEC2へ接続するため、AWS管理ポリシーをRoleへ付与する。

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ================================================
# EC2へIAM Roleを渡すInstance Profile
# ================================================
# EC2へRoleを関連付けるための入れ物。EC2にはRole名ではなくInstance Profileを指定する。

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2.name

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-profile"
  }
}

# ================================================
# Amazon Linux 2023 AMIを取得
# ================================================
# AMI IDを固定値で書かず、AWS Systems Manager Parameter Storeから最新の標準AMIを取得する。

data "aws_ssm_parameter" "amazon_linux_2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# ================================================
# Private SubnetのEC2
# ================================================
# アプリをPrivate Subnetで稼働させ、インターネットからEC2へ直接到達できない構成にする。

resource "aws_instance" "app" {
  ami                    = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type          = var.ec2_instance_type
  subnet_id              = aws_subnet.private_az2.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name

  # このEC2にPublic IPv4を割り当てない
  associate_public_ip_address = false

  user_data = <<-EOF
    #!/bin/bash
    set -eux
    dnf update -y
    dnf install -y httpd
    systemctl enable httpd
    systemctl start httpd
    echo "It works from EC2" > /var/www/html/index.html
  EOF

  # SSM用ポリシーとPrivate Subnetから外へ出る経路の準備後に作成
  depends_on = [
    aws_iam_role_policy_attachment.ssm_core,
    aws_route.private_default
  ]

  tags = {
    Name = "${var.project_name}-${var.environment}-app-ec2"
  }
}
