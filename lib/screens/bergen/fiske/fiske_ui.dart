import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/auth/launch/lf_widgets.dart';
import '../kit/bergen_css.dart' show rgba;
import '../utforsk/utforsk_bits.dart' show utfMerke;
import 'fiske_cards.dart' show FiskeCatch;
import 'fiske_copy.dart';
import 'fiske_game.dart';

// ── Fjordfiske · the Launch controls (L8069–8106, design px) ─────────────────
// Everything here is drawn in the prototype's own px; the screen scales it
// with the frame's one uniform factor.

/// `bobleInn .4s cubic-bezier(.3,1.3,.5,1)` (or `.3s ease-out`) on mount.
class FiskeBobleInn extends StatelessWidget {
  const FiskeBobleInn({super.key, required this.child, this.ms = 400, this.curve = const Cubic(.3, 1.3, .5, 1)});

  final Widget child;
  final double ms;
  final Curve curve;

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: ms,
    child: child,
    builder: (context, t, child) {
      final p = (t / ms).clamp(0.0, 1.0);
      final y = kf(p, const [0, .6, 1], const [10, -2, 0], curve);
      final s = kf(p, const [0, .6, 1], const [.9, 1.02, 1], curve);
      final o = kf(p, const [0, .6, 1], const [0, 1, 1], curve);
      return Opacity(
        opacity: o.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, y), child: Transform.scale(scale: s, child: child)),
      );
    },
  );
}

/// «Kast ut» / «Kast ut igjen» (`kastUt`): 56 px orange key with the rod
/// icon.
class FiskeLKastUt extends StatelessWidget {
  const FiskeLKastUt({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  static const String _ikon =
      '<svg viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round"><path d="M4 20L16 4"/><path d="M16 4c2 3 1 7-2 9"/><circle cx="13" cy="15" r="2.2"/></svg>';

  @override
  Widget build(BuildContext context) => FiskeBobleInn(
    child: LfPress(
      key: const Key('a1_fiske_kast'),
      onTap: onTap,
      dy: 3,
      scale: .97,
      child: CssBox(
        height: 56,
        radius: BorderRadius.circular(28),
        padding: const EdgeInsets.fromLTRB(20, 0, 26, 0),
        bg: const [CssLinear(180, [Color(0xFFFF9466), Color(0xFFE95C2C)])],
        shadows: [
          CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .5)),
          CssShadow.inset(0, -2, 0, 0, rgba(0, 0, 0, .08)),
          const CssShadow(0, 4, 0, 0, Color(0xFFA63A12)),
          CssShadow(0, 16, 22, -8, rgba(3, 16, 24, .8)),
        ],
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.string(_ikon, width: 22, height: 22),
            const SizedBox(width: 9),
            Text(label, style: jakarta(16, em: -0.01)),
          ],
        ),
      ),
    ),
  );
}

/// «Snøret er ute … vent på napp»: the glass pill with three lantern dots
/// (`glod 1.2s`, .3 s apart).
class FiskeLVenter extends StatelessWidget {
  const FiskeLVenter({super.key});

  @override
  Widget build(BuildContext context) => FiskeBobleInn(
    ms: 300,
    curve: cssEaseOut,
    child: CssBox(
      key: const Key('a1_fiske_venter'),
      height: 52,
      radius: BorderRadius.circular(26),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      bg: const [CssLinear(180, [Color.fromRGBO(63, 135, 152, .7), Color.fromRGBO(26, 70, 84, .82)])],
      shadows: [
        CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .35)),
        CssShadow.inset(0, 0, 0, 1, rgba(255, 255, 255, .12)),
        CssShadow(0, 3, 0, 0, rgba(8, 28, 36, .8)),
        CssShadow(0, 14, 20, -10, rgba(3, 16, 24, .8)),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RepaintBoundary(
            child: LfLoop(
              frozenMs: 600,
              builder: (context, t, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Opacity(
                      opacity: () {
                        final p = kfLoop(t, i * 300.0, 1200);
                        return p == null ? 1.0 : kf(p, const [0, .5, 1], const [.7, 1, .7], cssEaseInOut);
                      }(),
                      child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFF2C14E), shape: BoxShape.circle)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 9),
          Flexible(child: Text(FiskeCopy.a1_fiske_venter, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(13.5, weight: FontWeight.w800))),
        ],
      ),
    ),
  );
}

