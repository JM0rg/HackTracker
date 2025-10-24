# HackTracker

Slowpitch softball stat tracking application.

## Tech Stack

- **Language**: Python 3.13
- **Package Manager**: uv
- **Infrastructure**: Terraform
- **Database**: DynamoDB
- **Compute**: AWS Lambda

## Setup

```bash
# Install uv (if needed)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install dependencies
make install
```

## Commands

```bash
# Database
make db-start         # Start DynamoDB Local
make db-stop          # Stop DynamoDB Local
make db-create        # Create table
make db-delete        # Delete table
make db-clear         # Clear all data
make db-reset         # Reset table
make db-status        # Show status

# Development (Local Testing)
make test create                      # Test create-user Lambda
make test get <userId>                # Test get-user Lambda
make test query list                  # Test query-users (list all)
make test query email <email>         # Test query by email
make test-help                        # Show all test options

# Cloud Testing (Deployed API Gateway)
make test-cloud get <userId>          # Test deployed get-user
make test-cloud query list            # Test deployed query-users
make test-cloud query email <email>   # Test query by email (cloud)

# Build
make package                          # Package Lambdas for deployment

# Deployment
make deploy           # Deploy to AWS

# Cleanup
make clean            # Remove build artifacts
```

## Lambda Functions

### Users

- **create** (`src/users/create/`) - Cognito post-confirmation trigger to create user in DynamoDB
- **get** (`src/users/get/`) - GET /users/{userId} - Retrieve a single user by ID
- **query** (`src/users/query/`) - GET /users - Query/list users with filters (email, cognitoSub, teamId)

## Quick Start

### Local Development

```bash
# 1. Start local environment
make db-start
make db-create

# 2. Test Lambdas locally
make test create                              # Create a user
make test get <userId>                        # Get user by ID
make test query list                          # List all users
make test query email test@example.com        # Query by email

# 3. Clean up
make db-stop
```

### Deploy to AWS

```bash
# 1. Package and deploy
make deploy

# 2. Test deployed API Gateway
make test-cloud get <userId>                  # Test deployed get-user
make test-cloud query list                    # Test deployed query-users
make test-cloud query email test@example.com  # Test query by email (cloud)
```

## DynamoDB Admin UI

When running locally: http://localhost:8001

