# HackTracker Quick Start Guide

**For New AI Sessions with Zero Context**

This guide provides essential context for AI assistants to quickly understand HackTracker's current implementation status, architecture, and development patterns.

---

## What is HackTracker?

**HackTracker** is a softball statistics tracking application built with Flutter (frontend) and AWS serverless (backend). It allows users to create teams, manage rosters, and track player performance.

**Current Status:** MVP Complete - User, Team & Player Management

---

## Essential Context

### Technology Stack

**Frontend:**
- Flutter 3.9+ with Dart 3.9+
- Riverpod 3.0+ for state management
- AWS Amplify Auth Cognito for authentication
- Material 3 with custom theming
- Shared Preferences for persistent caching

**Backend:**
- AWS API Gateway HTTP API (15 endpoints)
- AWS Lambda functions (Python 3.13, ARM64)
- DynamoDB Single Table Design
- Cognito JWT Authorizer
- Terraform for infrastructure

### Key Architectural Decisions

1. **Single Table Design:** All entities in one DynamoDB table with PK/SK patterns
2. **JWT Authentication:** Cognito tokens validated at API Gateway level
3. **Optimistic UI:** Race-condition-safe updates with rollback on error
4. **Persistent Caching:** Data retained between app sessions with SWR pattern
5. **Personal Teams:** Auto-created hidden teams for individual stats
6. **v2 Policy Engine:** Centralized authorization with action-to-role mapping
7. **Global DynamoDB Client:** Lambda warm-start optimization

---

## Documentation Map

### Primary Documents

| Document | Purpose | When to Use |
|----------|---------|-------------|
| **[ARCHITECTURE.md](./architecture-docs/ARCHITECTURE.md)** | Complete backend system design | Understanding backend patterns, data model, infrastructure |
| **[UI_ARCHITECTURE.md](./architecture-docs/UI_ARCHITECTURE.md)** | Complete frontend implementation | Understanding Flutter patterns, state management, UI components |
| **[DATA_MODEL.md](./DATA_MODEL.md)** | Current implementation snapshot | Understanding what exists now, API contracts, testing |
| **[architecture-docs/architecture-diagram.md](./architecture-docs/architecture-diagram.md)** | Visual system overview | Quick visual understanding of system architecture |

### Detailed Sub-Documents

| Document | Purpose | When to Use |
|----------|---------|-------------|
| **[architecture-docs/ui/screens.md](./architecture-docs/ui/screens.md)** | Screen-by-screen documentation | Understanding specific UI screens and navigation |
| **[architecture-docs/ui/state-management.md](./architecture-docs/ui/state-management.md)** | Riverpod implementation details | Understanding state management patterns |
| **[architecture-docs/ui/styling.md](./architecture-docs/ui/styling.md)** | Theming and styling system | Understanding UI styling and theming |
| **[architecture-docs/ui/widgets.md](./architecture-docs/ui/widgets.md)** | Reusable widget catalog | Understanding UI components and patterns |
| **[architecture-docs/ui/forms.md](./architecture-docs/ui/forms.md)** | Form handling patterns | Understanding form validation and handling |
| **[architecture-docs/caching.md](./architecture-docs/caching.md)** | Caching strategy details | Understanding data persistence and refresh |
| **[architecture-docs/authorization.md](./architecture-docs/authorization.md)** | Authorization system | Understanding permission patterns |
| **[architecture-docs/dynamodb-design.md](./architecture-docs/dynamodb-design.md)** | Database schema details | Understanding data access patterns |

### Development Resources

| Document | Purpose | When to Use |
|----------|---------|-------------|
| **[TESTING.md](./TESTING.md)** | Testing workflows and commands | Running tests, debugging issues |
| **[Makefile](./Makefile)** | Development commands | Common development tasks |

---

## Current Implementation Status

### ✅ Completed Features

**User Management:**
- User registration via Cognito
- User profile management
- JWT authentication
- Personal stats team auto-creation

**Team Management:**
- Create, read, update, delete teams
- Team membership management
- Role-based permissions (owner, coach, player)
- Soft delete with recovery

**Player Management:**
- Add ghost players to rosters
- Player profile management
- Status tracking (active, inactive, sub)
- Player number assignment

