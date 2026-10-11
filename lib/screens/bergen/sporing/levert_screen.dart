import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../data/ops/tracking_models.dart';
import '../../../dialogs/reviewDialog/review_dialog_repo.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../../common/auth/launch/launch_onboarding.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/auth/launch/lf_widgets.dart';
import '../../common/home/bergen/bergen_nav.dart';
import '../../common/homeMainV1/home_main_v1.dart';
import '../../snurre/snurre_launcher_policy.dart';
import '../hjem/hjem_harness.dart';
import '../kit/bergen_kit.dart';
import 'hjelp_sheet.dart';
import 'sporing_bits.dart';
import 'sporing_copy.dart';

/// `levert` (Launch L7278–7336) at `/bergen/levert/{id}`: the night over
/// Bryggen (baked), the aurora swaying, «Levert. Håper det smaker.», «18:11
/// · to minutter før tiden», the Æ sticker + «rend», Ægil cheering, the
/// Poeng card («+34 poeng for denne ordren», the balance, «+50 poeng ·
/// første gang hos X», the local-support line), «Levert til deg · koden ble
/// bekreftet av X», «Takk til X» (the tips sheet), «Hvordan gikk det?» (the
/// rating sheet), «Noe galt med bestillingen?», «Ferdig», and the nav with
/// no tab lit. (The referral ticket is the Sporing panel's slot right after
/// a purchase; Launch has no sheet for it here.)
class LevertScreen extends StatefulWidget {
  const LevertScreen({super.key, this.orderId, this.tracking, this.api, this.rating, this.levertKl, this.poeng});

  final int? orderId;
  final OpsTracking? tracking;
  final OpsCustomerApi? api;

  /// Injected in tests.
  final Future<void> Function(int orderId, int stars)? rating;

  /// When the order was delivered, as the Sporing screen saw it.
  final DateTime? levertKl;

  /// The order's points, when the Sporing screen already fetched them.
  final int? poeng;

  @override
  State<LevertScreen> createState() => _LevertScreenState();
}

enum _Ark { tips, vurder }

class _LevertScreenState extends State<LevertScreen> {
  bool _routeRead = false;
  int _id = 0;
  OpsTracking? _tracking;
  bool _missing = false;
  Map<String, dynamic>? _points;
  int? _saldo;
  bool _rated = false;
  _Ark? _ark;

