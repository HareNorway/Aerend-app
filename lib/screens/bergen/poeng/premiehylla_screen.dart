import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;

import '../../../data/points/points_app_repo.dart';
import '../../../data/points/points_models.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/home/bergen/bergen_kit.dart' show bergenSvg;
import '../aegil/aegil_bits.dart';
import '../kit/bergen_kit.dart';
import '../meg/a3_services.dart';
import '../meg/meg_ark.dart';
import '../meg/meg_copy_a4.dart';
import '../meg/meg_nav.dart';
import '../meg/meg_nivaa_card.dart' show MegMedal, medalFor;
import '../meg/meg_sheets.dart';
import 'aegil_velger_screen.dart';
import 'prize_art.dart';

/// Premiehylla (`erPremier`, L7556–7707 in `Ærend Kunde Launch.dc.html`,
/// design px): the floating back key and the points pill (the coin turning,
/// `phMynt`), and the rounded teal sheet — the title, the Nivå + «Målet
/// ditt» glass card (the medal with its spinning dashed ring, the goal ring
/// and the striped bar with its spark), «Mine premier» as holo tickets, «Åpent
/// på {nivå}» with the prize grid (each prize floating over its shadow,
/// sunburst and sparks when it can be taken, the coin, «Hent» / «Sett som mål»
/// and the target key), «Låst til {neste}», and the 60-day note.
/// Data: `points/me`, `points/prizes`, `points/claims`.
class PremiehyllaScreen extends StatefulWidget {
  const PremiehyllaScreen({super.key, this.api});

  final PointsAppApi? api;

  @override
  State<PremiehyllaScreen> createState() => _PremiehyllaScreenState();
}

