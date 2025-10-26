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
| `TEAM#<teamId>` | `INVITE#<inviteId>` | Pending Team Invite |
| `TEAM#<teamId>#SEASON#<seasonId>` | `METADATA` | Team Season Info |
| `TEAM#<teamId>#SEASON#<seasonId>` | `GAME#<gameId>` | Game under Team Season |
| `GAME#<gameId>` | `METADATA` | Game Info |
| `GAME#<gameId>` | `ATBAT#<atBatId>` | Individual At-Bat Record |
| `PLAYER#<playerId>` | `METADATA` | Player Info (cross-team) |
| `LEAGUE#<leagueId>` | `METADATA` | League Info |
| `LEAGUE#<leagueId>#SEASON#<seasonId>` | `METADATA` | League Season Info |
| `LEAGUE#<leagueId>#SEASON#<seasonId>` | `GAME#<gameId>` | League Game Info |
| `LEAGUE#<leagueId>#SEASON#<seasonId>` | `TEAM#<teamId>` | Team Participation Link |
| `FREEAGENCY#<region>` | `USER#<userId>` | Free Agent Listing |

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
- `GSI2PK`: `ENTITY#<type>` (e.g., `ENTITY#USER`, `ENTITY#TEAM`)
- `GSI2SK`: `METADATA#<id>`

**Use Cases:**
- List all users
- List all teams
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

### GSI3: Geographic Search (Reserved)

**Purpose:** Find free agents/subs by region

**Keys:**
- `GSI3PK`: `REGION#<city>`
- `GSI3SK`: `USER#<userId>`

**Use Case:** Free agent discovery by location

**Status:** Defined but not yet populated (future feature)

---

### GSI4: User's Players (Reserved)

**Purpose:** Find all players linked to a user across all teams

**Keys:**
- `GSI4PK`: `USER#<userId>`
- `GSI4SK`: `PLAYER#<playerId>`

**Use Case:** User dashboard showing stats across all teams

**Status:** Defined but not yet populated (future feature)

**Why Essential:** User's cross-team stats survive team deletion

---

### GSI5: Player Stats (Reserved)

**Purpose:** Query all at-bats for a player

**Keys:**
- `GSI5PK`: `PLAYER#<playerId>`
- `GSI5SK`: `ATBAT#<atBatId>`

**Use Case:** Player dashboard, stat aggregation

**Status:** Defined but not yet populated (future feature)

**Why Essential:** Player stat aggregation (hot path)

---

## Query Patterns

### Direct PK/SK Queries (No GSI Needed)

| Query | Pattern | Returns |
|-------|---------|---------|
| Team roster | `TEAM#<id>` + `SK` begins with `PLAYER#` | All players |
| Game at-bats | `GAME#<id>` + `SK` begins with `ATBAT#` | All at-bats |
| League teams | `LEAGUE#<id>#SEASON#<id>` + `SK` begins with `TEAM#` | All teams |
| User's teams | `USER#<id>` + `SK` begins with `TEAM#` | All memberships |

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
**GSI3 (Region)** - Geographic search has no alternative  
**GSI4 (User→Players)** - Cross-team user stats (survives team deletion)  
**GSI5 (Player→AtBats)** - Player stat aggregation (hot path)  

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

League/Team entities also include:

```json
{
  "ownerType": "team" | "league",
  "isEditable": true | false,
  "inheritedFromLeague": true | false
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
  "status": "active",
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
  "status": "active",
  "createdAt": "2025-10-25T12:00:00.000Z",
  "updatedAt": "2025-10-25T12:00:00.000Z",
  "GSI2PK": "ENTITY#TEAM",
  "GSI2SK": "METADATA#a6f27724-7042-4816-94d3-a2183ef50a09"
}
```

### Team Membership

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

### Player (Ghost)

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

## Eliminated GSIs & Alternatives

| Removed GSI | Original Purpose | Alternative Solution |
|-------------|------------------|---------------------|
| ~~Email lookup~~ | User by email | Use Cognito `ListUsers` API (rare operation) |
| ~~League→Teams~~ | League's teams | Query `LEAGUE#id → TEAM#*` (already PK/SK) |
| ~~Email→Invites~~ | Invites by email | Query `TEAM#id → INVITE#*` and filter (rare operation) |
| ~~Season→Games~~ | Season's games | Query `TEAM#id#SEASON#id → GAME#*` (already PK/SK) |

**Note:** Game→AtBats doesn't need a GSI because `GAME#<id> → ATBAT#*` is the primary key pattern.

---

## Performance Considerations

### Hot Partitions

**Problem:** Too many requests to same partition key

**Solutions:**
- Use composite keys (e.g., `TEAM#id#SEASON#id`)
- Spread writes across time
- Use caching (see [caching.md](./caching.md))

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

- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Complete system design
- **[DATA_MODEL.md](../DATA_MODEL.md)** - Current implementation
- **[authorization.md](./authorization.md)** - Authorization system

