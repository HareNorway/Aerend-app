import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../../../ui/kit/ae_theme.dart';
import '../../../ui/kit/ae_rise_in.dart';
import '../../../ui/kit/ae_subpage_shell.dart';
import '../account/account_widgets.dart';
import '../account/settings_design_kit.dart';

/// Native «Kontakt oss» — replaces the old CMS HTML page (norwayhare@…).
class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  static const String email = 'ailogisticsas@gmail.com';
  static const String phoneDisplay = '+47 451 35 576';
  static const String phoneTel = '+4745135576';
  static const String address = 'Birkelundsbakken 19, 5231 Paradis';
  static const String company = 'Ai Logistics AS';

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;

    return Scaffold(
      backgroundColor: theme.background,
      body: AeFixedTypography(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AccountTkHead(
                title: 'Kontakt oss',
                onBack: () => Navigator.maybePop(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AeRiseIn(
                        delay: const Duration(milliseconds: 80),
                        child: _HeroCard(theme: theme),
                      ),
                      const SizedBox(height: 18),
                      AeRiseIn(
                        delay: const Duration(milliseconds: 140),
                        child: const DgLabel('Henvendelser'),
                      ),
                      AeRiseIn(
                        delay: const Duration(milliseconds: 160),
                        child: _InquiryCard(
                          icon: Icons.business_center_outlined,
                          title: 'Media og forretning',
                          body:
                              'Presse, partnerskap og forretningshenvendelser.',
                          email: email,
                        ),
                      ),
                      const SizedBox(height: 10),
                      AeRiseIn(
                        delay: const Duration(milliseconds: 200),
                        child: _InquiryCard(
                          icon: Icons.support_agent_rounded,
                          title: 'Generelt og teknisk',
                          body:
                              'Spørsmål om appen, kontoen eller en bestilling.',
                          email: email,
                        ),
                      ),
                      const SizedBox(height: 18),
                      AeRiseIn(
                        delay: const Duration(milliseconds: 240),
                        child: const DgLabel('Kundestøtte'),
                      ),
                      AeRiseIn(
                        delay: const Duration(milliseconds: 260),
                        child: _CompanyCard(theme: theme),
                      ),
                      const SizedBox(height: 14),
                      AeRiseIn(
                        delay: const Duration(milliseconds: 300),
                        child: DgInfoBox(
                          icon: Icons.info_outline_rounded,
                          text:
                              'Vi svarer vanligvis innen 1–2 virkedager. '
                              'For akutte leveringsproblemer, ring oss.',
                        ),
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
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.theme});

  final AeThemePalette theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: ScSaasThemeTokens.shadowCard,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              'assets/Logo/reen/mark-coral-navy.png',
              width: 52,
              height: 52,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ærend',
                  style: dgText(
                    17,
                    FontWeight.w800,
                    color: ScSaasThemeTokens.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Vi hjelper deg gjerne — send en e-post eller ring.',
                  style: dgText(
                    13,
                    FontWeight.w500,
                    height: 1.4,
                    color: ScSaasThemeTokens.gray600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InquiryCard extends StatelessWidget {
  const _InquiryCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.email,
  });

  final IconData icon;
  final String title;
  final String body;
  final String email;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => openUrl('mailto:$email'),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: ScSaasThemeTokens.shadowCard,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8E2F4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.primaryTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: theme.primaryHover),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: dgText(
                          14.5,
                          FontWeight.w700,
                          color: ScSaasThemeTokens.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: dgText(
                          12.5,
                          FontWeight.w500,
                          height: 1.4,
                          color: ScSaasThemeTokens.gray600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.mail_outline_rounded,
                            size: 15,
                            color: theme.primary,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              email,
                              style: dgText(
                                13,
                                FontWeight.w700,
                                color: theme.primaryHover,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: theme.primary.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompanyCard extends StatelessWidget {
  const _CompanyCard({required this.theme});

  final AeThemePalette theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ScSaasThemeTokens.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            ContactUsScreen.company,
            style: dgText(
              15,
              FontWeight.w800,
              color: ScSaasThemeTokens.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Org.nr. 936 971 857',
            style: dgText(
              12,
              FontWeight.w500,
              color: ScSaasThemeTokens.gray600,
            ),
          ),
          const SizedBox(height: 8),
          _ContactRow(
            icon: Icons.location_on_outlined,
            label: ContactUsScreen.address,
          ),
          _ContactRow(
            icon: Icons.phone_outlined,
            label: ContactUsScreen.phoneDisplay,
            onTap: () => openUrl('tel:${ContactUsScreen.phoneTel}'),
          ),
          _ContactRow(
            icon: Icons.email_outlined,
            label: ContactUsScreen.email,
            onTap: () => openUrl('mailto:${ContactUsScreen.email}'),
            emphasize: true,
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    this.onTap,
    this.emphasize = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Icon(icon, size: 17, color: theme.primaryHover),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: dgText(
                13.5,
                emphasize ? FontWeight.w700 : FontWeight.w600,
                color: emphasize
                    ? theme.primaryHover
                    : ScSaasThemeTokens.gray600,
              ),
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: theme.primary.withValues(alpha: 0.4),
            ),
        ],
      ),
    );

    if (onTap == null) return row;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap!();
        },
        borderRadius: BorderRadius.circular(10),
        child: row,
      ),
    );
  }
}
