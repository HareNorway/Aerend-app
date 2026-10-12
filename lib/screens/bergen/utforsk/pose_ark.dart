import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../data/points/points_rules.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/home/bergen/bergen_nav.dart' show BergenTab;
import '../../common/home/bergen/bergen_rails.dart' show BergenHolo, BergenKenBurns;
import '../../common/homeMainV1/home_main_v1.dart';
import '../hjem/hjem_harness.dart';
import '../kasse/kurv_parts.dart' show KurvLinje;
import '../kit/bergen_cart.dart';
import '../kit/bergen_perf.dart';
import '../kit/bergen_routes.dart';
import '../kit/bergen_toast.dart';
import '../meg/meg_ark.dart';
import 'pose_segment.dart';
import 'utforsk_copy.dart';

/// Secures one bag: a real cart line through the normal cart API (no
/// payment). The server's own message shows when it says no (another
/// store's basket, sold out …).
Future<bool> sikrePose(BuildContext context, UtfPose p, {bool toast = true}) => BergenCart.add(
  context,
  storeId: p.storeId,
  productId: p.id,
  toast: toast ? UtforskCopy.a1_pose_sikret_toast(p.hent ?? '') : null,
  stille: !toast,
);

/// The bag's sheet (new Bergen `utfPose`, L9764–9801 and L20320): the dark
/// Ark with the photo (the slots left, «−60 %», «Overraskelse fra dagens
/// overskudd», «Sikret»), the price card (+N poeng, the value bar), the
/// three tiles (pickup, distance, put out), and what the store writes about
/// the bag. «Se butikken» opens the store; «Sikre en · 99 kr» puts the bag in
/// the cart and flies it there (`upTilKurv`).
Future<void> visPoseArk(BuildContext context, UtfPose p, {PointsRules? rules, VoidCallback? onSikret}) {
  final hero = GlobalKey();
  final skjult = ValueNotifier<bool>(false);
  var pose = p;
  var opptatt = false;
  // Debug: `poseSikre` presses «Sikre en» once the sheet is up.
  if (kDebugMode && HjemHarness.poseSikre && !p.sikret) {
    HjemHarness.poseSikre = false;
    Future<void>.delayed(const Duration(milliseconds: 1600), () {
      final ctx = hero.currentContext;
      if (ctx == null || !ctx.mounted) return;
      _sikreOgFly(ctx, pose, hero, skjult, rules).then((ok) {
        if (ok) onSikret?.call();
      });
    });
  }
  return showMegArk<void>(
    context,
    mork: true,
    title: p.navn,
    subtitle: p.kat == null ? UtforskCopy.a1_pose_tittel_under(null) : UtforskCopy.a1_pose_tittel_under(p.kat!.toLowerCase()),
    body: (ctx, setState) => _PoseArkKropp(pose: pose, rules: rules, heroKey: hero, skjult: skjult),
    secondary: MegArkButton(
      key: const Key('a1_pose_se_butikken'),
      label: UtforskCopy.a1_pose_se_butikken,
      onTap: () {
        final nav = Navigator.of(context);
        nav.maybePop();
        // `bpApne(p.butikk)`: the store's profile in Ærend Feed.
        BergenRoutes.push<dynamic>(nav.context, '/bergen/butikkprofil/${p.storeId}');
      },
    ),
    primaryBuilder: (ctx) => pose.sikret
        ? MegArkButton(key: const Key('a1_pose_sikret_kn'), label: UtforskCopy.a1_pose_sikret_cta(pose.hent ?? ''), av: true, onTap: () {})
        : MegArkButton(
            key: const Key('a1_pose_sikre_kn'),
            label: UtforskCopy.a1_pose_sikre_cta(pose.prisKr),
            onTap: () async {
              if (opptatt) return;
              opptatt = true;
              final ok = await _sikreOgFly(ctx, pose, hero, skjult, rules);
              opptatt = false;
              if (ok) {
                pose = pose.medSikret(true);
                onSikret?.call();
              }
            },
          ),
  );
}

// ── The sheet's body ─────────────────────────────────────────────────────────

class _PoseArkKropp extends StatelessWidget {
  const _PoseArkKropp({required this.pose, required this.rules, required this.heroKey, required this.skjult});

  final UtfPose pose;
  final PointsRules? rules;
  final GlobalKey heroKey;
  final ValueNotifier<bool> skjult;

