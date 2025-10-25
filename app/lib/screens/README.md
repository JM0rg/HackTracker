# Screens

This directory contains all the main screen/page components for the HackTracker app.

## File Structure

### Main App Screens
- **`home_screen.dart`** - Main layout with top tabs (Player/Team) and bottom navigation
- **`player_view_screen.dart`** - Player stats view (personal stats across all teams)
- **`team_view_screen.dart`** - Team view with roster, stats, and games
- **`profile_screen.dart`** - User profile and settings

### Navigation
The app uses a two-tier navigation system:
1. **Top Tabs** (Player/Team) - Main content switching
2. **Bottom Nav** (Home/Record/Profile) - App-level navigation

### Widgets
Reusable components are in `/lib/widgets/`:
- **`app_drawer.dart`** - Collapsible sidebar with team management