**UI Features:**
- Material 3 theming with custom extensions
- Optimistic UI updates
- Persistent caching
- Responsive design
- Form validation
- Error handling

### 🔄 In Progress

**None currently** - MVP is complete and stable.

### 📋 Planned Features

**Game Management:**
- Record at-bats and game stats
- Player performance tracking
- Team statistics

**Recruitment:**
- Free agent profiles
- Player recruitment tools
- Team discovery

**Analytics:**
- Performance trends
- Spray charts
- Advanced statistics

---

## Common Development Tasks

### Adding a New Lambda Function

1. **Create handler:** `src/{entity}/{action}/handler.py`
2. **Add Terraform module:** `terraform/lambda-{entity}.tf`
3. **Add API Gateway route:** `terraform/api-gateway.tf`
4. **Update documentation:** `DATA_MODEL.md`

**Pattern to follow:**
```python
# Use global DynamoDB client
from utils import get_table, create_response
from utils.authorization import get_user_id_from_event, authorize

def handler(event, context):
    user_id = get_user_id_from_event(event)
    table = get_table()
    
    # Authorization check
    authorize(table, user_id, team_id, 'manage_roster')
    
    # Process request
    # Return clean DTO (no PK/SK fields)
```

### Adding a New UI Screen

1. **Create screen:** `app/lib/screens/{screen_name}_screen.dart`
2. **Add navigation:** Update navigation patterns
3. **Add state management:** Create providers if needed
4. **Update documentation:** `architecture-docs/ui/screens.md`

**Pattern to follow:**
```dart
class ExampleScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(dataProvider);
    
    return Scaffold(
      appBar: AppBar(title: Text('Screen Title')),
      body: dataAsync.when(
        data: (data) => _buildContent(data),
        loading: () => CircularProgressIndicator(),
        error: (error, stack) => ErrorWidget(error: error),
      ),
    );
  }
}
```

### Modifying the Data Model

1. **Update DynamoDB schema:** `terraform/dynamodb.tf`
2. **Update Lambda handlers:** Add new fields to DTOs
3. **Update frontend models:** `app/lib/models/`
4. **Update documentation:** `DATA_MODEL.md` and `architecture-docs/dynamodb-design.md`

### Testing Locally vs Cloud

**Local Testing:**
```bash
# Start local environment
make db-start
make db-create

# Test specific function
make test create
make test get <userId>
```

**Cloud Testing:**
```bash
# Deploy first
make deploy

# Test deployed functions
make test-cloud get <userId>
make test-cloud query list
```

---

## Key Patterns to Follow

### Backend Patterns

**Authorization:**
```python
# Use v2 Policy Engine
authorize(table, user_id, team_id, 'manage_roster')
```

**Global DynamoDB Client:**
```python
# Use global client for warm-start optimization
from utils import get_table
table = get_table()
```

**Clean DTOs:**
```python
# Return clean data without internal fields
return create_response(200, {
    'teamId': team['teamId'],
    'name': team['name'],
    # No PK, SK, GSI* fields
})
```

### Frontend Patterns

**Optimistic Updates:**
```dart
// Generate temp ID
final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';

// Update UI immediately
state.whenData((items) {
  state = AsyncValue.data([...items, tempItem]);
});

// API call with rollback on error
try {
  final newItem = await api.createItem(data);
  // Replace temp with real data
} catch (e) {
  // Rollback optimistic update
}
```

**Persistent Caching:**
```dart
// Load cached data first
final cached = await Persistence.getJson<List<Item>>('items_cache', fromJson);
if (cached != null) {
  Future.microtask(() => _refreshInBackground());
  return cached;
}
```

**Theme Usage:**
```dart
// Use theme styles instead of inline styles
Text(
  'Content',
  style: Theme.of(context).textTheme.bodyMedium,
)

// Use custom extensions
Text(
  'Custom',
  style: Theme.of(context).extension<CustomTextStyles>()!.sectionHeader,
)
```

---

## Important Terminology

### Consistent Terms

- **"Ghost player"** - Unlinked roster slot (not "unlinked player")
- **"Personal team"** - Hidden team for individual stats (not "personal stats container")
- **"Team-owner"** - Role name (not "owner")
- **"Team-coach"** - Role name (not "coach")
- **"Team-player"** - Role name (not "player")

### API Endpoints

