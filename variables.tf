variable "aws_region" {
  type    = string
  default = "eu-west-2"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "bucket_name" {
  type    = string
  default = "rsschool-devops-terraform-lordofthevillage-e8d5e3f7"
}

variable "github_username" {
  type    = string
  default = "LordOfTheVillage"
}

variable "github_repository" {
  type    = string
  default = "rsschool-devops-course-tasks"
}

variable "project_name" {
  type    = string
  default = "rsschool-devops"
}
