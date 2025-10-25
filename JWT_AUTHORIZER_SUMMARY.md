# JWT Authorizer Implementation Summary

## Overview

Implemented a proper JWT authorizer on API Gateway to handle Cognito authentication, replacing the manual JWT decoding workaround in Lambda functions.

## Changes Made

### 1. Terraform Configuration

**File:** `terraform/api-gateway.tf`

Added JWT authorizer configuration:
```hcl
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
```

Attached the authorizer to all protected routes:
- All `/users/*` routes
- All `/teams/*` routes

Each route now includes:
```hcl
authorization_type = "JWT"
authorizer_key     = "cognito"
```

**File:** `terraform/locals.tf`

Added `region` local variable for reusability:
```hcl
region = "us-east-1"
```

### 2. Lambda Authorization Utilities

**File:** `src/utils/authorization.py`

Simplified `get_user_id_from_event()` function:
- **Primary method:** Extract `sub` from `requestContext.authorizer.jwt.claims` (populated by API Gateway)
- **Fallback:** `X-User-Id` header for local testing
- **Removed:** Manual JWT decoding logic (no longer needed)

Key benefits:
- Cleaner, more maintainable code
- JWT validation happens at API Gateway level (before Lambda invocation)
- Invalid/expired tokens are rejected automatically
- Lambda functions receive validated claims directly

### 3. Deployment

Repackaged all Lambda functions and deployed via Terraform:
```bash
python scripts/package_lambdas.py
cd terraform && terraform apply
```

## How It Works

### Authentication Flow

1. **Client (Flutter app):**
   - Signs in via Amplify Auth
   - Obtains JWT token from Cognito
   - Sends token in `Authorization: Bearer <token>` header

2. **API Gateway:**
   - Receives request
   - Extracts JWT from `Authorization` header
   - Validates token against Cognito User Pool:
     - Signature verification
     - Expiration check
     - Issuer/audience validation
   - If valid: populates `requestContext.authorizer.jwt.claims` and forwards to Lambda
   - If invalid: returns `401 Unauthorized` (Lambda never invoked)

3. **Lambda Function:**
   - Calls `get_user_id_from_event(event)`
   - Extracts `sub` from `event['requestContext']['authorizer']['jwt']['claims']`
   - Uses `sub` as the authenticated user ID

### JWT Claims Structure

The JWT token contains standard Cognito claims:
```json
{
  "sub": "d4c83418-5071-7069-0886-41747299b671",
  "email": "jmorgdev@gmail.com",
  "email_verified": true,
  "cognito:username": "jmorgdev@gmail.com",
  "iat": 1729871482,
  "exp": 1729875082,
  "aud": "6d5gg4nr09c33lji5rvmqiu3rf",
  "iss": "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_6oZj7BCGd"
}
```

API Gateway automatically validates:
- `iss` (issuer) matches configured Cognito User Pool
- `aud` (audience) matches configured Client ID
- `exp` (expiration) is in the future
- Signature is valid

## Security Benefits

1. **Centralized Validation:** JWT validation happens once at the gateway, not in every Lambda
2. **No Token Leakage:** Lambda functions never see the raw JWT token
3. **Standard Implementation:** Uses AWS best practices for JWT authorization
4. **Automatic Rejection:** Invalid/expired tokens never reach Lambda (cost savings)
5. **Easier Debugging:** API Gateway logs show auth failures separately from Lambda errors

## Local Testing

The Lambda functions still support local testing via the `X-User-Id` header:

```python
headers = {
    'X-User-Id': 'test-user-id-123'
}
```

This bypasses JWT validation and is useful for:
- Local DynamoDB testing
- Unit tests
- Development workflows

## API Gateway Resources Created

- **Authorizer:** `cognito-authorizer` (ID: `vxlf37`)
- **Protected Routes:** 9 routes (all user and team operations)
- **Issuer:** `https://cognito-idp.us-east-1.amazonaws.com/us-east-1_6oZj7BCGd`
- **Audience:** `6d5gg4nr09c33lji5rvmqiu3rf` (Cognito Client ID)

## Next Steps

The Flutter app should now successfully authenticate with the backend:
1. Sign in via Amplify Auth
2. Amplify automatically includes JWT in `Authorization` header
3. API Gateway validates token
4. Lambda receives validated user claims
5. Team creation and other operations work as expected

## Testing

To verify the JWT authorizer is working:

1. **Sign in to the Flutter app**
2. **Try creating a team** (should succeed with proper authentication)
3. **Check CloudWatch logs** for Lambda (should see "User ID extracted from JWT authorizer")
4. **Try with an invalid token** (should get 401 from API Gateway before Lambda)

## Files Modified

- `terraform/api-gateway.tf` - Added JWT authorizer, attached to routes
- `terraform/locals.tf` - Added region variable
- `src/utils/authorization.py` - Simplified JWT extraction
- All Lambda functions - Repackaged with updated utilities