  @override
  Widget build(BuildContext context) {
    // Debug: `poseArkRull` shows the end of the sheet (the store's text).
    if (kDebugMode && HjemHarness.poseArkRull) {
      HjemHarness.poseArkRull = false;
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (!context.mounted) return;
        final pos = Scrollable.maybeOf(context)?.position;
        pos?.jumpTo(pos.maxScrollExtent);
      });
    }
    final p = pose;
    final poeng = rules?.pointsForOre(p.priceOre);
    final tiles = <Widget>[
      if (p.hent != null) _Flis(key: const Key('a1_pose_flis_hent'), ikon: _ikKlokke, verdi: p.hent!, under: UtforskCopy.a1_pose_hentes_idag, delayMs: 100),
      if (p.avstand != null) _Flis(key: const Key('a1_pose_flis_avstand'), ikon: _ikNaal, verdi: p.avstand!, under: p.gate ?? '', delayMs: 140),
      if (p.utlagt != null) _Flis(key: const Key('a1_pose_flis_utlagt'), ikon: _ikPose, verdi: p.utlagt!, under: UtforskCopy.a1_pose_lagt_ut_idag, delayMs: 180),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: skjult,
          builder: (context, s, child) => Visibility(visible: !s, maintainSize: true, maintainAnimation: true, maintainState: true, child: child!),
          child: _Inn(delayMs: 0, child: KeyedSubtree(key: heroKey, child: PoseHero(pose: p))),
        ),
        const SizedBox(height: 8),
        _Inn(delayMs: 60, child: _PrisKort(pose: p, poeng: poeng == null || poeng <= 0 ? null : poeng)),
        if (tiles.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: i < tiles.length ? tiles[i] : const SizedBox.shrink()),
              ],
            ],
          ),
        ],
        if (p.innhold != null) ...[
          const SizedBox(height: 8),
          // «1 · Butikken skriver om posen» (8px 4px 0).
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF5CE0B8), boxShadow: [BoxShadow(color: Color(0xFF5CE0B8), blurRadius: 4)]),
                ),
                const SizedBox(width: 7),
                Flexible(child: Text(UtforskCopy.a1_pose_skriver, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(11, weight: FontWeight.w800, em: .06, color: const Color(0xFF7FF0CB)))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _Inn(delayMs: 140, child: _Sitat(pose: p)),
        ],
      ],
    );
  }
}

/// `spOpp .35s <delay> ease-out both`.
class _Inn extends StatelessWidget {
  const _Inn({required this.delayMs, required this.child});

  final double delayMs;
  final Widget child;

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: 350 + delayMs,
    child: child,
    builder: (context, t, child) {
      final p = cssEaseOut.transform(((t - delayMs) / 350).clamp(0.0, 1.0));
      return Opacity(opacity: p, child: Transform.translate(offset: Offset(0, 12 * (1 - p)), child: child));
    },
  );
}

/// The glass card of the dark Ark (`rgba(255,255,255,.14 → .05)`, a .16
/// ring, the top light, the deep drop), 20 px corners.
class _Glass extends StatelessWidget {
  const _Glass({required this.child, this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 13), this.radius = 20});

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) => CssBox(
    radius: BorderRadius.circular(radius),
    clip: true,
    padding: padding,
    bg: const [CssLinear(180, [Color.fromRGBO(255, 255, 255, .14), Color.fromRGBO(255, 255, 255, .05)])],
    shadows: const [
      CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .16)),
      CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .22)),
      CssShadow(0, 12, 20, -14, Color.fromRGBO(0, 10, 16, .85)),
    ],
    child: child,
  );
}

/// The sheet's photo (184 px, `data-uphero`): Ken Burns (9 s alternate),
/// the holo shine, the shade top and bottom, the slots left, the gold
/// «−60 %», «Overraskelse fra dagens overskudd» and «Sikret».
class PoseHero extends StatelessWidget {
  const PoseHero({super.key, required this.pose, this.chips = true});

  final UtfPose pose;

  /// The flying copy leaves the chips behind (they fade as it lifts).
  final bool chips;

