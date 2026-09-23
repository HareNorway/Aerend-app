import 'dart:math' as math;
import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../commonView/customCountryCodePicker/custom_country_code_picker.dart';
import '../../../commonView/customCountryCodePicker/selection_dialog.dart';
import '../splash/splash_sticker_painter.dart';
import 'onboarding_copy.dart';

// ── Ærend Bergen onboarding kit ─────────────────────────────────────────────
// Shared pieces of `data-screen-label="Onboarding"` in
// `Design/Ærend Kunde Bergen (frittstående).html`: the persistent sea surface,
// the step ladder ("stige"), Ægil + speech bubble, the orange CTA, white
// label fields, segmented tabs and the design's entrance keyframes. All sizes
// are the design's CSS px.

// ── Tokens ──────────────────────────────────────────────────────────────────

abstract final class OnbColors {
  static const Color base = Color(0xFF2F6270);
  static const Color navy = Color(0xFF0F1F2B);
  static const Color ink = Color(0xFF23201D);
  static const Color subtitle = Color(0xFFDCE9EC);
  static const Color orange = Color(0xFFF26D3D);
  static const Color orangeLight = Color(0xFFF9A273);
  static const Color mint = Color(0xFF5CE0B8);
  static const Color mintDeep = Color(0xFF2FB893);
  static const Color mintText = Color(0xFF9FE0C8);
  static const Color fieldLabel = Color(0xFF9A9188);
  static const Color cardSub = Color(0xFF7A736A);
  static const Color chevron = Color(0xFFB9AF9C);
  static const Color error = Color(0xFFE9573A);
  static const Color placeholder = Color(0xFFA9A9A9);

  /// Field accent bar when a value is not yet valid.
  static const Color accentIdle = Color(0x1F23201D);
}

/// `linear-gradient(180deg,#F9A273,#F26D3D 56%,#DD5A25)` — the orange CTA.
const LinearGradient kOnbCtaGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)],
  stops: [0, .56, 1],
);

/// `linear-gradient(180deg,#FF7A45,#F1591F 60%,#D9450F)` — Vipps + tab thumb.
const LinearGradient kOnbVippsGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFFFF7A45), Color(0xFFF1591F), Color(0xFFD9450F)],
  stops: [0, .6, 1],
);

/// `linear-gradient(180deg,rgba(255,255,255,.16),rgba(255,255,255,.08))` —
/// the CTA while its step isn't complete yet.
const LinearGradient kOnbCtaIdleGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0x29FFFFFF), Color(0x14FFFFFF)],
);

/// The white "paper" shadow every white card/field/bubble carries:
/// `0 2px 0 rgba(180,171,160,.8), 0 14px 24px -14px rgba(3,16,24,.9)`.
List<BoxShadow> onbPaperShadow({
  double y = 14,
  double blur = 24,
  double spread = -14,
  double lip = .8,
}) => [
  BoxShadow(
    color: Color.fromRGBO(180, 171, 160, lip),
    offset: const Offset(0, 2),
  ),
  BoxShadow(
    color: const Color.fromRGBO(3, 16, 24, .9),
    offset: Offset(0, y),
    blurRadius: onbBlur(blur),
    spreadRadius: spread,
  ),
];

/// CSS box-shadow blur length → Flutter `blurRadius` (CSS σ = blur / 2).
double onbBlur(double cssBlur) =>
    cssBlur <= 0 ? 0 : math.max(0, (cssBlur / 2 - .5) / .57735);

TextStyle onbDisplay(
  double size, {
  FontWeight weight = FontWeight.w800,
  double letterSpacingEm = 0,
  double? height,
  Color color = Colors.white,
}) => GoogleFonts.plusJakartaSans(
  fontSize: size,
  fontWeight: weight,
  letterSpacing: size * letterSpacingEm,
  height: height,
  color: color,
);

TextStyle onbText(
  double size, {
  FontWeight weight = FontWeight.w600,
  double letterSpacingEm = 0,
  double? height,
  Color color = Colors.white,
  TextDecoration? decoration,
}) => GoogleFonts.inter(
  fontSize: size,
  fontWeight: weight,
  letterSpacing: size * letterSpacingEm,
  height: height,
  color: color,
  decoration: decoration,
  decorationColor: color,
);

// ── Keyframe helpers (same maths as the splash) ─────────────────────────────

/// Progress of a one-shot CSS animation with `fill-mode: both`.
double onbP(double t, double delayMs, double durMs) =>
    ((t - delayMs) / durMs).clamp(0.0, 1.0);

/// Progress of an `infinite` CSS animation; null before its delay (no fill).
double? onbLoop(
  double t,
  double delayMs,
  double durMs, {
  bool reverse = false,
}) {
  final elapsed = t - delayMs;
  if (elapsed < 0) return null;
  final p = (elapsed / durMs) % 1.0;
  return reverse ? 1 - p : p;
}

/// A keyframed property with the timing function applied per segment.
double onbKf(double p, List<double> stops, List<double> values, Curve curve) {
  if (p <= stops.first) return values.first;
  for (var i = 1; i < stops.length; i++) {
    if (p <= stops[i]) {
      final a = stops[i - 1];
      final b = stops[i];
      final local = b == a ? 1.0 : (p - a) / (b - a);
      return lerpDouble(values[i - 1], values[i], curve.transform(local))!;
    }
  }
  return values.last;
}

