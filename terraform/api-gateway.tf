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

  # Routes and integrations
  routes = {
    # Get User by ID
    "GET /users/{userId}" = {
      integration = {
        uri                    = module.get_user_lambda.lambda_function_invoke_arn
        payload_format_version = "2.0"
        timeout_milliseconds   = 10000
      }
    }

    # Query/List Users
    "GET /users" = {
      integration = {
        uri                    = module.query_users_lambda.lambda_function_invoke_arn
        payload_format_version = "2.0"
        timeout_milliseconds   = 30000
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

