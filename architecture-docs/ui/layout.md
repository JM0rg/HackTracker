# UI Layout Documentation

**Part of:** [ARCHITECTURE.md](../ARCHITECTURE.md) - Complete system architecture guide

This document provides a comprehensive visual guide to all UI layouts, screens, views, buttons, and interactive elements in the HackTracker Flutter application.

---

## Table of Contents

1. [App Structure Overview](#app-structure-overview)
2. [Navigation Architecture](#navigation-architecture)
3. [Screen Layouts](#screen-layouts)
4. [Component Hierarchy](#component-hierarchy)
5. [Interactive Elements](#interactive-elements)
6. [Visual Patterns](#visual-patterns)

---

## App Structure Overview

### Main Application Container

The app uses a **single Scaffold** structure (`DynamicHomeScreen`) that persists across all navigation:

```
DynamicHomeScreen (Scaffold)
├── AppBar (Top Bar)
│   ├── Menu Icon (Hamburger - opens drawer)
│   └── Title (Dynamic based on tab/context)
├── AppDrawer (Side Navigation)
├── Body (Tab Content - switches based on bottom nav)
│   └── [Tab Content - see below]
└── BottomNavigationBar (Always Visible)
    ├── Home Icon + Label
    ├── Recruiter Icon + Label
    └── Profile Icon + Label
```

**Key Points:**
- **Bottom Navigation Bar**: Always visible on all screens (except auth screens)
- **AppBar**: Always visible with dynamic title
- **Drawer**: Accessible via hamburger menu icon
- **Body Content**: Changes based on selected bottom nav tab

---

## Navigation Architecture

### Bottom Navigation Bar

**Location:** Fixed at bottom of screen  
**Visibility:** Always visible (except on auth screens)  
**Tabs (Left to Right):**

1. **Home** (Icon: `Icons.home`)
   - Label: "Home"
   - Shows: HomeTabView, PlayerViewScreen, or TeamViewScreen (context-dependent)

2. **Recruiter** (Icon: `Icons.people`)
   - Label: "Recruiter"
   - Shows: RecruiterScreen

3. **Profile** (Icon: `Icons.person`)
   - Label: "Profile"
   - Shows: ProfileScreen

**AppBar Title Changes:**
- Home Tab: "HackTracker", "My Stats", or Team Name (context-dependent)
- Recruiter Tab: "Recruiter"
- Profile Tab: "Profile"

**Note:** The Record/Scoring functionality is now accessed via a full-screen modal from the Schedule tab (Start Game/Score buttons), not as a bottom navigation tab.

### Side Drawer (AppDrawer)

**Access:** Tap hamburger menu icon (top-left)  
**Contains:**
- Team selection dropdown (if multiple teams)
- Settings/Options (if implemented)
- Sign out button

---

## Screen Layouts

### 1. DynamicHomeScreen (Main Container)

**File:** `lib/screens/dynamic_home_screen.dart`

**Layout Structure:**
```
Scaffold
├── AppBar
│   ├── Leading: IconButton (menu icon)
│   └── Title: Dynamic text
├── Drawer: AppDrawer
├── Body
│   └── [Content based on _bottomNavIndex]
│       ├── 0: Home Tab Content
│       ├── 1: RecruiterScreen
│       └── 2: ProfileScreen
└── BottomNavigationBar
    └── 3 BottomNavigationBarItems
```

---

### 2. Home Tab Content

The Home tab content is **context-dependent**:

#### A. HomeTabView (When user has both PERSONAL and MANAGED teams)

**File:** `lib/features/home/home_tab_view.dart`

**Layout:**
```
Column
├── SegmentedButton (Toggle)
│   ├── "PLAYER VIEW" button
│   └── "TEAM VIEW" button
└── TabBarView
    ├── Tab 0: PlayerViewScreen
    └── Tab 1: TeamViewScreen
```

#### B. PlayerViewScreen (PERSONAL teams only)

**File:** `lib/screens/player_view_screen.dart`

**Layout:**
```
SingleChildScrollView
├── Header Section
│   ├── "MY STATS" title
│   └── Year filter dropdown (e.g., "2024")
├── Quick Stats Card (Grid)
│   ├── Stat 1 (AVG)
│   ├── Stat 2 (HR)
│   ├── Stat 3 (RBI)
│   └── Stat 4 (SB)
├── Season Stats Section
│   ├── Section Header
│   └── Expanded stats cards
├── Recent Games Section
│   ├── Section Header
│   └── Game cards list
└── Teams Section
    └── Team membership cards
```

**Buttons/Actions:**
- Year filter dropdown (top-right)
- Game cards (tappable to view details)

#### C. TeamViewScreen (MANAGED teams only)

**File:** `lib/features/team/screens/team_view_screen.dart`

**Layout:**
```
Column
├── TabBar (Horizontal tabs)
│   ├── "STATS" tab
│   ├── "SCHEDULE" tab
│   ├── "ROSTER" tab
│   └── "CHAT" tab
└── TabBarView
    ├── StatsTab
    ├── ScheduleTab
    ├── RosterTab
    └── ChatTab
```

**Tabs Content:**

##### StatsTab Layout:
```
Column
├── Toggle Button Section
│   ├── "MY STATS" button (liquid glass style)
│   └── "TEAM STATS" button (liquid glass style)
└── Stats Display
    ├── [If MY STATS]
    │   └── Player stats cards
    └── [If TEAM STATS]
        └── Team stats cards
```

##### ScheduleTab Layout:
```
Column
├── Calendar View (top)
│   └── Calendar widget showing games
└── Game List View (bottom)
    └── GameCard widgets
        ├── Opponent name
        ├── Date/time
        ├── Location
        ├── Status badge
        └── Action buttons
            ├── "View Game" button
            └── "Start Game" button (if applicable)
```

##### RosterTab Layout:
```
Column
├── Add Player Button (top)
│   └── FloatingActionButton or OutlinedButton
└── Player List
    └── RosterPlayerCard widgets
        ├── Player number
        ├── Player name
        ├── Positions
        └── Edit/Remove buttons
```

##### ChatTab Layout:
```
Column
└── Chat interface
    └── [Chat messages and input]
```

---

### 3. Scoring Flow (Full-Screen Modal)

**Note:** Scoring is no longer a bottom navigation tab. It is launched as a full-screen modal from the Schedule tab when users tap "Start Game" or "Score" buttons on a game card.

**File:** `lib/features/scoring/screens/scoring_flow_screen.dart`

**Launch Context:**
- Launched from Schedule tab in TeamViewScreen
- Opened when user taps "Start Game" button (SCHEDULED games)
- Opened when user taps "Score" button (IN_PROGRESS games)
- Uses slide-up transition animation
- Full-screen modal (hides bottom navigation)

---

### 4. Scoring Flow Screen (Modal)

**File:** `lib/features/scoring/screens/scoring_flow_screen.dart`

**Layout:**
```
Scaffold
├── AppBar
│   ├── Leading: Close (X) button → Navigator.pop()
│   ├── Title: "Inning {n} • {n} Outs" (dynamic from game state)
│   └── Actions
│       ├── List icon (Icons.list) → Navigator.push(AtBatsListScreen)
│       └── "Finish Game" button (only if IN_PROGRESS)
└── SafeArea
    └── Column
        ├── "Up to Bat" Header (fixed at top)
        │   └── Row (Up to Bat: Player Name #Number)
        └── Expanded
            └── ScoringScreen
```

**Modal Behavior:**
- **Launch**: Full-screen modal with slide-up transition from Schedule tab
- **Exit**: Close (X) button in AppBar dismisses modal
- **Finish Game**: "Finish Game" button in AppBar (visible only for IN_PROGRESS games)
  - Updates game status to FINAL
  - Closes modal and returns to Schedule tab

**Navigation:**
- **List Icon**: Tap list icon in AppBar to push AtBatsListScreen onto navigation stack
- **Back Button**: AtBatsListScreen has standard AppBar with back arrow (Navigator.pop())
- **Explicit Navigation**: No hidden swipe gestures - all navigation is explicit via buttons

---

### 5. Scoring Screen

**File:** `lib/features/scoring/screens/scoring_screen.dart`

**Layout:**
```
Column
├── Spray Chart Section (top)
│   ├── "Spray Chart" title
│   ├── "Select hit location. Hold to clear." subtitle
│   └── Field Diagram (AspectRatio 0.9 - taller than wide)
│       └── Interactive field with tap/long-press gestures
└── Action Area (fixed height: 220px)
    └── ActionArea widget (see below)
```

**ActionArea - Initial State:**
```
Column
├── Row (3 circular buttons)
│   ├── K button (48x48, "Strikeout" subtitle)
│   ├── BB button (48x48, "Walk" subtitle)
│   └── FO button (48x48, "Flyout" subtitle)
├── SizedBox (16px spacing)
└── Row (Submit button row - centered)
    └── "Submit At-Bat" button (OutlinedButton)
```

**ActionArea - Outcome State (after field tap):**
```
Column
├── Row (6 circular buttons)
│   ├── 1B button (48x48)
│   ├── 2B button (48x48)
│   ├── 3B button (48x48)
│   ├── HR button (48x48)
│   ├── OUT button (48x48)
│   └── E button (48x48)
├── Scrollable Row (detail chips)
│   ├── "Grounder" chip
│   ├── "Fly Ball" chip
│   └── "Line Drive" chip
├── SizedBox (12px spacing)
└── Row (Submit button row - centered)
    └── "Submit At-Bat" button (OutlinedButton)
```

**Buttons:**
- **K, BB, FO buttons**: 48x48 circular, with subtitles below
- **1B, 2B, 3B, HR, OUT, E buttons**: 48x48 circular, no subtitles
- **Detail chips**: Horizontal scrollable, toggleable
- **Submit At-Bat button**: OutlinedButton, green when valid, grey when disabled

**Interactions:**
- **Field Diagram**: Tap to set hit location, long-press to clear
- **Circular buttons**: Select result (K, BB, FO, or 1B-3B, HR, OUT, E)
- **Detail chips**: Optional additional details (Grounder, Fly Ball, Line Drive)
- **Submit button**: Submit at-bat (only enabled when result selected)
- **List Icon (AppBar)**: Tap to navigate to at-bats list view

---

### 6. At-Bats List Screen

**File:** `lib/features/scoring/screens/atbats_list_screen.dart`

**Layout:**
```
Scaffold (if not embedded) OR Column (if embedded)
└── ListView (or SingleChildScrollView)
    └── ExpansionTile widgets (grouped by inning)
        ├── ExpansionTile Header
        │   └── "1st Inning", "2nd Inning", etc.
        └── ExpansionTile Content
            └── List of AtBat items
                └── ListTile
                    ├── Leading: Batting order number
                    ├── Title: Player first name
                    ├── Subtitle: Result (e.g., "Hit, 3B, 1RBI" or "K")
                    └── Trailing: "Edit" button (IconButton)
```

**List Item Format:**
- **Format**: `{battingOrder}. {firstName} - {result}`
- **Examples:**
  - `2. Jacob - Hit, 3B, 1RBI`
  - `3. John - Out`
  - `4. Mike - K`

**Buttons:**
- **Edit button**: IconButton with edit icon, navigates to ScoringScreen in edit mode

**Interactions:**
- **ExpansionTile**: Tap header to expand/collapse inning
- **Edit button**: Navigate to ScoringScreen with at-bat ID for editing

---

### 7. Recruiter Screen

**File:** `lib/screens/recruiter_screen.dart`

**Layout:**
```
[Screen content - structure to be documented]
```

---

### 8. Profile Screen

**File:** `lib/screens/profile_screen.dart`

**Layout:**
```
[Screen content - structure to be documented]
```

---

## Component Hierarchy

### Button Types and Styles

#### 1. Circular Action Buttons

**Used in:** ScoringScreen ActionArea

**Size:** 48x48 pixels  
**Shape:** Circle  
**Colors:**
- Selected: `AppColors.accent` (green)
- Unselected: `Colors.grey.shade600`

**Variants:**
- **With Subtitle**: K, BB, FO buttons
  - Button: 48x48 circle
  - Subtitle text below (e.g., "Strikeout")
- **Without Subtitle**: 1B, 2B, 3B, HR, OUT, E buttons
  - Button: 48x48 circle only

#### 2. OutlinedButton (Submit At-Bat)

**Style:**
- Border: 2px solid
- Enabled: Green border + green background, white text
- Disabled: Grey border, transparent background, grey text
- Padding: 32px horizontal, 12px vertical
- Border radius: 8px

#### 3. List Icon Button (AppBar Action)

**Location:** AppBar actions (ScoringFlowScreen)  
**Style:**
- Icon: `Icons.list`
- Tooltip: "View At-Bats"
- Color: `AppColors.textPrimary`

#### 4. Liquid Glass Toggle Buttons

**Used in:** StatsTab (MY STATS / TEAM STATS)

**Style:**
- Frosted glass effect with backdrop blur
- Beveled edges with curved corners
- Selected: Primary color highlight
- Unselected: Transparent/tertiary

---

## Interactive Elements

### Navigation Patterns

#### Scoring Flow Screen

**List View Navigation:**
- **List Icon (AppBar)**: Tap list icon to push AtBatsListScreen onto navigation stack
- **Back Button**: Standard Material back arrow on AtBatsListScreen returns to ScoringScreen
- **No Hidden Gestures**: All navigation is explicit via buttons

### Tap Gestures

#### Field Diagram (Spray Chart)

**Single Tap:** Set hit location (coordinates stored)  
**Long Press:** Clear hit location

**Implementation:** `GestureDetector` with `onTap` and `onLongPress`

### Button States

#### Submit At-Bat Button

**States:**
- **Disabled**: No result selected (`selectedResult == null`)
  - Grey border, transparent background, grey text
  - Not tappable
- **Enabled**: Result selected (`selectedResult != null`)
  - Green border, green background, white text
  - Tappable, triggers `onSubmit` callback

---

## Visual Patterns

### Color Scheme

**Primary Colors:**
- **Accent/Green**: `AppColors.accent` - Used for selected buttons, active states
- **Primary**: `AppColors.primary` - Used for tabs, highlights
- **Background**: `AppColors.background` - Main app background
- **Card Background**: `AppColors.cardBackground` - Card/container backgrounds
- **Surface**: `AppColors.surface` - Tab bar background

**Text Colors:**
- **Primary Text**: `AppColors.textPrimary`
- **Secondary Text**: `AppColors.textSecondary`
- **Tertiary Text**: `AppColors.textTertiary`

### Spacing

**Common Spacing Values:**
- Small: 8px
- Medium: 16px
- Large: 24px
- Action Area Padding: 16px horizontal, 16px bottom
- Submit button: Centered in ActionArea

### Typography

**Font Sizes:**
- Headline Medium: Used for Inning/Outs display
- Headline Small: Used for player name
- Title Medium: Used for section headers
- Body Small: Used for subtitles, labels

**Font Weights:**
- W600: Section headers, selected states
- W700: Player names, important numbers
- W400: Body text, unselected states

---

## Layout Flow Diagrams

### Main App Navigation Flow

```
DynamicHomeScreen
│
├── Bottom Nav: Home (index 0)
│   └── HomeTabView OR PlayerViewScreen OR TeamViewScreen
│       │
│       └── [If TeamViewScreen]
│           └── TabBar
│               ├── STATS tab
│               ├── SCHEDULE tab
│               ├── ROSTER tab
│               └── CHAT tab
│
├── Bottom Nav: Recruiter (index 1)
│   └── RecruiterScreen
│
└── Bottom Nav: Profile (index 2)
    └── ProfileScreen

[Modal Flow - from Schedule tab]
Schedule Tab → Game Card → "Start Game" / "Score" button
    ↓
ScoringFlowScreen (full-screen modal)
    ├── AppBar
    │   ├── Title: "Inning {n} • {n} Outs"
    │   ├── List icon → Navigator.push(AtBatsListScreen)
    │   └── "Finish Game" button (if IN_PROGRESS)
    ├── "Up to Bat" Header
    └── ScoringScreen
```

### Scoring Flow Navigation

```
ScoringFlowScreen
│
├── AppBar
│   ├── Close (X) button
│   ├── Title: "Inning {n} • {n} Outs" (from game state)
│   └── Actions
│       ├── List icon (Icons.list) → Push AtBatsListScreen
│       └── "Finish Game" button (if IN_PROGRESS)
│
├── "Up to Bat" Header (Always Visible)
│   └── "Up to Bat: Player Name #Number"
│
└── ScoringScreen
    ├── Spray Chart Section
    │   ├── "Spray Chart" title
    │   ├── Instructions text
    │   └── Field Diagram (interactive)
    │
    └── ActionArea
        ├── [Initial State]
        │   ├── K, BB, FO buttons (48x48)
        │   └── "Submit At-Bat" button (centered)
        │
        └── [Outcome State]
            ├── 1B, 2B, 3B, HR, OUT, E buttons (48x48)
            ├── Detail chips (scrollable)
            └── "Submit At-Bat" button (centered)
```

---

## Responsive Considerations

### Safe Areas

**Usage:** `SafeArea` widget wraps content to avoid system intrusions:
- iPhone notch/status bar (top)
- Home indicator (bottom)

**Applied in:**
- ScoringFlowScreen (wraps entire content)
- Auth screens

### Fixed Heights

**ActionArea:** Fixed height of 220px to ensure consistent layout

**Field Diagram:** Uses `AspectRatio` (0.9) for responsive sizing within available space

---

## Summary

This document provides a comprehensive overview of the HackTracker UI layout. Key takeaways:

1. **Single Scaffold Structure**: The app uses one persistent Scaffold with bottom navigation (3 tabs: Home, Recruiter, Profile)
2. **Context-Aware Layouts**: Home tab content changes based on user's team context
3. **Modal Scoring Flow**: Scoring is accessed via full-screen modal from Schedule tab, not as a bottom nav tab
4. **Explicit Navigation**: ScoringFlowScreen uses AppBar list icon to push AtBatsListScreen; no hidden swipe gestures
5. **Consistent Button Sizes**: All circular buttons are 48x48 pixels
6. **Fixed Action Area**: ScoringScreen's ActionArea has fixed height for consistency
7. **Always-Visible Bottom Nav**: Bottom navigation bar remains visible on all screens (except auth and scoring modal)

For more details on specific components, see:
- [screens.md](./screens.md) - Detailed screen documentation
- [widgets.md](./widgets.md) - Widget component details
- [styling.md](./styling.md) - Styling guidelines and themes
