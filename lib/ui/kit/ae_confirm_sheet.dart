import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../theme/design_scale.dart';

import '../../theme/sc_saas_theme.dart';
import '../../screens/common/auth/auth_style.dart';
import 'ae_theme.dart';
import 'ae_sheet.dart';

/// Shared bottom-sheet vocabulary for the dugnad dialog family
/// (`dugnad/dialogs.jsx` + the two password sheets in `dugnad/auth-screens.jsx`).
///
/// Every "dialog" in the approved design is a bottom sheet, so all of these
/// build on [showAeSheet] / [AeSheetHandle] and implement the prototype
/// classes verbatim:
///
/// * `.dg-msheet`      — [AeSheetBody] (lavender, 12/18/safe+22 padding)
/// * `.dg-msheet-grab` — [AeSheetHandle] (from `dugnad_sheet.dart`)
/// * `.dg-mem-head`    — [AeSheetHead]
/// * `.dgd-confirm`    — [AeSheetConfirmButton] (+ `.danger`)
/// * `.ae-btn--primary`— [AeSheetPrimaryButton]
/// * `.dga-cancel`     — [AeSheetCancelButton]
/// * `.dgo-err`        — [AeSheetErrorNote]

/// `--ae-shiny-purple`: linear-gradient(150deg,#a98fe0,#7f5fc4 55%,#6b4fa8).
const LinearGradient kAeSheetShinyPurple = LinearGradient(
  begin: Alignment(-0.5, -0.85), // ≈ 150deg origin
  end: Alignment(0.5, 0.85),
  colors: [Color(0xFFA98FE0), Color(0xFF7F5FC4), Color(0xFF6B4FA8)],
  stops: [0.0, 0.55, 1.0],
);

/// `--ae-gray-200` as rendered in `dugnad.css` (#e2ddf0) — the sheet control
/// hairline. Not the same value as [ScSaasThemeTokens.gray300].
const Color kAeSheetHairline = Color(0xFFE2DDF0);

/// `--ae-gray-300` as rendered in `dugnad.css` (#d5cfe4).
const Color kAeSheetIdle = Color(0xFFD5CFE4);

/// `--ae-purple-300` (#c9b8ec) — the dashed promo border.
const Color kAePurple300 = Color(0xFFC9B8EC);

/// The head chip fill: purple gradient / error red / success green.
enum AeSheetTone { purple, danger, success }

TextStyle _sheetText(
  BuildContext context, {
  required double fontSize,
  required FontWeight fontWeight,
  required Color color,
  double? height,
  double? letterSpacing,
}) {
  final base = Theme.of(context).textTheme.bodyMedium;
  final style = TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
  return base?.merge(style) ?? style;
}

/// `.dg-msheet` — the sheet body itself: lavender background (supplied by
/// [showAeSheet]), `padding: 12px 18px calc(safe-area + 22px)`, grab handle
/// on top. Lifts above the keyboard so field sheets stay usable.
class AeSheetBody extends StatelessWidget {
  const AeSheetBody({
    super.key,
    required this.children,
    this.showHandle = true,
  });

