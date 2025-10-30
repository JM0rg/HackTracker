# Lambda Functions Catalog

Complete reference for all 21 implemented Lambda functions in HackTracker.

---

## Overview

**Total Functions:** 21  
**Domains:** Users (6), Teams (5), Players (5), Games (5)  
**Runtime:** Python 3.13  
**Architecture:** ARM64  
**Authorization:** JWT (Cognito) + Role-Based Access Control

---

## Table of Contents

1. [User Management (6 functions)](#user-management)
2. [Team Management (5 functions)](#team-management)
3. [Player Management (5 functions)](#player-management)
4. [Game Management (5 functions)](#game-management)
5. [Common Patterns](#common-patterns)
6. [Error Codes](#error-codes)

---

## User Management

### 1. Create User (Cognito Trigger)

**Handler:** `src/users/create/handler.py`  
**Trigger:** Cognito Post-Confirmation  
**Purpose:** Automatically create user record in DynamoDB after successful Cognito registration

**Trigger Event:**
```json
{
  "request": {
    "userAttributes": {
      "sub": "12345678-1234-1234-1234-123456789012",
      "email": "user@example.com"
    }
  }
}
```

**Database Operation:**
- Creates `USER#<userId>` → `METADATA` record
- Sets up GSI1 (Cognito lookup) and GSI2 (entity listing)
- Generates default firstName/lastName from email

**Returns:** Modified Cognito event (not HTTP response)

---

### 2. Get User

**Handler:** `src/users/get/handler.py`  
**Route:** `GET /users/{userId}`  
**Authorization:** User must be requesting their own profile

**Path Parameters:**
- `userId` (required): User's Cognito sub

**Response (200):**
```json
{
  "userId": "12345678-1234-1234-1234-123456789012",
  "email": "user@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "phoneNumber": "+15555551234",
  "createdAt": "2025-10-30T12:00:00.000Z",
  "updatedAt": "2025-10-30T12:00:00.000Z"
}
```

**Error Codes:**
- `400`: Missing userId
- `403`: Unauthorized (accessing another user's profile)
- `404`: User not found

---

### 3. Query Users

**Handler:** `src/users/query/handler.py`  
**Route:** `GET /users`  
**Authorization:** Public (all authenticated users)

**Query Parameters:**
- `cognitoSub` (optional): Query by Cognito sub
- `limit` (optional): Max results (default: 50)
- `nextToken` (optional): Pagination token

**Response (200) - List All:**
```json
{
  "users": [
    {
      "userId": "...",
      "email": "...",
      "firstName": "...",
      "lastName": "...",
      "createdAt": "...",
      "updatedAt": "..."
    }
  ],
  "count": 25,
  "nextToken": "..." 
}
```

**Response (200) - Query by Cognito Sub:**
```json
{
  "userId": "...",
  "email": "...",
  "firstName": "...",
  "lastName": "..."
}
```

---

### 4. Update User

**Handler:** `src/users/update/handler.py`  
**Route:** `PUT /users/{userId}`  
**Authorization:** User must be updating their own profile

**Path Parameters:**
- `userId` (required): User's Cognito sub

**Request Body:**
```json
{
  "firstName": "Jane",
  "lastName": "Smith",
  "phoneNumber": "+15555559999"
}
```

**Allowed Fields:** `firstName`, `lastName`, `phoneNumber`  
**Read-Only Fields:** `userId`, `email`, `createdAt`, `updatedAt`

**Response (200):**
```json
{
  "userId": "...",
  "email": "...",
  "firstName": "Jane",
  "lastName": "Smith",
  "phoneNumber": "+15555559999",
  "updatedAt": "2025-10-30T14:00:00.000Z"
}
```

**Error Codes:**
- `400`: Invalid fields or missing userId
- `403`: Unauthorized (updating another user's profile)
- `404`: User not found

---

### 5. Delete User

**Handler:** `src/users/delete/handler.py`  
**Route:** `DELETE /users/{userId}`  
**Authorization:** User must be deleting their own profile

**Path Parameters:**
- `userId` (required): User's Cognito sub

**Response (204):** No content

**Error Codes:**
- `400`: Missing userId
- `403`: Unauthorized (deleting another user)
- `404`: User not found

---

### 6. Get User Context

**Handler:** `src/users/context/handler.py`  
**Route:** `GET /users/context`  
**Authorization:** Authenticated user

**Purpose:** Provides UI-relevant context about user's teams and permissions

**Response (200):**
```json
{
  "userId": "...",
  "teams": [
    {
      "teamId": "...",
      "name": "Team Name",
      "role": "owner"
    }
  ],
  "shouldShowPlayerViewOnly": false,
  "shouldShowTeamViewOnly": true,
  "shouldShowTeamSelector": false
}
```

---

## Team Management

### 1. Create Team

**Handler:** `src/teams/create/handler.py`  
**Route:** `POST /teams`  
**Authorization:** Authenticated user

**Request Body:**
```json
{
  "name": "Seattle Sluggers",
  "description": "Best team in Seattle",
  "team_type": "MANAGED"
}
```

**Team Types:**
- `MANAGED`: Full roster management (default)
- `PERSONAL`: Single-owner stat filtering label

**Response (201):**
```json
{
  "teamId": "a6f27724-7042-4816-94d3-a2183ef50a09",
  "name": "Seattle Sluggers",
  "description": "Best team in Seattle",
  "ownerId": "...",
  "team_type": "MANAGED",
  "createdAt": "...",
  "updatedAt": "..."
}
```

**Database Operations (Atomic Transaction):**
1. Create team record
2. Create owner membership record
3. For PERSONAL teams: Create player record linked to owner

**Error Codes:**
- `400`: Invalid request body or team type
- `409`: Team already exists

---

### 2. Get Team

**Handler:** `src/teams/get/handler.py`  
**Route:** `GET /teams/{teamId}`  
**Authorization:** Must be team member

**Path Parameters:**
- `teamId` (required): Team UUID

**Response (200):**
```json
{
  "teamId": "...",
  "name": "...",
  "description": "...",
  "ownerId": "...",
  "team_type": "MANAGED",
  "role": "owner",
  "memberCount": 12,
  "createdAt": "...",
  "updatedAt": "..."
}
```

**Error Codes:**
- `400`: Missing teamId
- `403`: Not a team member
- `404`: Team not found

---

### 3. Query Teams

**Handler:** `src/teams/query/handler.py`  
**Route:** `GET /teams`  
**Authorization:** Authenticated user

**Query Parameters:**
- `userId` (optional): Filter by user membership
- `ownerId` (optional): Filter by owner
- `teamType` (optional): Filter by team type (MANAGED/PERSONAL)
- `limit` (optional): Max results (default: 50)
- `nextToken` (optional): Pagination token

**Response (200):**
```json
{
  "teams": [
    {
      "teamId": "...",
      "name": "...",
      "description": "...",
      "ownerId": "...",
      "team_type": "MANAGED",
      "role": "owner",
      "memberCount": 12,
      "joinedAt": "...",
      "createdAt": "...",
      "updatedAt": "..."
    }
  ],
  "count": 5
}
```

---

### 4. Update Team

**Handler:** `src/teams/update/handler.py`  
**Route:** `PUT /teams/{teamId}`  
**Authorization:** owner or manager role

**Path Parameters:**
- `teamId` (required): Team UUID

**Request Body:**
```json
{
  "name": "Updated Team Name",
  "description": "Updated description"
}
```

**Allowed Fields:** `name`, `description`  
**Read-Only Fields:** `teamId`, `ownerId`, `team_type`, `createdAt`

**Response (200):** Updated team object

**Error Codes:**
- `400`: Invalid fields
- `403`: Insufficient permissions
- `404`: Team not found

---

### 5. Delete Team

**Handler:** `src/teams/delete/handler.py`  
**Route:** `DELETE /teams/{teamId}`  
**Authorization:** owner role only

**Path Parameters:**
- `teamId` (required): Team UUID

**Response (204):** No content

**Special Handling:**
- PERSONAL teams cannot be deleted
- Deletes all team data (roster, memberships)

**Error Codes:**
- `400`: Cannot delete PERSONAL team
- `403`: Not team owner
- `404`: Team not found

---

## Player Management

### 1. Add Player

**Handler:** `src/players/add/handler.py`  
**Route:** `POST /teams/{teamId}/players`  
**Authorization:** owner or manager role

**Path Parameters:**
- `teamId` (required): Team UUID

**Request Body:**
```json
{
  "firstName": "John",
  "lastName": "Doe",
  "playerNumber": 12,
  "positions": ["SS", "2B"],
  "status": "active"
}
```

**Response (201):**
```json
{
  "playerId": "b7e38835-8153-5927-a5e4-b3294fg61b1a",
  "teamId": "...",
  "firstName": "John",
  "lastName": "Doe",
  "playerNumber": 12,
  "positions": ["SS", "2B"],
  "status": "active",
  "isGhost": true,
  "userId": null,
  "createdAt": "...",
  "updatedAt": "..."
}
```

**Validation:**
- Position validation (valid position codes)
- Player number uniqueness per team
- Cannot add players to PERSONAL teams

**Error Codes:**
- `400`: Invalid request or PERSONAL team
- `403`: Insufficient permissions
- `409`: Player number already exists

---

### 2. List Players

**Handler:** `src/players/list/handler.py`  
**Route:** `GET /teams/{teamId}/players`  
**Authorization:** Must be team member

**Path Parameters:**
- `teamId` (required): Team UUID

**Query Parameters:**
- `status` (optional): Filter by status (active/inactive/sub)
- `isGhost` (optional): Filter by ghost status (true/false)
- `includeRoles` (optional): Include role from team membership (true/false)

**Response (200):**
```json
[
  {
    "playerId": "...",
    "teamId": "...",
    "firstName": "John",
    "lastName": "Doe",
    "playerNumber": 12,
    "positions": ["SS", "2B"],
    "status": "active",
    "isGhost": false,
    "userId": "...",
    "role": "owner",
    "linkedAt": "...",
    "createdAt": "...",
    "updatedAt": "..."
  }
]
```

**Error Codes:**
- `403`: Not a team member
- `404`: Team not found

---

### 3. Get Player

**Handler:** `src/players/get/handler.py`  
**Route:** `GET /teams/{teamId}/players/{playerId}`  
**Authorization:** Must be team member

**Path Parameters:**
- `teamId` (required): Team UUID
- `playerId` (required): Player UUID

**Response (200):** Single player object

**Error Codes:**
- `403`: Not a team member
- `404`: Team or player not found

---

### 4. Update Player

**Handler:** `src/players/update/handler.py`  
**Route:** `PUT /teams/{teamId}/players/{playerId}`  
**Authorization:** owner or manager role

**Path Parameters:**
- `teamId` (required): Team UUID
- `playerId` (required): Player UUID

**Request Body:**
```json
{
  "firstName": "Jane",
  "playerNumber": 13,
  "positions": ["P", "1B"],
  "status": "inactive"
}
```

**Allowed Fields:** `firstName`, `lastName`, `playerNumber`, `positions`, `status`  
**Read-Only Fields:** `playerId`, `teamId`, `userId`, `isGhost`, `linkedAt`

**Response (200):** Updated player object

**Error Codes:**
- `400`: Invalid fields
- `403`: Insufficient permissions
- `404`: Player not found
- `409`: Player number conflict

---

### 5. Remove Player

**Handler:** `src/players/remove/handler.py`  
**Route:** `DELETE /teams/{teamId}/players/{playerId}`  
**Authorization:** owner or manager role

**Path Parameters:**
- `teamId` (required): Team UUID
- `playerId` (required): Player UUID

**Response (204):** No content

**Restrictions:**
- Can only remove ghost players (not linked to users)
- Cannot remove linked players (must unlink first)

**Error Codes:**
- `400`: Cannot remove linked player
- `403`: Insufficient permissions
- `404`: Player not found

---

## Game Management

### 1. Create Game

**Handler:** `src/games/create/handler.py`  
**Route:** `POST /games`  
**Authorization:** owner, manager, or scorekeeper role

**Request Body:**
```json
{
  "teamId": "...",
  "status": "SCHEDULED",
  "scheduledStart": "2025-11-01T19:30:00.000Z",
  "opponentName": "Portland Pioneers",
  "location": "Lincoln Park Field 3",
  "teamScore": 0,
  "opponentScore": 0,
  "lineup": [],
  "seasonId": null
}
```

**Response (201):**
```json
{
  "gameId": "c8d39946-9264-6038-c6f5-d4405gh72c2b",
  "teamId": "...",
  "status": "SCHEDULED",
  "scheduledStart": "2025-11-01T19:30:00.000Z",
  "opponentName": "Portland Pioneers",
  "location": "Lincoln Park Field 3",
  "teamScore": 0,
  "opponentScore": 0,
  "lineup": [],
  "createdAt": "...",
  "updatedAt": "..."
}
```

**Game Status Values:** `SCHEDULED`, `IN_PROGRESS`, `FINAL`, `POSTPONED`

**Error Codes:**
- `400`: Invalid status or lineup
- `403`: Insufficient permissions
- `404`: Team not found

---

### 2. List Games

**Handler:** `src/games/list/handler.py`  
**Route:** `GET /teams/{teamId}/games`  
**Authorization:** Must be team member

**Path Parameters:**
- `teamId` (required): Team UUID

**Query Parameters:**
- `status` (optional): Filter by status
- `limit` (optional): Max results (default: 50)

**Response (200):**
```json
[
  {
    "gameId": "...",
    "teamId": "...",
    "status": "SCHEDULED",
    "scheduledStart": "...",
    "opponentName": "...",
    "location": "...",
    "teamScore": 0,
    "opponentScore": 0,
    "lineup": [],
    "createdAt": "...",
    "updatedAt": "..."
  }
]
```

---

### 3. Get Game

**Handler:** `src/games/get/handler.py`  
**Route:** `GET /games/{gameId}`  
**Authorization:** Must be member of game's team

**Path Parameters:**
- `gameId` (required): Game UUID

**Response (200):** Single game object

**Error Codes:**
- `403`: Not a team member
- `404`: Game not found

---

### 4. Update Game

**Handler:** `src/games/update/handler.py`  
**Route:** `PATCH /games/{gameId}`  
**Authorization:** owner, manager, or scorekeeper role

**Path Parameters:**
- `gameId` (required): Game UUID

**Request Body:**
```json
{
  "status": "FINAL",
  "teamScore": 8,
  "opponentScore": 5,
  "scheduledStart": "2025-11-02T19:00:00.000Z",
  "opponentName": "Updated Name",
  "location": "Updated Location"
}
```

**Allowed Fields:** `status`, `scheduledStart`, `opponentName`, `location`, `teamScore`, `opponentScore`, `lineup`, `seasonId`  
**Read-Only Fields:** `gameId`, `teamId`, `createdAt`

**Response (200):** Updated game object

**Error Codes:**
- `400`: Invalid fields
- `403`: Insufficient permissions
- `404`: Game not found

---

### 5. Delete Game

**Handler:** `src/games/delete/handler.py`  
**Route:** `DELETE /games/{gameId}`  
**Authorization:** owner, manager, or scorekeeper role

**Path Parameters:**
- `gameId` (required): Game UUID

**Response (204):** No content

**Error Codes:**
- `403`: Insufficient permissions
- `404`: Game not found

---

## Common Patterns

### Request Headers

All API requests require:
```
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
```

### Response Format

**Success:**
```json
{
  "statusCode": 200,
  "body": { ...data... },
  "headers": {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*"
  }
}
```

**Error:**
```json
{
  "statusCode": 400,
  "body": {
    "error": "Detailed error message"
  }
}
```

### Timestamps

All timestamps are ISO 8601 format in UTC:
```
"2025-10-30T12:00:00.000Z"
```

### UUIDs

All entity IDs are UUID v4:
```
"a6f27724-7042-4816-94d3-a2183ef50a09"
```

---

## Error Codes

| Code | Meaning | Common Causes |
|------|---------|---------------|
| 400 | Bad Request | Invalid JSON, missing required fields, validation errors |
| 403 | Forbidden | Insufficient permissions, not a team member |
| 404 | Not Found | Entity doesn't exist |
| 409 | Conflict | Duplicate player number, resource already exists |
| 500 | Internal Server Error | DynamoDB errors, unexpected exceptions |

---

## Authorization Roles

| Role | Permissions |
|------|-------------|
| **owner** | Full control, can delete team |
| **manager** | Manage roster, schedule games, record stats |
| **player** | View team data, edit own profile |
| **scorekeeper** | Record stats during games |

**See:** [authorization.md](./authorization.md) for complete authorization details

---

## See Also

- **[ARCHITECTURE.md](../ARCHITECTURE.md)** - Complete system design
- **[dynamodb-design.md](./dynamodb-design.md)** - Database schema
- **[authorization.md](./authorization.md)** - Authorization system

