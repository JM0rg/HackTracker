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

### LoginScreen (Unified Authentication)

**File:** `lib/features/auth/screens/login_screen.dart`

**Purpose:** Unified authentication screen handling login, signup, and forgot password with iOS liquid glass aesthetic

**Design Theme:**
- **Glassmorphism** - Frosted glass effect with backdrop blur
- **Single Screen** - All auth forms on one page with animated transitions
- **No Scrolling** - Forms fit on one screen without keyboard overflow

**Widget Tree Structure:**
```
LoginScreen
├── Scaffold
│   └── Container (GlassTheme.backgroundGradient)
│       └── SafeArea
│           └── Padding
│               ├── AuthTitleHeader (always visible)
│               └── Expanded
│                   └── FadeTransition (form animation)
│                       └── SingleChildScrollView
│                           └── GlassContainer
│                               └── Switch (_formMode)
│                                   ├── AuthFormMode.login
│                                   │   ├── StatusIndicator ("LOG IN")
│                                   │   ├── AuthGlassField (Email)
│                                   │   ├── AuthGlassField (Password)
│                                   │   ├── TextButton ("FORGOT PASSWORD?")
│                                   │   ├── AuthErrorMessage (conditional)
│                                   │   ├── GlassButton ("LOG IN")
│                                   │   ├── AuthDivider ("OR")
│                                   │   └── AuthFormLink ("CREATE ACCOUNT")
│                                   ├── AuthFormMode.signup
│                                   │   ├── StatusIndicator ("SIGN UP")
│                                   │   ├── AuthGlassField (First Name)
│                                   │   ├── AuthGlassField (Last Name)
│                                   │   ├── AuthGlassField (Email)
│                                   │   ├── AuthGlassField (Password)
│                                   │   ├── AuthGlassField (Confirm Password)
│                                   │   ├── Text ("Minimum 8 characters")
│                                   │   ├── AuthErrorMessage (conditional)
│                                   │   ├── GlassButton ("SIGN UP")
│                                   │   ├── AuthDivider ("OR")
│                                   │   └── AuthFormLink ("SIGN IN")
│                                   └── AuthFormMode.forgotPassword
│                                       ├── StatusIndicator ("RESET PASSWORD")
│                                       ├── if (!_codeSent)
│                                       │   ├── AuthGlassField (Email)
│                                       │   └── AuthInfoBox (instructions)
│                                       ├── else
│                                       │   ├── AuthGlassField (Reset Code)
│                                       │   ├── AuthGlassField (New Password)
│                                       │   ├── AuthGlassField (Confirm Password)
│                                       │   └── AuthInfoBox ("Check your email")
│                                       ├── AuthErrorMessage (conditional)
│                                       ├── GlassButton ("SEND CODE" / "RESET PASSWORD")
│                                       ├── AuthDivider ("OR")
│                                       └── AuthFormLink ("GO BACK")
```

**Props and Callbacks:**
- No external props
- Internal callbacks:
  - `_handleSignIn()` - Authenticate user with Cognito
  - `_handleSignUp()` - Register new user
  - `_sendResetCode()` - Send password reset code
  - `_confirmReset()` - Confirm password reset with code
  - `_switchFormMode()` - Animate between forms

**State Management:**
- `_formMode` - `AuthFormMode` enum (`login`, `signup`, `forgotPassword`)
- `_isLoading` - Loading state for async operations
- `_codeSent` - Track forgot password flow state
- `_errorMessage` - Error message display (null when no error)
- `_animationController` - Controls fade transition animation

**Form Controllers:**
- Login: `_emailController`, `_passwordController`
- Signup: `_firstNameController`, `_lastNameController`, `_signupEmailController`, `_signupPasswordController`, `_confirmPasswordController`
- Forgot Password: `_forgotPasswordEmailController`, `_codeController`, `_newPasswordController`, `_confirmNewPasswordController`

**State Dependencies:**
- `Amplify.Auth.signIn()` - Cognito authentication
- `Amplify.Auth.signUp()` - Cognito registration
- `Amplify.Auth.resetPassword()` - Send reset code
- `Amplify.Auth.confirmResetPassword()` - Confirm password reset

**Navigation Patterns:**
- Success (Login) → `HomeScreen` (via `AuthGate`)
- Success (Signup) → Success dialog → Stay on screen
- Success (Forgot Password) → Success dialog → Return to login form
- Form Switch → Animated fade transition (no page navigation)
- Error → Stay on screen with error message

