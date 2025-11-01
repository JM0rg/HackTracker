import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../providers/player_providers.dart';
import '../models/player.dart';
import 'app_input_fields.dart';

class PlayerFormDialog extends ConsumerStatefulWidget {
  final String teamId;
  final Player? player; // null for add
  final VoidCallback? onSaved;

  const PlayerFormDialog({
    super.key,
    required this.teamId,
    this.player,
    this.onSaved,
  });

  @override
  ConsumerState<PlayerFormDialog> createState() => _PlayerFormDialogState();
}

class _PlayerFormDialogState extends ConsumerState<PlayerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _number;
  String _status = 'active';
  List<String> _selectedPositions = [];
  final List<Map<String, dynamic>> _playerQueue = [];
  bool _saving = false;
  
  static const List<String> _availablePositions = [
    '1B', '2B', '3B', 'SS', 'OF', 'C', 'P', 'DH', 'UTIL'
  ];

  @override
  void initState() {
    super.initState();
    _firstName = TextEditingController(text: widget.player?.firstName ?? '');
    _lastName = TextEditingController(text: widget.player?.lastName ?? '');
    _number = TextEditingController(
      text: widget.player?.playerNumber != null ? widget.player!.playerNumber.toString() : '',
    );
    _status = widget.player?.status ?? 'active';
    _selectedPositions = widget.player?.positions != null ? List<String>.from(widget.player!.positions!) : [];
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _number.dispose();
    super.dispose();
  }

  String? _validateName(String? value, {required String field}) {
    final v = (value ?? '').trim();
    if (field == 'firstName' && v.isEmpty) return 'First name is required';
    if (v.isEmpty) return null; // optional
    if (v.contains(' ')) return 'One word only';
    final regex = RegExp(r'^[A-Za-z-]{1,30}$');
    if (!regex.hasMatch(v)) return 'Letters and hyphens only (max 30)';
    return null;
  }

  String? _validateNumber(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null; // optional
    final n = int.tryParse(v);
    if (n == null || n < 0 || n > 99) return 'Number must be 0-99';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final actions = ref.read(rosterActionsProvider(widget.teamId));
    final first = _firstName.text.trim();
    final last = _lastName.text.trim();
    final numStr = _number.text.trim();
    final numVal = numStr.isEmpty ? null : int.parse(numStr);
    final positions = _selectedPositions.isEmpty ? null : _selectedPositions;

    // Close first for optimistic UX
    if (mounted) {
      widget.onSaved?.call();
      Navigator.pop(context, true);
    }

    // Note: Success/error toasts are handled by the optimistic mutation
    // No need to handle them here - just await the operation
    if (widget.player == null) {
      // If there are queued players, add them all at once (including current form)
      if (_playerQueue.isNotEmpty) {
        // Combine queued players with current form player
        final allPlayers = [
          ..._playerQueue,
          {
            'firstName': first,
            'lastName': last.isEmpty ? null : last,
            'playerNumber': numVal,
            'status': _status,
            'positions': positions,
          }
        ];
        
        // Add all players in bulk with optimistic updates for all
        await actions.addPlayersBulk(allPlayers);
      } else {
        // Single player - use regular add
        await actions.addPlayer(
          firstName: first,
          lastName: last.isEmpty ? null : last,
          playerNumber: numVal,
          status: _status,
          positions: positions,
        );
      }
    } else {
      await actions.updatePlayer(
        widget.player!.playerId,
        firstName: first,
        lastName: last.isEmpty ? null : last,
        playerNumber: numVal,
        status: _status,
        positions: positions,
      );
    }
    
    if (mounted) setState(() => _saving = false);
  }
  
  void _addToQueue() {
    if (!_formKey.currentState!.validate()) return;
    
    final first = _firstName.text.trim();
    final last = _lastName.text.trim();
    final numStr = _number.text.trim();
    final numVal = numStr.isEmpty ? null : int.parse(numStr);
    final positions = _selectedPositions.isEmpty ? null : _selectedPositions;
    
    setState(() {
      _playerQueue.add({
        'firstName': first,
        'lastName': last.isEmpty ? null : last,
        'playerNumber': numVal,
        'status': _status,
        'positions': positions,
      });
      
      // Clear form for next player
      _firstName.clear();
      _lastName.clear();
      _number.clear();
      _status = 'active';
      _selectedPositions = [];
    });
  }
  
  void _removeFromQueue(int index) {
    setState(() {
      _playerQueue.removeAt(index);
    });
  }
  
  void _togglePosition(String position) {
    setState(() {
      if (_selectedPositions.contains(position)) {
        _selectedPositions.remove(position);
      } else {
        if (_selectedPositions.length < 2) {
          _selectedPositions.add(position);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.player != null;
    final totalPlayers = _playerQueue.length + 1;
    final title = isEdit ? 'Edit Player' : (_playerQueue.isEmpty ? 'Add Player' : 'Add Players ($totalPlayers)');
    
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
            // Show queued players
            if (_playerQueue.isNotEmpty) ...[
              Text(
                'Players to Add (${_playerQueue.length})',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(_playerQueue.length, (index) {
                final p = _playerQueue[index];
                final name = p['lastName'] != null && p['lastName'].isNotEmpty 
                    ? '${p['firstName']} ${p['lastName']}'
                    : p['firstName'];
                final number = p['playerNumber'] != null ? '#${p['playerNumber']}' : '';
                final positions = p['positions'] != null ? (p['positions'] as List).join(', ') : '';
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$name $number'.trim(),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (positions.isNotEmpty)
                              Text(
                                positions,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => _removeFromQueue(index),
                        color: AppColors.textTertiary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(height: 24),
              Text(
                _playerQueue.isEmpty ? 'Player Details' : 'Next Player',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Main form
            AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppTextFormField(
                      controller: _firstName,
                      labelText: 'FIRST NAME',
                      validator: (v) => _validateName(v, field: 'firstName'),
                      autofocus: _playerQueue.isNotEmpty,
                      autocorrect: false,
                      enableSuggestions: false,
                      autofillHints: const [],
                    ),
                    const SizedBox(height: 12),
                    AppTextFormField(
                      controller: _lastName,
                      labelText: 'LAST NAME (Optional)',
                      validator: (v) => _validateName(v, field: 'lastName'),
                      autocorrect: false,
                      enableSuggestions: false,
                      autofillHints: const [],
                    ),
                    const SizedBox(height: 12),
                    AppTextFormField(
                      controller: _number,
                      labelText: 'PLAYER NUMBER (0-99, Optional)',
                      keyboardType: TextInputType.number,
                      validator: _validateNumber,
                      autocorrect: false,
                      enableSuggestions: false,
                      autofillHints: const [],
                    ),
                    const SizedBox(height: 12),
                    AppDropdownFormField<String>(
                      value: _status,
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('ACTIVE')),
                        DropdownMenuItem(value: 'inactive', child: Text('INACTIVE')),
                        DropdownMenuItem(value: 'sub', child: Text('SUB')),
                      ],
                      onChanged: (v) => setState(() => _status = v ?? 'active'),
                      labelText: 'STATUS',
                    ),
                    const SizedBox(height: 16),
                    
                    // Positions selector
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'POSITIONS (Optional, Max 2)',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availablePositions.map((pos) {
                            final isSelected = _selectedPositions.contains(pos);
                            final isDisabled = !isSelected && _selectedPositions.length >= 2;
                            
                            return FilterChip(
                              label: Text(pos),
                              selected: isSelected,
                              onSelected: isDisabled ? null : (_) => _togglePosition(pos),
                              selectedColor: AppColors.primary.withValues(alpha: 0.2),
                              checkmarkColor: AppColors.primary,
                              backgroundColor: AppColors.surface,
                              disabledColor: AppColors.border,
                              side: BorderSide(
                                color: isSelected ? AppColors.primary : AppColors.border,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    
                    // Add another button (only for new players, not editing)
                    if (!isEdit) ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _addToQueue,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('ADD ANOTHER'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
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
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Text(isEdit ? 'SAVE' : (_playerQueue.isEmpty ? 'ADD' : 'ADD ALL')),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}


