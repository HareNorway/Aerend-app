import 'package:flutter/material.dart';

import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../../dugnad/dugnad_club_theme.dart';
import '../../dugnad/widgets/dugnad_rise_in.dart';
import '../../dugnad/widgets/dugnad_subpage_shell.dart';
import 'account_widgets.dart';
import 'appearance.dart';
import 'settings_design_kit.dart';

/// «Appinnstillinger» — the companion of [Appearance] in design
/// `settings-screens.jsx` `AppearanceScreen`: `.tk-head` + `.dg-label`
/// sections of `.dgs-list` rows (`.row.tgl` with `.dr-toggle`, value rows).
class ApplicationSetting extends StatefulWidget {
  const ApplicationSetting({super.key});

  @override
  State<ApplicationSetting> createState() => _ApplicationSettingState();
}

class _ApplicationSettingState extends State<ApplicationSetting> {
  /// Flip to true to restore Generelt + bottom Utseende CTA.
  static const bool _showGeneralAndAppearance = false;

  bool limitTracking = false;
  String language = 'English';
  List<String> languageList = [
    'English',
    'Franch',
    'Japanese',
    'Chinese',
    'Spanish',
    'Italian'
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    return Scaffold(
      backgroundColor: theme.background,
      body: DugnadFixedTypography(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AccountTkHead(
                title: 'Appinnstillinger', // TODO(l10n)
                onBack: () => Navigator.pop(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  // .ae-body { padding: 0 18px 120px }
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_showGeneralAndAppearance) ...[
                        DugnadRiseIn(
                          delay: const Duration(milliseconds: 120),
                          child: _generalSection(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      DugnadRiseIn(
                        delay: const Duration(milliseconds: 120),
                        child: _aboutSection(),
                      ),
                      if (_showGeneralAndAppearance) ...[
                        const SizedBox(height: 16),
                        DugnadRiseIn(
                          delay: const Duration(milliseconds: 260),
                          child: DgPrimaryButton(
                            label: languages.settingsAppearance,
                            icon: Icons.palette_outlined,
                            onPressed: () => openScreenWithResult(
                              context,
                              const Appearance(),
                            ),
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
      ),
    );
  }

  /// `.dg-label` + `.dgs-list` — tracking toggle, appearance link, language.
  Widget _generalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DgLabel('Generelt'), // TODO(l10n)
        DgsList(
          rows: [
            DgsInfoRow(
              title: languages.settingsLimitTracking,
              subtitle: 'Del mindre bruksdata med Reen Dugnad', // TODO(l10n)
              trailing: DrToggle(
                value: limitTracking,
                onChanged: (value) => setState(() => limitTracking = value),
              ),
            ),
            DgsInfoRow(
              title: languages.settingsAppearance,
              subtitle: 'Tema og varslingsvalg', // TODO(l10n)
              onTap: () => openScreenWithResult(context, const Appearance()),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: kDgGray400,
              ),
            ),
            DgsInfoRow(
              title: languages.settingsLanguage,
              trailing: _languageDropdown(),
            ),
          ],
        ),
      ],
    );
  }

  /// Trailing value picker — keeps the screen's existing local language state.
  Widget _languageDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: language,
        isDense: true,
        borderRadius: BorderRadius.circular(14),
        dropdownColor: Colors.white,
        icon: const Icon(
          Icons.expand_more_rounded,
          size: 18,
          color: kDgGray400,
        ),
        style: dgText(14.5, FontWeight.w700, color: ScSaasThemeTokens.gray500),
        onChanged: (String? newValue) {
          setState(() => language = newValue ?? language);
        },
        items: languageList
            .map(
              (value) => DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: dgText(
                    14.5,
                    FontWeight.w700,
                    color: ScSaasThemeTokens.gray500,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  /// `.dg-label` + `.dgs-list` — read-only version rows.
  Widget _aboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DgLabel('Om appen'), // TODO(l10n)
        DgsList(
          rows: [
            DgsInfoRow(
              title: languages.settingsAerendVersion,
              trailing: _valueText('4.54.0'),
            ),
            DgsInfoRow(
              title: languages.settingsOsVersion,
              trailing: _valueText('14'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _valueText(String value) => Text(
        value,
        style: dgText(
          14.5,
          FontWeight.w700,
          color: ScSaasThemeTokens.gray500,
        ),
      );
}
