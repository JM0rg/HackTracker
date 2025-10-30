# DynamoDB Single-Table Design

## Overview

HackTracker uses a single DynamoDB table for all entities, following AWS best practices for single-table design.

**Table Name:** `hacktracker-{environment}` (e.g., `hacktracker-test`, `hacktracker-prod`)

**Billing Mode:** PAY_PER_REQUEST (on-demand)

---

## Primary Keys

### Partition Key (PK) & Sort Key (SK)

| PK Pattern | SK Pattern | Entity Type |
|------------|------------|-------------|
| `USER#<userId>` | `METADATA` | User Profile |
| `USER#<userId>` | `TEAM#<teamId>` | Team Membership |
| `TEAM#<teamId>` | `METADATA` | Team Profile |
| `TEAM#<teamId>` | `PLAYER#<playerId>` | Player Roster Record |
| `GAME#<gameId>` | `METADATA` | Game Info |

---

## Global Secondary Indexes (GSIs)

### GSI1: User Lookup by Cognito Sub

**Purpose:** Find user by Cognito authentication sub

**Keys:**
- `GSI1PK`: `COGNITO#<cognitoSub>`
- `GSI1SK`: `USER`

**Use Case:** User login, JWT validation

**Why Essential:** No alternative for mapping Cognito tokens to user records

**Example Query:**
```python
response = table.query(
    IndexName='GSI1',
    KeyConditionExpression='GSI1PK = :pk AND GSI1SK = :sk',
    ExpressionAttributeValues={
        ':pk': f'COGNITO#{cognito_sub}',
        ':sk': 'USER'
    }
)
```

---

### GSI2: Entity Listing

**Purpose:** List all entities of a specific type

**Keys:**
- `GSI2PK`: `ENTITY#<type>` (e.g., `ENTITY#USER`, `ENTITY#TEAM`, `ENTITY#GAME`)
- `GSI2SK`: `METADATA#<id>`

**Use Cases:**
- List all users
- List all teams
- List all games
- Admin dashboards
- Generic entity queries

**Why Essential:** More efficient than table scans, supports pagination

**Example Query:**
```python
# List all teams
response = table.query(
    IndexName='GSI2',
    KeyConditionExpression='GSI2PK = :pk',
    ExpressionAttributeValues={
        ':pk': 'ENTITY#TEAM'
    },
    Limit=50
)
```

---

### GSI3: Games by Team

**Purpose:** Query all games for a specific team

**Keys:**
- `GSI3PK`: `TEAM#<teamId>`
- `GSI3SK`: `GAME#<gameId>`

**Use Case:** List games by team, team game history, schedule management

**Status:** Active (used by list-games Lambda)

**Why Essential:** Efficient querying of games by team without scanning

**Example Query:**
```python
# Get all games for a team
response = table.query(
    IndexName='GSI3',
    KeyConditionExpression='GSI3PK = :pk AND begins_with(GSI3SK, :sk_prefix)',
    ExpressionAttributeValues={
        ':pk': f'TEAM#{team_id}',
        ':sk_prefix': 'GAME#'
    }
)
```

---

### GSI4: User's Players (Reserved for Future)

**Purpose:** Find all players linked to a user across all teams

**Keys:**
- `GSI4PK`: `USER#<userId>`
- `GSI4SK`: `PLAYER#<playerId>`

**Use Case:** User dashboard showing stats across all teams

**Status:** Defined but not yet populated (future feature)

**Why Planned:** User's cross-team stats survive team deletion

---

### GSI5: Player Stats (Reserved for Future)

**Purpose:** Query all at-bats for a player

**Keys:**
- `GSI5PK`: `PLAYER#<playerId>`
- `GSI5SK`: `ATBAT#<atBatId>`

**Use Case:** Player dashboard, stat aggregation

**Status:** Defined but not yet populated (future feature)

**Why Planned:** Player stat aggregation (hot path)

---

## Query Patterns

### Direct PK/SK Queries (No GSI Needed)

| Query | Pattern | Returns |
|-------|---------|---------|
| Team roster | `TEAM#<id>` + `SK` begins with `PLAYER#` | All players |
| User's teams | `USER#<id>` + `SK` begins with `TEAM#` | All memberships |
| Team games | `GSI3PK = TEAM#<id>` + `GSI3SK` begins with `GAME#` | All games for team |