const List<CssBg> _kOrangeRund = [
  CssRadial([Color.fromRGBO(255, 255, 255, .4), Color.fromRGBO(255, 255, 255, 0)], stops: [0, .7], rx: .7, ry: .55, cx: .5, cy: .22),
  CssLinear(180, [Color(0xFFFF9466), Color(0xFFE95C2C), Color(0xFFC94A1E)], [0, .6, 1]),
];

const String _kPilOpp =
    '<svg viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M12 19V5M5.5 11.5L12 5l6.5 6.5"/></svg>';

/// «DRA INN!» (`draInn`): the 84 px orange disc pulsing (`nappPuls .55s`:
/// scale 1.06 and a ring spreading 18 px) with the 1.7 s time line under it
/// (`tidStrek`).
class FiskeLDraInn extends StatelessWidget {
  const FiskeLDraInn({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LfPress(
    key: const Key('a1_fiske_dra'),
    onTap: onTap,
    dy: 3,
    scale: .97,
    child: SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          RepaintBoundary(
            child: LfLoop(
              builder: (context, t, child) {
                final p = (t % 550) / 550;
                final k = kf(p, const [0, .5, 1], const [0, 1, 0], cssEaseInOut);
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // The ring spreading out (`0 0 0 18px rgba(242,109,61,0)`).
                    Positioned.fill(
                      child: Transform.scale(
                        scale: 1 + .06 * k,
                        child: CssBox(
                          radius: BorderRadius.circular(42),
                          shadows: [
                            CssShadow(0, 0, 0, 18 * k, rgba(242, 109, 61, .7 * (1 - k))),
                            CssShadow(0, 18 + 4 * k, 30 + 4 * k, -12, rgba(233, 92, 44, .9 + .1 * k)),
                          ],
                        ),
                      ),
                    ),
                    Positioned.fill(child: Transform.scale(scale: 1 + .06 * k, child: child)),
                  ],
                );
              },
              child: CssBox(
                radius: BorderRadius.circular(42),
                bg: _kOrangeRund,
                shadows: [
                  CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .55)),
                  CssShadow.inset(0, -4, 8, 0, rgba(120, 30, 6, .35)),
                  CssShadow(0, 0, 0, 3, rgba(255, 148, 102, .25)),
                  const CssShadow(0, 4, 0, 0, Color(0xFFA63A12)),
                ],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.string(_kPilOpp, width: 22, height: 22),
                    const SizedBox(height: 1),
                    Text(FiskeCopy.a1_fiske_dra, style: jakarta(13, em: -0.01, height: 1)),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: -14,
            height: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: ColoredBox(
                color: rgba(255, 255, 255, .3),
                child: LfOnce(
                  ms: 1700,
                  builder: (context, t, _) => Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: 1 - (t / 1700).clamp(0.0, 1.0),
                      heightFactor: 1,
                      child: const DecoratedBox(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(2)))),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// A round key with its label under it: glass 54 px or orange 68 px
/// (Slipp, Legg i kurven, Lagre; Slipp, Hent, Sett som mål).
class FiskeLRund extends StatelessWidget {
  const FiskeLRund({super.key, required this.svg, required this.label, required this.onTap, this.orange = false, this.ikon = 20, this.opacity = 1});

  final String svg;
  final String label;
  final VoidCallback onTap;
  final bool orange;
  final double ikon;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final d = orange ? 68.0 : 54.0;
    final tekstSkygge = [Shadow(color: rgba(3, 14, 20, .8), blurRadius: 6, offset: const Offset(0, 1))];
    return Opacity(
      opacity: opacity,
      child: LfPress(
        onTap: onTap,
        dy: 3,
        scale: .97,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CssBox(
              width: d,
              height: d,
              radius: BorderRadius.circular(d / 2),
              bg: orange
                  ? _kOrangeRund
                  : const [
                      CssRadial([Color.fromRGBO(255, 255, 255, .26), Color.fromRGBO(255, 255, 255, 0)], stops: [0, .7], rx: .7, ry: .55, cx: .5, cy: .2),
                      CssLinear(180, [Color.fromRGBO(63, 135, 152, .75), Color.fromRGBO(26, 70, 84, .85)]),
                    ],
              shadows: orange
                  ? [
                      CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .55)),
                      CssShadow.inset(0, -4, 8, 0, rgba(120, 30, 6, .35)),
                      CssShadow(0, 0, 0, 3, rgba(255, 148, 102, .22)),
                      const CssShadow(0, 4, 0, 0, Color(0xFFA63A12)),
                      CssShadow(0, 16, 22, -8, rgba(3, 16, 24, .8)),
                    ]
                  : [
                      CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .4)),
                      CssShadow.inset(0, 0, 0, 1, rgba(255, 255, 255, .14)),
                      CssShadow.inset(0, -3, 6, 0, rgba(3, 16, 24, .35)),
                      CssShadow(0, 3.5, 0, 0, rgba(8, 28, 36, .85)),
                      CssShadow(0, 14, 20, -8, rgba(3, 16, 24, .8)),
                    ],
              child: Center(child: SvgPicture.string(svg, width: ikon, height: ikon)),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: inter(10.5, weight: FontWeight.w800, color: orange ? Colors.white : const Color(0xFFDCE9EC)).copyWith(shadows: tekstSkygge),
            ),
          ],
        ),
      ),
    );
  }

  static const String kryss =
      '<svg viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="2.6" stroke-linecap="round"><path d="M6 6l12 12M18 6L6 18"/></svg>';
  static const String pilOpp = _kPilOpp;
  static const String hjerte =
      '<svg viewBox="0 0 24 24" fill="#F26D3D" stroke="#FFFFFF" stroke-width="2.6" stroke-linejoin="round"><path d="M12 20.4l-7.2-7.2a4.9 4.9 0 1 1 7-7l.2.3.2-.3a4.9 4.9 0 1 1 7 7z"/></svg>';
  static const String hake =
      '<svg viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M20 7L9 18l-5-5"/></svg>';
  static const String blink =
      '<svg viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="4.5"/><circle cx="12" cy="12" r="1" fill="#FFFFFF"/></svg>';
}

