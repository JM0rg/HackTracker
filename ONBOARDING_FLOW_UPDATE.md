# Onboarding Flow Update

## Summary
Improved the first-time user experience by adding a dedicated team creation form for users who select "Manage a Full Team" on the welcome screen.

---

## Changes Made

### 1. **New Screen: `TeamCreationScreen`** (`app/lib/screens/team_creation_screen.dart`)

A full-page form for creating a MANAGED team during onboarding.

**Features:**
- ✅ Clean, focused UI with no distractions (no bottom nav or drawer)
- ✅ Back button in top-left to return to welcome screen
- ✅ Form validation matching backend requirements
- ✅ Required field: Team Name (2-100 characters)
- ✅ Optional field: Team Description (max 500 characters)
- ✅ Loading state during submission
- ✅ Auto-clears hall pass and refreshes context after team creation
- ✅ Returns to welcome screen after creation (which then routes to DynamicHomeScreen)

**Backend Validation:**
- Team name: Required, 2-100 characters (validated by `validate_team_name`)
- Team description: Optional, max 500 characters (validated by `validate_team_description`)
- Team type: Automatically set to `MANAGED`

---

### 2. **Updated: `WelcomeScreen`** (`app/lib/screens/welcome_screen.dart`)

**Changes:**
- Now navigates to `TeamCreationScreen` when user confirms "Manage a Full Team"
- Sets hall pass before navigation (for consistency, though not strictly needed now)
- Refreshes user context after returning from team creation screen
- Maintains selection state + confirmation button flow

**New Flow:**
1. User selects "Manage a Full Team"
2. User clicks CONFIRM
3. App navigates to `TeamCreationScreen`
4. User creates team OR goes back
5. Returns to welcome screen
6. Context refreshes, AuthGate routes to appropriate screen

---

### 3. **Simplified: `DynamicHomeScreen`** (`app/lib/screens/dynamic_home_screen.dart`)

**Removed:**
- Hall pass check in `_buildHomeTab()` (no longer needed)
- Now only shows when user has at least one team

**Keeps:**
- Bottom navigation bar (only visible when user has teams)
- Hamburger menu/drawer (only visible when user has teams)

---

### 4. **Simplified: `AuthGate`** (`app/lib/features/auth/widgets/auth_gate.dart`)

**Removed:**
- Hall pass check in routing logic
- Simplified back to original clean logic:
  - No teams → WelcomeScreen
  - Has teams → DynamicHomeScreen

---

## User Flow Comparison

### ❌ Old Flow (Confusing)
1. Welcome screen
2. Click "Manage a Full Team" → Loading spinner
3. Briefly shows DynamicHomeScreen with empty state
4. User has to find and click "Create Team" button
5. Modal dialog appears

### ✅ New Flow (Clear)
1. Welcome screen
2. Select "Manage a Full Team" → Click CONFIRM
3. **Dedicated full-page team creation form**
4. Fill out form and submit
5. Returns to app with team created

---

## Navigation Restrictions

**Before First Team:**
- ❌ No bottom navigation bar
- ❌ No hamburger menu
- ❌ Can't access other app features
- ✅ Only WelcomeScreen and TeamCreationScreen accessible

**After First Team:**
- ✅ Full app access
- ✅ Bottom navigation visible
- ✅ Hamburger menu visible
- ✅ All features unlocked

---

## Testing Checklist

- [ ] User with no teams sees WelcomeScreen
- [ ] Selecting "Track My Personal Stats" creates Default team and routes to Player View
- [ ] Selecting "Manage a Full Team" shows TeamCreationScreen
- [ ] Back button on TeamCreationScreen returns to WelcomeScreen
- [ ] Team creation form validates required fields
- [ ] Submitting valid team creates it and routes to Team View
- [ ] No bottom nav/drawer visible until team is created
- [ ] After team creation, full app is accessible

---

## Technical Notes

### Hall Pass Provider (`creatingFirstTeamProvider`)
- Still exists but is no longer used in routing logic
- Set to `true` when navigating to TeamCreationScreen
- Cleared automatically when team is created
- Cleared manually when user presses back button
- Could be removed in future cleanup if deemed unnecessary

### Backend Alignment
The form fields exactly match the Lambda requirements:
- `name`: Required (validated by `validate_team_name`)
- `teamType`: Set to 'MANAGED' automatically
- `description`: Optional (validated by `validate_team_description`)

---

## Future Enhancements

1. Add team logo/image upload
2. Add team color picker
3. Add "Skip for now" option to create team later
4. Add animated transitions between screens
5. Add progress indicator for multi-step onboarding

