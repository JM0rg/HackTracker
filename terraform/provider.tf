terraform {
  required_version = ">= 1.10"
  
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "JMorg"

    workspaces {
      prefix = "hacktracker-"
    }
  }
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project   = "HackTracker"
      ManagedBy = "Terraform"
    }
  }
}

