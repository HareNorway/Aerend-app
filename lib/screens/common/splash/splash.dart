import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/bergen_tokens.dart';
import '../consent/reen_flip_mark.dart';
import 'splash_bloc.dart';
import 'splash_sticker_painter.dart';

// ── Ærend Kunde Bergen splash — 1:1 port of
// `Design/Ærend Kunde Bergen (frittstående).html`,
// `data-screen-label="Splash · klistremerke"` (default `splashStil`
// "Klistremerke 3D").
//
// Every value below is the design's CSS keyframe, sampled from one 2.6s
// clock (`_SplashScene.t`, ms). Positions are the design's 390×844 frame,
// kept centred on the device.

const double _kTotalMs = 2600; // `spUt 2.6s` — splash leaves at its end.
const double _kSettledMs = 2000; // Reduced motion: everything landed.
const int _kReducedHoldMs = 700;
const int _kExitMs = 420;
const int _kSkipMs = 320;

const double _kFrameH = 844;

const Cubic _kCamera = Cubic(.2, .7, .2, 1);
const Cubic _kSlap = Cubic(.3, .9, .3, 1);
const Cubic _kLetter = Cubic(.2, 1.2, .4, 1);
const Cubic _kHorizon = Cubic(.2, .8, .3, 1);

const Color _kBase = Color(0xFF2F6270);
const Color _kInk = Color(0xFFF5F3EF);
const Color _kLocation = Color(0xFFBFD6DD);

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  SplashState createState() => SplashState();
}

class SplashState extends State<Splash> with TickerProviderStateMixin {
  SplashBloc? _bloc;

  late final AnimationController _timeline;
  late final AnimationController _skip;

  Timer? _reducedDone;

  final GlobalKey _logoKey = GlobalKey();

