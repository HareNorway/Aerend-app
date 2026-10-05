import 'package:flutter/material.dart';

import '../../splash/splash_sticker_painter.dart';
import 'lf_css.dart';

// ── Splash · klistremerke ───────────────────────────────────────────────────
// `data-screen-label="Splash · klistremerke"` (prototype L1843). One 3.4s
// clock ([t], ms). The final fade (`spxUt`, 86%→100%) is the route
// cross-fade into the next screen, so this scene never fades itself.

const double kLfSplashMs = 3400;

/// When the cross-fade starts (`spxUt` 86%).
const double kLfSplashFadeAt = 3400 * .86;

class LfSplashScene extends StatelessWidget {
  const LfSplashScene({super.key, required this.t, this.logoKey});

  final double t;

  /// Measured for the hand-off into the onboarding logo.
  final GlobalKey? logoKey;

  static const Cubic _kick = Cubic(.3, .7, .3, 1);
  static const Cubic _letter = Cubic(.2, 1.25, .35, 1);
  static const Cubic _logoOut = Cubic(.5, 0, .75, 0);
  static const Cubic _text = Cubic(.2, .8, .3, 1);

  @override
  Widget build(BuildContext context) {
    // spmBg .7s ease-out
    final bg = cssEaseOut.transform(kfP(t, 0, 700));
    // spmGlod 2.4s .2s ease-out: opacity 0→1 (55%)→.75, scale .7→1
    final gp = kfP(t, 200, 2400);
    final glowO = kf(gp, const [0, .55, 1], const [0, 1, .75], cssEaseOut);
    final glowS = kf(gp, const [0, 1], const [.7, 1], cssEaseOut);
    // spmLogoUt .55s 2.85s
    final lo = _logoOut.transform(kfP(t, 2850, 550));
    // spmSkygge .9s 1.2s ease-out
    final sk = cssEaseOut.transform(kfP(t, 1200, 900));
    // spmKick .7s 1.22s (origin 40% 85%)
    final kp = kfP(t, 1220, 700);
    final kx = kf(kp, const [0, .28, .62, .82, 1], const [0, 7, -2, .5, 0], _kick);
    final ks = kf(kp, const [0, .28, .62, .82, 1], const [0, -11, 3, -.8, 0], _kick);
    // spmInn .22s 1.46s ease-out — the finished sticker over the drawing
    final inn = cssEaseOut.transform(kfP(t, 1460, 220));
    // spGlattUt .9s 2.05s ease-in-out
    final gl = kfP(t, 2050, 900);
    final glX = kf(gl, const [0, 1], const [-90, 150], cssEaseInOut);
    final glO = kf(gl, const [0, .2, 1], const [0, .85, 0], cssEaseInOut);
    // spmTekst .7s 1.95s
    final tx = _text.transform(kfP(t, 1950, 700));

    return ColoredBox(
      color: const Color(0xFF0D232B),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: bg,
              child: const CssBox(
                bg: [
                  CssRadial(
                    [Color(0xFF2F6A7A), Color(0xFF1E4F5C), Color(0xFF143A45)],
                    stops: [0, .46, 1],
                    rx: 1.2,
                    ry: .7,
                    cx: .5,
                    cy: .44,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 195 - 230,
            top: 382 - 170,
            width: 460,
            height: 340,
            child: Opacity(
              opacity: glowO.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: glowS,
                child: const CssBox(
                  bg: [
                    CssRadial.closestSide(
                      [Color(0x3896D7E1), Color(0x0096D7E1)],
                      stops: [0, .72],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 322,
            height: 120,
            child: Opacity(
              opacity: (1 - lo).clamp(0.0, 1.0),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.translationValues(0, -6 * lo, 0)
                  ..scaleByDouble(1 + .05 * lo, 1 + .05 * lo, 1, 1),
                child: Center(
                  child: Transform.translate(
                    offset: const Offset(-8 / 2, 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 150,
                          height: 120,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Shadow: left 30 right 6 top 104 h22.
                              Positioned(
                                left: 30,
                                right: 6,
                                top: 104,
                                height: 22,
                                child: Opacity(
                                  opacity: sk,
                                  child: Transform.scale(
                                    scaleX: .6 + .4 * sk,
                                    child: const CssBox(
                                      bg: [
                                        CssRadial.closestSide(
                                          [Color.fromRGBO(4, 18, 24, .5), Color.fromRGBO(4, 18, 24, 0)],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: Transform(
                                  alignment: const FractionalOffset(.4, .85),
                                  transform: Matrix4.translationValues(kx, 0, 0)
                                    ..multiply(Matrix4.skewX(rad(ks))),
                                  child: Stack(
                                    key: logoKey,
                                    children: [
                                      Positioned.fill(
                                        child: CustomPaint(
                                          painter: SplashStrokeDrawPainter(t: t),
                                        ),
                                      ),
                                      if (inn > 0)
                                        Positioned.fill(
                                          child: Opacity(
                                            opacity: inn,
                                            child: const CustomPaint(
                                              painter: SplashStickerPainter(),
                                            ),
                                          ),
                                        ),
                                      Positioned.fill(
                                        child: CustomPaint(
                                          painter: SplashSheenPainter(
                                            translateX: glX,
                                            opacity: glO,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // `margin-left:-30px; padding:0 6px 14px 14px;
                        // clip-path:inset(-20px -20px -20px 6px)`.
                        Transform.translate(
                          offset: const Offset(-30, 0),
                          child: _Wordmark(t: t),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 478,
            child: Opacity(
              opacity: tx,
              child: Transform.translate(
                offset: Offset(0, 8 * (1 - tx)),
                child: Text(
                  'Alt du trenger, ett ærend.',
                  textAlign: TextAlign.center,
                  style: inter(14, em: .01, color: const Color(0xFFCFE3E8)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.t});

  final double t;

  static const Cubic _letter = LfSplashScene._letter;

  static TextStyle get _style => jakarta(
    66,
    em: -.045,
    height: 1,
    color: const Color(0xFFF5F3EF),
    shadows: const [
      Shadow(color: Color(0xFFC9D4D8), offset: Offset(0, 1)),
      Shadow(color: Color(0xFFA9BAC0), offset: Offset(0, 2)),
      Shadow(color: Color(0xFF8CA2A9), offset: Offset(0, 3)),
      Shadow(color: Color.fromRGBO(3, 16, 24, .45), offset: Offset(0, 12), blurRadius: 10),
    ],
  );

  @override
  Widget build(BuildContext context) {
    const letters = ['r', 'e', 'n', 'd'];
    final style = _style;
    // spmGlans .9s 2.12s: background-position 130% → -30% (size 260%).
    final gp = cssEaseInOut.transform(kfP(t, 2120, 900));
    final pos = 1.3 + (-0.3 - 1.3) * gp;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 6, 0),
      child: ClipRect(
        clipper: const _LeftInsetClip(6 - 14),
        child: Stack(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < letters.length; i++)
                  Builder(
                    builder: (context) {
                      final p = kfP(t, 1360 + 65.0 * i, 620);
                      final e = _letter.transform(p);
                      final o = kf(p, const [0, .35, 1], const [0, 1, 1], _letter);
                      return Opacity(
                        opacity: o.clamp(0.0, 1.0),
                        child: Transform(
                          transform: Matrix4.translationValues(-34 * (1 - e), 0, 0)
                            ..scaleByDouble(.85 + .15 * e, 1, 1, 1),
                          child: Text(letters[i], style: style),
                        ),
                      );
                    },
                  ),
              ],
            ),
            if (t > 2120 && t < 3020)
              Positioned.fill(
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (r) {
                    // A 260%-wide band image; position p maps the band's
                    // left edge to (r.width - 2.6w) * p.
                    final bw = r.width * 2.6;
                    final left = (r.width - bw) * pos;
                    return LinearGradient(
                      colors: const [
                        Color(0x00FFFFFF),
                        Color(0xF2FFFFFF),
                        Color(0x00FFFFFF),
                      ],
                      stops: const [.4, .5, .6],
                      transform: _Shift(left, bw, r.width),
                    ).createShader(Rect.fromLTWH(0, 0, r.width, r.height));
                  },
                  child: Text(
                    'rend',
                    style: style.copyWith(shadows: const [], color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Gradient laid out over a [bw]-wide box starting at [left] (100deg ≈
/// horizontal for this short text).
class _Shift extends GradientTransform {
  const _Shift(this.left, this.bw, this.w);

  final double left;
  final double bw;
  final double w;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(left, 0, 0)..scaleByDouble(bw / w, 1, 1, 1);
}

/// `clip-path: inset(-20px -20px -20px <left>px)` measured from the padded
/// box; [left] is relative to the text start.
class _LeftInsetClip extends CustomClipper<Rect> {
  const _LeftInsetClip(this.left);

  final double left;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(left, -20, size.width + 20, size.height + 20);

  @override
  bool shouldReclip(_LeftInsetClip oldClipper) => oldClipper.left != left;
}