**Key Features:**
1. **Unified Screen** - All authentication flows on one page
2. **Animated Transitions** - `FadeTransition` for smooth form switching
3. **Keyboard Handling** - Forms scroll naturally when keyboard appears
4. **Glassmorphism Design** - Frosted glass containers and buttons
5. **Consistent Sizing** - All form containers have same height
6. **No Navigation Stack** - Forms switch in-place (better UX)

**Code Example:**
```dart
enum AuthFormMode { login, signup, forgotPassword }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  AuthFormMode _formMode = AuthFormMode.login;
  bool _isLoading = false;
  bool _codeSent = false;
  String? _errorMessage;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  void _switchFormMode(AuthFormMode mode) {
    if (_formMode == mode) return;

    setState(() {
      _formMode = mode;
      _errorMessage = null;
      if (mode != AuthFormMode.forgotPassword) {
        _codeSent = false;
      }
      _animationController.reset();
      _animationController.forward();
    });
  }

  Future<void> _handleSignIn() async {
    if (_emailController.text.trim().isEmpty || 
        _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter email and password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Amplify.Auth.signIn(
        username: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthGate()),
        );
      }
    } on AuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: GlassTheme.backgroundGradient,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const AuthTitleHeader(),
                const SizedBox(height: 24),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      child: GlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: _formMode == AuthFormMode.login
                            ? _buildLoginForm()
                            : _formMode == AuthFormMode.signup
                                ? _buildSignupForm()
                                : _buildForgotPasswordForm(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

### Removed Screens

The following screens were consolidated into `LoginScreen`:

- **SignUpScreen** - Functionality merged into `LoginScreen` with `AuthFormMode.signup`
- **ForgotPasswordScreen** - Functionality merged into `LoginScreen` with `AuthFormMode.forgotPassword`

Both screens have been deleted and are no longer in the codebase.

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

**Purpose:** Team management, roster operations, game scheduling, and statistics

**Widget Tree Structure:**
```
TeamViewScreen
├── Scaffold
│   ├── AppBar
│   │   ├── IconButton (drawer)
│   │   ├── Text (team name)
│   │   └── TabBar
│   │       ├── Tab ("Stats")
│   │       ├── Tab ("Schedule")
│   │       ├── Tab ("Roster")
│   │       └── Tab ("Chat")
│   └── Body
│       └── TabBarView
│           ├── _StatsTab
│           │   ├── SegmentedButton (My Stats / Team Stats)
│           │   └── StatefulWidget
│           │       ├── _MyStatsView → Placeholder cards
│           │       └── _TeamStatsView → Placeholder cards
│           ├── _ScheduleTab
│           │   ├── SegmentedButton (List / Calendar)
│           │   └── StatefulWidget
│           │       ├── _GameListView → Grouped games list
│           │       └── _GameCalendarView → Placeholder
│           ├── _RosterTab
│           │   ├── Legend (Has Account / No Account)
│           │   ├── Button (Add Player) [owner only]
│           │   └── ListView (_RosterPlayerCard)
│           └── _ChatTab → Placeholder
```

**Props and Callbacks:**
- `team` - Current team being viewed (passed to screen)

**State Dependencies:**
- `teamsProvider` - Team data with optimistic updates
- `rosterProvider` - Team roster data with roles
- `gamesProvider` - Team games data
- Tab-specific state for view toggles

**Tab Features:**

**Stats Tab:**
- SegmentedButton toggle: "MY STATS" / "TEAM STATS"
- My Stats view: Personal batting average, performance trend, achievements (placeholder)
- Team Stats view: Team batting average, top performers, recent games summary (placeholder)

**Schedule Tab:**
- SegmentedButton toggle: "LIST" / "CALENDAR"
- List view: Games grouped by "This Week", "Next Week", "Later"
- Calendar view: Coming soon (placeholder)
- Floating action button for adding games (owner only)

**Roster Tab:**
- Color-coded legend for linked vs ghost players
- Player cards with number, name, positions, and role
- Edit/remove actions for owners
- Add player button (owner only)

**Chat Tab:**
- Placeholder for future team communication

**Navigation Patterns:**
- View Team → `TeamViewScreen`
- Add Player → `PlayerFormDialog` (bottom sheet)
- Edit Player → `PlayerFormDialog` (bottom sheet)
- Remove Player → `ConfirmDialog`
- Add Game → `GameFormDialog` (bottom sheet)
- Edit Game → `GameFormDialog` (bottom sheet)

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
| ScoringScreen | gamesProvider, rosterProvider, atBatsProvider | ApiService | Game, Player, AtBat |
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
| ScoringScreen | TeamViewScreen (game schedule) | GameCard (Start Game button) |
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

### ScoringScreen

**File:** `lib/features/scoring/screens/scoring_screen.dart`

**Purpose:** Fast at-bat entry with interactive field diagram for hit location selection

**Widget Tree Structure:**
```
ScoringScreen
├── Scaffold
│   ├── AppBar (game info, back button)
│   └── Body
│       └── Consumer (game data)
│           └── Column
│               ├── _buildGameStateHeader
│               │   ├── Row (Inning / Outs)
│               │   └── Row (Up to Bat: Player Name #Number)
│               ├── Container (Spray Chart title + instructions)
│               ├── Expanded
│               │   └── AspectRatio (FieldDiagram)
│               │       ├── Container (background)
│               │       └── Stack
│               │           ├── SvgPicture (softball field)
│               │           └── CustomPaint (hit location arc)
│               └── ActionArea
│                   ├── Row (initial buttons: K, BB, FO)
│                   ├── Row (outcome buttons: 1B, 2B, 3B, HR, OUT, E)
│                   └── ElevatedButton (Submit At-Bat)
```

**Props:**
- `gameId` - Game UUID (required)
- `teamId` - Team UUID (required)

**State Management:**
- `_step` - EntryStep enum (`initial`, `outcome`)
- `_hitLocation` - Map<String, double>? (normalized 0.0-1.0 coordinates)
- `_hitType` - String? (optional hit type)
- `_selectedResult` - String? (selected at-bat result)
- `_currentInning` - int (current inning)
- `_currentOuts` - int (current outs, 0-2)
- `_currentBatterIndex` - int (position in lineup)

**Hit Location Coordinate System:**
- Coordinates captured as normalized 0.0-1.0 values (percentage-based)
- Tap position divided by field size: `normalizedX = tapX / fieldWidth`
- Stored in DynamoDB as Decimal types (not float)
- Scales proportionally when rendering on any device size
- See [FieldDiagram Widget](#fielddiagram) for detailed coordinate system

**User Flows:**
1. **Quick Entry (1 tap)**: Tap K, BB, or FO → Submit (no field interaction)
2. **Hit with Location (2 taps)**: Tap field → Select outcome (1B, 2B, etc.) → Submit
3. **Advanced Entry (3+ taps)**: Tap field → Optional hit type/hit details → Select outcome → Submit

**Navigation Patterns:**
- Back → Previous screen (game schedule)
- Submit → Auto-advance to next batter in lineup
- Long press field → Clear hit location and reset to initial state

**Code Example:**
```dart
class ScoringScreen extends ConsumerStatefulWidget {
  final String gameId;
  final String teamId;

  const ScoringScreen({
    super.key,
    required this.gameId,
    required this.teamId,
  });

  @override
  ConsumerState<ScoringScreen> createState() => _ScoringScreenState();
}

class _ScoringScreenState extends ConsumerState<ScoringScreen> {
  EntryStep _step = EntryStep.initial;
  Map<String, double>? _hitLocation;
  String? _selectedResult;
  int _currentInning = 1;
  int _currentOuts = 0;

  void _handleFieldTap(double x, double y) {
    setState(() {
      _hitLocation = {'x': x, 'y': y};
      _step = EntryStep.outcome;
    });
  }

  Future<void> _saveAtBat(String result, Map<String, dynamic> batter) async {
    await ref.read(atBatActionsProvider(widget.gameId)).recordAtBat(
      playerId: batter['playerId'],
      result: result,
      inning: _currentInning,
      outs: _currentOuts,
      battingOrder: batter['battingOrder'],
      hitLocation: _hitLocation,
    );
    _advanceToNextBatter(result);
    _resetState();
  }
}
```

---

## Future Screen Additions

### Planned Screens

1. **PlayerStatsScreen** - Detailed player statistics
2. **TeamStatsScreen** - Team performance analytics
3. **FreeAgentScreen** - Browse and recruit free agents
4. **SettingsScreen** - App configuration and preferences

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