double _o(double v) => v.clamp(0.0, 1.0);
double _rad(double deg) => deg * math.pi / 180;

/// Blur that doesn't clamp at the edges (CSS `filter: blur()`).
Widget onbBlurred(double cssBlur, Widget child) => ImageFiltered(
  imageFilter: ImageFilter.blur(
    sigmaX: cssBlur,
    sigmaY: cssBlur,
    tileMode: TileMode.decal,
  ),
  child: child,
);

// ── Clocks ──────────────────────────────────────────────────────────────────

/// Plays once from mount and hands [builder] the elapsed ms.
class OnbTimeline extends StatefulWidget {
  const OnbTimeline({
    super.key,
    required this.durationMs,
    required this.builder,
    this.child,
  });

  final double durationMs;
  final Widget Function(BuildContext context, double t, Widget? child) builder;
  final Widget? child;

  @override
  State<OnbTimeline> createState() => _OnbTimelineState();
}

class _OnbTimelineState extends State<OnbTimeline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.durationMs.round()),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else if (!_c.isAnimating && _c.value == 0) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    child: widget.child,
    builder: (context, child) =>
        widget.builder(context, _c.value * widget.durationMs, child),
  );
}

/// Ticks forever. With [shared], every instance reads one app-wide clock, so
/// the sea surface keeps drifting seamlessly from one onboarding step to the
/// next (the design's surface is a single persistent layer).
class OnbLoopClock extends StatefulWidget {
  const OnbLoopClock({
    super.key,
    required this.builder,
    this.shared = false,
    this.child,
  });

  final Widget Function(BuildContext context, double t, Widget? child) builder;
  final bool shared;
  final Widget? child;

  static final Stopwatch _app = Stopwatch()..start();

  @override
  State<OnbLoopClock> createState() => _OnbLoopClockState();
}

class _OnbLoopClockState extends State<OnbLoopClock>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _t = ValueNotifier<double>(0);
  final Stopwatch _local = Stopwatch()..start();

  double get _now =>
      (widget.shared ? OnbLoopClock._app : _local).elapsedMicroseconds / 1000.0;

  @override
  void initState() {
    super.initState();
    _t.value = _now;
    _ticker = createTicker((_) => _t.value = _now);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce && _ticker.isActive) _ticker.stop();
    if (!reduce && !_ticker.isActive) _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
    valueListenable: _t,
    child: widget.child,
    builder: (context, t, child) => widget.builder(context, t, child),
  );
}

// ── Entrance animations ─────────────────────────────────────────────────────

/// `onbInn` — each step's content slides in 26px from the right.
class OnbEnter extends StatelessWidget {
  const OnbEnter({super.key, required this.child});

  final Widget child;

  static const Cubic _curve = Cubic(.2, .9, .3, 1);

  @override
  Widget build(BuildContext context) => OnbTimeline(
    durationMs: 320,
    child: child,
    builder: (context, t, child) {
      final p = _curve.transform(onbP(t, 0, 320));
      return Opacity(
        opacity: _o(p),
        child: Transform.translate(
          offset: Offset(26 * (1 - p), 0),
          child: child,
        ),
      );
    },
  );
}

/// `spOpp` — fade + rise 12px.
class OnbRise extends StatelessWidget {
  const OnbRise({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.durationMs = 450,
  });

  final Widget child;
  final double delayMs;
  final double durationMs;

  @override
  Widget build(BuildContext context) => OnbTimeline(
    durationMs: delayMs + durationMs,
    child: child,
    builder: (context, t, child) {
      final p = Curves.easeOut.transform(onbP(t, delayMs, durationMs));
      return Opacity(
        opacity: _o(p),
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - p)),
          child: child,
        ),
      );
    },
  );
}

/// `onbBoble` — Ægil's row pops up (translateY 8 → 0, scale .92 → 1).
class OnbBubbleIn extends StatelessWidget {
  const OnbBubbleIn({super.key, required this.child, this.delayMs = 0});

  final Widget child;
  final double delayMs;

  static const Cubic _curve = Cubic(.2, 1.1, .4, 1);

  @override
  Widget build(BuildContext context) => OnbTimeline(
    durationMs: delayMs + 500,
    child: child,
    builder: (context, t, child) {
      final p = _curve.transform(onbP(t, delayMs, 500));
      return Opacity(
        opacity: _o(p),
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - p)),
          child: Transform.scale(scale: .92 + .08 * p, child: child),
        ),
      );
    },
  );
}

/// `spChipA/B/C` and `klistre` — a sticker slapped down: big + tilted →
/// overshoot → settles tilted. Keyframes at 0 / 55 / 75 / 100%.
class OnbSlap extends StatelessWidget {
  const OnbSlap({
    super.key,
    required this.child,
    required this.scales,
    required this.degs,
    this.delayMs = 0,
    this.durationMs = 450,
    this.curve = const Cubic(.2, 1.1, .4, 1),
  });

