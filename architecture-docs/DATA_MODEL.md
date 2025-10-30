# HackTracker Data Model - Current Implementation

**Last Updated:** October 30, 2025  
**Status:** MVP Complete - 21 Lambda Functions Implemented

This document provides a quick reference snapshot of HackTracker's current implementation.

---

## Quick Stats

| Metric | Count |
|--------|-------|
| **Lambda Functions** | 21 |
| **Implemented Entities** | 4 (User, Team, Player, Game) |
| **API Routes** | 21 |
| **DynamoDB GSIs** | 5 (3 active, 2 reserved) |
| **Test Coverage** | 72% |
| **Frontend Screens** | 8 |

---

## Implemented Entities

### User
- **Storage:** `USER#<userId>` → `METADATA`
- **Attributes:** userId (Cognito sub), email, firstName, lastName, phoneNumber
- **Operations:** Create (Cognito trigger), Get, Query, Update, Delete, Get Context
- **Frontend:** Profile management, authentication

### Team
- **Storage:** `TEAM#<teamId>` → `METADATA`
- **Attributes:** teamId, name, description, ownerId, team_type (MANAGED/PERSONAL)
- **Operations:** Create, Get, Query, Update, Delete
- **Team Types:**
  - `MANAGED`: Full roster management (default)
  - `PERSONAL`: Single-owner stat filtering label
- **Frontend:** Team creation, team selection, team management

### Player
- **Storage:** `TEAM#<teamId>` → `PLAYER#<playerId>`
- **Attributes:** playerId, teamId, firstName, lastName, playerNumber, positions, status, isGhost, userId (optional)
- **Operations:** Add, List, Get, Update, Remove
- **Player Types:**
  - **Ghost Player** (`isGhost: true`): Roster slot not linked to user
  - **Linked Player** (`isGhost: false`): Connected to registered user
- **Frontend:** Roster management, player forms

### Game
- **Storage:** `GAME#<gameId>` → `METADATA`
- **Attributes:** gameId, teamId, status, scheduledStart, opponentName, location, teamScore, opponentScore, lineup
- **Operations:** Create, List (by team), Get, Update, Delete
- **Status Values:** `SCHEDULED`, `IN_PROGRESS`, `FINAL`, `POSTPONED`
- **Frontend:** Schedule tab, game forms, game cards

---

## Team Membership

**Storage:** `USER#<userId>` → `TEAM#<teamId>`

**Roles:**
- `owner`: Team creator, full control
- `manager`: Coach/assistant, manages roster and games
- `player`: Team member, views and edits own profile
- `scorekeeper`: Records stats during games

**Relationships:**
- One user can be on multiple teams
- Each user-team relationship has a specific role
- Roles are team-scoped (user can have different roles on different teams)

---

## Lambda Functions by Domain

### Users (6 functions)
1. **create-user** - Cognito post-confirmation trigger
2. **get-user** - GET /users/{userId}
3. **query-users** - GET /users
4. **update-user** - PUT /users/{userId}
5. **delete-user** - DELETE /users/{userId}
6. **context-user** - GET /users/context

### Teams (5 functions)
7. **create-team** - POST /teams
8. **get-team** - GET /teams/{teamId}
9. **query-teams** - GET /teams
10. **update-team** - PUT /teams/{teamId}
11. **delete-team** - DELETE /teams/{teamId}

### Players (5 functions)
12. **add-player** - POST /teams/{teamId}/players
13. **list-players** - GET /teams/{teamId}/players
14. **get-player** - GET /teams/{teamId}/players/{playerId}
15. **update-player** - PUT /teams/{teamId}/players/{playerId}
16. **remove-player** - DELETE /teams/{teamId}/players/{playerId}

### Games (5 functions)
17. **create-game** - POST /games
18. **list-games** - GET /teams/{teamId}/games
19. **get-game** - GET /games/{gameId}
20. **update-game** - PATCH /games/{gameId}
21. **delete-game** - DELETE /games/{gameId}

---

## DynamoDB Access Patterns

### Active GSIs

**GSI1: Cognito Lookup**
- Purpose: Find user by Cognito sub (login flow)
- Keys: `GSI1PK = COGNITO#<sub>`, `GSI1SK = USER`
- Usage: User authentication

**GSI2: Entity Listing**
- Purpose: List all entities of a type
- Keys: `GSI2PK = ENTITY#<type>`, `GSI2SK = METADATA#<id>`
- Usage: List all users, teams, or games

**GSI3: Games by Team**
- Purpose: Query games for a specific team
- Keys: `GSI3PK = TEAM#<teamId>`, `GSI3SK = GAME#<gameId>`
- Usage: Team schedule, game history

