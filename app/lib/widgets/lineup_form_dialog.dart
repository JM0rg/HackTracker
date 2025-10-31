import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../providers/player_providers.dart';
import '../providers/game_providers.dart';
import '../services/api_service.dart';
import '../utils/messenger.dart';

class LineupFormDialog extends ConsumerStatefulWidget {
  final String teamId;
  final String gameId;
  final List<dynamic>? currentLineup;

  const LineupFormDialog({
    super.key,
    required this.teamId,
    required this.gameId,
    this.currentLineup,
  });

  @override
  ConsumerState<LineupFormDialog> createState() => _LineupFormDialogState();
}

class _LineupFormDialogState extends ConsumerState<LineupFormDialog> {
  final List<Map<String, dynamic>> _lineup = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Initialize with existing lineup if provided
    if (widget.currentLineup != null) {
      for (final item in widget.currentLineup!) {
        if (item is Map<String, dynamic>) {
          final playerId = item['playerId'] as String?;
          final battingOrder = item['battingOrder'] as int?;
          if (playerId != null && battingOrder != null) {
            _lineup.add({
              'playerId': playerId,
              'battingOrder': battingOrder,
            });
          }
        }
      }
      // Sort by batting order
      _lineup.sort((a, b) => (a['battingOrder'] as int).compareTo(b['battingOrder'] as int));
    }
  }

  void _togglePlayer(Player player) {
    setState(() {
      final existingIndex = _lineup.indexWhere((item) => item['playerId'] == player.playerId);
      
      if (existingIndex != -1) {
        // Remove player from lineup
        final removedOrder = _lineup[existingIndex]['battingOrder'] as int;
        _lineup.removeAt(existingIndex);
        // Adjust batting orders for remaining players
        for (final item in _lineup) {
          if ((item['battingOrder'] as int) > removedOrder) {
            item['battingOrder'] = (item['battingOrder'] as int) - 1;
          }
        }
      } else {
        // Add player to lineup
        final nextOrder = _lineup.isEmpty ? 1 : (_lineup.map((e) => e['battingOrder'] as int).reduce((a, b) => a > b ? a : b) + 1);
        _lineup.add({
          'playerId': player.playerId,
          'battingOrder': nextOrder,
        });
      }
      // Re-sort by batting order
      _lineup.sort((a, b) => (a['battingOrder'] as int).compareTo(b['battingOrder'] as int));
    });
  }

  void _adjustBattingOrder(int index, int newOrder) {
    if (newOrder < 1) return;
    
    setState(() {
      final oldOrder = _lineup[index]['battingOrder'] as int;
      
      // Check if new order conflicts with existing
      final conflictingIndex = _lineup.indexWhere(
        (item) => item['battingOrder'] == newOrder && item != _lineup[index],
      );
      
      if (conflictingIndex != -1) {
        // Swap orders
        _lineup[conflictingIndex]['battingOrder'] = oldOrder;
      }
      
      _lineup[index]['battingOrder'] = newOrder;
      // Re-sort
      _lineup.sort((a, b) => (a['battingOrder'] as int).compareTo(b['battingOrder'] as int));
    });
  }

  Future<void> _submit() async {
    setState(() => _saving = true);

    try {
      final actions = ref.read(gameActionsProvider(widget.teamId));
      await actions.setLineup(widget.gameId, _lineup);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        showErrorToast('Failed to save lineup: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rosterAsync = ref.watch(rosterProvider(widget.teamId));

    return Container(
      padding: const EdgeInsets.only(top: 50),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Set Lineup'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Select players and assign batting order',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              rosterAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error loading roster: $e')),
                data: (players) {
                  // Filter to active players only
                  final activePlayers = players.where((p) => p.isActive).toList();
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current lineup display with drag-and-drop
                      if (_lineup.isNotEmpty) ...[
                        Text(
                          'CURRENT LINEUP',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ReorderableListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          onReorder: (oldIndex, newIndex) {
                            setState(() {
                              if (newIndex > oldIndex) {
                                newIndex -= 1;
                              }
                              final item = _lineup.removeAt(oldIndex);
                              _lineup.insert(newIndex, item);
                              // Update batting orders to match new positions (1-based)
                              for (int i = 0; i < _lineup.length; i++) {
                                _lineup[i]['battingOrder'] = i + 1;
                              }
                            });
                          },
                          children: _lineup.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            final player = players.firstWhere(
                              (p) => p.playerId == item['playerId'],
                              orElse: () => throw StateError('Player not found in roster'),
                            );
                            final order = item['battingOrder'] as int;
                            
                            return Container(
                              key: ValueKey(item['playerId']),
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.drag_handle,
                                    color: AppColors.textTertiary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      order.toString(),
                                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          player.fullName,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (player.playerNumber != null)
                                          Text(
                                            '#${player.playerNumber}',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: AppColors.textSecondary,
                                              fontSize: 11,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    onPressed: () => _togglePlayer(player),
                                    color: AppColors.textTertiary,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const Divider(height: 24),
                      ],
                      
                      // Available players
                      Text(
                        'AVAILABLE PLAYERS',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...activePlayers.map((player) {
                        final isInLineup = _lineup.any((item) => item['playerId'] == player.playerId);
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isInLineup ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isInLineup ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          child: InkWell(
                            onTap: () => _togglePlayer(player),
                            borderRadius: BorderRadius.circular(8),
                            child: Row(
                              children: [
                                if (isInLineup)
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      (_lineup.firstWhere((item) => item['playerId'] == player.playerId)['battingOrder'] as int).toString(),
                                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                  ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        player.fullName,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (player.playerNumber != null)
                                        Text(
                                          '#${player.playerNumber}',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppColors.textSecondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (isInLineup)
                                  Icon(
                                    Icons.check_circle,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            top: 16,
          ),
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border(
              top: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('SAVE'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

