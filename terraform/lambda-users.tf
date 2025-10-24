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
# Future User Lambda Functions
################################################################################

# TODO: Add additional user management Lambdas as needed:
# - Get User Lambda
# - Update User Lambda
# - Delete User Lambda
# - List Users Lambda

