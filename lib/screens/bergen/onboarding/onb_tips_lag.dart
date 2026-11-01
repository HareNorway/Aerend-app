import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../common/auth/launch/lf_css.dart' show CssBox, CssLinear, CssShadow, inter, kf, rad, cssEaseInOut;
import '../../common/auth/launch/lf_motion.dart' show LfLoop, aegStaa;
import '../../common/auth/onboarding_kit.dart' show onbDisplay, OnbTimeline, onbP;
import '../kit/bergen_perf.dart';
import 'onb_maal.dart';
import 'onb_runde.dart';
import 'onb_status.dart';
import 'onb_tips.dart';

/// The Ægil-tips layer (Onboarding plan Step 4; prototype `data-cm-lag`
/// L11304–11323, z 79): the soft spotlight on the target, the bubble with
/// the small Ægil, and the «?» dot when no mark is up. It never blocks the
/// screen: everything but the bubble and the dot ignores pointers, and a
/// translucent catcher closes the mark on any tap outside it.
class OnbTipsLag extends StatefulWidget {
  const OnbTipsLag({super.key});

  @override
  State<OnbTipsLag> createState() => _OnbTipsLagState();
}

class _OnbTipsLagState extends State<OnbTipsLag> {
  final OnbTips _t = OnbTips.instance;
  OnbPrikk? _prikk;
  Timer? _prikkT;

  @override
  void initState() {
    super.initState();
    _t.addListener(_endret);
    OnbRunde.instance.addListener(_endret);
    OnbStatus.instance.addListener(_endret);
    OnbMaalRegistry.endring.addListener(_endret);
  }

  @override
  void dispose() {
    _t.removeListener(_endret);
    OnbRunde.instance.removeListener(_endret);
    OnbStatus.instance.removeListener(_endret);
    OnbMaalRegistry.endring.removeListener(_endret);
    _prikkT?.cancel();
    super.dispose();
  }

  void _endret() {
    if (!mounted) return;
    // The tour over a mark: the mark goes (`cmKan` is false while `rt` is up).
    if (OnbRunde.instance.aktiv && _t.naa != null) _t.lukk(grunn: 'runde');
    _lesPrikk();
    setState(() {});
  }

