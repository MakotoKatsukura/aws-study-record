provider "aws" {
  region = var.aws_region # variables.tfで作った値を参照 = Terraformで操作するAWSリージョン
}