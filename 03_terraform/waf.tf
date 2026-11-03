# ================================================
# CloudWatch Logs Log Group：WAFアクセスログの保存先
# ================================================
# WAFの判定記録を後から調査できるよう保存先を作り、保存期間も指定する。
resource "aws_cloudwatch_log_group" "waf" {
  name              = "aws-waf-logs-${var.project_name}-${var.environment}"
  retention_in_days = 30

  tags = {
    Name = "aws-waf-logs-${var.project_name}-${var.environment}"
  }
}

# ================================================
# AWS WAF Web ACL：AWSマネージドルールをCOUNTで評価
# ================================================
# Web ACLに検査ルールをまとめる。マネージドルールはCOUNTにして、学習中の誤遮断を避けながら評価する。
resource "aws_wafv2_web_acl" "main" {
  name  = "${var.project_name}-${var.environment}-web-acl"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 0

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-${var.environment}-common-rule-set"
      sampled_requests_enabled   = true
    }


  }

  # ================================================
  # テスト専用ルール：指定URIだけ遮断する
  # ================================================
  # /waf-block-testへのアクセスでBLOCK動作を確認するための学習用ルール。
  rule {
    name     = "BlockWafTestPath"
    priority = 1

    action {
      block {}
    }

    statement {
      byte_match_statement {
        search_string         = "/waf-block-test"
        positional_constraint = "EXACTLY"

        field_to_match {
          uri_path {}
        }

        text_transformation {
          priority = 0
          type     = "NONE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BlockWafTestPath"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-${var.environment}-web-acl"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-web-acl"
  }
}

# ================================================
# Web ACL Association：Web ACLをALBへ関連付ける
# ================================================
# Web ACLをALBへ結び付け、ALBへ届くリクエストにWAFの検査を適用する。
resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = aws_lb.main.arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}

# ================================================
# WAF Logging Configuration：Web ACLのログをCloudWatch Logsへ送る
# ================================================
# Web ACLのログ送信先を指定し、許可・遮断などの判定を後から確認できるようにする。
resource "aws_wafv2_web_acl_logging_configuration" "main" {

  resource_arn            = aws_wafv2_web_acl.main.arn
  log_destination_configs = [aws_cloudwatch_log_group.waf.arn]

}
