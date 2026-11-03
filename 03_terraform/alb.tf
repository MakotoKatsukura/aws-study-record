# ================================================
# Application Load Balancer：インターネットからHTTPを受ける入口
# ================================================
# ALBを入口に置くことで、利用者の通信をEC2へ直接さらさずに集約できる。
resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"

  # ALBに入口用Security Groupと2つのPublic Subnetを割り当てる
  security_groups = [aws_security_group.alb.id]
  subnets = [
    aws_subnet.public_az1.id,
    aws_subnet.public_az2.id
  ]

  # 学習環境のため削除保護は無効にする
  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-${var.environment}-alb"
  }
}

# ================================================
# Target Group：ALBが転送するEC2と正常性確認の方法
# ================================================
# 転送先とHealth Checkを分けて管理し、ALBからEC2への振り分けを設定する。
resource "aws_lb_target_group" "app" {
  name        = "${var.project_name}-${var.environment}-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id

  health_check {
    protocol = "HTTP"
    path     = "/"
    port     = "traffic-port"
    matcher  = "200"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-target-group"
  }
}

# ================================================
# Target Group Attachment：アプリ用EC2を転送先へ登録
# ================================================
# Target Groupだけでは転送先が決まらないため、作成したEC2を明示的に登録する。
resource "aws_lb_target_group_attachment" "app" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app.id
  port             = 80
}

# ================================================
# HTTP Listener：ALBで受けたHTTP通信をTarget Groupへ転送
# ================================================
# Listenerが受信ポートと転送先を結び付け、ALBの入口として働く。
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