class _PremiehyllaScreenState extends State<PremiehyllaScreen> {
  late final PointsAppApi _api = widget.api ?? A3Services.points();
  PointsBalance? _balance;
  Premiehylla? _shelf;
  List<PrizeClaim> _claims = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await Future.wait<Object?>([a3Try(_api.balance), a3Try(_api.shelf), a3Try(_api.claims)]);
    if (!mounted) return;
    setState(() {
      _balance = r[0] as PointsBalance?;
      _shelf = r[1] as Premiehylla?;
      _claims = (r[2] as List<PrizeClaim>?) ?? const [];
      _loading = false;
    });
  }

  int get _points => _balance?.available ?? 0;

  Future<void> _setGoal(Prize p) async {
    if (_shelf?.goal?.prizeId == p.id) {
      showBergenToast(context, A4MegCopy.a4_hylla_er_maal);
      return;
    }
    final g = await _api.setGoal(prizeId: p.id);
    if (!mounted) return;
    if (g != null) {
      showBergenToast(context, A4MegCopy.a4_hylla_satt_maal(p.pointPrice - _points), icon: Icons.flag_rounded);
      _load();
    }
  }

  Future<void> _hent(Prize p) async {
    if (!p.inStock) {
      showBergenToast(context, A4MegCopy.a4_hylla_utsolgt_toast(p.name));
      return;
    }
    if (!p.affordable) {
      await _setGoal(p);
      return;
    }
    final claimed = await _krevArk(p);
    if (claimed == true && mounted) _load();
  }

  /// `krev`: what happens, how long it lasts, points after — and the boat asks
  /// for its name first (identity prize).
  Future<bool?> _krevArk(Prize p) {
    final after = (_points - p.pointPrice).clamp(0, 1 << 30);
    final identity = p.type == 'identity';
    final name = TextEditingController();
    var busy = false;
    String? error;
    StateSetter? sheetSet;

    return showMegArk<bool>(
      context,
      key: const Key('hylla-krev-sheet'),
      title: p.name,
      subtitle: identity ? A4MegCopy.a4_hylla_baat_linje : '${A4MegCopy.nf(p.pointPrice)} poeng${p.partnerName == null ? '' : ' · ${p.partnerName}'}',
      body: (ctx, setState) {
        sheetSet = setState;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (identity)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  key: const Key('hylla-baat-navn'),
                  controller: name,
                  maxLength: 20,
                  onChanged: (_) => setState(() {}),
                  style: BergenTokens.text(15, weight: FontWeight.w800, color: MegArkInk.ink),
                  decoration: InputDecoration(
                    hintText: A4MegCopy.a4_hylla_baat_hint,
                    counterText: '${name.text.length} av 20 tegn',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: .7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: .9), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: .9), width: 1.5),
                    ),
                  ),
                ),
              ),
            MegArkRow(title: A4MegCopy.a4_hylla_dette_skjer, sub: identity ? A4MegCopy.a4_hylla_baat_skjer : _hvordan(p.type)),
            MegArkRow(title: A4MegCopy.a4_hylla_gyldighet, sub: identity ? A4MegCopy.a4_hylla_baat_gyldig : A4MegCopy.a4_hylla_60_dager),
            MegArkRow(title: A4MegCopy.a4_hylla_poeng_etter, sub: '${A4MegCopy.nf(after)} poeng'),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(error!, style: megInter(12, FontWeight.w700, color: const Color(0xFFB9441A))),
              ),
          ],
        );
      },
      primary: MegArkButton(
        key: const Key('hylla-krev-cta'),
        label: identity ? A4MegCopy.a4_hylla_baat_cta : A4MegCopy.a4_hylla_hent_for(p.pointPrice),
        onTap: () async {
          if (busy) return;
          if (identity && name.text.trim().isEmpty) {
            showBergenToast(context, A4MegCopy.a4_hylla_baat_navn_forst);
            return;
          }
          busy = true;
          final nav = Navigator.of(context);
          final r = await _api.claim(p.id, identityName: identity ? name.text.trim() : null);
          busy = false;
          if (r.claim != null) {
            nav.pop(true);
            if (mounted) showBergenToast(context, A4MegCopy.a4_hylla_hentet(p.name), icon: Icons.check_rounded);
          } else {
            sheetSet?.call(() => error = r.error ?? A4MegCopy.a4_hylla_feil);
          }
        },
      ),
    );
  }

  static String _hvordan(String type) {
    switch (type) {
      case 'voucher':
        return 'Brukes automatisk på neste levering';
      case 'physical':
        return 'Sendes hjem til deg';
      case 'donation':
        return 'Gis til klubben du velger';
      case 'identity':
        return 'Båten din legges i Vågen';
      default:
        return 'Kode vises her';
    }
  }

  void _openVelger() => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AegilVelgerScreen(api: _api))).then((_) => _load());

  /// A claim's ticket, opened: how it is used, the code, how long it lasts.
  void _visClaim(PrizeClaim c, Prize? p) {
    showMegArk<void>(
      context,
      title: c.prizeName ?? p?.name ?? '',
      subtitle: p?.partnerName ?? 'Ærend',
      body: (ctx, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MegArkRow(title: A4MegCopy.a4_hylla_dette_skjer, sub: _hvordan(p?.type ?? '')),
          if ((c.voucherCode ?? '').isNotEmpty) MegArkRow(title: A4MegCopy.a4_hylla_kode, sub: c.voucherCode!),
          if (c.expiresAt != null) MegArkRow(title: A4MegCopy.a4_hylla_gyldighet, sub: A4MegCopy.a4_hylla_dager_igjen(_dagerIgjen(c))),
        ],
      ),
    );
  }

  static int _dagerIgjen(PrizeClaim c) => c.expiresAt == null ? 60 : math.max(0, c.expiresAt!.difference(DateTime.now()).inHours ~/ 24);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF173E48),
      body: LfFrame(
        child: Builder(
          builder: (context) {
            final top = MediaQuery.paddingOf(context).top;
            return AeOnce(
              kind: AeInn.skjermInn,
              ms: 340,
              curve: const Cubic(.2, .9, .3, 1),
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: CssBox(
                      bg: [
                        CssRadial([Color.fromRGBO(255, 255, 255, .22), Color.fromRGBO(255, 255, 255, 0)], stops: [0, .6], rx: .8, ry: .5, cx: .14, cy: 0),
                        CssLinear(180, [Color(0xFF2A6272), Color(0xFF1E4F5C), Color(0xFF173E48)], [0, .42, 1]),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: top + 66,
                    bottom: 0,
                    child: CssBox(
                      radius: const BorderRadius.vertical(top: Radius.circular(28)),
                      clip: true,
                      bg: const [
                        CssRadial([Color.fromRGBO(255, 255, 255, .22), Color.fromRGBO(255, 255, 255, 0)], stops: [0, .6], rx: .8, ry: .5, cx: .14, cy: 0),
                        CssLinear(180, [Color(0xFF27596A), Color(0xFF1E4F5C), Color(0xFF173E48)], [0, .48, 1]),
                      ],
                      shadows: const [
                        CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .4)),
                        CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .12)),
                        CssShadow(0, -24, 50, -18, Color.fromRGBO(4, 18, 26, .8)),
                      ],
                      child: _loading ? const Center(child: CircularProgressIndicator(color: BergenTokens.mint)) : _body(),
                    ),
                  ),
                  const Positioned(left: 0, right: 0, bottom: 0, child: MegNav()),
                  Positioned(
                    left: 16,
                    right: 16,
                    top: top + 12,
                    child: Row(
                      children: [
                        HyllaTilbake(onTap: () => Navigator.of(context).maybePop()),
                        const Spacer(),
                        HyllaPoengPille(poeng: _points),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _body() {
    final b = _balance;
    final shelf = _shelf;
    final goal = shelf?.goal;
    final prizes = shelf?.prizes ?? const <Prize>[];
    final previews = shelf?.previews ?? const <PrizePreview>[];
    final locked = (shelf?.locked.isNotEmpty ?? false) ? shelf!.locked : previews;
    final klare = prizes.where((p) => p.inStock && p.affordable).length;
    final byId = {for (final p in prizes) p.id: p};
    final cheapest = prizes.where((p) => p.inStock).map((p) => p.pointPrice).fold<int?>(null, (a, v) => a == null || v < a ? v : a);
    final aktive = _claims.where((c) => c.state != 'used' && c.state != 'expired' && c.state != 'cancelled').length;

    return ListView(
      key: const Key('hylla-list'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 132),
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            // The two glows (`top:70px;right:-70px` gold, `top:520px;left:-80px` mint).
            const Positioned(right: -86, top: 54, width: 250, height: 250, child: _Glod(Color.fromRGBO(242, 193, 78, .24))),
            const Positioned(left: -96, top: 504, width: 260, height: 260, child: _Glod(Color.fromRGBO(92, 224, 184, .14))),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(A4MegCopy.a4_hylla_title, style: jakarta(27, em: -.035, height: 1.05)),
                      const SizedBox(height: 4),
                      Text(
                        A4MegCopy.a4_hylla_sub,
                        style: inter(12, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .72)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (b != null)
                  _KortInn(
                    child: _NivaaMaal(
                      balance: b,
                      goal: goal,
                      onNivaa: () => MegSheets.nivaa(context, b, opens: previews),
                    ),
                  ),
                if (_claims.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 22, 2, 10),
                    child: Row(
                      children: [
                        Text(A4MegCopy.a4_hylla_mine, style: jakarta(16, em: -.02)),
                        const SizedBox(width: 8),
                        _Mint(A4MegCopy.a4_hylla_aktive(aktive)),
                      ],
                    ),
                  ),
                  // The tickets run edge to edge (`margin: 0 -16px`) and the row
                  // is as tall as its tallest ticket.
                  OverflowBox(
                    minWidth: 390,
                    maxWidth: 390,
                    fit: OverflowBoxFit.deferToChild,
                    child: SingleChildScrollView(
                      key: const Key('hylla-mine'),
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final (i, c) in _claims.indexed) ...[
                            if (i > 0) const SizedBox(width: 10),
                            _Billett(claim: c, prize: byId[c.prizeId], dager: _dagerIgjen(c), onTap: () => _visClaim(c, byId[c.prizeId])),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                if (b != null) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 18, 2, 2),
                    child: Row(
                      children: [
                        _LitenMedalje(navn: b.tierName),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(A4MegCopy.a4_hylla_aapent(b.tierName), maxLines: 1, overflow: TextOverflow.ellipsis, style: jakarta(16, em: -.02)),
                        ),
                        const SizedBox(width: 8),
                        _KlarePille(key: const Key('hylla-klare'), tekst: A4MegCopy.a4_hylla_klare(klare)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 4, 2, 4),
                    child: Text(A4MegCopy.a4_hylla_intro_l, style: inter(11.5, height: 1.45, color: const Color.fromRGBO(255, 255, 255, .68))),
                  ),
                ],
                _Rutenett(
                  children: [
                    for (final (i, p) in prizes.indexed)
                      _PremieKort(
                        key: Key('hylla-premie-${p.id}'),
                        i: i,
                        navn: p.name,
                        merke: p.partnerName,
                        linje: p.line,
                        pris: p.pointPrice,
                        art: _Art(
                          art: PrizeArt.of(slug: p.slug, name: p.name),
                        ),
                        poeng: _points,
                        ute: !p.inStock,
                        erMaal: goal?.prizeId == p.id,
                        onHent: () => _hent(p),
                        onMaal: () => _setGoal(p),
                      ),
                    _PremieKort(
                      key: const Key('hylla-velger'),
                      i: prizes.length,
                      navn: A4MegCopy.a4_hylla_velger,
                      linje: A4MegCopy.a4_hylla_velger_linje_l,
                      pris: cheapest ?? 0,
                      art: const _VelgerArt(),
                      poeng: _points,
                      ute: cheapest == null,
                      erMaal: false,
                      velger: true,
                      onHent: _openVelger,
                      onMaal: _openVelger,
                    ),
                  ],
                ),
                if (locked.isNotEmpty && b != null) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 24, 2, 2),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color.fromRGBO(255, 255, 255, .1),
                            border: Border.all(color: const Color.fromRGBO(255, 255, 255, .2)),
                          ),
                          alignment: Alignment.center,
                          child: const AeIkon(_las, size: 11, stroke: 2.4),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(A4MegCopy.a4_hylla_laast(locked.first.tierName), style: jakarta(16, em: -.02))),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 4, 2, 10),
                    child: Text(A4MegCopy.a4_hylla_laast_sub(locked.first.tierName), style: inter(11.5, height: 1.45, color: const Color.fromRGBO(255, 255, 255, .68))),
                  ),
                  for (final (i, p) in locked.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: _KortInn(
                        delay: i * 45.0,
                        child: _Laast(
                          key: Key('hylla-laast-${p.id}'),
                          preview: p,
                          onTap: () => MegSheets.nivaa(context, b, opens: previews),
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 9),
                _Vilkaar(onTap: () => MegSheets.vilkaar(context)),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

const String _las = 'M7 11h10a2 2 0 0 1 2 2v6a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2v-6a2 2 0 0 1 2-2zM8 11V7a4 4 0 0 1 8 0v4';

/// The glass of the hylla cards (`linear-gradient(165deg,rgba(255,255,255,.19),
/// .08 40%, .04)`, a 1 px .22 border).
const List<CssBg> _glass = [
  CssLinear(165, [Color.fromRGBO(255, 255, 255, .19), Color.fromRGBO(255, 255, 255, .08), Color.fromRGBO(255, 255, 255, .04)], [0, .4, 1]),
];
const List<CssShadow> _glassSh = [
  CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .36)),
  CssShadow.inset(0, -1, 0, 0, Color.fromRGBO(255, 255, 255, .06)),
  CssShadow(0, 2, 0, 0, Color.fromRGBO(8, 30, 38, .5)),
  CssShadow(0, 20, 30, -18, Color.fromRGBO(2, 12, 18, .95)),
];

class _Glod extends StatelessWidget {
  const _Glod(this.c);
  final Color c;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [c, c.withValues(alpha: 0)], stops: const [0, .68]),
      ),
    ),
  );
}

