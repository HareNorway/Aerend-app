import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_icons.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/auth/launch/lf_widgets.dart';

// ── Sporing · shared bits (Launch prototype L6400–7340) ─────────────────────
// Small widgets the tracking screens share: the glass keys, the live pulse
// dot, the sheen sweep, the sticker/stamp/bubble keyframes and the Ægil
// images. Everything is in design px (the screens sit in an LfFrame).

const Color kSpMint = Color(0xFF5CE0B8);
const Color kSpMintLight = Color(0xFF7FF0CB);
const Color kSpOrange = Color(0xFFF26D3D);
const Color kSpInk = Color(0xFF23201D);
const Color kSpLabel = Color(0xFFBFD8DF);
const Color kSpSub = Color(0xFFDCE9EC);
const Color kSpTeal = Color(0xFF1E4F5C);
const Color kSpPaperInk = Color(0xFF173E48);

Color rgba(int r, int g, int b, double a) => Color.fromRGBO(r, g, b, a);

/// `cubic-bezier(.3,1.3,.5,1)` (`bobleInn`).
const Cubic cssBoble = Cubic(.3, 1.3, .5, 1);

/// `cubic-bezier(.3,1.2,.5,1)` (`klistre`, `stigOpp`).
const Cubic cssKlistre = Cubic(.3, 1.2, .5, 1);

/// `cubic-bezier(.3,1.4,.5,1)` (`stempel`, `etaPopp`).
const Cubic cssStempel = Cubic(.3, 1.4, .5, 1);

/// `cubic-bezier(.2,.9,.3,1)` (`skjermInn`, `arkOpp`).
const Cubic cssSkjerm = Cubic(.2, .9, .3, 1);

/// `cubic-bezier(.2,1.2,.4,1)` (the big `spOpp`).
const Cubic cssOppStor = Cubic(.2, 1.2, .4, 1);

/// `cubic-bezier(.2,1.1,.4,1)` (`spChipC`).
const Cubic cssChip = Cubic(.2, 1.1, .4, 1);

/// The Ægil sticker images (`assets/aegil-s/*.png` in the prototype).
Widget aegil(String name, {double? w, double? h, BoxFit fit = BoxFit.contain}) => Image.asset('assets/images/dashboard/$name.png', width: w, height: h, fit: fit, filterQuality: FilterQuality.medium);

/// A store logo in a disc: the network image, else the first letter.
class SpLogo extends StatelessWidget {
  const SpLogo({super.key, required this.size, this.url, this.name = '', this.radius, this.bg = Colors.white});

  final double size;
  final String? url;
  final String name;
  final double? radius;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    final r = radius ?? size / 2;
    final u = url;
    return ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: SizedBox(
        width: size,
        height: size,
        child: u != null && u.isNotEmpty ? Image.network(u, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _bokstav()) : _bokstav(),
      ),
    );
  }

  Widget _bokstav() => ColoredBox(
    color: bg,
    child: Center(
      child: Text(name.isEmpty ? 'Æ' : name.characters.first.toUpperCase(), style: jakarta(size * .46, color: const Color(0xFF7A3A22))),
    ),
  );
}

/// `livePuls` — the dot with its expanding ring (scale .6→1.9, opacity .9→0).
class SpPuls extends StatelessWidget {
  const SpPuls({super.key, required this.size, required this.color, this.dur = 1800, this.glow, this.gradient});

  final double size;
  final Color color;
  final double dur;
  final Color? glow;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: gradient == null ? color : null,
              gradient: gradient,
              boxShadow: glow == null ? null : [BoxShadow(color: glow!, blurRadius: cssSigma(8) * 2)],
            ),
          ),
        ),
        Positioned.fill(
          child: LfLoop(
            builder: (context, t, child) {
              final p = cssEaseOut.transform((t / dur) % 1.0);
              return Opacity(
                opacity: .9 * (1 - p),
                child: Transform.scale(scale: .6 + 1.3 * p, child: child),
              );
            },
            child: DecoratedBox(
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
          ),
        ),
      ],
    ),
  );
}

/// `sveipLys` — a sheen band sweeping across (`translateX(-120%)→120%` over
/// the first 45 % of the cycle). Fill its parent; the parent clips.
class SpSveip extends StatelessWidget {
  const SpSveip({super.key, this.dur = 5000, this.delay = 1000, this.alpha = .22, this.deg = 105});