  /// `spChipA`: scales [1.7, .96, 1.03, 1], degs [-14, -4, -6.5, -6].
  /// `klistre`: scales [1.5, .97, 1.03, 1], degs [-14, -4, -6, -5].
  final List<double> scales;
  final List<double> degs;
  final Widget child;
  final double delayMs;
  final double durationMs;
  final Curve curve;

  @override
  Widget build(BuildContext context) => OnbTimeline(
    durationMs: delayMs + durationMs,
    child: child,
    builder: (context, t, child) {
      final p = onbP(t, delayMs, durationMs);
      const stops = [0.0, .55, .75, 1.0];
      final s = onbKf(p, stops, scales, curve);
      final r = onbKf(p, stops, degs, curve);
      final o = onbKf(p, const [0, .55, 1], const [0, 1, 1], curve);
      return Opacity(
        opacity: _o(o),
        child: Transform.rotate(
          angle: _rad(r),
          child: Transform.scale(scale: s, child: child),
        ),
      );
    },
  );
}

/// `onbHake` — a tick popping in: scale 0 → 1.25 → 1, −30° → 4° → 0°.
class OnbHake extends StatelessWidget {
  const OnbHake({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.durationMs = 380,
  });

  final Widget child;
  final double delayMs;
  final double durationMs;

  static const Cubic _curve = Cubic(.34, 1.56, .64, 1);

  @override
  Widget build(BuildContext context) => OnbTimeline(
    durationMs: delayMs + durationMs,
    child: child,
    builder: (context, t, child) {
      final p = onbP(t, delayMs, durationMs);
      const stops = [0.0, .6, 1.0];
      final s = onbKf(p, stops, const [0, 1.25, 1], _curve);
      final r = onbKf(p, stops, const [-30, 4, 0], _curve);
      final o = onbKf(p, stops, const [0, 1, 1], _curve);
      return Opacity(
        opacity: _o(o),
        child: Transform.rotate(
          angle: _rad(r),
          child: Transform.scale(scale: math.max(0, s), child: child),
        ),
      );
    },
  );
}

/// `onbRist` — horizontal shake whenever [trigger] changes.
class OnbShake extends StatefulWidget {
  const OnbShake({super.key, required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  State<OnbShake> createState() => _OnbShakeState();
}

class _OnbShakeState extends State<OnbShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  @override
  void didUpdateWidget(OnbShake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    child: widget.child,
    builder: (context, child) {
      final dx = onbKf(
        _c.value,
        const [0, .2, .4, .6, .8, 1],
        const [0, -7, 6, -4, 3, 0],
        Curves.easeInOut,
      );
      return Transform.translate(offset: Offset(dx, 0), child: child);
    },
  );
}

// ── Pressables ──────────────────────────────────────────────────────────────

/// `style-active` — pushes down [pressDy] px (or scales to [pressScale])
/// while held, 140ms ease.
class OnbPressable extends StatefulWidget {
  const OnbPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.pressDy = 3,
    this.pressScale,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressDy;
  final double? pressScale;

  @override
  State<OnbPressable> createState() => _OnbPressableState();
}

class _OnbPressableState extends State<OnbPressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null || _down == v) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    Widget child = widget.child;
    if (widget.pressScale != null) {
      child = AnimatedScale(
        scale: _down ? widget.pressScale! : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.ease,
        child: child,
      );
    } else {
      child = AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.ease,
        transform: Matrix4.translationValues(0, _down ? widget.pressDy : 0, 0),
        child: child,
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      child: child,
    );
  }
}

/// CSS `inset 0 <h>px 0 rgba(255,255,255,<a>)` — a highlight line along the
/// top inner edge, clipped by the parent's radius.
class _InsetTop extends StatelessWidget {
  const _InsetTop({required this.radius, this.height = 1.5, this.alpha = .4});

  final double radius;
  final double height;
  final double alpha;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: IgnorePointer(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: ColoredBox(color: Colors.white.withValues(alpha: alpha)),
          ),
        ),
      ),
    ),
  );
}

