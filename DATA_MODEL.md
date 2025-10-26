# HackTracker Data Model

**Current Implementation Status:** User, Team & Player Management (MVP Complete)

This document describes the **actual implemented** data model for HackTracker. For the complete system design including future features and architectural rationale, see [architecture-docs/ARCHITECTURE.md](./architecture-docs/ARCHITECTURE.md).

> **📖 Documentation Guide:**
> - **This document (DATA_MODEL.md):** Current implementation snapshot (WHAT exists now)
> - **[architecture-docs/](./architecture-docs/):** Complete system design, patterns, and rationale (WHAT + WHY + HOW)

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
| `TEAM#<teamId>` | `METADATA` | Team Profile |
| `USER#<userId>` | `TEAM#<teamId>` | Team Membership |
| `TEAM#<teamId>` | `PLAYER#<playerId>` | Player Profile (Ghost) |

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
  - `GSI2PK`: `ENTITY#<type>` (currently `ENTITY#USER` and `ENTITY#TEAM`)
  - `GSI2SK`: `METADATA#<id>`
- **Purpose:** List all entities of a specific type
- **Use Case:** List all users, list all teams, admin dashboards
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

### Team Profile

**Status:** ✅ Fully Implemented

**Primary Keys:**
```
PK: TEAM#<teamId>
SK: METADATA
```

**GSI Keys:**
```
GSI2PK: ENTITY#TEAM
GSI2SK: METADATA#<teamId>
```

**Attributes:**

| Field | Type | Required | Editable | Description |
|-------|------|----------|----------|-------------|
| `teamId` | String (UUID) | ✅ | ❌ | Team's unique identifier |
| `name` | String | ✅ | ✅ | Team name (3-50 chars, alphanumeric + spaces) |
| `description` | String | ❌ | ✅ | Optional team description (max 500 chars) |
| `ownerId` | String | ✅ | ❌ | User ID of team owner |
| `status` | String | ✅ | ❌ | Team status: `active` or `deleted` |
| `createdAt` | ISO 8601 | ✅ | ❌ | Team creation timestamp |
| `updatedAt` | ISO 8601 | ✅ | ❌ | Last update timestamp (auto-updated) |
| `deletedAt` | ISO 8601 | ❌ | ❌ | Soft delete timestamp (if deleted) |
| `recoveryToken` | String (UUID) | ❌ | ❌ | Recovery token for 30-day recovery period |

**Example Item:**
```json
{
  "PK": "TEAM#a6f27724-7042-4816-94d3-a2183ef50a09",
  "SK": "METADATA",
  "teamId": "a6f27724-7042-4816-94d3-a2183ef50a09",
  "name": "Seattle Sluggers",
  "description": "Best team in Seattle",
  "ownerId": "12345678-1234-1234-1234-123456789012",
  "status": "active",
  "createdAt": "2025-10-25T12:00:00.000Z",
  "updatedAt": "2025-10-25T12:00:00.000Z",
  "GSI2PK": "ENTITY#TEAM",
  "GSI2SK": "METADATA#a6f27724-7042-4816-94d3-a2183ef50a09"
}
```

**Lambda Functions:**

| Function | Method | Endpoint | Status |
|----------|--------|----------|--------|
| `create-team` | POST | `/teams` | ✅ Implemented |
| `get-team` | GET | `/teams/{teamId}` | ✅ Implemented |
| `query-teams` | GET | `/teams` | ✅ Implemented |
| `update-team` | PUT | `/teams/{teamId}` | ✅ Implemented |
| `delete-team` | DELETE | `/teams/{teamId}` | ✅ Implemented |

---

### Team Membership

**Status:** ✅ Fully Implemented

**Primary Keys:**
```
PK: USER#<userId>
SK: TEAM#<teamId>
```

**Attributes:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `userId` | String | ✅ | User's unique identifier |
| `teamId` | String (UUID) | ✅ | Team's unique identifier |
| `role` | String | ✅ | User's role: `team-owner`, `team-coach`, `team-player` |
| `status` | String | ✅ | Membership status: `active`, `inactive`, `invited` |
| `joinedAt` | ISO 8601 | ✅ | When user joined/was added to team |
| `invitedBy` | String | ❌ | User ID of inviter (null for team owner) |

**Example Item:**
```json
{
  "PK": "USER#12345678-1234-1234-1234-123456789012",
  "SK": "TEAM#a6f27724-7042-4816-94d3-a2183ef50a09",
  "userId": "12345678-1234-1234-1234-123456789012",
  "teamId": "a6f27724-7042-4816-94d3-a2183ef50a09",
  "role": "team-owner",
  "status": "active",
  "joinedAt": "2025-10-25T12:00:00.000Z",
  "invitedBy": null
}
```