  bool _reduceMotion = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _timeline = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _kTotalMs.round()),
    )..addStatusListener(_onPhaseDone);
    _skip = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _kSkipMs),
    )..addStatusListener(_onPhaseDone);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (mounted) {
      _bloc ??= SplashBloc(context, this);
    }
    if (!_started) {
      _started = true;
      if (_reduceMotion) {
        _reducedDone = Timer(
          const Duration(milliseconds: _kReducedHoldMs + _kExitMs),
          _requestNavigation,
        );
      } else {
        _timeline.forward();
      }
    }
  }

  @override
  void dispose() {
    _reducedDone?.cancel();
    _timeline.dispose();
    _skip.dispose();
    _bloc!.dispose();
    super.dispose();
  }

  void _onTap() {
    if (_reduceMotion) return;
    if (_skip.status == AnimationStatus.dismissed) _skip.forward();
  }

  void _onPhaseDone(AnimationStatus status) {
    if (status == AnimationStatus.completed) _requestNavigation();
  }

  void _requestNavigation() {
    if (!mounted) return;
    ReenMarkHandoff.splashMark = ReenMarkHandoff.measure(_logoKey);
    _bloc?.skipSplashDelay();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AerendBergenAuthTokens.navyBottom,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _onTap,
          child: AnimatedBuilder(
            animation: Listenable.merge(<Listenable>[_timeline, _skip]),
            builder: (BuildContext context, Widget? child) {
              return _SplashScene(
                t: _reduceMotion ? _kSettledMs : _timeline.value * _kTotalMs,
                skip: _skip.value,
                logoKey: _logoKey,
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Keyframe helpers ────────────────────────────────────────────────────────

/// Progress of a one-shot CSS animation with `animation-fill-mode: both`.
double _p(double t, double delayMs, double durMs) =>
    ((t - delayMs) / durMs).clamp(0.0, 1.0);

/// Progress of an `infinite` CSS animation (fill-mode none).
double _loop(double t, double delayMs, double durMs, {bool reverse = false}) {
  final elapsed = t - delayMs;
  if (elapsed < 0) return 0;
  final p = (elapsed / durMs) % 1.0;
  return reverse ? 1 - p : p;
}

/// One keyframed property: [stops] (0..1) → [values], with the animation's
/// timing function applied per keyframe segment (as CSS does).
double _kf(double p, List<double> stops, List<double> values, Curve curve) {
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

double _rad(double deg) => deg * math.pi / 180;

/// CSS `perspective(d)`.
Matrix4 _perspective(double d) => Matrix4.identity()..setEntry(3, 2, -1 / d);

Matrix4 _translate(double x, double y, [double z = 0]) =>
    Matrix4.translationValues(x, y, z);

Matrix4 _scale(double x, double y) => Matrix4.diagonal3Values(x, y, 1);

double _o(double v) => v.clamp(0.0, 1.0);

Widget _blur(double sigma, Widget child) => ImageFiltered(
  imageFilter: ImageFilter.blur(
    sigmaX: sigma,
    sigmaY: sigma,
    tileMode: TileMode.decal,
  ),
  child: child,
);

// ── Scene ───────────────────────────────────────────────────────────────────

class _SplashScene extends StatelessWidget {
  const _SplashScene({
    required this.t,
    required this.skip,
    required this.logoKey,
  });

  final double t;
  final double skip;
  final GlobalKey logoKey;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        // Design `top:` values are for an 844pt frame — keep the lockup's
        // spacing exact and centre it on taller/shorter screens.
        final dy = (h - _kFrameH) / 2;

        // spUt 2.6s ease-in both — hold, then fade + scale up.
        final pOut = _p(t, 0, 2600);
        final outOpacity =
            _kf(pOut, const [0, .8, 1], const [1, 1, 0], Curves.easeIn) *
            (1 - Curves.ease.transform(skip));
        final outScale = _kf(
          pOut,
          const [0, .8, 1],
          const [1, 1, 1.08],
          Curves.easeIn,
        );

        // spKamera 2.6s — push-in.
        final pCam = _p(t, 0, 2600);
        final camScale = _kf(pCam, const [0, 1], const [1.12, 1], _kCamera);
        final camY = _kf(pCam, const [0, 1], const [14, 0], _kCamera);

        return ClipRect(
          child: Opacity(
            opacity: _o(outOpacity),
            child: Transform.scale(
              scale: outScale,
              child: ColoredBox(
                color: _kBase,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Transform(
                      alignment: Alignment.center,
                      transform: _scale(camScale, camScale)
                        ..multiply(_translate(0, camY)),
                      child: Stack(
                        fit: StackFit.expand,
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          const CustomPaint(
                            painter: SplashRadialPainter(
                              center: Offset(.5, .3),
                              radii: Offset(1.1, .7),
                              colors: [
                                Color(0xFF3A7080),
                                Color(0xFF2F6270),
                                Color(0xFF1B414C),
                              ],
                              stops: [0, .45, 1],
                            ),
                          ),
                          ..._lightBlobs(w, h),
                          _lightShaft(w, dy),
                          ..._shockRings(w, dy),
                          _backlight(w, dy),
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 292 + dy,
                            height: 120,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                // 150px sticker, `margin-left:-14px` on the
                                // word → 136px of layout width.
                                SizedBox(
                                  width: 136,
                                  height: 120,
                                  child: OverflowBox(
                                    alignment: Alignment.centerLeft,
                                    minWidth: 150,
                                    maxWidth: 150,
                                    child: _sticker(),
                                  ),
                                ),
                                _wordmark(),
                              ],
                            ),
                          ),
                          _horizon(w, dy),
                          _tagline(dy),
                          // Vignette.
                          const CustomPaint(
                            painter: SplashRadialPainter(
                              center: Offset(.5, .3),
                              radii: Offset(1.2, .8),
                              colors: [
                                Color(0x00081A24),
                                Color(0x00081A24),
                                Color(0x80081A24),
                              ],
                              stops: [0, .5, 1],
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: h * .34,
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0x000F1F2B),
                                    Color(0xB30F1F2B),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _location(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Two soft light pools drifting (`onbLysDrift`).
  List<Widget> _lightBlobs(double w, double h) {
    Widget blob({
      required double left,
      required double top,
      required double width,
      required double height,
      required Color color,
      required double sigma,
      required double p,
    }) {
      final dx = _kf(p, const [0, .5, 1], const [0, 14, 0], Curves.easeInOut);
      final dyy = _kf(p, const [0, .5, 1], const [0, -10, 0], Curves.easeInOut);
      final s = _kf(p, const [0, .5, 1], const [1, 1.06, 1], Curves.easeInOut);
      return Positioned(
        left: left,
        top: top,
        width: width,
        height: height,
        child: Transform(
          alignment: Alignment.center,
          transform: _translate(dx, dyy)..multiply(_scale(s, s)),
          child: _blur(
            sigma,
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

    return <Widget>[
      blob(
        left: -.2 * w,
        top: -.06 * h,
        width: .8 * w,
        height: .46 * h,
        color: const Color(0x29FFFFFF),
        sigma: 28,
        p: _loop(t, 0, 17000),
      ),
      blob(
        left: .5 * w, // `right:-25%; width:75%`
        top: .4 * h,
        width: .75 * w,
        height: .44 * h,
        color: const Color.fromRGBO(120, 200, 190, .18),
        sigma: 30,
        p: _loop(t, -9000, 23000, reverse: true),
      ),
    ];
  }

  /// `spLysSjakt` — a light beam sweeping across the lockup.
  Widget _lightShaft(double w, double dy) {
    final p = _p(t, 100, 1600);
    final opacity = _kf(
      p,
      const [0, .4, 1],
      const [0, .7, 0],
      Curves.easeInOut,
    );
    final tx = _kf(p, const [0, 1], const [-20, 24], Curves.easeInOut);
    final sy = _kf(p, const [0, 1], const [.6, 1.05], Curves.easeInOut);
    return Positioned(
      left: w / 2 - 75,
      top: -40,
      width: 150,
      height: math.max(300, 520 + dy),
      child: Opacity(
        opacity: _o(opacity),
        child: Transform(
          alignment: Alignment.topCenter,
          transform: _translate(tx, 0)..multiply(_scale(1, sy)),
          // CSS applies `filter` before `clip-path` → hard trapezoid edges.
          child: ClipPath(
            clipper: _ShaftClipper(),
            child: _blur(
              14,
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.fromRGBO(210, 242, 246, .55),
                      Color.fromRGBO(210, 242, 246, 0),
                    ],
                    stops: [0, .8],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// `spSlag` — three impact rings where the sticker lands.
  List<Widget> _shockRings(double w, double dy) {
    Widget ring(double delay, double dur, Color color, double width) {
      final p = _p(t, delay, dur);
      final s = _kf(p, const [0, 1], const [.2, 1.9], Curves.easeOut);
      final o = _kf(p, const [0, .1, 1], const [0, .9, 0], Curves.easeOut);
      return Positioned(
        left: w / 2 - 170,
        top: 352 + dy - 60,
        width: 340,
        height: 120,
        child: Opacity(
          opacity: _o(o),
          child: Transform.scale(
            scale: s,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                shape: OvalBorder(
                  side: BorderSide(color: color, width: width),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return <Widget>[
      ring(680, 1100, const Color.fromRGBO(255, 255, 255, .7), 1.5),
      ring(780, 1300, const Color.fromRGBO(92, 224, 184, .7), 1),
      ring(900, 1500, const Color.fromRGBO(255, 255, 255, .4), 1),
    ];
  }

  /// `spBakLys` — mint glow behind the lockup.
  Widget _backlight(double w, double dy) {
    final p = _p(t, 900, 800);
    final o = _kf(p, const [0, 1], const [0, 1], Curves.easeOut);
    final s = _kf(p, const [0, 1], const [.6, 1], Curves.easeOut);
    // `radial-gradient(circle, …)` = farthest-corner of a 420×300 box.
    final r = math.sqrt(210 * 210 + 150 * 150);
    return Positioned(
      left: w / 2 - 210,
      top: 300 + dy,
      width: 420,
      height: 300,
      child: Opacity(
        opacity: _o(o),
        child: Transform.scale(
          scale: s,
          child: _blur(
            30,
            CustomPaint(
              painter: SplashRadialPainter(
                center: const Offset(.5, .5),
                radii: Offset(r / 420, r / 300),
                colors: const [
                  Color.fromRGBO(92, 224, 184, .3),
                  Color.fromRGBO(92, 224, 184, 0),
                ],
                stops: const [0, .65],
                oval: true,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The 150×120 sticker: shadow slam, dust burst, 3D slap-down, peel flap,
  /// idle float and sheen.
  Widget _sticker() {
    // spSkyggeSlag .9s .2s ease-out.
    final pShadow = _p(t, 200, 900);
    const shadowStops = [0.0, .55, .7, 1.0];
    final shadowO = _kf(pShadow, shadowStops, const [
      0,
      .25,
      .7,
      .6,
    ], Curves.easeOut);
    final shadowS = _kf(pShadow, shadowStops, const [
      .55,
      1.2,
      .94,
      1,
    ], Curves.easeOut);

    // spKlistre .9s .15s — flies in from the camera and slaps down.
    final pSlap = _p(t, 150, 900);
    const slapStops = [0.0, .58, .74, 1.0];
    final tz = _kf(pSlap, slapStops, const [420, 0, 0, 0], _kSlap);
    final ty = _kf(pSlap, slapStops, const [-30, 0, 0, 0], _kSlap);
    final rx = _kf(pSlap, slapStops, const [38, 0, 0, 0], _kSlap);
    final ry = _kf(pSlap, slapStops, const [-28, 0, 0, 0], _kSlap);
    final rz = _kf(pSlap, slapStops, const [-22, -4, -5.5, -5], _kSlap);
    final sx = _kf(pSlap, slapStops, const [1, 1.03, .985, 1], _kSlap);
    final sy = _kf(pSlap, slapStops, const [1, .93, 1.03, 1], _kSlap);
    final slapO = _kf(pSlap, const [0, .18, 1], const [0, 1, 1], _kSlap);
    final slap = _perspective(700)
      ..multiply(_translate(0, ty, tz))
      ..rotateX(_rad(rx))
      ..rotateY(_rad(ry))
      ..rotateZ(_rad(rz))
      ..multiply(_scale(sx, sy));

    // spSvevTung 4s 1.2s infinite — heavy idle float.
    final pFloat = _loop(t, 1200, 4000);
    final fx = _kf(pFloat, const [0, .5, 1], const [0, 4, 0], Curves.easeInOut);
    final fy = _kf(
      pFloat,
      const [0, .5, 1],
      const [0, -5, 0],
      Curves.easeInOut,
    );
    final fTy = _kf(
      pFloat,
      const [0, .5, 1],
      const [0, -5, 0],
      Curves.easeInOut,
    );
    final float = _perspective(700)
      ..rotateX(_rad(fx))
      ..rotateY(_rad(fy))
      ..multiply(_translate(0, fTy));

    // spFlik .9s .15s — the peeled flap unfolds from the bottom-left.
    final pFlap = _p(t, 150, 900);
    final flapX = _kf(pFlap, const [0, .55, 1], const [-46, -46, 0], _kSlap);
    final flapY = _kf(pFlap, const [0, .55, 1], const [18, 18, 0], _kSlap);
    final flap = _perspective(500)
      ..rotateX(_rad(flapX))
      ..rotateY(_rad(flapY));

    // spGlattUt .7s .72s — sheen sweep.
    final pSheen = _p(t, 720, 700);
    final sheenX = _kf(
      pSheen,
      const [0, 1],
      const [-90, 150],
      Curves.easeInOut,
    );
    final sheenO = _kf(
      pSheen,
      const [0, .2, 1],
      const [0, .85, 0],
      Curves.easeInOut,
    );

    return SizedBox(
      key: logoKey,
      width: 150,
      height: 120,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            left: 14,
            top: 108,
            width: 126,
            height: 22,
            child: Opacity(
              opacity: _o(shadowO),
              child: Transform.scale(
                scale: shadowS,
                child: _blur(
                  5,
                  const CustomPaint(
                    painter: SplashRadialPainter(
                      center: Offset(.5, .5),
                      radii: Offset(.5, .5),
                      colors: [
                        Color.fromRGBO(3, 16, 24, .85),
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
          _dust(70, 60, 6, const Color(0xFFFFFFFF), 700, -44, -30),
          _dust(78, 56, 5, const Color(0xFFF26D3D), 720, 48, -24),
          _dust(66, 66, 4, const Color(0xFF5CE0B8), 710, -30, 34),
          _dust(82, 64, 5, const Color(0xFFFFFFFF), 730, 40, 30),
          Positioned.fill(
            child: Opacity(
              opacity: _o(slapO),
              child: Transform(
                origin: const Offset(75, 72),
                transform: slap,
                child: Transform(
                  origin: const Offset(75, 60),
                  transform: float,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      Transform(
                        origin: const Offset(0, 120),
                        transform: flap,
                        child: const CustomPaint(
                          painter: SplashStickerPainter(),
                        ),
                      ),
                      CustomPaint(
                        painter: SplashSheenPainter(
                          translateX: sheenX,
                          opacity: sheenO,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// `spStovA…D` — a dust fleck bursting out from under the sticker.
  Widget _dust(
    double left,
    double top,
    double size,
    Color color,
    double delay,
    double toX,
    double toY,
  ) {
    final p = _p(t, delay, 600);
    final dx = _kf(p, const [0, 1], [0, toX], Curves.easeOut);
    final dyy = _kf(p, const [0, 1], [0, toY], Curves.easeOut);
    final s = _kf(p, const [0, 1], const [1, .1], Curves.easeOut);
    final o = _kf(p, const [0, .12, 1], const [0, 1, 0], Curves.easeOut);
    return Positioned(
      left: left,
      top: top,
      width: size,
      height: size,
      child: Opacity(
        opacity: _o(o),
        child: Transform(
          alignment: Alignment.center,
          transform: _translate(dx, dyy)..multiply(_scale(s, s)),
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }

  /// "rend" — each letter flips up (`spBokstav`), 60ms apart.
  Widget _wordmark() {
    final style = GoogleFonts.plusJakartaSans(
      fontSize: 66,
      fontWeight: FontWeight.w800,
      letterSpacing: 66 * -0.045,
      height: 1.0,
      color: _kInk,
      shadows: const [
        Shadow(color: Color.fromRGBO(15, 31, 43, .6), offset: Offset(0, 2)),
        // CSS 30px blur ≈ σ15.
        Shadow(
          color: Color.fromRGBO(3, 16, 24, .6),
          offset: Offset(0, 14),
          blurRadius: 25,
        ),
      ],
    ).copyWith(leadingDistribution: TextLeadingDistribution.even);
    const letters = ['r', 'e', 'n', 'd'];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var i = 0; i < letters.length; i++)
          Builder(
            builder: (BuildContext context) {
              final p = _p(t, 1050 + 60.0 * i, 400);
              final rx = _kf(p, const [0, 1], const [92, 0], _kLetter);
              final tx = _kf(p, const [0, 1], const [-16, 0], _kLetter);
              final o = _kf(p, const [0, 1], const [0, 1], _kLetter);
              return Opacity(
                opacity: _o(o),
                child: Transform(
                  alignment: Alignment.bottomCenter,
                  transform: _perspective(420)
                    ..rotateX(_rad(rx))
                    ..multiply(_translate(tx, 0)),
                  child: Text(letters[i], style: style),
                ),
              );
            },
          ),
      ],
    );
  }

  /// `spHorisont` — the orange rule under the wordmark.
  Widget _horizon(double w, double dy) {
    final p = _p(t, 1300, 600);
    final sx = _kf(p, const [0, 1], const [0, 1], _kHorizon);
    final o = _kf(p, const [0, .6, 1], const [0, 1, .7], _kHorizon);
    return Positioned(
      left: w / 2 - 90,
      top: 428 + dy,
      width: 180,
      height: 1.5,
      child: Opacity(
        opacity: _o(o),
        child: Transform(
          alignment: Alignment.center,
          transform: _scale(sx, 1),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: const LinearGradient(
                colors: [
                  Color(0x00F26D3D),
                  Color(0xFFF26D3D),
                  Color(0xFFF26D3D),
                  Color(0x00F26D3D),
                ],
                stops: [0, .3, .7, 1],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tagline(double dy) {
    final p = _p(t, 1400, 500);
    final o = _kf(p, const [0, 1], const [0, 1], Curves.easeOut);
    final ty = _kf(p, const [0, 1], const [12, 0], Curves.easeOut);
    return Positioned(
      left: 0,
      right: 0,
      top: 446 + dy,
      child: Opacity(
        opacity: _o(o),
        child: Transform.translate(
          offset: Offset(0, ty),
          child: Text(
            'Alt du trenger, ett ærend.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 15 * -0.01,
              color: _kInk,
            ),
          ),
        ),
      ),
    );
  }

  Widget _location() {
    final p = _p(t, 1600, 500);
    final o = _kf(p, const [0, 1], const [0, 1], Curves.easeOut);
    final ty = _kf(p, const [0, 1], const [12, 0], Curves.easeOut);
    return Positioned(
      left: 0,
      right: 0,
      bottom: 36,
      child: Opacity(
        opacity: _o(o),
        child: Transform.translate(
          offset: Offset(0, ty),
          child: Text(
            'BERGEN · VESTLAND',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 11 * 0.06,
              color: _kLocation,
            ),
          ),
        ),
      ),
    );
  }
}

/// `clip-path: polygon(38% 0, 62% 0, 100% 100%, 0 100%)`.
class _ShaftClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width * .38, 0)
    ..lineTo(size.width * .62, 0)
    ..lineTo(size.width, size.height)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(_ShaftClipper oldClipper) => false;
}
