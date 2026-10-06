import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../kit/bergen_css.dart' show rgba;
import 'feed_icons.dart';
import 'utforsk_copy.dart';

// ── Utforsk · shared pieces (Launch prototype, design px) ───────────────────

/// The glass of the Forundringspose segment's cards (L5651, L5704, L5712):
/// `linear-gradient(180deg,rgba(255,255,255,.15),rgba(255,255,255,.06))`.
const List<CssBg> kUtfGlassBg = [
  CssLinear(180, [Color.fromRGBO(255, 255, 255, .15), Color.fromRGBO(255, 255, 255, .06)]),
];

/// `inset 0 1.5px 0 rgba(255,255,255,.32), inset 0 0 0 1px rgba(255,255,255,.12),
/// 0 3px 0 rgba(10,34,42,.55), 0 22px 30px -18px rgba(3,14,20,.85)`.
const List<CssShadow> kUtfGlassShadow = [
  CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .32)),
  CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .12)),
  CssShadow(0, 3, 0, 0, Color.fromRGBO(10, 34, 42, .55)),
  CssShadow(0, 22, 30, -18, Color.fromRGBO(3, 14, 20, .85)),
];

/// The feed's glass (`.14 → .06`, 1px `.2` border, L5498 / L5563 / L5571).
const List<CssBg> kFeedGlassBg = [
  CssLinear(180, [Color.fromRGBO(255, 255, 255, .14), Color.fromRGBO(255, 255, 255, .06)]),
];

/// The teal tile with its sunken base (`linear-gradient(160deg,#3F8798 0%,
/// #27606F 52%,#1A4654 100%)`, L5706 / L5714).
const List<CssBg> kUtfTileBg = [
  CssLinear(160, [Color(0xFF3F8798), Color(0xFF27606F), Color(0xFF1A4654)], [0, .52, 1]),
];
const List<CssShadow> kUtfTileShadow = [
  CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .32)),
  CssShadow.inset(0, -3, 5, 0, Color.fromRGBO(4, 20, 28, .42)),
  CssShadow(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .07)),
  CssShadow(0, 9, 12, -6, Color.fromRGBO(3, 16, 24, .8)),
];

/// The mint glass arrow disc (L5701, L5711).
class UtfPilDisk extends StatelessWidget {
  const UtfPilDisk({super.key, this.size = 30, this.icon = 12});

  final double size;
  final double icon;

  @override
  Widget build(BuildContext context) => CssBox(
    width: size,
    height: size,
    radius: BorderRadius.circular(size / 2),
    bg: const [
      CssLinear(180, [Color.fromRGBO(130, 242, 210, .3), Color.fromRGBO(92, 224, 184, .1)]),
    ],
    shadows: const [
      CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .32)),
      CssShadow.inset(0, -2, 4, 0, Color.fromRGBO(4, 30, 26, .32)),
      CssShadow(0, 0, 0, 1, Color.fromRGBO(92, 224, 184, .38)),
      CssShadow(0, 6, 10, -6, Color.fromRGBO(3, 16, 24, .85)),
    ],
    child: Center(child: feedIcon(FeedIcons.arrowRight, icon)),
  );
}

/// `pulsDot 1.8s ease-in-out infinite`: the glowing dot of the count chips.
class UtfPulsDot extends StatelessWidget {
  const UtfPulsDot({super.key, required this.color, this.size = 6, this.periodMs = 1800, this.glow = 6});

  final Color color;
  final double size;
  final double periodMs;
  final double glow;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: LfLoop(
      builder: (context, t, child) {
        final p = (t % periodMs) / periodMs;
        final s = kf(p, const [0, .5, 1], const [1, 1.35, 1], cssEaseInOut);
        final o = kf(p, const [0, .5, 1], const [1, .7, 1], cssEaseInOut);
        return Opacity(opacity: o, child: Transform.scale(scale: s, child: child));
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color, blurRadius: glow)],
        ),
      ),
    ),
  );
}

/// One-shot entrance used by the segment switch (`utfSeg`, L15225) and the
/// feed's filter change (`feedBytt`, L18518): from [from] / [scaleFrom] /
/// opacity 0 to rest, with opacity reaching 1 at [opacityAt] of the run.
///
/// Plays when [seq] changes, and on mount if [since] is under 900 ms ago —
/// a lazily built card that scrolls in later does not replay it.
class UtfInn extends StatefulWidget {
  const UtfInn({
    super.key,
    required this.seq,
    required this.child,
    this.since,
    this.delayMs = 0,
    this.durMs = 480,
    this.from = Offset.zero,
    this.scaleFrom = 1,
    this.opacityAt = 1,
    this.curve = Curves.linear,
  });

