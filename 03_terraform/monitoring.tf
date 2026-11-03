# ================================================
# SNS Topic：アラーム通知を受け取るSNSトピック
# ================================================
# 通知先をTopicに集約すると、監視設定とメール宛先を分けて管理できる。
resource "aws_sns_topic" "monitoring" {
  name = "${var.project_name}-${var.environment}-monitoring-topic"

  tags = {
    Name = "${var.project_name}-${var.environment}-monitoring-topic"
  }
}

# ================================================
# SNS Email Subscription：SNSトピックへのメール通知購読
# ================================================
# Topicからメールを届ける購読設定。受信者が確認メールで承認して初めて配信される。
resource "aws_sns_topic_subscription" "alarm_email" {
  topic_arn = aws_sns_topic.monitoring.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# ================================================
# CloudWatch Alarm：EC2のCPU使用率監視
# ================================================
# CPU使用率を一定期間評価し、しきい値を超えた状態を検知したときSNSへ通知する。
resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  alarm_name        = "${var.project_name}-${var.environment}-ec2-cpu-utilization-alarm"
  alarm_description = "EC2のCPU使用率が70%以上の状態を検知する"

  namespace   = "AWS/EC2"
  metric_name = "CPUUtilization"
  dimensions = {
    InstanceId = aws_instance.app.id
  }
  unit      = "Percent"
  period    = 300
  statistic = "Average"

  threshold           = 70
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  treat_missing_data  = "missing"

  alarm_actions = [aws_sns_topic.monitoring.arn]

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-cpu-alarm"
  }
}
