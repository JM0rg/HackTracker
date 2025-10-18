########## API GATEWAY V2 HTTP API ##########

module "api_gateway" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "~> 5.4.0"

  name          = "hacktracker-${local.environment}"
  description   = "HackTracker HTTP API Gateway"
  protocol_type = "HTTP"
  
  # Don't create custom domain (use default API Gateway URL)
  create_domain_name = false

  # CORS Configuration
  cors_configuration = {
    allow_headers = ["content-type", "authorization", "x-amz-date", "x-api-key", "x-amz-security-token"]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_origins = ["*"] # TODO: Restrict to app domain in production
  }

  # Access Logs
  stage_access_log_settings = {
    create_log_group            = true
    log_group_retention_in_days = local.environment == "prod" ? 30 : 7
    format = jsonencode({
      requestId      = "$context.requestId"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
      integrationError = "$context.integrationErrorMessage"
      ip             = "$context.identity.sourceIp"
      userAgent      = "$context.identity.userAgent"
    })
  }

  # Cognito JWT Authorizer
  authorizers = {
    "cognito" = {
      authorizer_type  = "JWT"
      identity_sources = ["$request.header.Authorization"]
      name             = "cognito-authorizer"
      jwt_configuration = {
        audience = [aws_cognito_user_pool_client.hacktracker.id]
        issuer   = "https://cognito-idp.us-east-1.amazonaws.com/${aws_cognito_user_pool.hacktracker.id}"
      }
    }
  }

  # Routes & Integrations
  routes = {
    # Teams Routes
    "GET /teams" = {
      authorization_type = "JWT"
      authorizer_key     = "cognito"
      integration = {
        uri                    = module.teams_lambda.lambda_function_arn
        payload_format_version = "2.0"
        timeout_milliseconds   = 10000
      }
    }

    "POST /teams" = {
      authorization_type = "JWT"
      authorizer_key     = "cognito"
      integration = {
        uri                    = module.teams_lambda.lambda_function_arn
        payload_format_version = "2.0"
        timeout_milliseconds   = 10000
      }
    }

    "GET /teams/{teamId}" = {
      authorization_type = "JWT"
      authorizer_key     = "cognito"
      integration = {
        uri                    = module.teams_lambda.lambda_function_arn
        payload_format_version = "2.0"
        timeout_milliseconds   = 10000
      }
    }

    "PUT /teams/{teamId}" = {
      authorization_type = "JWT"
      authorizer_key     = "cognito"
      integration = {
        uri                    = module.teams_lambda.lambda_function_arn
        payload_format_version = "2.0"
        timeout_milliseconds   = 10000
      }
    }

    "DELETE /teams/{teamId}" = {
      authorization_type = "JWT"
      authorizer_key     = "cognito"
      integration = {
        uri                    = module.teams_lambda.lambda_function_arn
        payload_format_version = "2.0"
        timeout_milliseconds   = 10000
      }
    }
  }

  tags = merge(local.common_tags, {
    Name = "HackTracker API"
  })
}

########## OUTPUTS ##########

output "api_gateway_url" {
  value       = module.api_gateway.stage_invoke_url
  description = "The base URL of the API Gateway"
}

output "api_gateway_id" {
  value       = module.api_gateway.api_id
  description = "The ID of the API Gateway"
}

output "api_gateway_execution_arn" {
  value       = module.api_gateway.api_execution_arn
  description = "The execution ARN of the API Gateway"
}

