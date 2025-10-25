################################################################################
# User Lambda Functions
################################################################################

# Create User Lambda (Cognito Post-Confirmation Trigger)
module "create_user_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.1"

  function_name = "hacktracker-create-user-${local.environment}"
  description   = "Cognito post-confirmation trigger to create user in DynamoDB"
  handler       = "handler.handler"
  runtime       = "python3.13"
  
  # Use pre-built package
  create_package         = false
  local_existing_package = "${path.module}/lambdas/users-create.zip"
  
  # Lambda configuration
  timeout       = 30
  memory_size   = 128
  architectures = ["arm64"]
  
  # Environment variables
  environment_variables = {
    TABLE_NAME  = aws_dynamodb_table.hacktracker.name
    ENVIRONMENT = local.environment
  }
  
  # IAM permissions
  attach_policy_json = true
  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.hacktracker.arn,
          "${aws_dynamodb_table.hacktracker.arn}/index/*"
        ]
      }
    ]
  })
  
  # CloudWatch Logs
  cloudwatch_logs_retention_in_days = 7
  
  # Tags
  tags = merge(local.common_tags, {
    Name     = "create-user"
    Function = "cognito-post-confirmation"
  })
}

################################################################################
# Outputs - User Lambdas
################################################################################

output "create_user_lambda_arn" {
  value       = module.create_user_lambda.lambda_function_arn
  description = "ARN of the Create User Lambda function (for Cognito trigger)"
}

output "create_user_lambda_name" {
  value       = module.create_user_lambda.lambda_function_name
  description = "Name of the Create User Lambda function"
}

output "create_user_lambda_invoke_arn" {
  value       = module.create_user_lambda.lambda_function_invoke_arn
  description = "Invoke ARN of the Create User Lambda function"
}

################################################################################
# Get User Lambda (API Gateway - GET /users/{userId})
################################################################################

module "get_user_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.1"

  function_name = "hacktracker-get-user-${local.environment}"
  description   = "Get a single user by userId"
  handler       = "handler.handler"
  runtime       = "python3.13"
  
  # Use pre-built package
  create_package         = false
  local_existing_package = "${path.module}/lambdas/users-get.zip"
  
  # Lambda configuration
  timeout       = 10
  memory_size   = 128
  architectures = ["arm64"]
  
  # Environment variables
  environment_variables = {
    TABLE_NAME  = aws_dynamodb_table.hacktracker.name
    ENVIRONMENT = local.environment
  }
  
  # IAM permissions (read-only)
  attach_policy_json = true
  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem"
        ]
        Resource = aws_dynamodb_table.hacktracker.arn
      }
    ]
  })
  
  # CloudWatch Logs
  cloudwatch_logs_retention_in_days = 7
  
  # Tags
  tags = merge(local.common_tags, {
    Name     = "get-user"
    Function = "api-get-user"
  })
}

################################################################################
# Query Users Lambda (API Gateway - GET /users with filters)
################################################################################

module "query_users_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.1"

  function_name = "hacktracker-query-users-${local.environment}"
  description   = "Query/list users with various filters"
  handler       = "handler.handler"
  runtime       = "python3.13"
  
  # Use pre-built package
  create_package         = false
  local_existing_package = "${path.module}/lambdas/users-query.zip"
  
  # Lambda configuration
  timeout       = 30
  memory_size   = 256
  architectures = ["arm64"]
  
  # Environment variables
  environment_variables = {
    TABLE_NAME  = aws_dynamodb_table.hacktracker.name
    ENVIRONMENT = local.environment
  }
  
  # IAM permissions (read-only with GSI access)
  attach_policy_json = true
  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.hacktracker.arn,
          "${aws_dynamodb_table.hacktracker.arn}/index/*"
        ]
      }
    ]
  })
  
  # CloudWatch Logs
  cloudwatch_logs_retention_in_days = 7
  
  # Tags
  tags = merge(local.common_tags, {
    Name     = "query-users"
    Function = "api-query-users"
  })
}

################################################################################
# Update User Lambda
################################################################################

module "update_user_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.1"

  function_name = "hacktracker-update-user-${local.environment}"
  description   = "Update user information"
  handler       = "handler.handler"
  runtime       = "python3.13"

  create_package         = false
  local_existing_package = "${path.module}/lambdas/users-update.zip"

  timeout       = 10
  memory_size   = 128
  architectures = ["arm64"]

  environment_variables = {
    TABLE_NAME  = aws_dynamodb_table.hacktracker.name
    ENVIRONMENT = local.environment
  }

  attach_policy_json = true
  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:UpdateItem"
        ]
        Resource = aws_dynamodb_table.hacktracker.arn
      }
    ]
  })

  # CloudWatch Logs
  cloudwatch_logs_retention_in_days = 7

  # Tags
  tags = merge(local.common_tags, {
    Name     = "update-user"
    Function = "api-update-user"
  })
}

################################################################################
# Delete User Lambda
################################################################################

module "delete_user_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.1"

  function_name = "hacktracker-delete-user-${local.environment}"
  description   = "Delete user"
  handler       = "handler.handler"
  runtime       = "python3.13"

  create_package         = false
  local_existing_package = "${path.module}/lambdas/users-delete.zip"

  timeout       = 10
  memory_size   = 128
  architectures = ["arm64"]

  environment_variables = {
    TABLE_NAME  = aws_dynamodb_table.hacktracker.name
    ENVIRONMENT = local.environment
  }

  attach_policy_json = true
  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:DeleteItem"
        ]
        Resource = aws_dynamodb_table.hacktracker.arn
      }
    ]
  })

  # CloudWatch Logs
  cloudwatch_logs_retention_in_days = 7

  # Tags
  tags = merge(local.common_tags, {
    Name     = "delete-user"
    Function = "api-delete-user"
  })
}

################################################################################
# Additional Outputs
################################################################################

output "get_user_lambda_arn" {
  value       = module.get_user_lambda.lambda_function_arn
  description = "ARN of the Get User Lambda function"
}

output "get_user_lambda_invoke_arn" {
  value       = module.get_user_lambda.lambda_function_invoke_arn
  description = "Invoke ARN of the Get User Lambda function (for API Gateway)"
}

output "query_users_lambda_arn" {
  value       = module.query_users_lambda.lambda_function_arn
  description = "ARN of the Query Users Lambda function"
}

output "query_users_lambda_invoke_arn" {
  value       = module.query_users_lambda.lambda_function_invoke_arn
  description = "Invoke ARN of the Query Users Lambda function (for API Gateway)"
}

output "update_user_lambda_arn" {
  value       = module.update_user_lambda.lambda_function_arn
  description = "ARN of the Update User Lambda function"
}

output "update_user_lambda_invoke_arn" {
  value       = module.update_user_lambda.lambda_function_invoke_arn
  description = "Invoke ARN of the Update User Lambda function (for API Gateway)"
}

output "delete_user_lambda_arn" {
  value       = module.delete_user_lambda.lambda_function_arn
  description = "ARN of the Delete User Lambda function"
}

output "delete_user_lambda_invoke_arn" {
  value       = module.delete_user_lambda.lambda_function_invoke_arn
  description = "Invoke ARN of the Delete User Lambda function (for API Gateway)"
}

