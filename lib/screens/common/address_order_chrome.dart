import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../commonView/custom_text_field.dart';
import '../../theme/design_scale.dart';
import '../../theme/sc_saas_theme.dart';
import '../dugnad/dugnad_club_theme.dart';
import '../dugnad/widgets/dugnad_subpage_shell.dart';

/// Shared Ærend design chrome for the "Leveringsadresse / Ny adresse /
/// Ordrehistorikk / Ordredetaljer" screens.
///
/// Prototype sources: `dugnad/address-order.jsx`, `dugnad/offers.jsx`
/// (`AddressScreen`, `OrderHistoryScreen`), `ui_kits/customer/track.css`
/// (`.tk-head`), `dugnad/dugnad.css` (`.dg-label`, `.dg-info`,
/// `.dg-green-banner`, `.dn-addteam`, `.oh-wrap`, `.oh-acts`),
/// `ui_kits/customer/app.css` (`.co-foot`).
///
/// All values are fixed px on the 375×812 design frame.

// ── Literal palette values that have no ScSaasThemeTokens entry ───────────
/// `--ae-gray-200` — `.oh-acts button` / `.dgm-types .tp` border.
const Color kAoGray200 = Color(0xFFE2DDF0);

/// `--ae-gray-400` — `.dgm-types .tp .ic`, `.dn-addteam .go` fallbacks.
const Color kAoGray400 = Color(0xFFA9A4BB);

/// `--ae-purple-200` — `.dn-addteam` dashed border.
const Color kAoPurple200 = Color(0xFFD9CEF0);

/// `--ae-purple-400` — `.dgo-route .arw`.
const Color kAoPurple400 = Color(0xFFA98FE0);

/// `.dgs-list` / `.dgo-sum` / `.dgo-ship` 1px row separator.
const Color kAoHairline = Color(0xFFF4F0FB);

/// `.dgo-head .st.levert` background / foreground.
const Color kAoSuccessChipBg = Color(0xFFEAFAF0);
const Color kAoSuccessChipFg = Color(0xFF1F8A5B);

/// `.oh-acts .cancel` border — literal `rgba(217,83,79,.28)`.
const Color kAoCancelBorder = Color(0x47D9534F);

/// kit-shared.css: 120ms ease colour/shadow, 60ms ease transform.
const Duration kAoColorDuration = Duration(milliseconds: 120);
const Duration kAoMoveDuration = Duration(milliseconds: 60);

TextStyle aoText(
  double size,
  FontWeight weight, {
  Color? color,
  double? height,
  double? letterSpacingEm,
}) {
  return GoogleFonts.plusJakartaSans(
    fontSize: size,
    fontWeight: weight,
    height: height,
    letterSpacing: letterSpacingEm != null ? size * letterSpacingEm : null,
    color: color ?? ScSaasThemeTokens.text,
  );
}

/// Field labels on light dugnad screens (not the dark auth `.ae-flabel`).
TextStyle aoFieldLabelStyle(BuildContext context) {
  return aoText(14, FontWeight.w600, color: ScSaasThemeTokens.gray500);
}

/// White `.ae-input` for address-order forms on the lavender page background.
class AoField extends StatefulWidget {
  const AoField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.validator,
    this.textInputAction = TextInputAction.next,
    this.keyboardType = TextInputType.text,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String) validator;
  final TextInputAction textInputAction;
  final TextInputType keyboardType;

  @override
  State<AoField> createState() => _AoFieldState();
}

