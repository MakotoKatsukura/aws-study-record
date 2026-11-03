variable "aws_region" {
  description = "Terraformで操作するAWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" { # VPCやALBのNameタグへ使う共通名
  description = "Terraformで再構築する学習環境の名前接頭辞"
  type        = string
  default     = "terraform-cfn-rebuild"
}

variable "environment" {
  description = "構築する環境の区分"
  type        = string
  default     = "dev"
}

variable "ec2_instance_type" {
  description = "EC2で使用するインスタンスタイプ"
  type        = string
  default     = "t2.micro"
}

variable "db_instance_class" {
  description = "RDSで使用するインスタンスクラス"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "RDSに初期作成するデータベース名"
  type        = string
  default     = "sampledb"
}

variable "db_master_username" {
  description = "RDSのマスターユーザー名"
  type        = string
  default     = "admin"
}

variable "notification_email" {
  description = "CloudWatch Alarmの通知先メールアドレス"
  type        = string
  sensitive   = true
}
