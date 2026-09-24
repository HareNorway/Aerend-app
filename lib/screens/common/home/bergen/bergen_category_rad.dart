import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../auth/onboarding_kit.dart';
import 'bergen_copy.dart';
import 'bergen_kit.dart';
import 'bergen_painters.dart';

// ── Kategorirad (`stilRom`) ─────────────────────────────────────────────────
// Five 3D category icons on a ring: the focused one sits large in the middle
// on a splash of water rings, the others small on either side. Drag sideways
// or tap a neighbour to rotate; tap the focused one to open it.

class BergenCategory {
  const BergenCategory({
    required this.id,
    required this.name,
    required this.liveText,
    this.iconAsset,
    this.iconUrl,
    this.isNew = false,
    this.look,
  });

  final int id;
  final String name;

  /// `LIVE[ki]` — "24 åpne nå" / "Åpner 10:00".
  final String liveText;
  final String? iconAsset;
  final String? iconUrl;
  final bool isNew;
  final BergenCategoryLook? look;
}

class BergenCategoryRad extends StatefulWidget {
  const BergenCategoryRad({
    super.key,
    required this.categories,
    required this.index,
    required this.onIndexChanged,
    required this.onOpen,
  });

  final List<BergenCategory> categories;
  final int index;
  final ValueChanged<int> onIndexChanged;
  final ValueChanged<BergenCategory> onOpen;

  @override
  State<BergenCategoryRad> createState() => _BergenCategoryRadState();
}

class _BergenCategoryRadState extends State<BergenCategoryRad> {
  double _dx = 0;
  bool _dragging = false;

  /// `katTikk` — bumps on every rotation to replay the splash.
  int _tick = 0;