  final double dur, delay, alpha, deg;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: IgnorePointer(
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth.isFinite ? box.maxWidth : 390.0;
            final h = box.maxHeight.isFinite ? box.maxHeight : 80.0;
            return LfLoop(
              builder: (context, t, child) {
                final e = t - delay;
                final p = e < 0 ? 0.0 : (e / dur) % 1.0;
                final x = kf(p, const [0, .45, 1], const [-1.2, 1.2, 1.2], cssEaseInOut);
                return Transform.translate(offset: Offset(x * w, 0), child: child);
              },
              child: OverflowBox(
                maxWidth: w * 2.2,
                maxHeight: h * 1.8,
                child: SizedBox(
                  width: w * 2.2,
                  height: h * 1.8,
                  child: CssBox(
                    bg: [
                      CssLinear(deg, [rgba(255, 255, 255, 0), rgba(255, 255, 255, alpha), rgba(255, 255, 255, 0)], const [.44, .5, .56]),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

/// `bobleInn` — translateY(10→-2→0) scale(.9→1.02→1), opacity 0→1.
class SpBobleInn extends StatelessWidget {
  const SpBobleInn({super.key, required this.child, this.delay = 0, this.dur = 500, this.origin = Alignment.center});

  final Widget child;
  final double delay, dur;
  final Alignment origin;

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: delay + dur,
    child: child,
    builder: (context, t, child) {
      final p = cssBoble.transform(kfP(t, delay, dur));
      final y = kf(p, const [0, .6, 1], const [10, -2, 0]);
      final k = kf(p, const [0, .6, 1], const [.9, 1.02, 1]);
      final o = kf(p, const [0, .6, 1], const [0, 1, 1]);
      return Opacity(
        opacity: o.clamp(0.0, 1.0),
        child: Transform(alignment: origin, transform: Matrix4.translationValues(0, y, 0)..scaleByDouble(k, k, 1, 1), child: child),
      );
    },
  );
}

/// `bobleFraAegil` — the speech bubble growing out of Ægil (origin 0 100%).
class SpBobleFraAegil extends StatelessWidget {
  const SpBobleFraAegil({super.key, required this.child, this.delay = 1000, this.dur = 550});

  final Widget child;
  final double delay, dur;

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: delay + dur,
    child: child,
    builder: (context, t, child) {
      final p = cssBoble.transform(kfP(t, delay, dur));
      final x = kf(p, const [0, .6, 1], const [-14, 2, 0]);
      final k = kf(p, const [0, .6, 1], const [.7, 1.03, 1]);
      final o = kf(p, const [0, .6, 1], const [0, 1, 1]);
      return Opacity(
        opacity: o.clamp(0.0, 1.0),
        child: Transform(alignment: Alignment.bottomLeft, transform: Matrix4.translationValues(x, 0, 0)..scaleByDouble(k, k, 1, 1), child: child),
      );
    },
  );
}

/// `klistre` — a sticker slapped on: scale 1.5→.97→1.03→1, rotate
/// −14→−4→−6→−5 deg, opacity 0→1 at 55 %.
class SpKlistre extends StatelessWidget {
  const SpKlistre({super.key, required this.child, this.delay = 0, this.dur = 600});

  final Widget child;
  final double delay, dur;

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: delay + dur,
    child: child,
    builder: (context, t, child) {
      final p = cssKlistre.transform(kfP(t, delay, dur));
      const st = [0.0, .55, .75, 1.0];
      final k = kf(p, st, const [1.5, .97, 1.03, 1]);
      final r = kf(p, st, const [-14, -4, -6, -5]);
      final o = kf(p, const [0, .55, 1], const [0, 1, 1]);
      return Opacity(
        opacity: o.clamp(0.0, 1.0),
        child: Transform(alignment: Alignment.center, transform: Matrix4.rotationZ(rad(r))..scaleByDouble(k, k, 1, 1), child: child),
      );
    },
  );
}

/// `stempel` — a stamp pressed on: scale 2.2→.92→1, rotate −18→−12, opacity
/// 0→1 at 55 %.
class SpStempel extends StatelessWidget {
  const SpStempel({super.key, required this.child, this.delay = 500, this.dur = 700});

  final Widget child;
  final double delay, dur;

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: delay + dur,
    child: child,
    builder: (context, t, child) {
      final p = cssStempel.transform(kfP(t, delay, dur));
      final k = kf(p, const [0, .55, 1], const [2.2, .92, 1]);
      final r = kf(p, const [0, .55, 1], const [-18, -12, -12]);
      final o = kf(p, const [0, .55, 1], const [0, 1, 1]);
      return Opacity(
        opacity: o.clamp(0.0, 1.0),
        child: Transform(alignment: Alignment.center, transform: Matrix4.rotationZ(rad(r))..scaleByDouble(k, k, 1, 1), child: child),
      );
    },
  );
}

/// `spChipC` — the SPART TID chip: scale 1.7→.96→1.03→1, rotate
/// −10→−2→−3.5→−3, opacity 0→1 at 55 %.
class SpChipC extends StatelessWidget {
  const SpChipC({super.key, required this.child, this.delay = 1600, this.dur = 500});

  final Widget child;
  final double delay, dur;

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: delay + dur,
    child: child,
    builder: (context, t, child) {
      final p = cssChip.transform(kfP(t, delay, dur));
      const st = [0.0, .55, .75, 1.0];
      final k = kf(p, st, const [1.7, .96, 1.03, 1]);
      final r = kf(p, st, const [-10, -2, -3.5, -3]);
      final o = kf(p, const [0, .55, 1], const [0, 1, 1]);
      return Opacity(
        opacity: o.clamp(0.0, 1.0),
        child: Transform(alignment: Alignment.center, transform: Matrix4.rotationZ(rad(r))..scaleByDouble(k, k, 1, 1), child: child),
      );
    },
  );
}

/// `etaPopp` — translateY(4→0) scale(.9→1.06→1), opacity 0→1.
class SpEtaPopp extends StatelessWidget {
  const SpEtaPopp({super.key, required this.child, this.delay = 0, this.dur = 500});

  final Widget child;
  final double delay, dur;

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: delay + dur,
    child: child,
    builder: (context, t, child) {
      final p = cssStempel.transform(kfP(t, delay, dur));
      final y = kf(p, const [0, .6, 1], const [4, 0, 0]);
      final k = kf(p, const [0, .6, 1], const [.9, 1.06, 1]);
      final o = kf(p, const [0, .6, 1], const [0, 1, 1]);
      return Opacity(
        opacity: o.clamp(0.0, 1.0),
        child: Transform(alignment: Alignment.center, transform: Matrix4.translationValues(0, y, 0)..scaleByDouble(k, k, 1, 1), child: child),
      );
    },
  );
}

/// `aeKnSvev` + `aeKnSkygge` — a key floating (translateY 0→−5→0, 3.4 s)
/// over its own soft shadow (left/right 10 %, 15 px tall, scaleX 1→.82).
class SpSvev extends StatelessWidget {
  const SpSvev({super.key, required this.child, this.phase = 0, this.shadow = const Color.fromRGBO(8, 26, 32, .5)});