/// `kortInn .5s cubic-bezier(.3,1.15,.5,1)` — translateY(140px) scale(.86) →
/// none.
class _KortInn extends StatelessWidget {
  const _KortInn({required this.child, this.delay = 0});
  final Widget child;
  final double delay;

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: 500 + delay,
    child: child,
    builder: (context, t, child) {
      final e = const Cubic(.3, 1.15, .5, 1).transform(kfP(t, delay, 500));
      if (e >= 1) return child!;
      return Opacity(
        opacity: e.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 140 * (1 - e)),
          child: Transform.scale(scale: .86 + .14 * e, child: child),
        ),
      );
    },
  );
}

/// The floating back key (`aeKnSvev 3.4s -2.3s`, white, the teal chevron).
class HyllaTilbake extends StatelessWidget {
  const HyllaTilbake({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    key: const Key('hylla-tilbake'),
    onTap: onTap,
    child: RepaintBoundary(
      child: LfLoop(
        builder: (context, t, _) {
          final p = ((t + 1100) / 3400) % 1.0;
          final y = kf(p, const [0, .5, 1], const [0, -5, 0], cssEaseInOut);
          final sx = kf(p, const [0, .5, 1], const [1, .82, 1], cssEaseInOut);
          final o = kf(p, const [0, .5, 1], const [1, .6, 1], cssEaseInOut);
          return SizedBox(
            width: 40,
            height: 58,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 4,
                  right: 4,
                  top: 41 + 5 * (1 - (sx - .82) / .18),
                  height: 15,
                  child: Opacity(
                    opacity: o,
                    child: Transform.scale(
                      scaleX: sx,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.elliptical(16, 7.5)),
                          gradient: RadialGradient(colors: [Color.fromRGBO(8, 26, 32, .5), Color.fromRGBO(0, 0, 0, 0)], stops: [0, .72]),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: y,
                  child: const CssBox(
                    width: 40,
                    height: 40,
                    radius: BorderRadius.all(Radius.circular(999)),
                    bg: [
                      CssLinear(180, [Colors.white, Color(0xFFE9EEED)]),
                    ],
                    shadows: [CssShadow.inset(0, -3, 6, 0, Color.fromRGBO(30, 79, 92, .14))],
                    child: Center(child: AeIkon('M15 6l-6 6 6 6', size: 15, stroke: 2.6, color: Color(0xFF1B4A57))),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

/// The points pill (`data-phpoeng`): the gold coin turning every 4 s, the
/// balance.
class HyllaPoengPille extends StatelessWidget {
  const HyllaPoengPille({super.key, required this.poeng});
  final int poeng;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(999),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
      child: CssBox(
        key: const Key('hylla-poeng'),
        radius: BorderRadius.circular(999),
        bg: const [CssSolid(Color.fromRGBO(15, 42, 51, .55))],
        shadows: const [CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .3)), CssShadow(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .28))],
        padding: const EdgeInsets.fromLTRB(6, 5, 14, 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Mynt(size: 26, periodMs: 4000, dollar: true),
            const SizedBox(width: 7),
            Text(A4MegCopy.a4_hylla_poeng_tx(poeng), style: aeTab(jakarta(14, em: -.02))),
          ],
        ),
      ),
    ),
  );
}

/// The gold coin (`phMynt`: rotateY 0 → 180 at 86 %, back at 100 %).
class _Mynt extends StatelessWidget {
  const _Mynt({required this.size, required this.periodMs, this.delayMs = 0, this.dollar = false});
  final double size;
  final double periodMs;
  final double delayMs;
  final bool dollar;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: LfLoop(
      builder: (context, t, _) {
        final p = ((t - delayMs) / periodMs) % 1.0;
        final ry = kf(p, const [0, .72, .86, 1], const [0, 0, 180, 0]);
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, .002)
            ..rotateY(rad(ry)),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: dollar
                  ? const RadialGradient(center: Alignment(-.32, -.44), radius: .8, colors: [Color(0xFFFBE8B4), Color(0xFFE0A32C), Color(0xFFB77F1C)], stops: [0, .62, 1])
                  : const RadialGradient(center: Alignment(-.32, -.44), radius: .8, colors: [Color(0xFFFFF1C4), Color(0xFFE8B23E), Color(0xFFB77F1C)], stops: [0, .58, 1]),
              boxShadow: dollar
                  ? const [BoxShadow(color: Color.fromRGBO(242, 193, 78, .6), blurRadius: 5)]
                  : const [BoxShadow(color: Color(0xFF946410), offset: Offset(0, 1.5)), BoxShadow(color: Color.fromRGBO(242, 193, 78, .45), blurRadius: 4)],
            ),
            alignment: Alignment.center,
            child: dollar ? const AeIkon('M12 4v16M8 8.5h6a3 3 0 0 1 0 6H10a3 3 0 0 0 0 6h7', size: 13, stroke: 2.6, color: Color(0xFF7C5A18)) : null,
          ),
        );
      },
    ),
  );
}

/// The Nivå row and «Målet ditt» (L7577–7613).
class _NivaaMaal extends StatelessWidget {
  const _NivaaMaal({required this.balance, required this.goal, required this.onNivaa});

  final PointsBalance balance;
  final PointGoal? goal;
  final VoidCallback onNivaa;