  final List<Widget> children;
  final bool showHandle;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(
        top: 12,
        left: 18,
        right: 18,
        // .dg-msheet paddingBottom override in dialogs.jsx: safe-area + 22.
        bottom: media.padding.bottom + 22 + media.viewInsets.bottom,
      ),
      // Long sheets (five cancel reasons, three password fields) must still
      // reach their CTA once the keyboard is up.
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showHandle) const AeSheetHandle(),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// `.dg-mem-head` — 40px round tone chip + `h2` 18/800/-0.02em midnight +
/// optional `p` 12.5/600/lh1.45 gray-500. `gap: 13px`, `margin: 4px 2px`.
class AeSheetHead extends StatelessWidget {
  const AeSheetHead({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.tone = AeSheetTone.purple,
    this.iconSize = 19,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? message;
  final AeSheetTone tone;
  final double iconSize;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final hasMessage = message != null && message!.trim().isNotEmpty;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.dp(2), vertical: context.dp(4)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: context.dp(40),
            height: context.dp(40),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tone == AeSheetTone.danger
                  ? ScSaasThemeTokens.danger
                  : tone == AeSheetTone.success
                      ? ScSaasThemeTokens.success
                      : null,
              gradient: tone == AeSheetTone.purple
                  ? theme.shinyGradient
                  : null,
            ),
            child: Icon(icon, size: iconSize, color: Colors.white),
          ),
          SizedBox(width: context.dp(13)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: _sheetText(
                    context,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: theme.text,
                    letterSpacing: 18 * -0.02,
                  ),
                ),
                if (hasMessage) ...[
                  SizedBox(height: context.dp(5)),
                  Text(
                    message!,
                    style: _sheetText(
                      context,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: ScSaasThemeTokens.gray500,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// `.dgd-confirm` — full-width 15px-padded pill, radius 15, shiny-purple (or
/// `.danger` red), 15/800 white label, `margin-top: 18px`, purple glow.
/// Disabled = opacity .42 and no shadow.
class AeSheetConfirmButton extends StatelessWidget {
  const AeSheetConfirmButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.danger = false,
    this.icon,
    this.isLoading = false,
    this.topMargin = 18,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool danger;
  final IconData? icon;
  final bool isLoading;
  final double topMargin;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;
    final theme = context.aeTheme;
    return Padding(
      padding: EdgeInsets.only(top: topMargin),
      child: AuthPressable(
        onTap: disabled ? null : onPressed,
        builder: (context, pressed) => Opacity(
          // .dgd-confirm:disabled { opacity: .42 }
          opacity: disabled ? 0.42 : 1,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: context.dp(15)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(context.dp(15)),
              color: danger ? ScSaasThemeTokens.danger : null,
              gradient: danger ? null : theme.shinyGradient,
              boxShadow: disabled
                  ? null
                  : [
                      BoxShadow(
                        color: (danger
                                ? ScSaasThemeTokens.danger
                                : theme.primary)
                            .withValues(alpha: 0.55),
                        blurRadius: context.dp(22),
                        offset: const Offset(0, 10),
                        spreadRadius: -10,
                      ),
                    ],
            ),
            child: isLoading
                ? Center(
                    child: SizedBox(
                      width: context.dp(19),
                      height: context.dp(19),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: context.dp(17), color: Colors.white),
                        SizedBox(width: context.dp(8)), // .dgd-confirm { gap: 8px }
                      ],
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _sheetText(
                            context,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
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

/// `.ae-btn.ae-btn--primary` inside a sheet — 56px, radius 14, flat purple-600
/// (pressed purple-700, disabled purple-400 without shadow), optional leading
/// icon with the 10px `.ae-btn` gap.
class AeSheetPrimaryButton extends StatelessWidget {
  const AeSheetPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.topMargin = 16,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double topMargin;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;
    final theme = context.aeTheme;
    return Padding(
      padding: EdgeInsets.only(top: topMargin),
      child: AuthPressable(
        onTap: disabled ? null : onPressed,
        builder: (context, pressed) => AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.ease,
          height: context.dp(56),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.dp(14)),
            color: disabled
                ? theme.primaryDisabled
                : pressed
                    ? theme.primaryHover
                    : theme.primary,
            boxShadow: disabled ? null : theme.shadowButton,
          ),
          child: isLoading
              ? SizedBox(
                  width: context.dp(22),
                  height: context.dp(22),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: context.dp(17), color: Colors.white),
                      SizedBox(width: context.dp(10)), // .ae-btn { gap: 10px }
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _sheetText(
                          context,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 16 * -0.01,
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

/// `.dga-cancel` — full-width transparent text button, `margin-top: 10px`,
/// `padding: 13px`, 14.5/700 gray-500.
class AeSheetCancelButton extends StatelessWidget {
  const AeSheetCancelButton({
    super.key,
    required this.label,
    this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: context.dp(10)),
      child: AuthPressable(
        onTap: onPressed ??
            () {
              aeSheetCloseHaptic();
              Navigator.pop(context);
            },
        builder: (context, pressed) => Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: context.dp(13)),
          color: Colors.transparent,
          alignment: Alignment.center,
          child: Text(
            label,
            style: _sheetText(
              context,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: ScSaasThemeTokens.gray500,
            ),
          ),
        ),
      ),
    );
  }
}

/// `.dgo-err` — alert row, `margin-top: 10px`, gap 6, 12.5/700 error red.
class AeSheetErrorNote extends StatelessWidget {
  const AeSheetErrorNote({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: context.dp(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: context.dp(13),
            color: ScSaasThemeTokens.danger,
          ),
          SizedBox(width: context.dp(6)),
          Expanded(
            child: Text(
              message,
              style: _sheetText(
                context,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: ScSaasThemeTokens.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `AeConfirmSheet` — the generic yes/no sheet every confirmation builds on.
class AeConfirmSheet extends StatelessWidget {
  const AeConfirmSheet({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.tone = AeSheetTone.purple,
    this.confirmLabel = 'Bekreft', // TODO(l10n)
    this.cancelLabel = 'Avbryt', // TODO(l10n)
    this.onConfirm,
    this.onCancel,
    this.isLoading = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final AeSheetTone tone;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return AeSheetBody(
      children: [
        AeSheetHead(
          icon: icon,
          title: title,
          message: message,
          tone: tone,
        ),
        AeSheetConfirmButton(
          label: confirmLabel,
          danger: tone == AeSheetTone.danger,
          isLoading: isLoading,
          onPressed: onConfirm ??
              () {
                aeSheetSaveHaptic();
                Navigator.pop(context, true);
              },
        ),
        AeSheetCancelButton(
          label: cancelLabel,
          onPressed: onCancel,
        ),
      ],
    );
  }
}

/// Presents [AeConfirmSheet] and resolves to `true` when the primary action is
/// tapped, `null` when the sheet is dismissed.
Future<bool?> showAeConfirmSheet({
  required BuildContext context,
  required IconData icon,
  required String title,
  String? message,
  AeSheetTone tone = AeSheetTone.purple,
  String confirmLabel = 'Bekreft', // TODO(l10n)
  String cancelLabel = 'Avbryt', // TODO(l10n)
}) {
  return showAeSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) => AeConfirmSheet(
      icon: icon,
      title: title,
      message: message,
      tone: tone,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
    ),
  );
}

/// Rounded-rect dashed outline — Flutter has no `border-style: dashed`, so the
/// `.dgd-promo` border is painted (6px dash / 5px gap approximates the CSS).
class AeDashedBorder extends StatelessWidget {
  const AeDashedBorder({
    super.key,
    required this.child,
    required this.radius,
    this.color = kAePurple300,
    this.strokeWidth = 1.5,
  });

  final Widget child;
  final double radius;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        radius: radius,
        color: color,
        strokeWidth: strokeWidth,
      ),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.radius,
    required this.color,
    required this.strokeWidth,
  });

  final double radius;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            inset,
            inset,
            size.width - strokeWidth,
            size.height - strokeWidth,
          ),
          Radius.circular(radius),
        ),
      );
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    const dash = 6.0;
    const gap = 5.0;
    for (final ui.PathMetric metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.radius != radius ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
