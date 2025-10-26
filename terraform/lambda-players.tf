################################################################################
# Player Lambda Functions
################################################################################

# Add Player Lambda (API Gateway - POST /teams/{teamId}/players)
module "add_player_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.1"

  function_name = "hacktracker-add-player-${local.environment}"
  description   = "Add a ghost player to team roster"
  handler       = "handler.handler"
  runtime       = "python3.13"
  
  # Use pre-built package
  create_package         = false
  local_existing_package = "${path.module}/lambdas/players-add.zip"
  
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
    Name     = "add-player"
    Function = "roster-management"
  })
}

################################################################################
# List Players Lambda (API Gateway - GET /teams/{teamId}/players)
################################################################################

module "list_players_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.1"

  function_name = "hacktracker-list-players-${local.environment}"
  description   = "List all players on a team roster"
  handler       = "handler.handler"
  runtime       = "python3.13"
  
  create_package         = false
  local_existing_package = "${path.module}/lambdas/players-list.zip"
  
  timeout       = 30  # Longer timeout for potential large rosters
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
    Name     = "list-players"
    Function = "roster-management"
  })
}

################################################################################
# Get Player Lambda (API Gateway - GET /teams/{teamId}/players/{playerId})
################################################################################

module "get_player_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.1"

  function_name = "hacktracker-get-player-${local.environment}"
  description   = "Get a single player from team roster"
  handler       = "handler.handler"
  runtime       = "python3.13"
  
  create_package         = false
  local_existing_package = "${path.module}/lambdas/players-get.zip"
  
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
    Name     = "get-player"
    Function = "roster-management"
  })
}

################################################################################
# Update Player Lambda (API Gateway - PUT /teams/{teamId}/players/{playerId})
################################################################################

module "update_player_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.1"

  function_name = "hacktracker-update-player-${local.environment}"
  description   = "Update player information"
  handler       = "handler.handler"
  runtime       = "python3.13"
  
  create_package         = false
  local_existing_package = "${path.module}/lambdas/players-update.zip"
  
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
  
  cloudwatch_logs_retention_in_days = 7
  
  tags = merge(local.common_tags, {
    Name     = "update-player"
    Function = "roster-management"
  })
}

################################################################################
# Remove Player Lambda (API Gateway - DELETE /teams/{teamId}/players/{playerId})
################################################################################

module "remove_player_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.1"

  function_name = "hacktracker-remove-player-${local.environment}"
  description   = "Remove a ghost player from team roster"
  handler       = "handler.handler"
  runtime       = "python3.13"
  
  create_package         = false
  local_existing_package = "${path.module}/lambdas/players-remove.zip"
  
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
          "dynamodb:DeleteItem",
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
    Name     = "remove-player"
    Function = "roster-management"
  })
}

################################################################################
# Outputs - Player Lambdas
################################################################################

output "add_player_lambda_invoke_arn" {
  value       = module.add_player_lambda.lambda_function_invoke_arn
  description = "Invoke ARN of the Add Player Lambda function"
}

output "add_player_lambda_name" {
  value       = module.add_player_lambda.lambda_function_name
  description = "Name of the Add Player Lambda function"
}

output "list_players_lambda_invoke_arn" {
  value       = module.list_players_lambda.lambda_function_invoke_arn
  description = "Invoke ARN of the List Players Lambda function"
}

output "list_players_lambda_name" {
  value       = module.list_players_lambda.lambda_function_name
  description = "Name of the List Players Lambda function"
}

output "get_player_lambda_invoke_arn" {
  value       = module.get_player_lambda.lambda_function_invoke_arn
  description = "Invoke ARN of the Get Player Lambda function"
}

output "get_player_lambda_name" {
  value       = module.get_player_lambda.lambda_function_name
  description = "Name of the Get Player Lambda function"
}

output "update_player_lambda_invoke_arn" {
  value       = module.update_player_lambda.lambda_function_invoke_arn
  description = "Invoke ARN of the Update Player Lambda function"
}

output "update_player_lambda_name" {
  value       = module.update_player_lambda.lambda_function_name
  description = "Name of the Update Player Lambda function"
}

output "remove_player_lambda_invoke_arn" {
  value       = module.remove_player_lambda.lambda_function_invoke_arn
  description = "Invoke ARN of the Remove Player Lambda function"
}

output "remove_player_lambda_name" {
  value       = module.remove_player_lambda.lambda_function_name
  description = "Name of the Remove Player Lambda function"
}