  @override
  Widget build(BuildContext context) {
    final b = balance;
    final g = goal;
    final pct = g == null ? 0 : g.percent.clamp(0, 100);
    return CssBox(
      key: const Key('hylla-nivaa'),
      radius: BorderRadius.circular(24),
      bg: _glass,
      shadows: _glassSh,
      border: Border.all(color: const Color.fromRGBO(255, 255, 255, .22)),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AePress(
            onTap: onNivaa,
            dy: 0,
            scale: .98,
            child: Row(
              children: [
                SizedBox(
                  width: 46,
                  height: 46,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // `inset:-5px; 1.5px dashed rgba(242,193,78,.55); medSnurr 16s`.
                      Positioned(
                        left: -5,
                        top: -5,
                        right: -5,
                        bottom: -5,
                        child: RepaintBoundary(
                          child: LfLoop(
                            builder: (context, t, _) => Transform.rotate(
                              angle: (t / 16000) * 2 * math.pi,
                              child: CustomPaint(painter: _Stiplet(const Color.fromRGBO(242, 193, 78, .55), 1.5)),
                            ),
                          ),
                        ),
                      ),
                      _Glod2(child: MegMedal(name: b.tierName, size: 46, animate: false)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        A4MegCopy.a4_hylla_nivaa_kicker,
                        style: inter(9.5, weight: FontWeight.w800, em: .14, color: const Color.fromRGBO(255, 255, 255, .6)),
                      ),
                      Text(b.tierName, style: jakarta(17, em: -.02, height: 1.15)),
                      const SizedBox(height: 1),
                      Text(
                        b.nextTierName == null || b.pointsToNextTier == null ? A4MegCopy.a4_meg_hoyeste : A4MegCopy.a4_meg_til_neste(b.pointsToNextTier!, b.nextTierName!),
                        style: aeTab(inter(11.5, color: const Color.fromRGBO(255, 255, 255, .7))),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color.fromRGBO(255, 255, 255, .1),
                    border: Border.all(color: const Color.fromRGBO(255, 255, 255, .18)),
                  ),
                  alignment: Alignment.center,
                  child: const AeIkon('M9 6l6 6-6 6', size: 12, stroke: 2.6),
                ),
              ],
            ),
          ),
          Container(height: 1, margin: const EdgeInsets.symmetric(vertical: 13), color: const Color.fromRGBO(255, 255, 255, .1)),
          Row(
            children: [
              SizedBox(
                key: const Key('hylla-maal'),
                width: 64,
                height: 64,
                child: AeTw(
                  v: pct / 100,
                  ms: 1000,
                  curve: const Cubic(.3, 1.1, .5, 1),
                  builder: (f) => CustomPaint(
                    painter: _Ring(f.clamp(0.0, 1.0)),
                    child: Center(child: Text('$pct%', style: aeTab(jakarta(14)))),
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      A4MegCopy.a4_hylla_maalet_ditt,
                      style: inter(9.5, weight: FontWeight.w800, em: .14, color: const Color.fromRGBO(255, 255, 255, .6)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      g == null ? A4MegCopy.a4_hylla_sett_maal : (g.reached ? A4MegCopy.a4_hylla_klar(g.label) : A4MegCopy.a4_hylla_til(g.remaining, g.label)),
                      style: inter(13.5, weight: FontWeight.w800, height: 1.3),
                    ),
                    const SizedBox(height: 8),
                    _Stripebar(pct: pct / 100),
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

/// `medGlod 3.2s` — the medal's pulsing gold glow.
class _Glod2 extends StatelessWidget {
  const _Glod2({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: LfLoop(
      child: child,
      builder: (context, t, child) {
        final p = (t / 3200) % 1.0;
        final spread = kf(p, const [0, .5, 1], const [0, 9, 0], cssEaseInOut);
        final a1 = kf(p, const [0, .5, 1], const [.55, 0, .55], cssEaseInOut);
        final blur = kf(p, const [0, .5, 1], const [18, 30, 18], cssEaseInOut);
        final a2 = kf(p, const [0, .5, 1], const [.35, .7, .35], cssEaseInOut);
        return DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Color.fromRGBO(242, 193, 78, a1), spreadRadius: spread),
              BoxShadow(color: Color.fromRGBO(242, 193, 78, a2), blurRadius: blur / 2),
            ],
          ),
          child: child,
        );
      },
    ),
  );
}

class _Stiplet extends CustomPainter {
  _Stiplet(this.c, this.w);
  final Color c;
  final double w;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2 - w / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..color = c;
    const n = 26;
    for (var i = 0; i < n; i++) {
      final a0 = i / n * 2 * math.pi;
      canvas.drawArc(Rect.fromCircle(center: size.center(Offset.zero), radius: r), a0, math.pi / n, false, paint);
    }
  }

  @override
  bool shouldRepaint(_Stiplet old) => false;
}

/// The goal ring (r 26, stroke 7, the track `rgba(0,0,0,.3)`, the arc
/// `#F7D57E → #F26D3D`, round caps, from 12 o'clock).
class _Ring extends CustomPainter {
  _Ring(this.f);
  final double f;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: c, radius: 26);
    canvas.drawCircle(
      c,
      26,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..color = const Color.fromRGBO(0, 0, 0, .3),
    );
    if (f <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * f,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF7D57E), Color(0xFFF26D3D)]).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_Ring old) => old.f != f;
}

/// The striped goal bar (`phStripe .9s`) with the spark at its end
/// (`phGnist 1.8s`).
class _Stripebar extends StatelessWidget {
  const _Stripebar({required this.pct});
  final double pct;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 9,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), color: const Color.fromRGBO(0, 0, 0, .3)),
          ),
        ),
        LayoutBuilder(
          builder: (context, box) => AeTw(
            v: pct.clamp(0.0, 1.0),
            ms: 800,
            curve: const Cubic(.3, 1.1, .5, 1),
            builder: (f) => SizedBox(
              width: box.maxWidth * f,
              height: 9,
              child: f <= 0
                  ? null
                  : Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: RepaintBoundary(
                              child: LfLoop(builder: (context, t, _) => CustomPaint(painter: _Striper((t / 900) % 1.0))),
                            ),
                          ),
                        ),
                        Positioned(right: -6, top: -2.5, child: const _Gnist(size: 14, periodMs: 1800)),
                      ],
                    ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _Striper extends CustomPainter {
  _Striper(this.p);
  final double p;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.drawRect(r, Paint()..shader = const LinearGradient(colors: [Color(0xFFF2C14E), Color(0xFFF26D3D)]).createShader(r));
    // 135° stripes, 14 px period, white .28, moving 14 px per cycle.
    final paint = Paint()..color = const Color.fromRGBO(255, 255, 255, .28);
    canvas.save();
    canvas.clipRect(r);
    for (double x = -size.height - 14 + p * 14; x < size.width + 14; x += 14) {
      final path = Path()
        ..moveTo(x, size.height)
        ..lineTo(x + 3.5, size.height)
        ..lineTo(x + 3.5 + size.height, 0)
        ..lineTo(x + size.height, 0)
        ..close();
      final p2 = Path()
        ..moveTo(x + 7, size.height)
        ..lineTo(x + 10.5, size.height)
        ..lineTo(x + 10.5 + size.height, 0)
        ..lineTo(x + 7 + size.height, 0)
        ..close();
      canvas.drawPath(path, paint);
      canvas.drawPath(p2, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Striper old) => old.p != p;
}

/// The four-point spark (`clip-path` star, `#FFF3C9`; `phGnist`: scale .3 → 1,
/// rotate 45°, fading in and out).
class _Gnist extends StatelessWidget {
  const _Gnist({required this.size, required this.periodMs, this.delayMs = 0});
  final double size;
  final double periodMs;
  final double delayMs;

  static final Path _stjerne = Path()
    ..moveTo(.5, 0)
    ..lineTo(.62, .38)
    ..lineTo(1, .5)
    ..lineTo(.62, .62)
    ..lineTo(.5, 1)
    ..lineTo(.38, .62)
    ..lineTo(0, .5)
    ..lineTo(.38, .38)
    ..close();

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: LfLoop(
      builder: (context, t, _) {
        final p = ((t - delayMs) / periodMs) % 1.0;
        final s = kf(p, const [0, .5, 1], const [.3, 1, .3], cssEaseInOut);
        final r = kf(p, const [0, .5, 1], const [0, 45, 0], cssEaseInOut);
        final o = kf(p, const [0, .5, 1], const [0, 1, 0], cssEaseInOut);
        return Opacity(
          opacity: o,
          child: Transform.rotate(
            angle: rad(r),
            child: Transform.scale(
              scale: s,
              child: CustomPaint(size: Size.square(size), painter: _PathPainter(_stjerne, const Color(0xFFFFF3C9))),
            ),
          ),
        );
      },
    ),
  );
}