/// The orange primary CTA. While [ready] is false it shows the design's
/// translucent idle look but stays tappable, so the screen can explain what
/// is missing (the design's toast / shake).
class OnbCta extends StatelessWidget {
  const OnbCta({
    super.key,
    required this.label,
    required this.onTap,
    this.ready = true,
    this.loading = false,
    this.height = 54,
    this.fontSize = 15.5,
    this.dropY = 18,
    this.dropBlur = 28,
    this.dropSpread = -14,
    this.trailing,
    this.pulse = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool ready;
  final bool loading;
  final double height;
  final double fontSize;
  final double dropY;
  final double dropBlur;
  final double dropSpread;
  final Widget? trailing;

  /// `onbPuls` — mint ring pulsing out from the button (Ferdig).
  final bool pulse;

  static const double _r = 18;

  @override
  Widget build(BuildContext context) {
    final shadows = ready
        ? [
            const BoxShadow(color: Color(0xFFC4491A), offset: Offset(0, 2)),
            BoxShadow(
              color: const Color.fromRGBO(200, 70, 25, .95),
              offset: Offset(0, dropY),
              blurRadius: onbBlur(dropBlur),
              spreadRadius: dropSpread,
            ),
          ]
        : const <BoxShadow>[];
    Widget button = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.ease,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_r),
        gradient: ready ? kOnbCtaGradient : kOnbCtaIdleGradient,
        boxShadow: shadows,
      ),
      child: Stack(
        children: [
          _InsetTop(
            radius: _r,
            height: ready ? 1.5 : 1,
            alpha: ready ? .4 : .2,
          ),
          Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label, style: onbDisplay(fontSize)),
                      if (trailing != null) ...[
                        const SizedBox(width: 9),
                        trailing!,
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
    if (pulse) button = _OnbPulse(radius: _r, child: button);
    return OnbPressable(onTap: loading ? null : onTap, child: button);
  }
}

class _OnbPulse extends StatelessWidget {
  const _OnbPulse({required this.child, required this.radius});

  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) => OnbLoopClock(
    child: child,
    builder: (context, t, child) {
      final p = onbLoop(t, 1200, 2400);
      if (p == null) return child!;
      final spread = onbKf(
        p,
        const [0, .7, 1],
        const [0, 14, 0],
        Curves.easeOut,
      );
      final a = onbKf(p, const [0, .7, 1], const [.55, 0, .55], Curves.easeOut);
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: OnbColors.mint.withValues(alpha: _o(a)),
              spreadRadius: spread,
            ),
          ],
        ),
        child: child,
      );
    },
  );
}

/// A quiet centred text link ("Avvis", "Tilbake", …).
class OnbTextLink extends StatelessWidget {
  const OnbTextLink({
    super.key,
    required this.label,
    required this.onTap,
    this.color = const Color(0x80FFFFFF),
    this.size = 12.5,
    this.underline = false,
  });

  final String label;
  final VoidCallback? onTap;
  final Color color;
  final double size;
  final bool underline;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: onbText(
          size,
          weight: FontWeight.w800,
          color: color,
          decoration: underline ? TextDecoration.underline : null,
        ),
      ),
    ),
  );
}

// ── Icons (the design's inline SVGs) ────────────────────────────────────────

abstract final class OnbIcons {
  static String _stroke(String color, double width, String body) =>
      '<svg viewBox="0 0 24 24" fill="none" stroke="$color" '
      'stroke-width="$width" stroke-linecap="round" stroke-linejoin="round">'
      '$body</svg>';

  static String check(String color, double width) =>
      _stroke(color, width, '<path d="M20 7L9 18l-5-5"/>');
  static String chevronRight(String color) =>
      _stroke(color, 2.6, '<path d="M9 5l7 7-7 7"/>');
  static String chevronLeft(String color) =>
      _stroke(color, 2.6, '<path d="M15 6l-6 6 6 6"/>');
  static final String doc = _stroke(
    '#FFFFFF',
    2,
    '<path d="M7 3h10v18l-5-2.5L7 21z"/><path d="M10 8h4M10 12h4"/>',
  );
  static final String shield = _stroke(
    '#0F1F2B',
    2,
    '<path d="M12 3l7 3v6c0 4.2-2.9 7.9-7 9-4.1-1.1-7-4.8-7-9V6z"/>',
  );
  static final String user = _stroke(
    '#9A9188',
    2,
    '<circle cx="12" cy="8" r="3.6"/>'
        '<path d="M4.5 20c1.2-3.8 4-5.8 7.5-5.8s6.3 2 7.5 5.8"/>',
  );
  static final String mail = _stroke(
    '#9A9188',
    2,
    '<rect x="3" y="5.5" width="18" height="13" rx="3"/>'
        '<path d="M4 8l8 5.5L20 8"/>',
  );
  static final String lock = _stroke(
    '#9A9188',
    2,
    '<rect x="4" y="10.5" width="16" height="10" rx="3"/>'
        '<path d="M8 10.5V8a4 4 0 0 1 8 0v2.5"/>',
  );
  static final String search = _stroke(
    '#F9A273',
    2.4,
    '<circle cx="11" cy="11" r="7"/><path d="M16.5 16.5L21 21"/>',
  );
  static final String pencil = _stroke(
    '#F9A273',
    2.2,
    '<path d="M4 20l5-1 10-10-4-4L5 15z"/>',
  );
  static final String arrowOut = _stroke(
    '#FFFFFF',
    2.8,
    '<path d="M5 19L19 5M11 5h8v8"/>',
  );

  static Widget of(String svg, double size) =>
      SvgPicture.string(svg, width: size, height: size);
}

// ── Surface ─────────────────────────────────────────────────────────────────