// ── Agn (L8091–8104) ─────────────────────────────────────────────────────────

/// The bait rail: 46 px discs (lit teal with the orange rim when chosen,
/// lifted 4 px), the Æ mark for «Alle» and an extruded line icon for the
/// others turning in 3D (`hjulIkon 4.5s`, .9 s apart), the count badge, the
/// label.
class FiskeLAgnRail extends StatelessWidget {
  const FiskeLAgnRail({super.key, required this.selected, required this.count, required this.onSelect});

  final FiskeAgn selected;
  final int Function(FiskeAgn) count;
  final ValueChanged<FiskeAgn> onSelect;

  static String label(FiskeAgn a) => switch (a) {
    FiskeAgn.alle => FiskeCopy.a1_fiske_agn_alle,
    FiskeAgn.fisk => FiskeCopy.a1_fiske_agn_fisk,
    FiskeAgn.mat => FiskeCopy.a1_fiske_agn_mat,
    FiskeAgn.mote => FiskeCopy.a1_fiske_agn_mote,
    FiskeAgn.interior => FiskeCopy.a1_fiske_agn_interior,
    FiskeAgn.gaver => FiskeCopy.a1_fiske_agn_gaver,
  };

  /// `sti` and `side` per bait (the prototype's map).
  static (String, Color)? sti(FiskeAgn a) => switch (a) {
    FiskeAgn.fisk => ('M3 12c3-5 9-6 13-3l4-3v12l-4-3c-4 3-10 2-13-3zM8 11.5h.01', const Color(0xFF0F4A5A)),
    FiskeAgn.mat => ('M4 18v-4a8 6 0 0 1 16 0v4zM8.5 10.5l1 3M12 9.5v4M15.5 10.5l-1 3', const Color(0xFF7A5408)),
    FiskeAgn.mote => ('M8 4L3 7l2 4 3-1v10h8V10l3 1 2-4-5-3c-.5 1.5-2 2.5-4 2.5S8.5 5.5 8 4z', const Color(0xFF4A2E6E)),
    FiskeAgn.interior => ('M5 10V8a3 3 0 0 1 3-3h8a3 3 0 0 1 3 3v2M3 12a2 2 0 0 1 4 0v2h10v-2a2 2 0 0 1 4 0v5H3zM5 17v2M19 17v2', const Color(0xFF5E4428)),
    FiskeAgn.gaver => ('M4 10h16v10H4zM3 7h18v3H3zM12 7v13M12 7C10.5 4 7 4 7 6s3 1 5 1zM12 7c1.5-3 5-3 5-1s-3 1-5 1z', const Color(0xFF8F3414)),
    FiskeAgn.alle => null,
  };

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    key: const Key('a1_fiske_agn'),
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
    clipBehavior: Clip.none,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final a in FiskeAgn.values) ...[
          if (a != FiskeAgn.values.first) const SizedBox(width: 6),
          _Agn(agn: a, on: a == selected, count: count(a), onTap: () => onSelect(a == selected ? FiskeAgn.alle : a)),
        ],
      ],
    ),
  );
}

