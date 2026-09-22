import 'package:flutter/material.dart';

import '../../../data/aegil/aegil_models.dart';
import '../../../theme/reen_pre_club_theme.dart';
import 'aegil_disclosure.dart';

/// The onboarding chip-card batch (AGIL-2 Phase 6).
///
/// Tapping a chip is the *only* way an allergen or a diet is ever recorded — the backend
/// refuses to infer food-safety facts from anything a customer types. That is why those chips
/// are visually distinguished and why the card says so: the customer should understand that
/// this tap, and nothing they say in passing, is what Ægil will treat as absolute.
///
/// Skipping is a first-class option, not a dismissal. Phase 6 re-invites after 7 days.
class OnboardingChipBatch extends StatefulWidget {
  const OnboardingChipBatch({
    super.key,
    required this.title,
    required this.chips,
    this.subtitle,
    this.onSubmit,
    this.onSkip,
    this.submitting = false,
  });

  final String title;
  final String? subtitle;
  final List<OnboardingChip> chips;

  /// Receives only the selected chips.
  final void Function(List<OnboardingChip> selected)? onSubmit;

  final VoidCallback? onSkip;
  final bool submitting;

  @override
  State<OnboardingChipBatch> createState() => _OnboardingChipBatchState();
}

class _OnboardingChipBatchState extends State<OnboardingChipBatch> {
  late final List<OnboardingChip> _chips = List.of(widget.chips);

  List<OnboardingChip> get _selected =>
      _chips.where((c) => c.selected).toList(growable: false);

  bool get _hasHardConstraint => _chips.any((c) => c.isHardConstraint);

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('onboarding-chip-batch'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AerendBergenAuthTokens.glassFill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AerendBergenAuthTokens.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            key: const Key('onboarding-title'),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AerendBergenAuthTokens.ink,
            ),
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 5),
            Text(
              widget.subtitle!,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AerendBergenAuthTokens.textSoft,
              ),
            ),
          ],
          const SizedBox(height: 14),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _chips.length; i++)
                _chip(_chips[i], i),
            ],
          ),

          if (_hasHardConstraint) ...[
            const SizedBox(height: 12),
            const Text(
              'Allergier og kosthold er absolutte. Ægil gjetter dem aldri — de gjelder '
              'bare når du velger dem her.',
              key: Key('onboarding-hard-constraint-note'),
              style: TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: AerendBergenAuthTokens.textMuted,
              ),
            ),
          ],

          const SizedBox(height: 16),
          const AegilDisclosure(variant: AegilDisclosureVariant.short),
          const SizedBox(height: 14),

          Row(
            children: [
              ElevatedButton(
                key: const Key('onboarding-submit'),
                onPressed: widget.submitting || widget.onSubmit == null
                    ? null
                    : () => widget.onSubmit!(_selected),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AerendBergenAuthTokens.orange,
                  foregroundColor: Colors.white,
                ),
                child: Text(widget.submitting ? 'Lagrer…' : 'Lagre'),
              ),
              const SizedBox(width: 10),
              TextButton(
                key: const Key('onboarding-skip'),
                onPressed: widget.onSkip,
                child: const Text(
                  'Hopp over',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AerendBergenAuthTokens.textSoft,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(OnboardingChip chip, int index) {
    final selected = chip.selected;

    return GestureDetector(
      key: Key('onboarding-chip-${chip.kind}-${chip.value}'),
      onTap: () => setState(() => _chips[index] = chip.toggled()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AerendBergenAuthTokens.mint.withValues(alpha: 0.22)
              : AerendBergenAuthTokens.glassFill,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            // A hard constraint looks different even before it is chosen, because it
            // behaves differently.
            color: chip.isHardConstraint
                ? AerendBergenAuthTokens.orange.withValues(alpha: selected ? 0.9 : 0.45)
                : AerendBergenAuthTokens.glassBorder,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(
                Icons.check,
                size: 13,
                color: AerendBergenAuthTokens.mintDeep,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              chip.label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: AerendBergenAuthTokens.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Decides whether the onboarding invitation should be shown again.
///
/// Skipping is a real choice, so it is honoured for a full week. Re-inviting sooner would
/// make "Hopp over" mean "ask me again in a minute".
class OnboardingReinvitePolicy {
  const OnboardingReinvitePolicy({this.waitDays = 7});

  final int waitDays;

  /// [skippedAt] null means the customer has never skipped.
  bool shouldInvite({DateTime? skippedAt, bool completed = false, DateTime? now}) {
    if (completed) return false;
    if (skippedAt == null) return true;

    final elapsed = (now ?? DateTime.now()).difference(skippedAt);

    return elapsed.inDays >= waitDays;
  }

  /// Guest onboarding waits until there is something to personalise from — the first
  /// delivery — rather than interrogating someone who has not ordered yet.
  bool shouldInviteGuest({required int deliveredOrders, DateTime? skippedAt, DateTime? now}) {
    if (deliveredOrders < 1) return false;

    return shouldInvite(skippedAt: skippedAt, now: now);
  }
}