**Example:**
```python
# Get all players on a team
response = table.query(
    KeyConditionExpression='PK = :pk AND begins_with(SK, :sk_prefix)',
    ExpressionAttributeValues={
        ':pk': f'TEAM#{team_id}',
        ':sk_prefix': 'PLAYER#'
    }
)

# Get all games for a team
response = table.query(
    IndexName='GSI3',
    KeyConditionExpression='GSI3PK = :pk AND begins_with(GSI3SK, :sk_prefix)',
    ExpressionAttributeValues={
        ':pk': f'TEAM#{team_id}',
        ':sk_prefix': 'GAME#'
    }
)
```

---

## Design Rationale

### Why Single-Table?

✅ **Performance** - All related data in one table, fewer network calls  
✅ **Cost-Effective** - One table = one set of provisioned capacity  
✅ **Atomic Transactions** - `TransactWriteItems` works within single table  
✅ **Simplified Operations** - One table to backup, monitor, and manage  

### Why 5 GSIs?

**GSI1 (Cognito)** - No alternative for login flow  
**GSI2 (Entity)** - Generic listing (replaces 4+ specific GSIs)  
**GSI3 (Games by Team)** - Team schedule and game history  
**GSI4 (User→Players)** - Cross-team user stats (future)  
**GSI5 (Player→AtBats)** - Player stat aggregation (future)  

**Why not more?**
- Most queries use PK/SK directly
- Each GSI doubles storage cost
- Fewer indexes = simpler maintenance
- Fewer indexes = faster writes

---

## Common Fields

All entities include:

```json
{
  "createdAt": "2025-10-24T00:00:00Z",
  "updatedAt": "2025-10-24T00:00:00Z"
}
```

---

## Entity Examples

### User Profile

```json
{
  "PK": "USER#12345678-1234-1234-1234-123456789012",
  "SK": "METADATA",
  "userId": "12345678-1234-1234-1234-123456789012",
  "email": "john.doe@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "phoneNumber": "+15555551234",
  "createdAt": "2025-10-25T12:00:00.000Z",
  "updatedAt": "2025-10-25T12:00:00.000Z",
  "GSI1PK": "COGNITO#12345678-1234-1234-1234-123456789012",
  "GSI1SK": "USER",
  "GSI2PK": "ENTITY#USER",
  "GSI2SK": "METADATA#12345678-1234-1234-1234-123456789012"
}
```

### Team Profile

```json
{
  "PK": "TEAM#a6f27724-7042-4816-94d3-a2183ef50a09",
  "SK": "METADATA",
  "teamId": "a6f27724-7042-4816-94d3-a2183ef50a09",
  "name": "Seattle Sluggers",
  "description": "Best team in Seattle",
  "ownerId": "12345678-1234-1234-1234-123456789012",
  "team_type": "MANAGED",
  "createdAt": "2025-10-25T12:00:00.000Z",
  "updatedAt": "2025-10-25T12:00:00.000Z",
  "GSI2PK": "ENTITY#TEAM",
  "GSI2SK": "METADATA#a6f27724-7042-4816-94d3-a2183ef50a09"
}
```

**Team Types:**
- `MANAGED`: Full roster management, lineup requirements, multi-player stat tracking
- `PERSONAL`: Single-owner label team for filtering personal stats by team/season context. Cannot add additional players. Always contains one player linked to the owner.

### Team Membership

```json
{
  "PK": "USER#12345678-1234-1234-1234-123456789012",
  "SK": "TEAM#a6f27724-7042-4816-94d3-a2183ef50a09",
  "userId": "12345678-1234-1234-1234-123456789012",
  "teamId": "a6f27724-7042-4816-94d3-a2183ef50a09",
  "role": "owner",
  "status": "active",
  "joinedAt": "2025-10-25T12:00:00.000Z",
  "invitedBy": null
}
```

**Roles:**
- `owner`: Team creator, full control
- `manager`: Coach/assistant, can manage roster and games
- `player`: Team member, can view and edit own profile
- `scorekeeper`: Can record stats during games

### Player (Roster Record)

```json
{
  "PK": "TEAM#a6f27724-7042-4816-94d3-a2183ef50a09",
  "SK": "PLAYER#b7e38835-8153-5927-a5e4-b3294fg61b1a",
  "playerId": "b7e38835-8153-5927-a5e4-b3294fg61b1a",
  "teamId": "a6f27724-7042-4816-94d3-a2183ef50a09",
  "firstName": "John",
  "lastName": "Doe",
  "playerNumber": 12,
  "positions": ["SS", "2B"],
  "status": "active",
  "isGhost": false,
  "userId": "12345678-1234-1234-1234-123456789012",
  "linkedAt": "2025-10-25T12:00:00.000Z",
  "createdAt": "2025-10-25T12:00:00.000Z",
  "updatedAt": "2025-10-25T12:00:00.000Z"
}
```