class _Agn extends StatelessWidget {
  const _Agn({required this.agn, required this.on, required this.count, required this.onTap});

  final FiskeAgn agn;
  final bool on;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) == true;
    final sti = FiskeLAgnRail.sti(agn);
    return Semantics(
      button: true,
      selected: on,
      label: FiskeLAgnRail.label(agn),
      child: LfPress(
        key: Key('a1_fiske_agn_${agn.name}'),
        onTap: onTap,
        scale: .94,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: on ? -4 : 0),
          duration: Duration(milliseconds: reduce ? 0 : 350),
          curve: const Cubic(.34, 1.56, .64, 1),
          builder: (context, y, child) => Transform.translate(offset: Offset(0, y), child: child),
          child: SizedBox(
            width: 56,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 46,
                  height: 46,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: CssBox(
                          radius: BorderRadius.circular(23),
                          bg: on
                              ? const [CssLinear(180, [Color(0xFF438C9D), Color(0xFF1E4F5C)])]
                              : const [CssLinear(180, [Color.fromRGBO(255, 255, 255, .26), Color.fromRGBO(255, 255, 255, .08)])],
                          shadows: on
                              ? [
                                  CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .45)),
                                  CssShadow.inset(0, -3, 5, 0, rgba(3, 16, 24, .35)),
                                  const CssShadow(0, 0, 0, 2.5, Color(0xFFF26D3D)),
                                  CssShadow(0, 0, 0, 4, rgba(255, 148, 102, .25)),
                                  const CssShadow(0, 3, 0, 2.5, Color(0xFFA63A12)),
                                  CssShadow(0, 14, 18, -6, rgba(3, 16, 24, .8)),
                                ]
                              : [
                                  CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .45)),
                                  CssShadow.inset(0, 0, 0, 1, rgba(255, 255, 255, .18)),
                                  CssShadow(0, 3, 0, 0, rgba(6, 22, 30, .45)),
                                  CssShadow(0, 12, 16, -8, rgba(3, 16, 24, .75)),
                                ],
                        ),
                      ),
                      Positioned(
                        left: 8,
                        right: 8,
                        top: 3,
                        height: 14,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(Radius.elliptical(15, 7)),
                            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [rgba(255, 255, 255, .4), rgba(255, 255, 255, 0)]),
                          ),
                        ),
                      ),
                      Center(
                        child: sti == null
                            ? Padding(padding: const EdgeInsets.only(left: 2), child: utfMerke(30, 24))
                            : _Hjulikon(sti: sti.$1, side: sti.$2, delayMs: -900.0 * FiskeAgn.values.indexOf(agn)),
                      ),
                      if (count > 0)
                        Positioned(
                          top: -6,
                          right: -8,
                          child: CssBox(
                            height: 18,
                            radius: BorderRadius.circular(9),
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            bg: on ? const [CssLinear(180, [Color(0xFFFF9466), Color(0xFFE95C2C)])] : [CssSolid(rgba(6, 22, 30, .72))],
                            shadows: on
                                ? [CssShadow.inset(0, 1, 0, 0, rgba(255, 255, 255, .5)), const CssShadow(0, 1.5, 0, 0, Color(0xFFA63A12))]
                                : [CssShadow.inset(0, 0, 0, 1, rgba(255, 255, 255, .22)), CssShadow(0, 2, 4, 0, rgba(0, 0, 0, .4))],
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 8),
                              child: Center(
                                widthFactor: 1,
                                child: Text(
                                  '$count',
                                  style: inter(9.5, weight: FontWeight.w800).copyWith(fontFeatures: const [ui.FontFeature.tabularFigures()]),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  FiskeLAgnRail.label(agn),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: inter(10, weight: FontWeight.w800, color: on ? Colors.white : const Color(0xFFDCE9EC)).copyWith(
                    shadows: [Shadow(color: rgba(3, 14, 20, .8), blurRadius: 6, offset: const Offset(0, 1))],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The extruded line icon (`harSti`): eight copies in the side colour
/// 0.8 px apart in depth and the white face on top, turning together
/// (`hjulIkon 4.5s ease-in-out infinite`: rotateY ∓24°, rotateX 6° / −4°,
/// `perspective:240px`).
class _Hjulikon extends StatelessWidget {
  const _Hjulikon({required this.sti, required this.side, required this.delayMs});

  final String sti;
  final Color side;
  final double delayMs;

  String _svg(Color c) {
    final hex = '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    return '<svg viewBox="0 0 24 24"><path d="$sti" fill="none" stroke="$hex" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round"/></svg>';
  }

  @override
  Widget build(BuildContext context) {
    final sideSvg = SvgPicture.string(_svg(side), width: 26, height: 26);
    final face = SvgPicture.string(_svg(Colors.white), width: 26, height: 26);
    return RepaintBoundary(
      child: SizedBox(
        width: 26,
        height: 26,
        child: LfLoop(
          frozenMs: 0,
          builder: (context, t, _) {
            var p = ((t - delayMs) % 4500) / 4500;
            if (p < 0) p += 1;
            final ry = kf(p, const [0, .5, 1], const [-24, 24, -24], cssEaseInOut) * math.pi / 180;
            final rx = kf(p, const [0, .5, 1], const [6, -4, 6], cssEaseInOut) * math.pi / 180;
            Matrix4 m(double z) => Matrix4.identity()
              ..setEntry(3, 2, -1 / 240)
              ..rotateY(ry)
              ..rotateX(rx)
              ..translateByDouble(0, 0, z, 1);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = 8; i >= 1; i--) Transform(alignment: Alignment.center, transform: m(-.8 * i), child: sideSvg),
                Transform(alignment: Alignment.center, transform: m(0), child: face),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Fangst (L8011–8037) ──────────────────────────────────────────────────────

/// The catch card: the teal glass card (250), the scene with its water and
/// the art bobbing (`bob 4s`) with its shadow, the bydel chip, «Napp!» and
/// Ægil surprised for the day's first catch, «+N poeng» flying up
/// (`myntOpp 1.4s .3s`), name, shop, the orange price and the ETA.
class FiskeLFangstKort extends StatelessWidget {
  const FiskeLFangstKort({super.key, required this.item, required this.earned, this.onNappTap});

  final FiskeCatch item;
  final int earned;
  final VoidCallback? onNappTap;

  @override
  Widget build(BuildContext context) {
    final art = FiskeArt.of(FiskeAgn.of(item.suggestion));
    final ico = 'assets/svgs/dashboard/${art.asset}.svg';
    return SizedBox(
      key: const Key('a1_fiske_fangst'),
      width: 250,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CssBox(
            radius: BorderRadius.circular(26),
            padding: const EdgeInsets.all(6),
            bg: const [CssLinear(180, [Color.fromRGBO(52, 112, 128, .88), Color.fromRGBO(24, 64, 76, .94)])],
            shadows: [
              CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .32)),
              CssShadow.inset(0, 0, 0, 1, rgba(255, 255, 255, .12)),
              CssShadow(0, 3, 0, 0, rgba(10, 34, 42, .85)),
              CssShadow(0, 30, 44, -18, rgba(3, 14, 20, .9)),
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 144,
                  child: CssBox(
                    radius: BorderRadius.circular(20),
                    clip: true,
                    bg: const [
                      CssRadial([Color.fromRGBO(255, 255, 255, .18), Color.fromRGBO(255, 255, 255, 0)], stops: [0, .7], rx: .7, ry: .6, cx: .5, cy: .3),
                      CssLinear(180, [Color(0xFF3E7E8E), Color(0xFF24596A), Color(0xFF173F4C)], [0, .6, 1]),
                    ],
                    shadows: [
                      CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .3)),
                      CssShadow.inset(0, -6, 12, -6, rgba(3, 14, 20, .5)),
                    ],
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        const Positioned(left: 0, right: 0, top: 104, bottom: 0, child: CustomPaint(painter: _KortVann())),
                        Positioned(
                          left: 238 / 2 - 60,
                          top: 106,
                          width: 120,
                          height: 16,
                          child: const CssBox(
                            radius: BorderRadius.all(Radius.elliptical(60, 8)),
                            bg: [CssRadial.closestSide([Color.fromRGBO(3, 14, 20, .55), Color.fromRGBO(3, 14, 20, 0)])],
                          ),
                        ),
                        Positioned(left: 238 / 2 - 65, top: 104, width: 130, height: 18, child: const _Skvulp()),
                        Positioned(
                          left: art.left,
                          top: art.top,
                          width: art.width,
                          height: art.height,
                          child: _Bob(child: _MedSkygge(child: SvgPicture.asset(ico, width: art.width, height: art.height))),
                        ),
                        if (item.napp) ...[
                          Positioned(
                            top: 10,
                            left: 10,
                            child: GestureDetector(
                              onTap: onNappTap,
                              child: _Popp(
                                child: Container(
                                  key: const Key('a1_fiske_napp_badge'),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    gradient: const LinearGradient(colors: [Color(0xFF5CE0B8), Color(0xFF9C7BE8)]),
                                    boxShadow: [BoxShadow(color: rgba(92, 224, 184, .8), offset: const Offset(0, 8), blurRadius: 14, spreadRadius: -6)],
                                  ),
                                  child: Text(FiskeCopy.a1_fiske_napp, style: inter(10.5, weight: FontWeight.w800, color: const Color(0xFF0F1F2B))),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 6,
                            left: 6,
                            width: 58,
                            child: _Popp(delayMs: 150, child: Image.asset('assets/images/dashboard/shock.png', width: 58)),
                          ),
                        ],
                        if ((item.bydel ?? '').isNotEmpty)
                          Positioned(
                            top: 9,
                            right: 9,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(7, 3, 9, 3),
                              decoration: BoxDecoration(
                                color: rgba(6, 22, 30, .5),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: rgba(255, 255, 255, .16)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SvgPicture.string(_pin, width: 9, height: 9),
                                  const SizedBox(width: 4),
                                  Text(item.bydel!, style: inter(9.5, weight: FontWeight.w800)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: jakarta(16, em: -0.015, height: 1.2)),
                      if ((item.storeName ?? '').isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(item.storeName!, style: inter(11.5, weight: FontWeight.w700, color: const Color(0xFFBFD6DD))),
                      ],
                      const SizedBox(height: 2 + 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (item.priceKr != null)
                            CssBox(
                              radius: BorderRadius.circular(11),
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                              bg: const [CssLinear(180, [Color(0xFFFF9466), Color(0xFFE95C2C)])],
                              shadows: [
                                CssShadow.inset(0, 1, 0, 0, rgba(255, 255, 255, .45)),
                                const CssShadow(0, 2.5, 0, 0, Color(0xFFA63A12)),
                                CssShadow(0, 8, 12, -6, rgba(3, 16, 24, .7)),
                              ],
                              child: Text(
                                '${item.priceKr} kr',
                                style: jakarta(16).copyWith(fontFeatures: const [ui.FontFeature.tabularFigures()]),
                              ),
                            )
                          else
                            const SizedBox.shrink(),
                          if ((item.eta ?? '').isNotEmpty)
                            Flexible(
                              child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: rgba(255, 255, 255, .1),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: rgba(255, 255, 255, .14)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SvgPicture.string(_klokke, width: 10, height: 10),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(item.eta!, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(10, weight: FontWeight.w800, color: const Color(0xFFDCE9EC))),
                                  ),
                                ],
                              ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (earned > 0)
            Positioned(
              top: 10,
              left: 10,
              child: LfOnce(
                ms: 1700,
                builder: (context, t, child) {
                  final p = kfP(t, 300, 1400);
                  if (p <= 0 || p >= 1) return Opacity(opacity: 0, child: child);
                  final o = kf(p, const [0, .25, .75, 1], const [0, 1, 1, 0], cssEaseOut);
                  final y = kf(p, const [0, .25, .75, 1], const [6, -14, -20, -30], cssEaseOut);
                  final sc = kf(p, const [0, .25, .75, 1], const [.6, 1.05, 1, .9], cssEaseOut);
                  return FractionalTranslation(
                    translation: const Offset(-.5, 0),
                    child: Opacity(opacity: o, child: Transform.translate(offset: Offset(0, y), child: Transform.scale(scale: sc, child: child))),
                  );
                },
                child: Container(
                  key: const Key('a1_fiske_plus'),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1F2B),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [BoxShadow(color: Color(0xFF7FF0CB), spreadRadius: 1.5)],
                  ),
                  child: Text(FiskeCopy.a1_fiske_plus(earned), style: inter(10, weight: FontWeight.w800, color: const Color(0xFF7FF0CB))),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static const String _pin =
      '<svg viewBox="0 0 24 24" fill="none" stroke="#9FF0D4" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M12 21s-7-6.5-7-12a7 7 0 0 1 14 0c0 5.5-7 12-7 12z"/><circle cx="12" cy="9" r="2.4"/></svg>';
  static const String _klokke =
      '<svg viewBox="0 0 24 24" fill="none" stroke="#9FF0D4" stroke-width="2.8" stroke-linecap="round"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg>';
}

/// The card's water: lines every 7 px over `#2C6A7B → #17404D`, the surface
/// line.
class _KortVann extends CustomPainter {
  const _KortVann();

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.drawRect(r, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2C6A7B), Color(0xFF17404D)]).createShader(r));
    final l = Paint()..color = const Color.fromRGBO(200, 240, 245, .08);
    for (var y = size.height - 1; y >= 0; y -= 7) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), l);
    }
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 1), Paint()..color = const Color.fromRGBO(214, 242, 250, .45));
  }

  @override
  bool shouldRepaint(_KortVann old) => false;
}

/// `duppSkvulp 4s ease-out infinite` on the ring round the art.
class _Skvulp extends StatelessWidget {
  const _Skvulp();

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: LfLoop(
      frozenMs: 1500,
      builder: (context, t, child) {
        final p = (t % 4000) / 4000;
        return Opacity(
          opacity: kf(p, const [0, .18, 1], const [0, .5, 0], cssEaseOut),
          child: Transform.scale(scale: kf(p, const [0, 1], const [.55, 1.6], cssEaseOut), child: child),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.elliptical(65, 9)),
          border: Border.all(color: rgba(214, 242, 250, .5), width: 1.3),
        ),
      ),
    ),
  );
}

/// `bob 4s ease-in-out infinite`.
class _Bob extends StatelessWidget {
  const _Bob({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: LfLoop(
      builder: (context, t, child) => Transform.translate(
        offset: Offset(0, kf((t % 4000) / 4000, const [0, .5, 1], const [0, -5, 0], cssEaseInOut)),
        child: child,
      ),
      child: child,
    ),
  );
}

/// `filter: drop-shadow(0 12px 14px rgba(20,25,30,.45))` — a blurred, tinted
/// copy under the art (static, so it is drawn once).
class _MedSkygge extends StatelessWidget {
  const _MedSkygge({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Transform.translate(
        offset: const Offset(0, 12),
        child: ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
          child: ColorFiltered(colorFilter: ColorFilter.mode(rgba(20, 25, 30, .45), BlendMode.srcIn), child: child),
        ),
      ),
      child,
    ],
  );
}

/// `popp .6s cubic-bezier(.34,1.56,.64,1)`.
class _Popp extends StatelessWidget {
  const _Popp({required this.child, this.delayMs = 0});

  final Widget child;
  final double delayMs;

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: 600 + delayMs,
    child: child,
    builder: (context, t, child) => Transform.scale(
      scale: kf(kfP(t, delayMs, 600), const [0, .35, .7, 1], const [1, 1.16, .96, 1], const Cubic(.34, 1.56, .64, 1)),
      child: child,
    ),
  );
}
