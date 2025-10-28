################################################################################
# Game Lambda Functions
################################################################################

# Create Game Lambda (API Gateway - POST /games)
module "create_game_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.1"

  function_name = "hacktracker-create-game-${local.environment}"
  description   = "Create a new game"
  handler       = "handler.handler"
  runtime       = "python3.13"
  
  # Use pre-built package
  create_package         = false
  local_existing_package = "${path.module}/lambdas/games-create.zip"
  
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
    Name     = "create-game"
    Function = "game-management"
  })
}

################################################################################
# List Games by Team Lambda (API Gateway - GET /teams/{teamId}/games)
################################################################################

module "list_games_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.1"

  function_name = "hacktracker-list-games-${local.environment}"
  description   = "List all games for a specific team"
  handler       = "handler.handler"
  runtime       = "python3.13"
  
  create_package         = false
  local_existing_package = "${path.module}/lambdas/games-list.zip"
  
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
    Name     = "list-games"
    Function = "game-management"
  })
}

################################################################################
# Get Game Lambda (API Gateway - GET /games/{gameId})
################################################################################

module "get_game_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.1"

  function_name = "hacktracker-get-game-${local.environment}"
  description   = "Retrieve a single game by ID"
  handler       = "handler.handler"
  runtime       = "python3.13"
  
  create_package         = false
  local_existing_package = "${path.module}/lambdas/games-get.zip"
  
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
    Name     = "get-game"
    Function = "game-management"
  })
}

################################################################################
# Update Game Lambda (API Gateway - PATCH /games/{gameId})
################################################################################

module "update_game_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.1"

  function_name = "hacktracker-update-game-${local.environment}"
  description   = "Update game information"
  handler       = "handler.handler"
  runtime       = "python3.13"
  
  create_package         = false
  local_existing_package = "${path.module}/lambdas/games-update.zip"
  
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
    Name     = "update-game"
    Function = "game-management"
  })
}

################################################################################
# Delete Game Lambda (API Gateway - DELETE /games/{gameId})
################################################################################

module "delete_game_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.1"

  function_name = "hacktracker-delete-game-${local.environment}"
  description   = "Delete a game"
  handler       = "handler.handler"
  runtime       = "python3.13"
  
  create_package         = false
  local_existing_package = "${path.module}/lambdas/games-delete.zip"
  
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
    Name     = "delete-game"
    Function = "game-management"
  })
}

################################################################################
# Outputs - Game Lambdas
################################################################################

output "create_game_lambda_invoke_arn" {
  value       = module.create_game_lambda.lambda_function_invoke_arn
  description = "Invoke ARN of the Create Game Lambda function"
}

output "list_games_lambda_invoke_arn" {
  value       = module.list_games_lambda.lambda_function_invoke_arn
  description = "Invoke ARN of the List Games Lambda function"
}

output "get_game_lambda_invoke_arn" {
  value       = module.get_game_lambda.lambda_function_invoke_arn
  description = "Invoke ARN of the Get Game Lambda function"
}

output "update_game_lambda_invoke_arn" {
  value       = module.update_game_lambda.lambda_function_invoke_arn
  description = "Invoke ARN of the Update Game Lambda function"
}

output "delete_game_lambda_invoke_arn" {
  value       = module.delete_game_lambda.lambda_function_invoke_arn
  description = "Invoke ARN of the Delete Game Lambda function"
}