  @override
  Widget build(BuildContext context) {
    final p = pose;
    final igjen = p.igjenN;
    final kap = p.kap;
    final lav = igjen != null && igjen <= 1;
    final r = p.rabatt;
    return CssBox(
      height: 184,
      radius: BorderRadius.circular(24),
      clip: true,
      bg: const [CssLinear(165, [Color(0xFFF6F0E6), Color(0xFFDCCDB4)])],
      shadows: const [
        CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .5)),
        CssShadow(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .12)),
        CssShadow(0, 18, 28, -16, Color.fromRGBO(0, 10, 16, .9)),
      ],
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (p.bildeUrl != null)
            BergenKenBurns(
              seconds: 18,
              reverse: false,
              product: true,
              child: Image.network(p.bildeUrl!, fit: BoxFit.cover, cacheWidth: 1080, errorBuilder: (_, _, _) => const SizedBox.shrink()),
            ),
          const IgnorePointer(
            child: BergenHolo(
              dodge: true,
              colors: [
                Color.fromRGBO(255, 255, 255, 0),
                Color.fromRGBO(255, 120, 80, .6),
                Color.fromRGBO(255, 214, 120, .6),
                Color.fromRGBO(255, 150, 190, .55),
                Color.fromRGBO(210, 150, 255, .45),
                Color.fromRGBO(255, 255, 255, 0),
              ],
              stops: [.22, .36, .45, .54, .63, .76],
            ),
          ),
          const Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: 54,
              width: double.infinity,
              child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.fromRGBO(6, 22, 30, .42), Color.fromRGBO(6, 22, 30, 0)]))),
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: 64,
              width: double.infinity,
              child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color.fromRGBO(6, 22, 30, .55), Color.fromRGBO(6, 22, 30, 0)]))),
            ),
          ),
          if (chips && igjen != null)
            Positioned(
              top: 11,
              left: 11,
              child: _BlurChip(
                key: const Key('a1_pose_ark_igjen'),
                padding: const EdgeInsets.fromLTRB(9, 5, 10, 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (kap != null && kap > 0) ...[
                      for (var k = 0; k < kap; k++) ...[
                        if (k > 0) const SizedBox(width: 2),
                        Opacity(
                          opacity: k < igjen ? 1 : .32,
                          child: SvgPicture.string(
                            _slot(k < igjen ? (lav ? 'FF9466' : '7FF0CB') : 'FFFFFF'),
                            width: 11,
                            height: 12,
                          ),
                        ),
                      ],
                      const SizedBox(width: 7),
                    ],
                    Flexible(child: Text(UtforskCopy.a1_utforsk_pose_left(igjen), maxLines: 1, overflow: TextOverflow.clip, softWrap: false, style: inter(11, weight: FontWeight.w800).copyWith(fontFeatures: const [ui.FontFeature.tabularFigures()]))),
                  ],
                ),
              ),
            ),
          if (chips && r != null)
            Positioned(
              top: 10,
              right: 11,
              child: Transform.rotate(
                angle: -5 * math.pi / 180,
                child: CssBox(
                  radius: BorderRadius.circular(8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  bg: const [CssLinear(180, [Color(0xFFFFE7A8), Color(0xFFE9AC3C)])],
                  shadows: const [
                    CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .7)),
                    CssShadow(0, 2, 0, 0, Color(0xFFA87418)),
                    CssShadow(0, 6, 8, -4, Color.fromRGBO(3, 16, 24, .6)),
                  ],
                  child: Text(UtforskCopy.a1_pose_rabatt(r), style: jakarta(13, color: const Color(0xFF4A300A)).copyWith(fontFeatures: const [ui.FontFeature.tabularFigures()])),
                ),
              ),
            ),
          if (chips)
            Positioned(
              left: 11,
              bottom: 11,
              child: _BlurChip(
                padding: const EdgeInsets.fromLTRB(9, 5, 11, 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.string(
                      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#FFDD86" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3l2.6 5.6 6 .7-4.5 4.1 1.2 6L12 16.4 6.7 19.4l1.2-6L3.4 9.3l6-.7z"/></svg>',
                      width: 12,
                      height: 12,
                    ),
                    const SizedBox(width: 6),
                    Text(UtforskCopy.a1_pose_overraskelse, style: inter(11, weight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
          if (chips && p.sikret) const Positioned(right: 11, bottom: 11, child: PoseSikretChip()),
        ],
      ),
    );
  }

  static String _slot(String c) =>
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 26"><path d="M4 9h16l-1.2 14H5.2z" fill="#$c"/><path d="M8.5 9V7a3.5 3.5 0 0 1 7 0v2" fill="none" stroke="#$c" stroke-width="2.4" stroke-linecap="round"/></svg>';
}

