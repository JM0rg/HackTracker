################################################################################
# AtBat Lambda Functions
################################################################################

# Create AtBat Lambda (API Gateway - POST /games/{gameId}/atbats)
module "create_atbat_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.1"

  function_name = "hacktracker-create-atbat-${local.environment}"
  description   = "Create a new at-bat for a game"
  handler       = "handler.handler"
  runtime       = "python3.13"
  
  # Use pre-built package
  create_package         = false
  local_existing_package = "${path.module}/lambdas/atbats-create.zip"
  
  # Lambda configuration
  timeout       = 10
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
          "dynamodb:Query"
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
    Name     = "create-atbat"
    Function = "stat-tracking"
  })
}

################################################################################
# List AtBats Lambda (API Gateway - GET /games/{gameId}/atbats)
################################################################################

module "list_atbats_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.1"

  function_name = "hacktracker-list-atbats-${local.environment}"
  description   = "List all at-bats for a game"
  handler       = "handler.handler"
  runtime       = "python3.13"
  
  create_package         = false
  local_existing_package = "${path.module}/lambdas/atbats-list.zip"
  
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
          "dynamodb:Query"
        ]
        Resource = [
          aws_dynamodb_table.hacktracker.arn,
          "${aws_dynamodb_table.hacktracker.arn}/index/*"
        ]
      }
    ]
  })
  
  cloudwatch_logs_retention_in_days = 7
  
  tags = merge(local.common_tags, {
    Name     = "list-atbats"
    Function = "stat-tracking"
  })
}

################################################################################
# Get AtBat Lambda (API Gateway - GET /games/{gameId}/atbats/{atBatId})
################################################################################

module "get_atbat_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.1"

  function_name = "hacktracker-get-atbat-${local.environment}"
  description   = "Retrieve a single at-bat by ID"
  handler       = "handler.handler"
  runtime       = "python3.13"
  
  create_package         = false
  local_existing_package = "${path.module}/lambdas/atbats-get.zip"
  
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
          "dynamodb:GetItem"
        ]
        Resource = aws_dynamodb_table.hacktracker.arn
      }
    ]
  })
  
  cloudwatch_logs_retention_in_days = 7
  
  tags = merge(local.common_tags, {
    Name     = "get-atbat"
    Function = "stat-tracking"
  })
}

################################################################################
# Update AtBat Lambda (API Gateway - PUT /games/{gameId}/atbats/{atBatId})
################################################################################

module "update_atbat_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.1"

  function_name = "hacktracker-update-atbat-${local.environment}"
  description   = "Update at-bat information"
  handler       = "handler.handler"
  runtime       = "python3.13"
  
  create_package         = false
  local_existing_package = "${path.module}/lambdas/atbats-update.zip"
  
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
  
  cloudwatch_logs_retention_in_days = 7
  
  tags = merge(local.common_tags, {
    Name     = "update-atbat"
    Function = "stat-tracking"
  })
}

################################################################################
# Delete AtBat Lambda (API Gateway - DELETE /games/{gameId}/atbats/{atBatId})
################################################################################

module "delete_atbat_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.1"

  function_name = "hacktracker-delete-atbat-${local.environment}"
  description   = "Delete an at-bat"
  handler       = "handler.handler"
  runtime       = "python3.13"
  
  create_package         = false
  local_existing_package = "${path.module}/lambdas/atbats-delete.zip"
  
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
  
  cloudwatch_logs_retention_in_days = 7
  
  tags = merge(local.common_tags, {
    Name     = "delete-atbat"
    Function = "stat-tracking"
  })
}

################################################################################
# Outputs - AtBat Lambdas
################################################################################

output "create_atbat_lambda_invoke_arn" {
  value       = module.create_atbat_lambda.lambda_function_invoke_arn
  description = "Invoke ARN of the Create AtBat Lambda function"
}

output "list_atbats_lambda_invoke_arn" {
  value       = module.list_atbats_lambda.lambda_function_invoke_arn
  description = "Invoke ARN of the List AtBats Lambda function"
}

output "get_atbat_lambda_invoke_arn" {
  value       = module.get_atbat_lambda.lambda_function_invoke_arn
  description = "Invoke ARN of the Get AtBat Lambda function"
}

output "update_atbat_lambda_invoke_arn" {
  value       = module.update_atbat_lambda.lambda_function_invoke_arn
  description = "Invoke ARN of the Update AtBat Lambda function"
}

output "delete_atbat_lambda_invoke_arn" {
  value       = module.delete_atbat_lambda.lambda_function_invoke_arn
  description = "Invoke ARN of the Delete AtBat Lambda function"
}