---

### Player Profile (Ghost Players)

**Status:** ✅ Fully Implemented

**Primary Keys:**
```
PK: TEAM#<teamId>
SK: PLAYER#<playerId>
```

**Attributes:**

| Field | Type | Required | Editable | Description |
|-------|------|----------|----------|-------------|
| `playerId` | String (UUID) | ✅ | ❌ | Player's unique identifier |
| `teamId` | String (UUID) | ✅ | ❌ | Team the player belongs to |
| `firstName` | String | ✅ | ✅ | Player's first name (1-30 chars, letters/hyphens) |
| `lastName` | String | ❌ | ✅ | Player's last name (1-30 chars, letters/hyphens) |
| `playerNumber` | Integer | ❌ | ✅ | Jersey number (0-99) |
| `status` | String | ✅ | ✅ | Player status: `active`, `inactive`, `sub` |
| `isGhost` | Boolean | ✅ | ❌ | True if player not linked to a user account |
| `userId` | String | ❌ | ❌ | User ID if linked (null for ghost players) |
| `linkedAt` | ISO 8601 | ❌ | ❌ | When player was linked to user (null for ghost) |
| `createdAt` | ISO 8601 | ✅ | ❌ | Player creation timestamp |
| `updatedAt` | ISO 8601 | ✅ | ❌ | Last update timestamp (auto-updated) |

**Example Item (Ghost Player):**
```json
{
  "PK": "TEAM#a6f27724-7042-4816-94d3-a2183ef50a09",
  "SK": "PLAYER#b7e38835-8153-5927-a5e4-b3294fg61b1a",
  "playerId": "b7e38835-8153-5927-a5e4-b3294fg61b1a",
  "teamId": "a6f27724-7042-4816-94d3-a2183ef50a09",
  "firstName": "John",
  "lastName": "Doe",
  "playerNumber": 12,
  "status": "active",
  "isGhost": true,
  "userId": null,
  "linkedAt": null,
  "createdAt": "2025-10-25T12:00:00.000Z",
  "updatedAt": "2025-10-25T12:00:00.000Z"
}
```

**Lambda Functions:**

| Function | Method | Endpoint | Status |
|----------|--------|----------|--------|
| `add-player` | POST | `/teams/{teamId}/players` | ✅ Implemented |

**Notes:**
- Ghost players are unlinked roster slots created by coaches/owners before players join
- `position` and `battingOrder` are NOT tracked on player record (hitting-focused MVP)
- GSI4 fields NOT populated for ghost players (since `userId` is null)
- Player numbers do not need to be unique within a team
- When a user is linked to a ghost player, `userId` and `linkedAt` will be set

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

#### 7. Create Team (Atomic Transaction)
**Pattern:** Atomic write to team + membership
```
Operation: TransactWriteItems
Items:
  1. PutItem: PK=TEAM#<teamId>, SK=METADATA (team record)
  2. PutItem: PK=USER#<userId>, SK=TEAM#<teamId> (owner membership)
```

**Lambda:** `create-team`
**Endpoint:** `POST /teams`
**Features:**
- Atomic transaction ensures team + membership created together
- Validates team name (3-50 chars, alphanumeric + spaces)
- Cleans whitespace automatically
- Optional description (max 500 chars)
- Assigns creator as team-owner

---

#### 8. Get Team by ID
**Pattern:** Direct primary key lookup
```
Operation: GetItem
Key: PK=TEAM#<teamId>, SK=METADATA
```

**Lambda:** `get-team`
**Endpoint:** `GET /teams/{teamId}`
**Response:** Team profile object
**Note:** Returns 404 for deleted teams

---

#### 9. List All Teams
**Pattern:** GSI2 query
```
Operation: Query
Index: GSI2
KeyCondition: GSI2PK=ENTITY#TEAM
Limit: 50 (paginated)
```

**Lambda:** `query-teams`
**Endpoint:** `GET /teams`
**Features:**
- Pagination support via `nextToken`
- Filters out deleted teams
- Efficient GSI query

---

#### 10. List User's Teams
**Pattern:** Query user's team memberships
```
Operation: Query
KeyCondition: PK=USER#<userId> AND begins_with(SK, 'TEAM#')
```

**Lambda:** `query-teams`
**Endpoint:** `GET /teams?userId={userId}`
**Features:**
- Returns user's teams with their role
- Only active memberships
- Fetches team details for each membership

---