  final Widget child;

  /// Negative animation delay in ms (`-0.9s` → 900).
  final double phase;
  final Color shadow;

  @override
  Widget build(BuildContext context) => LfLoop(
    child: child,
    builder: (context, t, child) {
      final p = ((t + phase) / 3400) % 1.0;
      final y = kf(p, const [0, .5, 1], const [0, -5, 0], cssEaseInOut);
      final sx = kf(p, const [0, .5, 1], const [1, .82, 1], cssEaseInOut);
      final so = kf(p, const [0, .5, 1], const [1, .6, 1], cssEaseInOut);
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionalTranslation(
                  translation: const Offset(0, 1),
                  child: Transform.translate(
                    offset: Offset(0, 1 - y),
                    child: Opacity(
                      opacity: so,
                      child: Transform.scale(
                        scaleX: sx * .8,
                        child: SizedBox(
                          height: 15,
                          width: 1000,
                          child: CssBox(
                            bg: [
                              CssRadial.closestSide([shadow, rgba(0, 0, 0, 0)], stops: const [0, .72]),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Transform.translate(offset: Offset(0, y), child: child),
        ],
      );
    },
  );
}

/// The header's glass key (42 × 42, radius 15): the gradient, the inner
/// rim, the lift, the highlight cap.
class SpGlassKey extends StatelessWidget {
  const SpGlassKey({super.key, required this.child, required this.onTap, this.size = 42, this.radius = 15, this.semantics});

  final Widget child;
  final VoidCallback? onTap;
  final double size, radius;
  final String? semantics;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semantics,
    child: LfPress(
      onTap: onTap,
      dy: 2.5,
      child: CssBox(
        width: size,
        height: size,
        radius: BorderRadius.circular(radius),
        clip: true,
        bg: [
          CssLinear(180, [rgba(255, 255, 255, .22), rgba(255, 255, 255, .07)]),
        ],
        shadows: [
          CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .42)),
          CssShadow.inset(0, 0, 0, 1, rgba(255, 255, 255, .14)),
          CssShadow.inset(0, -2, 0, 0, rgba(4, 20, 28, .2)),
          CssShadow(0, 3, 0, 0, rgba(4, 20, 28, .55)),
          CssShadow(0, 12, 18, -10, rgba(3, 14, 20, .85)),
        ],
        child: Stack(
          children: [
            Positioned(
              left: 5,
              right: 5,
              top: 3,
              height: size * .42,
              child: IgnorePointer(
                child: CssBox(
                  radius: const BorderRadius.vertical(top: Radius.circular(11), bottom: Radius.elliptical(16, 8)),
                  bg: [
                    CssLinear(180, [rgba(255, 255, 255, .26), rgba(255, 255, 255, 0)]),
                  ],
                ),
              ),
            ),
            Center(child: child),
          ],
        ),
      ),
    ),
  );
}

/// The panel's glass surface (the Sammendrag / Detaljer / action keys).
class SpGlass extends StatelessWidget {
  const SpGlass({super.key, this.child, this.width, this.height, this.radius = 16, this.padding, this.onTap, this.semantics});

  final Widget? child;
  final double? width, height;
  final double radius;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final String? semantics;

  @override
  Widget build(BuildContext context) {
    final box = CssBox(
      width: width,
      height: height,
      padding: padding,
      radius: BorderRadius.circular(radius),
      bg: [
        CssLinear(180, [rgba(255, 255, 255, .17), rgba(255, 255, 255, .08)]),
      ],
      shadows: [
        CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .32)),
        CssShadow(0, 0, 0, 1, rgba(255, 255, 255, .2)),
        CssShadow(0, 3, 0, 0, rgba(6, 30, 38, .6)),
        CssShadow(0, 12, 18, -10, rgba(4, 18, 26, .85)),
      ],
      child: child,
    );
    if (onTap == null) return box;
    return Semantics(
      button: true,
      label: semantics,
      child: LfPress(onTap: onTap, dy: 2.5, child: box),
    );
  }
}

/// The soft white tile behind an icon (28/34/42 px).
class SpTile extends StatelessWidget {
  const SpTile({super.key, required this.size, required this.radius, required this.colors, required this.child, this.inner = const Color.fromRGBO(90, 60, 20, .3)});

