# HackTracker Data Model

**Current Implementation Status:** User Management (MVP)

This document describes the **actual implemented** data model for HackTracker. For the complete system design including future features and architectural rationale, see [ARCHITECTURE.md](./ARCHITECTURE.md).

---

## Table of Contents

1. [Overview](#overview)
2. [DynamoDB Table Structure](#dynamodb-table-structure)
3. [Implemented Entities](#implemented-entities)
4. [Access Patterns](#access-patterns)
5. [Testing](#testing)
6. [Infrastructure](#infrastructure)

---

## Overview

**Table Name:** `hacktracker-{environment}` (e.g., `hacktracker-test`, `hacktracker-prod`)

**Billing Mode:** PAY_PER_REQUEST (on-demand)

**Primary Keys:**
- **PK** (Partition Key): String
- **SK** (Sort Key): String

**Global Secondary Indexes:** 5 total (2 active, 3 reserved)
- GSI1: User lookup by Cognito sub ✅ **Active**
- GSI2: Entity listing (generic queries) ✅ **Active**
- GSI3: Geographic search (reserved for free agents) 🔒 **Reserved**
- GSI4: User's players (reserved for team features) 🔒 **Reserved**
- GSI5: Player's at-bats (reserved for game stats) 🔒 **Reserved**

---

## DynamoDB Table Structure

### Primary Key Patterns (Implemented)

| PK Pattern | SK Pattern | Entity Type |
|------------|------------|-------------|
| `USER#<userId>` | `METADATA` | User Profile |

### Global Secondary Indexes (Active)

#### GSI1: User Lookup by Cognito Sub
- **Keys:**
  - `GSI1PK`: `COGNITO#<cognitoSub>`
  - `GSI1SK`: `USER`
- **Purpose:** Find user by Cognito authentication sub
- **Use Case:** User login, JWT validation
- **Why Essential:** No alternative for mapping Cognito tokens to user records

#### GSI2: Entity Listing
- **Keys:**
  - `GSI2PK`: `ENTITY#<type>` (currently only `ENTITY#USER`)
  - `GSI2SK`: `METADATA#<id>`
- **Purpose:** List all entities of a specific type
- **Use Case:** List all users, admin dashboards, future entity listings
- **Why Essential:** More efficient than table scans, supports pagination

### Global Secondary Indexes (Reserved)

GSI3, GSI4, and GSI5 are defined in the table schema but not yet populated. They will be activated when team, player, and game features are implemented. See [ARCHITECTURE.md](./ARCHITECTURE.md) for their planned usage.

---

## Implemented Entities

### User Profile

**Status:** ✅ Fully Implemented

**Primary Keys:**
```
PK: USER#<userId>
SK: METADATA
```

**GSI Keys:**
```
GSI1PK: COGNITO#<cognitoSub>
GSI1SK: USER
GSI2PK: ENTITY#USER
GSI2SK: METADATA#<userId>
```

**Attributes:**

| Field | Type | Required | Editable | Description |
|-------|------|----------|----------|-------------|
| `userId` | String | ✅ | ❌ | Cognito sub (globally unique) |
| `email` | String | ✅ | ❌ | User's email (lowercase) |
| `firstName` | String | ✅ | ✅ | User's first name |
| `lastName` | String | ✅ | ✅ | User's last name |
| `phoneNumber` | String | ❌ | ✅ | User's phone number |
| `status` | String | ✅ | ❌ | Account status: `active` or `deleted` |
| `createdAt` | ISO 8601 | ✅ | ❌ | Account creation timestamp |
| `updatedAt` | ISO 8601 | ✅ | ❌ | Last update timestamp (auto-updated) |

**Example Item:**
```json
{
  "PK": "USER#12345678-1234-1234-1234-123456789012",
  "SK": "METADATA",
  "userId": "12345678-1234-1234-1234-123456789012",
  "email": "john.doe@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "phoneNumber": "+15555551234",
  "status": "active",
  "createdAt": "2025-10-25T12:00:00.000Z",
  "updatedAt": "2025-10-25T12:00:00.000Z",
  "GSI1PK": "COGNITO#12345678-1234-1234-1234-123456789012",
  "GSI1SK": "USER",
  "GSI2PK": "ENTITY#USER",
  "GSI2SK": "METADATA#12345678-1234-1234-1234-123456789012"
}
```

**Lambda Functions:**

| Function | Method | Endpoint | Status |
|----------|--------|----------|--------|
| `create-user` | POST | Cognito Trigger | ✅ Implemented |
| `get-user` | GET | `/users/{userId}` | ✅ Implemented |
| `query-users` | GET | `/users` | ✅ Implemented |
| `update-user` | PUT | `/users/{userId}` | ✅ Implemented |
| `delete-user` | DELETE | `/users/{userId}` | ✅ Implemented |

---

## Access Patterns

### Implemented Access Patterns

#### 1. Create User (Cognito Post-Confirmation)
**Pattern:** Write to primary key + GSI1 + GSI2
```
Operation: PutItem
Key: PK=USER#<userId>, SK=METADATA
Condition: PK does not exist (prevent duplicates)
```

**Lambda:** `create-user`
**Trigger:** Cognito post-confirmation
**Features:**
- Idempotent (handles Cognito retries)
- Uses Cognito sub as userId
- Fallback names from email if not provided

---

#### 2. Get User by ID
**Pattern:** Direct primary key lookup
```
Operation: GetItem
Key: PK=USER#<userId>, SK=METADATA
```

**Lambda:** `get-user`
**Endpoint:** `GET /users/{userId}`
**Response:** User profile object

---

#### 3. Query User by Cognito Sub
**Pattern:** GSI1 query
```
Operation: Query
Index: GSI1
KeyCondition: GSI1PK=COGNITO#<sub> AND GSI1SK=USER
```

**Lambda:** `query-users`
**Endpoint:** `GET /users?cognitoSub={sub}`
**Use Case:** User login, JWT validation

---

#### 4. List All Users
**Pattern:** GSI2 query
```
Operation: Query
Index: GSI2
KeyCondition: GSI2PK=ENTITY#USER
Limit: 50 (paginated)
```

**Lambda:** `query-users`
**Endpoint:** `GET /users`
**Features:**
- Pagination support via `nextToken`
- Configurable limit
- More efficient than table scan

---

#### 5. Update User
**Pattern:** Update primary key item
```
Operation: UpdateItem
Key: PK=USER#<userId>, SK=METADATA
Allowed Fields: firstName, lastName, phoneNumber
Auto-Updated: updatedAt
```

**Lambda:** `update-user`
**Endpoint:** `PUT /users/{userId}`
**Allowed Fields:** `firstName`, `lastName`, `phoneNumber`
**Validation:**
- Read-only fields rejected (`userId`, `email`, `status`, `createdAt`, `updatedAt`, GSI keys)
- Field type validation
- Non-empty string requirements
- `updatedAt` automatically set to current timestamp

---

#### 6. Delete User
**Pattern:** Delete primary key item
```
Operation: DeleteItem
Key: PK=USER#<userId>, SK=METADATA
```

**Lambda:** `delete-user`
**Endpoint:** `DELETE /users/{userId}`
**Response:** 204 No Content

---

## Design Principles

### 1. Single-Table Design
All entities stored in one DynamoDB table for optimal performance and cost efficiency.

### 2. Cognito Sub as User ID
Using Cognito's globally unique sub as the userId eliminates cross-referencing and simplifies lookups.

### 3. Idempotent Operations
All Lambda functions handle retries gracefully, especially important for Cognito triggers.

### 4. Conditional Writes
Use `ConditionExpression` to prevent race conditions and duplicate records.

### 5. Reserved GSIs
GSI3, GSI4, and GSI5 are defined but not yet populated, ready for future features without schema changes.

---

## API Gateway Routes

| Method | Path | Lambda | Auth |
|--------|------|--------|------|
| GET | `/users/{userId}` | get-user | Not yet enforced |
| GET | `/users` | query-users | Not yet enforced |
| PUT | `/users/{userId}` | update-user | Not yet enforced |
| DELETE | `/users/{userId}` | delete-user | Not yet enforced |

**Note:** Cognito authentication will be enforced in a future update.

---

## Infrastructure

### Terraform Modules

- **DynamoDB Table:** `terraform/dynamodb.tf`
- **Cognito User Pool:** `terraform/cognito.tf`
- **Lambda Functions:** `terraform/lambda-users.tf`
- **API Gateway:** `terraform/api-gateway.tf`

### Lambda Configuration

| Setting | Value |
|---------|-------|
| Runtime | Python 3.13 |
| Architecture | ARM64 |
| Memory | 128 MB (users), 256 MB (query) |
| Timeout | 10-30 seconds |
| CloudWatch Logs | 7 day retention |

---

## Testing

### Local Testing Setup

- **DynamoDB Local:** Docker container on port 8000
- **Admin UI:** http://localhost:8001
- **Test Scripts:** `scripts/test_users.py`

### Test Commands

```bash
# Create user
make test create

# Get user
make test get <userId>

# Query users
make test query list
make test query cognitoSub <sub>

# Update user
uv run python scripts/test_users.py update <userId> firstName=Jane

# Delete user
uv run python scripts/test_users.py delete <userId>
```

### Cloud Testing

```bash
# Test against deployed API Gateway
make test-cloud get <userId>
make test-cloud query list
```

---

## See Also

- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Complete system design, future roadmap, and architectural rationale
- **[Makefile](./Makefile)** - Development commands and workflows
- **[terraform/](./terraform/)** - Infrastructure as code definitions