  OpsCustomerApi get _api => widget.api ?? OpsCustomerApi();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeRead) return;
    _routeRead = true;
    final args = BergenRoutes.argsOf(context);
    _id = widget.orderId ?? int.tryParse(args['id'] ?? '') ?? 0;
    _tracking = widget.tracking;
    if (_tracking == null) {
      _load();
    } else {
      _loadPoints();
    }
    _loadSaldo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ark = args['ark'] ?? (kDebugMode && HjemHarness.levert != null ? HjemHarness.levertArk : null);
      if (ark == 'tips') setState(() => _ark = _Ark.tips);
      if (ark == 'vurder') setState(() => _ark = _Ark.vurder);
    });
  }

  Future<void> _load() async {
    try {
      final json = await _api.tracking(_id);
      if (!mounted) return;
      setState(() => _tracking = OpsTracking.fromJson(json));
      _loadPoints();
    } catch (_) {
      if (mounted) setState(() => _missing = true);
    }
  }

  Future<void> _loadPoints() async {
    final p = await _api.pointsForOrder(_id);
    if (mounted && p != null) setState(() => _points = p);
  }

  Future<void> _loadSaldo() async {
    final me = await _api.pointsMe();
    final available = (me?['points'] is Map) ? (me!['points']['available'] as num?) : null;
    if (mounted && available != null) setState(() => _saldo = available.toInt());
  }

  Future<void> _rate(int stars) async {
    if (widget.rating != null) {
      await widget.rating!(_id, stars);
    } else {
      try {
        await ReviewDialogRepo().callOrderRatingApi(_id, stars.toDouble(), stars.toDouble(), null, null);
      } catch (_) {
        // The thanks stay; a failed post is not the customer's problem.
      }
    }
    if (mounted) setState(() => _rated = true);
  }

  void _ferdig() {
    Navigator.of(context).popUntil((r) => r.isFirst);
    context.findAncestorStateOfType<HomeMainV1State>()?.switchToTab(BergenTab.home.index);
  }

  void _hjelp([HjelpState initial = HjelpState.main]) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        settings: RouteSettings(name: '$snurreLauncherHiddenRoutePrefix/bergen/sporing/$_id/hjelp'),
        transitionDuration: Duration(milliseconds: reduce ? 0 : 380),
        reverseTransitionDuration: Duration(milliseconds: reduce ? 0 : 260),
        pageBuilder: (_, __, ___) => HjelpScreen(orderId: _id, tracking: _tracking, api: _api, initial: initial),
        transitionsBuilder: (context, a, _, child) {
          final p = cssSkjerm.transform(a.value);
          return Opacity(
            opacity: (.6 + .4 * p).clamp(0.0, 1.0) * (a.status == AnimationStatus.reverse ? p : 1),
            child: Transform.translate(offset: Offset(0, 26 * (1 - p)), child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _tracking;
    if (_missing) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F1F2B),
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white),
        body: Center(
          child: Text(SporingCopy.a1_sporing_ikke_funnet, style: inter(13, weight: FontWeight.w700)),
        ),
      );
    }
    if (t == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F1F2B),
        body: Center(child: CircularProgressIndicator(color: kSpMint)),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFF0F2A36),
      resizeToAvoidBottomInset: false,
      body: LfFrame(
        child: LfOnce(
          ms: 340,
          builder: (context, tt, child) {
            final p = cssSkjerm.transform(kfP(tt, 0, 340));
            return Opacity(
              opacity: kf(p, const [0, .55, 1], const [0, 1, 1]),
              child: Transform(alignment: Alignment.center, transform: Matrix4.translationValues(0, 14 * (1 - p), 0)..scaleByDouble(.978 + .022 * p, .978 + .022 * p, 1, 1), child: child),
            );
          },
          child: _skjerm(context, t),
        ),
      ),
    );
  }

  Widget _skjerm(BuildContext context, OpsTracking t) {
    final mq = MediaQuery.of(context);
    final topp = mq.padding.top;
    final bunn = mq.padding.bottom;
    // The prototype's frame has its own status row (29 px); on the device the
    // scene slides down under the real one.
    final off = math.max(0.0, topp - 29);
    final levertKl = widget.levertKl ?? DateTime.tryParse('${t.raw['delivered_at'] ?? ''}')?.toLocal() ?? t.deliveryCode?.verifiedAt ?? DateTime.now();
    final early = t.promisedEnd == null ? null : t.promisedEnd!.difference(levertKl).inMinutes;
    final points = _points;
    final earned = widget.poeng ?? spPoengForOrdre(points, _id);
    final firstTime = (points?['first_time_bonus'] ?? points?['first_time']) as num?;
    final leagueGap = points?['league_gap'];
    final byWhom = t.isPartner ? t.deliveredByLabel : (t.courier?.firstName ?? SporingCopy.a1_sporing_Budet.toLowerCase());
    final codeConfirmed = t.deliveryCode?.verifiedAt != null;
    final navBunn = math.max(bunn, 16.0);
    final butikk = t.store?.name ?? '';
    // Backend plan Step 4: the customer's delivered orders this month and the
    // store's own story, from the tracking payload (absent: the line hides).
    final lokale = (t.raw['month_local_count'] as num?)?.toInt();
    final historie = t.raw['store'] is Map ? (t.raw['store'] as Map)['story']?.toString().trim() : null;
    final visTakk = !t.isPartner && !t.isPickup && t.courier != null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: ColoredBox(color: const Color(0xFF0F1F2B))),
        Positioned(
          left: 0,
          top: off,
          width: 390,
          height: 844,
          child: Image.asset('assets/images/sporing/levert.jpg', fit: BoxFit.fill, filterQuality: FilterQuality.medium),
        ),
        if (off > 0)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: off + 1,
            child: const ColoredBox(color: Color(0xFF0F1F2B)),
          ),
        // The aurora (`sway`).
        Positioned(left: 0, top: off, child: const _Nordlys()),
        // Title block (padding 34 under the status row).
        Positioned(
          left: 24,
          right: 24,
          top: off + 29 + 34,
          child: Column(
            children: [
              LfOnce(
                ms: 900,
                builder: (context, tt, child) => Opacity(opacity: .6 + .4 * cssEaseOut.transform(kfP(tt, 0, 900)), child: child),
                child: Text(
                  SporingCopy.a1_sporing_levert_haaper,
                  key: const Key('a1_sporing_levert_tittel'),
                  textAlign: TextAlign.center,
                  style: jakarta(30, em: -.03, height: 1.12, color: const Color(0xFFF5F3EF)),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                early != null && early > 0 ? SporingCopy.a1_sporing_min_for_tiden(spKlokke(levertKl), early) : spKlokke(levertKl),
                key: Key(early != null && early > 0 ? 'a1_sporing_levert_for' : 'a1_sporing_levert_klokke'),
                style: inter(12.5, weight: FontWeight.w500, color: const Color(0xFF9FB6C2)),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SpKlistre(delay: 600, dur: 700, child: const LfMerke(w: 44, h: 35)),
                  Transform.translate(
                    offset: const Offset(-5, 0),
                    child: Text('rend', style: jakarta(19, em: -.045, color: const Color(0xFFF5F3EF))),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Ægil cheering (right 18, top 304, 80 wide), `aegHopp 2.6s`.
        Positioned(
          right: 18,
          top: off + 304,
          child: LfLoop(
            builder: (context, tt, child) {
              final p = (tt / 2600) % 1.0;
              const st = [0.0, .3, .55, .7, 1.0];
              final y = kf(p, st, const [0, -10, 0, -4, 0], cssEaseInOut);
              final r = kf(p, st, const [0, -3, 0, 0, 0], cssEaseInOut);
              return Transform(alignment: Alignment.bottomCenter, transform: Matrix4.translationValues(0, y, 0)..rotateZ(rad(r)), child: child);
            },
            child: Opacity(opacity: .92, child: aegil('explore', w: 80, h: 80)),
          ),
        ),
        // The bottom block (left/right 20, bottom 96 over the nav).
        Positioned(
          left: 20,
          right: 20,
          bottom: navBunn + 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Poeng for denne ordren (the prototype's top 432; here it sits
              // above the keys so the extra «Levert til deg» line never
              // collides with it).
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 19, sigmaY: 19),
                      child: Container(
                        key: const Key('a1_sporing_poeng'),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: rgba(15, 31, 43, .55),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: rgba(255, 255, 255, .12)),
                          boxShadow: [BoxShadow(color: rgba(255, 255, 255, .16), offset: const Offset(0, 1), blurStyle: BlurStyle.inner)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _StigOpp(
                              delay: 250,
                              child: Row(
                                children: [
                                  Text(
                                    earned == null ? '—' : '+$earned',
                                    key: const Key('a1_sporing_poeng_tall'),
                                    style: jakarta(28, em: -.03, height: 1, color: kSpMint),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          SporingCopy.a1_sporing_poeng_for_ordren,
                                          style: inter(13, weight: FontWeight.w800, color: const Color(0xFFF2EFFA)),
                                        ),
                                        if (_saldo != null) Text(SporingCopy.a1_sporing_balansen(spTall(_saldo!)), style: inter(11, color: const Color(0xFF9FB6C2))),
                                        if (leagueGap is Map)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 1),
                                            child: Text(
                                              SporingCopy.a1_sporing_liga_gap(((leagueGap['points'] ?? 0) as num).toInt(), ((leagueGap['place'] ?? 0) as num).toInt()),
                                              style: inter(11, color: const Color(0xFF9FB6C2)),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (firstTime != null && firstTime > 0)
                              _StigOpp(
                                delay: 450,
                                child: Container(
                                  margin: const EdgeInsets.only(top: 12),
                                  padding: const EdgeInsets.only(top: 11),
                                  decoration: BoxDecoration(
                                    border: Border(top: BorderSide(color: rgba(255, 255, 255, .12))),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        clipBehavior: Clip.antiAlias,
                                        decoration: BoxDecoration(color: rgba(220, 233, 236, .15), borderRadius: BorderRadius.circular(10)),
                                        child: Image.asset('assets/images/aegil/voucher.png', fit: BoxFit.cover),
                                      ),
                                      const SizedBox(width: 11),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              SporingCopy.a1_sporing_forste_gang(firstTime.toInt(), butikk),
                                              style: inter(13, weight: FontWeight.w800, color: const Color(0xFFF2EFFA)),
                                            ),
                                            Text(SporingCopy.a1_sporing_en_gang, style: inter(11, color: const Color(0xFF9FB6C2))),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (lokale != null && lokale > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Row(
                                  children: [
                                    spIkon(kSpIkonFolk, size: 18, color: const Color(0xFF9FB6C2), width: 1.75, extra: kSpIkonFolkExtra),
                                    const SizedBox(width: 11),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            SporingCopy.a1_sporing_lokalt(butikk, lokale),
                                            key: const Key('a1_sporing_lokalt'),
                                            style: inter(12, height: 1.45, color: const Color(0xFFB9CBD5)),
                                          ),
                                          if (historie != null && historie.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 3),
                                              child: Text(
                                                historie,
                                                key: const Key('a1_sporing_historie'),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: inter(11, height: 1.4, color: const Color(0xFF9FB6C2)),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (codeConfirmed)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  decoration: BoxDecoration(
                    color: rgba(92, 224, 184, .14),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: rgba(92, 224, 184, .4)),
                  ),
                  child: Text(
                    SporingCopy.a1_sporing_levert_til_deg(byWhom),
                    key: const Key('a1_sporing_levert_til_deg'),
                    style: inter(13, weight: FontWeight.w800, color: kSpMint),
                  ),
                ),
              Row(
                children: [
                  if (visTakk) ...[
                    Expanded(
                      child: _Knapp(key: const Key('a1_sporing_takk'), tekst: SporingCopy.a1_sporing_takk(t.courier!.firstName), onTap: () => setState(() => _ark = _Ark.tips)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: _Knapp(
                      key: const Key('a1_sporing_vurder'),
                      tekst: _rated ? SporingCopy.a1_sporing_takk_sendt : SporingCopy.a1_sporing_hvordan,
                      onTap: _rated ? null : () => setState(() => _ark = _Ark.vurder),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LfPress(
                key: const Key('a1_sporing_noe_galt'),
                onTap: () => _hjelp(),
                scale: .99,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: rgba(255, 255, 255, .08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: rgba(255, 255, 255, .14)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          SporingCopy.a1_sporing_noe_galt,
                          style: inter(12.5, weight: FontWeight.w700, color: const Color(0xFFB9CBD5)),
                        ),
                      ),
                      spIkon(kSpIkonPilLiten, size: 13, color: const Color(0xFF9FB6C2)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              LfPress(
                key: const Key('a1_sporing_ferdig'),
                onTap: _ferdig,
                dy: 2,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: rgba(245, 243, 239, .94),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: rgba(0, 0, 0, .5), offset: const Offset(0, 10), blurRadius: 24, spreadRadius: -10)],
                  ),
                  child: Center(
                    child: Text(
                      SporingCopy.a1_sporing_ferdig,
                      style: inter(15, weight: FontWeight.w700, color: const Color(0xFF0F1F2B)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // The nav, no tab lit.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: BergenBottomNav(
            index: -1,
            merkMeg: false,
            onTab: (i) {
              Navigator.of(context).popUntil((r) => r.isFirst);
              context.findAncestorStateOfType<HomeMainV1State>()?.switchToTab(i);
            },
            cartCount: ValueNotifier<int>(0),
            onSearch: (_) => _ferdig(),
            onAegil: (_) => _ferdig(),
            showHint: false,
          ),
        ),
        if (_ark case final ark?)
          Positioned.fill(
            child: _LevertArk(
              ark: ark,
              navn: t.courier?.firstName ?? SporingCopy.a1_sporing_Budet,
              butikk: butikk,
              onLukk: () => setState(() => _ark = null),
              onTips: (kr) {
                setState(() => _ark = null);
                // UI-TEMP: Placeholder data because reference UI currently has no backend/API support —
                // there is no tipping endpoint; the sheet is checked visually only.
                showBergenToast(context, SporingCopy.a1_sporing_tips_sendt(kr, t.courier?.firstName ?? ''));
              },
              onAltStemte: () async {
                setState(() => _ark = null);
                await _rate(5);
                if (mounted) showBergenToast(context, SporingCopy.a1_sporing_takk_sendt);
              },
              onNoeGalt: () {
                setState(() => _ark = null);
                _hjelp(HjelpState.mangler);
              },
            ),
          ),
      ],
    );
  }
}

/// `stigOpp .5s` — translateY(26→0), opacity 0→1.
class _StigOpp extends StatelessWidget {
  const _StigOpp({required this.child, required this.delay});

  final Widget child;
  final double delay;

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: delay + 500,
    child: child,
    builder: (context, t, child) {
      final p = cssKlistre.transform(kfP(t, delay, 500));
      return Opacity(
        opacity: p.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, 26 * (1 - p)), child: child),
      );
    },
  );
}

/// The two 44 px glass keys («Takk til X», «Hvordan gikk det?»).
class _Knapp extends StatelessWidget {
  const _Knapp({super.key, required this.tekst, required this.onTap});

  final String tekst;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => LfPress(
    onTap: onTap,
    scale: .97,
    child: Container(
      height: 44,
      decoration: BoxDecoration(
        color: rgba(245, 243, 239, .16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: rgba(245, 243, 239, .3)),
      ),
      child: Center(
        child: Text(
          tekst,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: inter(12.5, weight: FontWeight.w800, color: const Color(0xFFF5F3EF)),
        ),
      ),
    ),
  );
}

/// The aurora: two soft bands skewing and drifting (`sway 8s` / `10s`).
class _Nordlys extends StatelessWidget {
  const _Nordlys();

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: SizedBox(
      width: 390,
      height: 300,
      child: Stack(
        children: [
          _band(8000, 0, 28, .4, const Offset(-20, 190), const [Offset(60, 130), Offset(140, 160), Offset(220, 110)], const [Offset(280, 76), Offset(340, 86), Offset(410, 52)]),
          _band(10000, 1200, 13, .35, const Offset(-20, 230), const [Offset(80, 180), Offset(160, 200), Offset(240, 155)], const [Offset(300, 122), Offset(360, 128), Offset(410, 100)]),
        ],
      ),
    ),
  );

  static Widget _band(double dur, double delay, double w, double a, Offset start, List<Offset> c1, List<Offset> c2) => Positioned.fill(
    child: LfLoop(
      builder: (context, t, child) {
        final e = t - delay;
        final p = e < 0 ? 0.0 : (e / dur) % 1.0;
        final sk = kf(p, const [0, .5, 1], const [-4, 3, -4], cssEaseInOut);
        final x = kf(p, const [0, .5, 1], const [0, 9, 0], cssEaseInOut);
        return Transform(alignment: Alignment.center, transform: Matrix4.skewX(rad(sk))..translateByDouble(x, 0, 0, 1), child: child);
      },
      child: Opacity(
        opacity: a,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: CustomPaint(
            painter: _NordlysPainter(w: w, start: start, c1: c1, c2: c2),
          ),
        ),
      ),
    ),
  );
}

class _NordlysPainter extends CustomPainter {
  const _NordlysPainter({required this.w, required this.start, required this.c1, required this.c2});

  final double w;
  final Offset start;
  final List<Offset> c1, c2;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(c1[0].dx, c1[0].dy, c1[1].dx, c1[1].dy, c1[2].dx, c1[2].dy)
      ..cubicTo(c2[0].dx, c2[0].dy, c2[1].dx, c2[1].dy, c2[2].dx, c2[2].dy);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(colors: [Color(0xFF5CE0B8), Color(0xFF9678DC), Color(0xFF5CE0B8)]).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// The Levert sheets (`kArk` tips / vurder): the paper sheet with its title,
/// line, rows and the «Ikke nå» key.
class _LevertArk extends StatelessWidget {
  const _LevertArk({required this.ark, required this.navn, required this.butikk, required this.onLukk, required this.onTips, required this.onAltStemte, required this.onNoeGalt});

  final _Ark ark;
  final String navn, butikk;
  final VoidCallback onLukk, onAltStemte, onNoeGalt;
  final ValueChanged<int> onTips;

  @override
  Widget build(BuildContext context) {
    final tips = ark == _Ark.tips;
    return Stack(
      key: Key(tips ? 'a1_sporing_ark_tips' : 'a1_sporing_ark_vurder'),
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onLukk,
            child: LfOnce(
              ms: 240,
              builder: (context, t, child) => Opacity(opacity: kfP(t, 0, 240), child: child),
              child: ColoredBox(color: rgba(8, 24, 32, .45)),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: LfOnce(
            ms: 300,
            builder: (context, t, child) {
              final p = cssSkjerm.transform(kfP(t, 0, 300));
              return Opacity(
                opacity: kf(p, const [0, .55, 1], const [0, 1, 1]),
                child: Transform(alignment: Alignment.bottomCenter, transform: Matrix4.translationValues(0, 14 * (1 - p), 0)..scaleByDouble(.978 + .022 * p, .978 + .022 * p, 1, 1), child: child),
              );
            },
            child: CssBox(
              radius: const BorderRadius.vertical(top: Radius.circular(28)),
              clip: true,
              bg: [CssSolid(rgba(245, 243, 239, .94))],
              shadows: [CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .95)), CssShadow(0, -30, 60, -20, rgba(8, 24, 32, .5))],
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(color: rgba(35, 32, 29, .16), borderRadius: BorderRadius.circular(999)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tips ? SporingCopy.a1_sporing_takk_til_budet : SporingCopy.a1_sporing_hvordan_gikk_leveringen, style: jakarta(19, em: -.02, color: kSpInk)),
                              const SizedBox(height: 3),
                              Text(tips ? SporingCopy.a1_sporing_tips_linje(navn) : SporingCopy.a1_sporing_ett_trykk(butikk, navn), style: inter(12.5, height: 1.45, color: const Color(0xFF57534B))),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        LfPress(
                          onTap: onLukk,
                          scale: .92,
                          child: CssBox(
                            width: 40,
                            height: 40,
                            radius: BorderRadius.circular(999),
                            bg: const [
                              CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFE9EEED)]),
                            ],
                            shadows: [CssShadow.inset(0, -3, 6, 0, rgba(30, 79, 92, .14)), CssShadow(0, 8, 14, -8, rgba(8, 24, 32, .45))],
                            child: Center(child: spIkon(kSpIkonKryss, size: 14, color: kSpTeal, width: 2.8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (tips)
                          for (final kr in const [20, 30, 50]) ...[
                            _Rad(key: Key('a1_sporing_tips_$kr'), navn: spKr(kr), under: SporingCopy.a1_sporing_tips_til(navn), onTap: () => onTips(kr)),
                            const SizedBox(height: 8),
                          ]
                        else ...[
                          _Rad(key: const Key('a1_sporing_alt_stemte'), navn: SporingCopy.a1_sporing_alt_stemte, under: '👍', onTap: onAltStemte),
                          const SizedBox(height: 8),
                          _Rad(key: const Key('a1_sporing_noe_var_galt'), navn: SporingCopy.a1_sporing_noe_var_galt, under: '→ ${SporingCopy.a1_sporing_noe_galt}', onTap: onNoeGalt),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                  if (tips)
                    Padding(
                      padding: EdgeInsets.fromLTRB(18, 2, 18, 18 + math.max(MediaQuery.paddingOf(context).bottom - 8, 0)),
                      child: LfPress(
                        key: const Key('a1_sporing_tips_ikke_naa'),
                        onTap: onLukk,
                        dy: 2,
                        child: CssBox(
                          height: 52,
                          radius: BorderRadius.circular(999),
                          bg: const [
                            CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFE9EEED)]),
                          ],
                          shadows: [CssShadow.inset(0, -3, 6, 0, rgba(30, 79, 92, .14)), CssShadow(0, 12, 18, -12, rgba(8, 24, 32, .5))],
                          child: Center(
                            child: Text(
                              SporingCopy.a1_sporing_ikke_naa,
                              style: inter(14, weight: FontWeight.w800, color: const Color(0xFF1B4A57)),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(height: 10 + math.max(MediaQuery.paddingOf(context).bottom - 8, 0)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A sheet row (`r.kort`): radius 20, the white rim, name and line, arrow.
class _Rad extends StatelessWidget {
  const _Rad({super.key, required this.navn, required this.under, required this.onTap});

  final String navn, under;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LfPress(
    onTap: onTap,
    dy: 1,
    child: CssBox(
      radius: BorderRadius.circular(20),
      padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
      bg: const [CssSolid(Color(0xFFFFFFFF))],
      shadows: [CssShadow(0, 0, 0, 1.5, rgba(35, 32, 29, .06)), CssShadow.inset(0, 1, 0, 0, rgba(255, 255, 255, .95)), CssShadow(0, 10, 18, -14, rgba(8, 24, 32, .45))],
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  navn,
                  style: inter(14, weight: FontWeight.w800, em: -.01, color: kSpInk),
                ),
                const SizedBox(height: 1),
                Text(under, style: inter(12, height: 1.4, color: const Color(0xFF6E6862))),
              ],
            ),
          ),
          CssBox(
            width: 30,
            height: 30,
            radius: BorderRadius.circular(999),
            bg: const [
              CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFE9EEED)]),
            ],
            shadows: [CssShadow.inset(0, -2, 4, 0, rgba(30, 79, 92, .14)), CssShadow(0, 4, 8, -4, rgba(8, 24, 32, .4))],
            child: Center(child: spIkon(kSpIkonPilLiten, size: 11, color: kSpTeal, width: 3)),
          ),
        ],
      ),
    ),
  );
}
