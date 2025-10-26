# ⚾ HackTracker Softball — Architecture & Implementation Guide

*(A multi-tenant stat-tracking platform for Players, Teams, and Leagues)*

> **📖 Documentation Guide:**
> - **This document (ARCHITECTURE.md):** Complete system design, current + future features, architectural rationale (WHAT + WHY)
> - **[DATA_MODEL.md](./DATA_MODEL.md):** Current implementation snapshot, what exists right now (WHAT only)

---

## 🧭 1. System Overview

**Goal:**
Provide a flexible ecosystem where:

* Individual players can track personal stats
* Teams can manage rosters, schedules, and record games
* Leagues can organize official seasons and tournaments
* Free agents/subs can find and join temporary opportunities

**Design Priorities:**

* Scalable (multi-tenant DynamoDB schema)
* Modular (Lambda-driven microservices)
* Secure (Cognito-based RBAC)
* Extensible (easily add new entities later — e.g., tournaments, standings)
* Multi-context (supports both team-created and league-managed seasons)

---

## 🧱 2. High-Level Architecture

### 🧩 Tech Stack

| Layer          | Service                           |
| -------------- | --------------------------------- |
| Frontend       | Flutter (iOS + Android + Web)     |
| Auth           | Amazon Cognito                    |
| API            | API Gateway + AWS Lambda (Python) |
| Database       | DynamoDB (single-table design)    |
| File Storage   | S3 (logos, exports, media)        |
| Events         | DynamoDB Streams + EventBridge    |
| Observability  | CloudWatch + X-Ray                |
| Infrastructure | Terraform                         |
| CI/CD          | GitLab CI                         |

### Frontend State Management

**Technology:** Riverpod 2.6+

**Pattern:** Persistent caching with stale-while-revalidate (SWR) + Race-Condition-Safe Optimistic UI

**Implementation:**
- **Persistent cache** via Shared Preferences for key providers (teams, roster, current user)
- **Cache versioning** - auto-clear on schema changes (increment `Persistence.cacheVersion`)
- Cached data shown instantly on cold start and navigation (no loading screens)
- Fresh data fetched in background automatically (SWR)
- Pull-to-refresh for manual refresh
- **Optimistic updates** for CRUD: mutate UI immediately, run Lambda in background, rollback on failure
- **Safe rollback pattern** - uses rollback functions instead of snapshots to prevent race conditions
- Cache updated on successful mutations; cleared on logout

**Optimistic UI Pattern:**
```dart
// All mutations use the safe mutate() extension
await notifier.mutate(
  optimisticUpdate: (current) => /* add/update/remove from current state */,
  apiCall: () => api.doSomething(),
  applyResult: (current, result) => /* apply real result to current state */,
  rollback: (current) => /* undo from current state (not snapshot!) */,
  successMessage: 'Success!',
  errorMessage: (e) => 'Failed: $e',
);
```

**Key Safety Feature:**
- Rollback functions operate on **current state**, not previous snapshots
- Prevents race conditions when multiple operations happen concurrently
- Example: If User adds Player A (succeeds) then Player B (fails), rollback removes only Player B without losing Player A

**Benefits:**
- ✅ Instant cold-start UX (teams/roster/current user available offline)
- ✅ Perceived performance: UI reacts immediately to user actions
- ✅ Race-condition safe: handles concurrent mutations correctly
- ✅ Automatic rollback: errors handled gracefully with toast notifications
- ✅ Reduced API calls and Lambda invocations
- ✅ Consistent, resilient UX across screens
- ✅ Easy to test with provider overrides

**See Also:** `OPTIMISTIC_UI_GUIDE.md` for complete implementation guide

---

## 🧠 3. Domain Model

### Core Entities

| Entity        | Description                                                                |
| ------------- | -------------------------------------------------------------------------- |
| **User**      | Registered app user (Cognito account) - can own/join multiple teams       |
| **Player**    | Roster slot on a team - can be "ghost" (unlinked) or linked to a User     |
| **Team**      | Collection of players, schedule, stats - owned by a User                   |
| **League**    | Organizer of multiple teams, seasons, and tournaments                      |
| **Season**    | Group of games belonging to either a team or league                        |
| **Game**      | Individual match (may belong to a league season or team season)            |
| **AtBat**     | Single play event (atomic unit of stat tracking) - always linked to Player |
| **FreeAgent** | Player advertising availability to teams                                   |
| **Invite**    | Pending invitation to join a team (email-based, 1 week expiration)         |

### User vs Player Distinction

**Critical Concept:** Users and Players are separate entities.

| Concept    | Description                                                                    |
| ---------- | ------------------------------------------------------------------------------ |
| **User**   | A person with a Cognito account (userId = Cognito sub)                        |
| **Player** | A roster slot on a team (playerId = UUID) - may or may not be linked to User  |
| **Link**   | Connection between User and Player (`TEAM#id → PLAYER#playerId → userId`)     |

