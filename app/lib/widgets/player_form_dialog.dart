import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../providers/player_providers.dart';
import '../services/api_service.dart';
import '../utils/messenger.dart';
import 'form_dialog.dart';
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
    return FormDialog(
      title: isEdit ? 'EDIT PLAYER' : 'ADD PLAYER',
      content: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            AppTextFormField(
              controller: _firstName,
              labelText: 'FIRST NAME',
              validator: (v) => _validateName(v, field: 'firstName'),
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [], // Disable autofill
            ),
            const SizedBox(height: 12),
            AppTextFormField(
              controller: _lastName,
              labelText: 'LAST NAME (Optional)',
              validator: (v) => _validateName(v, field: 'lastName'),
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [], // Disable autofill
            ),
            const SizedBox(height: 12),
            AppTextFormField(
              controller: _number,
              labelText: 'PLAYER NUMBER (0-99, Optional)',
              keyboardType: TextInputType.number,
              validator: _validateNumber,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [], // Disable autofill
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
            ],
          ),
        ),
      ),
      cancelLabel: 'CANCEL',
      confirmLabel: 'SAVE',
      isLoading: _saving,
      onConfirm: _submit,
    );
  }
}


