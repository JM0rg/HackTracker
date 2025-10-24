# Testing Guide

HackTracker supports both **local** and **cloud** testing for Lambda functions.

## Local Testing

Test Lambda functions locally using DynamoDB Local:

```bash
# Start local environment
make db-start
make db-create

# Test Lambdas
make test create                      # Create user (Cognito trigger)
make test get <userId>                # Get user by ID
make test query list                  # List all users
make test query email <email>         # Query by email
make test query cognitoSub <sub>      # Query by Cognito sub
make test query teamId <teamId>       # Query by team ID
```

### How it works:
- ✅ Imports Lambda handler directly
- ✅ Simulates API Gateway event (v2.0 format)
- ✅ Uses DynamoDB Local (localhost:8000)
- ✅ Fast feedback loop
- ✅ No AWS costs

## Cloud Testing

Test deployed Lambda functions via API Gateway:

```bash
# Deploy first
make deploy

# Test deployed Lambdas
make test-cloud get <userId>          # Test deployed get-user
make test-cloud query list            # Test deployed query-users
make test-cloud query email <email>   # Test query by email (cloud)
```

### How it works:
- ✅ Makes real HTTP requests to API Gateway
- ✅ Uses deployed Lambda functions
- ✅ Uses production DynamoDB table
- ✅ Tests full AWS integration
- ✅ Validates CORS, IAM, etc.

## Workflow

### 1. Local Development
```bash
make db-start
make db-create
make test create                      # Create test user
make test get <userId>                # Verify locally
make test query list                  # List users
```

### 2. Deploy & Verify
```bash
make deploy                           # Deploy to AWS
make test-cloud get <userId>          # Test in cloud
make test-cloud query list            # Verify cloud data
```

### 3. Debugging

**Local Issues:**
- Check DynamoDB Local: http://localhost:8001
- Check logs in terminal output
- Verify table exists: `make db-status`

**Cloud Issues:**
- Check CloudWatch Logs in AWS Console
- Verify API Gateway URL: `cd terraform && terraform output api_gateway_endpoint`
- Check IAM permissions in `terraform/lambda-users.tf`

## Test Script Options

```bash
# Show all options
make test-help

# Or directly
uv run python scripts/test_users.py

# Manual usage
uv run python scripts/test_users.py create
uv run python scripts/test_users.py get <userId>
uv run python scripts/test_users.py get <userId> --cloud
uv run python scripts/test_users.py query list
uv run python scripts/test_users.py query email test@example.com --cloud
```

## Tips

1. **Always test locally first** - faster feedback, no AWS costs
2. **Test cloud after deploy** - validates full integration
3. **Use different data** - local uses `HackTracker-dev`, cloud uses `HackTracker-test` or `HackTracker-prod`
4. **Check both databases** - local and cloud are separate
5. **Clean up** - `make db-clear` for local, manually delete items in cloud

## Troubleshooting

### "Failed to get API Gateway URL"
- Make sure you've deployed: `make deploy`
- Check Terraform outputs: `cd terraform && terraform output`

### "Connection refused" (local)
- Start DynamoDB Local: `make db-start`
- Check status: `make db-status`

### "User not found" (cloud)
- Create user in cloud (via Cognito or manually)
- Check DynamoDB table in AWS Console
- Verify correct workspace: `cd terraform && terraform workspace show`

