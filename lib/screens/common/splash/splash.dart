import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../auth/launch/lf_css.dart';
import '../auth/launch/lf_splash.dart';
import '../../snurre/snurre_launcher_policy.dart';
import '../consent/reen_flip_mark.dart';
import 'splash_bloc.dart';

// ── Ærend Kunde Launch splash ───────────────────────────────────────────────
// `Design-New/Ærend Kunde Launch.dc.html`, `data-screen-label="Splash ·
// klistremerke"` (default `splashStil` "Klistremerke 3D"): the Æ drawn in
// strokes, kicked, "rend" sliding out from behind it, the sheen, the
// tagline. At 86% of the 3.4s clock (`spxUt`) the next screen cross-fades
// in over 476ms ([lfSplashFadeRoute]); the splash keeps playing underneath
// until it is gone, as in the prototype. No tap-to-skip (the prototype's
// splash is `pointer-events:none`).

const int _kReducedHoldMs = 700;

/// Reduced motion: the settled frame (every stroke, letter and the tagline
/// in place, the logo not yet leaving).
const double _kSettledMs = 2700;

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  SplashState createState() => SplashState();
}

class SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  SplashBloc? _bloc;

  late final AnimationController _timeline;

  Timer? _reducedDone;

  final GlobalKey _logoKey = GlobalKey();

  bool _reduceMotion = false;
  bool _started = false;
  bool _requested = false;

  @override
  void initState() {
    super.initState();
    _timeline = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..addListener(_onTick);
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
          const Duration(milliseconds: _kReducedHoldMs),
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
    _bloc!.dispose();
    super.dispose();
  }

  void _onTick() {
    if (_timeline.value * kLfSplashMs >= kLfSplashFadeAt) _requestNavigation();
  }

  void _requestNavigation() {
    if (!mounted || _requested) return;
    _requested = true;
    ReenMarkHandoff.splashMark = ReenMarkHandoff.measure(_logoKey);
    _bloc?.skipSplashDelay();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D232B),
        body: LfFrame(
          child: AnimatedBuilder(
            animation: _timeline,
            builder: (BuildContext context, Widget? child) => LfSplashScene(
              t: _reduceMotion ? _kSettledMs : _timeline.value * kLfSplashMs,
              logoKey: _logoKey,
            ),
          ),
        ),
      ),
    );
  }
}

/// The splash's exit: the next screen fades in linearly over the last 14%
/// of the 3.4s clock (`spxUt 3.4s linear`, 86% → 100%).
PageRoute<T> lfSplashFadeRoute<T extends Object?>(Widget screen) {
  return PageRouteBuilder<T>(
    settings: RouteSettings(name: snurreLauncherRouteNameFor(screen)),
    pageBuilder: (context, animation, secondaryAnimation) => screen,
    transitionDuration: const Duration(milliseconds: 476),
    reverseTransitionDuration: Duration.zero,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}