  final double size, radius;
  final List<Color> colors;
  final Widget child;
  final Color inner;

  @override
  Widget build(BuildContext context) => CssBox(
    width: size,
    height: size,
    radius: BorderRadius.circular(radius),
    bg: [
      CssRadial(colors, stops: const [0, .55, 1], rx: 1.3, ry: 1.1, cx: .28, cy: 0),
    ],
    shadows: [CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .95)), CssShadow.inset(0, -6, 10, -6, inner)],
    child: Center(child: child),
  );
}

/// The warm tile colours (`#FFF6E8 → #F5DCB4 → #DDB178`).
const List<Color> kSpTileVarm = [Color(0xFFFFF6E8), Color(0xFFF5DCB4), Color(0xFFDDB178)];

/// The teal tile colours (`#F3FAFB → #BFE0E6 → #8FC0CA`).
const List<Color> kSpTileTeal = [Color(0xFFF3FAFB), Color(0xFFBFE0E6), Color(0xFF8FC0CA)];

/// The food tile colours (`#FFF1E6 → #F8D3B6 → #E9AE86`).
const List<Color> kSpTileMat = [Color(0xFFFFF1E6), Color(0xFFF8D3B6), Color(0xFFE9AE86)];

/// The Vipps tile colours (`#FFF3EE → #F9B9A8 → #E88A78`).
const List<Color> kSpTileVipps = [Color(0xFFFFF3EE), Color(0xFFF9B9A8), Color(0xFFE88A78)];

