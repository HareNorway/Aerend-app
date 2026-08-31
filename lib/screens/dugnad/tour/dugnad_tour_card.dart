import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../../../theme/ae_typography.dart';
import '../../../theme/design_scale.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart' show languages;
import '../dugnad_club_theme.dart';
import 'dugnad_tour_controller.dart';

/// Overlay scrim + stroke constants (the only non-theme colours allowed here).
const Color kTourScrim = Color(0x99140C28);
const double kTourHoleInflate = 6.0;
const double kTourHoleRadius = 18.0;
/// Space between the spotlight hole and the explanation card.
const double kTourCardGap = 20.0;

/// Persistent-dim spotlight. Paints ONE scrim over the whole screen (the base
/// dim, always present while the overlay is up) and subtracts a rounded hole
/// from it via `BlendMode.dstOut` weighted by [reveal] — so the hole + ring fade
/// in per step while the scrim never fades. Because there is a single scrim and
/// the hole is subtracted inside the same layer, nothing double-darkens.
/// Null rect ⇒ flat scrim, no hole (welcome / done, and between steps).
class DugnadTourSpotlightPainter extends CustomPainter {
  DugnadTourSpotlightPainter({required this.rect, required this.reveal})
      : super(repaint: Listenable.merge([rect, reveal]));

  /// Live target rect in overlay coordinates (null ⇒ no hole). NOT yet inflated.
  final ValueListenable<Rect?> rect;

  /// 0..1 fade for the hole + ring only.
  final Animation<double> reveal;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Offset.zero & size;
    final r = rect.value;
    final f = reveal.value.clamp(0.0, 1.0);
    final hasHole = r != null && f > 0 && r.width > 0 && r.height > 0;

    canvas.saveLayer(full, Paint());
    canvas.drawRect(full, Paint()..color = kTourScrim);
    if (hasHole) {
      // Clamp to the overlay so an inflated / mid-transform rect never paints
      // a ring that clips against the screen edge (matches .dg-tour-hole inset).
      final hole = r.inflate(kTourHoleInflate).intersect(full);
      if (!hole.isEmpty) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(hole, const Radius.circular(kTourHoleRadius)),
          Paint()
            ..blendMode = BlendMode.dstOut
            ..color = Colors.white.withValues(alpha: f),
        );
      }
    }
    canvas.restore();

    if (hasHole) {
      final hole = r.inflate(kTourHoleInflate).intersect(full);
      if (!hole.isEmpty) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(hole, const Radius.circular(kTourHoleRadius)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = Colors.white.withValues(alpha: 0.75 * f),
        );
      }
    }
  }

  @override
  bool shouldRepaint(DugnadTourSpotlightPainter old) => false;
}

/// The tour explanation card. Returns a positioned widget — use inside a Stack.
/// Placement math is in RAW logical pixels (D4); sizing uses context.dp.
class DugnadTourCard extends StatelessWidget {
  const DugnadTourCard({
    super.key,
    required this.controller,
    required this.step,
    required this.rectListenable,
    required this.metrics,
    this.opacity,
  });

  final DugnadTourController controller;
  final DugnadTourStep step;

  /// Live target rect (overlay coords), or null for a centered card. Repositions
  /// the card on scroll WITHOUT rebuilding its contents.
  final ValueListenable<Rect?> rectListenable;

  /// Ticks on viewport metrics changes so placement re-runs.
  final Listenable metrics;

  /// Optional fade for the card body. Applied inside [Positioned] so this widget
  /// can stay a direct [Stack] child.
  final Animation<double>? opacity;

  @override
  Widget build(BuildContext context) {
    // Content is built ONCE per step; a scroll/metrics tick only re-runs [_place].
    final content = _fade(_cardContent(context));
    return AnimatedBuilder(
      animation: Listenable.merge([rectListenable, metrics]),
      child: content,
      builder: (ctx, child) => _place(ctx, rectListenable.value, child!),
    );
  }