  /// The dot follows its target while it is on screen (the target scrolls).
  void _lesPrikk() {
    final p = _t.naa == null ? _t.prikk() : null;
    _prikk = p;
    if (p != null) {
      _prikkT ??= Timer.periodic(const Duration(milliseconds: 400), (_) {
        if (!mounted) return;
        final q = _t.naa == null ? _t.prikk() : null;
        if (q?.id != _prikk?.id || q?.m.rect != _prikk?.m.rect) setState(() => _prikk = q);
        if (q == null) {
          _prikkT?.cancel();
          _prikkT = null;
        }
      });
    } else {
      _prikkT?.cancel();
      _prikkT = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final W = mq.size.width, H = mq.size.height, s = W / 390, top = mq.padding.top, bunn = mq.padding.bottom;
    _t.bandLo = () => top + 76 * s;
    _t.bandHi = () => H - 144 * s;
    final rolig = BergenPerf.of(context) == BergenTier.still || MediaQuery.disableAnimationsOf(context);
    final v = _t.naa;
    if (v == null) {
      final p = _prikk;
      if (p == null) return const SizedBox.shrink();
      return _Lag(
        children: [
          Positioned(
            left: p.m.x + p.m.w - 12 * s,
            top: p.m.y - 5 * s,
            child: _Prikk(s: s, onTap: () => _t.vis(p.id, tving: true)),
          ),
        ],
      );
    }

    final m = v.m;
    final bw = 268 * s;
    double x;
    double? topPos, bottomPos;
    if (m != null) {
      x = (m.x + m.w / 2 - bw / 2).clamp(10 * s, W - bw - 10 * s);
      if (m.y > H * (300 / 844)) {
        bottomPos = H - m.y + 10 * s;
      } else {
        topPos = m.y + m.h + 10 * s;
      }
    } else {
      x = (W - bw) / 2;
      if (v.tip.pose == OnbTipPose.peekTop) {
        topPos = math.max(64 * s, top + 20 * s);
      } else {
        // The design's `bottom: 130px` in a frame with a 34 px home indicator.
        bottomPos = 130 * s + math.max(0, bunn - 34 * s);
      }
    }

    return _Lag(
      children: [
        // Any tap outside the bubble closes it (the bubble is opaque above).
        Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => _t.utenfor(),
          ),
        ),
        if (m != null)
          Positioned.fill(
            child: IgnorePointer(
              child: _Innfade(
                key: ValueKey('lys${v.t}'),
                ms: rolig ? 1 : 300,
                child: CustomPaint(
                  painter: _LysMaler(
                    RRect.fromRectAndRadius(m.rect.inflate(4 * s), Radius.circular(math.min(22, m.radius) + 4 * s)),
                    s,
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          left: x,
          top: topPos,
          bottom: bottomPos,
          width: bw,
          child: _Inn(
            key: ValueKey('kort${v.t}'),
            s: s,
            rolig: rolig,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 56 * s,
                  height: 56 * s,
                  child: IgnorePointer(child: _TipsAegil(pose: v.tip.pose, bilde: v.tip.bilde, s: s, rolig: rolig)),
                ),
                SizedBox(width: 8 * s),
                Expanded(child: _Boble(v: v, s: s)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The layer sits above the app's `MaterialApp`: its texts need a Material.
class _Lag extends StatelessWidget {
  const _Lag({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: Stack(clipBehavior: Clip.hardEdge, children: children),
  );
}

/// `cmInn .45s cubic-bezier(.2,1.2,.4,1)`: up 10 px, from scale .94.
class _Inn extends StatelessWidget {
  const _Inn({super.key, required this.s, required this.rolig, required this.child});
  final double s;
  final bool rolig;
  final Widget child;

  static const Curve _c = Cubic(.2, 1.2, .4, 1);

  @override
  Widget build(BuildContext context) {
    if (rolig) return child;
    return OnbTimeline(
      durationMs: 450,
      child: child,
      builder: (context, ms, child) {
        final p = _c.transform(onbP(ms, 0, 450));
        return Opacity(
          opacity: p.clamp(0.0, 1.0),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..translateByDouble(0, 10 * s * (1 - p), 0, 1)
              ..scaleByDouble(.94 + .06 * p, .94 + .06 * p, 1, 1),
            child: child,
          ),
        );
      },
    );
  }
}

/// `vkFade .3s`.
class _Innfade extends StatelessWidget {
  const _Innfade({super.key, required this.ms, required this.child});
  final int ms;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Duration(milliseconds: ms),
    builder: (context, o, child) => Opacity(opacity: o, child: child),
    child: child,
  );
}

/// The soft spotlight: `box-shadow 0 0 0 9999px rgba(4,18,26,.18), 0 0 0 2px
/// rgba(92,224,184,.9)` on a span 4 px around the target.
class _LysMaler extends CustomPainter {
  const _LysMaler(this.rr, this.s);
  final RRect rr;
  final double s;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(rr);
    canvas.drawPath(p, Paint()..color = const Color(0x2E04121A));
    canvas.drawRRect(
      rr.inflate(1 * s),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * s
        ..color = const Color(0xE65CE0B8),
    );
  }

  @override
  bool shouldRepaint(_LysMaler old) => old.rr != rr || old.s != s;
}

/// The bubble: radius 16 16 16 5, paper gradient, the stacked edges, the
/// «ÆGIL-TIPS» label with ×, the sentence, the action chip.
class _Boble extends StatelessWidget {
  const _Boble({required this.v, required this.s});
  final OnbTipVisning v;
  final double s;

  static const Color _mork = Color(0xFF12303B), _gronn = Color(0xFF1E8F72), _teal = Color(0xFF1E4F5C), _x = Color(0xFF8C9A9E);

  @override
  Widget build(BuildContext context) {
    final t = OnbTips.instance;
    return Semantics(
      container: true,
      liveRegion: true,
      child: GestureDetector(
        key: const Key('onb-tips'),
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: CssBox(
          radius: BorderRadius.only(
            topLeft: Radius.circular(16 * s),
            topRight: Radius.circular(16 * s),
            bottomRight: Radius.circular(16 * s),
            bottomLeft: Radius.circular(5 * s),
          ),
          bg: const [
            CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFF4F1EA)]),
          ],
          shadows: [
            const CssShadow(0, 0, 0, 1, Color(0xF2FFFFFF)),
            CssShadow(0, 2 * s, 0, 0, const Color(0xFFE5DDCD)),
            CssShadow(0, 4 * s, 0, 0, const Color(0xFFCFC5B2)),
            CssShadow(0, 16 * s, 26 * s, -12 * s, const Color(0xB3061A24)),
          ],
          padding: EdgeInsets.fromLTRB(12 * s, 10 * s, 12 * s, 9 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      OnbTipsCopy.merkelapp.toUpperCase(),
                      style: inter(9.5 * s, weight: FontWeight.w800, em: .08, color: _gronn),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: OnbTipsCopy.lukk,
                    // 22 px hit box in a 16 × 14 slot (`margin: -4px -6px -4px 0`).
                    child: SizedBox(
                      width: 16 * s,
                      height: 14 * s,
                      child: OverflowBox(
                        maxWidth: 22 * s,
                        maxHeight: 22 * s,
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          key: const Key('onb-tips-lukk'),
                          behavior: HitTestBehavior.opaque,
                          onTap: () => t.lukk(grunn: 'kryss'),
                          child: SizedBox(
                            width: 22 * s,
                            height: 22 * s,
                            child: Center(child: CustomPaint(size: Size.square(9 * s), painter: _KryssMaler(_x, 1.4 * s))),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 3 * s),
              Text(
                v.tip.tekst,
                style: onbDisplay(12.5 * s, letterSpacingEm: -.01, height: 1.36, color: _mork),
              ),
              if (v.tip.handling) ...[
                SizedBox(height: 8 * s),
                Row(
                  children: [
                    Flexible(
                      child: _Trykk(
                        onTap: t.handling,
                        child: Container(
                          key: const Key('onb-tips-handling'),
                          height: 30 * s,
                          padding: EdgeInsets.symmetric(horizontal: 11 * s),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: _teal.withValues(alpha: .1), borderRadius: BorderRadius.circular(999)),
                          child: Text(
                            v.tip.handlingTekst,
                            style: inter(11.5 * s, weight: FontWeight.w800, color: _teal),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _KryssMaler extends CustomPainter {
  const _KryssMaler(this.color, this.w);
  final Color color;
  final double w;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), p);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), p);
  }

  @override
  bool shouldRepaint(_KryssMaler old) => old.color != color || old.w != w;
}

/// `style-active: translateY(1px)`.
class _Trykk extends StatefulWidget {
  const _Trykk({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_Trykk> createState() => _TrykkState();
}

class _TrykkState extends State<_Trykk> {
  bool _ned = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapDown: (_) => setState(() => _ned = true),
    onTapCancel: () => setState(() => _ned = false),
    onTapUp: (_) => setState(() => _ned = false),
    onTap: widget.onTap,
    child: Transform.translate(offset: Offset(0, _ned ? 1 : 0), child: widget.child),
  );
}

/// The small Ægil (56 px, pivot at his feet) with the pose's animation:
/// `cmPeekOpp` / `cmPeekNed` .5s, `vkVink .9s .3s`, `vkNikk .5s .3s`,
/// `vkHopp .6s .3s`, else `aegStaa 3.6s` forever.
class _TipsAegil extends StatelessWidget {
  const _TipsAegil({required this.pose, required this.bilde, required this.s, required this.rolig});
  final OnbTipPose pose;
  final String bilde;
  final double s;
  final bool rolig;

  static const Curve _peek = Cubic(.2, 1, .4, 1);

  @override
  Widget build(BuildContext context) {
    final img = Image.asset('assets/images/aegil/$bilde.png', fit: BoxFit.contain, gaplessPlayback: true);
    if (rolig) return img;
    return LfLoop(
      essential: true, // Step 8: the small Ægil keeps its pose animation in `lite`
      child: img,
      builder: (context, ms, child) {
        var ty = 0.0, rot = 0.0, sx = 1.0, sy = 1.0;
        var idle = false;
        switch (pose) {
          case OnbTipPose.peekBottom:
            ty = 56 * s * .7 * (1 - _peek.transform(onbP(ms, 0, 500)));
          case OnbTipPose.peekTop:
            ty = -56 * s * .7 * (1 - _peek.transform(onbP(ms, 0, 500)));
          case OnbTipPose.wave:
            final p = onbP(ms, 300, 900);
            rot = kf(p, const [0, .2, .45, .7, 1], const [0, -7, 6, -4, 0], cssEaseInOut);
          case OnbTipPose.nod:
            final p = onbP(ms, 300, 500);
            rot = kf(p, const [0, .3, .6, 1], const [0, 5, -2, 0], cssEaseInOut);
            ty = kf(p, const [0, .3, .6, 1], const [0, 2, 0, 0], cssEaseInOut) * s;
          case OnbTipPose.celebrate:
            final p = onbP(ms, 300, 600);
            sx = kf(p, const [0, .2, .5, .8, 1], const [1, 1.08, .95, 1.04, 1]);
            sy = kf(p, const [0, .2, .5, .8, 1], const [1, .9, 1.06, .96, 1]);
            ty = kf(p, const [0, .2, .5, .8, 1], const [0, 0, -22, 0, 0]) * s;
          case OnbTipPose.idle || OnbTipPose.point || OnbTipPose.present || OnbTipPose.think:
            idle = true;
        }
        var mtx = Matrix4.identity()
          ..translateByDouble(0, ty, 0, 1)
          ..rotateZ(rad(rot))
          ..scaleByDouble(sx, sy, 1, 1);
        if (idle) mtx = aegStaa(ms, 3600);
        return Transform(alignment: Alignment.bottomCenter, transform: mtx, child: child);
      },
    );
  }
}

/// The «?» dot (18 px, `#1E4F5C`, ring `#F5F3EF`): reopens the mark.
class _Prikk extends StatelessWidget {
  const _Prikk({required this.s, required this.onTap});
  final double s;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: OnbTipsCopy.prikk,
    child: GestureDetector(
      key: const Key('onb-tips-prikk'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 18 * s,
        height: 18 * s,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF1E4F5C),
          boxShadow: [
            BoxShadow(color: const Color(0xFFF5F3EF), spreadRadius: 2 * s),
            BoxShadow(color: Colors.black.withValues(alpha: .5), blurRadius: 8 * s, spreadRadius: -4 * s, offset: Offset(0, 4 * s)),
          ],
        ),
        child: Text('?', style: inter(10.5 * s, weight: FontWeight.w800, color: Colors.white, height: 1)),
      ),
    ),
  );
}