/// A stroke icon from the prototype's 24-box SVG paths.
Widget spIkon(String d, {Key? key, double size = 16, Color color = Colors.white, double width = 2.2, String extra = ''}) => LfStroke(d, key: key, size: size, color: color, width: width, extra: extra);

// Icon paths (prototype SVGs).
const String kSpIkonTilbake = 'M15 5.5l-6.5 6.5 6.5 6.5';
const String kSpIkonHjelp = 'M9.5 9.5a2.5 2.5 0 1 1 3.5 2.3c-.7.4-1 1-1 1.7M12 17h.01';
const String kSpIkonHake = 'M5 12.5l4.5 4.5L19 7.5';
const String kSpIkonPose = 'M5 8h14l-1.2 11.4a2 2 0 0 1-2 1.8H8.2a2 2 0 0 1-2-1.8ZM9 8V6a3 3 0 0 1 6 0v2';
const String kSpIkonKvittering = 'M6 3h12v18l-6-4-6 4zM9 8h6M9 12h4';
const String kSpIkonKvitteringEnkel = 'M6 3h12v18l-6-4-6 4z';
const String kSpIkonChat = 'M20.5 12c0 4.1-3.8 7.4-8.5 7.4-1 0-2-.15-2.9-.42L4 20.5l1.6-3.7A7 7 0 0 1 3.5 12c0-4.1 3.8-7.4 8.5-7.4s8.5 3.3 8.5 7.4zM8.8 11.8h.01M12 11.8h.01M15.2 11.8h.01';
const String kSpIkonChatEnkel = 'M4 5h16v11H8l-4 4z';
const String kSpIkonChatBoble = 'M21 12a8 8 0 0 1-11.6 7.1L4 21l1.9-5.4A8 8 0 1 1 21 12z';
const String kSpIkonTelefon = 'M5.5 4.5h4l2 5-2.5 1.5a10 10 0 0 0 4.5 4.5L15 17l5 2v4h-1A15.5 15.5 0 0 1 3.5 7.5v-3z';
const String kSpIkonTelefon2 = 'M5 4h4l2 5-2.5 1.5a11 11 0 0 0 5 5L15 13l5 2v4a2 2 0 0 1-2 2A16 16 0 0 1 3 6a2 2 0 0 1 2-2';
const String kSpIkonPin = 'M12 21s7-6.4 7-11.4A7 7 0 0 0 5 9.6C5 14.6 12 21 12 21z';
const String kSpIkonPinExtra = '<circle cx="12" cy="9.6" r="2.6"/>';
const String kSpIkonHus = 'M4 10l8-6 8 6v10H4zM9 20v-6h6v6';
const String kSpIkonHus2 = 'M4 10.5L12 4l8 6.5M6 9.5V20h12V9.5M10 20v-5h4v5';
const String kSpIkonPil = 'M9 5l7 7-7 7';
const String kSpIkonPilLiten = 'M9 6l6 6-6 6';
const String kSpIkonKryss = 'M6 6l12 12M18 6L6 18';
const String kSpIkonKlokke = 'M12 9v4l3 2M9 2h6';
const String kSpIkonKlokkeExtra = '<circle cx="12" cy="13" r="8"/>';
const String kSpIkonSkjold = 'M12 3l7 3v6c0 4-3 7-7 9-4-2-7-5-7-9V6zM9 12l2.2 2.2L15.5 10';
const String kSpIkonButikk = 'M4 9l2-5h12l2 5M4 9h16v11H4zM10 20v-5h4v5';
const String kSpIkonSend = 'M22 2L11 13M22 2l-7 20-4-9-9-4z';
const String kSpIkonOpp = 'M12 19V5M5 12l7-7 7 7';
const String kSpIkonInfo = 'M12 8v4M12 16h.01';
const String kSpIkonInfoExtra = '<circle cx="12" cy="12" r="9"/>';
const String kSpIkonMangler = 'M6 8h12l1 13H5zM9 8V6a3 3 0 0 1 6 0v2M12 12v4M12 18.5v.5';
const String kSpIkonFeilVare = 'M4 7h16l-1.5 13h-13zM9.5 11.5l5 5M14.5 11.5l-5 5';
const String kSpIkonKomAldri = 'M12 7v5l3 2';
const String kSpIkonKomAldriExtra = '<circle cx="12" cy="12" r="9"/>';
const String kSpIkonHeadset = 'M12 3a8 8 0 0 0-8 8v3a2 2 0 0 0 2 2h1v-5H5M20 14v-3a8 8 0 0 0-8-8M19 16h-1v-5h2a2 2 0 0 1 2 2v1a2 2 0 0 1-2 2M19 16a4 4 0 0 1-4 4h-2';
const String kSpIkonDemp = 'M5.5 11a6.5 6.5 0 0 0 13 0M12 17.5V21M4 4l16 16';
const String kSpIkonDempExtra = '<rect x="9" y="3" width="6" height="11" rx="3"/>';
const String kSpIkonHoyttaler = 'M4 9v6h4l5 4V5L8 9zM16 8.5a5 5 0 0 1 0 7M18.5 6a8.5 8.5 0 0 1 0 12';
const String kSpIkonFolk = 'M3.5 19.5c.9-3.2 3-4.8 5.5-4.8s4.6 1.6 5.5 4.8M16.5 14.9c1.9.4 3.3 1.7 4 3.9';
const String kSpIkonFolkExtra = '<circle cx="9" cy="8.5" r="3"/><circle cx="16.8" cy="9.5" r="2.4"/>';
const String kSpIkonDel = 'M4 12v7a1 1 0 0 0 1 1h14a1 1 0 0 0 1-1v-7M16 6l-4-4-4 4M12 2v13';
const String kSpIkonKopier = 'M5 15V5a1 1 0 0 1 1-1h9';
const String kSpIkonKopierExtra = '<rect x="9" y="9" width="11" height="11" rx="2"/>';

