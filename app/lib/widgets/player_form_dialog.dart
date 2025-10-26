import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../providers/player_providers.dart';
import '../services/api_service.dart';
import '../utils/messenger.dart';

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
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _firstName = TextEditingController(text: widget.player?.firstName ?? '');
    _lastName = TextEditingController(text: widget.player?.lastName ?? '');
    _number = TextEditingController(
      text: widget.player?.playerNumber != null ? widget.player!.playerNumber.toString() : '',
    );
    _status = widget.player?.status ?? 'active';
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

    // Close first for optimistic UX
    if (mounted) {
      widget.onSaved?.call();
      Navigator.pop(context, true);
    }

    // Note: Success/error toasts are handled by the optimistic mutation
    // No need to handle them here - just await the operation
    if (widget.player == null) {
      await actions.addPlayer(
        firstName: first,
        lastName: last.isEmpty ? null : last,
        playerNumber: numVal,
        status: _status,
      );
    } else {
      await actions.updatePlayer(
        widget.player!.playerId,
        firstName: first,
        lastName: last.isEmpty ? null : last,
        playerNumber: numVal,
        status: _status,
      );
    }
    
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.player != null;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        isEdit ? 'EDIT PLAYER' : 'ADD PLAYER',
        style: GoogleFonts.tektur(
          color: AppColors.primary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
      content: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            TextFormField(
              controller: _firstName,
              decoration: const InputDecoration(labelText: 'FIRST NAME'),
              style: GoogleFonts.tektur(),
              validator: (v) => _validateName(v, field: 'firstName'),
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [], // Disable autofill
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lastName,
              decoration: const InputDecoration(labelText: 'LAST NAME (Optional)'),
              style: GoogleFonts.tektur(),
              validator: (v) => _validateName(v, field: 'lastName'),
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [], // Disable autofill
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _number,
              decoration: const InputDecoration(labelText: 'PLAYER NUMBER (0-99, Optional)'),
              keyboardType: TextInputType.number,
              style: GoogleFonts.tektur(),
              validator: _validateNumber,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [], // Disable autofill
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _status,
              items: const [
                DropdownMenuItem(value: 'active', child: Text('ACTIVE')),
                DropdownMenuItem(value: 'inactive', child: Text('INACTIVE')),
                DropdownMenuItem(value: 'sub', child: Text('SUB')),
              ],
              onChanged: (v) => setState(() => _status = v ?? 'active'),
              decoration: const InputDecoration(labelText: 'STATUS'),
              style: GoogleFonts.tektur(color: AppColors.textPrimary),
              dropdownColor: AppColors.surface,
            ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            textStyle: GoogleFonts.tektur(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          child: _saving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                )
              : const Text('SAVE'),
        ),
      ],
    );
  }
}


