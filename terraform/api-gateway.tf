################################################################################
# API Gateway HTTP API
################################################################################

module "api_gateway" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "~> 5.4.1"

  name          = "hacktracker-api-${local.environment}"
  description   = "HackTracker API Gateway"
  protocol_type = "HTTP"

  # CORS configuration
  cors_configuration = {
    allow_headers = [
      "content-type",
      "x-amz-date",
      "authorization",
      "x-api-key",
      "x-amz-security-token",
      "x-amz-user-agent"
    ]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_origins = ["*"] # TODO: Restrict to frontend domain in production
  }

  # Disable custom domain for now
  create_domain_name = false

  # Access logs
  stage_access_log_settings = {
    create_log_group            = true
    log_group_retention_in_days = 7
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
      errorMessage   = "$context.error.message"
    })
  }

  # Default stage settings
  stage_default_route_settings = {
    data_trace_enabled       = true
    detailed_metrics_enabled = true
    logging_level            = "INFO"
    throttling_burst_limit   = 500
    throttling_rate_limit    = 1000
  }

  # JWT Authorizer
  authorizers = {
    "cognito" = {
      authorizer_type  = "JWT"
      identity_sources = ["$request.header.Authorization"]
      name             = "cognito-authorizer"
      jwt_configuration = {
        audience = [aws_cognito_user_pool_client.hacktracker.id]
        issuer   = "https://cognito-idp.${local.region}.amazonaws.com/${aws_cognito_user_pool.hacktracker.id}"
      }
    }
  }

  # Routes and integrations
  routes = {
    # Get User by ID
    "GET /users/{userId}" = {
      authorization_type = "JWT"
      authorizer_key     = "cognito"
      integration = {
        uri                    = module.get_user_lambda.lambda_function_invoke_arn
        payload_format_version = "2.0"
        timeout_milliseconds   = 10000
      }
    }

    # Query/List Users
    "GET /users" = {
      authorization_type = "JWT"
      authorizer_key     = "cognito"
      integration = {
        uri                    = module.query_users_lambda.lambda_function_invoke_arn
        payload_format_version = "2.0"
        timeout_milliseconds   = 30000
      }
    }

    # Update User
    "PUT /users/{userId}" = {
      authorization_type = "JWT"
      authorizer_key     = "cognito"
      integration = {
        uri                    = module.update_user_lambda.lambda_function_invoke_arn
        payload_format_version = "2.0"
        timeout_milliseconds   = 10000
      }
    }

    # Delete User
    "DELETE /users/{userId}" = {
      authorization_type = "JWT"
      authorizer_key     = "cognito"
      integration = {
        uri                    = module.delete_user_lambda.lambda_function_invoke_arn
        payload_format_version = "2.0"
        timeout_milliseconds   = 10000
      }
    }

    # Create Team
    "POST /teams" = {
      authorization_type = "JWT"
      authorizer_key     = "cognito"
      integration = {
        uri                    = module.create_team_lambda.lambda_function_invoke_arn
        payload_format_version = "2.0"
        timeout_milliseconds   = 10000
      }
    }

    # Get Team by ID
    "GET /teams/{teamId}" = {
      authorization_type = "JWT"
      authorizer_key     = "cognito"
      integration = {
        uri                    = module.get_team_lambda.lambda_function_invoke_arn
        payload_format_version = "2.0"
        timeout_milliseconds   = 10000
      }
    }

    # Query/List Teams
    "GET /teams" = {
      authorization_type = "JWT"
      authorizer_key     = "cognito"
      integration = {
        uri                    = module.query_teams_lambda.lambda_function_invoke_arn
        payload_format_version = "2.0"
        timeout_milliseconds   = 30000
      }
    }

    # Update Team
    "PUT /teams/{teamId}" = {
      authorization_type = "JWT"
      authorizer_key     = "cognito"
      integration = {
        uri                    = module.update_team_lambda.lambda_function_invoke_arn
        payload_format_version = "2.0"
        timeout_milliseconds   = 10000
      }
    }

    # Delete Team
    "DELETE /teams/{teamId}" = {
      authorization_type = "JWT"
      authorizer_key     = "cognito"
      integration = {
        uri                    = module.delete_team_lambda.lambda_function_invoke_arn
        payload_format_version = "2.0"
        timeout_milliseconds   = 10000
      }
    }
  }

  tags = merge(local.common_tags, {
    Name = "api-gateway"
  })
}

################################################################################
# Lambda Permissions for API Gateway
################################################################################

# Allow API Gateway to invoke Get User Lambda
resource "aws_lambda_permission" "api_gateway_get_user" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.get_user_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.api_execution_arn}/*/*"
}

# Allow API Gateway to invoke Query Users Lambda
resource "aws_lambda_permission" "api_gateway_query_users" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.query_users_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.api_execution_arn}/*/*"
}

# Allow API Gateway to invoke Update User Lambda
resource "aws_lambda_permission" "api_gateway_update_user" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.update_user_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.api_execution_arn}/*/*"
}

# Allow API Gateway to invoke Delete User Lambda
resource "aws_lambda_permission" "api_gateway_delete_user" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.delete_user_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.api_execution_arn}/*/*"
}

# Allow API Gateway to invoke Create Team Lambda
resource "aws_lambda_permission" "api_gateway_create_team" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.create_team_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.api_execution_arn}/*/*"
}

# Allow API Gateway to invoke Get Team Lambda
resource "aws_lambda_permission" "api_gateway_get_team" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.get_team_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.api_execution_arn}/*/*"
}

# Allow API Gateway to invoke Query Teams Lambda
resource "aws_lambda_permission" "api_gateway_query_teams" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.query_teams_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.api_execution_arn}/*/*"
}

# Allow API Gateway to invoke Update Team Lambda
resource "aws_lambda_permission" "api_gateway_update_team" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.update_team_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.api_execution_arn}/*/*"
}

# Allow API Gateway to invoke Delete Team Lambda
resource "aws_lambda_permission" "api_gateway_delete_team" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.delete_team_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.api_execution_arn}/*/*"
}

################################################################################
# Outputs
################################################################################

output "api_gateway_endpoint" {
  value       = module.api_gateway.api_endpoint
  description = "API Gateway endpoint URL"
}

output "api_gateway_id" {
  value       = module.api_gateway.api_id
  description = "API Gateway ID"
}

output "api_gateway_arn" {
  value       = module.api_gateway.api_arn
  description = "API Gateway ARN"
}

