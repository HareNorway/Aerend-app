import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../theme/bergen_tokens.dart';
import '../../../theme/lys/lys_palett.dart';
import '../../../theme/lys/modus_scope.dart';
import '../../../ui/kit/ae_haptic.dart';
import '../../common/auth/onboarding_kit.dart' show onbBlur;
import '../../common/home/bergen/bergen_kit.dart' show BergenScale;
import 'bergen_css.dart';

/// Design 21 Nov plan Step 1: the shared pieces the Kasse, the sheets and the fast-order chat are rebuilt from.
///
/// - [AeKnappPille]: the 56 px orange CTA pill (`border-radius:999px`, `0 4px 0 #B8431A` edge; pressing sinks it 3 px).
/// - [AeRadioKort]: a 64 px radio card with a 3D icon tile, title, sub-line and the radio ring (the time slots, the
///   payment methods).
/// - [AeFanePille]: the tab pill with icons and a sliding thumb (Levering / Henting, 42 px).
/// - [AeKollaps]: a row's panel that opens with the design's `grid-template-rows 0fr → 1fr` (.36 s) and fades (.26 s).
/// - [aeSkriver]: true while a text field has focus — no tip, guide or scroll then (design `skriver()`).

/// `cubic-bezier(.2,.9,.3,1)`, the design's easing for panels and cards.
const Curve aeMyk = Cubic(.2, .9, .3, 1);

/// True while the customer types in a text field (the design's `skriver()`): coach marks, the Ægil guide and the
/// idle tips wait, and nothing scrolls the page or takes focus.
bool aeSkriver() {
  final f = FocusManager.instance.primaryFocus;
  if (f == null || !f.hasFocus) return false;
  final ctx = f.context;
  if (ctx == null) return false;
  if (ctx.widget is EditableText || ctx.findAncestorWidgetOfExactType<EditableText>() != null) return true;
  // A field whose focus node sits above its EditableText: the keyboard is the tell.
  return ui.PlatformDispatcher.instance.views.any((v) => v.viewInsets.bottom > 0);
}

// ── the CTA pill ────────────────────────────────────────────────────────────

class AeKnappPille extends StatefulWidget {
  const AeKnappPille({super.key, required this.label, this.onPressed, this.leading, this.trailing, this.expand = true, this.height = 56});

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final Widget? trailing;
  final bool expand;
  final double height;

  @override
  State<AeKnappPille> createState() => _AeKnappPilleState();
}