class _PathPainter extends CustomPainter {
  _PathPainter(this.unit, this.c);
  final Path unit;
  final Color c;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width, size.height);
    canvas.drawPath(unit, Paint()..color = c);
  }

  @override
  bool shouldRepaint(_PathPainter old) => false;
}

class _Mint extends StatelessWidget {
  const _Mint(this.t);
  final String t;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      color: const Color.fromRGBO(92, 224, 184, .18),
      border: Border.all(color: const Color.fromRGBO(92, 224, 184, .4)),
    ),
    child: Text(
      t,
      style: aeTab(inter(10, weight: FontWeight.w800, color: const Color(0xFF7FF0CB))),
    ),
  );
}

class _KlarePille extends StatelessWidget {
  const _KlarePille({super.key, required this.tekst});
  final String tekst;

  @override
  Widget build(BuildContext context) => CssBox(
    radius: BorderRadius.circular(999),
    bg: const [CssSolid(Color.fromRGBO(92, 224, 184, .14))],
    shadows: const [CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(92, 224, 184, .4))],
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AePulsDot(),
        const SizedBox(width: 6),
        Text(
          tekst,
          style: aeTab(inter(10.5, weight: FontWeight.w800, color: const Color(0xFF7FF0CB))),
        ),
      ],
    ),
  );
}

/// The 24 px medal beside «Åpent på …».
class _LitenMedalje extends StatelessWidget {
  const _LitenMedalje({required this.navn});
  final String navn;

  @override
  Widget build(BuildContext context) {
    final m = medalFor(navn);
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(center: const Alignment(-.32, -.44), radius: .9, colors: m.gradient, stops: m.stops),
        boxShadow: [
          BoxShadow(color: m.ring, spreadRadius: 1.5),
          const BoxShadow(color: Color.fromRGBO(242, 193, 78, .4), blurRadius: 6),
        ],
      ),
      alignment: Alignment.center,
      child: Text('Æ', style: jakarta(10, color: m.ink, height: 1)),
    );
  }
}

/// A claim (`minePremier`): the holo sweep, the art, the merchant, the chip,
/// the name and how it is used, then — under a dashed line — the days left
/// with their bar and «Detaljer».
class _Billett extends StatelessWidget {
  const _Billett({required this.claim, required this.prize, required this.dager, required this.onTap});

