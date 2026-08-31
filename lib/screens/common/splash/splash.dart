import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/reen_pre_club_theme.dart';
import '../../../utils/utils.dart';
import '../consent/reen_flip_mark.dart';
import 'splash_bloc.dart';

// ── Reen splash (aligned with Reen-web-portal site loader + existing merge exit)
//
// Entrance (web portal, no sheen):
//   logo pop → tagline rise → Ærend by-line rise → dots rise + bounce
// Exit to login (returning / already-consented path):
//   navy panel shrinks into the login coral mark box.
// Exit to consent (`.reen-to-consent`): panel stays, tagline/by/dots fade,
//   wordmark is measured for FLIP.

const int _kHoldMs = 2500;
const int _kExitMs = 400;
const int _kTotalMs = _kHoldMs + _kExitMs;
const int _kConsentHoldMs = 2300;
const int _kConsentExitMs = 180;
const int _kConsentTotalMs = _kConsentHoldMs + _kConsentExitMs;
const int _kReducedHoldMs = 700;
const int _kSkipMs = 380;

/// `cubic-bezier(.34,1.56,.64,1)` — logo pop overshoot (web `aesp-pop`).
const Cubic _kPop = Cubic(0.34, 1.56, 0.64, 1.0);

/// `cubic-bezier(.22,1,.36,1)` — rise (web `aesp-rise`).
const Cubic _kRise = Cubic(0.22, 1.0, 0.36, 1.0);

/// `cubic-bezier(.5,0,.2,1)` — panel merge exit.
const Cubic _kMerge = Cubic(0.5, 0.0, 0.2, 1.0);

