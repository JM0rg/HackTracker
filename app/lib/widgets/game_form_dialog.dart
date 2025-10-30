import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../providers/game_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/app_input_fields.dart';

/// Dialog for creating or editing a game
class GameFormDialog extends ConsumerStatefulWidget {
  final String teamId;
  final Game? game; // null = create mode, non-null = edit mode

  const GameFormDialog({
    super.key,
    required this.teamId,
    this.game,
  });

  @override
  ConsumerState<GameFormDialog> createState() => _GameFormDialogState();
}

class _GameFormDialogState extends ConsumerState<GameFormDialog> {
  late final TextEditingController _opponentController;
  late final TextEditingController _locationController;
  late String _status;
  DateTime? _scheduledStart;
  late final TextEditingController _teamScoreController;
  late final TextEditingController _opponentScoreController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final game = widget.game;
    _opponentController = TextEditingController(text: game?.opponentName ?? '');
    _locationController = TextEditingController(text: game?.location ?? '');
    _status = game?.status ?? 'SCHEDULED';
    _scheduledStart = game?.scheduledStart;
    _teamScoreController = TextEditingController(text: game?.teamScore.toString() ?? '0');
    _opponentScoreController = TextEditingController(text: game?.opponentScore.toString() ?? '0');
  }

  @override
  void dispose() {
    _opponentController.dispose();
    _locationController.dispose();
    _teamScoreController.dispose();
    _opponentScoreController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledStart ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: _scheduledStart != null
            ? TimeOfDay.fromDateTime(_scheduledStart!)
            : TimeOfDay.now(),
      );

      if (time != null && mounted) {
        setState(() {
          _scheduledStart = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    try {
      final notifier = ref.read(gamesProvider(widget.teamId).notifier);
      
      if (widget.game == null) {
        // Create mode
        await notifier.createGame(
          status: _status,
          teamScore: int.tryParse(_teamScoreController.text) ?? 0,
          opponentScore: int.tryParse(_opponentScoreController.text) ?? 0,
          scheduledStart: _scheduledStart?.toIso8601String(),
          opponentName: _opponentController.text.trim().isEmpty ? null : _opponentController.text.trim(),
          location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        );
      } else {
        // Edit mode
        await notifier.updateGame(
          gameId: widget.game!.gameId,
          status: _status,
          teamScore: int.tryParse(_teamScoreController.text) ?? 0,
          opponentScore: int.tryParse(_opponentScoreController.text) ?? 0,
          scheduledStart: _scheduledStart?.toIso8601String(),
          opponentName: _opponentController.text.trim().isEmpty ? null : _opponentController.text.trim(),
          location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save game: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.game != null;
    final title = isEditMode ? 'Edit Game' : 'Create Game';

    return Container(
        padding: const EdgeInsets.only(top: 50),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(title),
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
            AppTextField(
              controller: _opponentController,
              labelText: 'OPPONENT NAME (Optional)',
              hintText: 'Enter opponent team name',
              autofocus: !isEditMode,
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _locationController,
              labelText: 'LOCATION (Optional)',
              hintText: 'Enter game location',
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: 16),
            // Date/Time picker
            InkWell(
              onTap: _isSubmitting ? null : _selectDateTime,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'SCHEDULED START',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _scheduledStart != null
                      ? '${_scheduledStart!.month}/${_scheduledStart!.day}/${_scheduledStart!.year} ${_scheduledStart!.hour}:${_scheduledStart!.minute.toString().padLeft(2, '0')}'
                      : 'Tap to set date & time',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _scheduledStart != null ? null : AppColors.textTertiary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Status dropdown
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'STATUS',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'SCHEDULED', child: Text('SCHEDULED')),
                DropdownMenuItem(value: 'IN_PROGRESS', child: Text('IN PROGRESS')),
                DropdownMenuItem(value: 'FINAL', child: Text('FINAL')),
                DropdownMenuItem(value: 'POSTPONED', child: Text('POSTPONED')),
              ],
              onChanged: _isSubmitting
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _status = value);
                      }
                    },
            ),
            const SizedBox(height: 16),
            // Scores (only show if game is in progress or final)
            if (_status == 'IN_PROGRESS' || _status == 'FINAL') ...[
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _teamScoreController,
                      labelText: 'TEAM SCORE',
                      hintText: '0',
                      keyboardType: TextInputType.number,
                      enabled: !_isSubmitting,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      controller: _opponentScoreController,
                      labelText: 'OPPONENT SCORE',
                      hintText: '0',
                      keyboardType: TextInputType.number,
                      enabled: !_isSubmitting,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
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
                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: AppColors.border),
                ),
                child: const Text('CANCEL'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Text(isEditMode ? 'UPDATE' : 'CREATE'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}