/// A chip on the photo: `rgba(6,22,30,.58)` behind a 10 px blur (one
/// layer, `full` only — `lite` / `still` keep the flat tint).
class _BlurChip extends StatelessWidget {
  const _BlurChip({super.key, required this.child, required this.padding});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(999),
    child: BackdropFilter(
      enabled: BergenPerf.blurOn(context, secondary: true),
      filter: BergenPerf.blur(context, 10),
      child: CssBox(
        radius: BorderRadius.circular(999),
        padding: padding,
        bg: const [CssSolid(Color.fromRGBO(6, 22, 30, .58))],
        shadows: const [CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .18))],
        child: child,
      ),
    ),
  );
}

/// The price card: 32 px price, the value struck, the gold «+N poeng», the
/// striped value bar (the price's share fills in, `upFyll .9s .3s`; a shine
/// runs over it, `upGlans 2.6s 1.2s`) and «Du betaler / Du sparer minst».
class _PrisKort extends StatelessWidget {
  const _PrisKort({required this.pose, required this.poeng});

  final UtfPose pose;
  final int? poeng;

  @override
  Widget build(BuildContext context) {
    final p = pose;
    const tab = [ui.FontFeature.tabularFigures()];
    final harVerdi = p.verdiKr > p.prisKr;
    return _Glass(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The gold glow top-right (140 × 110 at right -30, top -40).
          const Positioned(
            right: -46,
            top: -54,
            width: 140,
            height: 110,
            child: CssBox(bg: [CssRadial.closestSide([Color.fromRGBO(242, 193, 78, .2), Color.fromRGBO(242, 193, 78, 0)])]),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.end,
                      spacing: 9,
                      children: [
                        Text(UtforskCopy.a1_utforsk_pose_price(p.prisKr), style: jakarta(32, em: -.035, height: 1).copyWith(fontFeatures: tab)),
                        if (harVerdi)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              UtforskCopy.a1_utforsk_pose_price(p.verdiKr),
                              style: inter(13, weight: FontWeight.w800, color: const Color.fromRGBO(255, 255, 255, .55)).copyWith(decoration: TextDecoration.lineThrough, decorationColor: const Color.fromRGBO(255, 255, 255, .55), fontFeatures: tab),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (poeng != null) ...[
                    const SizedBox(width: 10),
                    CssBox(
                      key: const Key('a1_pose_poeng'),
                      height: 30,
                      radius: BorderRadius.circular(999),
                      padding: const EdgeInsets.fromLTRB(8, 0, 11, 0),
                      bg: const [CssLinear(180, [Color.fromRGBO(255, 221, 134, .24), Color.fromRGBO(233, 172, 60, .12)])],
                      shadows: const [
                        CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(246, 210, 122, .55)),
                        CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .2)),
                        CssShadow(0, 0, 14, 0, Color.fromRGBO(242, 193, 78, .25)),
                      ],
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.string(
                            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#FFDD86"><path d="M12 2.8l2.8 6 6.5.7-4.9 4.4 1.4 6.4L12 17l-5.8 3.3 1.4-6.4-4.9-4.4 6.5-.7z"/></svg>',
                            width: 14,
                            height: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(UtforskCopy.a1_pose_poeng(poeng!), style: inter(12, weight: FontWeight.w800, color: const Color(0xFFFFDD86)).copyWith(fontFeatures: tab)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              if (harVerdi) ...[
                const SizedBox(height: 13),
                _VerdiStolpe(andel: p.prisKr / p.verdiKr),
                const SizedBox(height: 8),
                // justify-content: space-between; white-space: nowrap.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const _Prikk(Color(0xFFF26D3D)),
                            const SizedBox(width: 6),
                            Text(UtforskCopy.a1_pose_du_betaler(p.prisKr), softWrap: false, style: inter(11.5, weight: FontWeight.w800, color: const Color(0xFFFFB48E)).copyWith(fontFeatures: tab)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const _Prikk(Color(0xFF5CE0B8)),
                            const SizedBox(width: 6),
                            Text(UtforskCopy.a1_pose_du_sparer(p.spar), softWrap: false, style: inter(11.5, weight: FontWeight.w800, color: const Color(0xFF7FF0CB)).copyWith(fontFeatures: tab)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Prikk extends StatelessWidget {
  const _Prikk(this.c);
  final Color c;

  @override
  Widget build(BuildContext context) => Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: c));
}

/// The value bar (14 px): mint stripes (`repeating-linear-gradient(-45deg,
/// .34 0 6px, .16 6px 12px)`), the shine (`upGlans`, loops, `full` only)
/// and the orange price share filling in once (`upFyll`).
class _VerdiStolpe extends StatelessWidget {
  const _VerdiStolpe({required this.andel});

  final double andel;

  @override
  Widget build(BuildContext context) => CssBox(
    height: 14,
    radius: BorderRadius.circular(999),
    clip: true,
    shadows: const [
      CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(92, 224, 184, .45)),
      CssShadow(0, 0, 12, 0, Color.fromRGBO(92, 224, 184, .18)),
    ],
    child: LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        return Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: _Striper())),
            // upGlans 2.6s 1.2s: translateX 0 → 360 % by 60 %, then rests.
            Positioned(
              top: 0,
              bottom: 0,
              left: -.4 * w,
              width: .4 * w,
              child: LfLoop(
                builder: (context, t, child) {
                  final p = kfLoop(t, 1200, 2600);
                  final x = p == null ? 0.0 : kf(p, const [0, .6, 1], const [0, 3.6, 3.6], cssEaseInOut);
                  return Transform.translate(offset: Offset(x * .4 * w, 0), child: child);
                },
                child: const DecoratedBox(
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [Color.fromRGBO(255, 255, 255, 0), Color.fromRGBO(255, 255, 255, .35), Color.fromRGBO(255, 255, 255, 0)])),
                ),
              ),
            ),
            // upFyll .9s .3s cubic-bezier(.3,1.2,.5,1), origin left.
            LfOnce(
              ms: 1200,
              builder: (context, t, _) {
                final p = const Cubic(.3, 1.2, .5, 1).transform(((t - 300) / 900).clamp(0.0, 1.0));
                return Container(
                  width: w * andel.clamp(0.0, 1.0) * p.clamp(0.0, 1.2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF9A273), Color(0xFFE95C2C)]),
                    boxShadow: const [BoxShadow(color: Color.fromRGBO(242, 109, 61, .6), blurRadius: 5)],
                  ),
                );
              },
            ),
          ],
        );
      },
    ),
  );
}

