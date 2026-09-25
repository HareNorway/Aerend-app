import 'package:flutter/material.dart';

import '../../../theme/bergen_tokens.dart';

/// What the drag handle says (design `.ark-handle` states).
enum BergenSheetHandle {
  /// Peeking above the hero: "Alle butikker og varer".
  browse('Alle butikker og varer'),

  /// Dragged past the threshold: "Slipp — Ægil åpner".
  release('Slipp — Ægil åpner'),

  /// Fully open: "Lukk vinduet".
  close('Lukk vinduet');

  const BergenSheetHandle(this.label);

  final String label;
}

/// The draggable bottom sheet panel (design `.ark`): rounded top, a handle
/// with a state-dependent caption, and a body slot. Embed it in a screen
/// through [BergenSheet.draggable], or present it modally with
/// [showBergenSheet].
class BergenSheet extends StatelessWidget {
  const BergenSheet({
    super.key,
    required this.child,
    this.handle = BergenSheetHandle.close,
    this.onHandleTap,
    this.onDark = false,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 16),
  });

  final Widget child;
  final BergenSheetHandle handle;
  final VoidCallback? onHandleTap;

  /// Teal glass (the Hjem sheet) instead of paper.
  final bool onDark;
  final EdgeInsetsGeometry padding;

  /// A [DraggableScrollableSheet] whose panel is a [BergenSheet]; the handle
  /// caption follows the extent through [handleFor] (default:
  /// [defaultHandleFor]).
  static Widget draggable({
    required Widget Function(BuildContext context, ScrollController controller)
    body,
    double initialChildSize = .28,
    double minChildSize = .28,
    double maxChildSize = .92,
    bool onDark = false,
    BergenSheetHandle Function(double extent)? handleFor,
  }) {
    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      snap: true,
      builder: (context, controller) => _ExtentListener(
        initialExtent: initialChildSize,
        builder: (context, extent) => BergenSheet(
          onDark: onDark,
          handle: (handleFor ??
              (e) => defaultHandleFor(e, minChildSize, maxChildSize))(extent),
          padding: EdgeInsets.zero,
          child: body(context, controller),
        ),
      ),
    );
  }

  /// Below a third of the travel: browse; above 85 %: close; between: release.
  static BergenSheetHandle defaultHandleFor(
    double extent,
    double min,
    double max,
  ) {
    final t = max == min ? 1.0 : ((extent - min) / (max - min)).clamp(0.0, 1.0);
    if (t < .33) return BergenSheetHandle.browse;
    if (t < .85) return BergenSheetHandle.release;
    return BergenSheetHandle.close;
  }

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.vertical(
      top: Radius.circular(BergenTokens.radiusSheet),
    );
    final fg = onDark ? Colors.white : BergenTokens.inkSecondary;

    return ClipRRect(
      borderRadius: radius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onDark ? BergenTokens.screen : null,
          color: onDark ? null : BergenTokens.paper,
          border: Border(
            top: BorderSide(
              color: onDark ? BergenTokens.glassBorder : BergenTokens.paperWarm,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              button: onHandleTap != null,
              label: handle.label,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onHandleTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: fg.withValues(alpha: .35),
                          borderRadius: BorderRadius.circular(
                            BergenTokens.radiusChip,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedSwitcher(
                        duration: BergenTokens.motion(
                          context,
                          BergenTokens.motionFast,
                        ),
                        child: Text(
                          handle.label,
                          key: ValueKey(handle),
                          style: BergenTokens.text(
                            BergenTokens.textMicro,
                            weight: FontWeight.w700,
                            color: fg,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // The body sizes itself; tall bodies scroll (BergenArk does).
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

/// Tracks the sheet extent from [DraggableScrollableNotification]s.
class _ExtentListener extends StatefulWidget {
  const _ExtentListener({required this.initialExtent, required this.builder});

  final double initialExtent;
  final Widget Function(BuildContext context, double extent) builder;

  @override
  State<_ExtentListener> createState() => _ExtentListenerState();
}

class _ExtentListenerState extends State<_ExtentListener> {
  late double _extent = widget.initialExtent;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (n) {
        if (n.extent != _extent) setState(() => _extent = n.extent);
        return false;
      },
      child: Builder(builder: (ctx) => widget.builder(ctx, _extent)),
    );
  }
}

/// Present a [BergenSheet] modally. Scroll-controlled so tall content can
/// grow to [maxHeightFraction] of the screen.
Future<T?> showBergenSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  BergenSheetHandle handle = BergenSheetHandle.close,
  bool onDark = false,
  double maxHeightFraction = .92,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: BergenTokens.tealNight.withValues(alpha: .55),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * maxHeightFraction,
    ),
    sheetAnimationStyle: AnimationStyle(
      curve: BergenTokens.motionCurve,
      duration: BergenTokens.motion(context, BergenTokens.motionSheet),
      reverseCurve: Curves.easeIn,
      reverseDuration: BergenTokens.motion(context, BergenTokens.motionBase),
    ),
    builder: (ctx) => SafeArea(
      top: false,
      child: BergenSheet(
        handle: handle,
        onDark: onDark,
        onHandleTap: () => Navigator.of(ctx).maybePop(),
        child: builder(ctx),
      ),
    ),
  );
}