class _AoFieldState extends State<AoField> {
  static OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(width: 1.5, color: color),
      );

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: aoFieldLabelStyle(context)),
        const SizedBox(height: 8),
        TextFormFieldCustom(
          controller: widget.controller,
          setError: true,
          useLabelWithBorder: false,
          backgroundColor: Colors.white,
          radius: 14,
          textAlignVertical: TextAlignVertical.center,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          validator: widget.validator,
          decoration: InputDecoration(
            hintText: widget.hint,
            contentPadding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            enabledBorder: _border(Colors.transparent),
            focusedBorder: _border(theme.primary),
            errorBorder: _border(ScSaasThemeTokens.danger),
            focusedErrorBorder: _border(ScSaasThemeTokens.danger),
            hintStyle: GoogleFonts.plusJakartaSans(
              color: ScSaasThemeTokens.gray500,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
          style: GoogleFonts.plusJakartaSans(
            color: ScSaasThemeTokens.ink,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

/// `.tk-head` — back button, centred h1 (20/800/-0.015em), 38px end spacer.
/// Design is `padding: 8px 18px 10px`; we use 22px horizontal so the shiny
/// back circle isn’t flush to the device edge on modern phones.
class AoTkHead extends StatelessWidget {
  const AoTkHead({super.key, required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.dp(22),
        context.dp(8),
        context.dp(22),
        // Design JSX uses 6; leave more air so the first body card
        // (e.g. `.dg-green-banner`) doesn’t sit under the back circle.
        context.dp(14),
      ),
      child: Row(
        children: [
          AoShinyBackButton(
            onPressed: onBack ?? () => Navigator.maybePop(context),
          ),
          SizedBox(width: context.dp(12)),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: aoText(20, FontWeight.w800,
                  letterSpacingEm: -0.015, color: theme.text),
            ),
          ),
          SizedBox(width: context.dp(12)),
          SizedBox(width: context.dp(38)),
        ],
      ),
    );
  }
}

/// `.tk-head .ae-back` — delegates to the shared [DugnadLbBackButton].
class AoShinyBackButton extends StatelessWidget {
  const AoShinyBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DugnadLbBackButton(onPressed: onPressed);
  }
}

/// `.dg-label` — 11/800, 0.08em, uppercase, gray-500, margin 2px 2px 10px.
class AoSectionLabel extends StatelessWidget {
  const AoSectionLabel(this.text, {super.key, this.bottom = 10});

  final String text;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(2, 2, 2, bottom),
      child: Text(
        text.toUpperCase(),
        style: aoText(
          11,
          FontWeight.w800,
          letterSpacingEm: 0.08,
          color: ScSaasThemeTokens.gray500,
        ),
      ),
    );
  }
}

/// `.dg-info` — purple-100 box, radius 14, padding 13×14, gap 11,
/// purple-600 icon, 12.5/600 purple-700 body at lh 1.45.
class AoInfoBox extends StatelessWidget {
  const AoInfoBox({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: theme.primaryTint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 17, color: theme.primary),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              text,
              style: aoText(
                12.5,
                FontWeight.w600,
                height: 1.45,
                color: theme.primaryHover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `.dg-green-banner` — rgba(34,167,105,.10) fill, .22 hairline, radius 16,
/// padding 13×15, 38px rounded icon chip, 13.5/800 title + 11.5/700 success sub.
class AoGreenBanner extends StatelessWidget {
  const AoGreenBanner({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.favorite_rounded,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0x1A22A769),
        border: Border.all(color: const Color(0x3822A769)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0x2922A769),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 19, color: ScSaasThemeTokens.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: aoText(
                    13.5,
                    FontWeight.w800,
                    height: 1.25,
                    letterSpacingEm: -0.01,
                    color: context.dugnadTheme.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: aoText(
                    11.5,
                    FontWeight.w700,
                    color: ScSaasThemeTokens.success,
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

/// `.dn-addteam` — white card, 1.5px dashed purple-200, radius 16, padding 14,
/// 42px purple-100 icon tile, 14.5/800 title + 11.5/600 sub, gray-300 chevron.
class AoAddRow extends StatelessWidget {
  const AoAddRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.icon = Icons.add_rounded,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    return AoPressable(
      onTap: onTap,
      builder: (context, pressed) => CustomPaint(
        painter: _DashedBorderPainter(
          color: theme.primaryTint,
          radius: 16,
          strokeWidth: 1.5,
          dash: 6,
          gap: 4,
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A2D1B5B), // 0 2px 4px rgba(45,27,91,.04)
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.primaryTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: theme.primaryHover,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: aoText(
                        14.5,
                        FontWeight.w800,
                        letterSpacingEm: -0.01,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: aoText(
                        11.5,
                        FontWeight.w600,
                        color: ScSaasThemeTokens.gray500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: ScSaasThemeTokens.gray300,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum AoActionKind { cancel, review }

/// `.oh-acts button` — 8×13 padding, 1.5px gray-200 border, radius 11,
/// white fill, 12.5/800 label with a 13px leading icon (6px gap).
class AoActionButton extends StatelessWidget {
  const AoActionButton({
    super.key,
    required this.kind,
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });

  final AoActionKind kind;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  /// Overrides `.review` / `.cancel` foreground (club `primaryHover` on dugnad).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isCancel = kind == AoActionKind.cancel;
    final fg = color ??
        (isCancel ? ScSaasThemeTokens.danger : ScSaasThemeTokens.primaryHover);
    final borderColor = isCancel ? kAoCancelBorder : kAoGray200;

    return AoPressable(
      onTap: onTap,
      scale: 0.96,
      builder: (context, pressed) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 6),
            Text(label, style: aoText(12.5, FontWeight.w800, color: fg)),
          ],
        ),
      ),
    );
  }
}

/// `.oh-acts` — 8px gap row, `padding: 0 2px 4px`, `margin-top: -2px`.
class AoActionsRow extends StatelessWidget {
  const AoActionsRow({
    super.key,
    required this.children,
    this.compact = false,
  });

  final List<Widget> children;

  /// `style={{ padding: 0 }}` variant used on the order-detail screen.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final spaced = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) spaced.add(const SizedBox(width: 8));
      spaced.add(children[i]);
    }
    return Padding(
      padding: compact
          ? EdgeInsets.zero
          : const EdgeInsets.fromLTRB(2, 0, 2, 4),
      child: Transform.translate(
        offset: compact ? Offset.zero : const Offset(0, -2),
        child: Row(children: spaced),
      ),
    );
  }
}

/// `.co-foot` — sticky footer: 14px 18px (safe-area + 20px), lavender
/// gradient fade (`linear-gradient(to top, --ae-lavender 60%, transparent)`).
class AoStickyFooter extends StatelessWidget {
  const AoStickyFooter({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(18, 14, 18, safeBottom + 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            ScSaasThemeTokens.background,
            ScSaasThemeTokens.background,
            Color(0x00F4F0FB),
          ],
          stops: [0, 0.6, 1],
        ),
      ),
      child: child,
    );
  }
}

/// Press feedback for tappable cards/rows — `:active { transform: scale(…) }`
/// at the kit's 60ms ease transform timing.
class AoPressable extends StatefulWidget {
  const AoPressable({
    super.key,
    required this.builder,
    this.onTap,
    this.scale = 0.99,
  });

  final Widget Function(BuildContext context, bool pressed) builder;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<AoPressable> createState() => _AoPressableState();
}

class _AoPressableState extends State<AoPressable> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: kAoMoveDuration,
        curve: Curves.ease,
        child: widget.builder(context, _pressed),
      ),
    );
  }
}

