locals {

  environment = terraform.workspace == "hacktracker-prod" ? "prod" : "test"
  
  common_tags = {
    Project     = "HackTracker"
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
}

