locals {
  # Extract environment from workspace name
  # Workspace: "hacktracker-dev" -> env: "dev"
  # Workspace: "hacktracker-test" -> env: "test"
  # Workspace: "hacktracker-prod" -> env: "prod"
  environment = replace(terraform.workspace, "hacktracker-", "")

  # Common tags
  common_tags = {
    Project     = "HackTracker"
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
}