  final PrizeClaim claim;
  final Prize? prize;
  final int dager;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = claim;
    final (chip, chipBg, chipC) = switch (c.state) {
      'claimed' || 'applied' => (A4MegCopy.a4_hylla_chip_klar, const Color(0xFF5CE0B8), const Color(0xFF0F2A33)),
      'shipped' => (A4MegCopy.a4_hylla_chip_sendt, const Color(0xFFF7D57E), const Color(0xFF3A2708)),
      'delivered' || 'used' => (A4MegCopy.a4_hylla_chip_brukt, const Color.fromRGBO(255, 255, 255, .2), Colors.white),
      _ => (A4MegCopy.a4_hylla_chip_utlopt, const Color.fromRGBO(255, 255, 255, .2), Colors.white),
    };
    final brukt = c.state == 'used' || c.state == 'expired' || c.state == 'cancelled';
    final art = PrizeArt.of(slug: prize?.slug, name: c.prizeName ?? prize?.name ?? '');
    return AePress(
      onTap: onTap,
      dy: 0,
      scale: .97,
      child: Opacity(
        opacity: brukt ? .55 : 1,
        child: CssBox(
          width: 252,
          radius: BorderRadius.circular(20),
          clip: true,
          bg: _glass,
          shadows: _glassSh,
          border: Border.all(color: const Color.fromRGBO(255, 255, 255, .22)),
          child: Stack(
            children: [
              const Positioned.fill(child: _Holo()),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 50, height: 50, child: _Art(art: art)),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      prize?.partnerName ?? 'Ærend',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: inter(9.5, weight: FontWeight.w800, em: .06, color: const Color(0xFF7FF0CB)),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: chipBg),
                                    child: Text(
                                      chip,
                                      style: inter(9.5, weight: FontWeight.w800, color: chipC),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(c.prizeName ?? prize?.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: jakarta(14, em: -.015, height: 1.2)),
                              const SizedBox(height: 2),
                              Text(
                                _PremiehyllaScreenState._hvordan(prize?.type ?? ''),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: inter(11, height: 1.35, color: const Color.fromRGBO(255, 255, 255, .72)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  CustomPaint(painter: _StipletLinje(), child: const SizedBox(height: 1.5)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 9, 12, 11),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                A4MegCopy.a4_hylla_dager_igjen(dager),
                                style: aeTab(inter(10.5, weight: FontWeight.w800, color: dager <= 7 ? const Color(0xFFF7D57E) : const Color(0xFFDCE9EC))),
                              ),
                              const SizedBox(height: 5),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: SizedBox(
                                  height: 4,
                                  width: double.infinity,
                                  child: Stack(
                                    children: [
                                      const Positioned.fill(child: ColoredBox(color: Color.fromRGBO(0, 0, 0, .3))),
                                      FractionallySizedBox(
                                        widthFactor: (dager / 60).clamp(0.0, 1.0),
                                        heightFactor: 1,
                                        alignment: Alignment.centerLeft,
                                        child: const DecoratedBox(
                                          decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF3FD0A4), Color(0xFF9CF5D6)])),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        CssBox(
                          radius: BorderRadius.circular(999),
                          bg: const [
                            CssLinear(180, [Color.fromRGBO(255, 255, 255, .18), Color.fromRGBO(255, 255, 255, .07)]),
                          ],
                          shadows: const [CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .3)), CssShadow(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .24))],
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          child: Text(A4MegCopy.a4_hylla_detaljer, style: inter(11, weight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StipletLinje extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color.fromRGBO(255, 255, 255, .16)
      ..strokeWidth = 1.5;
    for (double x = 0; x < size.width; x += 7) {
      canvas.drawLine(Offset(x, .75), Offset(math.min(x + 4, size.width), .75), paint);
    }
  }

  @override
  bool shouldRepaint(_StipletLinje old) => false;
}

/// `phHolo 5.5s` — a mint-to-peach band sweeping the ticket.
class _Holo extends StatelessWidget {
  const _Holo();

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: LayoutBuilder(
      builder: (context, box) => RepaintBoundary(
        child: LfLoop(
          builder: (context, t, _) {
            final p = (t / 5500) % 1.0;
            final x = kf(p, const [0, .6, 1], const [-1.3, 2.8, 2.8], cssEaseInOut);
            final w = box.maxWidth * .45;
            return Transform.translate(
              offset: Offset(x * w, 0),
              child: Transform(
                transform: Matrix4.skewX(rad(-18)),
                child: SizedBox(
                  width: w,
                  height: box.maxHeight,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-1, -.18),
                        end: Alignment(1, .18),
                        colors: [Color.fromRGBO(255, 255, 255, 0), Color.fromRGBO(170, 255, 225, .18), Color.fromRGBO(255, 205, 150, .18), Color.fromRGBO(255, 255, 255, 0)],
                        stops: [0, .4, .6, 1],
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
  );
}

/// The prize's 3D art (`PremieIkon`): the drawing at its own proportions,
/// fitted in the box.
class _Art extends StatelessWidget {
  const _Art({required this.art});
  final PrizeArt art;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.contain,
    child: SizedBox(
      width: art.width,
      height: art.height,
      child: bergenSvg(art.icon, fit: BoxFit.contain),
    ),
  );
}

/// «Ægil velger»'s art: Ægil on the deep teal roundel.
class _VelgerArt extends StatelessWidget {
  const _VelgerArt();

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(begin: Alignment(-.34, -.94), end: Alignment(.34, .94), colors: PrizeArt.velgerTint),
      boxShadow: [BoxShadow(color: Color.fromRGBO(255, 255, 255, .3), spreadRadius: 1.5)],
    ),
    clipBehavior: Clip.antiAlias,
    child: Transform.translate(
      offset: const Offset(0, 6),
      child: Image.asset(aePose('popup'), fit: BoxFit.cover, alignment: Alignment.topCenter),
    ),
  );
}

class _Rutenett extends StatelessWidget {
  const _Rutenett({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < children.length; i += 2)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: children[i]),
              const SizedBox(width: 10),
              Expanded(child: i + 1 < children.length ? children[i + 1] : const SizedBox()),
            ],
          ),
        ),
    ],
  );
}

/// A prize on the shelf (`premier[i]`, L7642–7681).
class _PremieKort extends StatelessWidget {
  const _PremieKort({
    super.key,
    required this.i,
    required this.navn,
    this.merke,
    this.linje,
    required this.pris,
    required this.art,
    required this.poeng,
    required this.ute,
    required this.erMaal,
    this.velger = false,
    required this.onHent,
    required this.onMaal,
  });

  final int i;
  final String navn;
  final String? merke;
  final String? linje;
  final int pris;
  final Widget art;
  final int poeng;
  final bool ute;
  final bool erMaal;
  final bool velger;
  final VoidCallback onHent;
  final VoidCallback onMaal;

  @override
  Widget build(BuildContext context) {
    final raad = poeng >= pris && pris > 0;
    final laast = !ute && !raad;
    final glans = !ute && raad;
    final bobD = (i % 4) * 400.0;
    final knTx = ute
        ? A4MegCopy.a4_hylla_utsolgt_mnd
        : (raad ? A4MegCopy.a4_hylla_hent : (velger ? A4MegCopy.a4_hylla_la_aegil : (erMaal ? A4MegCopy.a4_hylla_er_maal_kn : A4MegCopy.a4_hylla_sett_som_maal)));
    final visLinje = (linje ?? '').isNotEmpty && linje != 'Fra ${merke ?? ''}';

    Widget kort = CssBox(
      radius: BorderRadius.circular(22),
      bg: const [
        CssRadial([Color.fromRGBO(255, 214, 140, .14), Color.fromRGBO(255, 214, 140, 0)], stops: [0, .7], rx: .9, ry: .5, cx: .5, cy: 0),
        CssLinear(180, [Color.fromRGBO(255, 255, 255, .16), Color.fromRGBO(255, 255, 255, .06)]),
      ],
      shadows: const [
        CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .36)),
        CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .14)),
        CssShadow(0, 3, 0, 0, Color.fromRGBO(4, 20, 28, .5)),
        CssShadow(0, 18, 26, -16, Color.fromRGBO(2, 12, 18, .9)),
      ],
      padding: const EdgeInsets.fromLTRB(11, 0, 11, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The art floats 28 px above the card (`margin-top:-28px`).
          SizedBox(
            height: 54,
            child: OverflowBox(
              alignment: Alignment.bottomCenter,
              maxHeight: 82,
              child: SizedBox(
                height: 82,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    if (glans) ...[
                      const Positioned(top: 40 - 75, width: 150, height: 150, child: _Straaler()),
                      const Positioned(
                        left: 0,
                        right: 0,
                        top: 18,
                        child: Align(alignment: Alignment(-.68, 0), child: _Gnist(size: 9, periodMs: 2400)),
                      ),
                      const Positioned(
                        left: 0,
                        right: 0,
                        top: 8,
                        child: Align(alignment: Alignment(.6, 0), child: _Gnist(size: 7, periodMs: 2400, delayMs: 800)),
                      ),
                    ],
                    Positioned(bottom: 3, child: _Skygge(delayMs: bobD)),
                    Positioned(
                      top: 2,
                      width: 66,
                      height: 66,
                      child: _Flyt(delayMs: bobD, child: art),
                    ),
                    if (ute)
                      Positioned(
                        top: 82 * .44 - 12,
                        child: Transform.rotate(
                          angle: rad(-9),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(7),
                              color: const Color.fromRGBO(15, 42, 51, .85),
                              border: Border.all(color: const Color.fromRGBO(255, 255, 255, .6), width: 2),
                            ),
                            child: Text(A4MegCopy.a4_hylla_utsolgt, style: inter(9, weight: FontWeight.w800, em: .08)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Builder(
            builder: (context) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((merke ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    merke!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: inter(9.5, weight: FontWeight.w800, em: .04, color: const Color(0xFF7FF0CB)),
                  ),
                ],
                const SizedBox(height: 3),
                Text(navn, style: jakarta(14, em: -.02, height: 1.2)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _Mynt(size: 18, periodMs: 4500, delayMs: bobD),
                    const SizedBox(width: 5),
                    Text(A4MegCopy.nf(pris), style: aeTab(jakarta(15.5, em: -.02, color: const Color(0xFFF7D57E)))),
                    const SizedBox(width: 5),
                    Text(
                      A4MegCopy.a4_meg_poeng,
                      style: inter(10.5, weight: FontWeight.w800, color: const Color.fromRGBO(247, 213, 126, .78)),
                    ),
                  ],
                ),
                if (visLinje) ...[const SizedBox(height: 4), Text(linje!, style: inter(10.5, height: 1.4, color: const Color.fromRGBO(255, 255, 255, .7)))],
              ],
            ),
          ),
          const Spacer(),
          if (laast) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: SizedBox(
                height: 7,
                width: double.infinity,
                child: Stack(
                  children: [
                    const Positioned.fill(child: ColoredBox(color: Color.fromRGBO(0, 0, 0, .3))),
                    FractionallySizedBox(
                      widthFactor: pris == 0 ? 0 : (poeng / pris).clamp(0.0, 1.0),
                      heightFactor: 1,
                      alignment: Alignment.centerLeft,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(99)),
                          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFD27A), Color(0xFFF26D3D)]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              A4MegCopy.a4_hylla_igjen(math.max(0, pris - poeng)),
              style: aeTab(inter(10, weight: FontWeight.w800, color: const Color.fromRGBO(255, 255, 255, .78))),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _Knapp(tekst: knTx, ute: ute, raad: raad, glans: glans, pulsDelay: (i % 3) * 450.0, onTap: onHent),
              ),
              if (raad && !ute && !velger) ...[
                const SizedBox(width: 6),
                AePress(
                  onTap: onMaal,
                  dy: 2,
                  child: CssBox(
                    width: 40,
                    height: 40,
                    radius: BorderRadius.circular(14),
                    bg: erMaal
                        ? const [
                            CssLinear(180, [Color(0xFFA6F8DD), Color(0xFF3CC79F)]),
                          ]
                        : const [
                            CssLinear(180, [Color.fromRGBO(255, 255, 255, .18), Color.fromRGBO(255, 255, 255, .07)]),
                          ],
                    shadows: erMaal
                        ? const [CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .6)), CssShadow(0, 2.5, 0, 0, Color(0xFF23946F)), CssShadow(0, 8, 12, -6, Color.fromRGBO(20, 110, 80, .6))]
                        : const [
                            CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .35)),
                            CssShadow(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .22)),
                            CssShadow(0, 2.5, 0, 0, Color.fromRGBO(8, 30, 38, .5)),
                          ],
                    child: Center(
                      child: AeIkon('${AeIkon.sirkel(12, 12, 8.5)}${AeIkon.sirkel(12, 12, 4.5)}', size: 17, stroke: 2.4, color: erMaal ? const Color(0xFF0F3A40) : const Color(0xFF7FF0CB)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
    if (ute)
      kort = Opacity(
        opacity: .72,
        child: ColorFiltered(colorFilter: const ColorFilter.matrix(_mettet35), child: kort),
      );
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _KortInn(delay: i * 45.0, child: kort),
          if (erMaal)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 3, 8, 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFA6F8DD), Color(0xFF3CC79F)]),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFF23946F), offset: Offset(0, 2)),
                    BoxShadow(color: Color.fromRGBO(92, 224, 184, .5), blurRadius: 6),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AeIkon('${AeIkon.sirkel(12, 12, 8)}${AeIkon.sirkel(12, 12, 3)}', size: 9, stroke: 3, color: const Color(0xFF0F2A33)),
                    const SizedBox(width: 3),
                    Text(
                      A4MegCopy.a4_hylla_maal_merke,
                      style: inter(8.5, weight: FontWeight.w800, em: .08, color: const Color(0xFF0F2A33)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// `saturate(.35)`.
const List<double> _mettet35 = [
  .5157, .4644, .0199, 0, 0, //
  .1382, .8418, .0199, 0, 0, //
  .1382, .4644, .3973, 0, 0, //
  0, 0, 0, 1, 0,
];

/// The card's key: orange «Hent» (`phKnPuls 2.6s`, the sheen), glass «Sett
/// som mål», the sunken «Utsolgt denne måneden».
class _Knapp extends StatelessWidget {
  const _Knapp({required this.tekst, required this.ute, required this.raad, required this.glans, required this.pulsDelay, required this.onTap});

  final String tekst;
  final bool ute;
  final bool raad;
  final bool glans;
  final double pulsDelay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, sh, fg, dy) = ute
        ? (const [CssSolid(Color.fromRGBO(0, 0, 0, .25))], const [CssShadow.inset(0, 1, 3, 0, Color.fromRGBO(0, 0, 0, .4))], const Color.fromRGBO(255, 255, 255, .55), 0.0)
        : raad
        ? (
            const [
              CssLinear(180, [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], [0, .56, 1]),
            ],
            const [
              CssShadow(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .5)),
              CssShadow(0, 1.5, 0, 0, Color(0xFFC4491A)),
              CssShadow(0, 3.5, 0, 0, Color.fromRGBO(120, 45, 15, .42)),
              CssShadow(0, 11, 16, -9, Color.fromRGBO(200, 70, 25, .75)),
            ],
            Colors.white,
            3.5,
          )
        : (
            const [
              CssLinear(180, [Color.fromRGBO(255, 255, 255, .18), Color.fromRGBO(255, 255, 255, .07)]),
            ],
            const [
              CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .35)),
              CssShadow(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .28)),
              CssShadow(0, 2, 0, 0, Color.fromRGBO(8, 30, 38, .5)),
              CssShadow(0, 9, 14, -8, Color.fromRGBO(2, 12, 18, .8)),
            ],
            Colors.white,
            2.0,
          );
    Widget k = CssBox(
      height: 40,
      radius: BorderRadius.circular(14),
      clip: glans,
      bg: bg,
      shadows: sh,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (glans) const Positioned.fill(child: _Sveip()),
          Text(
            tekst,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: inter(12.5, weight: FontWeight.w800, color: fg),
          ),
        ],
      ),
    );
    if (raad && !ute) {
      final inner = k;
      k = RepaintBoundary(
        child: LfLoop(
          child: inner,
          builder: (context, t, child) {
            final p = ((t - pulsDelay) / 2600) % 1.0;
            final s = kf(p, const [0, .5, 1], const [1, 1.035, 1], cssEaseInOut);
            final y = kf(p, const [0, .5, 1], const [0, -1, 0], cssEaseInOut);
            return Transform.translate(
              offset: Offset(0, y),
              child: Transform.scale(scale: s, child: child),
            );
          },
        ),
      );
    }
    return AePress(onTap: ute ? null : onTap, dy: dy, child: k);
  }
}

