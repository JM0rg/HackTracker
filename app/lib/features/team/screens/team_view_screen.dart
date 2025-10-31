import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/team_providers.dart';
import '../tabs/stats_tab.dart';
import '../tabs/schedule_tab.dart';
import '../tabs/roster_tab.dart';
import '../tabs/chat_tab.dart';

/// Team View - Main coordinator for team-specific screens
class TeamViewScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToRecruiter;
  
  const TeamViewScreen({super.key, this.onNavigateToRecruiter});

  @override
  ConsumerState<TeamViewScreen> createState() => _TeamViewScreenState();
}

class _TeamViewScreenState extends ConsumerState<TeamViewScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(teamsProvider);
    final selectedTeam = ref.watch(selectedTeamProvider);

    // Set initial selected team if none is selected
    teamsAsync.whenData((teams) {
      if (teams.isNotEmpty && selectedTeam == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(selectedTeamProvider.notifier).state = teams.first;
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: AppBar(
          elevation: 0,
          backgroundColor: AppColors.background,
          automaticallyImplyLeading: false,
          toolbarHeight: 0,
          flexibleSpace: Column(
            children: [
              // Tabs with underline indicator
              Container(
                height: 48,
                color: AppColors.surface,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  dividerColor: Colors.transparent,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(
                    fontFamily: 'Tektur',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontFamily: 'Tektur',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                  tabs: const [
                    Tab(text: 'STATS'),
                    Tab(text: 'SCHEDULE'),
                    Tab(text: 'ROSTER'),
                    Tab(text: 'CHAT'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: selectedTeam == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                StatsTab(team: selectedTeam),
                ScheduleTab(team: selectedTeam),
                RosterTab(team: selectedTeam),
                ChatTab(team: selectedTeam),
              ],
            ),
    );
  }
}


