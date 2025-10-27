# HackTracker UI Architecture

**Current Implementation Status:** Complete MVP with User, Team & Player Management

This document describes the **complete UI implementation** for HackTracker's Flutter frontend. For backend system design, see [ARCHITECTURE.md](./ARCHITECTURE.md). For current implementation status, see [DATA_MODEL.md](../DATA_MODEL.md).

> **📖 Documentation Guide:**
> - **This document (UI_ARCHITECTURE.md):** Complete frontend implementation guide
> - **[architecture-docs/ui/](./ui/):** Detailed sub-documents for specific topics
> - **[ARCHITECTURE.md](./ARCHITECTURE.md):** Backend system design and integration
> - **[DATA_MODEL.md](../DATA_MODEL.md):** Current implementation snapshot

---

## Table of Contents

1. [Overview](#overview)
2. [Project Structure](#project-structure)
3. [State Management](#state-management)
4. [Authentication Flow](#authentication-flow)
5. [Navigation Architecture](#navigation-architecture)
6. [Screen Catalog](#screen-catalog)
7. [Optimistic UI Pattern](#optimistic-ui-pattern)
8. [API Integration](#api-integration)
9. [Reusable Widget Library](#reusable-widget-library)
10. [Theming System](#theming-system)
11. [Data Persistence](#data-persistence)
12. [Best Practices](#best-practices)

---

## Overview

### Technology Stack

- **Framework:** Flutter 3.9+ with Dart 3.9+
- **Target Platforms:** iOS, Android, Web
- **Architecture Pattern:** MVVM with Riverpod state management
- **Authentication:** AWS Amplify Auth Cognito
- **API Communication:** HTTP with JWT authentication
- **Local Storage:** Shared Preferences for persistent caching

### Key Dependencies

From `app/pubspec.yaml`:

```yaml
dependencies:
  flutter: ^3.9.0
  flutter_riverpod: ^3.0.0          # State management
  riverpod: ^3.0.0                  # Core Riverpod
  hydrated_riverpod: ^3.0.0        # Persistent state
  shared_preferences: ^2.2.2       # Local storage
  amplify_flutter: ^2.0.0          # AWS Amplify
  amplify_auth_cognito: ^2.0.0     # Cognito authentication
  http: ^1.1.0                     # HTTP client
  google_fonts: ^6.1.0            # Typography
  path_provider: ^2.1.1           # File system access
```

### Architecture Pattern

HackTracker follows a **MVVM (Model-View-ViewModel)** pattern with Riverpod:

- **Model:** DTO classes (`Team`, `Player`, `User`) representing API data
- **View:** Flutter widgets (`Screen`, `Widget` classes)
- **ViewModel:** Riverpod providers (`AsyncNotifier`, `StateProvider`)

---

## Project Structure

### Directory Layout

```
app/lib/
├── app.dart                    # Main app widget
├── main.dart                   # Entry point
├── features/                   # Feature-based organization
│   ├── auth/                   # Authentication feature
│   │   ├── screens/            # Auth screens
│   │   │   ├── login_screen.dart
│   │   │   ├── signup_screen.dart
│   │   │   └── forgot_password_screen.dart
│   │   └── widgets/            # Auth-specific widgets
│   │       └── auth_gate.dart
│   └── home/                   # Home feature
│       └── home_tab_view.dart  # Player/Team toggle
├── screens/                    # Main app screens
│   ├── home_screen.dart        # Bottom nav container
│   ├── player_view_screen.dart # Player stats view
│   ├── team_view_screen.dart   # Team management view
│   ├── profile_screen.dart     # User profile
│   └── recruiter_screen.dart   # Recruiter placeholder
├── widgets/                     # Reusable UI components
│   ├── app_drawer.dart         # Navigation drawer
│   ├── app_input_fields.dart   # Input components
│   ├── form_dialog.dart        # Modal dialogs
│   ├── confirm_dialog.dart     # Confirmation dialogs
│   ├── player_form_dialog.dart # Player add/edit form
│   └── toggle_button.dart      # Segmented button
├── providers/                   # State management
│   ├── auth_providers.dart     # Authentication state
│   ├── team_providers.dart     # Team data management
│   ├── player_providers.dart   # Player data management
│   └── persistence.dart         # Cache utilities
├── services/                    # External service integration
│   ├── api_service.dart        # HTTP API client
│   └── auth_service.dart       # Authentication service
├── theme/                       # Styling system
│   ├── app_theme.dart          # Material 3 theme
│   ├── app_colors.dart         # Color palette
│   ├── custom_text_styles.dart # Custom typography
│   └── decoration_styles.dart  # Container decorations
└── utils/                       # Utility functions
    ├── ui_helpers.dart         # UI utilities
    └── messenger.dart          # Snackbar notifications
```

### Naming Conventions

- **Files:** `snake_case.dart`
- **Classes:** `PascalCase`
- **Variables/Functions:** `camelCase`
- **Constants:** `UPPER_SNAKE_CASE`
- **Providers:** `*Provider` suffix
- **Screens:** `*Screen` suffix
- **Widgets:** `*Widget` suffix (optional)

---

## State Management

### Riverpod 3.0+ Implementation

HackTracker uses **Riverpod 3.0+** with the following provider patterns:

#### AsyncNotifierProvider (Primary Pattern)

For data fetching and caching:

```dart
// Example: TeamsNotifier
final teamsProvider = AsyncNotifierProvider<TeamsNotifier, List<Team>>(() {
  return TeamsNotifier();
});

class TeamsNotifier extends AsyncNotifier<List<Team>> {
  @override
  Future<List<Team>> build() async {
    // Load cached data first, then refresh
    final cached = await Persistence.getJson<List<Team>>(/* ... */);
    if (cached != null) {
      Future.microtask(() => _refreshInBackground());
      return cached;
    }
    return await _fetchFromAPI();
  }
}
```

#### StateProvider (Simple State)

For UI state and configuration:

```dart
final selectedTeamProvider = StateProvider<Team?>((ref) => null);
final authStatusProvider = StateProvider<AuthStatus>((ref) => AuthStatus.valid);
```

#### Family Providers

For parameterized providers:

```dart
final playerProvider = AsyncNotifierProvider.family<PlayerNotifier, Player?, String>(
  () => PlayerNotifier(),
);

class PlayerNotifier extends FamilyAsyncNotifier<Player?, String> {
  @override
  Future<Player?> build(String playerId) async {
    // Fetch specific player by ID
  }
}
```

### Persistent Caching Strategy

#### Cache Versioning

Current cache version: `1.0.0` (from `persistence.dart`)

```dart
class Persistence {
  static const String _cacheVersion = '1.0.0';
  
  static Future<void> setJson<T>(String key, T data) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheData = {
      'version': _cacheVersion,
      'timestamp': DateTime.now().toIso8601String(),
      'data': data,
    };
    await prefs.setString(key, jsonEncode(cacheData));
  }
}
```

#### Stale-While-Revalidate (SWR) Pattern

1. **On App Launch:** Show cached data immediately
2. **Background Refresh:** Fetch fresh data from API
3. **Update UI:** Replace cached data with fresh data
4. **Error Handling:** Keep cached data if API fails

```dart
@override
Future<List<Team>> build() async {
  // 1. Load cached data
  final cached = await Persistence.getJson<List<Team>>('teams_cache', /* ... */);
  
  if (cached != null && cached.isNotEmpty) {
    // 2. Show cached data immediately
    Future.microtask(() async {
      try {
        // 3. Refresh in background
        final fresh = await apiService.listTeams();
        state = AsyncValue.data(fresh);
        // 4. Update cache
        await Persistence.setJson('teams_cache', fresh.map((t) => t.toJson()).toList());
      } catch (_) {
        // 5. Keep cached data on error
      }
    });
    return cached;
  }
  
  // No cache - fetch from API
  final apiService = ref.watch(apiServiceProvider);
  final teams = await apiService.listTeams();
  await Persistence.setJson('teams_cache', teams.map((t) => t.toJson()).toList());
  return teams;
}
```

---

## Authentication Flow

### Amplify Auth Cognito Integration

HackTracker uses **AWS Amplify Auth Cognito** for authentication:

```dart
// Configuration in main.dart
await Amplify.addPlugin(AmplifyAuthCognito());
await Amplify.configure(amplifyconfig);
```

### AuthGate Widget Pattern

The `AuthGate` widget manages authentication state:

```dart
class AuthGate extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStatus = ref.watch(authStatusProvider);
    
    switch (authStatus) {
      case AuthStatus.valid:
        return const HomeScreen();
      case AuthStatus.expired:
        return const LoginScreen();
      case AuthStatus.invalidToken:
        return const LoginScreen();
      case AuthStatus.error:
        return const LoginScreen();
    }
  }
}
```

### Token Validation on App Startup

```dart
class AuthService {
  static Future<AuthStatus> validateAuth() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      final cognitoSession = session as CognitoAuthSession;
      final tokens = cognitoSession.userPoolTokensResult.value;
      
      if (tokens.idToken == null) {
        return AuthStatus.invalidToken;
      }
      
      // Decode JWT to check expiration
      final payload = _decodeJwtPayload(tokens.idToken.raw);
      final exp = payload['exp'] as int?;
      
      if (exp == null || DateTime.now().millisecondsSinceEpoch >= exp * 1000) {
        return AuthStatus.expired;
      }
      
      return AuthStatus.valid;
    } catch (e) {
      return AuthStatus.error;
    }
  }
}
```

### Session Management

- **Automatic Token Refresh:** Handled by Amplify
- **Sign Out:** Clears all cached data and redirects to login
- **Error Handling:** Automatic sign out on auth errors

---

## Navigation Architecture

### Bottom Navigation Bar Structure

Four main tabs in `HomeScreen`:

```dart
BottomNavigationBar(
  items: const [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.sports_baseball), label: 'Record'),
    BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Recruiter'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
  ],
  currentIndex: _bottomNavIndex,
  onTap: (index) => setState(() => _bottomNavIndex = index),
)
```

### Home Tab Sub-Navigation

The Home tab contains a **Player View / Team View toggle**:

```dart
class HomeTabView extends ConsumerStatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Segmented Button Toggle
        Row(
          children: [
            Expanded(child: ToggleButton(label: 'PLAYER VIEW', /* ... */)),
            Expanded(child: ToggleButton(label: 'TEAM VIEW', /* ... */)),
          ],
        ),
        // Tab Content
        Expanded(
          child: TabBarView(
            children: [
              PlayerViewScreen(onNavigateToTeamView: _navigateToTeamView),
              TeamViewScreen(onNavigateToRecruiter: widget.onNavigateToRecruiter),
            ],
          ),
        ),
      ],
    );
  }
}
```

### Drawer Navigation

`AppDrawer` provides additional navigation options:

- User profile information
- Sign out option
- App version display

### Route Management

Currently uses **imperative navigation** (no routing package):

- Bottom navigation: `setState()` to change `_bottomNavIndex`
- Sub-navigation: `TabController` for Player/Team toggle
- Modal dialogs: `showDialog()` for forms and confirmations

---

## Screen Catalog

### Authentication Screens

#### LoginScreen (`lib/features/auth/screens/login_screen.dart`)

**Purpose:** User authentication entry point

**User Flow:**
1. Email/password input
2. Sign in button
3. Navigate to "Sign Up" or "Forgot Password"
4. Success → HomeScreen

**State Management:**
- `authStatusProvider` - Authentication state
- `AuthService.signIn()` - API call

**Key Widgets:**
- `AppEmailField` - Email input
- `AppPasswordField` - Password input
- `ElevatedButton` - Sign in action

**Data Dependencies:**
- Cognito User Pool
- JWT token validation

#### SignUpScreen (`lib/features/auth/screens/signup_screen.dart`)

**Purpose:** New user registration

**User Flow:**
1. Email/password/password confirmation input
2. Password requirements validation
3. Sign up button
4. Cognito confirmation required
5. Success → LoginScreen

**State Management:**
- `authStatusProvider` - Authentication state
- `AuthService.signUp()` - API call

**Key Widgets:**
- `AppEmailField` - Email input
- `AppPasswordField` - Password input
- Password requirements display
- `ElevatedButton` - Sign up action

**Data Dependencies:**
- Cognito User Pool
- Email validation

#### ForgotPasswordScreen (`lib/features/auth/screens/forgot_password_screen.dart`)

**Purpose:** Password reset initiation

**User Flow:**
1. Email input
2. Send reset code button
3. Cognito sends reset code to email
4. Success → LoginScreen

**State Management:**
- `AuthService.resetPassword()` - API call

**Key Widgets:**
- `AppEmailField` - Email input
- `ElevatedButton` - Send reset code action

**Data Dependencies:**
- Cognito User Pool
- Email delivery

#### AuthGate (`lib/features/auth/widgets/auth_gate.dart`)

**Purpose:** Authentication state router

**User Flow:**
- Valid token → HomeScreen
- Invalid/expired token → LoginScreen

**State Management:**
- `authStatusProvider` - Authentication state

**Key Widgets:**
- Conditional rendering based on auth status

**Data Dependencies:**
- JWT token validation

### Main App Screens

#### HomeScreen (`lib/screens/home_screen.dart`)

**Purpose:** Main app container with bottom navigation

**User Flow:**
- Bottom navigation between 4 main sections
- Drawer navigation for additional options

**State Management:**
- `_bottomNavIndex` - Current tab state
- `authStatusProvider` - Authentication state

**Key Widgets:**
- `AppBar` - Top navigation
- `AppDrawer` - Side navigation
- `BottomNavigationBar` - Main navigation
- `HomeTabView` - Home tab content

**Data Dependencies:**
- Authentication status
- Navigation state

#### HomeTabView (`lib/features/home/home_tab_view.dart`)

**Purpose:** Player/Team view toggle container

**User Flow:**
- Toggle between Player View and Team View
- Navigate to Recruiter from Team View

**State Management:**
- `TabController` - Player/Team toggle state
- `SingleTickerProviderStateMixin` - Animation support

**Key Widgets:**
- `ToggleButton` - Segmented control
- `TabBarView` - Content switching
- `PlayerViewScreen` - Player stats
- `TeamViewScreen` - Team management

**Data Dependencies:**
- Navigation callbacks

#### PlayerViewScreen (`lib/screens/player_view_screen.dart`)

**Purpose:** Individual player statistics and performance

**User Flow:**
- View personal stats
- Navigate to team view
- View recent games
- View spray chart (placeholder)

**State Management:**
- `currentUserProvider` - Current user data
- `teamsProvider` - User's teams

**Key Widgets:**
- `AppBar` - Navigation
- `ToggleButton` - Navigate to team view
- Status chips - Performance indicators
- Placeholder sections for future features

**Data Dependencies:**
- Current user profile
- User's team memberships

#### TeamViewScreen (`lib/screens/team_view_screen.dart`)

**Purpose:** Team management and roster operations

**User Flow:**
- View team list
- Create new team
- Manage team roster
- Add/edit/remove players
- Navigate to recruiter

**State Management:**
- `teamsProvider` - Team data with optimistic updates
- `selectedTeamProvider` - Currently selected team
- `playersProvider` - Team roster data

**Key Widgets:**
- `AppBar` - Navigation with team selector
- `FloatingActionButton` - Create team
- `FormDialog` - Team creation form
- `PlayerFormDialog` - Player add/edit form
- `ConfirmDialog` - Player removal confirmation
- Player list with avatars and actions

**Data Dependencies:**
- Team CRUD operations
- Player CRUD operations
- User permissions

#### ProfileScreen (`lib/screens/profile_screen.dart`)

**Purpose:** User profile management

**User Flow:**
- View profile information
- Edit profile details
- Sign out

**State Management:**
- `currentUserProvider` - Current user data
- `AuthService.signOut()` - Sign out action

**Key Widgets:**
- `AppBar` - Navigation
- Profile information display
- `ElevatedButton` - Sign out action

**Data Dependencies:**
- Current user profile
- Authentication state

#### RecruiterScreen (`lib/screens/recruiter_screen.dart`)

**Purpose:** Player recruitment and free agent management (placeholder)

**User Flow:**
- Placeholder content
- Future: Browse free agents, create profiles

**State Management:**
- None (placeholder)

**Key Widgets:**
- `AppBar` - Navigation
- Placeholder content

**Data Dependencies:**
- None (placeholder)

---

## Optimistic UI Pattern

### Race-Condition-Safe Implementation

HackTracker implements a **race-condition-safe optimistic UI** pattern:

#### Temp ID Pattern

```dart
// Generate temporary ID for optimistic updates
String _generateTempId() {
  return 'temp-${DateTime.now().millisecondsSinceEpoch}';
}

// Add optimistic team
final tempTeam = Team(
  teamId: _generateTempId(),
  name: name,
  description: description,
  ownerId: currentUser.userId,
  status: 'active',
  createdAt: DateTime.now().toIso8601String(),
  updatedAt: DateTime.now().toIso8601String(),
);

// Update UI immediately
state = AsyncValue.data([...currentTeams, tempTeam]);
```

#### Rollback from Current State

Instead of reverting to snapshots, rollback operates on **current state**:

```dart
Future<void> _rollbackAddTeam(String tempId) async {
  state.whenData((teams) {
    final updatedTeams = teams.where((team) => team.teamId != tempId).toList();
    state = AsyncValue.data(updatedTeams);
  });
}
```

#### Success/Error Messaging

```dart
try {
  final newTeam = await apiService.createTeam(name, description);
  
  // Replace temp team with real team
  state.whenData((teams) {
    final updatedTeams = teams.map((team) {
      return team.teamId == tempId ? newTeam : team;
    }).toList();
    state = AsyncValue.data(updatedTeams);
  });
  
  // Show success message
  Messenger.showSuccess(context, 'Team created successfully!');
} catch (e) {
  // Rollback optimistic update
  await _rollbackAddTeam(tempId);
  
  // Show error message
  Messenger.showError(context, 'Failed to create team: ${e.toString()}');
}
```

### Example from team_providers.dart

```dart
Future<void> addTeam(String name, String description) async {
  final currentUser = ref.read(currentUserProvider);
  if (currentUser == null) return;
  
  // Generate temp ID
  final tempId = _generateTempId();
  
  // Create optimistic team
  final tempTeam = Team(
    teamId: tempId,
    name: name,
    description: description,
    ownerId: currentUser.userId,
    status: 'active',
    createdAt: DateTime.now().toIso8601String(),
    updatedAt: DateTime.now().toIso8601String(),
  );
  
  // Update UI immediately
  state.whenData((teams) {
    state = AsyncValue.data([...teams, tempTeam]);
  });
  
  try {
    // API call
    final newTeam = await apiService.createTeam(name, description);
    
    // Replace temp with real
    state.whenData((teams) {
      final updatedTeams = teams.map((team) {
        return team.teamId == tempId ? newTeam : team;
      }).toList();
      state = AsyncValue.data(updatedTeams);
    });
    
    Messenger.showSuccess(context, 'Team created successfully!');
  } catch (e) {
    // Rollback
    state.whenData((teams) {
      final updatedTeams = teams.where((team) => team.teamId != tempId).toList();
      state = AsyncValue.data(updatedTeams);
    });
    
    Messenger.showError(context, 'Failed to create team: ${e.toString()}');
  }
}
```

---

## API Integration

### ApiService Architecture

The `ApiService` class handles all HTTP communication:

```dart
class ApiService {
  final String baseUrl;
  
  ApiService({required this.baseUrl});
  
  // Get Cognito ID token for authentication
  Future<String> _getIdToken() async {
    final session = await Amplify.Auth.fetchAuthSession();
    final cognitoSession = session as CognitoAuthSession;
    final tokens = cognitoSession.userPoolTokensResult.value;
    return tokens.idToken.raw;
  }
  
  // Make authenticated HTTP request
  Future<http.Response> _authenticatedRequest({
    required String method,
    required String path,
    Map<String, dynamic>? body,
  }) async {
    final idToken = await _getIdToken();
    final uri = Uri.parse('$baseUrl$path');
    
    final headers = {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };
    
    // Handle different HTTP methods
    switch (method.toUpperCase()) {
      case 'GET': return await http.get(uri, headers: headers);
      case 'POST': return await http.post(uri, headers: headers, body: jsonEncode(body));
      case 'PUT': return await http.put(uri, headers: headers, body: jsonEncode(body));
      case 'DELETE': return await http.delete(uri, headers: headers);
      default: throw ArgumentError('Unsupported HTTP method: $method');
    }
  }
}
```

### Authentication Header Injection

All API requests automatically include JWT authentication:

```dart
Future<List<Team>> listTeams() async {
  final response = await _authenticatedRequest(
    method: 'GET',
    path: '/teams',
  );
  return _handleResponse(response);
}
```

### Error Handling Patterns

```dart
dynamic _handleResponse(http.Response response) {
  if (response.statusCode >= 200 && response.statusCode < 300) {
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  } else {
    // Parse error response
    dynamic errorBody;
    try {
      errorBody = jsonDecode(response.body);
    } catch (_) {
      errorBody = {'message': response.body};
    }
    
    throw ApiException(
      statusCode: response.statusCode,
      message: errorBody['message'] ?? 'Unknown error',
      errorType: errorBody['errorType'] ?? 'Unknown',
    );
  }
}
```

### DTO Models

Clean data transfer objects without internal DynamoDB fields:

```dart
class Team {
  final String teamId;
  final String name;
  final String? description;
  final String ownerId;
  final String status;
  final bool isPersonal;
  final String createdAt;
  final String updatedAt;
  
  Team({
    required this.teamId,
    required this.name,
    this.description,
    required this.ownerId,
    required this.status,
    this.isPersonal = false,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      teamId: json['teamId'],
      name: json['name'],
      description: json['description'],
      ownerId: json['ownerId'],
      status: json['status'],
      isPersonal: json['isPersonal'] ?? false,
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'teamId': teamId,
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'status': status,
      'isPersonal': isPersonal,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
```

### Response Parsing

All API responses are parsed into DTO objects:

```dart
Future<List<Team>> listTeams() async {
  final response = await _authenticatedRequest(method: 'GET', path: '/teams');
  final data = _handleResponse(response);
  
  if (data is List) {
    return data.map((item) => Team.fromJson(item)).toList();
  }
  
  throw ApiException(
    statusCode: 500,
    message: 'Invalid response format',
    errorType: 'ParseError',
  );
}
```

---

## Reusable Widget Library

### AppDrawer (`lib/widgets/app_drawer.dart`)

**Purpose:** Navigation drawer with user information

**Props:**
- `onSignOut` - Sign out callback

**Usage:**
```dart
AppDrawer(onSignOut: () => AuthService.signOut())
```

**Features:**
- User profile display
- Sign out option
- App version information

### AppTextField/AppTextFormField (`lib/widgets/app_input_fields.dart`)

**Purpose:** Standardized text input components

**Props:**
- `controller` - Text editing controller
- `labelText` - Input label
- `hintText` - Placeholder text
- `validator` - Form validation function
- `obscureText` - Password masking
- `keyboardType` - Input keyboard type

**Usage:**
```dart
AppTextField(
  controller: _nameController,
  labelText: 'Team Name',
  hintText: 'Enter team name',
)
```

**Features:**
- Consistent styling via theme
- Form validation support
- Autofill prevention
- Accessibility support

### AppPasswordField (`lib/widgets/app_input_fields.dart`)

**Purpose:** Password input with validation

**Props:**
- `controller` - Text editing controller
- `labelText` - Input label
- `validator` - Password validation function

**Usage:**
```dart
AppPasswordField(
  controller: _passwordController,
  labelText: 'Password',
  validator: _validatePassword,
)
```

**Features:**
- Password visibility toggle
- Strength requirements display
- Autofill prevention

### AppEmailField (`lib/widgets/app_input_fields.dart`)

**Purpose:** Email input with validation

**Props:**
- `controller` - Text editing controller
- `labelText` - Input label
- `validator` - Email validation function

**Usage:**
```dart
AppEmailField(
  controller: _emailController,
  labelText: 'Email',
  validator: _validateEmail,
)
```

**Features:**
- Email keyboard type
- Email validation
- Autofill prevention

### AppDropdownFormField (`lib/widgets/app_input_fields.dart`)

**Purpose:** Dropdown selection component

**Props:**
- `value` - Selected value
- `items` - List of dropdown items
- `onChanged` - Selection callback
- `hint` - Placeholder text

**Usage:**
```dart
AppDropdownFormField<String>(
  value: _selectedStatus,
  items: ['active', 'inactive', 'sub'],
  onChanged: (value) => setState(() => _selectedStatus = value),
  hint: 'Select status',
)
```

### FormDialog (`lib/widgets/form_dialog.dart`)

**Purpose:** Modal dialog wrapper for forms

**Props:**
- `title` - Dialog title
- `children` - Form widgets
- `onSave` - Save callback
- `onCancel` - Cancel callback
- `saveText` - Save button text
- `cancelText` - Cancel button text

**Usage:**
```dart
FormDialog(
  title: 'Create Team',
  children: [
    AppTextField(controller: _nameController, labelText: 'Team Name'),
    AppTextField(controller: _descController, labelText: 'Description'),
  ],
  onSave: () => _createTeam(),
  onCancel: () => Navigator.pop(context),
)
```

**Features:**
- Responsive width (percentage-based with min/max)
- Consistent button styling
- Form validation support
- Keyboard handling

### ConfirmDialog (`lib/widgets/confirm_dialog.dart`)

**Purpose:** Confirmation dialog for destructive actions

**Props:**
- `title` - Dialog title
- `message` - Confirmation message
- `confirmText` - Confirm button text
- `cancelText` - Cancel button text
- `onConfirm` - Confirm callback
- `onCancel` - Cancel callback

**Usage:**
```dart
ConfirmDialog(
  title: 'Remove Player',
  message: 'Are you sure you want to remove this player?',
  confirmText: 'Remove',
  cancelText: 'Cancel',
  onConfirm: () => _removePlayer(),
  onCancel: () => Navigator.pop(context),
)
```

### PlayerFormDialog (`lib/widgets/player_form_dialog.dart`)

**Purpose:** Player add/edit form dialog

**Props:**
- `player` - Existing player (null for new)
- `onSave` - Save callback
- `onCancel` - Cancel callback

**Usage:**
```dart
PlayerFormDialog(
  player: existingPlayer, // null for new player
  onSave: (playerData) => _savePlayer(playerData),
  onCancel: () => Navigator.pop(context),
)
```

**Features:**
- Form validation
- Player number input (0-99)
- Status selection
- First/last name inputs

### ToggleButton (`lib/widgets/toggle_button.dart`)

**Purpose:** Segmented button for navigation

**Props:**
- `label` - Button text
- `isSelected` - Selection state
- `onTap` - Tap callback

**Usage:**
```dart
ToggleButton(
  label: 'PLAYER VIEW',
  isSelected: _tabController.index == 0,
  onTap: () => _tabController.animateTo(0),
)
```

**Features:**
- Custom styling via theme
- Selection state management
- Smooth animations

### UI Helpers (`lib/utils/ui_helpers.dart`)

**Purpose:** Utility functions for UI components

**Functions:**
- `buildStatusChip()` - Status indicator chips
- `buildPlayerAvatar()` - Player number avatars
- `buildLoadingIndicator()` - Loading spinners
- `buildErrorWidget()` - Error display widgets

**Usage:**
```dart
buildStatusChip('active', context)  // Green chip
buildPlayerAvatar(12, context)      // Circular avatar with number
buildLoadingIndicator(context)      // Standard loading spinner
```

---

## Theming System

### Material 3 Theme Configuration

HackTracker uses **Material 3** with custom styling:

```dart
// app/lib/theme/app_theme.dart
ThemeData _buildTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ),
    textTheme: _buildTextTheme(),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        textStyle: GoogleFonts.tektur(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    extensions: [
      CustomTextStyles.dark,
    ],
  );
}
```

### Tektur Font Integration

**Google Fonts** integration for typography:

```dart
TextTheme _buildTextTheme() {
  return TextTheme(
    displayLarge: GoogleFonts.tektur(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      letterSpacing: -0.5,
    ),
    displayMedium: GoogleFonts.tektur(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: -0.25,
    ),
    // ... complete Material 3 text scale
  );
}
```

### AppColors - Color Palette

Centralized color management:

```dart
// app/lib/theme/app_colors.dart
class AppColors {
  // Brand colors (bright/neon theme)
  static const primary = Color(0xFF14D68E);     // Bright emerald
  static const secondary = Color(0xFF4AE4A8);  // Bright mint
  
  // Backgrounds
  static const background = Color(0xFF0F172A); // Dark slate
  static const surface = Color(0xFF1E293B);    // Slate
  
  // Text colors
  static const textPrimary = Color(0xFFE2E8F0);
  static const textSecondary = Color(0xFF94A3B8);
  static const textTertiary = Color(0xFF64748B);
  
  // Status colors
  static const error = Color(0xFFEF4444);
  static const success = Color(0xFF14D68E);
}
```

### CustomTextStyles ThemeExtension

Custom text styles that don't fit Material's standard categories:

```dart
// app/lib/theme/custom_text_styles.dart
class CustomTextStyles extends ThemeExtension<CustomTextStyles> {
  final TextStyle toggleButtonLabel;
  final TextStyle statusIndicator;
  final TextStyle appBarTitle;
  final TextStyle sectionHeader;
  final TextStyle errorMessage;
  
  const CustomTextStyles({
    required this.toggleButtonLabel,
    required this.statusIndicator,
    required this.appBarTitle,
    required this.sectionHeader,
    required this.errorMessage,
  });
  
  // Usage in widgets:
  // Theme.of(context).extension<CustomTextStyles>()!.toggleButtonLabel
}
```

### DecorationStyles Utility Class

Common `BoxDecoration` patterns:

```dart
// app/lib/theme/decoration_styles.dart
class DecorationStyles {
  static BoxDecoration primaryBorder() {
    return BoxDecoration(
      border: Border.all(color: AppColors.primary, width: 2),
      borderRadius: BorderRadius.circular(8),
    );
  }
  
  static BoxDecoration surfaceContainer() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    );
  }
  
  static BoxDecoration statusContainer() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.border),
    );
  }
}
```

### Dark Theme Implementation

HackTracker uses a **dark theme** throughout:

- **Background:** Dark slate (`#0F172A`)
- **Surface:** Slate (`#1E293B`)
- **Text:** Light colors for contrast
- **Accents:** Bright emerald/mint for visibility

---

## Data Persistence

### Shared Preferences Usage

Local storage for persistent caching:

```dart
// app/lib/providers/persistence.dart
class Persistence {
  static const String _cacheVersion = '1.0.0';
  
  static Future<void> setJson<T>(String key, T data) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheData = {
      'version': _cacheVersion,
      'timestamp': DateTime.now().toIso8601String(),
      'data': data,
    };
    await prefs.setString(key, jsonEncode(cacheData));
  }
  
  static Future<T?> getJson<T>(String key, T Function(dynamic) fromJson) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);
    
    if (jsonString == null) return null;
    
    try {
      final cacheData = jsonDecode(jsonString);
      final version = cacheData['version'] as String?;
      
      if (version != _cacheVersion) {
        // Clear outdated cache
        await prefs.remove(key);
        return null;
      }
      
      return fromJson(cacheData['data']);
    } catch (e) {
      // Clear corrupted cache
      await prefs.remove(key);
      return null;
    }
  }
}
```

### Cache Keys and Structure

Standardized cache key naming:

```dart
// Cache keys
const String teamsCacheKey = 'teams_cache';
const String playersCacheKey = 'players_cache';
const String currentUserCacheKey = 'current_user_cache';

// Cache structure
{
  "version": "1.0.0",
  "timestamp": "2025-01-27T10:30:00.000Z",
  "data": [/* actual data */]
}
```

### Cache Versioning Strategy

**Version 1.0.0** - Current implementation

- **Breaking Changes:** Increment major version (2.0.0)
- **Schema Changes:** Increment minor version (1.1.0)
- **Bug Fixes:** Increment patch version (1.0.1)

**Migration Strategy:**
- Old cache versions are automatically cleared
- No backward compatibility maintained
- Fresh data fetched on version mismatch

### Persistence Utility Class

Centralized cache management:

```dart
class Persistence {
  // Set cache with versioning
  static Future<void> setJson<T>(String key, T data) async { /* ... */ }
  
  // Get cache with version check
  static Future<T?> getJson<T>(String key, T Function(dynamic) fromJson) async { /* ... */ }
  
  // Clear specific cache
  static Future<void> clearCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
  
  // Clear all cache
  static Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
```

---

## Best Practices

### Widget Composition Patterns

#### Single Responsibility Principle

Each widget should have one clear purpose:

```dart
// Good: Single purpose
class PlayerAvatar extends StatelessWidget {
  final int playerNumber;
  const PlayerAvatar({required this.playerNumber});
  
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: AppColors.primary,
      child: Text('$playerNumber'),
    );
  }
}

// Bad: Multiple purposes
class PlayerInfo extends StatelessWidget {
  // Handles avatar, name, status, actions - too many responsibilities
}
```

#### Composition over Inheritance

Build complex widgets by composing simpler ones:

```dart
class PlayerCard extends StatelessWidget {
  final Player player;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            PlayerAvatar(playerNumber: player.playerNumber),
            Text(player.firstName),
            Text(player.lastName ?? ''),
            StatusChip(status: player.status),
          ],
        ),
      ),
    );
  }
}
```

### Provider Usage Guidelines

#### AsyncNotifier for Data Fetching

Use `AsyncNotifier` for data that needs to be fetched:

```dart
final teamsProvider = AsyncNotifierProvider<TeamsNotifier, List<Team>>(() {
  return TeamsNotifier();
});

class TeamsNotifier extends AsyncNotifier<List<Team>> {
  @override
  Future<List<Team>> build() async {
    // Data fetching logic
  }
}
```

#### StateProvider for Simple State

Use `StateProvider` for simple UI state:

```dart
final selectedTeamProvider = StateProvider<Team?>((ref) => null);
final isLoadingProvider = StateProvider<bool>((ref) => false);
```

#### Family Providers for Parameters

Use family providers for parameterized data:

```dart
final playerProvider = AsyncNotifierProvider.family<PlayerNotifier, Player?, String>(
  () => PlayerNotifier(),
);
```

### Error Handling Standards

#### Provider Error Handling

```dart
class TeamsNotifier extends AsyncNotifier<List<Team>> {
  @override
  Future<List<Team>> build() async {
    try {
      final apiService = ref.watch(apiServiceProvider);
      return await apiService.listTeams();
    } catch (e) {
      // Log error
      print('Error fetching teams: $e');
      
      // Return empty list or cached data
      return [];
    }
  }
}
```

#### UI Error Display

```dart
Consumer(
  builder: (context, ref, child) {
    final teamsAsync = ref.watch(teamsProvider);
    
    return teamsAsync.when(
      data: (teams) => TeamsList(teams: teams),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => ErrorWidget(error),
    );
  },
)
```

### Form Validation Patterns

#### Input Validation

```dart
String? _validateTeamName(String? value) {
  if (value == null || value.isEmpty) {
    return 'Team name is required';
  }
  if (value.length < 3) {
    return 'Team name must be at least 3 characters';
  }
  if (value.length > 50) {
    return 'Team name must be less than 50 characters';
  }
  return null;
}
```

#### Form State Management

```dart
class _CreateTeamFormState extends State<CreateTeamForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Form is valid, proceed with submission
      widget.onSave(_nameController.text, _descController.text);
    }
  }
}
```

### Responsive Design Approach

#### Screen Size Adaptation

```dart
class ResponsiveWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 600) {
      return MobileLayout();
    } else if (screenWidth < 1200) {
      return TabletLayout();
    } else {
      return DesktopLayout();
    }
  }
}
```

#### Flexible Layouts

```dart
// Use Expanded and Flexible for responsive layouts
Row(
  children: [
    Expanded(
      flex: 2,
      child: MainContent(),
    ),
    Expanded(
      flex: 1,
      child: Sidebar(),
    ),
  ],
)
```

#### Responsive Dialogs

```dart
// FormDialog uses responsive width
static double _getDialogWidth(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final maxWidth = screenWidth * 0.8; // 80% of screen width
  return maxWidth.clamp(300.0, 600.0); // Min 300px, max 600px
}
```

---

## Cross-References

### Related Documentation

- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Backend system design and integration patterns
- **[DATA_MODEL.md](../DATA_MODEL.md)** - Current implementation status and API contracts
- **[architecture-docs/caching.md](./caching.md)** - Detailed caching strategy and implementation
- **[architecture-docs/authorization.md](./authorization.md)** - Backend authorization patterns
- **[architecture-docs/dynamodb-design.md](./dynamodb-design.md)** - Database schema and access patterns

### Detailed Sub-Documents

- **[architecture-docs/ui/screens.md](./ui/screens.md)** - Comprehensive screen documentation
- **[architecture-docs/ui/state-management.md](./ui/state-management.md)** - Deep dive into Riverpod implementation
- **[architecture-docs/ui/styling.md](./ui/styling.md)** - Complete theming guide
- **[architecture-docs/ui/widgets.md](./ui/widgets.md)** - Widget catalog with examples
- **[architecture-docs/ui/forms.md](./ui/forms.md)** - Form handling patterns

### Testing and Development

- **[TESTING.md](../TESTING.md)** - Testing workflows and commands
- **[Makefile](../Makefile)** - Development commands and workflows

---

## Summary

HackTracker's UI architecture provides a **comprehensive, scalable foundation** for a Flutter application with:

- **Modern State Management:** Riverpod 3.0+ with persistent caching
- **Optimistic UI:** Race-condition-safe updates with rollback
- **Centralized Styling:** Material 3 theme with custom extensions
- **Reusable Components:** Modular widget library
- **Authentication Integration:** AWS Amplify Cognito
- **API Communication:** Clean HTTP client with JWT authentication
- **Responsive Design:** Adaptive layouts for multiple screen sizes

The architecture follows **Flutter best practices** and provides a **solid foundation** for future feature development while maintaining **code quality** and **user experience** standards.