#### 11. Update Team
**Pattern:** Update with authorization
```
Operation: UpdateItem
Key: PK=TEAM#<teamId>, SK=METADATA
Authorization: Check USER#<userId> → TEAM#<teamId> membership
Required Role: team-owner or team-coach
Allowed Fields: name, description
Auto-Updated: updatedAt
```

**Lambda:** `update-team`
**Endpoint:** `PUT /teams/{teamId}`
**Validation:** Same as create (team name, description)

---

#### 12. Delete Team (Soft Delete)
**Pattern:** Update status to deleted
```
Operation: UpdateItem
Key: PK=TEAM#<teamId>, SK=METADATA
Set: status='deleted', deletedAt=timestamp, recoveryToken=uuid
Authorization: team-owner only
```

**Lambda:** `delete-team`
**Endpoint:** `DELETE /teams/{teamId}`
**Response:** 204 No Content
**Features:**
- Soft delete preserves data
- 30-day recovery period
- Team hidden from queries

---

#### 13. Add Ghost Player to Roster
**Pattern:** Create player record with authorization
```
Operation: PutItem
Key: PK=TEAM#<teamId>, SK=PLAYER#<playerId>
Authorization: Check USER#<userId> → TEAM#<teamId> membership
Required Role: team-owner or team-coach
Condition: PK and SK do not exist (prevent duplicates)
```

**Lambda:** `add-player`
**Endpoint:** `POST /teams/{teamId}/players`
**Required Fields:** `firstName`
**Optional Fields:** `lastName`, `playerNumber` (0-99), `status` (default: active)
**Validation:**
- firstName/lastName: 1-30 chars, letters and hyphens only, single word
- playerNumber: Integer 0-99
- status: One of `active`, `inactive`, `sub`

**Response:** `201 Created` with player data

---

#### 14. List Team Players
**Pattern:** Query team's roster
```
Operation: Query
KeyCondition: PK=TEAM#<teamId> AND begins_with(SK, 'PLAYER#')
Authorization: All team members can view
Sorting: By playerNumber (ascending, nulls last), then lastName, then firstName
```

**Lambda:** `list-players`
**Endpoint:** `GET /teams/{teamId}/players`
**Query Parameters:**
- `status` - Filter by status (active/inactive/sub)
- `isGhost` - Filter by ghost status (true/false)

**Response:** `200 OK` with `{ players: [...], count: N }`

---

#### 15. Get Single Player
**Pattern:** Direct lookup with authorization
```
Operation: GetItem
Key: PK=TEAM#<teamId>, SK=PLAYER#<playerId>
Authorization: All team members can view
```

**Lambda:** `get-player`
**Endpoint:** `GET /teams/{teamId}/players/{playerId}`
**Response:** `200 OK` with player object
**Error:** `404 Not Found` if player doesn't exist

---

#### 16. Update Player
**Pattern:** Update with authorization
```
Operation: UpdateItem
Key: PK=TEAM#<teamId>, SK=PLAYER#<playerId>
Authorization: Check USER#<userId> → TEAM#<teamId> membership
Required Role: team-owner or team-coach
Updatable Fields: firstName, lastName, playerNumber, status
Read-Only Fields: playerId, teamId, isGhost, userId, linkedAt, createdAt
Auto-Updated: updatedAt
```

**Lambda:** `update-player`
**Endpoint:** `PUT /teams/{teamId}/players/{playerId}`
**Validation:** Same as create (name, number, status validation)
**Response:** `200 OK` with updated player data
**Features:**
- Can set lastName or playerNumber to null to remove
- Rejects attempts to update read-only fields (400)

---

#### 17. Remove Player from Roster
**Pattern:** Hard delete ghost players only
```
Operation: DeleteItem
Key: PK=TEAM#<teamId>, SK=PLAYER#<playerId>
Authorization: Check USER#<userId> → TEAM#<teamId> membership
Required Role: team-owner or team-coach
Condition: isGhost = true (prevent deletion of linked players)
```

**Lambda:** `remove-player`
**Endpoint:** `DELETE /teams/{teamId}/players/{playerId}`
**Response:** `204 No Content`
**Restriction:** Cannot delete linked players (userId != null)
**Error:** `400 Bad Request` if player is linked

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

### User Routes

| Method | Path | Lambda | Auth |
|--------|------|--------|------|
| GET | `/users/{userId}` | get-user | Not yet enforced |
| GET | `/users` | query-users | Not yet enforced |
| PUT | `/users/{userId}` | update-user | Not yet enforced |
| DELETE | `/users/{userId}` | delete-user | Not yet enforced |

### Team Routes