  Widget _fade(Widget child) {
    final anim = opacity;
    if (anim == null) return child;
    return FadeTransition(opacity: anim, child: child);
  }

  Widget _place(BuildContext context, Rect? rect, Widget content) {
    final mq = MediaQuery.of(context);
    final h = mq.size.height;
    final safe = mq.padding;
    const insetSide = 18.0;
    // Comfortable height for title + multi-line body + chrome + actions.
    const minComfortable = 220.0;

    if (rect == null || step.placement == DugnadTourPlacement.center) {
      return _centered(content, h, safe);
    }

    final holePad = kTourHoleInflate;
    // Address chip shares the hero row with the 40dp bell. A full-bleed
    // card (18px inset) covers the bell's left edge — pull both sides in so
    // the card sits as a centered panel under the address.
    final clearHeaderBell = step.id == 'addr';
    final inset = clearHeaderBell ? context.dp(40) + 32 : insetSide;
    final gap = kTourCardGap + (clearHeaderBell ? 10.0 : 0.0);

    final roomBelow = h - (rect.bottom + holePad + gap) - safe.bottom - 8;
    final roomAbove = (rect.top - holePad) - safe.top - 8;

    // Neither side fits a full card — center so we use the full safe area.
    if (roomBelow < minComfortable && roomAbove < minComfortable) {
      return _centered(content, h, safe);
    }

    final placeAbove = step.placement == DugnadTourPlacement.above ||
        roomBelow < minComfortable ||
        (roomBelow < roomAbove && roomAbove >= minComfortable);

    if (placeAbove) {
      final rawBottom = h - (rect.top - holePad) + gap;
      final bottom = rawBottom.clamp(safe.bottom + 8.0, h - safe.top - 8.0);
      final available = h - bottom - safe.top - 8;
      if (available < minComfortable) return _centered(content, h, safe);
      return Positioned(
        left: inset,
        right: inset,
        bottom: bottom,
        child: _scrollableCard(content, available),
      );
    }

    final top = (rect.bottom + holePad + gap)
        .clamp(safe.top + 8.0, h - safe.bottom - 8.0);
    final available = h - top - safe.bottom - 8;
    if (available < minComfortable) return _centered(content, h, safe);
    return Positioned(
      left: inset,
      right: inset,
      top: top,
      child: _scrollableCard(content, available),
    );
  }

