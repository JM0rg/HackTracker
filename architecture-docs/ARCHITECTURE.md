# ⚾ HackTracker Softball — Architecture Guide

*(A multi-tenant stat-tracking platform for Players, Teams, and Leagues)*

> **📖 Documentation Structure:**
> - **This document:** High-level system overview and design philosophy
> - **Sub-Documents:** Detailed guides for specific topics (see below)
> - **[DATA_MODEL.md](../DATA_MODEL.md):** Current implementation snapshot

---

## 📚 Documentation Index

### Core Architecture
- **[dynamodb-design.md](./dynamodb-design.md)** - Single-table design, GSIs, query patterns
- **[authorization.md](./authorization.md)** - v2 Policy Engine, role-based access control
- **[caching.md](./caching.md)** - Frontend caching, optimistic UI, state management

### Implementation Guides
- **[DATA_MODEL.md](../DATA_MODEL.md)** - Current entities, Lambda functions, API routes
- **[TESTING.md](../TESTING.md)** - Local and cloud testing workflows
- **[OPTIMISTIC_UI_GUIDE.md](../OPTIMISTIC_UI_GUIDE.md)** - Detailed optimistic UI patterns

---

## 🧭 1. System Overview

**Goal:**
Provide a flexible ecosystem where:

* Individual players can track personal stats
* Teams can manage rosters, schedules, and record games
* Leagues can organize official seasons and tournaments
* Free agents/subs can find and join temporary opportunities

**Design Priorities:**

* **Scalable** - Multi-tenant DynamoDB schema
* **Modular** - Lambda-driven microservices
* **Secure** - Cognito-based RBAC with v2 Policy Engine
* **Extensible** - Easily add new entities (tournaments, standings, etc.)
* **Multi-context** - Supports both team-created and league-managed seasons
* **Fast UX** - Persistent caching with optimistic UI

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

### 🔄 Data Flow

```
Flutter App
  ↓ (JWT Auth)
API Gateway (JWT Authorizer)
  ↓ (Invoke)
Lambda Functions (Python)
  ↓ (Query/Write)
DynamoDB (Single Table)
  ↓ (Stream)
Aggregation Lambdas (Future)
```

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

**See:** [dynamodb-design.md](./dynamodb-design.md) for data model details

---

## 🔐 4. Authorization System

HackTracker uses a **v2 Policy Engine** for authorization.

### Key Concepts

**Team-Scoped Roles:**
- `team-owner` - Full control, can delete team
- `team-coach` - Manage roster, record stats
- `team-player` - View team data, edit own profile
- `team-assistant` - Record stats, view roster (no edits)
- `team-scorekeeper` - Record at-bats during games only
- `team-viewer` - Read-only access (parents, fans)

**Policy Engine Pattern:**
```python
# Handlers just ask: "can this user do X?"
authorize(table, user_id, team_id, action='manage_roster')

# They don't need to know WHO can do X
# That's defined in the central POLICY_MAP
```

**Benefits:**
- ✅ Handlers are "dumb" - zero knowledge of roles
- ✅ Single source of truth - all permissions in one place
- ✅ Future-proof - add roles without touching handlers
- ✅ Self-documenting - policy map shows all permissions

**See:** [authorization.md](./authorization.md) for complete details

---

## 💾 5. Data Architecture

### Single-Table Design

All entities stored in one DynamoDB table for optimal performance and cost efficiency.

**Table:** `hacktracker-{environment}`

**Primary Keys:**
- `PK` (Partition Key): Entity identifier (e.g., `USER#<id>`, `TEAM#<id>`)
- `SK` (Sort Key): Sub-entity or metadata (e.g., `METADATA`, `PLAYER#<id>`)

**Global Secondary Indexes (5):**
1. **GSI1** - User lookup by Cognito sub (login flow)
2. **GSI2** - Entity listing (generic queries)
3. **GSI3** - Geographic search (reserved for free agents)
4. **GSI4** - User's players (cross-team stats)
5. **GSI5** - Player's at-bats (stat aggregation)

**Key Principles:**
- Most queries use PK/SK directly (no GSI needed)
- Atomic transactions for related writes
- Conditional writes prevent race conditions
- Cognito sub used as userId (no cross-referencing)

**See:** [dynamodb-design.md](./dynamodb-design.md) for complete schema

---

## 🎨 6. Frontend Architecture

### State Management

**Technology:** Riverpod 2.6+

**Pattern:** Persistent caching with stale-while-revalidate (SWR) + Race-Condition-Safe Optimistic UI

**Key Features:**
- **Persistent cache** - Data survives app restarts
- **Cache versioning** - Auto-clear on schema changes
- **Instant UX** - Cached data shown immediately
- **Background refresh** - Fresh data fetched automatically
- **Optimistic updates** - UI reacts instantly to user actions
- **Safe rollback** - Handles concurrent operations correctly

