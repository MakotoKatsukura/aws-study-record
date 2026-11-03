terraform {
  required_version = ">= 1.16.0, < 2.0.0" # Terraform本体のバージョン条件

  required_providers { # AWS Providerのバージョン条件
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}