import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../auth/onboarding_kit.dart';
import 'bergen_copy.dart';
import 'bergen_floats.dart';
import 'bergen_kit.dart';
import 'bergen_painters.dart';

// ── The hero (`data-hero="1"`, ROM style) ───────────────────────────────────
// A 390×250 window under the header: weather sky, the Fløyen scene with the
// cable car, the Bryggen houses on the quay, the water with Ægil's product
// floats, Ægil on the pier with the Fjordfiske button, the surprise bag, the
// greeting — and Ægil's one-off intro walk on first open.

const double kBergenHeroHeight = 250;

class BergenHero extends StatefulWidget {
  const BergenHero({
    super.key,
    required this.look,
    required this.greeting,
    required this.floats,
    required this.onFloatAdd,
    required this.onFloatSunk,
    required this.onFloatNever,
    required this.onFjordfiske,
    required this.onBag,
    this.showLantern = false,
    this.boat,
    this.onBoat,
    this.playIntro = true,
  });

  final BergenWeatherLook look;
  final String greeting;
  final List<BergenFloatItem> floats;
  final ValueChanged<BergenFloatItem> onFloatAdd;
  final ValueChanged<BergenFloatItem> onFloatSunk;
  final ValueChanged<BergenFloatItem> onFloatNever;
  final VoidCallback onFjordfiske;
  final VoidCallback onBag;

  /// `vsNyLykt` — a lantern on the quay for something new in town.
  final bool showLantern;

  /// `visBaat` — an order on its way: 0…1 progress across the water.
  final double? boat;
  final VoidCallback? onBoat;

  /// `aegIntro` — Ægil walks in, talks, and goes back to the pier once.
  final bool playIntro;

  @override
  State<BergenHero> createState() => _BergenHeroState();
}

class _BergenHeroState extends State<BergenHero> {
  late bool _intro = widget.playIntro;
  BergenFloatItem? _selected;
  bool _cardUp = false;
  bool _catchToast = false;

  @override
  void initState() {
    super.initState();
    if (_intro) {
      Future<void>.delayed(const Duration(milliseconds: 4450), () {
        if (mounted) setState(() => _intro = false);
      });
    }
  }