class _AeKnappPilleState extends State<AeKnappPille> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final enabled = widget.onPressed != null;
    final down = _down || !enabled;
    final lys = context.lys;
    // `--x-kft` in light mode is the fjord-teal pill; dark is the orange glow.
    final grad = lys
        ? cssLinear(180, const [Color(0xFF2B6A7A), Color(0xFF1E4F5C), Color(0xFF174553)], const [0, .58, 1])
        : cssLinear(180, const [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], const [0, .56, 1]);
    final edge = lys ? const Color(0xFF123B46) : const Color(0xFFB8431A);
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTap: aeTrykkTikk(widget.onPressed),
        child: AnimatedContainer(
          duration: BergenTokens.motion(context, const Duration(milliseconds: 140)),
          curve: Curves.easeOut,
          height: widget.height * s,
          transform: Matrix4.translationValues(0, down ? 3 * s : 0, 0),
          padding: EdgeInsets.symmetric(horizontal: 22 * s),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: enabled ? grad : null,
            color: enabled ? null : BergenTokens.inkFaint,
            boxShadow: [
              BoxShadow(color: edge, offset: Offset(0, (down ? 1 : 4) * s)),
              if (!down) BoxShadow(color: rgba(4, 18, 26, .7), offset: Offset(0, 14 * s), blurRadius: onbBlur(22 * s), spreadRadius: -12 * s),
            ],
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            // `inset 0 1.5px 0 rgba(255,255,255,.4)`: the light edge on top of the face.
            border: Border(top: BorderSide(color: rgba(255, 255, 255, lys ? .26 : .4), width: 1.5)),
          ),
          child: Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.leading != null) ...[widget.leading!, SizedBox(width: 8 * s)],
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BergenTokens.display(15 * s, weight: FontWeight.w800, color: Colors.white, letterSpacingEm: -0.01)
                      .copyWith(shadows: [Shadow(color: rgba(120, 40, 10, .4), offset: Offset(0, 1 * s))]),
                ),
              ),
              if (widget.trailing != null) ...[SizedBox(width: 8 * s), widget.trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

// ── the radio card ──────────────────────────────────────────────────────────

/// One choice in a group (`role=radio`, 64 px): a 3D icon tile on the left, title and sub-line, the ring on the right.
/// Selected: mint fill and border with a glow (dark) or `--lys-mint-dis` (light).
class AeRadioKort extends StatelessWidget {
  const AeRadioKort({super.key, required this.valgt, required this.onTap, required this.tittel, this.under, this.ikon, this.flis, this.trailing, this.semanticsKey});

  final bool valgt;
  final VoidCallback onTap;
  final String tittel;
  final String? under;

  /// What sits in the 40 px tile (an icon, a payment mark, a time).
  final Widget? ikon;

  /// A whole 40 px tile of the caller's instead (the payment brands' coloured tiles).
  final Widget? flis;

  /// Replaces the radio ring.
  final Widget? trailing;
  final Key? semanticsKey;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final lys = context.lys;
    final v = valgt;
    final bg = lys
        ? (v ? LysPalett.mintDis : LysPalett.hvit)
        : null;
    final grad = lys
        ? null
        : (v ? cssLinear(180, [rgba(92, 224, 184, .24), rgba(92, 224, 184, .08)]) : cssLinear(180, [rgba(255, 255, 255, .14), rgba(255, 255, 255, .05)]));
    final bd = lys ? (v ? const Color.fromRGBO(11, 107, 87, .4) : LysPalett.kantFarge) : (v ? rgba(127, 240, 203, .75) : rgba(255, 255, 255, .16));
    final shadow = lys
        ? LysPalett.kortskygge.map((c) => BoxShadow(color: c.color, offset: Offset(c.dx * s, c.dy * s), blurRadius: onbBlur(c.blur * s), spreadRadius: c.spread * s)).toList()
        : [
            if (v)
              BoxShadow(color: rgba(92, 224, 184, .7), blurRadius: onbBlur(22 * s), spreadRadius: -6 * s)
            else
              BoxShadow(color: rgba(4, 18, 26, .8), offset: Offset(0, 12 * s), blurRadius: onbBlur(20 * s), spreadRadius: -14 * s),
          ];
    // The tile (`tBg` / `tBd` / `tC`).
    final tBg = lys ? (v ? LysPalett.hvit : LysPalett.dis) : null;
    final tGrad = lys ? null : (v ? cssLinear(160, [rgba(127, 240, 203, .4), rgba(92, 224, 184, .14)]) : cssLinear(160, [rgba(255, 255, 255, .22), rgba(255, 255, 255, .08)]));
    final tBd = lys ? (v ? const Color.fromRGBO(11, 107, 87, .25) : Colors.transparent) : (v ? rgba(127, 240, 203, .5) : rgba(255, 255, 255, .18));
    final tC = lys ? (v ? LysPalett.mintTekst : LysPalett.fjord) : (v ? const Color(0xFF7FF0CB) : Colors.white);
    final ring = lys ? (v ? Colors.transparent : rgba(30, 79, 92, .28)) : (v ? Colors.transparent : rgba(255, 255, 255, .3));
    final tittelC = lys ? LysPalett.tittel : Colors.white;
    final underC = lys ? LysPalett.sekundar : rgba(255, 255, 255, .62);
    return Semantics(
      key: semanticsKey,
      inMutuallyExclusiveGroup: true,
      checked: v,
      selected: v,
      button: true,
      label: tittel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: aeTrykkTikk(onTap),
        child: AnimatedContainer(
          duration: BergenTokens.motion(context, const Duration(milliseconds: 250)),
          curve: Curves.easeOut,
          constraints: BoxConstraints(minHeight: 64 * s),
          padding: EdgeInsets.fromLTRB(10 * s, 10 * s, 14 * s, 10 * s),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20 * s), color: bg, gradient: grad, border: Border.all(color: bd), boxShadow: shadow),
          child: Row(
            children: [
              if (flis != null) ...[flis!, SizedBox(width: 12 * s)],
              if (ikon != null) ...[
                Container(
                  width: 40 * s,
                  height: 40 * s,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13 * s),
                    color: tBg,
                    gradient: tGrad,
                    border: Border.all(color: tBd),
                    boxShadow: lys ? null : [BoxShadow(color: rgba(4, 18, 26, .6), offset: Offset(0, 6 * s), blurRadius: onbBlur(10 * s), spreadRadius: -6 * s)],
                  ),
                  child: IconTheme(data: IconThemeData(color: tC, size: 18 * s), child: DefaultTextStyle(style: TextStyle(color: tC), child: ikon!)),
                ),
                SizedBox(width: 12 * s),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(tittel, maxLines: 1, overflow: TextOverflow.ellipsis, style: BergenTokens.text(13.5 * s, weight: FontWeight.w800, color: tittelC).copyWith(letterSpacing: 13.5 * s * -0.01)),
                    if (under != null) ...[
                      SizedBox(height: 2 * s),
                      Text(under!, maxLines: 2, overflow: TextOverflow.ellipsis, style: BergenTokens.text(11 * s, weight: FontWeight.w600, color: underC)),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 10 * s),
              trailing ??
                  AnimatedContainer(
                    duration: BergenTokens.motion(context, const Duration(milliseconds: 250)),
                    width: 22 * s,
                    height: 22 * s,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: ring, width: 2),
                      gradient: v ? cssLinear(180, const [Color(0xFF7FF0CB), Color(0xFF2FB893)]) : null,
                      boxShadow: v ? [BoxShadow(color: rgba(92, 224, 184, .55), blurRadius: onbBlur(10 * s))] : null,
                    ),
                    child: v ? Icon(Icons.check_rounded, size: 14 * s, color: const Color(0xFF0A2128)) : null,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── the tab pill ────────────────────────────────────────────────────────────

class AeFane {
  const AeFane({required this.label, this.icon, this.key});
  final String label;
  final IconData? icon;
  final Key? key;
}

/// The segmented pill with a sliding thumb (`role=tablist`, 42 px): white/cream thumb on a dark inset track (dark
/// mode), fjord thumb on `--lys-dis-ull` (light).
class AeFanePille extends StatelessWidget {
  const AeFanePille({super.key, required this.faner, required this.valgt, required this.onValg, this.height = 42});

  final List<AeFane> faner;
  final int valgt;
  final ValueChanged<int> onValg;
  final double height;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final lys = context.lys;
    final n = faner.length;
    return Semantics(
      container: true,
      child: Container(
        padding: EdgeInsets.all(4 * s),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: lys ? LysPalett.disUll : null,
          gradient: lys
              ? null
              : LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [rgba(0, 0, 0, .45), rgba(0, 0, 0, .26), rgba(0, 0, 0, .26), rgba(255, 255, 255, .14)], stops: const [0, .16, .96, 1]),
        ),
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth / n;
            return TweenAnimationBuilder<double>(
              tween: Tween<double>(end: valgt.toDouble()),
              duration: BergenTokens.motion(context, const Duration(milliseconds: 380)),
              curve: const Cubic(.34, 1.3, .5, 1),
              builder: (context, t, _) => SizedBox(
                height: height * s,
                child: Stack(
                  children: [
                    Positioned(
                      left: t * w,
                      top: 0,
                      bottom: 0,
                      width: w,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: lys ? cssLinear(180, const [Color(0xFF235E6D), Color(0xFF124A58)]) : cssLinear(180, const [Color(0xFFFFFFFF), Color(0xFFF3EEE2)]),
                          boxShadow: [
                            BoxShadow(color: rgba(4, 18, 26, .8), offset: Offset(0, 8 * s), blurRadius: onbBlur(14 * s), spreadRadius: -8 * s),
                            if (!lys) BoxShadow(color: const Color(0xFFCDB98E), offset: Offset(0, 3 * s)),
                          ],
                        ),
                      ),
                    ),
                    for (var i = 0; i < n; i++)
                      Positioned(
                        left: i * w,
                        top: 0,
                        bottom: 0,
                        width: w,
                        child: _fane(context, i, t, s, lys),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _fane(BuildContext context, int i, double t, double s, bool lys) {
    final f = faner[i];
    // How much of the thumb is under this tab: the label blends from the track colour to the thumb colour.
    final k = (1 - (t - i).abs()).clamp(0.0, 1.0);
    final paa = lys ? Colors.white : const Color(0xFF1E4F5C);
    final av = lys ? LysPalett.fjord : rgba(255, 255, 255, .78);
    final c = Color.lerp(av, paa, k)!;
    return Semantics(
      selected: valgt == i,
      button: true,
      label: f.label,
      child: GestureDetector(
        key: f.key,
        behavior: HitTestBehavior.opaque,
        onTap: aeTrykkTikk(() => onValg(i)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (f.icon != null) ...[Icon(f.icon, size: 15 * s, color: c), SizedBox(width: 7 * s)],
            Text(f.label, style: BergenTokens.text(13.5 * s, weight: FontWeight.w800, color: c)),
          ],
        ),
      ),
    );
  }
}

// ── the collapsible panel ───────────────────────────────────────────────────

/// A panel under a row that opens like the design's `grid-template-rows: 0fr → 1fr` (.36 s, [aeMyk]) with its content
/// fading in over .26 s. Closed, it takes no height. Under reduced motion it snaps.
class AeKollaps extends StatelessWidget {
  const AeKollaps({super.key, required this.aapen, required this.child});

  final bool aapen;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final d = BergenTokens.motion(context, const Duration(milliseconds: 360));
    return ClipRect(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: aapen ? 1 : 0),
        duration: d,
        curve: aeMyk,
        child: child,
        builder: (context, t, child) => Align(
          alignment: Alignment.topCenter,
          heightFactor: t,
          child: Opacity(opacity: (t * 1.4).clamp(0.0, 1.0), child: IgnorePointer(ignoring: t < .999, child: child)),
        ),
      ),
    );
  }
}
