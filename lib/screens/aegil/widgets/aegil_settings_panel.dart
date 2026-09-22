import 'package:flutter/material.dart';

import '../../../data/aegil/aegil_models.dart';
import '../../../theme/reen_pre_club_theme.dart';
import 'aegil_disclosure.dart';

/// The Ægil settings screen (AGIL-2 Phase 6).
///
/// Every level is shown with what it actually permits, not just its name, so choosing one is
/// an informed decision rather than a guess at a label. Level 4 is visibly conditional on a
/// Vipps recurring agreement, and says so *before* it is tapped — the backend's 422 should be
/// a backstop, not how the customer finds out.
class AegilSettingsPanel extends StatelessWidget {
  const AegilSettingsPanel({
    super.key,
    required this.settings,
    required this.levels,
    this.onLevelChanged,
    this.onToggle,
    this.onPause,
    this.onResume,
    this.onForgetAll,
    this.levelError,
  });

  final AegilSettings settings;
  final List<AegilLevel> levels;
  final void Function(int level)? onLevelChanged;
  final void Function(String field, bool value)? onToggle;
  final void Function(int days)? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onForgetAll;

  /// e.g. LEVEL_REQUIRES_RECURRING, when the backend refused a change.
  final String? levelError;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('aegil-settings-panel'),
      padding: const EdgeInsets.all(16),
      children: [
        const AegilDisclosure(),
        const SizedBox(height: 18),

        const Text(
          'SÅ MYE KAN ÆGIL GJØRE',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: AerendBergenAuthTokens.textMuted,
          ),
        ),
        const SizedBox(height: 10),

        for (final level in levels) _levelTile(level),

        if (levelError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              levelError == 'LEVEL_REQUIRES_RECURRING'
                  ? 'Fast ukeshandel krever en Vipps-avtale for gjentakende trekk.'
                  : levelError!,
              key: const Key('aegil-level-error'),
              style: const TextStyle(
                fontSize: 12,
                color: AerendBergenAuthTokens.orangeLight,
              ),
            ),
          ),

        const SizedBox(height: 22),
        _switch(
          key: const Key('aegil-learning-toggle'),
          label: 'La Ægil lære',
          body: 'Husker hva du liker. Slår du det av, glemmer Ægil ingenting av seg selv — '
              'bruk «Glem alt» for det.',
          value: settings.learningEnabled,
          field: 'learning_enabled',
        ),
        _switch(
          key: const Key('aegil-against-interest-toggle'),
          label: 'Råd mot Ærends egen interesse',
          body: 'Ægil sier fra når noe er billigere et annet sted, når du allerede har varen, '
              'eller når du bør vente.',
          value: settings.againstInterestEnabled,
          field: 'against_interest_enabled',
        ),
        _switch(
          key: const Key('aegil-read-aloud-toggle'),
          label: 'Les opp',
          body: 'Ægil leser svarene sine høyt.',
          value: settings.readAloud,
          field: 'read_aloud',
        ),

        const SizedBox(height: 18),
        Text(
          settings.hasQuietHours
              ? 'Stille timer: ${settings.quietHoursFrom}–${settings.quietHoursTo}'
              : 'Ingen stille timer satt',
          key: const Key('aegil-quiet-hours'),
          style: const TextStyle(
            fontSize: 12.5,
            color: AerendBergenAuthTokens.textSoft,
          ),
        ),

        const SizedBox(height: 18),
        if (settings.paused)
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ægil er satt på pause'
                  '${settings.pausedUntil != null ? ' til ${settings.pausedUntil!.day}.${settings.pausedUntil!.month}' : ''}.',
                  key: const Key('aegil-paused-notice'),
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AerendBergenAuthTokens.textSubtitle,
                  ),
                ),
              ),
              TextButton(
                key: const Key('aegil-resume'),
                onPressed: onResume,
                child: const Text('Start igjen'),
              ),
            ],
          )
        else
          TextButton(
            key: const Key('aegil-pause'),
            onPressed: onPause == null ? null : () => onPause!(7),
            child: const Text(
              'Sett Ægil på pause i en uke',
              style: TextStyle(
                fontSize: 12.5,
                color: AerendBergenAuthTokens.textSoft,
              ),
            ),
          ),

        const SizedBox(height: 26),
        TextButton(
          key: const Key('aegil-forget-all'),
          onPressed: onForgetAll,
          child: const Text(
            'Glem alt Ægil vet om meg',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AerendBergenAuthTokens.orangeLight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _levelTile(AegilLevel level) {
    final selected = level.level == settings.level;
    final blocked = level.requiresRecurring && !settings.recurringAgreement;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        key: Key('aegil-level-${level.level}'),
        onTap: onLevelChanged == null ? null : () => onLevelChanged!(level.level),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: selected
                ? AerendBergenAuthTokens.mint.withValues(alpha: 0.16)
                : AerendBergenAuthTokens.glassFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AerendBergenAuthTokens.mint.withValues(alpha: 0.6)
                  : AerendBergenAuthTokens.glassBorder,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${level.level} · ${level.name}',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AerendBergenAuthTokens.ink,
                      ),
                    ),
                  ),
                  if (level.isDefault)
                    const Text(
                      'standard',
                      style: TextStyle(
                        fontSize: 11,
                        color: AerendBergenAuthTokens.textMuted,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                level.body,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: AerendBergenAuthTokens.textSoft,
                ),
              ),
              if (blocked) ...[
                const SizedBox(height: 6),
                Text(
                  'Krever Vipps-avtale for gjentakende trekk.',
                  key: Key('aegil-level-${level.level}-requires-recurring'),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AerendBergenAuthTokens.orangeLight,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _switch({
    required Key key,
    required String label,
    required String body,
    required bool value,
    required String field,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AerendBergenAuthTokens.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: AerendBergenAuthTokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            key: key,
            value: value,
            onChanged: onToggle == null ? null : (v) => onToggle!(field, v),
          ),
        ],
      ),
    );
  }
}