### Reserved GSIs (Future Features)

**GSI4: User's Players**
- Purpose: Cross-team player stats
- Keys: `GSI4PK = USER#<userId>`, `GSI4SK = PLAYER#<playerId>`
- Status: Defined but not populated

**GSI5: Player Stats**
- Purpose: At-bat aggregation
- Keys: `GSI5PK = PLAYER#<playerId>`, `GSI5SK = ATBAT#<atBatId>`
- Status: Defined but not populated

---

## Frontend Screens

### Authentication
1. **Login Screen** - Email/password authentication
2. **Signup Screen** - New user registration
3. **Forgot Password Screen** - Password reset

### Main App
4. **Welcome Screen** - First-time user flow (Solo User vs Team Manager)
5. **Dynamic Home Screen** - Adapts based on user context
6. **Team View Screen** - Team details with tabs (Stats, Schedule, Roster, Chat)
7. **Player View Screen** - Personal stats view
8. **Profile Screen** - User profile management
9. **Recruiter Screen** - (Placeholder)
10. **Team Creation Screen** - Create new team

---

## State Management

**Technology:** Riverpod 3.0+

**Providers:**
- `teamsProvider` - Team list with SWR caching
- `selectedTeamProvider` - Currently selected team
- `rosterProvider` - Team roster with roles
- `gamesProvider` - Games by team with SWR caching
- `currentUserProvider` - Current user profile
- `userContextProvider` - UI context (teams, permissions)

**Pattern:** Persistent cache + Stale-While-Revalidate + Optimistic UI

---

## Authorization Policy Map

```python
POLICY_MAP = {
    'manage_roster': ['owner', 'manager'],
    'manage_team': ['owner', 'manager'],
    'delete_team': ['owner'],
    'manage_games': ['owner', 'manager', 'scorekeeper'],
}
```

**See:** [api/authorization.md](./api/authorization.md)

---

## Validation Rules

### Team
- Name: 3-50 characters, alphanumeric + spaces/hyphens
- Description: Max 500 characters (optional)

### Player
- Name: 1-50 characters each
- Number: 0-99, unique per team
- Positions: Max 2 positions per player, valid position codes
- Status: `active`, `inactive`, `sub`

### Game
- Status: `SCHEDULED`, `IN_PROGRESS`, `FINAL`, `POSTPONED`
- Scores: Non-negative integers
- Lineup: Array of valid player IDs from team roster

---

## Future Features (Not Yet Implemented)

The following entities are planned but not yet implemented:

- **League**: Multi-team organization
- **Season**: Group of games (team or league level)
- **AtBat**: Individual play event (stat tracking)
- **FreeAgent**: Player availability listing
- **Invite**: Team invitation system

---

## Technology Stack

### Backend
- **Runtime:** Python 3.13
- **Platform:** AWS Lambda (ARM64)
- **Database:** DynamoDB (single-table, PAY_PER_REQUEST)
- **API:** API Gateway (HTTP API)
- **Auth:** Amazon Cognito (JWT)
- **Infrastructure:** Terraform

### Frontend
- **Framework:** Flutter 3.9+
- **Language:** Dart 3.9+
- **State:** Riverpod 3.0+
- **Storage:** Shared Preferences (hydrated_riverpod)
- **Platforms:** iOS, Android, Web

### Development
- **Package Manager:** uv (Python)
- **Testing:** pytest + moto (72% coverage)
- **CI/CD:** GitLab CI

---

## Deployment

### Infrastructure
- **DynamoDB Table:** `hacktracker-{environment}`
- **Lambda Prefix:** `hacktracker-{environment}-`
- **API Gateway:** `hacktracker-{environment}-api`
- **Cognito Pool:** `hacktracker-{environment}-pool`

### Environments
- **test**: Local testing environment
- **prod**: Production environment

---

## Related Documentation

- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Complete system architecture
- **[api/lambda-functions.md](./api/lambda-functions.md)** - All 21 Lambda functions
- **[api/dynamodb-design.md](./api/dynamodb-design.md)** - Database schema
- **[api/authorization.md](./api/authorization.md)** - Authorization system
- **[TESTING.md](./TESTING.md)** - Testing guide
- **[ui/OPTIMISTIC_UI_GUIDE.md](./ui/OPTIMISTIC_UI_GUIDE.md)** - Optimistic UI patterns

---

**Current Status:** MVP complete with Users, Teams, Players, and Games fully functional. Ready for at-bat stat tracking implementation.

