import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/sc_saas_theme.dart';

/// Shared «Handlekurv → Kasse» primitives.
///
/// Every value here is copied verbatim from the design export:
/// `ui_kits/customer/app.css` (the `.co-*` block) and `dugnad/dugnad.css`
/// (`.dg-foodstep` / `.mk-cstep` / `.mk-cartbar` / `.dgsp-row`).
/// All numbers are fixed px on the 375×812 frame — never scale them.

/// `.co-body` — padding `4px 18px 18px`, column `gap: 14px`.
const double kCoBodyPadH = 18;
const double kCoBodyGap = 14;

/// `.co-card` — radius 16, padding 16.
const double kCoCardRadius = 16;
const EdgeInsets kCoCardPadding = EdgeInsets.all(16);

/// `.dgsp-row` neutrals (dugnad.css 1437-1448): `--ae-gray-200` / `--ae-gray-300`.
const Color kDgspBorder = Color(0xFFE2DDF0);
const Color kDgspRadio = Color(0xFFD5CFE4);

TextStyle coSans({
  required double size,
  required FontWeight weight,
  Color? color,
  double? height,
  double? letterSpacingEm,
}) {
  return GoogleFonts.plusJakartaSans(
    fontSize: size,
    fontWeight: weight,
    height: height,
    letterSpacing: letterSpacingEm == null ? null : size * letterSpacingEm,
    color: color ?? ScSaasThemeTokens.text,
  );
}

/// `.co-head h1` — 18/800 midnight, centered.
TextStyle get coHeadTitle =>
    coSans(size: 18, weight: FontWeight.w800, height: 1.2);

/// `.co-label` — 10.5/800, letter-spacing .08em, uppercase, gray-500.
TextStyle get coLabelStyle => coSans(
      size: 10.5,
      weight: FontWeight.w800,
      height: 1.2,
      letterSpacingEm: 0.08,
      color: ScSaasThemeTokens.gray500,
    );

/// `.co-row .t` — 14/700 midnight.
TextStyle get coRowTitle =>
    coSans(size: 14, weight: FontWeight.w700, height: 1.25);

/// `.co-row .s` — 12 gray-500 (`--ae-caption-weight: 500`).
TextStyle get coRowSub => coSans(
      size: 12,
      weight: FontWeight.w500,
      height: 1.3,
      color: ScSaasThemeTokens.gray500,
    );

/// `.co-row .edit` — 12.5/700 purple-700.
TextStyle get coEditStyle => coSans(
      size: 12.5,
      weight: FontWeight.w700,
      height: 1.2,
      color: ScSaasThemeTokens.primaryHover,
    );

/// `.co-item .nm` — 14/700 midnight.
TextStyle get coItemName =>
    coSans(size: 14, weight: FontWeight.w700, height: 1.25);

/// `.co-item .qty` — 12 gray-500.
TextStyle get coItemQty => coRowSub;

/// `.co-item .pr` — 14/800 midnight.
TextStyle get coItemPrice =>
    coSans(size: 14, weight: FontWeight.w800, height: 1.25);

/// `.co-totals .ln` — 13.5 gray-700.
TextStyle get coTotalLine => coSans(
      size: 13.5,
      weight: FontWeight.w500,
      height: 1.3,
      color: ScSaasThemeTokens.gray700,
    );

/// `.co-totals .ln.grand` — 17/800 midnight.
TextStyle get coTotalGrand =>
    coSans(size: 17, weight: FontWeight.w800, height: 1.2);

/// `.co-when` — 12.5/600 gray-500.
TextStyle get coWhenStyle => coSans(
      size: 12.5,
      weight: FontWeight.w600,
      height: 1.3,
      color: ScSaasThemeTokens.gray500,
    );

/// `.co-when b` — 800 midnight.
TextStyle get coWhenStrong =>
    coSans(size: 12.5, weight: FontWeight.w800, height: 1.3);

/// `.co-seg button` — 13.5/700.
TextStyle coSegLabel(Color color) =>
    coSans(size: 13.5, weight: FontWeight.w700, height: 1.2, color: color);

/// `.mk-cartbar .items .sum` — 11.5/700 gray-500.
TextStyle get coCartBarSum => coSans(
      size: 11.5,
      weight: FontWeight.w700,
      height: 1.2,
      color: ScSaasThemeTokens.gray500,
    );

/// `.mk-cartbar .total` — 17/800 midnight.
TextStyle get coCartBarTotal =>
    coSans(size: 17, weight: FontWeight.w800, height: 1.2);

/// `--ae-shiny-purple` — `linear-gradient(150deg, #A98FE0, #7F5FC4 55%, #6B4FA8)`.
const LinearGradient kAeShinyPurple = LinearGradient(
  begin: Alignment(-0.5, -0.87),
  end: Alignment(0.5, 0.87),
  colors: [Color(0xFFA98FE0), Color(0xFF7F5FC4), Color(0xFF6B4FA8)],
  stops: [0, 0.55, 1],
);

/// `.co-card` — white, radius 16, padding 16, `--ae-shadow-card`.
class CoCard extends StatelessWidget {
  const CoCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: kCoCardPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kCoCardRadius),
        boxShadow: ScSaasThemeTokens.shadowCard,
      ),
      child: child,
    );
  }
}

/// `.co-label` — margin `0 0 10px`.
class CoLabel extends StatelessWidget {
  const CoLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text.toUpperCase(), style: coLabelStyle),
    );
  }
}

