# Screen Documentation

**Part of:** [ARCHITECTURE.md](../ARCHITECTURE.md) - Complete system architecture guide

This document provides comprehensive documentation for all screens in the HackTracker Flutter application.

---

## Table of Contents

1. [Authentication Screens](#authentication-screens)
2. [Main App Screens](#main-app-screens)
3. [Screen Patterns](#screen-patterns)
4. [Navigation Flow](#navigation-flow)

---

## Authentication Screens

### LoginScreen

**File:** `lib/features/auth/screens/login_screen.dart`

**Purpose:** Primary authentication entry point for existing users

**Widget Tree Structure:**
```
LoginScreen
├── Scaffold
│   ├── AppBar (title: "Sign In")
│   └── Body
│       ├── Container (header decoration)
│       │   └── Text ("HACKTRACKER")
│       ├── Form
│       │   ├── AppEmailField
│       │   ├── AppPasswordField
│       │   └── ElevatedButton ("Sign In")
│       ├── Row (navigation links)
│       │   ├── TextButton ("Sign Up")
│       │   └── TextButton ("Forgot Password?")
│       └── Error Container (conditional)
```

**Props and Callbacks:**
- No external props (stateless screen)
- Internal callbacks:
  - `_signIn()` - Authenticate user
  - `_navigateToSignUp()` - Navigate to signup
  - `_navigateToForgotPassword()` - Navigate to password reset

**State Dependencies:**
- `authStatusProvider` - Authentication state management
- `AuthService.signIn()` - Cognito authentication
- Form validation state (local)

**Navigation Patterns:**
- Success → `HomeScreen` (via `AuthGate`)
- Sign Up → `SignUpScreen`
- Forgot Password → `ForgotPasswordScreen`
- Error → Stay on screen with error message

**Code Example:**
```dart
class LoginScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      try {
        await AuthService.signIn(
          _emailController.text,
          _passwordController.text,
        );
        // Navigation handled by AuthGate
      } catch (e) {
        setState(() => _errorMessage = e.toString());
      }
    }
  }
}
```

### SignUpScreen

**File:** `lib/features/auth/screens/signup_screen.dart`

**Purpose:** New user registration with password requirements

**Widget Tree Structure:**
```
SignUpScreen
├── Scaffold
│   ├── AppBar (title: "Create Account")
│   └── Body
│       ├── Container (header decoration)
│       │   └── Text ("JOIN HACKTRACKER")
│       ├── Form
│       │   ├── AppEmailField
│       │   ├── AppPasswordField
│       │   ├── AppPasswordField (confirmation)
│       │   └── ElevatedButton ("Create Account")
│       ├── Password Requirements Container
│       │   └── Column (requirement items)
│       ├── Row (navigation links)
│       │   └── TextButton ("Already have an account? Sign In")
│       └── Error Container (conditional)
```

**Props and Callbacks:**
- No external props
- Internal callbacks:
  - `_signUp()` - Register new user
  - `_navigateToLogin()` - Navigate to login

**State Dependencies:**
- `authStatusProvider` - Authentication state
- `AuthService.signUp()` - Cognito registration
- Form validation state (local)

**Navigation Patterns:**
- Success → `LoginScreen` (confirmation required)
- Login → `LoginScreen`
- Error → Stay on screen with error message

**Code Example:**
```dart
Future<void> _signUp() async {
  if (_formKey.currentState!.validate()) {
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }
    
    try {
      await AuthService.signUp(
        _emailController.text,
        _passwordController.text,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    }
  }
}
```

### ForgotPasswordScreen

**File:** `lib/features/auth/screens/forgot_password_screen.dart`

**Purpose:** Password reset initiation

**Widget Tree Structure:**
```
ForgotPasswordScreen
├── Scaffold
│   ├── AppBar (title: "Reset Password")
│   └── Body
│       ├── Container (header decoration)
│       │   └── Text ("RESET PASSWORD")
│       ├── Container (info box)
│       │   └── Text (instructions)
│       ├── Form
│       │   ├── AppEmailField
│       │   └── ElevatedButton ("Send Reset Code")
│       ├── Row (navigation links)
│       │   └── TextButton ("Back to Sign In")
│       └── Error Container (conditional)
```

**Props and Callbacks:**
- No external props
- Internal callbacks:
  - `_resetPassword()` - Send reset code
  - `_navigateToLogin()` - Navigate to login

**State Dependencies:**
- `AuthService.resetPassword()` - Cognito password reset
- Form validation state (local)

**Navigation Patterns:**
- Success → `LoginScreen` (with success message)
- Back to Sign In → `LoginScreen`
- Error → Stay on screen with error message

### AuthGate

**File:** `lib/features/auth/widgets/auth_gate.dart`

**Purpose:** Authentication state router

**Widget Tree Structure:**
```
AuthGate
└── Consumer
    └── Switch (authStatus)
        ├── AuthStatus.valid → HomeScreen
        ├── AuthStatus.expired → LoginScreen
        ├── AuthStatus.invalidToken → LoginScreen
        └── AuthStatus.error → LoginScreen
```

**Props and Callbacks:**
- No external props
- Internal callbacks:
  - `AuthService.validateAuth()` - Token validation

**State Dependencies:**
- `authStatusProvider` - Authentication state
- `AuthService.validateAuth()` - Token validation

**Navigation Patterns:**
- Valid token → `HomeScreen`
- Invalid/expired token → `LoginScreen`

---

## Main App Screens

### HomeScreen

**File:** `lib/screens/home_screen.dart`

**Purpose:** Main app container with bottom navigation

**Widget Tree Structure:**
```
HomeScreen
├── Scaffold
│   ├── AppBar
│   │   ├── IconButton (menu)
│   │   └── Text (title)
│   ├── AppDrawer
│   ├── Body
│   │   └── Switch (_bottomNavIndex)
│   │       ├── 0 → HomeTabView
│   │       ├── 1 → Record Placeholder
│   │       ├── 2 → RecruiterScreen
│   │       └── 3 → ProfileScreen
│   └── BottomNavigationBar
│       ├── BottomNavigationBarItem (Home)
│       ├── BottomNavigationBarItem (Record)
│       ├── BottomNavigationBarItem (Recruiter)
│       └── BottomNavigationBarItem (Profile)
```

**Props and Callbacks:**
- No external props
- Internal callbacks:
  - `_navigateToRecruiter()` - Switch to recruiter tab
  - `_buildCurrentScreen()` - Render current tab content

**State Dependencies:**
- `_bottomNavIndex` - Current tab state (local)
- `authStatusProvider` - Authentication state

**Navigation Patterns:**
- Bottom navigation → Switch tabs
- Drawer → Additional navigation options
- Home tab → `HomeTabView` with sub-navigation

**Code Example:**
```dart
class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _bottomNavIndex = 0;

  void _navigateToRecruiter() {
    setState(() {
      _bottomNavIndex = 2; // Recruiter tab index
    });
  }

  Widget _buildCurrentScreen() {
    switch (_bottomNavIndex) {
      case 0: return HomeTabView(onNavigateToRecruiter: _navigateToRecruiter);
      case 1: return const Center(child: Text('RECORD AT-BAT'));
      case 2: return const RecruiterScreen();
      case 3: return const ProfileScreen();
      default: return HomeTabView(onNavigateToRecruiter: _navigateToRecruiter);
    }
  }
}
```

### HomeTabView

**File:** `lib/features/home/home_tab_view.dart`

**Purpose:** Player/Team view toggle container

**Widget Tree Structure:**
```
HomeTabView
├── Column
│   ├── Container (segmented button container)
│   │   └── Row
│   │       ├── Expanded
│   │       │   └── ToggleButton ("PLAYER VIEW")
│   │       ├── SizedBox (spacing)
│   │       └── Expanded
│   │           └── ToggleButton ("TEAM VIEW")
│   └── Expanded
│       └── TabBarView
│           ├── PlayerViewScreen
│           └── TeamViewScreen
```

**Props and Callbacks:**
- `onNavigateToRecruiter` - Callback to navigate to recruiter tab

**State Dependencies:**
- `TabController` - Player/Team toggle state
- `SingleTickerProviderStateMixin` - Animation support

**Navigation Patterns:**
- Player View → `PlayerViewScreen`
- Team View → `TeamViewScreen`
- Recruiter navigation → Parent `HomeScreen`

**Code Example:**
```dart
class HomeTabView extends ConsumerStatefulWidget {
  final VoidCallback onNavigateToRecruiter;
  
  const HomeTabView({super.key, required this.onNavigateToRecruiter});

  @override
  ConsumerState<HomeTabView> createState() => _HomeTabViewState();
}

class _HomeTabViewState extends ConsumerState<HomeTabView> 
    with SingleTickerProviderStateMixin {
  late TabController _topTabController;

  @override
  void initState() {
    super.initState();
    _topTabController = TabController(length: 2, vsync: this);
  }

  void _navigateToTeamView() {
    setState(() {
      _topTabController.animateTo(1);
    });
  }
}
```

### PlayerViewScreen

**File:** `lib/screens/player_view_screen.dart`

**Purpose:** Individual player statistics and performance view

**Widget Tree Structure:**
```
PlayerViewScreen
├── Scaffold
│   ├── AppBar
│   │   ├── IconButton (back)
│   │   └── Text (title)
│   └── Body
│       ├── Container (header)
│       │   ├── Text ("PLAYER VIEW")
│       │   └── ToggleButton ("Go to Team View")
│       ├── Consumer (current user)
│       │   └── Column
│       │       ├── Text (user name)
│       │       ├── Text (user email)
│       │       └── Status chips
│       ├── Container (My Teams section)
│       │   ├── Text ("My Teams")
│       │   └── Consumer (teams)
│       │       └── ListView (teams)
│       ├── Container (Recent Games placeholder)
│       │   └── Text ("Recent Games")
│       └── Container (Spray Chart placeholder)
│           └── Text ("Spray Chart")
```

**Props and Callbacks:**
- `onNavigateToTeamView` - Navigate to team view callback

**State Dependencies:**
- `currentUserProvider` - Current user data
- `teamsProvider` - User's teams

**Navigation Patterns:**
- Back → Previous screen
- Go to Team View → `TeamViewScreen`
- Team selection → Team details (future)

**Code Example:**
```dart
class PlayerViewScreen extends ConsumerWidget {
  final VoidCallback onNavigateToTeamView;
  
  const PlayerViewScreen({super.key, required this.onNavigateToTeamView});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final teamsAsync = ref.watch(teamsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Player View', style: Theme.of(context).extension<CustomTextStyles>()!.appBarTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            _buildUserInfo(context, ref, currentUserAsync),
            _buildMyTeams(context, ref, teamsAsync),
            _buildRecentGames(context),
            _buildSprayChart(context),
          ],
        ),
      ),
    );
  }
}
```

### TeamViewScreen

**File:** `lib/screens/team_view_screen.dart`

**Purpose:** Team management and roster operations

**Widget Tree Structure:**
```
TeamViewScreen
├── Scaffold
│   ├── AppBar
│   │   ├── IconButton (back)
│   │   ├── DropdownButton (team selector)
│   │   └── IconButton (add player)
│   ├── Body
│   │   └── Consumer (teams)
│   │       └── Switch (teams state)
│   │           ├── Empty → Empty state
│   │           └── Has teams → Team content
│   │               ├── Consumer (selected team)
│   │               └── Consumer (players)
│   │                   └── Column
│   │                       ├── Text ("Roster")
│   │                       └── ListView (players)
│   └── FloatingActionButton (create team)
```

**Props and Callbacks:**
- `onNavigateToRecruiter` - Navigate to recruiter callback

**State Dependencies:**
- `teamsProvider` - Team data with optimistic updates
- `selectedTeamProvider` - Currently selected team
- `playersProvider` - Team roster data

**Navigation Patterns:**
- Back → Previous screen
- Create Team → `FormDialog`
- Add Player → `PlayerFormDialog`
- Remove Player → `ConfirmDialog`
- Navigate to Recruiter → Parent callback

**Code Example:**
```dart
class TeamViewScreen extends ConsumerWidget {
  final VoidCallback onNavigateToRecruiter;
  
  const TeamViewScreen({super.key, required this.onNavigateToRecruiter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(teamsProvider);
    final selectedTeam = ref.watch(selectedTeamProvider);

    return Scaffold(
      appBar: AppBar(
        title: _buildTeamSelector(context, ref, teamsAsync),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (selectedTeam != null)
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () => _showAddPlayerDialog(context, ref, selectedTeam),
            ),
        ],
      ),
      body: teamsAsync.when(
        data: (teams) => _buildTeamContent(context, ref, teams, selectedTeam),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTeamDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### ProfileScreen

**File:** `lib/screens/profile_screen.dart`

**Purpose:** User profile management and settings

**Widget Tree Structure:**
```
ProfileScreen
├── Scaffold
│   ├── AppBar
│   │   ├── IconButton (back)
│   │   └── Text ("Profile")
│   └── Body
│       └── Consumer (current user)
│           └── Column
│               ├── Container (profile header)
│               │   ├── CircleAvatar
│               │   └── Text (user name)
│               ├── Container (profile info)
│               │   ├── Text ("Email")
│               │   ├── Text (user email)
│               │   ├── Text ("Phone")
│               │   └── Text (user phone)
│               └── ElevatedButton ("Sign Out")
```

**Props and Callbacks:**
- No external props
- Internal callbacks:
  - `_signOut()` - Sign out user

**State Dependencies:**
- `currentUserProvider` - Current user data
- `AuthService.signOut()` - Sign out action

**Navigation Patterns:**
- Back → Previous screen
- Sign Out → `LoginScreen` (via `AuthGate`)

### RecruiterScreen

**File:** `lib/screens/recruiter_screen.dart`

**Purpose:** Player recruitment and free agent management (placeholder)

**Widget Tree Structure:**
```
RecruiterScreen
├── Scaffold
│   ├── AppBar
│   │   ├── IconButton (back)
│   │   └── Text ("Recruiter")
│   └── Body
│       └── Center
│           └── Column
│               ├── Icon (placeholder)
│               ├── Text ("Recruiter")
│               └── Text ("Coming Soon")
```

**Props and Callbacks:**
- No external props
- No callbacks (placeholder)

**State Dependencies:**
- None (placeholder)

**Navigation Patterns:**
- Back → Previous screen

---

## Screen Patterns

### Common Screen Structure

Most screens follow this pattern:

```dart
class ExampleScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Screen Title'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final dataAsync = ref.watch(dataProvider);
          
          return dataAsync.when(
            data: (data) => _buildContent(data),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          );
        },
      ),
    );
  }
}
```

### Error Handling Pattern

```dart
Widget _buildContent(dynamic data) {
  try {
    return _renderData(data);
  } catch (e) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.error, size: 48, color: AppColors.error),
          Text('Something went wrong'),
          Text('$e'),
        ],
      ),
    );
  }
}
```

### Loading State Pattern

```dart
Widget _buildLoadingState() {
  return const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Loading...'),
      ],
    ),
  );
}
```

---

## Navigation Flow

### Authentication Flow

```
App Launch
    ↓
