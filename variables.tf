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

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "availability_zones" {
  type    = list(string)
  default = ["eu-west-2a", "eu-west-2b"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "nat_instance_type" {
  type    = string
  default = "t2.micro"
  validation {
    condition     = contains(["t2.micro", "t4g.nano", "t4g.micro"], var.nat_instance_type)
    error_message = "Use Free Tier or cost-effective instance types."
  }
}

variable "bastion_instance_type" {
  type    = string
  default = "t2.micro"
  validation {
    condition     = contains(["t2.micro", "t3.micro", "t3.small"], var.bastion_instance_type)
    error_message = "Use Free Tier or cost-effective instance types."
  }
}

variable "key_pair_name" {
  description = "Name of the AWS key pair for EC2 instances"
  type        = string
  default     = "rsschool-devops-key"
}

variable "k3s_master_instance_type" {
  type    = string
  default = "t3.small"
  validation {
    condition     = contains(["t2.micro", "t3.micro", "t3.small"], var.k3s_master_instance_type)
    error_message = "Use Free Tier or cost-effective instance types."
  }
}

variable "k3s_worker_instance_type" {
  type    = string
  default = "t2.micro"
  validation {
    condition     = contains(["t2.micro", "t3.micro", "t3.small"], var.k3s_worker_instance_type)
    error_message = "Use Free Tier or cost-effective instance types."
  }
}

variable "k3s_cluster_name" {
  type    = string
  default = "rsschool-k3s"
}

variable "common_tags" {
  type = map(string)
  default = {
    Project     = "rsschool-devops"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