/// `.dgm-map` — 150px map plate themed to the active club palette.
class AoMapPlate extends StatelessWidget {
  const AoMapPlate({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final gridColor = theme.primary.withValues(alpha: 0.14);
    return AoPressable(
      onTap: onTap,
      builder: (context, pressed) => ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: const Alignment(-0.35, -1),
              end: const Alignment(0.35, 1),
              colors: [
                theme.primaryTint,
                Color.lerp(theme.primaryTint, theme.background, 0.45) ??
                    theme.background,
              ],
            ),
            boxShadow: ScSaasThemeTokens.shadowCard,
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  key: ValueKey(gridColor.toARGB32()),
                  painter: _MapGridPainter(lineColor: gridColor),
                ),
              ),
              Center(
                child: AoMapPin(
                  color: theme.primary,
                  shadowColor: theme.text.withValues(alpha: 0.35),
                ),
              ),
              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: theme.text.withValues(alpha: 0.22),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.near_me_outlined,
                        size: 14,
                        color: theme.primaryHover,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: aoText(
                          12.5,
                          FontWeight.w800,
                          color: theme.primaryHover,
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

/// `.dgm-map .pin` — 36px teardrop (radius 50%/50%/50%/4px, rotated -45deg,
/// with the glyph counter-rotated 45deg).
class AoMapPin extends StatelessWidget {
  const AoMapPin({
    super.key,
    required this.color,
    required this.shadowColor,
  });

  final Color color;
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -18),
      child: Transform.rotate(
        angle: -0.7853981633974483,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 18,
                offset: const Offset(0, 8),
                spreadRadius: -6,
              ),
            ],
          ),
          child: Transform.rotate(
            angle: 0.7853981633974483,
            child: const Icon(
              Icons.place_outlined,
              size: 18,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// `.dgm-map .grid` — 26px themed rules in both directions.
class _MapGridPainter extends CustomPainter {
  const _MapGridPainter({required this.lineColor});

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    for (var y = 0.0; y < size.height; y += 26) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (var x = 0.0; x < size.width; x += 26) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Dashed rounded outline — Flutter has no `border-style: dashed`.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dash,
    required this.gap,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.dash != dash ||
      oldDelegate.gap != gap;
}