  final int seq;
  final DateTime? since;
  final double delayMs;
  final double durMs;
  final Offset from;
  final double scaleFrom;
  final double opacityAt;
  final Curve curve;
  final Widget child;

  @override
  State<UtfInn> createState() => _UtfInnState();
}

class _UtfInnState extends State<UtfInn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, value: 1);

  bool get _fresh => widget.since != null && DateTime.now().difference(widget.since!).inMilliseconds < 900;

  @override
  void initState() {
    super.initState();
    if (widget.seq > 0 && _fresh) WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  @override
  void didUpdateWidget(UtfInn old) {
    super.didUpdateWidget(old);
    if (widget.seq != old.seq && widget.seq > 0) _play();
  }

  void _play() {
    if (!mounted) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) == true) {
      _c.value = 1;
      return;
    }
    final total = widget.delayMs + widget.durMs;
    _c.duration = Duration(milliseconds: total.round());
    _c.forward(from: 0);
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
      if (_c.value >= 1) return child!;
      final total = widget.delayMs + widget.durMs;
      final p = kfP(_c.value * total, widget.delayMs, widget.durMs);
      final k = widget.curve.transform(p);
      final o = kf(p, [0, widget.opacityAt], const [0, 1], widget.curve).clamp(0.0, 1.0);
      return Opacity(
        opacity: o,
        child: Transform.translate(
          offset: widget.from * (1 - k),
          child: Transform.scale(scale: widget.scaleFrom + (1 - widget.scaleFrom) * k, child: child),
        ),
      );
    },
  );
}

/// `feedBytt`'s exit (L18525): the visible posts slide 10 px down, shrink to
/// .985 and fade over 170 ms (`cubic-bezier(.4,0,1,1)`), 30 ms apart.
class UtfUt extends StatelessWidget {
  const UtfUt({super.key, required this.leaving, required this.index, required this.child});

  final bool leaving;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: leaving ? 1 : 0),
    duration: Duration(milliseconds: leaving ? 170 + math.min(index, 3) * 30 : 0),
    curve: Interval(leaving ? math.min(index, 3) * 30 / (170 + math.min(index, 3) * 30) : 0, 1,
        curve: const Cubic(.4, 0, 1, 1)),
    child: child,
    builder: (context, v, child) => v == 0
        ? child!
        : Opacity(
            opacity: 1 - v,
            child: Transform.translate(
              offset: Offset(0, 10 * v),
              child: Transform.scale(scale: 1 - .015 * v, child: child),
            ),
          ),
  );
}

/// One category orb (`stories`, L5468–5485): a 52 px disc that turns orange,
/// lifts 3 px and grows to 1.08 when it is the filter (`.28s
/// cubic-bezier(.3,1.3,.5,1)`, shadow and colour `.28s ease`), the «nytt» dot
/// when the category has a post from today, and the label in mint.
class UtfOrb extends StatelessWidget {
  const UtfOrb({
    super.key,
    required this.slug,
    required this.active,
    required this.hasNew,
    required this.onTap,
  });

  final String slug;
  final bool active;
  final bool hasNew;
  final VoidCallback onTap;

