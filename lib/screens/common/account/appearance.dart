import 'package:flutter/material.dart';

import '../../../utils/utils.dart';
import '../../../ui/kit/ae_theme.dart';
import '../../../ui/kit/ae_rise_in.dart';
import '../../../ui/kit/ae_subpage_shell.dart';
import 'account_widgets.dart';
import 'settings_design_kit.dart';

/// «Utseende og varsler» — mirrors design `settings-screens.jsx`
/// `AppearanceScreen` (`.tk-head` + `.dg-label`/`.dgs-themes` tema +
/// `.dg-label`/`.dgs-list` of `.row.tgl` + `.dr-toggle` varsler).
class Appearance extends StatefulWidget {
  const Appearance({super.key});

  @override
  State<Appearance> createState() => _AppearanceState();
}

class _AppearanceState extends State<Appearance> {
  // Dark mode / system appearance disabled until themes are ready — light only.
  ThemeMode _selectedMode = ThemeMode.light;

  /// Locally persisted notification preferences (default on, as in the
  /// prototype). Stored as strings so "unset" can still mean "on".
  static const String _prefNotifyOrders = 'settingsNotifyOrders';
  static const String _prefNotifyOffers = 'settingsNotifyOffers';
  static const String _prefNotifyClub = 'settingsNotifyClub';
  static const String _prefNotifySound = 'settingsNotifySound';
  static const String _prefNotifyHaptics = 'settingsNotifyHaptics';

  late final Map<String, bool> _switches = {
    for (final key in const [
      _prefNotifyOrders,
      _prefNotifyOffers,
      _prefNotifyClub,
      _prefNotifySound,
      _prefNotifyHaptics,
    ])
      key: prefGetStringWithDefaultValue(key, '1') == '1',
  };

  @override
  void initState() {
    super.initState();
    // _selectedMode = getSavedThemeMode();
  }

  void _applyTheme(ThemeMode themeMode) {
    setState(() {
      _selectedMode = themeMode;
    });
    MyApp.setThemeMode(context, themeMode);
  }

  void _toggle(String key) {
    final next = !(_switches[key] ?? false);
    setState(() => _switches[key] = next);
    prefSetString(key, next ? '1' : '0');
  }

  DgThemePreview get _preview {
    switch (_selectedMode) {
      case ThemeMode.dark:
        return DgThemePreview.dark;
      case ThemeMode.system:
        return DgThemePreview.auto;
      case ThemeMode.light:
        return DgThemePreview.light;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.aeTheme.background,
      body: AeFixedTypography(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AccountTkHead(
                title: 'Utseende og varsler', // TODO(l10n)
                onBack: () => Navigator.pop(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  // .ae-body { padding: 0 18px 120px }
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AeRiseIn(
                        delay: const Duration(milliseconds: 120),
                        child: _themeSection(),
                      ),
                      const SizedBox(height: 16),
                      AeRiseIn(
                        delay: const Duration(milliseconds: 190),
                        child: _notificationSection(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// `.dg-label` "Tema" + `.dgs-themes` — three preview tiles.
  Widget _themeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DgLabel('Tema'), // TODO(l10n)
        DgThemePicker(
          tiles: const [
            (DgThemePreview.light, 'Lyst'), // TODO(l10n)
            (DgThemePreview.dark, 'Mørkt'), // TODO(l10n)
            (DgThemePreview.auto, 'System'), // TODO(l10n)
          ],
          selected: _preview,
          onSelected: (preview) {
            if (preview == DgThemePreview.light) {
              _applyTheme(ThemeMode.light);
              return;
            }
            // Dark / system themes are not shipped yet — keep light applied.
            openSimpleSnackbar(
              'Mørkt tema kommer snart', // TODO(l10n)
            );
          },
        ),
      ],
    );
  }

  /// `.dg-label` "Varsler" + `.dgs-list` of `.row.tgl` with `.dr-toggle`.
  Widget _notificationSection() {
    const rows = <(String, String, String)>[
      (
        _prefNotifyOrders,
        'Bestillingsoppdateringer', // TODO(l10n)
        'Status på ordre og levering', // TODO(l10n)
      ),
      (
        _prefNotifyOffers,
        'Tilbud og kampanjer', // TODO(l10n)
        'Nye tilbud fra butikkene du følger', // TODO(l10n)
      ),
      (
        _prefNotifyClub,
        'Klubbnyheter', // TODO(l10n)
        'Milepæler og nyheter fra laget ditt', // TODO(l10n)
      ),
      (
        _prefNotifySound,
        'Lyd', // TODO(l10n)
        'Spill lyd ved varsler', // TODO(l10n)
      ),
      (
        _prefNotifyHaptics,
        'Vibrasjon', // TODO(l10n)
        'Haptisk respons ved handlinger', // TODO(l10n)
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DgLabel(languages.notifications),
        DgsList(
          rows: rows
              .map(
                (row) => DgsInfoRow(
                  title: row.$2,
                  subtitle: row.$3,
                  trailing: DrToggle(
                    value: _switches[row.$1] ?? false,
                    onChanged: (_) => _toggle(row.$1),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
