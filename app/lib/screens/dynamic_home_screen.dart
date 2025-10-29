import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../screens/player_view_screen.dart';
import '../screens/team_view_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/recruiter_screen.dart';
import '../widgets/app_drawer.dart';
import '../features/home/home_tab_view.dart';
import '../providers/user_context_provider.dart';

/// Dynamic home screen that adapts UI based on user's team context
/// 
/// Renders different layouts based on team ownership:
/// - Both PERSONAL and MANAGED teams: Show tabs (Player View + Team View)
/// - PERSONAL teams only: Show Player View only (no tabs)
/// - MANAGED teams only: Show Team View only (no tabs)
/// - No teams: Handled by AuthGate (shows Welcome Screen)
class DynamicHomeScreen extends ConsumerStatefulWidget {
  final UserContext userContext;

  const DynamicHomeScreen({
    super.key,
    required this.userContext,
  });

  @override
  ConsumerState<DynamicHomeScreen> createState() => _DynamicHomeScreenState();
}

class _DynamicHomeScreenState extends ConsumerState<DynamicHomeScreen> {
  int _bottomNavIndex = 0;

  void _navigateToRecruiter() {
    setState(() {
      _bottomNavIndex = 2; // Recruiter tab
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTap: (index) => setState(() => _bottomNavIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_baseball),
            label: 'Record',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Recruiter',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    if (_bottomNavIndex == 1) return 'Record At-Bat';
    if (_bottomNavIndex == 2) return 'Recruiter';
    if (_bottomNavIndex == 3) return 'Profile';
    
    // Home tab title depends on context
    if (widget.userContext.shouldShowPlayerViewOnly) {
      return 'My Stats';
    } else if (widget.userContext.shouldShowTeamViewOnly) {
      return 'My Team';
    } else {
      return 'HackTracker';
    }
  }

  Widget _buildBody() {
    switch (_bottomNavIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const Center(child: Text('RECORD AT-BAT (Coming Soon)'));
      case 2:
        return const RecruiterScreen();
      case 3:
        return const ProfileScreen();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    // Show tabs only if user has both PERSONAL and MANAGED teams
    if (widget.userContext.shouldShowTabs) {
      return HomeTabView(onNavigateToRecruiter: _navigateToRecruiter);
    }
    
    // Player View only (PERSONAL teams only)
    if (widget.userContext.shouldShowPlayerViewOnly) {
      return PlayerViewScreen(
        onNavigateToTeamView: () {
          // Can't navigate to team view if no managed teams
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Create a managed team to access Team View'),
            ),
          );
        },
      );
    }
    
    // Team View only (MANAGED teams only)
    if (widget.userContext.shouldShowTeamViewOnly) {
      return TeamViewScreen(onNavigateToRecruiter: _navigateToRecruiter);
    }
    
    // Fallback (should never reach here due to AuthGate)
    return const Center(
      child: Text('Loading...'),
    );
  }
}