/// Login logo is 68px (18.13% of 375) centered at 14.29% of 812 from top.
const double _kLogoFrac = 0.1813;
const double _kLogoCenterYFrac = 0.1429;

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
  bool _toConsent = false;

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
      _toConsent = !isLoggedIn();
      if (_toConsent) {
        _timeline.duration = const Duration(milliseconds: _kConsentTotalMs);
      }
      if (_reduceMotion) {
        _reducedDone = Timer(
          Duration(
            milliseconds:
                _kReducedHoldMs + (_toConsent ? _kConsentExitMs : _kExitMs),
          ),
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
    if (_toConsent) {
      ReenMarkHandoff.splashMark = ReenMarkHandoff.measure(_logoKey);
    }
    _bloc?.skipSplashDelay();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: ReenPreClubTokens.navyBottom,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _onTap,
          child: AnimatedBuilder(
            animation: Listenable.merge(<Listenable>[_timeline, _skip]),
            builder: (BuildContext context, Widget? child) {
              final size = MediaQuery.sizeOf(context);
              final totalMs = _toConsent
                  ? _kConsentTotalMs.toDouble()
                  : _kTotalMs.toDouble();
              final frame = _reduceMotion
                  ? const _ReenSplashFrame.settled()
                  : _ReenSplashFrame.at(
                      _timeline.value * totalMs,
                      skip: _skip.value,
                      toConsent: _toConsent,
                    );
              return _buildContent(context, size, frame);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Size size, _ReenSplashFrame f) {
    final logoSide = size.width * _kLogoFrac;
    final logoCenterY = size.height * _kLogoCenterYFrac;
    final half = logoSide / 2;
    final topInset = logoCenterY - half;
    final bottomInset = size.height - (logoCenterY + half);
    final sideInset = (size.width - logoSide) / 2;

    final clipTop = topInset * f.panelClip;
    final clipBottom = bottomInset * f.panelClip;
    final clipSide = sideInset * f.panelClip;
    final clipRadius = 15.0 * f.panelClip;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        // Navy panel — shrinks into logo box on exit.
        ClipPath(
          clipper: _InsetRoundClipper(
            top: clipTop,
            right: clipSide,
            bottom: clipBottom,
            left: clipSide,
            radius: clipRadius,
          ),
          child: Opacity(
            opacity: f.panelOpacity,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: ReenPreClubTokens.splashPanelGradient,
              ),
              child: SizedBox.expand(),
            ),
          ),
        ),
        // Stage (logo + tagline + by-line + dots) — fades on merge exit.
        Opacity(
          opacity: f.stageOpacity,
          child: Stack(
            children: <Widget>[
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Transform.scale(
                      scale: f.logoScale,
                      child: Opacity(
                        opacity: f.logoOpacity,
                        child: _buildLogo(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Opacity(
                      opacity: f.tagOpacity,
                      child: Transform.translate(
                        offset: Offset(0, f.tagDy),
                        child: _buildTagline(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Opacity(
                      opacity: f.byOpacity,
                      child: Transform.translate(
                        offset: Offset(0, f.byDy),
                        child: _buildByline(),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 70,
                child: Center(
                  child: Opacity(
                    opacity: f.dotsOpacity,
                    child: Transform.translate(
                      offset: Offset(0, f.dotsDy),
                      child: _buildDots(f),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Coral mark fades in at login logo position during merge.
        Positioned(
          left: sideInset,
          top: topInset,
          width: logoSide,
          height: logoSide,
          child: Opacity(
            opacity: f.markOpacity,
            child: Image.asset(
              ReenPreClubTokens.markCoralPng,
              width: logoSide,
              height: logoSide,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    // Soft dark drop shadow behind wordmark (mockup).
    return SizedBox(
      width: 232,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: <Widget>[
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Opacity(
              opacity: 0.55,
              child: Transform.translate(
                offset: const Offset(0, 8),
                child: SvgPicture.asset(
                  ReenPreClubTokens.logoWhite,
                  width: 220,
                  height: 52,
                  fit: BoxFit.contain,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF000000),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          SvgPicture.asset(
            ReenPreClubTokens.logoWhite,
            key: _logoKey,
            height: 44,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }

  Widget _buildTagline() {
    // Design `.reen-pre .sp-word .tag` — two lines, coral on «klubbkasse».
    final base = GoogleFonts.plusJakartaSans(
      fontSize: 18,
      fontWeight: FontWeight.w800,
      letterSpacing: 18 * -0.02,
      height: 1.2,
      color: Colors.white,
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 232),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Fra handlekurv', textAlign: TextAlign.center, style: base),
          Text.rich(
            TextSpan(
              style: base,
              children: const [
                TextSpan(text: 'til '),
                TextSpan(
                  text: 'klubbkasse',
                  style: TextStyle(color: ReenPreClubTokens.coralHover),
                ),
                TextSpan(text: '.'),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildByline() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: SvgPicture.string(
            ReenPreClubTokens.aerendByMarkSvg,
            width: 19,
            height: 19,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 7),
        Text.rich(
          TextSpan(
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xA8FFFFFF), // ~.66
            ),
            children: const <TextSpan>[
              TextSpan(text: 'et konsept av '),
              TextSpan(
                text: 'Ærend',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xDBFFFFFF),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDots(_ReenSplashFrame f) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < 3; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: 7),
          Transform.translate(
            offset: Offset(0, f.dotDy[i]),
            child: Opacity(
              opacity: f.dotOpacity[i],
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: ReenPreClubTokens.coral,
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: ReenPreClubTokens.coral.withValues(alpha: 0.6),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InsetRoundClipper extends CustomClipper<Path> {
  _InsetRoundClipper({
    required this.top,
    required this.right,
    required this.bottom,
    required this.left,
    required this.radius,
  });

  final double top;
  final double right;
  final double bottom;
  final double left;
  final double radius;

  @override
  Path getClip(Size size) {
    final rect = Rect.fromLTRB(
      left.clamp(0.0, size.width),
      top.clamp(0.0, size.height),
      (size.width - right).clamp(0.0, size.width),
      (size.height - bottom).clamp(0.0, size.height),
    );
    return Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
  }

  @override
  bool shouldReclip(_InsetRoundClipper old) =>
      old.top != top ||
      old.right != right ||
      old.bottom != bottom ||
      old.left != left ||
      old.radius != radius;
}

/// Animated values for one instant of the Reen splash clock.
class _ReenSplashFrame {
  const _ReenSplashFrame({
    required this.panelClip,
    required this.panelOpacity,
    required this.stageOpacity,
    required this.markOpacity,
    required this.logoOpacity,
    required this.logoScale,
    required this.tagOpacity,
    required this.tagDy,
    required this.byOpacity,
    required this.byDy,
    required this.dotsOpacity,
    required this.dotsDy,
    required this.dotDy,
    required this.dotOpacity,
  });

  const _ReenSplashFrame.settled()
    : panelClip = 0,
      panelOpacity = 1,
      stageOpacity = 1,
      markOpacity = 0,
      logoOpacity = 1,
      logoScale = 1,
      tagOpacity = 1,
      tagDy = 0,
      byOpacity = 1,
      byDy = 0,
      dotsOpacity = 1,
      dotsDy = 0,
      dotDy = const <double>[0, 0, 0],
      dotOpacity = const <double>[1, 1, 1];

  /// 0 = full screen; 1 = clipped to logo box (CSS inset progress).
  final double panelClip;
  final double panelOpacity;
  final double stageOpacity;
  final double markOpacity;
  final double logoOpacity;
  final double logoScale;
  final double tagOpacity;
  final double tagDy;
  final double byOpacity;
  final double byDy;
  final double dotsOpacity;
  final double dotsDy;
  final List<double> dotDy;
  final List<double> dotOpacity;

  factory _ReenSplashFrame.at(
    double t, {
    double skip = 0,
    bool toConsent = false,
  }) {
    // Entrance — match web portal timings (no sheen).
    // logo pop: 0 → 680ms
    final logoIn = _seg(t, 0, 680, _kPop);
    final logoOpacity = logoIn;
    final logoScale = 0.62 + 0.38 * logoIn;

    // tagline rise: 580 → 1120ms
    final tagIn = _seg(t, 580, 540, _kRise);
    // by-line rise: 920 → 1420ms
    final byIn = _seg(t, 920, 500, _kRise);
    // dots rise: 1250 → 1650ms
    final dotsIn = _seg(t, 1250, 400, Curves.ease);

    // Bounce dots (after they appear).
    final dotDy = <double>[0, 0, 0];
    final dotOp = <double>[0.5, 0.5, 0.5];
    if (t >= 1250) {
      for (int i = 0; i < 3; i++) {
        final delay = 1250.0 + 150.0 * i;
        if (t < delay) continue;
        final phase = ((t - delay) % 1000) / 1000;
        final u = phase < 0.5
            ? Curves.easeInOut.transform(phase / 0.5)
            : 1 - Curves.easeInOut.transform((phase - 0.5) / 0.5);
        dotDy[i] = -5.0 * u;
        dotOp[i] = 0.5 + 0.5 * u;
      }
    }

    double panelClip = 0;
    double panelOpacity = 1;
    double stageOpacity = 1;
    double markOpacity = 0;
    double tagOpacity = tagIn;
    double byOpacity = byIn;
    double dotsOpacity = dotsIn;

    if (toConsent) {
      // `.reen-to-consent .sp.out` — panel stays, coral mark never appears,
      // tagline / by-line / dots fade, wordmark holds for FLIP.
      final hold = _kConsentHoldMs.toDouble();
      if (t >= hold) {
        final exitT = t - hold;
        final fade = _seg(exitT, 0, 180, Curves.ease);
        tagOpacity *= 1 - fade;
        byOpacity *= 1 - fade;
        dotsOpacity *= 1 - _seg(exitT, 0, 160, Curves.ease);
      }
      if (skip > 0) {
        final s = Curves.ease.transform(skip);
        tagOpacity *= 1 - s;
        byOpacity *= 1 - s;
        dotsOpacity *= 1 - s;
      }
    } else {
      // Exit merge starts at hold (unchanged).
      if (t >= _kHoldMs) {
        final exitT = t - _kHoldMs;
        final clipProg = _seg(exitT, 0, _kExitMs.toDouble() * 0.68, _kMerge);
        panelClip = clipProg;
        if (exitT > _kExitMs * 0.68) {
          panelOpacity =
              1 -
              _seg(
                exitT,
                _kExitMs.toDouble() * 0.68,
                _kExitMs.toDouble() * 0.32,
                Curves.linear,
              );
        }
        stageOpacity = 1 - _seg(exitT, 0, _kExitMs * 0.13, Curves.ease);
        if (exitT >= _kExitMs * 0.55) {
          markOpacity = _seg(
            exitT,
            _kExitMs * 0.55,
            _kExitMs * 0.27,
            Curves.linear,
          );
        }
      }

      if (skip > 0) {
        final s = Curves.ease.transform(skip);
        panelOpacity *= 1 - s;
        stageOpacity *= 1 - s;
        markOpacity *= 1 - s;
        panelClip = panelClip + (1 - panelClip) * s * 0.5;
      }
    }

    return _ReenSplashFrame(
      panelClip: panelClip.clamp(0.0, 1.0),
      panelOpacity: panelOpacity.clamp(0.0, 1.0),
      stageOpacity: stageOpacity.clamp(0.0, 1.0),
      markOpacity: markOpacity.clamp(0.0, 1.0),
      logoOpacity: logoOpacity.clamp(0.0, 1.0),
      logoScale: logoScale.clamp(0.0, 1.4),
      tagOpacity: tagOpacity.clamp(0.0, 1.0),
      tagDy: 12 * (1 - tagIn),
      byOpacity: byOpacity.clamp(0.0, 1.0),
      byDy: 10 * (1 - byIn),
      dotsOpacity: dotsOpacity.clamp(0.0, 1.0),
      dotsDy: 12 * (1 - dotsIn),
      dotDy: dotDy,
      dotOpacity: dotOp,
    );
  }

  static double _seg(double t, double delay, double duration, Curve curve) {
    if (duration <= 0) return t >= delay ? 1 : 0;
    return curve.transform(((t - delay) / duration).clamp(0.0, 1.0));
  }
}
