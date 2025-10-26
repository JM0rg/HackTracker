# HackTracker

Slowpitch softball stat tracking application.

> **📖 Documentation:**
> - **[architecture-docs/](./architecture-docs/)** - Complete system architecture, design patterns, and guides
> - **[DATA_MODEL.md](./DATA_MODEL.md)** - Current implementation snapshot
> - **[TESTING.md](./TESTING.md)** - Testing workflows

## Tech Stack

- **Frontend**: Flutter (iOS + Android + Web)
- **Backend**: Python 3.13 + AWS Lambda
- **Database**: DynamoDB (single-table design)
- **Auth**: Amazon Cognito
- **API**: API Gateway (HTTP API with JWT authorizer)
- **Infrastructure**: Terraform
- **Package Manager**: uv

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
make test create                                        # Test create-user Lambda
make test get <userId>                                  # Test get-user Lambda
make test query list                                    # Test query-users (list all)
make test query email <email>                           # Test query by email
uv run python scripts/test_users.py update <userId> firstName=Jane  # Update user
uv run python scripts/test_users.py delete <userId>    # Delete user
make test-help                                          # Show all test options

# Cloud Testing (Deployed API Gateway)
make test-cloud get <userId>                                  # Test deployed get-user
make test-cloud query list                                    # Test deployed query-users
make test-cloud query email <email>                           # Test query by email (cloud)
uv run python scripts/test_users.py update <userId> firstName=Jane --cloud  # Update user (cloud)
uv run python scripts/test_users.py delete <userId> --cloud  # Delete user (cloud)

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
- **update** (`src/users/update/`) - PUT /users/{userId} - Update user information (firstName, lastName, phoneNumber)
- **delete** (`src/users/delete/`) - DELETE /users/{userId} - Delete a user

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