  @override
  void didUpdateWidget(BergenCategoryRad old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) _tick++;
  }

  void _rotate(int d) {
    final n = widget.categories.length;
    if (n == 0) return;
    widget.onIndexChanged((widget.index + d + n) % n);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final n = widget.categories.length;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (_) => setState(() {
        _dragging = true;
        _dx = 0;
      }),
      onHorizontalDragUpdate: (d) => setState(() {
        _dx = (_dx + d.delta.dx).clamp(-150.0, 150.0);
      }),
      onHorizontalDragEnd: (_) {
        final dx = _dx;
        setState(() {
          _dragging = false;
          _dx = 0;
        });
        if (dx <= -40) {
          _rotate(1);
        } else if (dx >= 40) {
          _rotate(-1);
        }
      },
      onHorizontalDragCancel: () => setState(() {
        _dragging = false;
        _dx = 0;
      }),
      child: SizedBox(
        height: 172 * s,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ..._splash(context),
            _burst(context),
            Positioned(
              left: 0,
              right: 0,
              top: 10 * s,
              height: 150 * s,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final e in _ordered(n)) _item(context, e.$1, e.$2, n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Items sorted so the focused one paints last (on top).
  List<(int, int)> _ordered(int n) {
    final list = <(int, int)>[];
    for (var ki = 0; ki < n; ki++) {
      final p = (ki - widget.index + 2 + n) % n;
      list.add((ki, p));
    }
    list.sort((a, b) => (a.$2 - 2).abs().compareTo((b.$2 - 2).abs()) * -1);
    return list;
  }

  /// `skvulpRingA/B` — one ring bursting out on every rotation.
  Widget _burst(BuildContext context) {
    final s = context.bs;
    final w = MediaQuery.sizeOf(context).width;
    return Positioned(
      left: w / 2 - 55 * s,
      top: 78 * s,
      width: 110 * s,
      height: 36 * s,
      child: IgnorePointer(
        child: OnbTimeline(
          key: ValueKey('burst-$_tick'),
          durationMs: 950,
          builder: (context, t, _) {
            if (_tick == 0) return const SizedBox.shrink();
            final p = const Cubic(.2, .7, .3, 1).transform(onbP(t, 0, 950));
            return Opacity(
              opacity: (.85 * (1 - p)).clamp(0.0, 1.0),
              child: Transform.scale(
                scale: .28 + 1.32 * p,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .85),
                      width: 1.5 * s,
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

  /// `skvulp` rings and the `ikSkygge` shadow under the focused icon.
  List<Widget> _splash(BuildContext context) {
    final s = context.bs;
    final w = MediaQuery.sizeOf(context).width;
    return [
      Positioned(
        left: w / 2 - 55 * s,
        top: 78 * s,
        width: 110 * s,
        height: 36 * s,
        child: IgnorePointer(
          child: OnbLoopClock(
            builder: (context, t, _) => Stack(
              fit: StackFit.expand,
              children: [
                for (final (delay, alpha) in [
                  (0.0, .55),
                  (1100.0, .4),
                  (2200.0, .3),
                ])
                  Builder(
                    builder: (context) {
                      final p = onbLoop(t, delay, 3200);
                      if (p == null) return const SizedBox.shrink();
                      final e = Curves.easeOut.transform(p);
                      return Opacity(
                        opacity: .8 * (1 - e),
                        child: Transform.scale(
                          scale: .55 + .95 * e,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: alpha),
                                width: (alpha > .35 ? 1.5 : 1) * s,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
      Positioned(
        left: w / 2 - 35 * s,
        top: 86 * s,
        width: 70 * s,
        height: 18 * s,
        child: IgnorePointer(
          child: OnbLoopClock(
            builder: (context, t, _) {
              final p = (onbLoop(t, 0, 3400) ?? 0);
              final sx = onbKf(
                p,
                const [0, .5, 1],
                const [1, .82, 1],
                Curves.easeInOut,
              );
              final o = onbKf(
                p,
                const [0, .5, 1],
                const [.55, .35, .55],
                Curves.easeInOut,
              );
              return Opacity(
                opacity: o,
                child: Transform.scale(
                  scaleX: sx,
                  child: onbBlurred(
                    4,
                    bergenRadial(
                      colors: const [Color(0x8C000000), Color(0x00000000)],
                      stops: const [0, .72],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ];
  }

  Widget _item(BuildContext context, int ki, int p, int n) {
    final s = context.bs;
    final w = MediaQuery.sizeOf(context).width;
    final cat = widget.categories[ki];
    final focus = p == 2;
    final d = (p - 2).abs();
    final visible = d <= 2;
    final dragShift = _dragging ? _dx * .35 : 0.0;
    final x = (p - 2) * 74.0 + dragShift;
    final y = focus ? 0.0 : 34.0;
    final sc = focus ? 1.0 : .54;
    final op = !visible ? 0.0 : (focus ? 1.0 : (d == 1 ? .82 : .7));

    return AnimatedPositioned(
      key: ValueKey('cat-$ki-${cat.id}'),
      duration: _dragging ? Duration.zero : const Duration(milliseconds: 600),
      curve: const Cubic(.3, 1.15, .4, 1),
      left: w / 2 - 45 * s + x * s,
      top: y * s,
      width: 90 * s,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 450),
        opacity: op,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (!visible) return;
            if (focus) {
              widget.onOpen(cat);
            } else {
              widget.onIndexChanged(ki);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 86 * s,
                height: 78 * s,
                child: OnbLoopClock(
                  child: _icon(context, cat, focus),
                  builder: (context, t, child) {
                    final hover = focus
                        ? onbKf(
                            (onbLoop(t, 0, 3400) ?? 0),
                            const [0, .5, 1],
                            const [0, -6, 0],
                            Curves.easeInOut,
                          )
                        : 0.0;
                    return Transform.translate(
                      offset: Offset(0, hover * s),
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 600),
                        curve: const Cubic(.3, 1.15, .4, 1),
                        alignment: Alignment.topCenter,
                        scale: sc,
                        child: child,
                      ),
                    );
                  },
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                // margin-top 6 (focus) / -28 — the negative part as a
                // transform since Flutter margins can't be negative.
                padding: EdgeInsets.only(top: focus ? 6 * s : 0),
                transform: Matrix4.translationValues(0, focus ? 0 : -28 * s, 0),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 400),
                  style: bDisplay(
                    context,
                    focus ? 12.5 : 10,
                    weight: focus ? FontWeight.w800 : FontWeight.w700,
                    letterSpacingEm: -.01,
                    color: focus
                        ? BergenColors.orangeText
                        : const Color(0xBFFFFFFF),
                    shadows: const [
                      Shadow(
                        color: Color.fromRGBO(6, 22, 30, .8),
                        offset: Offset(0, 1),
                      ),
                      Shadow(
                        color: Color.fromRGBO(6, 22, 30, .7),
                        offset: Offset(0, 2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Text(
                    cat.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 350),
                opacity: focus ? 1 : 0,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 500),
                  curve: const Cubic(.3, 1.2, .4, 1),
                  offset: Offset(0, focus ? 0 : -.6),
                  child: Column(
                    children: [
                      SizedBox(height: 2 * s),
                      Text(
                        cat.liveText,
                        style: bText(
                          context,
                          10,
                          color: const Color(0xFFFFD9A8),
                          shadows: const [
                            Shadow(
                              color: Color.fromRGBO(6, 22, 30, .8),
                              offset: Offset(0, 1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 4 * s),
                      Container(
                        width: 6 * s,
                        height: 6 * s,
                        decoration: BoxDecoration(
                          color: BergenColors.mint,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: BergenColors.mint,
                              blurRadius: 12 * s,
                            ),
                            BoxShadow(
                              color: BergenColors.mint.withValues(alpha: .6),
                              blurRadius: 24 * s,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (cat.isNew && !focus)
                Transform.translate(
                  offset: Offset(0, -16 * s),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6 * s,
                      vertical: 1 * s,
                    ),
                    decoration: BoxDecoration(
                      color: BergenColors.orange,
                      borderRadius: BorderRadius.circular(6 * s),
                      boxShadow: const [
                        BoxShadow(color: Colors.white, spreadRadius: 1.5),
                      ],
                    ),
                    child: Text(
                      BergenCopy.newTag,
                      style: bText(context, 8, weight: FontWeight.w800),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _icon(BuildContext context, BergenCategory cat, bool focus) {
    final s = context.bs;
    final shadow = focus
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: .7),
              offset: Offset(0, 12 * s),
              blurRadius: 9 * s,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: .16),
              blurRadius: 22 * s,
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: .55),
              offset: Offset(0, 8 * s),
              blurRadius: 6 * s,
            ),
          ];
    Widget art;
    if (cat.iconAsset != null) {
      art = bergenSvg(cat.iconAsset!, fit: BoxFit.contain);
    } else if (cat.iconUrl != null && cat.iconUrl!.isNotEmpty) {
      art = Padding(
        padding: EdgeInsets.all(10 * s),
        child: cat.iconUrl!.toLowerCase().endsWith('.svg')
            ? SvgPicture.network(cat.iconUrl!, fit: BoxFit.contain)
            : Image.network(cat.iconUrl!, fit: BoxFit.contain),
      );
    } else {
      art = Icon(Icons.storefront_rounded, size: 40 * s, color: Colors.white);
    }
    // Drop-shadow via a soft-edged copy beneath the art.
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: Container(
                width: 56 * s,
                height: 40 * s,
                margin: EdgeInsets.only(top: 22 * s),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20 * s),
                  boxShadow: shadow,
                ),
              ),
            ),
          ),
        ),
        art,
      ],
    );
  }
}

/// `md0…md4` — the little category dots under "Butikker på …".
class BergenCategoryDots extends StatelessWidget {
  const BergenCategoryDots({
    super.key,
    required this.count,
    required this.index,
  });

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < math.min(count, 8); i++) ...[
          if (i > 0) SizedBox(width: 4 * s),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: (i == index ? 14 : 4) * s,
            height: 4 * s,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2 * s),
              gradient: i == index
                  ? const LinearGradient(
                      colors: [BergenColors.orangeSoft, BergenColors.orangeHot],
                    )
                  : null,
              color: i == index ? null : const Color(0x66F28A55),
            ),
          ),
        ],
      ],
    );
  }
}
