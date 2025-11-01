# HackTracker - Context Summary for New Sessions

**Last Updated:** December 2024

This document provides a comprehensive overview of the HackTracker codebase to help new AI sessions quickly understand the project context, architecture, recent changes, and key implementation details.

---

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture Summary](#architecture-summary)
3. [Recent Major Changes](#recent-major-changes)
4. [UI Theme: Glassmorphism](#ui-theme-glassmorphism)
5. [Key Technical Decisions](#key-technical-decisions)
6. [File Structure](#file-structure)
7. [Common Patterns](#common-patterns)
8. [Important Notes](#important-notes)

---

## 🎯 Project Overview

**HackTracker** is a multi-tenant softball statistics tracking platform built with:
- **Frontend:** Flutter 3.9+ (iOS, Android, Web)
- **Backend:** AWS Lambda (Python 3.13, ARM64)
- **Database:** DynamoDB (single-table design)
- **Auth:** Amazon Cognito
- **Infrastructure:** Terraform (use `tf` command, not `terraform`)

**Core Entities:**
- **User** - Cognito-registered users
- **Team** - MANAGED (full roster) or PERSONAL (stat filtering)
- **Player** - Team roster slots (can be "ghost" or linked to User)
- **Game** - Scheduled matches with lineups
- **AtBat** - Atomic stat tracking events with normalized hit locations

---

## 🏗️ Architecture Summary

### Backend

- **26 Lambda Functions** - REST API endpoints
- **Single-Table DynamoDB** - Pattern-based PK/SK with 5 GSIs
- **v2 Policy Engine** - Role-based authorization (`owner`, `manager`, `scorekeeper`, `player`)
- **Validation Layer** - Centralized input validation with Decimal support for DynamoDB
- **JWT Authorization** - Cognito JWT tokens via API Gateway

### Frontend

- **Riverpod 3.0+** - State management (AsyncNotifier patterns)
- **Material 3 Theme** - Custom dark theme with Tektur font
- **Optimistic UI** - Race-condition-safe updates with rollback
- **Persistent Caching** - SharedPreferences with SWR pattern
- **Full-Screen Bottom Sheets** - Form presentation (not dialogs)

### Data Flow

```
Flutter App → API Gateway (JWT) → Lambda → DynamoDB → Response
```

---

## 🆕 Recent Major Changes

### 1. iOS Liquid Glass UI Theme (Latest)

**Implementation:**
- Consolidated Login, Signup, and Forgot Password into single `LoginScreen`
- Implemented glassmorphism design system
- Created reusable auth widgets (`GlassContainer`, `GlassButton`, `AuthGlassField`, etc.)
- Added `GlassTheme` constants and glassmorphism decorations

**Key Files:**
- `app/lib/features/auth/screens/login_screen.dart` - Unified auth screen
- `app/lib/theme/glass_theme.dart` - Glass theme constants
- `app/lib/features/auth/widgets/` - All glassmorphism widgets
- `app/lib/theme/decoration_styles.dart` - Extended with glass methods

**Removed Files:**
- `app/lib/features/auth/screens/signup_screen.dart` (deleted)
- `app/lib/features/auth/screens/forgot_password_screen.dart` (deleted)

### 2. AtBat Scoring System

**Implementation:**
- Created 5 Lambda functions for AtBat CRUD
- Implemented normalized hit location coordinate system (0.0-1.0)
- Built interactive scoring screen with SVG field diagram
- Added lineup management for games

**Key Files:**
- `app/lib/features/scoring/screens/scoring_screen.dart`
- `app/lib/features/scoring/widgets/field_diagram.dart` - SVG-based field
- `app/lib/features/scoring/widgets/action_area.dart` - Button states
- `src/atbats/*/handler.py` - Lambda handlers

### 3. Team View Refactor

**Implementation:**
- 4-tab structure (Stats, Schedule, Roster, Chat)
- Expandable game cards with lineup dropdown
- List/Calendar view toggle for schedule
- Role-based UI visibility (owner/manager only)

**Key Files:**
- `app/lib/screens/team_view_screen.dart`

### 4. Form Presentation Changes

**Implementation:**
- Moved all forms from small dialogs to full-screen bottom sheets
- Improved spacing and readability
- SafeArea handling for iPhone notch/bezels

**Pattern:**
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (context) => Container(
    decoration: BoxDecoration(/* ... */),
    child: SafeArea(
      child: Scaffold(/* form content */),
    ),
  ),
)
```

---

## 🎨 UI Theme: Glassmorphism

### Design System

HackTracker uses an **iOS liquid glass aesthetic** for authentication screens:

**Core Components:**
- `GlassContainer` - Frosted glass with backdrop blur
- `GlassButton` - Gradient buttons with elevation
- `AuthGlassField` - Glass-styled text inputs
- `GlassTheme` - Centralized constants

**Visual Characteristics:**
- Backdrop blur (sigma: 10.0)
- Semi-transparent backgrounds (0.5-0.8 opacity)
- Gradient backgrounds (background → surface)
- Subtle shadows for depth
- Primary color borders with opacity

**Theme Integration:**
- Uses `AppColors` for all colors
- Extends `DecorationStyles` with glass methods
- Uses Material 3 text theme
- Centralized in `GlassTheme` class

### Usage Pattern

```dart
Scaffold(
  body: Container(
    decoration: GlassTheme.backgroundGradient,
    child: SafeArea(
      child: Column(
        children: [
          AuthTitleHeader(),
          Expanded(
            child: GlassContainer(
              child: YourForm(),
            ),
          ),
        ],
      ),
    ),
  ),
)
```

---

## 🔧 Key Technical Decisions

### 1. Decimal Types for DynamoDB

**Issue:** DynamoDB doesn't support Python `float` types  
**Solution:** Convert float coordinates to `Decimal` before storage

```python
# src/utils/validation.py
from decimal import Decimal

def validate_hit_location(hit_location):
    # ... validation ...
    return {
        'x': Decimal(str(x)),
        'y': Decimal(str(y))
    }
```

### 2. Normalized Hit Locations

**Issue:** Hit locations must be consistent across device sizes  
**Solution:** Store as normalized 0.0-1.0 coordinates (percentages)

```dart
// Capture: Normalize to 0.0-1.0
final normalizedX = (tapX / fieldWidth).clamp(0.0, 1.0);
final normalizedY = (tapY / fieldHeight).clamp(0.0, 1.0);

// Display: Denormalize for rendering
final displayX = hitLocation['x']! * fieldWidth;
final displayY = hitLocation['y']! * fieldHeight;
```

### 3. Single Auth Screen

**Decision:** Consolidate Login, Signup, and Forgot Password into one screen  
**Reason:** Better UX with animated transitions, no navigation stack  
**Implementation:** `AuthFormMode` enum with `FadeTransition`

### 4. Full-Screen Bottom Sheets for Forms

**Decision:** Replace small dialogs with bottom sheets  
**Reason:** More space, better mobile UX, no keyboard overflow  
**Pattern:** `showModalBottomSheet` with `Scaffold` inside `Container`

### 5. Optimistic UI Pattern

**Decision:** Update UI immediately, rollback on error  
**Implementation:**
- Use `temp-` IDs for new entities
- Rollback from current state (not previous state)
- Race-condition-safe with proper state management

---

## 📁 File Structure

```
HackTracker/
├── app/                          # Flutter frontend
│   ├── lib/
│   │   ├── features/
│   │   │   ├── auth/            # Authentication
│   │   │   │   ├── screens/
│   │   │   │   │   └── login_screen.dart  # Unified auth
│   │   │   │   └── widgets/      # Glass widgets
│   │   │   └── scoring/          # AtBat scoring
│   │   │       ├── screens/
│   │   │       │   └── scoring_screen.dart
│   │   │       └── widgets/
│   │   │           ├── field_diagram.dart
│   │   │           └── action_area.dart
│   │   ├── screens/               # Main app screens
│   │   │   ├── team_view_screen.dart
│   │   │   └── ...
│   │   ├── theme/                # Theming
│   │   │   ├── app_colors.dart
│   │   │   ├── glass_theme.dart  # Glassmorphism
│   │   │   └── decoration_styles.dart
│   │   └── widgets/              # Reusable widgets
│   └── assets/
│       └── images/
│           └── softball_field.svg
├── src/                          # Lambda backend
│   ├── atbats/                   # AtBat CRUD
│   ├── games/                     # Game CRUD
│   ├── players/                  # Player CRUD
│   ├── teams/                     # Team CRUD
│   ├── users/                     # User CRUD
│   ├── utils/
│   │   ├── authorization.py      # v2 Policy Engine
│   │   └── validation.py         # Input validation
│   └── shared/                    # Shared utilities
├── architecture-docs/            # Architecture documentation
│   ├── ARCHITECTURE.md           # Main overview
│   ├── DATA_MODEL.md             # Entity details
│   ├── TESTING.md                # Testing guide
│   ├── api/                      # Backend docs
│   └── ui/                       # Frontend docs
│       ├── styling.md            # Theme system
│       ├── widgets.md            # Component library
│       └── screens.md            # Screen catalog
├── scripts/                      # E2E test scripts
│   └── run_all_tests.py          # Consolidated tests
└── CONTEXT_README.md             # This file
```

---

## 🎨 Common Patterns

### 1. Riverpod Provider Pattern

```dart
// AsyncNotifier with constructor params
final teamsProvider = AsyncNotifierProvider.family<TeamsNotifier, List<Team>, String>(
  TeamsNotifier.new,
  (ref, teamType) => TeamsNotifier(teamType),
);

class TeamsNotifier extends AsyncNotifier<List<Team>> {
  final String teamType;
  
  TeamsNotifier(this.teamType);
  
  @override
  Future<List<Team>> build() async {
    return await _loadTeams(teamType);
  }
}
```

### 2. Form Bottom Sheet Pattern

```dart
void _showPlayerForm(BuildContext context, Player? player) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(title: Text('Add Player')),
          body: YourForm(),
        ),
      ),
    ),
  );
}
```

### 3. Error Handling Pattern

```dart
try {
  await apiCall();
} on ApiException catch (e) {
  if (e.statusCode == 400) {
    showErrorToast(context, 'Invalid input: ${e.message}');
  } else if (e.statusCode == 403) {
    showErrorToast(context, 'Permission denied');
  } else {
    showErrorToast(context, 'An error occurred: ${e.message}');
  }
}
```

### 4. Optimistic UI Pattern

```dart
// In AsyncNotifier
Future<void> createTeam(String name) async {
  final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
  final tempTeam = Team(id: tempId, name: name, /* ... */);
  
  // Optimistic update
  final current = state.valueOrNull ?? [];
  state = AsyncData([...current, tempTeam]);
  
  try {
    final created = await apiService.createTeam(name);
    // Replace temp with real
    state = AsyncData([
      ...current.where((t) => t.id != tempId),
      created,
    ]);
  } catch (e) {
    // Rollback to previous state
    state = AsyncData(current);
    rethrow;
  }
}
```

### 5. Authorization Check Pattern

```python
# In Lambda handler
from src.utils.authorization import check_team_membership, get_user_id_from_event

user_id = get_user_id_from_event(event)
team_id = event['pathParameters']['teamId']

# Check membership and role
membership = await check_team_membership(user_id, team_id)
if not membership:
    return {'statusCode': 403, 'body': json.dumps({'error': 'Not a team member'})}

# Check specific permission
if not has_permission(membership['role'], 'manage_roster'):
    return {'statusCode': 403, 'body': json.dumps({'error': 'Insufficient permissions'})}
```

---

## ⚠️ Important Notes

### 1. Terraform Command

**Use `tf` instead of `terraform`** (project-specific alias)

```bash
tf init
tf plan
tf apply
```

### 2. Architecture Documentation

**Always reference `/architecture-docs` before making changes:**

- `ARCHITECTURE.md` - System overview
- `api/lambda-functions.md` - All Lambda functions
- `ui/styling.md` - Theme system (includes glassmorphism)
- `ui/widgets.md` - Component library
- `ui/screens.md` - Screen catalog

### 3. Validation Requirements

- All user input must go through `src/utils/validation.py`
- Hit locations must be Decimal types for DynamoDB
- Team names must be 1-50 characters
- Player numbers must be 0-99

### 4. Authorization Requirements

- Use `check_team_membership()` to verify team access
- Check permissions via `has_permission(role, action)`
- Owner has full permissions, others are restricted
- Personal teams don't require lineup for games

### 5. UI Consistency

- Use `AppColors` constants (no hardcoded colors)
- Use `DecorationStyles` methods (no inline BoxDecorations)
- Use `GlassTheme` for auth screens
- Use Material 3 text theme (not GoogleFonts directly)

### 6. Testing

- All Lambda functions have unit tests (pytest)
- E2E tests in `scripts/run_all_tests.py`
- 72% code coverage target
- Use `moto` for AWS service mocking

### 7. State Management

- Use Riverpod 3.0+ patterns (AsyncNotifier)
- Avoid `FamilyAsyncNotifier` (use constructor params)
- Implement optimistic UI with rollback
- Cache with SharedPreferences (SWR pattern)

### 8. Recent Bug Fixes

- **Keyboard Overflow:** Fixed by removing fixed height constraints and using `mainAxisSize: MainAxisSize.min`
- **Float to Decimal:** Fixed by converting hit location coordinates in `validate_hit_location()`
- **Form Sizing:** Ensured consistent form heights using `LayoutBuilder` and `SizedBox`

---

## 🔍 Quick Reference

### Key Files to Know

**Frontend:**
- `app/lib/features/auth/screens/login_screen.dart` - Unified auth
- `app/lib/screens/team_view_screen.dart` - Main team screen
- `app/lib/features/scoring/screens/scoring_screen.dart` - AtBat entry
- `app/lib/theme/glass_theme.dart` - Glass constants
- `app/lib/theme/app_colors.dart` - Color palette

**Backend:**
- `src/utils/authorization.py` - Policy engine
- `src/utils/validation.py` - Input validation
- `src/atbats/create/handler.py` - AtBat creation
- `src/games/update/handler.py` - Game updates (lineup)

**Documentation:**
- `architecture-docs/ARCHITECTURE.md` - Start here
- `architecture-docs/ui/styling.md` - Theme system
- `CONTEXT_README.md` - This file

### Common Commands

```bash
# Run Flutter app
cd app && flutter run

# Run Lambda tests
cd src && pytest

# Run E2E tests
cd scripts && python run_all_tests.py

# Terraform (use tf alias)
tf init && tf plan && tf apply
```

---

## 📝 Documentation Updates

When making significant changes:

1. **Update Architecture Docs:**
   - Add new features to `ARCHITECTURE.md`
   - Update relevant `api/` or `ui/` docs
   - Update `DATA_MODEL.md` if entities change

2. **Update This README:**
   - Add to "Recent Major Changes"
   - Update "Common Patterns" if new patterns emerge
   - Update "Important Notes" for new gotchas

3. **Code Comments:**
   - Document complex logic
   - Explain design decisions
   - Note any temporary workarounds

---

## 🎯 Current Status

**Completed:**
- ✅ AtBat CRUD (26 Lambda functions total)
- ✅ Lineup management for games
- ✅ Scoring screen with interactive field
- ✅ iOS glassmorphism auth UI
- ✅ Team view with tabs
- ✅ Optimistic UI implementation
- ✅ Comprehensive test coverage

**In Progress:**
- None currently

**Future Features:**
- League/Season management
- Free agent marketplace
- Team invites
- Advanced statistics

---

**For detailed information, always refer to `/architecture-docs` folder first!**