  Widget _centered(Widget content, double h, EdgeInsets safe) {
    final maxH = h - safe.top - safe.bottom - 48;
    return Positioned.fill(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(child: _scrollableCard(content, maxH)),
        ),
      ),
    );
  }

  /// Caps height; scrolls when step copy is taller than the available slot.
  Widget _scrollableCard(Widget content, double maxH) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH < 120 ? 120 : maxH),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: content,
      ),
    );
  }

  Widget _cardContent(BuildContext context) {
    final theme = context.dugnadTheme;
    final l = languages;
    final total = controller.totalSteps;
    final index = controller.index;
    final isLast = index >= total - 1;
    final reduce = MediaQuery.disableAnimationsOf(context);

    final counterStyle = aeOverline(color: theme.primaryHover).copyWith(
      fontSize: context.dp(10.5),
      fontWeight: FontWeight.w800,
      letterSpacing: context.dp(10.5) * 0.06,
    );
    final titleStyle = aeH3(color: theme.text).copyWith(
      fontSize: context.dp(17),
      fontWeight: FontWeight.w800,
      height: 1.25,
      letterSpacing: context.dp(17) * -0.02,
    );
    final bodyStyle = aeBody(color: ScSaasThemeTokens.gray600).copyWith(
      fontSize: context.dp(13.5),
      fontWeight: FontWeight.w600,
      height: 1.5,
    );

    return Container(
      // D1 chrome — white, radius 20, padding 16/17/13, deep shadow + hairline.
      padding: EdgeInsets.fromLTRB(
        context.dp(17),
        context.dp(16),
        context.dp(17),
        context.dp(13),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.dp(20)),
        border: Border.all(color: ScSaasThemeTokens.border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80140C28), // rgba(20,12,40,.5)
            blurRadius: 38,
            offset: Offset(0, 16),
            spreadRadius: -14,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.dugnadTourStepCounter(index + 1, total).toUpperCase(),
                  style: counterStyle,
                ),
              ),
              _CloseCircle(
                  onTap: controller.dismiss, label: l.dugnadTourClose),
            ],
          ),
          SizedBox(height: context.dp(9)),
          Text(step.title(l, again: controller.isAgain), style: titleStyle),
          SizedBox(height: context.dp(6)),
          Text(step.body(l, again: controller.isAgain), style: bodyStyle),
          Padding(
            padding:
                EdgeInsets.only(top: context.dp(14), bottom: context.dp(12)),
            child: Row(
              children: [
                for (var i = 0; i < total; i++) ...[
                  if (i > 0) SizedBox(width: context.dp(4)),
                  Expanded(
                    child: Container(
                      height: context.dp(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: i < index
                            ? theme.primaryDisabled
                            : i == index
                                ? theme.primary
                                : ScSaasThemeTokens.gray100,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Row(
            children: [
              if (index > 0)
                _TextAction(
                  label: l.dugnadTourBack,
                  reduce: reduce,
                  showLeadingChevron: true,
                  onTap: controller.back,
                )
              else
                _TextAction(
                  label: l.dugnadTourSkip,
                  reduce: reduce,
                  onTap: controller.dismiss,
                ),
              const Spacer(),
              _NextButton(
                label: isLast ? l.dugnadTourFinish : l.dugnadTourNext,
                isLast: isLast,
                reduce: reduce,
                onTap: controller.next,
                bg: theme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CloseCircle extends StatelessWidget {
  const _CloseCircle({required this.onTap, required this.label});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: context.dp(26),
          height: context.dp(26),
          decoration: const BoxDecoration(
            color: ScSaasThemeTokens.gray100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.close_rounded,
            size: context.dp(15),
            color: ScSaasThemeTokens.gray500,
          ),
        ),
      ),
    );
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({
    required this.label,
    required this.onTap,
    required this.reduce,
    this.showLeadingChevron = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool reduce;
  final bool showLeadingChevron;

  @override
  Widget build(BuildContext context) {
    final style = aeLabel(color: ScSaasThemeTokens.gray500).copyWith(
      fontSize: context.dp(13.5),
      fontWeight: FontWeight.w800,
    );
    return _PressScale(
      reduce: reduce,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.dp(10), horizontal: context.dp(2)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showLeadingChevron) ...[
              Icon(
                Icons.chevron_left_rounded,
                size: context.dp(16),
                color: ScSaasThemeTokens.gray500,
              ),
              SizedBox(width: context.dp(2)),
            ],
            Text(label, style: style),
          ],
        ),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({
    required this.label,
    required this.isLast,
    required this.onTap,
    required this.reduce,
    required this.bg,
  });

  final String label;
  final bool isLast;
  final VoidCallback onTap;
  final bool reduce;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return _PressScale(
      reduce: reduce,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: context.dp(18), vertical: context.dp(11)),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(context.dp(12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: aeLabel(color: Colors.white).copyWith(
                fontSize: context.dp(14),
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(width: context.dp(5)),
            Icon(
              isLast ? Icons.check_rounded : Icons.chevron_right_rounded,
              size: context.dp(16),
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

/// Scales its child to 0.97 while pressed over 120ms (D3). Instant under reduced
/// motion.
class _PressScale extends StatefulWidget {
  const _PressScale({
    required this.child,
    required this.onTap,
    required this.reduce,
  });

  final Widget child;
  final VoidCallback onTap;
  final bool reduce;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: (_down && !widget.reduce) ? 0.97 : 1.0,
        duration:
            widget.reduce ? Duration.zero : const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}