/// `skinnSveip 3.2s 1.2s` — the white sheen over «Hent».
class _Sveip extends StatelessWidget {
  const _Sveip();

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: LayoutBuilder(
      builder: (context, box) => RepaintBoundary(
        child: LfLoop(
          builder: (context, t, _) {
            final p = kfLoop(t, 1200, 3200);
            if (p == null) return const SizedBox.shrink();
            final x = kf(p, const [0, 1], const [-1.4, 2.4], cssEaseInOut);
            final o = kf(p, const [0, .2, 1], const [0, .7, 0]);
            final w = box.maxWidth * .4;
            return Opacity(
              opacity: o.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(x * w, 0),
                child: Transform(
                  transform: Matrix4.skewX(rad(-18)),
                  child: SizedBox(
                    width: w,
                    height: box.maxHeight,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(gradient: LinearGradient(colors: [Color.fromRGBO(255, 255, 255, 0), Color.fromRGBO(255, 255, 255, .45), Color.fromRGBO(255, 255, 255, 0)])),
                    ),
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

/// `phStraal 18s` — the gold sunburst behind a prize that can be taken.
class _Straaler extends StatelessWidget {
  const _Straaler();

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      child: LfLoop(
        builder: (context, t, _) => Transform.rotate(
          angle: (t / 18000) * 2 * math.pi,
          child: CustomPaint(painter: _StraalePainter()),
        ),
      ),
    ),
  );
}

class _StraalePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.saveLayer(rect, Paint());
    final paint = Paint()..color = const Color.fromRGBO(255, 226, 150, .22);
    for (var a = 0.0; a < 360; a += 30) {
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..arcTo(rect, rad(a - 90), rad(8), false)
        ..close();
      canvas.drawPath(path, paint);
    }
    // `mask-image: radial-gradient(circle,#000 20%,transparent 66%)`.
    canvas.drawRect(
      rect,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = const RadialGradient(colors: [Colors.black, Color(0x00000000)], stops: [.2, .66]).createShader(rect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StraalePainter old) => false;
}

/// `phFlyt 4.4s` — the art bobbing and rocking.
class _Flyt extends StatelessWidget {
  const _Flyt({required this.delayMs, required this.child});
  final double delayMs;
  final Widget child;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: LfLoop(
      child: child,
      builder: (context, t, child) {
        final p = ((t - delayMs) / 4400) % 1.0;
        final y = kf(p, const [0, .5, 1], const [0, -6, 0], cssEaseInOut);
        final r = kf(p, const [0, .5, 1], const [-2, 2, -2], cssEaseInOut);
        return Transform.translate(
          offset: Offset(0, y),
          child: Transform.rotate(angle: rad(r), child: child),
        );
      },
    ),
  );
}

/// `phSkyggeP 4.4s` — the shadow under the floating art.
class _Skygge extends StatelessWidget {
  const _Skygge({required this.delayMs});
  final double delayMs;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: LfLoop(
      builder: (context, t, _) {
        final p = ((t - delayMs) / 4400) % 1.0;
        final s = kf(p, const [0, .5, 1], const [1, .82, 1], cssEaseInOut);
        final o = kf(p, const [0, .5, 1], const [1, .7, 1], cssEaseInOut);
        return Opacity(
          opacity: o,
          child: Transform.scale(
            scale: s,
            child: const SizedBox(
              width: 54,
              height: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.elliptical(27, 5)),
                  gradient: RadialGradient(colors: [Color.fromRGBO(0, 8, 12, .5), Color.fromRGBO(0, 8, 12, 0)]),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

/// A locked prize (`laaste[i]`): the blurred art behind a lock, the band
/// medal, the name, the teaser, the price and «Fra {nivå} · N poeng til».
class _Laast extends StatelessWidget {
  const _Laast({super.key, required this.preview, required this.onTap});

  final PrizePreview preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = preview;
    final art = PrizeArt.of(slug: p.slug, name: p.name);
    final m = medalFor(p.tierName);
    return AePress(
      onTap: onTap,
      dy: 0,
      scale: .98,
      child: CssBox(
        radius: BorderRadius.circular(20),
        bg: const [
          CssLinear(165, [Color.fromRGBO(255, 255, 255, .11), Color.fromRGBO(255, 255, 255, .04)]),
        ],
        shadows: const [CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .2)), CssShadow(0, 14, 22, -16, Color.fromRGBO(2, 12, 18, .9))],
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, .14)),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: SizedBox(
                width: 76,
                height: 68,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(decoration: BoxDecoration(gradient: art.gradient)),
                    ),
                    ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 1.75, sigmaY: 1.75),
                      child: SizedBox(width: 50, height: 50, child: _Art(art: art)),
                    ),
                    const Positioned.fill(child: ColoredBox(color: Color.fromRGBO(15, 42, 51, .3))),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color.fromRGBO(15, 42, 51, .7),
                        border: Border.all(color: const Color.fromRGBO(255, 255, 255, .35)),
                      ),
                      alignment: Alignment.center,
                      child: const AeIkon(_las, size: 12, stroke: 2.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(center: const Alignment(-.32, -.44), radius: .9, colors: m.gradient, stops: m.stops),
                          boxShadow: const [BoxShadow(color: Color.fromRGBO(255, 255, 255, .2), blurRadius: 4)],
                        ),
                        alignment: Alignment.center,
                        child: Text('Æ', style: jakarta(8.5, color: m.ink, height: 1)),
                      ),
                      const SizedBox(width: 7),
                      Expanded(child: Text(p.name, style: jakarta(13.5, em: -.02, height: 1.2))),
                    ],
                  ),
                  if ((p.teaser ?? '').isNotEmpty) ...[const SizedBox(height: 4), Text(p.teaser!, style: inter(10.5, height: 1.4, color: const Color.fromRGBO(255, 255, 255, .66)))],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        A4MegCopy.a4_hylla_poeng_tx(p.pointPrice),
                        style: aeTab(inter(12, weight: FontWeight.w800, color: const Color(0xFFF7D57E))),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: const Color.fromRGBO(255, 255, 255, .08),
                          border: Border.all(color: const Color.fromRGBO(255, 255, 255, .16)),
                        ),
                        child: Text(
                          A4MegCopy.a4_hylla_krav(p.tierName, p.pointsToUnlock),
                          style: inter(9.5, weight: FontWeight.w800, color: const Color.fromRGBO(255, 255, 255, .8)),
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
    );
  }
}

/// The 60-day note with the varde (L7700).
class _Vilkaar extends StatelessWidget {
  const _Vilkaar({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AePress(
    key: const Key('hylla-vilkaar'),
    onTap: onTap,
    dy: 0,
    scale: .98,
    child: CssBox(
      radius: BorderRadius.circular(20),
      bg: const [
        CssLinear(165, [Color.fromRGBO(255, 255, 255, .1), Color.fromRGBO(255, 255, 255, .04)]),
      ],
      shadows: const [CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .2))],
      border: Border.all(color: const Color.fromRGBO(255, 255, 255, .14)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          SizedBox(width: 24, height: 30, child: bergenSvg('meg_varde3d', fit: BoxFit.contain)),
          const SizedBox(width: 11),
          Expanded(
            child: Text(A4MegCopy.a4_hylla_60, style: inter(11.5, height: 1.45, color: const Color.fromRGBO(255, 255, 255, .8))),
          ),
          const SizedBox(width: 11),
          const AeIkon('M9 6l6 6-6 6', size: 13, stroke: 2.6),
        ],
      ),
    ),
  );
}