**User Routes:**
- `GET /users/{userId}` - Get user by ID
- `GET /users` - Query users with filters
- `PUT /users/{userId}` - Update user
- `DELETE /users/{userId}` - Delete user

**Team Routes:**
- `POST /teams` - Create team
- `GET /teams/{teamId}` - Get team by ID
- `GET /teams` - Query teams with filters
- `PUT /teams/{teamId}` - Update team
- `DELETE /teams/{teamId}` - Delete team

**Player Routes:**
- `POST /teams/{teamId}/players` - Add player
- `GET /teams/{teamId}/players` - List players
- `GET /teams/{teamId}/players/{playerId}` - Get player
- `PUT /teams/{teamId}/players/{playerId}` - Update player
- `DELETE /teams/{teamId}/players/{playerId}` - Remove player

---

## Development Commands

### Essential Commands

```bash
# Start local development
make db-start          # Start DynamoDB Local
make db-create         # Create local table
make db-status         # Check table status
make db-clear          # Clear local data

# Testing
make test create       # Test user creation
make test get <userId> # Test get user
make test-cloud get <userId> # Test deployed function

# Deployment
make deploy            # Deploy to AWS
make package           # Package Lambda functions

# Development
make test-help         # Show all test options
```

### File Locations

**Backend:**
- Lambda handlers: `src/{entity}/{action}/handler.py`
- Utilities: `src/utils/`
- Terraform: `terraform/`
- Tests: `scripts/`

**Frontend:**
- Screens: `app/lib/screens/`
- Widgets: `app/lib/widgets/`
- Providers: `app/lib/providers/`
- Services: `app/lib/services/`
- Theme: `app/lib/theme/`

---

## Troubleshooting Common Issues

### Authentication Issues

**Problem:** "SignedOutException" errors
**Solution:** Check JWT token validation in `AuthService.validateAuth()`

**Problem:** Bypassing login screen
**Solution:** Verify `AuthGate` widget logic and token validation

### Caching Issues

**Problem:** Old data showing
**Solution:** Check cache versioning in `Persistence` class

**Problem:** Data not persisting
**Solution:** Verify Shared Preferences permissions

### API Issues

**Problem:** "ERR_NAME_NOT_RESOLVED"
**Solution:** Check API Gateway endpoint configuration

**Problem:** 401 Unauthorized
**Solution:** Verify JWT token and API Gateway authorizer

### UI Issues

**Problem:** Buttons not responding
**Solution:** Check Riverpod provider state and error handling

**Problem:** Inconsistent styling
**Solution:** Use theme styles instead of inline styles

---

## Getting Help

### Documentation Priority

1. **Start here:** This QUICK_START.md
2. **Architecture:** `ARCHITECTURE.md` for backend patterns
3. **UI Implementation:** `UI_ARCHITECTURE.md` for frontend patterns
4. **Current Status:** `DATA_MODEL.md` for what exists now
5. **Visual Overview:** `architecture-docs/architecture-diagram.md`
6. **Specific Topics:** Sub-documents in `architecture-docs/`

### Key Files to Reference

**For Backend Questions:**
- `src/utils/authorization.py` - Authorization patterns
- `src/utils/dynamodb.py` - Database access
- `terraform/api-gateway.tf` - API configuration

**For Frontend Questions:**
- `app/lib/providers/team_providers.dart` - State management example
- `app/lib/theme/app_theme.dart` - Theming system
- `app/lib/widgets/form_dialog.dart` - UI component example

**For Testing:**
- `scripts/test_users.py` - User testing patterns
- `scripts/test_teams.py` - Team testing patterns
- `scripts/test_players.py` - Player testing patterns

---

## Summary

HackTracker is a **complete MVP** with:

- ✅ **User Management** - Registration, profiles, authentication
- ✅ **Team Management** - CRUD operations, membership, permissions
- ✅ **Player Management** - Roster management, ghost players
- ✅ **Modern Architecture** - Serverless backend, Flutter frontend
- ✅ **Production Ready** - Error handling, caching, optimistic UI

The system follows **established patterns** and provides **comprehensive documentation** for continued development. All major architectural decisions are documented and implemented consistently across the codebase.

**Next Steps:** Focus on game management and statistics features while maintaining the established patterns and architecture.
