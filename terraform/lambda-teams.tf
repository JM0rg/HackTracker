################################################################################
# Team Lambda Functions
################################################################################

# Create Team Lambda (API Gateway - POST /teams)
module "create_team_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.1"

  function_name = "hacktracker-create-team-${local.environment}"
  description   = "Create a new team with owner membership"
  handler       = "handler.handler"
  runtime       = "python3.13"
  
  # Use pre-built package
  create_package         = false
  local_existing_package = "${path.module}/lambdas/teams-create.zip"
  
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
          "dynamodb:UpdateItem",
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
    Name     = "create-team"
    Function = "team-management"
  })
}

################################################################################
# Get Team Lambda (API Gateway - GET /teams/{teamId})
################################################################################

module "get_team_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.1"

  function_name = "hacktracker-get-team-${local.environment}"
  description   = "Retrieve a single team by ID"
  handler       = "handler.handler"
  runtime       = "python3.13"
  
  create_package         = false
  local_existing_package = "${path.module}/lambdas/teams-get.zip"
  
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
    Name     = "get-team"
    Function = "team-management"
  })
}

################################################################################
# Query Teams Lambda (API Gateway - GET /teams)
################################################################################

module "query_teams_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.1"

  function_name = "hacktracker-query-teams-${local.environment}"
  description   = "Query and list teams with various filters"
  handler       = "handler.handler"
  runtime       = "python3.13"
  
  create_package         = false
  local_existing_package = "${path.module}/lambdas/teams-query.zip"
  
  timeout       = 30
  memory_size   = 256
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
    Name     = "query-teams"
    Function = "team-management"
  })
}

################################################################################
# Update Team Lambda (API Gateway - PUT /teams/{teamId})
################################################################################

module "update_team_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.1"

  function_name = "hacktracker-update-team-${local.environment}"
  description   = "Update team information"
  handler       = "handler.handler"
  runtime       = "python3.13"
  
  create_package         = false
  local_existing_package = "${path.module}/lambdas/teams-update.zip"
  
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
    Name     = "update-team"
    Function = "team-management"
  })
}

################################################################################
# Delete Team Lambda (API Gateway - DELETE /teams/{teamId})
################################################################################

module "delete_team_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.1"

  function_name = "hacktracker-delete-team-${local.environment}"
  description   = "Soft delete a team"
  handler       = "handler.handler"
  runtime       = "python3.13"
  
  create_package         = false
  local_existing_package = "${path.module}/lambdas/teams-delete.zip"
  
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
    Name     = "delete-team"
    Function = "team-management"
  })
}

################################################################################
# Outputs - Team Lambdas
################################################################################

output "create_team_lambda_invoke_arn" {
  value       = module.create_team_lambda.lambda_function_invoke_arn
  description = "Invoke ARN of the Create Team Lambda function"
}

output "get_team_lambda_invoke_arn" {
  value       = module.get_team_lambda.lambda_function_invoke_arn
  description = "Invoke ARN of the Get Team Lambda function"
}

output "query_teams_lambda_invoke_arn" {
  value       = module.query_teams_lambda.lambda_function_invoke_arn
  description = "Invoke ARN of the Query Teams Lambda function"
}

output "update_team_lambda_invoke_arn" {
  value       = module.update_team_lambda.lambda_function_invoke_arn
  description = "Invoke ARN of the Update Team Lambda function"
}

output "delete_team_lambda_invoke_arn" {
  value       = module.delete_team_lambda.lambda_function_invoke_arn
  description = "Invoke ARN of the Delete Team Lambda function"
}

