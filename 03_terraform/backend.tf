terraform {
  backend "s3" {
    bucket       = "tfstate-kura202609-apne1"
    key          = "terraform-cfn-rebuild/dev/terraform.tfstate"
    region       = "ap-northeast-1"
    encrypt      = true
    use_lockfile = true
  }
}