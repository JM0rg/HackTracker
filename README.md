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

# Development
make test             # Test Lambda locally
make package          # Package Lambda for deployment

# Deployment
make deploy           # Deploy to AWS

# Cleanup
make clean            # Remove build artifacts
```

## Lambda Functions

### Users

- **create** (`src/users/create/`) - Cognito post-confirmation trigger to create user in DynamoDB

## Quick Start

```bash
# 1. Start local environment
make db-start
make db-create

# 2. Test Lambda
make test

# 3. Deploy to AWS
make deploy

# 4. Clean up
make db-stop
```

## DynamoDB Admin UI

When running locally: http://localhost:8001