/// `Overflate · onboarding` — the teal sea with drifting light, slow rings,
/// vignette and a darker floor. One shared clock keeps it continuous across
/// the onboarding routes.
class OnbSurface extends StatelessWidget {
  const OnbSurface({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final w = box.maxWidth;
      final h = box.maxHeight;
      return OnbLoopClock(
        shared: true,
        builder: (context, t, _) => Stack(
          fit: StackFit.expand,
          children: [
            const CustomPaint(
              painter: SplashRadialPainter(
                center: Offset(.5, .22),
                radii: Offset(1.1, .7),
                colors: [
                  Color(0xFF3A7080),
                  Color(0xFF2F6270),
                  Color(0xFF1F4A56),
                ],
                stops: [0, .45, 1],
              ),
            ),
            _blob(
              t,
              left: -.2 * w,
              top: -.1 * h,
              width: .8 * w,
              height: .5 * h,
              color: const Color(0x24FFFFFF),
              blur: 28,
              p: onbLoop(t, 0, 17000)!,
            ),
            _blob(
              t,
              left: .5 * w,
              top: .22 * h,
              width: .75 * w,
              height: .44 * h,
              color: const Color.fromRGBO(120, 200, 190, .16),
              blur: 30,
              p: onbLoop(t, -9000, 23000, reverse: true)!,
            ),
            CustomPaint(painter: _RingsPainter(t)),
            const CustomPaint(
              painter: SplashRadialPainter(
                center: Offset(.5, .2),
                radii: Offset(1.2, .8),
                colors: [
                  Color(0x00081A24),
                  Color(0x00081A24),
                  Color.fromRGBO(8, 26, 36, .45),
                ],
                stops: [0, .45, 1],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: h * .42,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.fromRGBO(15, 31, 43, 0),
                      Color.fromRGBO(15, 31, 43, .62),
                      Color.fromRGBO(15, 31, 43, .86),
                    ],
                    stops: [0, .65, 1],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget _blob(
    double t, {
    required double left,
    required double top,
    required double width,
    required double height,
    required Color color,
    required double blur,
    required double p,
  }) {
    const stops = [0.0, .5, 1.0];
    final dx = onbKf(p, stops, const [0, 14, 0], Curves.easeInOut);
    final dy = onbKf(p, stops, const [0, -10, 0], Curves.easeInOut);
    final s = onbKf(p, stops, const [1, 1.06, 1], Curves.easeInOut);
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.translationValues(dx, dy, 0)
          ..multiply(Matrix4.diagonal3Values(s, s, 1)),
        child: onbBlurred(
          blur,
          CustomPaint(
            painter: SplashRadialPainter(
              center: const Offset(.5, .5),
              radii: const Offset(.5, .5),
              colors: [color, color.withValues(alpha: 0)],
              stops: const [0, .7],
              oval: true,
            ),
          ),
        ),
      ),
    );
  }
}

/// `onbRing` — four ellipses slowly swelling out of the water.
class _RingsPainter extends CustomPainter {
  _RingsPainter(this.t);

  final double t;

  // (cx%, cy%, w, h, stroke, alpha, durMs, delayMs)
  static const _rings = <List<double>>[
    [.5, .38, 300, 110, 1.5, .55, 9000, 0],
    [.5, .38, 300, 110, 1, .45, 9000, 1100],
    [.22, .72, 180, 64, 1, .4, 12000, 5000],
    [.82, .16, 140, 50, 1, .4, 14000, 7500],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final r in _rings) {
      final p = onbLoop(t, r[7], r[6]);
      double scale = 1, opacity = 1; // before its delay: un-animated style
      if (p != null) {
        scale = onbKf(
          p,
          const [0, .12, 1],
          const [.55, .55, 1.9],
          Curves.easeOut,
        );
        opacity = onbKf(
          p,
          const [0, .12, .18, .6, 1],
          const [0, 0, .5, .18, 0],
          Curves.easeOut,
        );
      }
      if (opacity <= 0) continue;
      final c = Offset(size.width * r[0], size.height * r[1]);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r[4]
        ..color = Colors.white.withValues(alpha: r[5] * _o(opacity));
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.scale(scale);
      // CSS border sits inside the box.
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: r[2] - r[4],
          height: r[3] - r[4],
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.t != t;
}

// ── Scaffold + step ladder ──────────────────────────────────────────────────

/// Top inset of step content: the design's `padding-top: 64px` sits under
/// the ladder; on device the ladder also clears the status bar.
double onbTopInset(BuildContext context) =>
    MediaQuery.paddingOf(context).top + 52;

/// Full-bleed onboarding page: surface, optional [step] ladder, [child].
class OnbScaffold extends StatelessWidget {
  const OnbScaffold({
    super.key,
    required this.child,
    this.step,
    this.overlay = const [],
  });

  final Widget child;

  /// 0 Vilkår · 1 Konto · 2 Nummer · 3 Klar. Null hides the ladder.
  final int? step;
  final List<Widget> overlay;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: OnbColors.base,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(child: OnbSurface()),
            Positioned.fill(child: child),
            if (step != null)
              Positioned(
                left: 14,
                right: 14,
                top: MediaQuery.paddingOf(context).top + 4,
                child: OnbStepLadder(index: step!),
              ),
            ...overlay,
          ],
        ),
      ),
    );
  }
}

