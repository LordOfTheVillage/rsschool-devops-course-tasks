terraform {
  backend "s3" {
    bucket  = "rsschool-devops-terraform-lordofthevillage-e8d5e3f7"
    key     = "env/dev/terraform.tfstate"
    region  = "eu-west-2"
    encrypt = true
  }
}