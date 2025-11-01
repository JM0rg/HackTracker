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

    # Get User Context
    "GET /users/context" = {
      authorization_type = "JWT"
      authorizer_key     = "cognito"
      integration = {
        uri                    = module.user_context_lambda.lambda_function_invoke_arn
        payload_format_version = "2.0"
        timeout_milliseconds   = 10000
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

    # Add Player to Team
    "POST /teams/{teamId}/players" = {
      authorization_type = "JWT"
      authorizer_key     = "cognito"
      integration = {
        uri                    = module.add_player_lambda.lambda_function_invoke_arn
        payload_format_version = "2.0"
        timeout_milliseconds   = 10000
      }
    }

    # List Players on Team
    "GET /teams/{teamId}/players" = {
      authorization_type = "JWT"
      authorizer_key     = "cognito"
      integration = {
        uri                    = module.list_players_lambda.lambda_function_invoke_arn
        payload_format_version = "2.0"
        timeout_milliseconds   = 30000
      }
    }

    # Get Single Player
    "GET /teams/{teamId}/players/{playerId}" = {
      authorization_type = "JWT"
      authorizer_key     = "cognito"
      integration = {
        uri                    = module.get_player_lambda.lambda_function_invoke_arn
        payload_format_version = "2.0"
        timeout_milliseconds   = 10000
      }
    }

    # Update Player
    "PUT /teams/{teamId}/players/{playerId}" = {
      authorization_type = "JWT"
      authorizer_key     = "cognito"
      integration = {
        uri                    = module.update_player_lambda.lambda_function_invoke_arn
        payload_format_version = "2.0"
        timeout_milliseconds   = 10000
      }
    }

    # Remove Player from Team
    "DELETE /teams/{teamId}/players/{playerId}" = {
      authorization_type = "JWT"
      authorizer_key     = "cognito"
      integration = {
        uri                    = module.remove_player_lambda.lambda_function_invoke_arn
        payload_format_version = "2.0"
        timeout_milliseconds   = 10000
      }
    }

    # Create Game
    "POST /games" = {
      authorization_type = "JWT"
      authorizer_key     = "cognito"
      integration = {
        uri                    = module.create_game_lambda.lambda_function_invoke_arn
        payload_format_version = "2.0"
        timeout_milliseconds   = 10000
      }
    }

    # List Games by Team
    "GET /teams/{teamId}/games" = {
      authorization_type = "JWT"
      authorizer_key     = "cognito"
      integration = {
        uri                    = module.list_games_lambda.lambda_function_invoke_arn
        payload_format_version = "2.0"
        timeout_milliseconds   = 30000
      }
    }

    # Get Game by ID
    "GET /games/{gameId}" = {
      authorization_type = "JWT"
      authorizer_key     = "cognito"
      integration = {
        uri                    = module.get_game_lambda.lambda_function_invoke_arn
        payload_format_version = "2.0"
        timeout_milliseconds   = 10000
      }
    }

    # Update Game
    "PUT /games/{gameId}" = {
      authorization_type = "JWT"
      authorizer_key     = "cognito"
      integration = {
        uri                    = module.update_game_lambda.lambda_function_invoke_arn
        payload_format_version = "2.0"
        timeout_milliseconds   = 10000
      }
    }

    # Delete Game
    "DELETE /games/{gameId}" = {
      authorization_type = "JWT"
      authorizer_key     = "cognito"
      integration = {
        uri                    = module.delete_game_lambda.lambda_function_invoke_arn
        payload_format_version = "2.0"
        timeout_milliseconds   = 10000
      }
    }

    # Create AtBat
    "POST /games/{gameId}/atbats" = {
      authorization_type = "JWT"
      authorizer_key     = "cognito"
      integration = {
        uri                    = module.create_atbat_lambda.lambda_function_invoke_arn
        payload_format_version = "2.0"
        timeout_milliseconds   = 10000
      }
    }

    # List AtBats for Game
    "GET /games/{gameId}/atbats" = {
      authorization_type = "JWT"
      authorizer_key     = "cognito"
      integration = {
        uri                    = module.list_atbats_lambda.lambda_function_invoke_arn
        payload_format_version = "2.0"
        timeout_milliseconds   = 30000
      }
    }

    # Get AtBat by ID
    "GET /games/{gameId}/atbats/{atBatId}" = {
      authorization_type = "JWT"
      authorizer_key     = "cognito"
      integration = {
        uri                    = module.get_atbat_lambda.lambda_function_invoke_arn
        payload_format_version = "2.0"
        timeout_milliseconds   = 10000
      }
    }

    # Update AtBat
    "PUT /games/{gameId}/atbats/{atBatId}" = {
      authorization_type = "JWT"
      authorizer_key     = "cognito"
      integration = {
        uri                    = module.update_atbat_lambda.lambda_function_invoke_arn
        payload_format_version = "2.0"
        timeout_milliseconds   = 10000
      }
    }

    # Delete AtBat
    "DELETE /games/{gameId}/atbats/{atBatId}" = {
      authorization_type = "JWT"
      authorizer_key     = "cognito"
      integration = {
        uri                    = module.delete_atbat_lambda.lambda_function_invoke_arn
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

# Allow API Gateway to invoke User Context Lambda
resource "aws_lambda_permission" "api_gateway_user_context" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.user_context_lambda.lambda_function_name
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

# Allow API Gateway to invoke Add Player Lambda
resource "aws_lambda_permission" "api_gateway_add_player" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.add_player_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.api_execution_arn}/*/*"
}

# Allow API Gateway to invoke List Players Lambda
resource "aws_lambda_permission" "api_gateway_list_players" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.list_players_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.api_execution_arn}/*/*"
}

# Allow API Gateway to invoke Get Player Lambda
resource "aws_lambda_permission" "api_gateway_get_player" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.get_player_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.api_execution_arn}/*/*"
}

# Allow API Gateway to invoke Update Player Lambda
resource "aws_lambda_permission" "api_gateway_update_player" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.update_player_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.api_execution_arn}/*/*"
}