  void _selectFloat(BergenFloatItem f) {
    setState(() {
      _selected = f;
      _cardUp = false;
    });
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (mounted && _selected == f) setState(() => _cardUp = true);
    });
  }

  void _closeCard() => setState(() {
    _selected = null;
    _cardUp = false;
  });

  void _catchShown() {
    setState(() => _catchToast = true);
    Future<void>.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _catchToast = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final look = widget.look;
    final s = context.bs;
    final w = MediaQuery.sizeOf(context).width;
    return SizedBox(
      height: kBergenHeroHeight * s,
      child: ClipRect(
        child: Stack(
          clipBehavior: Clip.none,
          fit: StackFit.expand,
          children: [
            DecoratedBox(decoration: BoxDecoration(gradient: look.sky)),
            _scene(context, look),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 150 * s,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: look.mist),
                ),
              ),
            ),
            if (look.isSun) ..._sun(context),
            _cableCar(context),
            if (look.isRain) ..._rain(context),
            // The water from the quay's edge down.
            Positioned(
              left: 0,
              right: 0,
              top: 127 * s,
              bottom: 0,
              child: IgnorePointer(child: _sea(context, look)),
            ),
            Positioned(
              left: 0,
              top: 60 * s,
              width: w,
              height: 76 * s,
              child: IgnorePointer(
                child: CustomPaint(
                  painter: BergenHousesPainter(dim: look.houseDim),
                ),
              ),
            ),
            // The cream fade at the very top.
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 40 * s,
              child: const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [BergenColors.cream, Color(0x00F5F3EF)],
                    ),
                  ),
                ),
              ),
            ),
            _greeting(context, look),
            if (widget.showLantern) _lantern(context),
            ..._pier(context, look),
            if (widget.boat != null) _boat(context),
            _bag(context),
            ...widget.floats.asMap().entries.map(
              (e) => BergenFloat(
                key: ValueKey('float-${e.value.id}'),
                item: e.value,
                index: e.key,
                selected: _selected?.id == e.value.id,
                dimmed: _selected != null && _selected?.id != e.value.id,
                showCatchBadge: e.key == 0 && !_catchToast,
                onTap: () => _selectFloat(e.value),
              ),
            ),
            if (_selected != null) _rodLine(context),
            if (_intro) ..._aegilIntro(context),
            if (_catchToast) _catchPill(context),
            if (_selected != null && _cardUp)
              BergenNappCard(
                item: _selected!,
                onClose: _closeCard,
                onAdd: () {
                  final f = _selected!;
                  _closeCard();
                  _catchShown();
                  widget.onFloatAdd(f);
                },
                onNotNow: () {
                  final f = _selected!;
                  _closeCard();
                  widget.onFloatSunk(f);
                },
                onNever: () {
                  final f = _selected!;
                  _closeCard();
                  widget.onFloatNever(f);
                },
              ),
          ],
        ),
      ),
    );
  }

  // ── Scene ─────────────────────────────────────────────────────────────────

  /// `k-scene2` squashed to 390×190 at y 4, with its lit windows revealed
  /// left → right on first paint (`lysTenn .9s .15s`).
  Widget _scene(BuildContext context, BergenWeatherLook look) {
    final s = context.bs;
    final w = MediaQuery.sizeOf(context).width;
    return Positioned(
      left: 0,
      top: 4 * s,
      width: w,
      height: 190 * s,
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            bergenSvg('scene_mountains', fit: BoxFit.fill),
            if (look.houseDim > .2)
              ColoredBox(
                color: Colors.black.withValues(alpha: look.houseDim * .8),
              ),
            if (look.glow > 0)
              OnbTimeline(
                durationMs: 1050,
                builder: (context, t, _) {
                  final p = Curves.easeOut.transform(onbP(t, 150, 900));
                  return Opacity(
                    opacity: look.glow * (p < .1 ? p * 10 : 1),
                    child: ClipRect(
                      clipper: _RevealClipper(p),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Opacity(
                            opacity: .55,
                            child: onbBlurred(
                              4,
                              bergenSvg('scene_lights', fit: BoxFit.fill),
                            ),
                          ),
                          bergenSvg('scene_lights', fit: BoxFit.fill),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _sun(BuildContext context) {
    final s = context.bs;
    return [
      Positioned(
        left: 250 * s,
        top: -90 * s,
        width: 260 * s,
        height: 260 * s,
        child: IgnorePointer(
          child: bergenRadial(
            colors: const [
              Color.fromRGBO(255, 244, 214, .95),
              Color.fromRGBO(255, 226, 160, .65),
              Color.fromRGBO(255, 210, 140, .28),
              Color.fromRGBO(255, 200, 130, 0),
            ],
            stops: const [0, .14, .3, .6],
          ),
        ),
      ),
      Positioned(
        left: 316 * s,
        top: -28 * s,
        width: 28 * s,
        height: 28 * s,
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(-.1, -.2),
                colors: [
                  Color(0xFFFFFDF4),
                  Color(0xFFFFE9A8),
                  Color(0xFFFFD27A),
                ],
                stops: [0, .6, 1],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromRGBO(255, 236, 170, .9),
                  blurRadius: 18 * s,
                  spreadRadius: 6 * s,
                ),
                BoxShadow(
                  color: const Color.fromRGBO(255, 220, 140, .5),
                  blurRadius: 60 * s,
                  spreadRadius: 20 * s,
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  /// `floyBil 20s linear infinite` — the Fløibanen cabin climbing the hill.
  Widget _cableCar(BuildContext context) {
    final s = context.bs;
    return Positioned(
      left: 296 * s,
      top: 68 * s,
      child: IgnorePointer(
        child: OnbLoopClock(
          builder: (context, t, _) {
            final p = (onbLoop(t, 0, 20000) ?? 0);
            return Transform.translate(
              offset: Offset(44 * p * s, -78 * p * s),
              child: SizedBox(
                width: 18 * s,
                height: 12 * s,
                child: CustomPaint(painter: _CableCarPainter()),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _rain(BuildContext context) {
    final s = context.bs;
    Widget drop(double l, double t, double w, double h, {bool warm = false}) =>
        Positioned(
          left: l * s,
          top: t * s,
          width: w * s,
          height: h * s,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(w),
                gradient: const RadialGradient(
                  center: Alignment(-.3, -.4),
                  colors: [
                    Color.fromRGBO(255, 255, 255, .9),
                    Color.fromRGBO(255, 255, 255, .25),
                    Color.fromRGBO(255, 255, 255, .05),
                  ],
                  stops: [0, .6, 1],
                ),
                boxShadow: warm
                    ? [
                        BoxShadow(
                          color: const Color.fromRGBO(255, 220, 150, .35),
                          blurRadius: 3 * s,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        );
    return [
      // `drypp 9s` — one drop sliding down the glass.
      Positioned(
        left: 246 * s,
        top: 36 * s,
        child: IgnorePointer(
          child: OnbLoopClock(
            builder: (context, t, _) {
              final p = onbLoop(t, 600, 9000);
              if (p == null) return const SizedBox.shrink();
              const stops = [0.0, .08, .7, 1.0];
              final dy = onbKf(p, stops, const [0, 0, 150, 240], Curves.linear);
              final sy = onbKf(p, stops, const [1, 1, 1.6, 1.2], Curves.linear);
              final o = onbKf(p, stops, const [0, .9, .8, 0], Curves.linear);
              return Opacity(
                opacity: o.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, dy * s),
                  child: Transform.scale(
                    scaleY: sy,
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: 3 * s,
                      height: 14 * s,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x00FFFFFF), Color(0xCCFFFFFF)],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      drop(62, 64, 5, 6, warm: true),
      drop(118, 102, 4, 5),
      drop(204, 78, 6, 7, warm: true),
      drop(296, 126, 4, 5),
      drop(342, 60, 5, 6, warm: true),
      drop(160, 150, 4, 4),
    ];
  }

  Widget _sea(BuildContext context, BergenWeatherLook look) {
    final s = context.bs;
    return OnbLoopClock(
      shared: true,
      builder: (context, t, _) => Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: BergenSeaPainter(
              t: t,
              rain: false,
              base: look.isNight
                  ? const Color(0xFF2B4F5C)
                  : const Color(0xFF3D6B7A),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 60 * s,
            child: const CustomPaint(painter: BergenHouseReflectionPainter()),
          ),
        ],
      ),
    );
  }

  // ── Greeting, lantern ─────────────────────────────────────────────────────

  /// `bobleFraAegil .55s .3s` — slides in from the left with a little pop.
  Widget _greeting(BuildContext context, BergenWeatherLook look) {
    final s = context.bs;
    return Positioned(
      left: 32 * s,
      right: 92 * s,
      top: 24 * s,
      child: IgnorePointer(
        child: OnbTimeline(
          durationMs: 850,
          builder: (context, t, _) {
            final p = onbP(t, 300, 550);
            const c = Cubic(.3, 1.3, .5, 1);
            final dx = onbKf(p, const [0, .6, 1], const [-14, 2, 0], c);
            final sc = onbKf(p, const [0, .6, 1], const [.7, 1.03, 1], c);
            final o = onbKf(p, const [0, .6, 1], const [0, 1, 1], c);
            return Opacity(
              opacity: o.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(dx * s, 0),
                child: Transform.scale(
                  alignment: Alignment.bottomLeft,
                  scale: sc,
                  child: Text(
                    widget.greeting,
                    style: bDisplay(
                      context,
                      26,
                      letterSpacingEm: -.03,
                      height: 1.02,
                      color: look.text,
                      shadows: look.textShadow,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _lantern(BuildContext context) {
    final s = context.bs;
    return Positioned(
      left: 84 * s,
      top: 160 * s,
      child: IgnorePointer(
        child: SizedBox(
          width: 13 * s,
          height: 18 * s,
          child: OnbLoopClock(
            builder: (context, t, _) {
              final p = (onbLoop(t, 0, 3400) ?? 0);
              final g = onbKf(
                p,
                const [0, .5, 1],
                const [.55, 1, .55],
                Curves.easeInOut,
              );
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: -7 * s,
                    top: -6 * s,
                    width: 27 * s,
                    height: 29 * s,
                    child: Opacity(
                      opacity: g,
                      child: bergenRadial(
                        colors: const [
                          Color.fromRGBO(255, 205, 120, .75),
                          Color.fromRGBO(255, 205, 120, 0),
                        ],
                        stops: const [0, .68],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 3 * s,
                    top: 0,
                    width: 7 * s,
                    height: 3 * s,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A3128),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 1 * s,
                    top: 3 * s,
                    width: 11 * s,
                    height: 11 * s,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFFFE2A8), Color(0xFFF2B457)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromRGBO(255, 198, 110, .9),
                            blurRadius: 6 * s,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 4 * s,
                    top: 14 * s,
                    width: 5 * s,
                    height: 4 * s,
                    child: const ColoredBox(color: Color(0xFF3A3128)),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Ægil on the pier, the pier, Fjordfiske ────────────────────────────────

  List<Widget> _pier(BuildContext context, BergenWeatherLook look) {
    final s = context.bs;
    final rear = !_intro;
    Widget fade(Widget child) => AnimatedOpacity(
      opacity: rear ? 1 : 0,
      duration: const Duration(milliseconds: 450),
      child: child,
    );
    return [
      // Planks, the dark lip under them, the shade on the water.
      Positioned(
        right: 0,
        top: 196 * s,
        width: 124 * s,
        height: 14 * s,
        child: IgnorePointer(child: CustomPaint(painter: _PlankPainter())),
      ),
      Positioned(
        right: 0,
        top: 210 * s,
        width: 124 * s,
        height: 6 * s,
        child: const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(4)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1C1A17), Color(0x991C1A17)],
              ),
            ),
          ),
        ),
      ),
      Positioned(
        right: 0,
        top: 216 * s,
        width: 124 * s,
        height: 10 * s,
        child: const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromRGBO(8, 24, 32, .45),
                  Color.fromRGBO(8, 24, 32, 0),
                ],
              ),
            ),
          ),
        ),
      ),
      for (final r in [112.0, 14.0])
        Positioned(
          right: r * s,
          top: 190 * s,
          width: 5 * s,
          height: 18 * s,
          child: const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
                gradient: LinearGradient(
                  colors: [Color(0xFF4A3C2A), Color(0xFF2C2114)],
                ),
              ),
            ),
          ),
        ),
      // Ægil's shadow, rod and Ægil himself (rear view, fishing).
      Positioned(
        right: 22 * s,
        top: 198 * s,
        width: 58 * s,
        height: 9 * s,
        child: IgnorePointer(
          child: fade(
            onbBlurred(
              3,
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(20, 40, 50, .35),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
        ),
      ),
      Positioned(
        right: 18 * s,
        top: 152 * s,
        width: 86 * s,
        height: 60 * s,
        child: IgnorePointer(child: fade(CustomPaint(painter: _RodPainter()))),
      ),
      Positioned(
        right: 24 * s,
        top: 146 * s,
        width: 58 * s,
        child: fade(
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: rear ? widget.onFjordfiske : null,
            child: Image.asset(BergenAssets.aegilRear, width: 58 * s),
          ),
        ),
      ),
      if (look.isRain)
        Positioned(
          right: 38 * s,
          top: 170 * s,
          width: 24 * s,
          height: 12 * s,
          child: IgnorePointer(
            child: fade(CustomPaint(painter: _HatPainter())),
          ),
        ),
      // The Fjordfiske pill bobbing on the water, with its ripple.
      Positioned(
        right: 136 * s,
        top: 229 * s,
        width: 64 * s,
        height: 12 * s,
        child: IgnorePointer(
          child: fade(
            OnbLoopClock(
              builder: (context, t, _) {
                final p = (onbLoop(t, 0, 3200) ?? 0);
                return Opacity(
                  opacity: .8 * (1 - p),
                  child: Transform.scale(
                    scale: .4 + 1.2 * Curves.easeOut.transform(p),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .45),
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      Positioned(
        right: 130 * s,
        top: 200 * s,
        child: fade(
          OnbLoopClock(
            builder: (context, t, child) {
              final p = (onbLoop(t, 0, 3400) ?? 0);
              final dy = onbKf(
                p,
                const [0, .5, 1],
                const [0, -3, 0],
                Curves.easeInOut,
              );
              final r = onbKf(
                p,
                const [0, .5, 1],
                const [-3, 3, -3],
                Curves.easeInOut,
              );
              return Transform.translate(
                offset: Offset(0, dy * s),
                child: Transform.rotate(angle: r * math.pi / 180, child: child),
              );
            },
            child: _FjordfiskeButton(onTap: rear ? widget.onFjordfiske : null),
          ),
        ),
      ),
    ];
  }

  /// The line from Ægil's rod to a selected float (`visSnor`).
  Widget _rodLine(BuildContext context) {
    final s = context.bs;
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _LinePainter(
            from: Offset(336 * s, 186 * s),
            to: Offset(300 * s, 150 * s),
          ),
        ),
      ),
    );
  }

  /// `visBaat` — the longship carrying an order across the water.
  Widget _boat(BuildContext context) {
    final s = context.bs;
    final x = 40 + (widget.boat!.clamp(0.0, 1.0)) * 240;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 1200),
      left: x * s,
      top: 132 * s,
      width: 60 * s,
      height: 44 * s,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onBoat,
        child: OnbLoopClock(
          builder: (context, t, _) {
            final p = (onbLoop(t, 0, 3400) ?? 0);
            final dy = onbKf(
              p,
              const [0, .5, 1],
              const [0, -2.5, 0],
              Curves.easeInOut,
            );
            return Align(
              alignment: Alignment.bottomCenter,
              child: Transform.translate(
                offset: Offset(0, dy * s),
                child: bergenSvg('longship', width: 44 * s, height: 26 * s),
              ),
            );
          },
        ),
      ),
    );
  }

  /// `visPose` — the surprise bag left on the quay.
  Widget _bag(BuildContext context) {
    final s = context.bs;
    return Positioned(
      left: 34 * s,
      top: 158 * s,
      width: 44 * s,
      height: 44 * s,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onBag,
        child: OnbLoopClock(
          builder: (context, t, _) {
            final p = (onbLoop(t, 0, 3200) ?? 0);
            final g = onbKf(
              p,
              const [0, .5, 1],
              const [.55, 1, .55],
              Curves.easeInOut,
            );
            return Stack(
              children: [
                Positioned(
                  left: 10 * s,
                  bottom: 6 * s,
                  width: 24 * s,
                  height: 10 * s,
                  child: onbBlurred(
                    2,
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(8, 24, 32, .45),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12 * s,
                  top: 2 * s,
                  width: 20 * s,
                  height: 12 * s,
                  child: Opacity(
                    opacity: g,
                    child: bergenRadial(
                      colors: const [
                        Color.fromRGBO(255, 214, 140, .75),
                        Color.fromRGBO(255, 214, 140, 0),
                      ],
                      stops: const [0, .7],
                    ),
                  ),
                ),
                Positioned(
                  left: 9 * s,
                  top: 8 * s,
                  width: 26 * s,
                  height: 30 * s,
                  child: CustomPaint(painter: _BagPainter()),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// `visNappKvitt` — "Dagens napp: +5".
  Widget _catchPill(BuildContext context) {
    final s = context.bs;
    return Positioned(
      left: 0,
      right: 0,
      top: 196 * s,
      child: IgnorePointer(
        child: Center(
          child: OnbTimeline(
            durationMs: 400,
            builder: (context, t, child) {
              final p = const Cubic(.3, 1.2, .5, 1).transform(onbP(t, 0, 400));
              return Opacity(
                opacity: p.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, 26 * (1 - p) * s),
                  child: child,
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 14 * s,
                vertical: 7 * s,
              ),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(15, 31, 43, .62),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0x3DFFFFFF)),
              ),
              child: Text(
                BergenCopy.todaysCatch,
                style: bText(
                  context,
                  11.5,
                  weight: FontWeight.w800,
                  color: BergenColors.cream,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Ægil's intro (`aegKomInn` / `bobleTilBruker`, 4.6s) ───────────────────

  List<Widget> _aegilIntro(BuildContext context) {
    final s = context.bs;
    final w = MediaQuery.sizeOf(context).width;
    const c = Cubic(.3, .9, .4, 1);
    return [
      Positioned(
        left: w / 2 - 30 * s,
        top: 196 * s,
        width: 60 * s,
        height: 11 * s,
        child: IgnorePointer(
          child: OnbTimeline(
            durationMs: 4600,
            builder: (context, t, _) {
              final p = onbP(t, 0, 4600);
              const st = [0.0, .14, .3, .38, .72, .96, 1.0];
              final dx = onbKf(p, st, const [150, 108, 24, 0, 0, 112, 112], c);
              final dy = onbKf(p, st, const [26, 19, 6, 0, 0, 24, 24], c);
              final sc = onbKf(p, st, const [.62, .72, .92, 1, 1, .78, .78], c);
              final o = onbKf(p, st, const [0, .9, .9, .9, .9, .9, .9], c);
              return Opacity(
                opacity: o.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(dx * s, dy * s),
                  child: Transform.scale(
                    scale: sc,
                    child: onbBlurred(
                      4,
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(20, 40, 50, .4),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      Positioned(
        left: w / 2 - 38 * s,
        top: 140 * s,
        width: 76 * s,
        child: IgnorePointer(
          child: OnbTimeline(
            durationMs: 4600,
            child: Image.asset(BergenAssets.aegilFront, width: 76 * s),
            builder: (context, t, child) {
              final p = onbP(t, 0, 4600);
              const st = [0.0, .14, .3, .38, .62, .68, .72, .96, 1.0];
              final dx = onbKf(p, st, const [
                150,
                108,
                24,
                0,
                0,
                0,
                6,
                112,
                112,
              ], c);
              final dy = onbKf(p, st, const [26, 19, 6, 0, 0, 0, 2, 24, 24], c);
              final sc = onbKf(p, st, const [
                .62,
                .72,
                .92,
                1,
                1,
                1,
                .99,
                .78,
                .78,
              ], c);
              final ry = onbKf(p, st, const [
                0,
                0,
                0,
                0,
                0,
                90,
                180,
                180,
                180,
              ], c);
              final o = onbKf(p, const [0, .14, 1], const [0, 1, 1], c);
              return Opacity(
                opacity: o.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(dx * s, dy * s),
                  child: Transform(
                    alignment: Alignment.bottomCenter,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, -1 / 700)
                      ..scaleByDouble(sc, sc, 1, 1)
                      ..rotateY(ry * math.pi / 180),
                    child: child,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      Positioned(
        left: 16 * s,
        right: 64 * s,
        top: 74 * s,
        child: IgnorePointer(
          child: Align(
            alignment: Alignment.centerLeft,
            child: OnbTimeline(
              durationMs: 4600,
              child: Container(
                constraints: BoxConstraints(maxWidth: 238 * s),
                padding: EdgeInsets.symmetric(
                  horizontal: 13 * s,
                  vertical: 10 * s,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .95),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16 * s),
                    topRight: Radius.circular(16 * s),
                    bottomRight: Radius.circular(5 * s),
                    bottomLeft: Radius.circular(16 * s),
                  ),
                  boxShadow: [
                    const BoxShadow(color: Color(0xE6FFFFFF), spreadRadius: 1),
                    BoxShadow(
                      color: const Color.fromRGBO(15, 31, 43, .5),
                      offset: Offset(0, 14 * s),
                      blurRadius: onbBlur(24 * s),
                      spreadRadius: -12 * s,
                    ),
                  ],
                ),
                child: Text(
                  BergenCopy.aegilIntro,
                  style: bText(
                    context,
                    11.5,
                    height: 1.4,
                    color: BergenColors.ink,
                  ),
                ),
              ),
              builder: (context, t, child) {
                final p = onbP(t, 0, 4600);
                const st = [0.0, .16, .2, .58, .66, 1.0];
                final sc = onbKf(p, st, const [
                  .7,
                  1.03,
                  1,
                  1,
                  .94,
                  .94,
                ], Curves.easeInOut);
                final dy = onbKf(p, st, const [
                  8,
                  0,
                  0,
                  0,
                  4,
                  4,
                ], Curves.easeInOut);
                final o = onbKf(p, st, const [
                  0,
                  1,
                  1,
                  1,
                  0,
                  0,
                ], Curves.easeInOut);
                return Opacity(
                  opacity: o.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, dy * s),
                    child: Transform.scale(
                      alignment: Alignment.bottomRight,
                      scale: sc,
                      child: child,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ];
  }
}

// ── Small painters and pieces ───────────────────────────────────────────────

class _RevealClipper extends CustomClipper<Rect> {
  _RevealClipper(this.p);
  final double p;
  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * p, size.height);
  @override
  bool shouldReclip(_RevealClipper old) => old.p != p;
}

class _CableCarPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size size) {
    final sx = size.width / 24;
    final sy = size.height / 16;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(1 * sx, 3 * sy, 22 * sx, 12 * sy),
      Radius.circular(4 * sx),
    );
    c.drawRRect(body, Paint()..color = const Color(0xFFEAE4D6));
    c.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1 * sx
        ..color = const Color(0xFF3A3128),
    );
    final win = Paint()..color = const Color(0xFF3E4A4E);
    c.drawRect(Rect.fromLTWH(4 * sx, 6 * sy, 5 * sx, 4 * sy), win);
    c.drawRect(Rect.fromLTWH(14 * sx, 6 * sy, 5 * sx, 4 * sy), win);
  }

  @override
  bool shouldRepaint(_CableCarPainter old) => false;
}

/// `repeating-linear-gradient(90deg, transparent 0 18px, rgba(0,0,0,.22) 18px
/// 19px)` over the wood gradient.
class _PlankPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size size) {
    final r = Offset.zero & size;
    final rr = RRect.fromRectAndCorners(
      r,
      topLeft: const Radius.circular(7),
      bottomLeft: const Radius.circular(3),
    );
    c.drawRRect(
      rr,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6A5A44), Color(0xFF4A3C2A), Color(0xFF2C2114)],
          stops: [0, .4, 1],
        ).createShader(r),
    );
    c.save();
    c.clipRRect(rr);
    final line = Paint()..color = Colors.black.withValues(alpha: .22);
    final step = size.width / 124 * 19;
    for (var x = size.width / 124 * 18; x < size.width; x += step) {
      c.drawRect(Rect.fromLTWH(x, 0, size.width / 124, size.height), line);
    }
    c.drawRect(
      Rect.fromLTWH(0, 0, size.width, 1),
      Paint()..color = Colors.white.withValues(alpha: .28),
    );
    c.restore();
  }

  @override
  bool shouldRepaint(_PlankPainter old) => false;
}

class _RodPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size size) {
    final sx = size.width / 86;
    final sy = size.height / 60;
    c.drawLine(
      Offset(12 * sx, 12 * sy),
      Offset(58 * sx, 40 * sy),
      Paint()
        ..color = const Color(0xFF5A4630)
        ..strokeWidth = 1.8 * sx
        ..strokeCap = StrokeCap.round,
    );
    final line = Path()
      ..moveTo(58 * sx, 40 * sy)
      ..quadraticBezierTo(62 * sx, 48 * sy, 60 * sx, 56 * sy);
    c.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .9 * sx
        ..color = Colors.white.withValues(alpha: .75),
    );
    c.drawCircle(
      Offset(60 * sx, 56 * sy),
      1.8 * sx,
      Paint()..color = BergenColors.orange,
    );
  }

  @override
  bool shouldRepaint(_RodPainter old) => false;
}

/// Ægil's rain hat (`erRegn`).
class _HatPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size size) {
    final sx = size.width / 44;
    final sy = size.height / 22;
    final brim = Path()
      ..moveTo(2 * sx, 20 * sy)
      ..cubicTo(6 * sx, 6 * sy, 38 * sx, 6 * sy, 42 * sx, 20 * sy)
      ..cubicTo(34 * sx, 15 * sy, 10 * sx, 15 * sy, 2 * sx, 20 * sy)
      ..close();
    c.drawPath(brim, Paint()..color = BergenColors.gold);
    final crown = Path()
      ..moveTo(12 * sx, 8 * sy)
      ..cubicTo(16 * sx, 2 * sy, 28 * sx, 2 * sy, 32 * sx, 8 * sy);
    c.drawPath(
      crown,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * sx
        ..color = const Color(0xFFD9A254),
    );
  }

  @override
  bool shouldRepaint(_HatPainter old) => false;
}

/// The paper bag on the quay, with its "Æ".
class _BagPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size size) {
    final sx = size.width / 26;
    final sy = size.height / 30;
    final body = Path()
      ..moveTo(3 * sx, 9 * sy)
      ..lineTo(23 * sx, 9 * sy)
      ..lineTo(21.5 * sx, 28 * sy)
      ..lineTo(4.5 * sx, 28 * sy)
      ..close();
    c.drawShadow(body, const Color(0xFF081820), 2, false);
    c.drawPath(body, Paint()..color = const Color(0xFFD9A254));
    final band = Path()
      ..moveTo(3 * sx, 9 * sy)
      ..lineTo(23 * sx, 9 * sy)
      ..lineTo(22.4 * sx, 14 * sy)
      ..lineTo(3.6 * sx, 14 * sy)
      ..close();
    c.drawPath(band, Paint()..color = const Color(0xFFC8913E));
    final handle = Path()
      ..moveTo(6 * sx, 9 * sy)
      ..lineTo(8 * sx, 4 * sy)
      ..lineTo(18 * sx, 4 * sy)
      ..lineTo(20 * sx, 9 * sy);
    c.drawPath(
      handle,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 * sx
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF7A5A28),
    );
    final squiggle = Path()
      ..moveTo(8 * sx, 8 * sy)
      ..lineTo(12 * sx, 6.5 * sy)
      ..lineTo(15 * sx, 8.5 * sy)
      ..lineTo(18 * sx, 7 * sy);
    c.drawPath(
      squiggle,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 * sx
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFFFE2A8),
    );
    final tp = TextPainter(
      text: TextSpan(
        text: 'Æ',
        style: onbDisplay(8 * sx, color: const Color(0xFF5A3C10)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(13 * sx - tp.width / 2, 23 * sy - tp.height * .85));
  }

  @override
  bool shouldRepaint(_BagPainter old) => false;
}

class _LinePainter extends CustomPainter {
  _LinePainter({required this.from, required this.to});
  final Offset from;
  final Offset to;
  @override
  void paint(Canvas c, Size size) => c.drawLine(
    from,
    to,
    Paint()
      ..color = Colors.white.withValues(alpha: .85)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round,
  );
  @override
  bool shouldRepaint(_LinePainter old) => old.from != from || old.to != to;
}

/// `Fjordfiske-knapp` — frosted pill with a bobber, label and chevron.
class _FjordfiskeButton extends StatelessWidget {
  const _FjordfiskeButton({required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return OnbPressable(
      onTap: onTap,
      pressScale: .94,
      child: Container(
        height: 30 * s,
        padding: EdgeInsets.only(left: 7 * s, right: 11 * s),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(15, 31, 43, .55),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0x4DFFFFFF)),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(4, 18, 26, .8),
              offset: Offset(0, 8 * s),
              blurRadius: onbBlur(14 * s),
              spreadRadius: -8 * s,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14 * s,
              height: 18 * s,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 6 * s,
                    top: -4 * s,
                    width: 1.6 * s,
                    height: 7 * s,
                    child: const ColoredBox(color: Colors.white),
                  ),
                  Positioned(
                    left: 0,
                    top: 2 * s,
                    width: 14 * s,
                    height: 16 * s,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(
                          Radius.elliptical(7 * s, 8 * s),
                        ),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFF9A273),
                            Color(0xFFF26D3D),
                            Color(0xFFFFFFFF),
                            Color(0xFFEAF2F4),
                          ],
                          stops: [0, .48, .5, 1],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 6 * s),
            Text(
              BergenCopy.fjordfiske,
              style: bText(
                context,
                11,
                weight: FontWeight.w800,
                letterSpacingEm: -.01,
              ),
            ),
            SizedBox(width: 6 * s),
            OnbIcons.of(OnbIcons.chevronRight('#7FF0CB'), 10 * s),
          ],
        ),
      ),
    );
  }
}