| Method | Path | Lambda | Auth |
|--------|------|--------|------|
| POST | `/teams` | create-team | JWT required |
| GET | `/teams/{teamId}` | get-team | JWT required |
| GET | `/teams` | query-teams | JWT required |
| PUT | `/teams/{teamId}` | update-team | JWT required |
| DELETE | `/teams/{teamId}` | delete-team | JWT required |

### Player Routes

| Method | Path | Lambda | Auth |
|--------|------|--------|------|
| POST | `/teams/{teamId}/players` | add-player | JWT required |
| GET | `/teams/{teamId}/players` | list-players | JWT required |
| GET | `/teams/{teamId}/players/{playerId}` | get-player | JWT required |
| PUT | `/teams/{teamId}/players/{playerId}` | update-player | JWT required |
| DELETE | `/teams/{teamId}/players/{playerId}` | remove-player | JWT required |

**Note:** All routes now use Cognito JWT authentication enforced at API Gateway level.

---

## Infrastructure

### Terraform Modules

- **DynamoDB Table:** `terraform/dynamodb.tf`
- **Cognito User Pool:** `terraform/cognito.tf`
- **User Lambda Functions:** `terraform/lambda-users.tf`
- **Team Lambda Functions:** `terraform/lambda-teams.tf`
- **Player Lambda Functions:** `terraform/lambda-players.tf`
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

### Frontend Data Strategy

- Persistent cache for Teams, Players (Roster), and Current User using Shared Preferences
- On app launch and navigation: show cached data immediately; refresh in background (SWR)
- Optimistic updates for team and player mutations (add/update/remove): UI updates instantly; rollback on error
- Pull-to-refresh supported on data screens

### Local Testing Setup

- **DynamoDB Local:** Docker container on port 8000
- **Admin UI:** http://localhost:8001
- **Test Scripts:** 
  - `scripts/test_users.py` - User CRUD operations
  - `scripts/test_teams.py` - Team CRUD operations
  - `scripts/test_players.py` - Player roster operations

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

### Team Testing

```bash
# Full test suite
uv run python scripts/test_teams.py full-test <userId>

# Create team
uv run python scripts/test_teams.py create <userId> "Team Name" "Description"

# Get team
uv run python scripts/test_teams.py get <teamId>

# Query teams
uv run python scripts/test_teams.py query list
uv run python scripts/test_teams.py query user <userId>

# Update team
uv run python scripts/test_teams.py update <userId> <teamId> name="New Name"

# Delete team
uv run python scripts/test_teams.py delete <userId> <teamId>
```

### Player Testing

```bash
# Full test suite (includes all CRUD operations)
uv run python scripts/test_players.py full-test <userId>

# Add player
uv run python scripts/test_players.py add <userId> <teamId> "FirstName" "LastName" 12 active

# Add minimal player (firstName only)
uv run python scripts/test_players.py add <userId> <teamId> "FirstName"

# List players
uv run python scripts/test_players.py list <userId> <teamId>

# List with filters
uv run python scripts/test_players.py list <userId> <teamId> active      # Filter by status
uv run python scripts/test_players.py list <userId> <teamId> "" true    # Filter ghost players

# Get player
uv run python scripts/test_players.py get <userId> <teamId> <playerId>

# Update player
uv run python scripts/test_players.py update <userId> <teamId> <playerId> firstName "NewName"
uv run python scripts/test_players.py update <userId> <teamId> <playerId> playerNumber 99
uv run python scripts/test_players.py update <userId> <teamId> <playerId> status inactive
uv run python scripts/test_players.py update <userId> <teamId> <playerId> lastName null  # Remove field

# Remove player
uv run python scripts/test_players.py remove <userId> <teamId> <playerId>

# Verify player exists in DB
uv run python scripts/test_players.py verify <teamId> <playerId>

# Create test team
uv run python scripts/test_players.py create-team <userId> "Team Name"
```

### Cloud Testing

```bash
# Test against deployed API Gateway
make test-cloud get <userId>
make test-cloud query list
```

---

## See Also

- **[architecture-docs/ARCHITECTURE.md](./architecture-docs/ARCHITECTURE.md)** - Complete system design and roadmap
- **[architecture-docs/dynamodb-design.md](./architecture-docs/dynamodb-design.md)** - DynamoDB schema details
- **[architecture-docs/authorization.md](./architecture-docs/authorization.md)** - Authorization system (v2 Policy Engine)
- **[architecture-docs/caching.md](./architecture-docs/caching.md)** - Frontend caching and optimistic UI
- **[Makefile](./Makefile)** - Development commands and workflows
- **[terraform/](./terraform/)** - Infrastructure as code definitions

