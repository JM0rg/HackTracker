########## POST CONFIRMATION LAMBDA ##########
module "post_confirmation_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.1.0"

  function_name = "hacktracker-${local.environment}-post-confirmation"
  description   = "Creates user profile in DynamoDB after Cognito signup"
  handler       = "index.handler"
  runtime       = "python3.12"
  timeout       = 10
  memory_size   = 256  # Adequate for simple DynamoDB writes

  source_path = [
    {
      path = "${path.module}/lambda/post-confirmation"
      pip_requirements = true
    },
    {
      path             = "${path.module}/lambda/shared"
      prefix_in_zip    = "shared"
      patterns         = ["!\\.pyc$", "!__pycache__"]
    }
  ]

  # Only version in prod, use $LATEST for dev/test
  publish                                 = local.environment == "prod"
  create_current_version_allowed_triggers = false

  environment_variables = {
    DYNAMODB_TABLE = aws_dynamodb_table.hacktracker.name
  }

  attach_policy_statements = true
  policy_statements = {
    dynamodb_access = {
      effect = "Allow"
      actions = [
        "dynamodb:PutItem",
        "dynamodb:Query"
      ]
      resources = [
        aws_dynamodb_table.hacktracker.arn,
        "${aws_dynamodb_table.hacktracker.arn}/index/*"
      ]
    }
  }

  allowed_triggers = {
    cognito = {
      principal  = "cognito-idp.amazonaws.com"
      source_arn = aws_cognito_user_pool.hacktracker.arn
    }
  }

  tags = merge(local.common_tags, {
    Name = "HackTracker PostConfirmation"
  })
}

########## TEAMS LAMBDA ##########
module "teams_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.1.0"

  function_name = "hacktracker-${local.environment}-teams"
  description   = "Handles team CRUD operations"
  handler       = "index.handler"
  runtime       = "python3.12"
  timeout       = 15
  memory_size   = 512  # More memory for query operations and batch gets

  source_path = [
    {
      path = "${path.module}/lambda/teams"
      pip_requirements = true
    },
    {
      path             = "${path.module}/lambda/shared"
      prefix_in_zip    = "shared"
      patterns         = ["!\\.pyc$", "!__pycache__"]
    }
  ]

  publish                                 = local.environment == "prod"
  create_current_version_allowed_triggers = false

  environment_variables = {
    DYNAMODB_TABLE = aws_dynamodb_table.hacktracker.name
  }

  attach_policy_statements = true
  policy_statements = {
    dynamodb_access = {
      effect = "Allow"
      actions = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query",
        "dynamodb:BatchGetItem"
      ]
      resources = [
        aws_dynamodb_table.hacktracker.arn,
        "${aws_dynamodb_table.hacktracker.arn}/index/*"
      ]
    }
  }

  allowed_triggers = {
    apigateway = {
      service    = "apigateway"
      source_arn = "${module.api_gateway.api_execution_arn}/*/*"
    }
  }

  tags = merge(local.common_tags, {
    Name = "HackTracker Teams"
  })
}

########## OUTPUTS ##########
output "post_confirmation_lambda_arn" {
  value       = module.post_confirmation_lambda.lambda_function_arn
  description = "The ARN of the postConfirmation Lambda function"
}

output "post_confirmation_lambda_name" {
  value       = module.post_confirmation_lambda.lambda_function_name
  description = "The name of the postConfirmation Lambda function"
}

output "teams_lambda_arn" {
  value       = module.teams_lambda.lambda_function_arn
  description = "The ARN of the teams Lambda function"
}

output "teams_lambda_name" {
  value       = module.teams_lambda.lambda_function_name
  description = "The name of the teams Lambda function"
}
