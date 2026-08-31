import 'package:aerend_customer/screens/common/homeMainV1/home_main_v1.dart';
import 'package:aerend_customer/screens/dugnad/widgets/dugnad_subpage_shell.dart';
import 'package:aerend_customer/theme/sc_saas_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/utils.dart';

/// «Ærend-kreditt» — mirrors design `checkout-screens.jsx` `CreditScreen`
/// (`.tk-head` + `.dgcr-card` hero + `.dg-label`/`.dgs-list` + `.dg-info`).
class Credit extends StatefulWidget {
  const Credit({super.key});

  @override
  State<Credit> createState() => _CreditState();
}

class _CreditState extends State<Credit> {
  static const Color _purple700 = ScSaasThemeTokens.primaryHover;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScSaasThemeTokens.background,
      body: DugnadFixedTypography(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildCreditCard(),
                      const SizedBox(height: 14),
                      _buildEarnSection(),
                      const SizedBox(height: 14),
                      _buildInfoBox(),
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

  /// `.tk-head` (paddingBottom 6) — shiny back circle, centred h1, 38px spacer.
  Widget _buildHeader(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 14),
        child: Row(
          children: [
            DugnadLbBackButton(
              onPressed: () => openScreenWithResult(context, const HomeMainV1(homeIndex: 3)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Ærend-kreditt", // TODO(l10n)
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 20 * -0.015,
                  color: ScSaasThemeTokens.text,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const SizedBox(width: 38),
          ],
        ),
      );

  /// `.dgcr-card .amt` — big amount from prefs, no currency suffix.
  String _creditAmountText() {
    final raw = prefGetString(prefAerendCredit).trim();
    final value = double.tryParse(raw.replaceAll(',', '.'));
    if (value == null) return raw.isEmpty ? "0" : raw;
    if (value == value.roundToDouble()) return value.toInt().toString();
    final whole = value.truncate();
    final frac = ((value - whole).abs() * 100).round().toString().padLeft(2, '0');
    return '$whole,$frac';
  }

  /// `.dgcr-card` — white hero: header, amount + kr, name/email, hairline, note.
  Widget _buildCreditCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: ScSaasThemeTokens.shadowCard,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // `.hd`
            Text(
              "Din Ærend-kreditt", // TODO(l10n)
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: ScSaasThemeTokens.text,
              ),
            ),
            // `.amt` — padding 14 0 12, 40/800 −0.03em purple-700, kr span 20/700.
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 12),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: _creditAmountText(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 40 * -0.03,
                        color: _purple700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    TextSpan(
                      text: " kr",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _purple700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // `.who` — name + right-aligned email, baseline, gap 10.
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  prefGetString(prefUserName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: ScSaasThemeTokens.text,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    prefGetString(prefEmail),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: ScSaasThemeTokens.gray500,
                    ),
                  ),
                ),
              ],
            ),
            // `.hair`
            Container(
              margin: const EdgeInsets.symmetric(vertical: 14),
              height: 1,
              color: const Color(0xFFF0EBF8),
            ),
            // `.note` — truck icon + purple-700 caption.
            Row(
              children: [
                const Icon(Icons.local_shipping_outlined, size: 15, color: _purple700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Gjelder kun bestillinger med levering", // TODO(l10n)
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _purple700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  /// `.dg-label` (margin 2 2 8) + `.dgs-list` of three `.row.tgl` rows.
  Widget _buildEarnSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 2, 2, 8),
            child: Text(
              "Slik tjener du kreditt".toUpperCase(), // TODO(l10n)
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 11 * 0.08,
                color: ScSaasThemeTokens.gray500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: ScSaasThemeTokens.shadowCard,
            ),
            child: Column(
              children: [
                _buildEarnRow(
                  icon: Icons.card_giftcard_rounded,
                  title: "Verv en venn", // TODO(l10n)
                  sub: "100 kr per venn som handler", // TODO(l10n)
                ),
                _buildRowSeparator(),
                _buildEarnRow(
                  icon: Icons.receipt_long_rounded,
                  title: "Avbrutt bestilling", // TODO(l10n)
                  sub: "Refunderes som kreditt med én gang", // TODO(l10n)
                ),
                _buildRowSeparator(),
                _buildEarnRow(
                  icon: Icons.shield_outlined,
                  title: "Klubbkampanjer", // TODO(l10n)
                  sub: "Bonuskreditt i utvalgte perioder", // TODO(l10n)
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildRowSeparator() => Container(height: 1, color: const Color(0xFFF4F0FB));

  /// `.dgs-list .row.tgl` — `.fl` icon + `.tx` title/sub, 14px v-padding, 12 gap.
  Widget _buildEarnRow({required IconData icon, required String title, required String sub}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              child: Icon(icon, size: 17, color: _purple700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: ScSaasThemeTokens.text,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      sub,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        color: ScSaasThemeTokens.gray500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  /// `.dg-info` — purple-100 note box, icon purple-600, text purple-700.
  Widget _buildInfoBox() => Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
        decoration: BoxDecoration(
          color: ScSaasThemeTokens.primaryTint,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(Icons.info_outline_rounded, size: 17, color: ScSaasThemeTokens.primary),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                "Kreditt trekkes automatisk i kassen før andre betalingsmåter.", // TODO(l10n)
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                  color: _purple700,
                ),
              ),
            ),
          ],
        ),
      );
}
