import 'dart:async';

import 'package:flutter/material.dart';

import '../../../theme/bergen_tokens.dart';

/// The Bergen toast (design `.toast`): a dark pill near the bottom that fades
/// in, holds for [BergenTokens.motionToast], and fades out. One at a time.
class BergenToast extends StatelessWidget {
  const BergenToast({super.key, required this.message, this.icon, this.angre, this.angreTekst = 'Angre'});

  final String message;
  final IconData? icon;

  /// The design's undo (`kSi(tx, angre)`): a mint «Angre» at the end.
  final VoidCallback? angre;
  final String angreTekst;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: BergenTokens.tealNight.withValues(alpha: .94),
            borderRadius: BorderRadius.circular(BergenTokens.radiusButton),
            border: Border.all(color: BergenTokens.glassBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x330F1F2B),
                offset: Offset(0, 8),
                blurRadius: 18,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: BergenTokens.mint),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  message,
                  style: BergenTokens.text(
                    BergenTokens.textBody,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              if (angre != null) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  key: const Key('bergen-toast-angre'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    hideBergenToast();
                    angre!();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(angreTekst, style: BergenTokens.text(BergenTokens.textBody, weight: FontWeight.w800, color: BergenTokens.mint)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

OverlayEntry? _current;

/// Show a [BergenToast] over everything. Replaces any toast still showing.
void showBergenToast(
  BuildContext context,
  String message, {
  IconData? icon,
  Duration? duration,
  VoidCallback? angre,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  _current?.remove();
  _current = null;

  final hold = duration ?? BergenTokens.motionToast;
  final fade = BergenTokens.motion(context, BergenTokens.motionBase);

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => _ToastHost(
      fade: fade,
      hold: hold,
      onDone: () {
        if (_current == entry) _current = null;
        entry.remove();
      },
      tappable: angre != null,
      child: BergenToast(message: message, icon: icon, angre: angre),
    ),
  );
  _current = entry;
  overlay.insert(entry);
}

/// Remove the toast immediately (tests, screen changes).
void hideBergenToast() {
  _current?.remove();
  _current = null;
}

class _ToastHost extends StatefulWidget {
  const _ToastHost({
    required this.fade,
    required this.hold,
    required this.onDone,
    required this.child,
    this.tappable = false,
  });

  final bool tappable;
  final Duration fade;
  final Duration hold;
  final VoidCallback onDone;
  final Widget child;

  @override
  State<_ToastHost> createState() => _ToastHostState();
}

class _ToastHostState extends State<_ToastHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.fade,
  );
  bool _done = false;
  Timer? _hold;

  @override
  void initState() {
    super.initState();
    _c.forward();
    _hold = Timer(widget.hold, () async {
      if (!mounted || _done) return;
      await _c.reverse();
      if (!mounted || _done) return;
      _done = true;
      widget.onDone();
    });
  }

  @override
  void dispose() {
    _done = true;
    _hold?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 96;
    return Positioned(
      left: 16,
      right: 16,
      bottom: bottom,
      child: IgnorePointer(
        ignoring: !widget.tappable,
        child: FadeTransition(
          opacity: _c,
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}