class _Striper extends CustomPainter {
  const _Striper();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color.fromRGBO(92, 224, 184, .16));
    final p = Paint()..color = const Color.fromRGBO(92, 224, 184, .34);
    // −45°: bands 6 px wide every 12 px along the gradient line.
    const step = 12 * 1.41421356, band = 6 * 1.41421356;
    for (var x = -size.height; x < size.width + size.height; x += step) {
      final path = Path()
        ..moveTo(x, size.height)
        ..lineTo(x + band, size.height)
        ..lineTo(x + band + size.height, 0)
        ..lineTo(x + size.height, 0)
        ..close();
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant _Striper old) => false;
}

const String _ikKlokke = '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>';
const String _ikNaal = '<path d="M12 21s-6.5-6-6.5-11a6.5 6.5 0 0 1 13 0c0 5-6.5 11-6.5 11z"/><circle cx="12" cy="10" r="2.4"/>';
const String _ikPose = '<path d="M6 8h12l-1.2 12H7.2z"/><path d="M9.5 8V6.5a2.5 2.5 0 0 1 5 0V8"/>';

/// One of the three tiles: the 30 px glass icon, the 15 px value, the label.
class _Flis extends StatelessWidget {
  const _Flis({super.key, required this.ikon, required this.verdi, required this.under, required this.delayMs});

  final String ikon;
  final String verdi;
  final String under;
  final double delayMs;

  @override
  Widget build(BuildContext context) => _Inn(
    delayMs: delayMs,
    child: _Glass(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(10, 11, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CssBox(
            width: 30,
            height: 30,
            radius: BorderRadius.circular(10),
            bg: const [CssLinear(180, [Color.fromRGBO(255, 255, 255, .18), Color.fromRGBO(255, 255, 255, .06)])],
            shadows: const [CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .18))],
            child: Center(
              child: SvgPicture.string(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#9FF0D4" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">$ikon</svg>',
                width: 15,
                height: 15,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(verdi, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, style: jakarta(15, em: -.02, height: 1.1).copyWith(fontFeatures: const [ui.FontFeature.tabularFigures()])),
          const SizedBox(height: 3),
          Text(under, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, style: inter(10.5, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .64))),
        ],
      ),
    ),
  );
}

/// What the store writes about the bag: the big « (mint .12), the text, a
/// line, the store's logo, its name and «Lagt ut i dag 15:40».
class _Sitat extends StatelessWidget {
  const _Sitat({required this.pose});

  final UtfPose pose;

