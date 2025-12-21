terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.27.0"
    }
  }

  backend "s3" {
    bucket         = "devops-homeinblock-tf-state"
    key            = "tf-state-setup"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "devops-homeinblock-tf-lock"
  }
}

provider "aws" {
  region = "us-west-2"
  default_tags {
    tags = {
      Environment = terraform.workspace
      Project     = var.project
      Contact     = var.contact
      ManagedBy   = "Terraform/setup"
    }
  }
}