/// `.co-row .ic` — 40×40, radius 11, purple-100 on purple-700.
class CoRowIcon extends StatelessWidget {
  const CoRowIcon(this.icon, {super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: ScSaasThemeTokens.primaryTint,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, size: 18, color: ScSaasThemeTokens.primaryHover),
    );
  }
}

/// `.co-row` — icon + body + optional «Endre» link.
class CoRow extends StatelessWidget {
  const CoRow({
    super.key,
    this.icon,
    this.leading,
    required this.title,
    this.subtitle,
    this.onEdit,
  });

  final IconData? icon;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        leading ?? CoRowIcon(icon ?? Icons.place_rounded),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: coRowTitle,
              ),
              if (subtitle != null && subtitle!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: coRowSub,
                  ),
                ),
            ],
          ),
        ),
        if (onEdit != null) ...[
          const SizedBox(width: 10),
          CoEditLink(onTap: onEdit!),
        ],
      ],
    );
  }
}

/// `.co-row .edit` — 12.5/700 purple-700, `:active { transform: scale(.94) }`.
class CoEditLink extends StatefulWidget {
  const CoEditLink({super.key, required this.onTap, this.label});

  final VoidCallback onTap;

  /// Defaults to the design's «Endre».
  final String? label;

  @override
  State<CoEditLink> createState() => _CoEditLinkState();
}

class _CoEditLinkState extends State<CoEditLink> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Text(
            widget.label ?? 'Endre', // TODO(l10n)
            style: coEditStyle,
          ),
        ),
      ),
    );
  }
}

/// `.co-when` — 1px gray-100 rule, 26×26 lavender chip, 12.5/600 gray-500.
class CoWhen extends StatelessWidget {
  const CoWhen({
    super.key,
    required this.icon,
    required this.label,
    required this.strong,
  });

  final IconData icon;
  final String label;
  final String strong;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 11),
      padding: const EdgeInsets.only(top: 11),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: ScSaasThemeTokens.gray100)),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: ScSaasThemeTokens.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: ScSaasThemeTokens.primaryHover),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  if (label.isNotEmpty) TextSpan(text: label),
                  TextSpan(text: strong, style: coWhenStrong),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: coWhenStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class CoTotalsEntry {
  const CoTotalsEntry(this.label, this.value);

  final String label;
  final String value;
}

/// `.co-card.co-totals` — column gap 9, grand line above a dashed gray-300 rule
/// (`padding-top: 11px; margin-top: 2px`).
class CoTotals extends StatelessWidget {
  const CoTotals({
    super.key,
    required this.lines,
    required this.grandLabel,
    required this.grandValue,
  });

  final List<CoTotalsEntry> lines;
  final String grandLabel;
  final String grandValue;

  @override
  Widget build(BuildContext context) {
    return CoCard(
      child: Column(
        children: [
          for (int i = 0; i < lines.length; i++) ...[
            if (i > 0) const SizedBox(height: 9),
            Row(
              children: [
                Expanded(child: Text(lines[i].label, style: coTotalLine)),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(lines[i].value, style: coTotalLine),
                ),
              ],
            ),
          ],
          const SizedBox(height: 11),
          const CoDashedRule(),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(child: Text(grandLabel, style: coTotalGrand)),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(grandValue, style: coTotalGrand),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// `border-top: 1px dashed var(--ae-gray-300)`.
class CoDashedRule extends StatelessWidget {
  const CoDashedRule({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(painter: _CoDashedRulePainter()),
    );
  }
}

class _CoDashedRulePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = ScSaasThemeTokens.gray300
      ..strokeWidth = 1;
    const double dash = 3;
    const double gap = 3;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0.5), Offset(x + dash, 0.5), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// `.co-foot` — sticky footer with solid page background so the swipe
/// capsule never composites over scrolled content.
class CoFoot extends StatelessWidget {
  const CoFoot({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    const bg = ScSaasThemeTokens.background;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        kCoBodyPadH,
        14,
        kCoBodyPadH,
        MediaQuery.paddingOf(context).bottom + 20,
      ),
      color: bg,
      child: child,
    );
  }
}

/// `.dg-foodstep.sm` / `.mk-cstep.sm` — lavender pill (radius 999, padding 3),
/// 26×26 white round buttons, count 13.5/800 midnight with `min-width: 24px`.
class CoQtyStepper extends StatelessWidget {
  const CoQtyStepper({
    super.key,
    required this.quantity,
    required this.onMinus,
    required this.onPlus,
    this.busy = false,
  });

  final int quantity;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: ScSaasThemeTokens.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CoStepButton(
            icon: Icons.remove_rounded,
            onTap: busy ? null : onMinus,
          ),
          SizedBox(
            width: 24,
            child: busy
                ? const Center(
                    child: SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.6,
                        color: ScSaasThemeTokens.primary,
                      ),
                    ),
                  )
                : Text(
                    '$quantity',
                    textAlign: TextAlign.center,
                    style: coSans(
                      size: 13.5,
                      weight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
          ),
          _CoStepButton(icon: Icons.add_rounded, onTap: busy ? null : onPlus),
        ],
      ),
    );
  }
}

/// `.dg-foodstep.sm button` — 26×26 white circle, `0 1px 2px rgba(45,27,91,.14)`.
class _CoStepButton extends StatelessWidget {
  const _CoStepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x242D1B5B),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 14,
          color: onTap == null
              ? ScSaasThemeTokens.primaryDisabled
              : ScSaasThemeTokens.primaryHover,
        ),
      ),
    );
  }
}