/// `onbStige` — Vilkår · Konto · Nummer · Klar.
class OnbStepLadder extends StatelessWidget {
  const OnbStepLadder({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final names = OnbCopy.ladder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 7),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(8, 26, 36, .42),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x29FFFFFF)),
          ),
          child: OnbTimeline(
            durationMs: 800,
            builder: (context, t, _) => Row(
              children: [
                for (var i = 0; i < names.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(child: _item(i, names[i], t)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(int i, String name, double t) {
    final done = i < index;
    final active = i == index;
    final nodeGradient = done
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF7FF0CB), OnbColors.mintDeep],
          )
        : active
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [OnbColors.orangeLight, OnbColors.orange],
          )
        : null;
    final nodeShadow = active
        ? [
            BoxShadow(
              color: OnbColors.orange.withValues(alpha: .28),
              spreadRadius: 3,
            ),
            BoxShadow(
              color: OnbColors.orange.withValues(alpha: .9),
              offset: const Offset(0, 6),
              blurRadius: onbBlur(12),
              spreadRadius: -6,
            ),
          ]
        : done
        ? [
            BoxShadow(
              color: OnbColors.mintDeep.withValues(alpha: .9),
              offset: const Offset(0, 4),
              blurRadius: onbBlur(10),
              spreadRadius: -6,
            ),
          ]
        : const <BoxShadow>[];
    // onbNode .5s cubic(.34,1.56,.64,1) on the active node.
    final nodeScale = active
        ? onbKf(
            onbP(t, 0, 500),
            const [0, .6, 1],
            const [.6, 1.18, 1],
            const Cubic(.34, 1.56, .64, 1),
          )
        : 1.0;
    // onbBar .5s (i × 60ms) for every bar up to the active one.
    final barFill = i <= index
        ? const Cubic(.3, .9, .3, 1).transform(onbP(t, i * 60.0, 500))
        : 0.0;
    final fill = done
        ? const LinearGradient(colors: [OnbColors.mint, OnbColors.mintDeep])
        : const LinearGradient(
            colors: [OnbColors.orangeLight, OnbColors.orange],
          );
    final labelColor = done
        ? OnbColors.mintText
        : active
        ? Colors.white
        : const Color(0x66FFFFFF);

    return Row(
      children: [
        Transform.scale(
          scale: nodeScale,
          child: Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: nodeGradient,
              color: nodeGradient == null ? const Color(0x1AFFFFFF) : null,
              border: nodeGradient == null
                  ? Border.all(color: const Color(0x2EFFFFFF))
                  : null,
              boxShadow: nodeShadow,
            ),
            child: done
                ? OnbIcons.of(OnbIcons.check('#0F1F2B', 4), 11)
                : Text(
                    '${i + 1}',
                    style: onbText(
                      9.5,
                      weight: FontWeight.w800,
                      color: active ? Colors.white : const Color(0x80FFFFFF),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: onbText(
                  9,
                  weight: FontWeight.w800,
                  letterSpacingEm: .03,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 3),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: SizedBox(
                  height: 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const ColoredBox(color: Color(0x24FFFFFF)),
                      if (i <= index)
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: barFill,
                          child: DecoratedBox(
                            decoration: BoxDecoration(gradient: fill),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Ægil ────────────────────────────────────────────────────────────────────

abstract final class OnbAegil {
  static const String landing = 'assets/images/aegil/aegil_landing.png';
  static const String invite = 'assets/images/aegil/aegil_invite.png';
  static const String terms = 'assets/images/aegil/aegil_terms.png';
  static const String account = 'assets/images/aegil/aegil_account.png';
  static const String phone = 'assets/images/aegil/aegil_phone.png';
  static const String code = 'assets/images/aegil/aegil_code.png';
  static const String done = 'assets/images/aegil/aegil_done.png';
}

/// Ægil's rounded portrait with the white ring, bobbing (`onbBaat`) over a
/// breathing shadow (`onbKjol`).
class AegilAvatar extends StatelessWidget {
  const AegilAvatar({
    super.key,
    required this.asset,
    required this.size,
    required this.radius,
    this.floorShadow = true,
    this.bob = true,
    this.ringDropY = 12,
    this.ringDropBlur = 20,
  });

  final String asset;
  final double size;
  final double radius;
  final bool floorShadow;
  final bool bob;
  final double ringDropY;
  final double ringDropBlur;

  @override
  Widget build(BuildContext context) {
    final big = size >= 80;
    // Floor shadow box per design: 58→46×10 @6, 54→44×10 @5, 96→72×14 @12,
    // 84→64×14 @10.
    final shadowW = big ? size * .75 : size - 12;
    final shadowH = big ? 14.0 : 10.0;
    final image = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: const Color(0x24FFFFFF),
        boxShadow: [
          const BoxShadow(color: Color(0xD9FFFFFF), spreadRadius: 2),
          BoxShadow(
            color: const Color.fromRGBO(3, 16, 24, .9),
            offset: Offset(0, ringDropY),
            blurRadius: onbBlur(ringDropBlur),
            spreadRadius: -ringDropY,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(asset, fit: BoxFit.cover),
      ),
    );
    return SizedBox(
      width: size,
      height: size,
      child: OnbLoopClock(
        builder: (context, t, _) {
          final p = onbLoop(t, 0, 3400)!;
          const stops = [0.0, .5, 1.0];
          final dy = bob
              ? onbKf(p, stops, const [0, -3, 0], Curves.easeInOut)
              : 0.0;
          final rot = bob
              ? onbKf(p, stops, const [-2, 2, -2], Curves.easeInOut)
              : 0.0;
          final sx = onbKf(p, stops, const [1, 1.3, 1], Curves.easeInOut);
          final so = onbKf(p, stops, const [.5, .2, .5], Curves.easeInOut);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              if (floorShadow)
                Positioned(
                  left: (size - shadowW) / 2,
                  bottom: big ? -6 : -4,
                  width: shadowW,
                  height: shadowH,
                  child: Opacity(
                    opacity: so,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.diagonal3Values(sx, 1, 1),
                      child: onbBlurred(
                        big ? 4 : 3,
                        const CustomPaint(
                          painter: SplashRadialPainter(
                            center: Offset(.5, .5),
                            radii: Offset(.5, .5),
                            colors: [
                              Color.fromRGBO(3, 16, 24, .72),
                              Color.fromRGBO(3, 16, 24, 0),
                            ],
                            stops: [0, .72],
                            oval: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Transform.translate(
                offset: Offset(0, dy),
                child: Transform.rotate(angle: _rad(rot), child: image),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Ægil + white speech bubble with the tail pointing at him.
class AegilSays extends StatelessWidget {
  const AegilSays({
    super.key,
    required this.asset,
    required this.text,
    this.avatarSize = 58,
    this.avatarRadius = 19,
    this.bubbleRadius = 18,
    this.padding = const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
    this.showLabel = true,
    this.fontSize = 12.5,
    this.floorShadow = true,
    this.delayMs = 240,
  });

  final String asset;
  final String text;
  final double avatarSize;
  final double avatarRadius;
  final double bubbleRadius;
  final EdgeInsets padding;
  final bool showLabel;
  final double fontSize;
  final bool floorShadow;
  final double delayMs;

  @override
  Widget build(BuildContext context) {
    final r = Radius.circular(bubbleRadius);
    return OnbBubbleIn(
      delayMs: delayMs,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AegilAvatar(
            asset: asset,
            size: avatarSize,
            radius: avatarRadius,
            floorShadow: floorShadow,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: padding,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: r,
                      topRight: r,
                      bottomRight: r,
                      bottomLeft: const Radius.circular(6),
                    ),
                    boxShadow: onbPaperShadow(),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showLabel) ...[
                        Text(
                          OnbCopy.aegilLabel,
                          style: onbText(
                            9.5,
                            weight: FontWeight.w800,
                            letterSpacingEm: .08,
                            color: OnbColors.mintDeep,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        text,
                        style: onbText(
                          fontSize,
                          weight: FontWeight.w700,
                          height: 1.4,
                          color: OnbColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: -6,
                  bottom: 8,
                  width: 12,
                  height: 12,
                  child: ClipPath(
                    clipper: _TailClipper(),
                    child: const ColoredBox(color: Colors.white),
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

/// `clip-path: polygon(100% 0, 100% 100%, 0 100%)`.
class _TailClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) => Path()
    ..moveTo(s.width, 0)
    ..lineTo(s.width, s.height)
    ..lineTo(0, s.height)
    ..close();

  @override
  bool shouldReclip(_TailClipper old) => false;
}

// ── Sticker mark ────────────────────────────────────────────────────────────

/// The 3D-sticker Æ, floating (`spSvev`) with an optional one-off sheen
/// (`spGlans`) and floor shadow. Used on the landing (136×108).
class OnbStickerMark extends StatelessWidget {
  const OnbStickerMark({
    super.key,
    this.width = 136,
    this.height = 108,
    this.floatMs = 4600,
    this.floatDelayMs = 0,
    this.sheen = true,
    this.floorShadow = true,
    this.markKey,
  });

  final double width;
  final double height;
  final double floatMs;
  final double floatDelayMs;
  final bool sheen;
  final bool floorShadow;

  /// Measured by the splash → landing mark hand-off.
  final Key? markKey;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: markKey,
      width: width,
      height: height,
      child: OnbLoopClock(
        builder: (context, t, _) {
          final pf = onbLoop(t, floatDelayMs, floatMs);
          final dy = pf == null
              ? 0.0
              : onbKf(pf, const [0, .5, 1], const [0, -6, 0], Curves.easeInOut);
          final ps = onbP(t, 600, 1000);
          final sx = onbKf(ps, const [0, 1], const [0, 240], Curves.easeInOut);
          final so = onbKf(
            ps,
            const [0, .18, 1],
            const [0, 1, 0],
            Curves.easeInOut,
          );
          return Stack(
            clipBehavior: Clip.none,
            children: [
              if (floorShadow)
                Positioned(
                  left: 10 * width / 136,
                  top: 90 * height / 108,
                  width: 116 * width / 136,
                  height: 20,
                  child: onbBlurred(
                    5,
                    const CustomPaint(
                      painter: SplashRadialPainter(
                        center: Offset(.5, .5),
                        radii: Offset(.5, .5),
                        colors: [
                          Color.fromRGBO(3, 16, 24, .8),
                          Color.fromRGBO(3, 16, 24, 0),
                        ],
                        stops: [0, .72],
                        oval: true,
                      ),
                    ),
                  ),
                ),
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(0, dy),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const CustomPaint(painter: SplashStickerPainter()),
                      if (sheen)
                        CustomPaint(
                          painter: SplashSheenPainter(
                            translateX: sx,
                            opacity: so,
                            bandWidth: 50,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// An input decoration with nothing of the app theme leaking in (fill,
/// enabled/focused borders, padding) — the white card around it is the field.
InputDecoration onbBareInput({String? hint, TextStyle? hintStyle}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: hintStyle,
      isDense: true,
      isCollapsed: true,
      filled: false,
      contentPadding: EdgeInsets.zero,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      counterText: '',
    );

// ── Inputs ──────────────────────────────────────────────────────────────────

/// White 58px field: icon, small caps label over the input, and a 4px
/// accent bar on the left that turns mint when the value is valid.
class OnbField extends StatelessWidget {
  const OnbField({
    super.key,
    required this.label,
    required this.controller,
    this.icon,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.accent = OnbColors.accentIdle,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.inputStyle,
    this.trailing,
    this.focusNode,
  });

  final String label;
  final TextEditingController controller;
  final String? icon;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final Color accent;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final TextStyle? inputStyle;
  final Widget? trailing;
  final FocusNode? focusNode;

  static const double _r = 17;

  @override
  Widget build(BuildContext context) {
    final style =
        inputStyle ??
        onbText(15, weight: FontWeight.w700, color: OnbColors.ink);
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_r),
        boxShadow: onbPaperShadow(spread: -16),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                if (icon != null) ...[
                  OnbIcons.of(icon!, 18),
                  const SizedBox(width: 11),
                ],
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: onbText(
                          10,
                          weight: FontWeight.w800,
                          letterSpacingEm: .07,
                          color: OnbColors.fieldLabel,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          obscureText: obscure,
                          keyboardType: keyboardType,
                          textInputAction: textInputAction,
                          textCapitalization: textCapitalization,
                          inputFormatters: inputFormatters,
                          autofillHints: autofillHints,
                          onChanged: onChanged,
                          onSubmitted: onSubmitted,
                          cursorColor: OnbColors.orange,
                          style: style,
                          decoration: onbBareInput(
                            hint: hint,
                            hintStyle: style.copyWith(
                              color: OnbColors.placeholder,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(_r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Segmented control with a sliding thumb (`transition: transform .42s
/// cubic-bezier(.34,1.32,.5,1)`).
class OnbSegmented extends StatelessWidget {
  const OnbSegmented({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(8, 26, 36, .34),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 420),
              curve: const Cubic(.34, 1.32, .5, 1),
              alignment: index == 0
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 1 / labels.length,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: onbPaperShadow(
                      y: 10,
                      blur: 18,
                      spread: -10,
                      lip: .65,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: onbText(
                          12.5,
                          weight: FontWeight.w800,
                          color: i == index
                              ? OnbColors.navy
                              : const Color(0x99FFFFFF),
                        ),
                        child: Text(labels[i], textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// NO | EN pill (landing, top-right).
class OnbLanguagePill extends StatelessWidget {
  const OnbLanguagePill({
    super.key,
    required this.isNorwegian,
    required this.onChanged,
  });

  final bool isNorwegian;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget item(String label, bool on, VoidCallback onTap) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
        decoration: BoxDecoration(
          color: on ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: onbText(
            11,
            weight: FontWeight.w800,
            color: on ? OnbColors.navy : const Color(0xB3FFFFFF),
          ),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x2EFFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          item('NO', isNorwegian, () => onChanged(true)),
          const SizedBox(width: 2),
          item('EN', !isNorwegian, () => onChanged(false)),
        ],
      ),
    );
  }
}

/// Glass card (`linear-gradient(160deg, white .12→.05)` + hairline border).
class OnbGlassCard extends StatelessWidget {
  const OnbGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
    this.radius = 18,
    this.from = .12,
    this.to = .05,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final double from;
  final double to;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          // 160deg
          begin: const Alignment(-.34, -.94),
          end: const Alignment(.34, .94),
          colors: [
            Colors.white.withValues(alpha: from),
            Colors.white.withValues(alpha: to),
          ],
        ),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Stack(
        children: [
          _InsetTop(radius: radius, height: 1, alpha: .22),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

/// Opens the country list (same dialog the old phone field used) and
/// returns the picked dial code, or null.
Future<String?> onbPickDialCode(BuildContext context) async {
  final elements = myCountryList
      .map(CountryCode.fromJson)
      .toList(growable: false);
  final result = await showDialog<CountryCode>(
    context: context,
    barrierColor: OnbColors.navy.withValues(alpha: .45),
    builder: (context) => Center(
      child: Dialog(
        child: SelectionDialog(
          elements,
          const [],
          showFlag: true,
          showCountryOnly: false,
          flagWidth: 28,
          hideSearch: false,
        ),
      ),
    ),
  );
  final dial = result?.dialCode;
  return (dial == null || dial.isEmpty) ? null : dial;
}

/// Regional-indicator flag emoji for a dial code (`+47` → 🇳🇴).
String onbFlagFor(String dialCode) {
  try {
    final code = CountryCode.fromDialCode(dialCode).code;
    if (code == null || code.length != 2) return '';
    return String.fromCharCodes(
      code.toUpperCase().codeUnits.map((c) => 0x1F1E6 + c - 0x41),
    );
  } catch (_) {
    return '';
  }
}