AuthGate
    ↓
Token Valid? ──No──→ LoginScreen
    ↓ Yes
HomeScreen
```

### Main App Flow

```
HomeScreen
    ↓
Bottom Navigation
    ├── Home Tab
    │   ├── Player View
    │   └── Team View
    ├── Record Tab (placeholder)
    ├── Recruiter Tab
    └── Profile Tab
```

### Team Management Flow

```
TeamViewScreen
    ↓
Team Actions
    ├── Create Team → FormDialog
    ├── Select Team → Dropdown
    ├── Add Player → PlayerFormDialog
    ├── Edit Player → PlayerFormDialog
    └── Remove Player → ConfirmDialog
```

### Modal Dialog Flow

```
Screen Action
    ↓
showDialog()
    ↓
Dialog Widget
    ├── FormDialog (forms)
    ├── ConfirmDialog (confirmations)
    └── PlayerFormDialog (player forms)
    ↓
User Action
    ├── Save → API Call → Close Dialog
    └── Cancel → Close Dialog
```

---

## Screen Dependencies

### Data Dependencies

| Screen | Providers | Services | Models |
|--------|-----------|----------|--------|
| LoginScreen | authStatusProvider | AuthService | - |
| SignUpScreen | authStatusProvider | AuthService | - |
| ForgotPasswordScreen | - | AuthService | - |
| AuthGate | authStatusProvider | AuthService | - |
| HomeScreen | authStatusProvider | - | - |
| HomeTabView | - | - | - |
| PlayerViewScreen | currentUserProvider, teamsProvider | - | User, Team |
| TeamViewScreen | teamsProvider, selectedTeamProvider, playersProvider | ApiService | Team, Player |
| ProfileScreen | currentUserProvider | AuthService | User |
| RecruiterScreen | - | - | - |

### Navigation Dependencies

| Screen | Navigation Targets | Navigation Sources |
|--------|-------------------|-------------------|
| LoginScreen | HomeScreen, SignUpScreen, ForgotPasswordScreen | AuthGate |
| SignUpScreen | LoginScreen | LoginScreen |
| ForgotPasswordScreen | LoginScreen | LoginScreen |
| AuthGate | HomeScreen, LoginScreen | App Launch |
| HomeScreen | HomeTabView, RecruiterScreen, ProfileScreen | AuthGate |
| HomeTabView | PlayerViewScreen, TeamViewScreen | HomeScreen |
| PlayerViewScreen | TeamViewScreen | HomeTabView |
| TeamViewScreen | RecruiterScreen | HomeTabView |
| ProfileScreen | LoginScreen | HomeScreen |
| RecruiterScreen | - | HomeScreen |

---

## Screen Testing Patterns

### Widget Testing

```dart
testWidgets('LoginScreen should show error on invalid credentials', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(home: LoginScreen()),
    ),
  );
  
  await tester.enterText(find.byType(AppEmailField), 'test@example.com');
  await tester.enterText(find.byType(AppPasswordField), 'wrongpassword');
  await tester.tap(find.text('Sign In'));
  await tester.pump();
  
  expect(find.text('Invalid credentials'), findsOneWidget);
});
```

### Integration Testing

```dart
testWidgets('Complete team creation flow', (tester) async {
  // Navigate to team view
  await tester.tap(find.text('TEAM VIEW'));
  await tester.pumpAndSettle();
  
  // Create team
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
  
  await tester.enterText(find.byType(AppTextField).first, 'Test Team');
  await tester.tap(find.text('Create'));
  await tester.pumpAndSettle();
  
  // Verify team appears
  expect(find.text('Test Team'), findsOneWidget);
});
```

---

## Future Screen Additions

### Planned Screens

1. **GameRecordingScreen** - Record at-bats and game stats
2. **PlayerStatsScreen** - Detailed player statistics
3. **TeamStatsScreen** - Team performance analytics
4. **FreeAgentScreen** - Browse and recruit free agents
5. **SettingsScreen** - App configuration and preferences

### Screen Patterns for Future Features

- **Data Visualization Screens** - Charts and graphs for stats
- **Form Screens** - Complex multi-step forms
- **List Screens** - Paginated data lists with search/filter
- **Detail Screens** - Drill-down views for specific entities
- **Settings Screens** - Configuration and preferences

---

## Summary

HackTracker's screen architecture provides:

- **Clear Separation of Concerns** - Each screen has a single responsibility
- **Consistent Navigation Patterns** - Standardized navigation flow
- **Reusable Components** - Common widgets across screens
- **State Management Integration** - Riverpod providers for data
- **Error Handling** - Consistent error display patterns
- **Loading States** - Standardized loading indicators
- **Modal Dialog Integration** - Form and confirmation dialogs

The screen architecture supports **scalable development** and provides a **solid foundation** for future feature additions while maintaining **consistent user experience** across the application.