**Why This Matters:**
- A User can be linked to multiple Players (one per team they're on)
- A Player can exist without a User ("ghost player" - coach creates roster slot first)
- When a User leaves a team, the Player record remains (preserves team's historical stats)
- When a User deletes their account, they're unlinked from Players (stats stay with team)

**Example Flow:**
1. Coach creates Team → adds 10 "ghost" Players to roster
2. Coach invites User via email → links User to specific Player
3. User accepts → now linked to that Player on that Team
4. User records at-bats → stored under Player (which is linked to User)
5. User leaves Team → link broken, but Player + at-bats remain for team
6. User can still query their historical stats from that Team

---

## 🧩 4. Ownership Model

Every major entity (Season, Game, Tournament) has a single **owner**:

* **Team-owned** → editable by team
* **League-owned** → editable by league only
* Teams get **read-only mirrors** of league-owned records

| Entity          | Owner        | Editable By  | Visible To                   |
| --------------- | ------------ | ------------ | ---------------------------- |
| League          | League Admin | League Admin | All teams                    |
| Team            | Coach/Owner  | Coach/Owner  | Players                      |
| Season (team)   | Team         | Team         | Team                         |
| Season (league) | League       | League Admin | All linked teams (read-only) |
| Game (team)     | Team         | Team         | Team                         |
| Game (league)   | League       | League Admin | Linked teams (read-only)     |

---

## 🧬 5. DynamoDB Single-Table Design

### Table Name

`hacktracker-{environment}` (e.g., `hacktracker-test`, `hacktracker-prod`)

### Partition / Sort Keys

| PK                                    | SK                  | Description                                     |
| ------------------------------------- | ------------------- | ----------------------------------------------- |
| `USER#<userId>`                       | `METADATA`          | User profile                                    |
| `USER#<userId>`                       | `TEAM#<teamId>`     | User's team membership (for querying)           |
| `TEAM#<teamId>`                       | `METADATA`          | Team info                                       |
| `TEAM#<teamId>`                       | `PLAYER#<playerId>` | Player roster record (may have userId link)     |
| `TEAM#<teamId>`                       | `INVITE#<inviteId>` | Pending team invite                             |
| `TEAM#<teamId>#SEASON#<seasonId>`     | `METADATA`          | Team season info                                |
| `TEAM#<teamId>#SEASON#<seasonId>`     | `GAME#<gameId>`     | Game under a team season                        |
| `GAME#<gameId>`                       | `METADATA`          | Game info (owner, score, status)                |
| `GAME#<gameId>`                       | `ATBAT#<atBatId>`   | **Individual at-bat record (PRIMARY)**          |
| `PLAYER#<playerId>`                   | `METADATA`          | Player info (for cross-team queries)            |
| `LEAGUE#<leagueId>`                   | `METADATA`          | League info                                     |
| `LEAGUE#<leagueId>#SEASON#<seasonId>` | `METADATA`          | League season info                              |
| `LEAGUE#<leagueId>#SEASON#<seasonId>` | `GAME#<gameId>`     | League game info (W/L, scores only)             |
| `LEAGUE#<leagueId>#SEASON#<seasonId>` | `TEAM#<teamId>`     | Team participation link                         |
| `FREEAGENCY#<region>`                 | `USER#<userId>`     | Free agent listing                              |

### Common Fields

```json
{
  "createdAt": "2025-10-24T00:00:00Z",
  "updatedAt": "2025-10-24T00:00:00Z",
  "ownerType": "team" | "league",
  "isEditable": true | false,
  "inheritedFromLeague": true | false
}
```

### GSIs (5 Total)

| Index    | PK                        | SK                  | Purpose                                | Why Essential |
| -------- | ------------------------- | ------------------- | -------------------------------------- | ------------- |
| **GSI1** | `COGNITO#<sub>`           | `USER`              | Lookup user by Cognito sub             | Login flow - no alternative |
| **GSI2** | `ENTITY#<type>`           | `METADATA#<id>`     | List entities by type (teams, leagues) | Generic entity queries |
| **GSI3** | `REGION#<city>`           | `USER#<userId>`     | Find free agents/subs by region        | Geographic search - no alternative |
| **GSI4** | `USER#<userId>`           | `PLAYER#<playerId>` | Find all players linked to a user      | User's cross-team stats - no alternative |
| **GSI5** | `PLAYER#<playerId>`       | `ATBAT#<atBatId>`   | Query all at-bats for a player         | Player stats aggregation - no alternative |

### Eliminated GSIs & Alternatives

| Removed GSI | Original Purpose | Alternative Solution |
|-------------|------------------|---------------------|
| ~~Email lookup~~ | User by email | Use Cognito `ListUsers` API (rare operation) |
| ~~League→Teams~~ | League's teams | Query `LEAGUE#id → TEAM#*` (already PK/SK) |
| ~~Email→Invites~~ | Invites by email | Query `TEAM#id → INVITE#*` and filter (rare operation) |
| ~~Season→Games~~ | Season's games | Query `TEAM#id#SEASON#id → GAME#*` (already PK/SK) |

**Note:** Game→AtBats doesn't need a GSI because `GAME#<id> → ATBAT#*` is the primary key pattern.

### Query Patterns with 5 GSIs

#### ✅ GSI1: User Login
- **Query:** `COGNITO#<sub>` → Returns user record
- **Use Case:** Every login, JWT validation
- **Frequency:** High

#### ✅ GSI2: Generic Entity Listing
- **Query:** `ENTITY#TEAM` → Returns all teams
- **Query:** `ENTITY#LEAGUE` → Returns all leagues
- **Query:** `ENTITY#GAME` + `STATUS#active` → Returns active games
- **Use Case:** Admin dashboards, search, listings
- **Frequency:** Medium

#### ✅ GSI3: Geographic Search
- **Query:** `REGION#<city>` → Returns users in that region
- **Use Case:** Free agent discovery by location
- **Frequency:** Low

#### ✅ GSI4: User's Players
- **Query:** `USER#<userId>` → Returns all players linked to user
- **Use Case:** User dashboard showing stats across all teams
- **Frequency:** High (every dashboard load)

#### ✅ GSI5: Player Stats
- **Query:** `PLAYER#<playerId>` → Returns all at-bats for player
- **Use Case:** Player dashboard, stat aggregation
- **Frequency:** High (every stat view)

#### ✅ Direct PK/SK Queries (No GSI Needed)

| Query | Pattern | Returns |
|-------|---------|---------|
| Team roster | `TEAM#<id>` + `SK` begins with `PLAYER#` | All players |
| Game at-bats | `GAME#<id>` + `SK` begins with `ATBAT#` | All at-bats |
| League teams | `LEAGUE#<id>#SEASON#<id>` + `SK` begins with `TEAM#` | All teams |
| User's teams | `USER#<id>` + `SK` begins with `TEAM#` | All memberships |

#### ✅ Aggregation Tables (Stream-Powered)

| Query | Pattern | Returns |
|-------|---------|---------|
| Player stats | `PLAYERSTATS#<id>` → `AGGREGATE` | Pre-computed totals |
| User stats | `USERSTATS#<id>` → `AGGREGATE` | Cross-team totals |
| Team stats | `TEAMSTATS#<id>` → `AGGREGATE` | Season totals |

### GSI Design Rationale

**Why 5 GSIs?**

1. **GSI1 (Cognito)** - No alternative for login flow
2. **GSI2 (Entity)** - Generic listing (replaces 4+ specific GSIs)
3. **GSI3 (Region)** - Geographic search has no alternative
4. **GSI4 (User→Players)** - Cross-team user stats (survives team deletion)
5. **GSI5 (Player→AtBats)** - Player stat aggregation (hot path)

**Why not more?**
- **Most queries use PK/SK directly** - Single-table design shines here
- **Cost efficiency** - Each GSI doubles your storage cost
- **Simpler maintenance** - Fewer indexes = fewer things to break
- **Better performance** - Fewer indexes = faster writes

**Trade-off:** 5 GSIs is the sweet spot - covers essential queries without explosion.

### AtBat Structure

```json
{
  "PK": "GAME#<gameId>",
  "SK": "ATBAT#<atBatId>",
  "atBatId": "uuid",
  "gameId": "uuid",
  "playerId": "uuid",
  "teamId": "uuid",
  "seasonId": "uuid (optional)",
  "leagueId": "uuid (optional)",
  "tournamentId": "uuid (optional)",
  "inning": 1,
  "battingOrder": 3,
  "result": "1B" | "2B" | "3B" | "HR" | "K" | "BB" | "OUT",
  "hitLocation": {"x": 120, "y": 85},
  "hitType": "line_drive" | "fly_ball" | "ground_ball" | "fly_out" | "ground_out" | "line_out" | "foul_out",
  "rbis": 2,
  "runnersOnBase": {
    "first": true,
    "second": false,
    "third": true
  },
  "runnersAdvanced": {
    "first": "scored",
    "third": "scored"
  },
  "outs": 1,
  "createdAt": "2025-10-24T00:00:00Z",
  "GSI5PK": "PLAYER#<playerId>",
  "GSI5SK": "ATBAT#<atBatId>"
}
```

### Player Structure

```json
{
  "PK": "TEAM#<teamId>",
  "SK": "PLAYER#<playerId>",
  "playerId": "uuid",
  "teamId": "uuid",
  "userId": "uuid (optional - null for ghost players)",
  "firstName": "John",
  "lastName": "Doe",
  "playerNumber": 12,
  "status": "active" | "inactive" | "sub",
  "isGhost": true | false,
  "createdAt": "2025-10-24T00:00:00Z",
  "updatedAt": "2025-10-24T00:00:00Z",
  "linkedAt": "2025-10-24T00:00:00Z (when user linked, null for ghost players)",
  "GSI4PK": "USER#<userId>",
  "GSI4SK": "PLAYER#<playerId>"
}
```

**Note:** 
- GSI4 fields only populated when `userId` is not null (i.e., not a ghost player).
- `position` and `battingOrder` are not tracked on player record - hitting-focused stats only (MVP).
- `battingOrder` will be tracked per-game in lineup, not as a player attribute.

### Team Structure

```json
{
  "PK": "TEAM#<teamId>",
  "SK": "METADATA",
  "teamId": "uuid",
  "name": "Seattle Sluggers",
  "ownerId": "userId",
  "status": "active" | "deleted",
  "createdAt": "2025-10-24T00:00:00Z",
  "updatedAt": "2025-10-24T00:00:00Z",
  "GSI2PK": "ENTITY#TEAM",
  "GSI2SK": "METADATA#<teamId>"
}
```

### User Structure

```json
{
  "PK": "USER#<userId>",
  "SK": "METADATA",
  "userId": "uuid (Cognito sub)",
  "email": "user@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "phoneNumber": "+15555551234",
  "status": "active" | "deleted",
  "createdAt": "2025-10-24T00:00:00Z",
  "updatedAt": "2025-10-24T00:00:00Z",
  "GSI1PK": "COGNITO#<userId>",
  "GSI1SK": "USER"
}
```

**Note:** Region and availability information is stored separately in the Free Agent profile (see below), not in the base user record.

### Free Agent Listing

```json
{
  "PK": "USER#<userId>",
  "SK": "FREEAGENT",
  "userId": "uuid",
  "region": "seattle",
  "position": "SS",
  "availability": "weekends",
  "createdAt": "2025-10-24T00:00:00Z",
  "GSI3PK": "REGION#seattle",
  "GSI3SK": "USER#<userId>"
}
```

### Player Stats Aggregate (Stream-Generated)

```json
{
  "PK": "PLAYERSTATS#<playerId>",
  "SK": "AGGREGATE",
  "playerId": "uuid",
  "teamId": "uuid",
  "atBats": 120,
  "hits": 45,
  "avg": 0.375,
  "homeRuns": 8,
  "rbis": 32,
  "strikeouts": 25,
  "walks": 15,
  "lastUpdated": "2025-10-24T00:00:00Z"
}
```

### Invite Structure

```json
{
  "PK": "TEAM#<teamId>",
  "SK": "INVITE#<inviteId>",
  "inviteId": "uuid",
  "teamId": "uuid",
  "playerId": "uuid (ghost player to link to)",
  "email": "user@example.com",
  "invitedBy": "userId",
  "status": "pending" | "accepted" | "revoked" | "expired",
  "expiresAt": "2025-10-31T00:00:00Z (1 week)",
  "createdAt": "2025-10-24T00:00:00Z"
}
```

**Note:** No GSI needed - query `TEAM#<teamId> → INVITE#*` and filter by email (rare operation).

---

## ⚙️ 6. Lambda Function Breakdown

| Lambda               | Purpose                                | Trigger         | Notes |
| -------------------- | -------------------------------------- | --------------- | ----- |
| `post-confirmation`  | Create user profile in DynamoDB        | Cognito         | ✅ Implemented |
| `get-user`           | Retrieve user profile by ID            | API             | ✅ Implemented |
| `query-users`        | List/search users                      | API             | ✅ Implemented |
| `update-user`        | Update user profile                    | API             | ✅ Implemented |
| `delete-user`        | Soft delete user                       | API             | ✅ Implemented |
| `create-team`        | Create team + owner record atomically  | API             | ✅ Implemented |
| `get-team`           | Retrieve team by ID                    | API             | ✅ Implemented |
| `query-teams`        | List/search teams                      | API             | ✅ Implemented |
| `update-team`        | Update team metadata                   | API             | ✅ Implemented |
| `delete-team`        | Soft delete team                       | API             | ✅ Implemented |
| `add-player`         | Add ghost player to roster             | API             | ✅ Implemented |
| `list-players`       | List team roster                       | API             | ✅ Implemented |
| `get-player`         | Retrieve player by ID                  | API             | ✅ Implemented |
| `update-player`      | Update player details                  | API             | ✅ Implemented |
| `remove-player`      | Remove ghost player from roster        | API             | ✅ Implemented |
| `invite-player`      | Send invite link/email                 | API             | 🔜 Planned |
| `join-team`          | Add player to roster                   | API             | 🔜 Planned |
| `create-season`      | Create season (team or league context) | API             | 🔜 Planned |
| `update-season`      | Update season metadata                 | API             | 🔜 Planned |
| `record-game`        | Add game + at-bats                     | API             | 🔜 Planned |
| `sync-league-season` | Mirror league seasons/games to teams   | DynamoDB Stream | 🔜 Planned |
| `get-dashboard`      | Fetch stats for user/team/league       | API             | 🔜 Planned |
| `join-free-agency`   | Add user to FA pool                    | API             | 🔜 Planned |
| `search-free-agents` | Query regional pool                    | API             | 🔜 Planned |
| `invite-sub`         | Invite free agent to team              | API             | 🔜 Planned |
| `accept-sub`         | Join as sub                            | API             | 🔜 Planned |
| `aggregate-stats`    | Compute averages, slugging, etc.       | Stream/Event    | ⚠️ See §15.1 for scale improvements |

---

## 🗓️ 7. Lifecycle Flows

### 7.1 Player Flow

1. Sign up → Cognito triggers `post-confirmation` Lambda → Creates `USER#id`
2. Player can:

   * Join an existing team via invite codez
   * Create personal stats profile
   * Join free agent pool (optional)

---

### 7.2 Team Flow

1. Coach creates a team (`TEAM#id`)
2. Adds players manually or via invites
3. Creates a **team-owned season**

   * `TEAM#id#SEASON#2025SPRING`
4. Adds games + records at-bats
5. Team dashboard shows cumulative stats

---

### 7.3 League Flow

1. League admin creates league (`LEAGUE#id`)
2. Creates **league-owned season**

   * `LEAGUE#id#SEASON#2025SPRING`
3. Adds teams via `TEAMSEASONLINK` (`LEAGUE#id#SEASON#id` → `TEAM#id`)
4. Creates league games
5. Sync Lambda mirrors read-only season + games to all teams
6. League dashboard aggregates standings & leaderboards

---

### 7.4 Free Agent Flow

1. Player opts into `FREEAGENCY#<region>`
2. Teams query by position/region
3. Coach sends invite
4. Player accepts → temporary roster record created (`TEAM#id` + `PLAYER#id`, `status=sub`)
5. Optional auto-expiration after game

---

## 🧩 8. Syncing & Inheritance Logic

### 8.1 When League Updates a Season

1. League updates `LEAGUE#id#SEASON#id`
2. DynamoDB Stream triggers `sync-league-season`
3. For each linked team in `TEAMSEASONLINK`, the function:

   * Upserts mirror record under `TEAM#id#SEASON#id`
   * Marks `isEditable = false`, `inheritedFromLeague = true`
   * Sends SNS → Frontend refresh event

---

### 8.2 When League Adds a Game

1. League creates game under `LEAGUE#id#SEASON#id → GAME#id`
2. Game record contains:
   - `homeTeamId`, `awayTeamId`
   - `homeScore`, `awayScore` (league-controlled)
   - `status`: "scheduled" | "in_progress" | "final"
   - `ownerType`: "league"
   - `isEditable`: false (for teams)
3. Stream triggers `sync-league-game` Lambda
4. Lambda creates read-only mirrors:
   - `TEAM#homeTeamId#SEASON#seasonId → GAME#id` (mirror)
   - `TEAM#awayTeamId#SEASON#seasonId → GAME#id` (mirror)
5. Teams can view game but **cannot edit** W/L or final scores
6. Teams **can** record AtBats for their own players:
   - AtBats stored under `GAME#id → ATBAT#*`
   - AtBats link to `PLAYER#id` (team's roster)
   - League doesn't see individual AtBats (only cares about W/L)

**Key Insight:** 
- League controls **game outcomes** (W/L, scores)
- Teams control **detailed stats** (at-bats, hit locations)
- No conflict because they're different data layers

### 8.3 League-Team Participation

**When League creates a season:**

1. League admin enters team names (can be "ghost teams" without app accounts)
2. For teams with app accounts:
   - League sends invite via `LEAGUE#id#SEASON#id → INVITE#teamId`
   - Team coach accepts → creates link record
   - Link: `LEAGUE#id#SEASON#id → TEAM#teamId` (participation)
3. For teams without app accounts:
   - League creates "ghost team" record
   - Only W/L and scores tracked (no detailed stats)
4. Team can participate in multiple leagues simultaneously
5. If team withdraws:
   - Delete link record
   - Team's mirror records remain (historical data)
   - League's authoritative records remain unchanged

---

## 🔐 9. Access Control (Cognito + Team-Scoped Roles)

### 9.1 Global vs Team-Scoped Roles

**Problem with Global Roles:**
- A user might be a coach on Team A but just a player on Team B
- Can't have different permissions per team
- Cognito groups are too rigid

**Solution: Team-Scoped Roles**

### 9.2 Role Hierarchy

| Level | Role | Scope | Capabilities |
|-------|------|-------|--------------|
| **Global** | `system-admin` | All entities | Full system access (internal ops) |
| **League** | `league-admin` | Specific league | Manage league, seasons, games, teams |
| **League** | `league-scorekeeper` | Specific league | Record game scores, W/L only |
| **Team** | `team-owner` | Specific team | Full team control, delete team |
| **Team** | `team-coach` | Specific team | Manage roster, create games, record stats |
| **Team** | `team-assistant` | Specific team | Record stats, view roster (no edits) |
| **Team** | `team-scorekeeper` | Specific team | Record at-bats during games only |
| **Team** | `team-player` | Specific team | View team data, edit own profile |
| **Team** | `team-viewer` | Specific team | Read-only access (parents, fans) |

### 9.3 Team Membership Structure

```json
{
  "PK": "USER#<userId>",
  "SK": "TEAM#<teamId>",
  "userId": "uuid",
  "teamId": "uuid",
  "role": "team-coach" | "team-player" | "team-scorekeeper" | "team-assistant" | "team-viewer",
  "playerId": "uuid (optional - if linked to roster)",
  "joinedAt": "2025-10-24T00:00:00Z",
  "invitedBy": "userId",
  "status": "active" | "inactive"
}
```

**Important:** Only the `role` is stored. Permissions are resolved at runtime by the policy engine (see §15.2).

### 9.4 League Membership Structure

```json
{
  "PK": "USER#<userId>",
  "SK": "LEAGUE#<leagueId>",
  "userId": "uuid",
  "leagueId": "uuid",
  "role": "league-admin" | "league-scorekeeper" | "league-viewer",
  "joinedAt": "2025-10-24T00:00:00Z",
  "status": "active"
}
```

**Important:** Only the `role` is stored. Permissions are resolved at runtime by the policy engine (see §15.2).

### 9.5 Permission Checking Flow

**How permissions are enforced:**

1. Extract user ID from Cognito JWT token
2. Check if user is system admin (global override)
3. Query user's membership record: `USER#<userId> → TEAM#<teamId>`
4. Verify membership status is `active`
5. **Resolve role to permissions** (via policy engine - see §15.2)
6. Check if resolved permissions include the required permission
7. Allow or deny the action

**Key Insight:** Permissions are **never stored** in the database - only roles. This allows changing what a role can do without updating every membership record.

### 9.6 Role-Based Permissions Matrix

| Permission | Owner | Coach | Assistant | Scorekeeper | Player | Viewer |
|------------|-------|-------|-----------|-------------|--------|--------|
| Edit team metadata | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Delete team | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Manage roster | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Send invites | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| Create games | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| Record at-bats | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| Edit at-bats | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| View roster | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| View stats | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Edit own profile | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |

### 9.7 League-Managed Game Permissions

**Special Case: League Games**

| Game Owner | Who Can Edit W/L | Who Can Record At-Bats |
|------------|------------------|------------------------|
| League | League admins/scorekeepers only | Team coaches/scorekeepers |
| Team | Team coaches/scorekeepers | Team coaches/scorekeepers |

**Key Insight:** League controls game outcomes, teams control detailed stats.

### 9.8 Role Assignment Flow

**1. Team Owner (automatic on team creation)**
- User creates team → automatically assigned `team-owner` role
- Membership record created: `USER#<userId> → TEAM#<teamId>`
- Gets all permissions by default

**2. Coach/Assistant (via invite)**
- Owner/coach sends invite with specified role
- Invite includes: email, role, optional playerId link
- User accepts → membership created with invited role
- Permissions resolved at runtime (not stored)

**3. Role Promotion (owner/coach only)**
- Owner/coach can change member's role
- Requires `canManageRoles` permission (resolved from requester's role)
- Updates membership record with new role only
- New permissions automatically available on next request

### 9.9 Cognito Groups (Minimal)

**Only use Cognito groups for global roles:**

| Cognito Group | Purpose |
|---------------|---------|
| `system-admin` | Internal ops, full access |
| `verified-user` | Has completed email verification |

**All team/league roles are stored in DynamoDB**, not Cognito.

### 9.10 Benefits of Team-Scoped Roles

✅ **Flexibility** - Different roles on different teams
✅ **Granular** - Fine-grained permissions per team
✅ **Auditable** - Track role changes over time
✅ **Scalable** - No Cognito group explosion
✅ **Contextual** - Permissions tied to specific entities
✅ **Revocable** - Easy to remove access to specific teams
✅ **Delegatable** - Coaches can assign scorekeepers

### 9.11 Implementation Notes

**Role Storage (Not Permissions):**
- **Only store `role` string** in membership records
- **Never store resolved permissions** in database
- Permissions resolved at runtime from role definition
- Allows changing role capabilities without database updates

**Permission Resolution:**
- Lambda queries membership → gets role string
- Policy engine resolves role → permission set
- Check if permission set includes required action
- This happens on every request (fast, in-memory lookup)

**Permission Caching (Optional):**
- Cache user's roles in JWT claims (not permissions)
- Reduces DynamoDB lookups on every request
- Permissions still resolved at runtime from cached role

**Audit Trail:**
- Log all role changes to `AUDIT#ROLE_CHANGE#<timestamp>`
- Track who changed what, when
- Required for compliance and debugging

**Future: Central Policy Engine (§15.2)**
- Move permission checks to shared policy engine
- Prevents logic drift across Lambdas
- Declarative JSON-based policies
- Single source of truth for authorization

---

## 🗑️ 10. Data Deletion, Retention & Preservation Guide

### 🎯 Goal

**Protect user privacy while preserving team and league history.**

No important game or stat data should ever disappear due to account or organization deletion.

### 🧱 Core Principles

| Concept              | Meaning                                                         |
| -------------------- | --------------------------------------------------------------- |
| **Ownership**        | Who controls and edits the data (User / Team / League)         |
| **Dependency**       | Who relies on the data (e.g., teams depending on league seasons) |
| **Mirroring**        | Read-only copies shared down the hierarchy (League → Team)      |
| **Promotion**        | When owner is deleted, dependents inherit the mirrored data     |
| **Pseudonymization** | Replace personal details with anonymous labels                  |
| **Retention**        | Keep deleted data for 30 days before permanent cleanup          |

### 🧩 Deletion Behavior by Entity

| Entity                  | On User Deletion                      | On Team Deletion                           | On League Deletion                  | Notes                                |
| ----------------------- | ------------------------------------- | ------------------------------------------ | ----------------------------------- | ------------------------------------ |
| User Profile            | Hard delete                           | N/A                                        | N/A                                 | Trigger anonymization of PII         |
| Player Stats / At-Bats  | Retain, anonymize name/email          | Retain (still linked to team/season)       | Retain                              | Stats tied to playerId, not userId   |
| Team Roster             | Remove player link                    | Delete team record                         | Retain if mirrored to league        | Roster uses playerId reference       |
| Team Games / Seasons    | Retain                                | Delete team data                           | Promote from league if mirrored     | Games are immutable                  |
| League Seasons / Games  | N/A                                   | N/A                                        | Promote all team mirrors to ownership | Teams keep preserved copies          |
| Free-Agent Listings     | Delete listing                        | N/A                                        | N/A                                 | Always personal data                 |

### 10.1 User Deletion (Privacy Flow)

**Triggered by:** Cognito account deletion or "Delete My Account"

**Steps:**

1. **Soft Delete (30-day grace period)**
   ```python
   USER#id.status = "deleted"
   USER#id.deletedAt = timestamp
   USER#id.recoveryToken = uuid  # For account recovery
   ```

2. **Anonymization (immediate)**
   - Find all Player records linked to userId
   - Replace PII in all related items:
     ```python
     PLAYER.firstName = "Anonymous"
     PLAYER.lastName = "Player"
     PLAYER.email = null
     PLAYER.userId = null
     PLAYER.orphaned = true
     PLAYER.anonymizedAt = timestamp
     ```
   - Delete free agent listings
   - Delete pending invites
   - Create audit entry: `AUDIT#USER_DELETION#<userId>`

3. **Hard Delete (after 30 days)**
   - Scheduled Lambda checks `deletedAt < now - 30 days`
   - Delete `USER#id` record permanently
   - Delete `USER#id → TEAM#*` membership records
   - Stats remain attached to anonymized Player records

**Why:** Teams and leagues depend on historical data. Stats must live forever, but identity can disappear.

### 10.2 Team Deletion

**Triggered by:** Team owner deletes team

**Steps:**

1. **Soft Delete (30-day grace period)**
   ```python
   TEAM#id.status = "deleted"
   TEAM#id.deletedAt = timestamp
   TEAM#id.recoveryToken = uuid
   ```

2. **Data Preservation**
   - **DO NOT** delete Player records or AtBats
   - **DO NOT** delete Games or Seasons
   - Mark all records as `orphaned = true`
   - Users can still query their own stats via GSI4 (`USER#id → PLAYER#*`)

3. **Hard Delete (after 30 days)**
   - Delete `TEAM#id → METADATA` record
   - Delete `TEAM#id → PLAYER#*` records (ghost players only)
   - **Preserve** Player records that were linked to Users
   - **Preserve** all AtBats (linked to Players, not Team)
   - **Preserve** Games (may be linked to League)
   - Create archive: `ARCHIVE#TEAM#<teamId>` for user historical queries

**Why:** Users should retain their personal stats even if team is deleted.

### 10.3 League Deletion & Data Promotion

**Triggered by:** League admin deletes league

**Steps:**

1. **Soft Delete (30-day grace period)**
   ```python
   LEAGUE#id.status = "deleted"
   LEAGUE#id.deletedAt = timestamp
   LEAGUE#id.recoveryToken = uuid
   ```

2. **Data Promotion (immediate)**
   - For each team in league:
     ```python
     # Promote mirrored seasons to team ownership
     TEAM#id#SEASON#leagueSeasonId.ownerType = "team"
     TEAM#id#SEASON#leagueSeasonId.isEditable = true
     TEAM#id#SEASON#leagueSeasonId.origin = "preservedFromLeague"
     TEAM#id#SEASON#leagueSeasonId.inheritedFromLeague = false
     
     # Promote mirrored games
     TEAM#id#SEASON#id → GAME#*.ownerType = "team"
     TEAM#id#SEASON#id → GAME#*.isEditable = true
     ```
   - Teams now own their historical league data
   - Standings, schedules, and W/L records preserved

3. **Hard Delete (after 30 days)**
   - Delete `LEAGUE#id` records
   - All team data already promoted (safe to delete)
   - Create archive: `ARCHIVE#LEAGUE#<leagueId>`

**Why:** League disbanding shouldn't destroy team history. Teams inherit all their data.

### 10.4 Player Unlinking (User Leaves Team)

**When a User leaves or is kicked from a Team:**

**Steps:**

1. **Unlink Process**
   ```python
   PLAYER.userId = null
   PLAYER.isGhost = true
   PLAYER.status = "inactive"
   PLAYER.unlinkedAt = timestamp
   ```

2. **Data Retention**
   - Player record remains on team roster (historical)
   - All AtBats remain linked to Player
   - User can still query their AtBats via GSI4 (`USER#id → PLAYER#*`)
   - Team retains full stats for that Player
   - User's personal dashboard still shows stats from that team

**Why:** Both team and user need access to historical performance data.

### 10.5 Data Mirroring & Promotion

**Mirroring (League → Team):**

When leagues create seasons/games, teams receive read-only mirrors:

```
LEAGUE#123#SEASON#2025SPRING → GAME#A45
  ↓ (mirrored)
TEAM#888#SEASON#2025SPRING → GAME#A45 (read-only)
```

**Promotion (League Deleted):**

When a league is removed, each team mirror is promoted to ownership:

```python
# Before (mirrored)
ownerType: "league"
isEditable: false
inheritedFromLeague: true

# After (promoted)
ownerType: "team"
isEditable: true
origin: "preservedFromLeague"
inheritedFromLeague: false
```

### 10.6 Retention & Cleanup

| Type                   | Duration             | Action                                  |
| ---------------------- | -------------------- | --------------------------------------- |
| Soft Deleted Entities  | 30 days              | Auto-purge by scheduled Lambda          |
| Archived Leagues       | 30 days (extendable) | Permanent delete after grace period     |
| Anonymized Data        | Indefinite           | Safe to keep for analytics              |
| Audit Logs             | 1 year               | Stored under `AUDIT#...` partition      |
| Recovery Tokens        | 30 days              | Deleted with hard delete                |

**Scheduled Cleanup Lambda (runs daily):**

```python
def cleanup_expired_deletions():
    cutoff = datetime.now(timezone.utc) - timedelta(days=30)
    
    # Scan for expired soft deletes
    response = table.scan(
        FilterExpression=Attr('status').eq('deleted') & Attr('deletedAt').lt(cutoff.isoformat())
    )
    
    for item in response['Items']:
        # Hard delete
        table.delete_item(Key={'PK': item['PK'], 'SK': item['SK']})
        
        # Create audit log
        table.put_item(Item={
            'PK': f"AUDIT#HARD_DELETE#{item['PK']}",
            'SK': datetime.now(timezone.utc).isoformat(),
            'originalItem': item,
            'deletedBy': 'system',
            'reason': 'retention_period_expired'
        })
```

### 10.7 Flags & Metadata

| Flag                   | Purpose                                      |
| ---------------------- | -------------------------------------------- |
| `deleted`              | Marks soft deletion                          |
| `deletedAt`            | Timestamp for retention calculation          |
| `recoveryToken`        | UUID for account recovery                    |
| `inheritedFromLeague`  | Indicates read-only mirror                   |
| `isEditable`           | Permission indicator                         |
| `ownerType`            | "user", "team", "league"                     |
| `origin`               | "manual", "mirrored", "preservedFromLeague"  |
| `orphaned`             | Marks data no longer tied to active entity   |
| `anonymizedAt`         | Timestamp when PII removed                   |
| `status`               | "active", "deleted", "archived"              |

### 10.8 Quick Rules to Remember

✅ **Never delete gameplay stats outright**
✅ **Always anonymize instead of removing user info**
✅ **League deletion promotes data to team ownership**
✅ **Soft delete first, hard delete after 30-day retention**
✅ **Audit every deletion for traceability**
✅ **Mirrors flow one-way (League → Team)**
✅ **Stats tied to Player, not User**
✅ **Identity can disappear, stats must live forever**

### 10.9 Example Lifecycle

| Event                  | Outcome                                                      |
| ---------------------- | ------------------------------------------------------------ |
| Player deletes account | PII anonymized, stats stay linked to Player                  |
| Team disbands          | Team metadata deleted, all games/stats preserved for users   |
| League disbands        | Teams inherit seasons and games as their own                 |
| Admin runs cleanup job | Removes expired soft-deleted items (30+ days old)            |
| League reinstated      | Archived data can be re-linked to teams (within 30 days)     |
| User leaves team       | Player unlinked, stats remain on team roster                 |

### 🎯 TL;DR

> **🧩 Identity can disappear.**
> **📊 Stats must live forever.**
> **🔒 PII is replaceable — history isn't.**

---

## 🔄 11. Aggregation & Analytics

* **Per-game stats** → stored as `ATBAT` events
* **Aggregate Lambda (via DynamoDB Stream)**:

  * Summarizes by `playerId`, `teamId`, `seasonId`
  * Updates `STAT#PLAYER#id` and `STAT#TEAM#id` records
* **League standings**:

  * Derived nightly from game outcomes
  * Written to `LEAGUE#id#SEASON#id → STANDINGS`

---

## 🧰 11. Current Project Structure

```
/terraform                    # Infrastructure as Code
  ├── provider.tf            # AWS provider configuration
  ├── locals.tf              # Environment variables
  ├── dynamodb.tf            # DynamoDB table definition
  ├── lambda-users.tf        # User Lambda functions
  ├── api-gateway.tf         # HTTP API Gateway
  └── lambdas/               # Packaged Lambda ZIP files

/src                          # Lambda source code
  ├── users/                 # User management Lambdas
  │   ├── create/           # Cognito post-confirmation
  │   ├── get/              # Get user by ID
  │   ├── query/            # Query/list users
  │   ├── update/           # Update user info
  │   └── delete/           # Delete user
  └── utils/                 # Shared utilities
      ├── dynamodb.py       # DynamoDB client
      └── api_gateway.py    # Response formatter

/scripts                      # Development scripts
  ├── db.py                 # DynamoDB Local management
  ├── test_users.py         # User Lambda tests
  └── package_lambdas.py    # Lambda packaging

/local                        # Local development
  └── docker-compose.yml    # DynamoDB Local + Admin UI
```

---

## 🧮 12. Development Phases

| Phase               | Deliverables                           | Status      |
| ------------------- | -------------------------------------- | ----------- |
| **1. MVP**          | Users, teams, games, stat tracking     | In Progress |
| **2. League Mode**  | League CRUD, linked seasons, standings | Planned     |
| **3. Free Agency**  | Regional search + sub invitations      | Planned     |
| **4. Tournaments**  | Brackets + elimination logic           | Planned     |
| **5. Premium Tier** | Exports, leaderboards, AI stat import  | Future      |

### Phase 1 Progress (MVP)

- [x] User CRUD operations (create, get, query, update, delete)
- [x] Cognito post-confirmation trigger
- [x] API Gateway integration
- [x] Local development environment (DynamoDB Local)
- [x] Test infrastructure (local + cloud)
- [x] Team CRUD operations (create, get, query, update, delete)
- [x] Team ownership & atomic membership creation
- [x] Role-based authorization (owner, coach, player)
- [x] Soft delete with 30-day recovery
- [x] Player roster management (full CRUD: add, list, get, update, remove)
- [ ] Player invitations and linking
- [ ] Season management
- [ ] Game recording
- [ ] At-bat tracking
- [ ] Basic stat aggregation

---

## 🧱 13. Testing Strategy

* **Unit tests:** Mocked DynamoDB (`moto`)
* **Integration tests:** Lambda → API Gateway flow
* **Frontend tests:** Flutter widget tests + integration tests
* **End-to-end:** Simulate full user → team → league workflow

### Current Testing Approach

- **Local Testing:** Direct Lambda invocation with simulated events
- **Cloud Testing:** HTTP requests to deployed API Gateway
- **Database:** DynamoDB Local for development, AWS DynamoDB for staging/prod

---

## 📊 14. Monitoring & Logging

* CloudWatch structured logs (JSON)
* Custom metric filters:

  * `GamesCreatedCount`
  * `AtBatsRecordedCount`
  * `SyncLagSeconds`
* Alarms on Lambda error rate > 5%

### Current Implementation

- Structured JSON logging in all Lambda functions
- Log levels: INFO, WARN, ERROR
- CloudWatch Logs retention: 7 days
- X-Ray tracing: Not yet enabled

---

## 🌎 15. Future Enhancements

### 15.1 Dedicated Stats Aggregation Service

**Problem:**
- Current approach: Stream-driven Lambda computes stats on every at-bat
- At scale (100k+ at-bats): race conditions, write contention, high costs
- Limited historical trend analysis (batting avg by month)

**Solution:**
- Dedicated stats-aggregator Lambda/service
- Subscribes to `ATBAT` Stream events
- Buffers writes via SQS (batch 100-500 updates)
- Aggregates once per player/team/season
- Time-based aggregates: `PLAYERSTATS#<playerId>#2025-04`

**Benefits:**
- ✅ Reduces write contention and DynamoDB costs
- ✅ Enables analytics (charts, streaks, trends)
- ✅ Supports retroactive re-aggregation (bug fixes)
- ✅ Prevents race conditions on concurrent updates

### 15.2 Central Policy Engine

**Problem:**
- Team-scoped roles are data-driven, not policy-driven
- Each Lambda re-implements permission checks
- Risk of logic drift and inconsistencies
- Hard to audit who can do what
- **Anti-pattern:** Storing resolved permissions in database (see §9.11)

**Solution:**
- Create central policy engine (Lambda Layer or shared utility)
- Accept: `userId`, `action`, `teamId/leagueId`
- Query membership once → get role string
- Resolve role to permissions at runtime
- Return authorization decision
- Store policies as declarative JSON:
  ```
  {
    "action": "recordAtBat",
    "allowedRoles": ["team-owner", "team-coach", "team-scorekeeper"]
  }
  ```
- Simple Lambda usage: `authorize(userId, "recordAtBat", teamId)`

**Benefits:**
- ✅ Centralized permission logic (no drift)
- ✅ Change role capabilities without database updates
- ✅ Easier auditing and compliance
- ✅ Future-ready for custom roles or dynamic policies
- ✅ Trivial onboarding for new developers
- ✅ Single source of truth for all authorization

**Critical:** Database stores only `role` strings. Policy engine resolves roles to permissions at runtime.

### 15.3 Other Enhancements

* **GraphQL layer (AppSync)** → real-time stat updates
* **Global Tables** → Multi-region replication
* **Stripe integration** → League billing
* **AI stat detection** → from video input
* **Open API** → Public data feed for scoreboards

---

## ✅ 16. Guiding Principles

| Principle                     | Explanation                                      |
| ----------------------------- | ------------------------------------------------ |
| **Ownership Clarity**         | Each entity has one source of truth              |
| **Mirroring, Not Merging**    | League → team syncs are one-way                  |
| **Context-Aware Permissions** | Role + `ownerType` define editability            |
| **Event-Driven Sync**         | Streams keep all layers up to date               |
| **Mobile-First Design**       | Core flows optimized for coaches/players in-game |
| **Serverless Simplicity**     | Lambda-first, no servers to manage               |
| **Idempotency**               | All operations safe to retry                     |
| **Cognito Sub as User ID**    | Use stable Cognito sub instead of random UUIDs   |

---

## 🔧 17. Development Guidelines

### DynamoDB Best Practices

1. **Use Cognito sub as userId** - Eliminates need for cross-referencing
2. **Conditional writes** - Prevent overwrites with `ConditionExpression`
3. **Handle retries gracefully** - Catch `ConditionalCheckFailedException`
4. **Lowercase resource names** - All Terraform resources use lowercase
5. **Consistent field ordering** - PK/SK first, then user data, then GSI keys

### Lambda Best Practices

1. **Shared utilities** - Common code in `src/utils/`
2. **Field validation** - Explicit allowed/readonly field lists
3. **Auto-timestamps** - Always update `updatedAt` on modifications
4. **Proper error handling** - Distinguish between retries and real errors
5. **API Gateway v2.0** - All API Lambdas use payload format 2.0

### Testing Best Practices

1. **Test locally first** - Faster feedback, no AWS costs
2. **Test cloud after deploy** - Validates full integration
3. **Use realistic data** - Cognito subs, proper UUIDs
4. **Clean up after tests** - `make db-clear` between test runs

### Flutter Best Practices

1. **Use ConsumerWidget** - All screens that need Riverpod access
2. **Use ConsumerStatefulWidget** - For screens with local state + Riverpod
3. **AsyncNotifier for API data** - Built-in caching and state management
4. **Watch providers in build** - Use `ref.watch()` to listen for changes
5. **Read providers for actions** - Use `ref.read()` in callbacks/methods
6. **Use optimistic mutations** - All CRUD operations use `notifier.mutate()` pattern
7. **Temp IDs for adds** - Use `temp-${timestamp}` prefix for optimistic adds
8. **Capture originals for rollback** - Save original item before update/delete
9. **Rollback from current state** - Never revert to snapshots (race condition risk)
10. **RefreshIndicator for manual refresh** - Allow users to force data refresh
11. **Handle all AsyncValue states** - loading, error, and data cases
12. **Show loading for temp items** - Check `id.startsWith('temp-')` in UI

**See `OPTIMISTIC_UI_GUIDE.md` for complete implementation checklist**

---

## 📚 18. Reference Documentation

### External Resources
- [DynamoDB Single-Table Design](https://www.alexdebrie.com/posts/dynamodb-single-table/)
- [API Gateway Payload Format 2.0](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-develop-integrations-lambda.html)
- [Cognito Triggers](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-identity-pools-working-with-aws-lambda-triggers.html)
- [Terraform AWS Lambda Module](https://registry.terraform.io/modules/terraform-aws-modules/lambda/aws/latest)

### Internal Guides
- **[OPTIMISTIC_UI_GUIDE.md](./OPTIMISTIC_UI_GUIDE.md)** - Complete guide for implementing race-condition-safe optimistic mutations
- **[DATA_MODEL.md](./DATA_MODEL.md)** - Current implementation snapshot (what exists now)
- **[TESTING.md](./TESTING.md)** - Local and cloud testing workflows

---

## 🎯 Next Steps

See [ARCHITECTURE.md](./ARCHITECTURE.md) for the complete system design and implementation plan.