**Flow:**
```
User opens screen
  ↓
Show cached data instantly (if available)
  ↓
Fetch fresh data in background
  ↓
Update UI when fresh data arrives
```

**Optimistic UI Pattern:**
```dart
await notifier.mutate(
  optimisticUpdate: (current) => /* add/update/remove */,
  apiCall: () => api.doSomething(),
  applyResult: (current, result) => /* apply real result */,
  rollback: (current) => /* undo from current state */,
  successMessage: 'Success!',
  errorMessage: (e) => 'Failed: $e',
);
```

**See:** [caching.md](./caching.md) for implementation details

---

## 🧩 7. Ownership Model

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

## 🔄 8. Lifecycle Flows

### 8.1 Player Flow

1. Sign up → Cognito triggers `post-confirmation` Lambda → Creates `USER#id`
2. Player can:
   * Join an existing team via invite code
   * Create personal stats profile
   * Join free agent pool (optional)

### 8.2 Team Flow

1. Coach creates a team (`TEAM#id`)
2. Adds players manually or via invites
3. Creates a **team-owned season**
   * `TEAM#id#SEASON#2025SPRING`
4. Adds games + records at-bats
5. Team dashboard shows cumulative stats

### 8.3 League Flow

1. League admin creates league (`LEAGUE#id`)
2. Creates **league-owned season**
   * `LEAGUE#id#SEASON#2025SPRING`
3. Adds teams via `TEAMSEASONLINK` (`LEAGUE#id#SEASON#id` → `TEAM#id`)
4. Creates league games
5. Sync Lambda mirrors read-only season + games to all teams
6. League dashboard aggregates standings & leaderboards

### 8.4 Free Agent Flow

1. Player opts into `FREEAGENCY#<region>`
2. Teams query by position/region
3. Coach sends invite
4. Player accepts → temporary roster record created (`TEAM#id` + `PLAYER#id`, `status=sub`)
5. Optional auto-expiration after game

---

## 🗑️ 9. Data Deletion & Retention

### Core Principles

| Concept              | Meaning                                                         |
| -------------------- | --------------------------------------------------------------- |
| **Ownership**        | Who controls and edits the data (User / Team / League)         |
| **Dependency**       | Who relies on the data (e.g., teams depending on league seasons) |
| **Mirroring**        | Read-only copies shared down the hierarchy (League → Team)      |
| **Promotion**        | When owner is deleted, dependents inherit the mirrored data     |
| **Pseudonymization** | Replace personal details with anonymous labels                  |
| **Retention**        | Keep deleted data for 30 days before permanent cleanup          |

### Deletion Behavior

| Entity                  | On User Deletion                      | On Team Deletion                           | On League Deletion                  |
| ----------------------- | ------------------------------------- | ------------------------------------------ | ----------------------------------- |
| User Profile            | Hard delete (30-day grace)            | N/A                                        | N/A                                 |
| Player Stats / At-Bats  | Retain, anonymize name/email          | Retain (still linked to team/season)       | Retain                              |
| Team Roster             | Remove player link                    | Delete team record                         | Retain if mirrored to league        |
| Team Games / Seasons    | Retain                                | Delete team data                           | Promote from league if mirrored     |
| League Seasons / Games  | N/A                                   | N/A                                        | Promote all team mirrors to ownership |

**Key Rules:**
- ✅ Never delete gameplay stats outright
- ✅ Always anonymize instead of removing user info
- ✅ League deletion promotes data to team ownership
- ✅ Soft delete first, hard delete after 30-day retention
- ✅ Audit every deletion for traceability

---

## ⚙️ 10. Lambda Functions

### Implemented (MVP Complete)

**User Management:**
- `create-user` - Cognito post-confirmation trigger
- `get-user` - Retrieve user profile
- `query-users` - List/search users
- `update-user` - Update user profile
- `delete-user` - Soft delete user

**Team Management:**
- `create-team` - Create team + owner membership (atomic)
- `get-team` - Retrieve team by ID
- `query-teams` - List teams (all or by user)
- `update-team` - Update team metadata
- `delete-team` - Soft delete team

**Player Management:**
- `add-player` - Add ghost player to roster
- `list-players` - List team roster
- `get-player` - Retrieve player by ID
- `update-player` - Update player details
- `remove-player` - Remove ghost player

### Planned (Future)

- `invite-player` - Send invite link/email
- `join-team` - Add player to roster
- `create-season` - Create season (team or league context)
- `update-season` - Update season metadata
- `record-game` - Add game + at-bats
- `sync-league-season` - Mirror league seasons/games to teams
- `get-dashboard` - Fetch stats for user/team/league
- `join-free-agency` - Add user to FA pool
- `search-free-agents` - Query regional pool
- `invite-sub` - Invite free agent to team
- `accept-sub` - Join as sub
- `aggregate-stats` - Compute averages, slugging, etc.