/// `#merke-flat` — the flat Æ mark, teal with the orange dash.
Widget spMerkeFlat({double w = 23, double h = 18, Color color = kSpTeal}) => LfSvg(lfMerkeInk(color), w: w, h: h);

/// Design-px text shadow for the big white titles over the scenes.
List<Shadow> spTekstSkygge([double a = .6]) => [Shadow(color: rgba(15, 31, 43, a), offset: const Offset(0, 2)), Shadow(color: rgba(3, 16, 24, a + .1), offset: const Offset(0, 14), blurRadius: 30)];

/// Clock text, `HH:MM`.
String spKlokke(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// `mm:ss` from seconds.
String spMmSs(int v) => '${(v ~/ 60).toString().padLeft(2, '0')}:${(v % 60).toString().padLeft(2, '0')}';

/// Norwegian thousands (`1 240`).
String spTall(num n) {
  final s = n.round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return b.toString();
}

/// `N kr`, whole kroner.
String spKr(num n) => '${spTall(n)} kr';

/// Triangle wave for `animation-direction: alternate`.
double spAlternate(double t, double dur, double delay) {
  final e = math.max(0.0, t - delay);
  final p = (e / dur) % 2.0;
  return p <= 1 ? p : 2 - p;
}

/// The order's points from `points/me/ledger`: a direct `points` / `amount`
/// / `earned` field, else the sum of the ledger's `earn` rows for this order.
int? spPoengForOrdre(Map<String, dynamic>? p, int orderId) {
  if (p == null) return null;
  final direkte = (p['points'] ?? p['amount'] ?? p['earned']) as num?;
  if (direkte != null) return direkte.toInt();
  final ledger = p['ledger'];
  if (ledger is! List) return null;
  var sum = 0;
  var traff = false;
  for (final r in ledger) {
    if (r is! Map) continue;
    if ('${r['ref_type']}' == 'order' && '${r['ref_id']}' == '$orderId' && '${r['kind']}' == 'earn') {
      sum += ((r['amount'] ?? 0) as num).toInt();
      traff = true;
    }
  }
  return traff ? sum : null;
}
