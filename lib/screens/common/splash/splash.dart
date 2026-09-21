import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/reen_pre_club_theme.dart';
import '../consent/reen_flip_mark.dart';
import 'splash_bloc.dart';

// ── Ærend Kunde Bergen splash — mirrors `designs/20des/Ærend Kunde Bergen.dc.html`
// `data-screen-label="Splash · klistremerke"` (mountain/harbor illustration,
// floating chip cards and boat graphics intentionally skipped — see plan).
//
// Mark pop → wordmark rise → tagline rise → location tag rise → fade out.

const int _kHoldMs = 2300;
const int _kExitMs = 420;
const int _kTotalMs = _kHoldMs + _kExitMs;
const int _kReducedHoldMs = 700;
const int _kSkipMs = 320;

/// `cubic-bezier(.34,1.56,.64,1)` — mark pop overshoot (design `sp-pop`).
const Cubic _kPop = Cubic(0.34, 1.56, 0.64, 1.0);

/// `cubic-bezier(.22,1,.36,1)` — rise (design `sp-rise`/`spOpp`).
const Cubic _kRise = Cubic(0.22, 1.0, 0.36, 1.0);

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
      duration: const Duration(milliseconds: _kTotalMs),
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
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.4),
                radius: 1.1,
                colors: [
                  AerendBergenAuthTokens.navyTop,
                  AerendBergenAuthTokens.navyMid,
                  AerendBergenAuthTokens.navyBottom,
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
            child: AnimatedBuilder(
              animation: Listenable.merge(<Listenable>[_timeline, _skip]),
              builder: (BuildContext context, Widget? child) {
                final frame = _reduceMotion
                    ? const _SplashFrame.settled()
                    : _SplashFrame.at(
                        _timeline.value * _kTotalMs,
                        skip: _skip.value,
                      );
                return _buildContent(context, frame);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, _SplashFrame f) {
    return Opacity(
      opacity: f.stageOpacity,
      child: Stack(
        children: <Widget>[
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Transform.scale(
                  scale: f.markScale,
                  child: Opacity(opacity: f.markOpacity, child: _buildLockup()),
                ),
                SizedBox(height: 14),
                Opacity(
                  opacity: f.tagOpacity,
                  child: Transform.translate(
                    offset: Offset(0, f.tagDy),
                    child: _buildTagline(),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 44,
            child: Center(
              child: Opacity(
                opacity: f.locationOpacity,
                child: Transform.translate(
                  offset: Offset(0, f.locationDy),
                  child: _buildLocationTag(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The sticker Æ mark stands in for "Æ", followed by literal "rend".
  Widget _buildLockup() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          height: 92,
          child: SvgPicture.asset(
            AerendBergenAuthTokens.mark,
            key: _logoKey,
            fit: BoxFit.contain,
          ),
        ),
        Transform.translate(
          offset: const Offset(-10, 0),
          child: Text(
            'rend',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 58,
              fontWeight: FontWeight.w800,
              letterSpacing: 58 * -0.045,
              height: 1.0,
              color: AerendBergenAuthTokens.ink,
              shadows: const [
                Shadow(color: Color(0x990F1F2B), offset: Offset(0, 2)),
                Shadow(color: Color(0x99031618), blurRadius: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagline() {
    return Text(
      'Alt du trenger, ett ærend.',
      textAlign: TextAlign.center,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 15 * -0.01,
        color: AerendBergenAuthTokens.textSubtitle,
      ),
    );
  }

  Widget _buildLocationTag() {
    return Text(
      'BERGEN · VESTLAND',
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 11 * 0.06,
        color: AerendBergenAuthTokens.textMuted,
      ),
    );
  }
}

/// Animated values for one instant of the splash clock.
class _SplashFrame {
  const _SplashFrame({
    required this.stageOpacity,
    required this.markOpacity,
    required this.markScale,
    required this.tagOpacity,
    required this.tagDy,
    required this.locationOpacity,
    required this.locationDy,
  });

  const _SplashFrame.settled()
    : stageOpacity = 1,
      markOpacity = 1,
      markScale = 1,
      tagOpacity = 1,
      tagDy = 0,
      locationOpacity = 1,
      locationDy = 0;

  final double stageOpacity;
  final double markOpacity;
  final double markScale;
  final double tagOpacity;
  final double tagDy;
  final double locationOpacity;
  final double locationDy;

  factory _SplashFrame.at(double t, {double skip = 0}) {
    // Mark pop: 0 → 620ms.
    final markIn = _seg(t, 0, 620, _kPop);
    final markOpacity = _seg(t, 0, 300, Curves.ease);
    final markScale = 0.7 + 0.3 * markIn;

    // Tagline rise: 620 → 1160ms.
    final tagIn = _seg(t, 620, 540, _kRise);
    // Location tag rise: 1350 → 1750ms.
    final locationIn = _seg(t, 1350, 400, Curves.ease);

    double stageOpacity = 1;
    if (t >= _kHoldMs) {
      final exitT = t - _kHoldMs;
      stageOpacity = 1 - _seg(exitT, 0, _kExitMs.toDouble(), Curves.ease);
    }

    if (skip > 0) {
      stageOpacity *= 1 - Curves.ease.transform(skip);
    }

    return _SplashFrame(
      stageOpacity: stageOpacity.clamp(0.0, 1.0),
      markOpacity: markOpacity.clamp(0.0, 1.0),
      markScale: markScale.clamp(0.0, 1.4),
      tagOpacity: tagIn.clamp(0.0, 1.0),
      tagDy: 12 * (1 - tagIn),
      locationOpacity: locationIn.clamp(0.0, 1.0),
      locationDy: 8 * (1 - locationIn),
    );
  }

  static double _seg(double t, double delay, double duration, Curve curve) {
    if (duration <= 0) return t >= delay ? 1 : 0;
    return curve.transform(((t - delay) / duration).clamp(0.0, 1.0));
  }
}
