import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/app_drawer.dart';
import '../theme/app_colors.dart';
import '../theme/custom_text_styles.dart';
import 'profile_screen.dart';
import 'recruiter_screen.dart';
import '../features/home/home_tab_view.dart';

/// Main home screen with bottom navigation
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _bottomNavIndex = 0;

  void _navigateToRecruiter() {
    setState(() {
      _bottomNavIndex = 2; // Recruiter tab index
    });
  }

  Widget _buildCurrentScreen() {
    switch (_bottomNavIndex) {
      case 0: // Home - shows the tab view
        return HomeTabView(onNavigateToRecruiter: _navigateToRecruiter);
      case 1: // Record (placeholder for now)
        return const Center(
          child: Text(
            'RECORD AT-BAT',
            style: TextStyle(fontSize: 24, color: AppColors.primary),
          ),
        );
      case 2: // Recruiter
        return const RecruiterScreen();
      case 3: // Profile
        return const ProfileScreen();
      default:
        return HomeTabView(onNavigateToRecruiter: _navigateToRecruiter);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.primary),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: Text(
          'HACKTRACKER',
          style: Theme.of(context).extension<CustomTextStyles>()!.appBarTitle,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.primary),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _buildCurrentScreen(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _bottomNavIndex,
          onTap: (index) {
            setState(() {
              _bottomNavIndex = index;
            });
          },
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textTertiary,
          selectedLabelStyle: Theme.of(context).textTheme.labelSmall,
          unselectedLabelStyle: Theme.of(context).textTheme.labelSmall,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'HOME',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sports_baseball_outlined),
              activeIcon: Icon(Icons.sports_baseball),
              label: 'RECORD',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_search_outlined),
              activeIcon: Icon(Icons.person_search),
              label: 'RECRUITER',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'PROFILE',
            ),
          ],
        ),
      ),
    );
  }
}

