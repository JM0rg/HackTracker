locals {

  environment = terraform.workspace == "hacktracker-prod" ? "prod" : "test"
  region      = "us-east-1"
  
  common_tags = {
    Project     = "HackTracker"
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
}

