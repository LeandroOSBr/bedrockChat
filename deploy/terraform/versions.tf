terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket  = "techfin-tfstate-947675433597"
    key     = "bedrock-chat/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "TechFin-Bedrock-Chat"
      ManagedBy   = "Terraform"
      Environment = var.environment
      Course      = "Cloud-Computing-AI-Security"
    }
  }
}