**Player Types:**
- **Ghost Player** (`isGhost: true`, `userId: null`): Roster slot not yet linked to a user
- **Linked Player** (`isGhost: false`, `userId` present): Player connected to a registered user

**Positions:** Array of position codes (e.g., `["P", "1B", "OF"]`)

**Status:** `active`, `inactive`, `sub`

### Game

```json
{
  "PK": "GAME#c8d39946-9264-6038-c6f5-d4405gh72c2b",
  "SK": "METADATA",
  "gameId": "c8d39946-9264-6038-c6f5-d4405gh72c2b",
  "teamId": "a6f27724-7042-4816-94d3-a2183ef50a09",
  "status": "SCHEDULED",
  "scheduledStart": "2025-11-01T19:30:00.000Z",
  "opponentName": "Portland Pioneers",
  "location": "Lincoln Park Field 3",
  "teamScore": 0,
  "opponentScore": 0,
  "lineup": [],
  "createdAt": "2025-10-25T12:00:00.000Z",
  "updatedAt": "2025-10-25T12:00:00.000Z",
  "GSI2PK": "ENTITY#GAME",
  "GSI2SK": "METADATA#c8d39946-9264-6038-c6f5-d4405gh72c2b",
  "GSI3PK": "TEAM#a6f27724-7042-4816-94d3-a2183ef50a09",
  "GSI3SK": "GAME#c8d39946-9264-6038-c6f5-d4405gh72c2b"
}
```

**Game Status:** `SCHEDULED`, `IN_PROGRESS`, `FINAL`, `POSTPONED`

**Fields:**
- `scheduledStart` (optional): ISO 8601 datetime
- `opponentName` (optional): Name of opponent team
- `location` (optional): Game location
- `seasonId` (optional): Associated season (future feature)
- `lineup` (optional): Array of player IDs in batting order

---

## Best Practices

### 1. Conditional Writes

Always use `ConditionExpression` to prevent race conditions:

```python
table.put_item(
    Item=item,
    ConditionExpression='attribute_not_exists(PK) AND attribute_not_exists(SK)'
)
```

### 2. Atomic Transactions

Use `TransactWriteItems` for operations that must succeed or fail together:

```python
table.meta.client.transact_write_items(
    TransactItems=[
        {
            'Put': {
                'TableName': table_name,
                'Item': team_item,
                'ConditionExpression': 'attribute_not_exists(PK)'
            }
        },
        {
            'Put': {
                'TableName': table_name,
                'Item': membership_item,
                'ConditionExpression': 'attribute_not_exists(PK)'
            }
        }
    ]
)
```

### 3. Consistent Field Ordering

Always order fields: PK, SK, entity fields, GSI keys

```json
{
  "PK": "...",
  "SK": "...",
  "userId": "...",
  "email": "...",
  "firstName": "...",
  "GSI1PK": "...",
  "GSI1SK": "..."
}
```

### 4. Auto-Timestamps

Always update `updatedAt` on modifications:

```python
item['updatedAt'] = datetime.now(timezone.utc).isoformat()
```

---

## Performance Considerations

### Hot Partitions

**Problem:** Too many requests to same partition key

**Solutions:**
- Use composite keys where appropriate
- Spread writes across time
- Use frontend caching (see [../ui/state-management.md](../ui/state-management.md))

### Large Items

**Limit:** 400 KB per item

**Solutions:**
- Store large data (images, videos) in S3
- Reference S3 URLs in DynamoDB
- Compress text data if needed

### Query Pagination

Always use pagination for large result sets:

```python
response = table.query(
    KeyConditionExpression='...',
    Limit=50
)

# Get next page
if 'LastEvaluatedKey' in response:
    next_response = table.query(
        KeyConditionExpression='...',
        Limit=50,
        ExclusiveStartKey=response['LastEvaluatedKey']
    )
```

---

## See Also

- **[ARCHITECTURE.md](../ARCHITECTURE.md)** - Complete system design
- **[authorization.md](./authorization.md)** - Authorization system
- **[lambda-functions.md](./lambda-functions.md)** - Lambda function catalog

