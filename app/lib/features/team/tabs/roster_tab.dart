import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/team.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/decoration_styles.dart';
import '../../../providers/player_providers.dart';
import '../../../widgets/player_form_dialog.dart';
import '../../../widgets/confirm_dialog.dart';
import '../widgets/roster_player_card.dart';

/// Roster Tab - Enhanced with roles and color-coded numbers
class RosterTab extends ConsumerWidget {
  final Team team;

  const RosterTab({super.key, required this.team});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rosterAsync = ref.watch(rosterProvider(team.teamId));

    return Column(
      children: [
        // Legend
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: DecorationStyles.surfaceContainerSmall(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppColors.linkedUserColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Has Account',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 16),
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppColors.guestUserColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'No Account',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        // Add button (owner only)
        if (team.isOwner)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    enableDrag: true,
                    builder: (_) => PlayerFormDialog(teamId: team.teamId),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('ADD PLAYER'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        // Roster list
        Expanded(
          child: rosterAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
            data: (players) {
              if (players.isEmpty) {
                return Center(
                  child: Text(
                    'No players on roster',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: players.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: RosterPlayerCard(
                      key: ValueKey(players[index].playerId),
                      player: players[index],
                      canManage: team.isOwner,
                      onEdit: () async {
                        await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          enableDrag: true,
                          builder: (_) => PlayerFormDialog(
                            teamId: team.teamId,
                            player: players[index],
                          ),
                        );
                      },
                      onRemove: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (_) => ConfirmDialog(
                            title: 'REMOVE PLAYER?',
                            message: 'Remove ${players[index].fullName} from roster?',
                            confirmLabel: 'REMOVE',
                            confirmColor: AppColors.error,
                          ),
                        );
                        if (confirmed == true) {
                          final actions = ref.read(rosterActionsProvider(team.teamId));
                          await actions.removePlayer(players[index].playerId);
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}


