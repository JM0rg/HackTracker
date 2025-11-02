import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// Action Area Widget
/// 
/// Renders different rows of buttons based on the current entry state.
/// Supports three states:
/// - initial: Non-play buttons (K, BB, FO) and field tap prompt
/// - outcome: Outcome buttons (1B, 2B, 3B, HR, OUT, ERROR)
/// - hitDetails: Optional detail buttons (Grounder, Fly Ball, Line Drive, Advanced to 2nd/3rd)
class ActionArea extends StatelessWidget {
  final EntryStep step;
  final String? hitType;
  final int? finalBaseReached;
  final String? selectedResult;
  final void Function(String result) onResultSelect;
  final void Function(String type) onHitTypeTap;
  final void Function(int base) onFinalBaseTap;

  const ActionArea({
    super.key,
    required this.step,
    this.hitType,
    this.finalBaseReached,
    this.selectedResult,
    required this.onResultSelect,
    required this.onHitTypeTap,
    required this.onFinalBaseTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          top: BorderSide(
            color: AppColors.textTertiary.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: step == EntryStep.initial ? _buildInitialState() : _buildOutcomeState(),
    );
  }

  /// Initial state: Non-play buttons
  Widget _buildInitialState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Primary action buttons (circular)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _CircularActionButton(
              label: 'K',
              subtitle: 'Strikeout',
              onPressed: () => onResultSelect('K'),
              isSelected: selectedResult == 'K',
            ),
            _CircularActionButton(
              label: 'BB',
              subtitle: 'Walk',
              onPressed: () => onResultSelect('BB'),
              isSelected: selectedResult == 'BB',
            ),
            _CircularActionButton(
              label: 'FO',
              subtitle: 'Flyout',
              onPressed: () => onResultSelect('FO'),
              isSelected: selectedResult == 'FO',
            ),
          ],
        ),
      ],
    );
  }

  /// Outcome state: Hit outcome and optional details
  Widget _buildOutcomeState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Primary outcome buttons (circular)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _CircularOutcomeButton(
              label: '1B',
              onPressed: () => onResultSelect('1B'),
              isSelected: selectedResult == '1B',
            ),
            _CircularOutcomeButton(
              label: '2B',
              onPressed: () => onResultSelect('2B'),
              isSelected: selectedResult == '2B',
            ),
            _CircularOutcomeButton(
              label: '3B',
              onPressed: () => onResultSelect('3B'),
              isSelected: selectedResult == '3B',
            ),
            _CircularOutcomeButton(
              label: 'HR',
              onPressed: () => onResultSelect('HR'),
              isSelected: selectedResult == 'HR',
            ),
            _CircularOutcomeButton(
              label: 'OUT',
              onPressed: () => onResultSelect('OUT'),
              isSelected: selectedResult == 'OUT',
            ),
            _CircularOutcomeButton(
              label: 'E',
              onPressed: () => onResultSelect('E'),
              isSelected: selectedResult == 'E',
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Optional detail buttons
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _ToggleChip(
                label: 'Grounder',
                isSelected: hitType == 'ground_out',
                onTap: () => onHitTypeTap('ground_out'),
              ),
              const SizedBox(width: 8),
              _ToggleChip(
                label: 'Fly Ball',
                isSelected: hitType == 'fly_ball',
                onTap: () => onHitTypeTap('fly_ball'),
              ),
              const SizedBox(width: 8),
              _ToggleChip(
                label: 'Line Drive',
                isSelected: hitType == 'line_drive',
                onTap: () => onHitTypeTap('line_drive'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Toggle Chip Widget
class _ToggleChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 6,
          horizontal: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withOpacity(0.2)
              : AppColors.cardBackground,
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.textTertiary.withOpacity(0.3),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isSelected ? AppColors.accent : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

/// Circular Action Button Widget (with subtitle) - same size as outcome buttons
class _CircularActionButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final VoidCallback onPressed;
  final bool isSelected;

  const _CircularActionButton({
    required this.label,
    required this.subtitle,
    required this.onPressed,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent : Colors.grey.shade600,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textTertiary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

/// Circular Outcome Button Widget (without subtitle)
class _CircularOutcomeButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isSelected;

  const _CircularOutcomeButton({
    required this.label,
    required this.onPressed,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.accent : Colors.grey.shade600,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Entry Step Enum
enum EntryStep {
  initial, // Initial state: Non-play buttons
  outcome, // Outcome state: After field tap, show outcome buttons
}

