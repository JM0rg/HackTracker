import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/decoration_styles.dart';
import '../../widgets/toggle_button.dart';
import '../../screens/player_view_screen.dart';
import '../../screens/team_view_screen.dart';

/// Home tab view that manages the Player/Team toggle and tab content
class HomeTabView extends ConsumerStatefulWidget {
  final VoidCallback onNavigateToRecruiter;
  
  const HomeTabView({
    super.key,
    required this.onNavigateToRecruiter,
  });

  @override
  ConsumerState<HomeTabView> createState() => _HomeTabViewState();
}

class _HomeTabViewState extends ConsumerState<HomeTabView> with SingleTickerProviderStateMixin {
  late TabController _topTabController;

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

  void _navigateToTeamView() {
    setState(() {
      _topTabController.animateTo(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Segmented Button Toggle (Player / Team)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: DecorationStyles.statusContainer(),
          child: Row(
            children: [
              Expanded(
                child: ToggleButton(
                  label: 'PLAYER VIEW',
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
                child: ToggleButton(
                  label: 'TEAM VIEW',
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
            children: [
              PlayerViewScreen(
                onNavigateToTeamView: _navigateToTeamView,
              ),
              TeamViewScreen(
                onNavigateToRecruiter: widget.onNavigateToRecruiter,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