# Allow API Gateway to invoke Remove Player Lambda
resource "aws_lambda_permission" "api_gateway_remove_player" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.remove_player_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.api_execution_arn}/*/*"
}

# Allow API Gateway to invoke Create Game Lambda
resource "aws_lambda_permission" "api_gateway_create_game" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.create_game_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.api_execution_arn}/*/*"
}

# Allow API Gateway to invoke List Games Lambda
resource "aws_lambda_permission" "api_gateway_list_games" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.list_games_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.api_execution_arn}/*/*"
}

# Allow API Gateway to invoke Get Game Lambda
resource "aws_lambda_permission" "api_gateway_get_game" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.get_game_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.api_execution_arn}/*/*"
}

# Allow API Gateway to invoke Update Game Lambda
resource "aws_lambda_permission" "api_gateway_update_game" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.update_game_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.api_execution_arn}/*/*"
}

# Allow API Gateway to invoke Delete Game Lambda
resource "aws_lambda_permission" "api_gateway_delete_game" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.delete_game_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.api_execution_arn}/*/*"
}

# Allow API Gateway to invoke Create AtBat Lambda
resource "aws_lambda_permission" "api_gateway_create_atbat" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.create_atbat_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.api_execution_arn}/*/*"
}

# Allow API Gateway to invoke List AtBats Lambda
resource "aws_lambda_permission" "api_gateway_list_atbats" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.list_atbats_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.api_execution_arn}/*/*"
}

# Allow API Gateway to invoke Get AtBat Lambda
resource "aws_lambda_permission" "api_gateway_get_atbat" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.get_atbat_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.api_execution_arn}/*/*"
}

# Allow API Gateway to invoke Update AtBat Lambda
resource "aws_lambda_permission" "api_gateway_update_atbat" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.update_atbat_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.api_execution_arn}/*/*"
}

# Allow API Gateway to invoke Delete AtBat Lambda
resource "aws_lambda_permission" "api_gateway_delete_atbat" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.delete_atbat_lambda.lambda_function_name
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

