import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/team.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/game_providers.dart';
import '../../../widgets/game_form_dialog.dart';
import '../widgets/game_list_view.dart';
import '../widgets/game_calendar_view.dart';

/// Schedule Tab - List and calendar view of games
class ScheduleTab extends ConsumerStatefulWidget {
  final Team team;

  const ScheduleTab({super.key, required this.team});

  @override
  ConsumerState<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends ConsumerState<ScheduleTab> {
  bool _isListView = true; // true = list, false = calendar

  @override
  Widget build(BuildContext context) {
    final gamesAsync = ref.watch(gamesProvider(widget.team.teamId));

    return Stack(
      children: [
        Column(
          children: [
            // View toggle
            Container(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('LIST'), icon: Icon(Icons.list)),
                  ButtonSegment(value: false, label: Text('CALENDAR'), icon: Icon(Icons.calendar_month)),
                ],
                selected: {_isListView},
                onSelectionChanged: (Set<bool> selection) {
                  setState(() => _isListView = selection.first);
                },
              ),
            ),
            Expanded(
              child: _isListView
                  ? GameListView(team: widget.team, gamesAsync: gamesAsync)
                  : GameCalendarView(team: widget.team, gamesAsync: gamesAsync),
            ),
          ],
        ),
        // Add Game button (owner only)
        if (widget.team.isOwner)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: () async {
                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  enableDrag: true,
                  builder: (_) => GameFormDialog(teamId: widget.team.teamId),
                );
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
      ],
    );
  }
}