  static const _on = [
    CssLinear(180, [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], [0, .56, 1]),
  ];
  static const _off = [
    CssLinear(165, [Color(0xFF2A6272), Color(0xFF1E4F5C)]),
  ];
  static const _onShadow = [
    CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .45)),
    CssShadow.inset(0, -4, 6, 0, Color.fromRGBO(120, 45, 15, .3)),
    CssShadow(0, 0, 0, 3, Color(0xFF12333D)),
    CssShadow(0, 0, 0, 4, Color.fromRGBO(0, 0, 0, .35)),
    CssShadow(0, -2, 0, 4, Color.fromRGBO(0, 0, 0, .45)),
    CssShadow(0, 2, 0, 4, Color.fromRGBO(255, 255, 255, .22)),
    CssShadow(0, 0, 0, 7, Color.fromRGBO(255, 255, 255, .05)),
    CssShadow(0, 3, 0, 3, Color(0xFFC4491A)),
    CssShadow(0, 12, 18, -6, Color.fromRGBO(200, 70, 25, .85)),
  ];
  static const _offShadow = [
    CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .28)),
    CssShadow(0, 2, 0, 0, Color.fromRGBO(11, 38, 45, .85)),
    CssShadow(0, 7, 11, -5, Color.fromRGBO(15, 45, 55, .75)),
  ];

  @override
  Widget build(BuildContext context) {
    final label = UtforskCopy.a1_feed_orb(slug);
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) == true;
    final ms = reduce ? 0 : 280;
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          key: Key('a1_feed_orb_$slug'),
          width: 66,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: active ? 1 : 0),
                duration: Duration(milliseconds: ms),
                curve: const Cubic(.3, 1.3, .5, 1),
                builder: (context, k, child) => Transform.translate(
                  offset: Offset(0, -3 * k),
                  child: Transform.scale(scale: 1 + .08 * k, child: child),
                ),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: RepaintBoundary(child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CssBox(width: 52, height: 52, radius: BorderRadius.circular(26), bg: _off, shadows: _offShadow),
                      AnimatedOpacity(
                        opacity: active ? 1 : 0,
                        duration: Duration(milliseconds: ms),
                        curve: cssEase,
                        child: CssBox(width: 52, height: 52, radius: BorderRadius.circular(26), bg: _on, shadows: _onShadow),
                      ),
                      Center(child: _iconWithShadow(FeedIcons.orb(slug), 26)),
                      if (hasNew)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            key: Key('a1_feed_orb_new_$slug'),
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF26D3D),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF12333D), width: 2.5),
                              boxShadow: [BoxShadow(color: rgba(233, 92, 44, .8), offset: const Offset(0, 3), blurRadius: 6, spreadRadius: -2)],
                            ),
                          ),
                        ),
                    ],
                  )),
                ),
              ),
              const SizedBox(height: 6),
              AnimatedDefaultTextStyle(
                duration: Duration(milliseconds: reduce ? 0 : 250),
                curve: cssEase,
                style: inter(11, weight: FontWeight.w800, color: active ? const Color(0xFF7FF0CB) : rgba(255, 255, 255, .6)),
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// `filter: drop-shadow(0 2px 3px rgba(15,31,43,.35))` on the icon.
  static Widget _iconWithShadow(String svg, double size) => Stack(
    clipBehavior: Clip.none,
    children: [
      Transform.translate(
        offset: const Offset(0, 2),
        child: ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
          child: feedIcon(svg, size, color: rgba(15, 31, 43, .35)),
        ),
      ),
      feedIcon(svg, size),
    ],
  );
}

/// A baked prototype symbol (`svg_bake.py`): a PNG of the symbol's viewBox
/// plus [pad] viewBox units of transparent room on every side, drawn so the
/// viewBox fills [width] × [height].
class UtfBaked extends StatelessWidget {
  const UtfBaked(this.asset, {super.key, required this.width, required this.height, required this.vbWidth, this.pad = 0});

  final String asset;
  final double width;
  final double height;
  final double vbWidth;
  final double pad;

  @override
  Widget build(BuildContext context) {
    final k = width / vbWidth;
    return SizedBox(
      width: width,
      height: height,
      child: OverflowBox(
        maxWidth: width + 2 * pad * k,
        maxHeight: height + 2 * pad * k,
        child: Image.asset(asset, width: width + 2 * pad * k, height: height + 2 * pad * k, fit: BoxFit.fill, filterQuality: FilterQuality.medium),
      ),
    );
  }
}

/// `#pose-bag` (viewBox `10 8 37 40`).
Widget utfPoseBag(double width, double height) =>
    UtfBaked('assets/images/utforsk/pose_bag.png', width: width, height: height, vbWidth: 37, pad: 4);

/// `#pose3d` (viewBox `0 0 64 64`).
Widget utfPose3d(double size) => UtfBaked('assets/images/utforsk/pose3d.png', width: size, height: size, vbWidth: 64, pad: 6);

/// `#stakk3d` (viewBox `0 0 60 58`).
Widget utfStakk3d(double w, double h) => UtfBaked('assets/images/utforsk/stakk3d.png', width: w, height: h, vbWidth: 60, pad: 4);

/// `#merke` (viewBox `-30 -14 172 138`).
Widget utfMerke(double w, double h) => Image.asset('assets/images/utforsk/merke.png', width: w, height: h, fit: BoxFit.fill, filterQuality: FilterQuality.medium);

/// `#pose-vann` — the bag on its raft (Step 2's `hjem_pose.svg`, 56 × 62).
Widget utfPoseVann(double w, double h) => SvgPicture.asset('assets/svgs/hjem/hjem_pose.svg', width: w, height: h);
