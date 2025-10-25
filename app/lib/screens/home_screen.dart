import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_drawer.dart';
import '../theme/app_colors.dart';
import 'player_view_screen.dart';
import 'team_view_screen.dart';
import 'profile_screen.dart';

/// Main home screen with top tabs (Player/Team) and bottom navigation
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _topTabController;
  int _bottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _topTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _topTabController.dispose();
    super.dispose();
  }

  Widget _buildCurrentScreen() {
    switch (_bottomNavIndex) {
      case 0: // Home - shows the tab view
        return _buildTabView();
      case 1: // Record (placeholder for now)
        return const Center(
          child: Text(
            'RECORD AT-BAT',
            style: TextStyle(fontSize: 24, color: AppColors.primary),
          ),
        );
      case 2: // Profile
        return const ProfileScreen();
      default:
        return _buildTabView();
    }
  }

  Widget _buildTabView() {
    return Column(
      children: [
        // Segmented Button Toggle (Player / Team)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _ToggleButton(
                  label: 'PLAYER',
                  isSelected: _topTabController.index == 0,
                  onTap: () {
                    setState(() {
                      _topTabController.animateTo(0);
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ToggleButton(
                  label: 'TEAM',
                  isSelected: _topTabController.index == 1,
                  onTap: () {
                    setState(() {
                      _topTabController.animateTo(1);
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _topTabController,
            children: const [
              PlayerViewScreen(),
              TeamViewScreen(),
            ],
          ),
        ),
      ],
    );
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
          style: GoogleFonts.tektur(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
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
          selectedLabelStyle: GoogleFonts.tektur(fontSize: 11),
          unselectedLabelStyle: GoogleFonts.tektur(fontSize: 11),
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

/// Custom toggle button for Player/Team view switching
class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.tektur(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.black : AppColors.textTertiary,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