  @override
  Widget build(BuildContext context) {
    final p = pose;
    return _Glass(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: -6, top: -28, child: Text('«', style: jakarta(84, height: 1, color: const Color.fromRGBO(127, 240, 203, .12)))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(p.innhold ?? '', key: const Key('a1_pose_innhold'), style: inter(14.5, weight: FontWeight.w700, height: 1.5)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.only(top: 11),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color.fromRGBO(255, 255, 255, .1)))),
                child: Row(
                  children: [
                    _Merke(navn: p.navn, logoUrl: p.logoUrl),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.navn, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(12, weight: FontWeight.w800)),
                          if (p.utlagt != null) ...[
                            const SizedBox(height: 1),
                            Text(
                              UtforskCopy.a1_pose_lagt_ut_kl(p.utlagt!),
                              style: inter(10.5, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .6)).copyWith(fontFeatures: const [ui.FontFeature.tabularFigures()]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The store's mark (28 px): its real logo, or its initials on teal.
class _Merke extends StatelessWidget {
  const _Merke({required this.navn, required this.logoUrl});

  final String navn;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    final init = navn.split(RegExp(r'\s+')).where((w) => w.isNotEmpty && RegExp(r'[A-Za-zÆØÅæøå]').hasMatch(w[0])).take(2).map((w) => w[0].toUpperCase()).join();
    return CssBox(
      width: 28,
      height: 28,
      radius: BorderRadius.circular(14),
      clip: true,
      bg: const [CssLinear(160, [Color(0xFF3F8798), Color(0xFF1A4654)])],
      shadows: const [
        CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .4)),
        CssShadow(0, 0, 0, 1.5, Color.fromRGBO(255, 255, 255, .2)),
      ],
      child: logoUrl != null
          ? Image.network(logoUrl!, fit: BoxFit.cover, cacheWidth: 96, errorBuilder: (_, _, _) => Center(child: Text(init, style: jakarta(11))))
          : Center(child: Text(init, style: jakarta(11))),
    );
  }
}

// ── «Sikre en»: the bag flies into the cart (`upTilKurv`) ───────────────────

/// Puts the bag in the cart, then: the photo lifts out of the sheet, the
/// sheet slides away, the photo flies to the middle, the shell turns to Kurv
/// and the photo lands on the bag's row — a mint ring, ten sparks and «+N
/// poeng» where it lands, and the row and its picture greet it. With
/// «Roligere bevegelse» / the `still` tier: straight to Kurv.
Future<bool> _sikreOgFly(BuildContext ark, UtfPose p, GlobalKey hero, ValueNotifier<bool> skjult, PointsRules? rules) async {
  final ok = await sikrePose(ark, p, toast: false);
  if (!ok || !ark.mounted) return false;
  final nav = Navigator.of(ark);
  final shell = HomeMainV1State.current;
  final toast = UtforskCopy.a1_pose_sikret_toast(p.hent ?? '');
  final rolig = BergenPerf.of(ark) == BergenTier.still;
  final box = hero.currentContext?.findRenderObject() as RenderBox?;
  final overlay = Overlay.maybeOf(ark, rootOverlay: true);
  void tilKurv() => shell?.switchToTab(BergenTab.cart.index);
  if (rolig || box == null || !box.hasSize || overlay == null) {
    nav.maybePop();
    tilKurv();
    if (overlay != null && overlay.mounted) showBergenToast(overlay.context, toast);
    return true;
  }
  final r0 = box.localToGlobal(Offset.zero) & Size(box.size.width * _skala(box), box.size.height * _skala(box));
  final screen = MediaQueryData.fromView(View.of(ark)).size;
  final poeng = rules?.pointsForOre(p.priceOre) ?? 0;
  final ferdig = Completer<void>();
  late OverlayEntry lag;
  lag = OverlayEntry(
    builder: (_) => _FlyLag(
      pose: p,
      fra: r0,
      skjerm: screen,
      poeng: poeng,
      onLoftet: () => skjult.value = true,
      onArkUt: () => nav.maybePop(),
      onKurv: tilKurv,
      onFerdig: () {
        lag.remove();
        if (overlay.mounted) showBergenToast(overlay.context, toast);
        ferdig.complete();
      },
    ),
  );
  overlay.insert(lag);
  return true;
}

/// The sheet lays out in the 390-px frame and is scaled to the device
/// (`MegArkSkala`): the photo's size on screen is its layout size times that.
double _skala(RenderBox box) {
  final m = box.getTransformTo(null);
  return m.getMaxScaleOnAxis();
}

class _FlyLag extends StatefulWidget {
  const _FlyLag({
    required this.pose,
    required this.fra,
    required this.skjerm,
    required this.poeng,
    required this.onLoftet,
    required this.onArkUt,
    required this.onKurv,
    required this.onFerdig,
  });

