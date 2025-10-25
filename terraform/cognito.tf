########## COGNITO USER POOL ##########
resource "aws_cognito_user_pool" "hacktracker" {
  name = "hacktracker-${local.environment}"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_LINK"
    email_subject_by_link = "Welcome to HackTracker - Verify Your Email"
    email_message_by_link = <<-EOT
      <h2>Welcome to HackTracker!</h2>
      <p>Thanks for signing up. Please click the link below to verify your email address:</p>
      <p>{##Click here to verify##}</p>
      <p>If you didn't sign up for HackTracker, you can safely ignore this email.</p>
    EOT
  }

  lambda_config {
    post_confirmation = module.create_user_lambda.lambda_function_arn
  }

  tags = merge(local.common_tags, {
    Name = "HackTracker"
  })

  lifecycle {
    ignore_changes = [schema]
  }
}

########## COGNITO USER POOL CLIENT ##########
resource "aws_cognito_user_pool_client" "hacktracker" {
  name         = "hacktracker-${local.environment}-client"
  user_pool_id = aws_cognito_user_pool.hacktracker.id

  # Token expiration
  access_token_validity  = 1  # hour
  id_token_validity      = 1  # hour
  refresh_token_validity = 3650  # days (10 years for mobile)
  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  # Security
  prevent_user_existence_errors = "ENABLED"

  # Allow password auth (no OAuth needed for mobile app)
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]

  # Disable OAuth since we're using direct auth
  allowed_oauth_flows_user_pool_client = false
}

########## COGNITO DOMAIN ##########
resource "aws_cognito_user_pool_domain" "hacktracker" {
  domain       = "hacktracker-${local.environment}"
  user_pool_id = aws_cognito_user_pool.hacktracker.id
}

########## OUTPUTS ##########
output "cognito_user_pool_id" {
  value       = aws_cognito_user_pool.hacktracker.id
  description = "The ID of the Cognito User Pool"
}

output "cognito_user_pool_arn" {
  value       = aws_cognito_user_pool.hacktracker.arn
  description = "The ARN of the Cognito User Pool"
}

output "cognito_client_id" {
  value       = aws_cognito_user_pool_client.hacktracker.id
  description = "The ID of the Cognito User Pool Client"
}

output "cognito_domain" {
  value       = aws_cognito_user_pool_domain.hacktracker.domain
  description = "The Cognito domain for hosted UI (if needed)"
}