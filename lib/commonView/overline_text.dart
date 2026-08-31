import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/sc_saas_theme.dart';

/// Ærend overline text — 10.5 / 800 / uppercase / 0.08em tracking.
///
/// Design spec: colors_and_type.css → .ae-overline
class AeOverlineText extends StatelessWidget {
  final String text;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;

  const AeOverlineText(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        height: 1.2,
        letterSpacing: 0.08 * 10.5, // 0.84px
        color: color ?? ScSaasThemeTokens.gray500,
      ),
    );
  }
}