  final UtfPose pose;
  final Rect fra;
  final Size skjerm;
  final int poeng;
  final VoidCallback onLoftet;
  final VoidCallback onArkUt;
  final VoidCallback onKurv;
  final VoidCallback onFerdig;

  @override
  State<_FlyLag> createState() => _FlyLagState();
}

class _FlyLagState extends State<_FlyLag> with TickerProviderStateMixin {
  late final AnimationController _fly1 = AnimationController(vsync: this, duration: const Duration(milliseconds: 640));
  late final AnimationController _fly2 = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  late final AnimationController _gnist = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  Rect? _mal;
  final _rnd = math.Random();
  late final List<double> _dd = List.generate(10, (_) => 26 + _rnd.nextDouble() * 16);

  double get _s => widget.skjerm.width / 390;

  Rect get _midt {
    final w = 92 * _s;
    return Rect.fromLTWH(widget.skjerm.width / 2 - w / 2, widget.skjerm.height * .3, w, w);
  }

  @override
  void initState() {
    super.initState();
    // The copy is on screen from the first frame; the sheet's photo hides then.
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onLoftet());
    // The sheet slides down from 90 ms; the shell turns to Kurv at 470 ms.
    Timer(const Duration(milliseconds: 90), widget.onArkUt);
    Timer(const Duration(milliseconds: 470), widget.onKurv);
    _fly1.forward().whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((_) => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _mal = _finnRad());
        _fly2.forward().whenComplete(() {
          if (!mounted) return;
          KurvLinje.landet.value = widget.pose.id;
          _gnist.forward().whenComplete(widget.onFerdig);
        });
      }));
    });
  }

  /// The bag's row picture in Kurv (`KurvLinje` for this product), or a
  /// spot under the middle when the row is not on screen yet.
  Rect _finnRad() {
    Rect? hit;
    void visit(Element e) {
      if (hit != null) return;
      final w = e.widget;
      if (w is KeyedSubtree && w.key == ValueKey('kurv_flis_${widget.pose.id}')) {
        final ro = e.findRenderObject();
        if (ro is RenderBox && ro.hasSize && ro.attached) {
          final r = ro.localToGlobal(Offset.zero) & ro.size;
          if (r.top >= 0 && r.top < widget.skjerm.height) hit = r;
        }
        return;
      }
      e.visitChildren(visit);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(visit);
    return hit ?? Rect.fromLTWH(widget.skjerm.width / 2 - 24 * _s, 150 * _s, 48 * _s, 48 * _s);
  }

  @override
  void dispose() {
    _fly1.dispose();
    _fly2.dispose();
    _gnist.dispose();
    super.dispose();
  }

  /// Linear between keyframes, the easing over the whole (Web Animations).
  static double _seg(double p, List<double> at, List<double> v) => kf(p, at, v, const Cubic(0, 0, 1, 1));

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: Listenable.merge([_fly1, _fly2, _gnist]),
      builder: (context, _) {
        final s = _s;
        final a = widget.fra, m = _midt;
        Rect r;
        double rad, rot, op = 1;
        if (_fly2.value == 0) {
          final p = const Cubic(.55, .05, .3, 1).transform(_fly1.value);
          const at = [0.0, .22, 1.0];
          r = Rect.fromLTWH(
            _seg(p, at, [a.left, a.left - 6 * s, m.left]),
            _seg(p, at, [a.top, a.top - 14 * s, m.top]),
            _seg(p, at, [a.width, a.width + 12 * s, m.width]),
            _seg(p, at, [a.height, a.height + 12 * s, m.height]),
          );
          rad = _seg(p, at, [24, 26, 28]) * s;
          rot = _seg(p, at, [0, -1.5, 6]);
        } else {
          final t = _mal!;
          final p = const Cubic(.4, 0, .2, 1).transform(_fly2.value);
          const at = [0.0, .72, 1.0];
          r = Rect.fromLTWH(
            _seg(p, at, [m.left, t.left - 6 * s, t.left]),
            _seg(p, at, [m.top, t.top - 6 * s, t.top]),
            _seg(p, at, [m.width, t.width + 12 * s, t.width]),
            _seg(p, at, [m.height, t.height + 12 * s, t.height]),
          );
          rad = _seg(p, at, [28, 18, 16]) * s;
          rot = _seg(p, at, [6, -4, 0]);
          op = _seg(p, at, [1, 1, 0]);
        }
        final kids = <Widget>[];
        if (_gnist.value == 0) {
          kids.add(
            Positioned.fromRect(
              rect: r,
              child: Opacity(
                opacity: op.clamp(0.0, 1.0),
                child: Transform.rotate(
                  angle: rot * math.pi / 180,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(rad),
                      boxShadow: [
                        const BoxShadow(color: Color.fromRGBO(255, 255, 255, .2), spreadRadius: 1),
                        BoxShadow(color: const Color.fromRGBO(0, 10, 16, .85), offset: Offset(0, 24 * s), blurRadius: 20 * s, spreadRadius: -14 * s),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(rad),
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(width: a.width / s, height: a.height / s, child: PoseHero(pose: widget.pose, chips: false)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        } else {
          kids.addAll(_landing(_mal!.center));
        }
        return Stack(children: kids);
      },
    ),
  );

  /// Where the bag lands: the mint ring (620 ms), ten sparks (720 ms) and
  /// «+N poeng» rising (1.5 s).
  List<Widget> _landing(Offset c) {
    final t = _gnist.value * 1500;
    final out = <Widget>[];
    final pr = (t / 620).clamp(0.0, 1.0);
    if (pr < 1) {
      final e = const Cubic(.2, .7, .3, 1).transform(pr);
      final sc = .4 + 1.1 * e;
      out.add(Positioned(
        left: c.dx - 30,
        top: c.dy - 30,
        width: 60,
        height: 60,
        child: Opacity(
          opacity: (.9 * (1 - e)).clamp(0.0, 1.0),
          child: Transform.scale(
            scale: sc,
            child: const DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.fromBorderSide(BorderSide(color: Color(0xFF7FF0CB), width: 2.5)))),
          ),
        ),
      ));
    }
    final ps = (t / 720).clamp(0.0, 1.0);
    if (ps < 1) {
      final n = BergenPerf.count(context, 10);
      final e = const Cubic(.2, .7, .3, 1).transform(ps);
      const farger = [Color(0xFF7FF0CB), Color(0xFFFFDD86), Color(0xFFF9A273)];
      for (var j = 0; j < n; j++) {
        final a = j / 10 * math.pi * 2, dd = _dd[j];
        final x = _seg(e, const [0, .55, 1], [0, math.cos(a) * dd, math.cos(a) * dd * 1.25]);
        final y = _seg(e, const [0, .55, 1], [0, math.sin(a) * dd, math.sin(a) * dd + 16]);
        final sc = _seg(e, const [0, .55, 1], [.4, 1, .2]);
        final rt = _seg(e, const [0, .55, 1], [0, 90, 180]);
        final o = _seg(e, const [0, .55, 1], [1, 1, 0]);
        out.add(Positioned(
          left: c.dx - 3 + x,
          top: c.dy - 3 + y,
          width: 6,
          height: 6,
          child: Opacity(
            opacity: o.clamp(0.0, 1.0),
            child: Transform.rotate(
              angle: rt * math.pi / 180,
              child: Transform.scale(
                scale: sc,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: farger[j % 3],
                    shape: j.isOdd ? BoxShape.circle : BoxShape.rectangle,
                    borderRadius: j.isOdd ? null : BorderRadius.circular(1.5),
                  ),
                ),
              ),
            ),
          ),
        ));
      }
    }
    if (widget.poeng > 0) {
      final pb = (t / 1500).clamp(0.0, 1.0);
      final e = const Cubic(.2, .7, .3, 1).transform(pb);
      const at = [0.0, .25, .7, 1.0];
      final y = _seg(e, at, [8, -4, -6, -26]);
      final sc = _seg(e, at, [.5, 1.08, 1, 1]);
      final o = _seg(e, at, [0, 1, 1, 0]);
      out.add(Positioned(
        left: c.dx + 14,
        top: c.dy - 30,
        child: Opacity(
          opacity: o.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, y),
            child: Transform.scale(
              scale: sc,
              child: CssBox(
                radius: BorderRadius.circular(999),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                bg: const [CssLinear(180, [Color(0xFFFFE7A8), Color(0xFFE9AC3C)])],
                shadows: const [CssShadow(0, 6, 12, -4, Color.fromRGBO(168, 116, 24, .8))],
                child: Text(UtforskCopy.a1_pose_pluss_poeng(widget.poeng), style: jakarta(11, color: const Color(0xFF4A300A))),
              ),
            ),
          ),
        ),
      ));
    }
    return out;
  }
}