**See:** [DATA_MODEL.md](../DATA_MODEL.md) for current implementation status

---

## 🧮 11. Development Phases

| Phase               | Deliverables                           | Status      |
| ------------------- | -------------------------------------- | ----------- |
| **1. MVP**          | Users, teams, players, basic CRUD      | ✅ Complete |
| **2. Stats**        | Games, at-bats, stat tracking          | In Progress |
| **3. League Mode**  | League CRUD, linked seasons, standings | Planned     |
| **4. Free Agency**  | Regional search + sub invitations      | Planned     |
| **5. Tournaments**  | Brackets + elimination logic           | Planned     |
| **6. Premium Tier** | Exports, leaderboards, AI stat import  | Future      |

### Phase 1 Progress (MVP) ✅

- [x] User CRUD operations
- [x] Cognito post-confirmation trigger
- [x] API Gateway integration
- [x] Local development environment
- [x] Test infrastructure
- [x] Team CRUD operations
- [x] Team ownership & atomic membership creation
- [x] Role-based authorization (v2 Policy Engine)
- [x] Soft delete with 30-day recovery
- [x] Player roster management (full CRUD)
- [x] Frontend persistent caching
- [x] Optimistic UI updates
- [ ] Player invitations and linking
- [ ] Season management
- [ ] Game recording
- [ ] At-bat tracking
- [ ] Basic stat aggregation

---

## 🧱 12. Testing Strategy

* **Unit tests:** Mocked DynamoDB (`moto`)
* **Integration tests:** Lambda → API Gateway flow
* **Frontend tests:** Flutter widget tests + integration tests
* **End-to-end:** Simulate full user → team → league workflow

### Current Testing Approach

- **Local Testing:** Direct Lambda invocation with simulated events
- **Cloud Testing:** HTTP requests to deployed API Gateway
- **Database:** DynamoDB Local for development, AWS DynamoDB for staging/prod

**See:** [TESTING.md](../TESTING.md) for detailed workflows

---

## 📊 13. Monitoring & Logging

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

## 🌎 14. Future Enhancements

### 14.1 Dedicated Stats Aggregation Service

**Problem:**
- Current approach: Stream-driven Lambda computes stats on every at-bat
- At scale (100k+ at-bats): race conditions, write contention, high costs

**Solution:**
- Dedicated stats-aggregator Lambda/service
- Subscribes to `ATBAT` Stream events
- Buffers writes via SQS (batch 100-500 updates)
- Time-based aggregates: `PLAYERSTATS#<playerId>#2025-04`

### 14.2 Central Policy Engine (✅ Implemented)

**Status:** ✅ Complete (v2 Policy Engine)

**See:** [authorization.md](./authorization.md)

### 14.3 Other Enhancements

* **GraphQL layer (AppSync)** → real-time stat updates
* **Global Tables** → Multi-region replication
* **Stripe integration** → League billing
* **AI stat detection** → from video input
* **Open API** → Public data feed for scoreboards

---

## ✅ 15. Guiding Principles

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
| **Instant UX**                | Persistent caching + optimistic UI               |
| **Zero Knowledge Handlers**   | Handlers ask "can I do X?" not "who can do X?"   |

---

## 🔧 16. Development Guidelines

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
6. **Use authorize()** - v2 Policy Engine for all authorization checks

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

---

## 📚 17. Reference Documentation

### External Resources
- [DynamoDB Single-Table Design](https://www.alexdebrie.com/posts/dynamodb-single-table/)
- [API Gateway Payload Format 2.0](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-develop-integrations-lambda.html)
- [Cognito Triggers](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-identity-pools-working-with-aws-lambda-triggers.html)
- [Terraform AWS Lambda Module](https://registry.terraform.io/modules/terraform-aws-modules/lambda/aws/latest)

### Internal Guides
- **[dynamodb-design.md](./dynamodb-design.md)** - Complete DynamoDB schema and query patterns
- **[authorization.md](./authorization.md)** - v2 Policy Engine implementation
- **[caching.md](./caching.md)** - Frontend caching and optimistic UI
- **[DATA_MODEL.md](../DATA_MODEL.md)** - Current implementation snapshot
- **[TESTING.md](../TESTING.md)** - Local and cloud testing workflows
- **[OPTIMISTIC_UI_GUIDE.md](../OPTIMISTIC_UI_GUIDE.md)** - Detailed optimistic UI patterns

---

## 🎯 Next Steps

**Current Focus:** Phase 2 - Stats Implementation
- [ ] Season management (create, update, list)
- [ ] Game recording (create game, link to season)
- [ ] At-bat tracking (record individual plays)
- [ ] Basic stat aggregation (batting average, slugging, etc.)
- [ ] Player dashboard (stats across all teams)

**See:** [DATA_MODEL.md](../DATA_MODEL.md) for detailed implementation status
