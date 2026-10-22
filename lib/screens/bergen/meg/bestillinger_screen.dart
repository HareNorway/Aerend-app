import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../networking/ops/cus_api.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../../../networking/ops/ops_kasse_api.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../aegil/aegil_bits.dart';
import '../hjelp/noe_galt_sheet.dart';
import '../hjelp/support.dart';
import '../hjem/hjem_harness.dart';
import '../hurtig/hurtig_glass.dart' show HbFlisInn;
import '../kit/bergen_kit.dart';
import '../kit/bergen_perf.dart';
import '../kit/butikk_bilder.dart';
import 'bestill_igjen.dart';
import 'meg_ark.dart';
import 'meg_nav.dart';

/// Ordrehistorikk (new Bergen `erOrdrer`, L8036–8089, + `ohVals` L15336):
/// the orders the customer has placed (`ops.customer.orders`), «Bestill igjen
/// · Dine faste» — the stores ordered from most, each with its banner, logo,
/// «N×» and the last order's sum on the key — then the orders by month, each
/// with the store's logo, code and day, the sum, the «+N poeng» it earned
/// (from the points ledger, when any), the item count and items, the status
/// (or «Sak løst») and «Bestill igjen». A tap opens the order in the dark Ark:
/// status and timeline, the three numbers, the receipt, the case and «Noe
/// galt». «Bestill igjen» only fills the basket; paying stays in Kurv.
class BestillingerScreen extends StatefulWidget {
  const BestillingerScreen({super.key, this.api, this.kasse, this.cus});

  final OpsCustomerApi? api;
  final OpsKasseApi? kasse;
  final CusApi? cus;

  @override
  State<BestillingerScreen> createState() => _BestillingerScreenState();
}

class _Ordre {
  _Ordre(this.raw);
  final Map<String, dynamic> raw;

  int get id => int.tryParse('${raw['order_id']}') ?? 0;
  String get kode => '${raw['code'] ?? ''}'.isEmpty ? 'Æ-$id' : '${raw['code']}';
  Map get store => raw['store'] is Map ? raw['store'] as Map : const {};
  int get storeId => (store['id'] as num?)?.toInt() ?? 0;
  String get butikk => '${store['name'] ?? ''}';
  DateTime get naar => DateTime.tryParse('${raw['ordered_at'] ?? ''}')?.toLocal() ?? DateTime.now();
  num get sum => (raw['total_pay'] as num?) ?? 0;
  num get levering => (raw['delivery_cost'] as num?) ?? 0;
  String get state => '${raw['state'] ?? ''}';
  String get stageLabel => '${raw['stage_label'] ?? ''}';
  bool get betalt => raw['paid'] == true;
  bool get levert => state == 'delivered' || state == 'completed';
  bool get avbestilt => state == 'cancelled';
  bool get aktiv => betalt && !levert && !avbestilt;

  /// How many of Bestilt · Bekreftet · Tilberedes · På vei · Levert are done,
  /// from the order's ops state. An unpaid order that is still under way
  /// (cash, or a payment not confirmed yet) is not «aktiv», but its sheet must
  /// not show it as delivered either.
  int get ferdigeSteg => switch (state) {
        'delivered' || 'completed' => 5,
        'picked_up' || 'arrived_customer' => 4,
        'seen' || 'ready' => 3,
        'accepted' => 2,
        _ => 1,
      };
  List<Map> get linjer => raw['items'] is List ? (raw['items'] as List).whereType<Map>().toList() : const [];
  int get antall => linjer.fold<int>(0, (a, l) => a + ((l['quantity'] ?? l['qty'] ?? 1) as num).toInt());
  String get varer => linjer.map((l) => '${l['name'] ?? ''}').where((x) => x.isNotEmpty).join(' · ');
}

/// What the status pill says and how it looks (`statusTx` / `statusBg` …).
class _Status {
  const _Status(this.tekst, {this.gull = false, this.ikon = _ikHake, this.oransje = false});
  final String tekst;
  final bool gull;
  final bool oransje;
  final String ikon;
}

const String _ikHake = 'M5 12.5l4.5 4.5L19 7.5';
const String _ikKryss = 'M7 7l10 10M17 7L7 17';
const String _ikSkjold = 'M12 3l7 3v5c0 4.5-3 8-7 9-4-1-7-4.5-7-9V6z M9 12l2 2 4-4';
const String _ikIgjen = 'M20 11a8 8 0 1 0-2.3 5.7 M20 4v7h-7';

class _BestillingerScreenState extends State<BestillingerScreen> {
  late final OpsCustomerApi _api = widget.api ?? OpsCustomerApi();
  late final OpsKasseApi _kasse = widget.kasse ?? OpsKasseApi();
  late final CusApi _cus = widget.cus ?? CusApi();

  /// Customer Step 10: the issue window per order, read when its sheet opens.
  final Map<int, CusIssueStatus?> _sakStatus = {};
  List<_Ordre> _ordrer = const [];
  final Map<int, int> _kroner = {};
  final Map<int, ButikkBilder> _bilder = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    // «Sak på ordren» reads the customer's cases from the server (Step 5).
    SupportStore.instance.oppdater();
  }

  Future<void> _load() async {
    final rows = await _api.orders(limit: 50);
    final ledger = await _api.pointsLedger();
    if (!mounted) return;
    final kr = <int, int>{};
    for (final e in ledger) {
      if ('${e['ref_type']}' != 'order') continue;
      final id = int.tryParse('${e['ref_id']}');
      final a = (e['amount'] as num?)?.toInt() ?? 0;
      if (id != null && a > 0) kr[id] = (kr[id] ?? 0) + a;
    }
    setState(() {
      _ordrer = [for (final r in rows) _Ordre(r)]..sort((a, b) => b.naar.compareTo(a.naar));
      _kroner
        ..clear()
        ..addAll(kr);
      _loading = false;
    });
    if (HjemHarness.ohOrdre case final id? when kDebugMode) {
      final noeGalt = HjemHarness.ohNoeGalt;
      HjemHarness.ohOrdre = null;
      HjemHarness.ohNoeGalt = false;
      final o = _ordrer.where((x) => x.id == id).firstOrNull;
      final sak = HjemHarness.ohSak;
      HjemHarness.ohSak = false;
      if (o != null) WidgetsBinding.instance.addPostFrameCallback((_) => noeGalt ? _noeGalt(o) : (sak ? _noeGalt(o) : _apne(o)));
    }
    // The logos and banners (the store page), a dozen stores at most.
    final ids = <int>[];
    for (final o in _ordrer) {
      if (o.storeId > 0 && !ids.contains(o.storeId)) ids.add(o.storeId);
    }
    final b = await ButikkBilder.alle(ids.take(12));
    if (mounted) setState(() => _bilder.addAll(b));
  }

  /// «Noe galt med bestillingen?» on [o] — the C2 sheet when the surface is
  /// on (Customer Step 10), else the plain three-step sheet.
  Future<void> _noeGalt(_Ordre o, {CusIssueStatus? status}) async {
    final issue = await noeGaltFlyt(
      context,
      ordre: SupportOrdre.fraRad(o.raw),
      api: _cus,
      status: status,
      linjer: [
        for (final l in o.linjer) (((l['quantity'] ?? l['qty'] ?? 1) as num).toInt(), '${l['name'] ?? ''}', (((l['unit_price'] as num?) ?? 0) * ((l['quantity'] ?? 1) as num)).round()),
      ],
    );
    if (issue != null && mounted) SupportStore.instance.settSak(issue);
  }

  /// «Ikke løst»: the case goes back to a person.
  Future<void> _ikkeLost(CusIssue i) async {
    final r = await _cus.issueReopen(i.id);
    if (!mounted) return;
    if (r != null) SupportStore.instance.settSak(r);
    showBergenToast(context, r == null ? BergenRoutes.provIgjen : CusIssueCopy.cus_sak_gjenaapnet);
  }

  /// «Bestill igjen»: the order's lines into the basket, then the basket
  /// (shared with Hjem's Vindu, `bestill_igjen.dart`).
  Future<void> _igjen(_Ordre o) => bestillIgjen(context, kasse: _kasse, storeId: o.storeId, butikk: o.butikk, linjer: [for (final l in o.linjer) Map<String, dynamic>.from(l)]);

  /// The order in the dark Ark (`kArk ordre`, L9861–9891).
  void _apne(_Ordre o) {
    if (o.aktiv) {
      BergenRoutes.push(context, '/bergen/sporing/${o.id}');
      return;
    }
    // Customer Step 10: the issue window and the case on this order (null → the surface is off).
    if (o.levert && !_sakStatus.containsKey(o.id)) {
      _cus.issueStatus(o.id).then((st) {
        if (!mounted) return;
        setState(() => _sakStatus[o.id] = st);
        if (st?.issue != null) SupportStore.instance.settSak(st!.issue!);
        SupportStore.instance.endret.value++;
      });
    }
    final kr = _kroner[o.id];
    final steg = o.avbestilt ? 1 : o.ferdigeSteg;
    final status = _status(o, medSak: false);
    showMegArk<void>(
      context,
      key: const Key('oh-ordre-sheet'),
      mork: true,
      title: '${o.kode} · ${o.butikk}',
      subtitle: OhCopy.arkLinje,
      body: (ctx, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatusKort(status: status.tekst, dato: OhCopy.dag(o.naar), ferdig: steg, avbestilt: o.avbestilt),
          const SizedBox(height: 10),
          _Tall(
            fliser: [
              (OhCopy.kr(o.sum.round()), o.betalt ? OhCopy.betalt : OhCopy.totalt.toLowerCase(), 0),
              if (kr != null) ('+$kr', OhCopy.kronerNavn, 1),
              (status.tekst, OhCopy.dag(o.naar), 2),
            ],
          ),
          const SizedBox(height: 10),
          _Kvittering(o: o),
          // Sak på ordren (L9883) and «Noe galt med bestillingen?» — with the C2
          // issue (Customer Step 10) when one exists; the entry row inside the window.
          ValueListenableBuilder<int>(
            valueListenable: SupportStore.instance.endret,
            builder: (context, _, _) {
              final issue = SupportStore.instance.issueFor(o.id);
              final sak = issue == null ? SupportStore.instance.sakFor(o.id) : null;
              final st = _sakStatus[o.id];
              final kanMelde = st == null ? !o.avbestilt : st.canReport;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (issue != null) ...[const SizedBox(height: 10), IssueSakRad(issue: issue, onIkkeLost: () => _ikkeLost(issue))],
                  if (sak != null) ...[const SizedBox(height: 10), SakPaaOrdren(sak: sak)],
                  if (kanMelde && (issue == null || issue.open)) ...[
                    const SizedBox(height: 10),
                    NoeGaltRad(
                      under: st == null ? null : CusIssueCopy.cus_sak_rad_under(st.slaMinutes),
                      onTap: () {
                        Navigator.of(context).pop();
                        _noeGalt(o, status: st);
                      },
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
      primary: MegArkButton(
        key: const Key('oh-ordre-igjen'),
        label: OhCopy.bestillIgjenSum(o.sum.round()),
        onTap: () {
          Navigator.of(context).pop();
          _igjen(o);
        },
      ),
    );
  }

  /// The pill: «Sak løst» (gold) for an order whose case is resolved; else
  /// the order's own status. The design's «· 89 kr tilbake» needs the credit,
  /// which the case does not carry, so it is left out.
  _Status _status(_Ordre o, {bool medSak = true}) {
    final sak = medSak ? SupportStore.instance.sakFor(o.id) : null;
    if (sak != null && sak.loest) return const _Status(OhCopy.sakLoest, gull: true, ikon: _ikSkjold);
    if (o.levert) return const _Status(OhCopy.levert);
    if (o.avbestilt) return const _Status(OhCopy.avbestilt, oransje: true, ikon: _ikKryss);
    return _Status(o.stageLabel.isEmpty ? OhCopy.paaVei : o.stageLabel);
  }

  @override
  Widget build(BuildContext context) {
    final O = _ordrer;
    final kr = _kroner.values.fold<int>(0, (a, b) => a + b);
    // Dine faste: the stores ordered from most (four at most).
    final tell = <int, List<_Ordre>>{};
    for (final o in O) {
      tell.putIfAbsent(o.storeId, () => []).add(o);
    }
    final faste = tell.values.toList()..sort((a, b) => b.length.compareTo(a.length));
    // By month, newest first.
    final grupper = <String, List<_Ordre>>{};
    for (final o in O) {
      grupper.putIfAbsent(OhCopy.maaned(o.naar), () => []).add(o);
    }
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
                  Positioned.fill(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator(color: BergenTokens.mint))
                        : ListenableBuilder(
                            listenable: SupportStore.instance.endret,
                            builder: (context, _) => ListView(
                              key: const Key('oh-list'),
                              padding: EdgeInsets.fromLTRB(16, top, 16, 130),
                              children: [
                                Align(alignment: Alignment.centerLeft, child: OhTilbake(onTap: () => Navigator.of(context).maybePop())),
                                const SizedBox(height: 14),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(OhCopy.tittel, style: jakarta(27, em: -.035)),
                                      const SizedBox(height: 3),
                                      Text(OhCopy.under(O.length, kr), key: const Key('oh-under'), style: inter(12.5, weight: FontWeight.w700, color: const Color(0xFFBFD6DC))),
                                    ],
                                  ),
                                ),
                                if (O.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 10),
                                    child: Column(
                                      children: [
                                        Image.asset(aePose('find'), width: 150, height: 150, fit: BoxFit.contain),
                                        const SizedBox(height: 10),
                                        Text(OhCopy.tom, style: jakarta(17)),
                                        const SizedBox(height: 10),
                                        SizedBox(width: 240, child: Text(OhCopy.tomSub, textAlign: TextAlign.center, style: inter(12.5, color: const Color(0xFFBFD6DC)))),
                                      ],
                                    ),
                                  )
                                else ...[
                                  const SizedBox(height: 20),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Row(
                                      children: [
                                        Flexible(child: Text(OhCopy.bestillIgjen, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, style: jakarta(18, em: -.02))),
                                        const SizedBox(width: 8),
                                        Container(
                                          key: const Key('oh-dine-faste'),
                                          height: 22,
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(999),
                                            color: const Color.fromRGBO(92, 224, 184, .18),
                                            border: Border.all(color: const Color.fromRGBO(92, 224, 184, .4)),
                                          ),
                                          child: Text(OhCopy.dineFaste, style: inter(11, weight: FontWeight.w800, color: const Color(0xFF7FF0CB))),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    height: 10 + 2 + _Fast.hoyde + 18,
                                    child: OverflowBox(
                                      maxWidth: 390,
                                      child: ListView(
                                        key: const Key('oh-faste'),
                                        scrollDirection: Axis.horizontal,
                                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                                        children: [
                                          for (final (i, l) in faste.take(4).indexed) ...[
                                            if (i > 0) const SizedBox(width: 10),
                                            HbFlisInn(
                                              delayMs: 60 + i * 80.0,
                                              child: _Fast(o: l.first, ganger: l.length, bilder: _bilder[l.first.storeId], onApne: () => _apne(l.first), onIgjen: () => _igjen(l.first)),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                  for (final g in grupper.entries) ...[
                                    const SizedBox(height: 4),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
                                      child: Row(
                                        children: [
                                          Flexible(child: Text(g.key.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, style: inter(11, weight: FontWeight.w800, em: .12, color: const Color(0xFF7FF0CB)))),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Container(
                                              height: 1,
                                              constraints: const BoxConstraints(minWidth: 12),
                                              decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color.fromRGBO(127, 240, 203, .4), Color.fromRGBO(127, 240, 203, 0)])),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            flex: 3,
                                            child: Text(
                                              '${OhCopy.antBestillinger(g.value.length)} · ${OhCopy.kr(g.value.fold<num>(0, (a, o) => a + o.sum).round())}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              softWrap: false,
                                              style: aeTab(inter(11.5, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .7))),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    for (final (i, o) in g.value.indexed) ...[
                                      if (i > 0) const SizedBox(height: 10),
                                      _OrdreKort(o: o, kroner: _kroner[o.id], bilder: _bilder[o.storeId], status: _status(o), onApne: () => _apne(o), onIgjen: () => _igjen(o)),
                                    ],
                                  ],
                                ],
                              ],
                            ),
                          ),
                  ),
                  const Positioned(left: 0, right: 0, bottom: 0, child: MegNav()),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The store tint (`farge`, by the store's name).
List<Color> _farge(String navn) {
  const pal = [
    [Color(0xFF4FA3B3), Color(0xFF1E4F5C)],
    [Color(0xFFF68450), Color(0xFFE65A28)],
    [Color(0xFF7FE6C6), Color(0xFF2FB893)],
    [Color(0xFF9DB8C4), Color(0xFF5E7F8C)],
    [Color(0xFFC7B59A), Color(0xFF8C7A5E)],
    [Color(0xFF6F86C9), Color(0xFF3A4E8C)],
  ];
  var h = 0;
  for (final c in navn.runes) {
    h = (h * 31 + c) % 997;
  }
  return pal[h % pal.length];
}

/// The kind icon on the tint when there is no logo (`KI`).
String _katIkon(String navn) {
  final n = navn.toLowerCase();
  if (RegExp(r'wok|thai').hasMatch(n)) return 'M4 11h16a8 8 0 0 1-16 0z M9 7l6-4 M12 7l6-3';
  if (RegExp(r'pizza|maria|napoli|trattoria').hasMatch(n)) return 'M12 3 21 20H3z M10 12v.01 M14 15v.01';
  return 'M3 13h18a9 9 0 0 1-18 0z M12 4v3';
}

/// The store's logo on white (80 %, contained), else the tint and its icon.
class _Logo extends StatelessWidget {
  const _Logo({required this.navn, required this.url, required this.size, required this.ikon});
  final String navn;
  final String? url;
  final double size;
  final double ikon;

  @override
  Widget build(BuildContext context) {
    final tint = DecoratedBox(
      decoration: BoxDecoration(gradient: LinearGradient(begin: const Alignment(-.34, -.94), end: const Alignment(.34, .94), colors: _farge(navn))),
      child: Center(child: AeIkon(_katIkon(navn), size: ikon, stroke: 2)),
    );
    return SizedBox(
      width: size,
      height: size,
      child: url == null
          ? tint
          : ColoredBox(
              color: Colors.white,
              child: Center(
                child: SizedBox(
                  width: size * .8,
                  height: size * .8,
                  child: CachedNetworkImage(imageUrl: url!, memCacheWidth: 160, fit: BoxFit.contain, errorWidget: (_, _, _) => tint, placeholder: (_, _) => const SizedBox.shrink()),
                ),
              ),
            ),
    );
  }
}

/// The glass card (`.14 → .05`, 1px white .16, the top light and the drop),
/// with CSS shadows (a Flutter `BoxShadow` would show through the glass).
Widget _glas({
  required double r,
  required Widget child,
  EdgeInsets? padding,
  double? width,
  double? height,
  bool clip = false,
  double topp = .24,
  double toppY = 1.5,
  CssShadow fall = const CssShadow(0, 18, 30, -20, Color.fromRGBO(0, 10, 16, .9)),
}) => CssBox(
  width: width,
  height: height,
  radius: BorderRadius.circular(r),
  clip: clip,
  padding: padding,
  bg: const [
    CssLinear(180, [Color.fromRGBO(255, 255, 255, .14), Color.fromRGBO(255, 255, 255, .05)]),
  ],
  border: Border.all(color: const Color.fromRGBO(255, 255, 255, .16)),
  shadows: [CssShadow.inset(0, toppY, 0, 0, Color.fromRGBO(255, 255, 255, topp)), fall],
  child: child,
);

/// The orange «↻ …» key (`o.igjen` / `f.igjen`): 13 round, the 3 px base.
class _Igjen extends StatelessWidget {
  const _Igjen({super.key, required this.tekst, required this.onTap, this.hoyde = 38, this.fontPx = 13, this.full = false});
  final String tekst;
  final VoidCallback onTap;
  final double hoyde;
  final double fontPx;
  final bool full;

  @override
  Widget build(BuildContext context) => AePress(
    onTap: onTap,
    dy: 2,
    child: CssBox(
      height: hoyde,
      radius: BorderRadius.circular(13),
      bg: const [
        CssLinear(180, [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], [0, .56, 1]),
      ],
      shadows: const [
        CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .45)),
        CssShadow(0, 3, 0, 0, Color.fromRGBO(160, 60, 20, .6)),
        CssShadow(0, 12, 20, -10, Color.fromRGBO(242, 109, 61, .8)),
      ],
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisSize: full ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AeIkon(_ikIgjen, size: 14, stroke: 2.6),
          const SizedBox(width: 6),
          Text(tekst, style: aeTab(inter(fontPx, weight: FontWeight.w800))),
        ],
      ),
    ),
  );
}

/// A «Dine faste» card (168 wide, L8053–8067): the banner (or the tint),
/// «↻ N×», the logo over the banner's edge, name, items and the sum key.
class _Fast extends StatelessWidget {
  const _Fast({required this.o, required this.ganger, required this.bilder, required this.onApne, required this.onIgjen});
  final _Ordre o;
  final int ganger;
  final ButikkBilder? bilder;
  final VoidCallback onApne;
  final VoidCallback onIgjen;

  static const double hoyde = 206;

  @override
  Widget build(BuildContext context) {
    final banner = bilder?.banner;
    return AePress(
      onTap: onApne,
      dy: 0,
      scale: .98,
      child: _glas(
        r: 22,
        width: 168,
        height: hoyde,
        clip: true,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 64,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: const Alignment(-.34, -.94), end: const Alignment(.34, .94), colors: _farge(o.butikk)))),
                      if (banner != null)
                        // `bpKB 16s ease-in-out infinite alternate` (rests in lite / still).
                        LfLoop(
                          builder: (context, t, child) {
                            final ping = (t / 16000) % 2;
                            final p = cssEaseInOut.transform(ping <= 1 ? ping : 2 - ping);
                            return Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..scaleByDouble(1.04 + .13 * p, 1.04 + .13 * p, 1, 1)
                                ..translateByDouble(-.025 * 168 * p, -.02 * 64 * p, 0, 1),
                              child: child,
                            );
                          },
                          child: CachedNetworkImage(imageUrl: banner, memCacheWidth: BergenPerf.decodeWidth, fit: BoxFit.cover, errorWidget: (_, _, _) => const SizedBox.shrink()),
                        ),
                      const DecoratedBox(
                        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.fromRGBO(10, 26, 34, 0), Color.fromRGBO(10, 26, 34, .5)])),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          height: 22,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: const Color.fromRGBO(10, 26, 34, .5),
                            border: Border.all(color: const Color.fromRGBO(255, 255, 255, .2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const AeIkon(_ikIgjen, size: 11, stroke: 2.6, color: Color(0xFF7FF0CB)),
                              const SizedBox(width: 4),
                              Text('$ganger×', style: aeTab(inter(11, weight: FontWeight.w800))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 22 + 6, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(o.butikk, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, style: inter(14.5, weight: FontWeight.w800, em: -.01)),
                        const SizedBox(height: 1),
                        SizedBox(
                          height: 31,
                          child: Text(o.varer, maxLines: 2, overflow: TextOverflow.clip, style: inter(11.5, weight: FontWeight.w600, height: 1.35, color: const Color.fromRGBO(255, 255, 255, .7))),
                        ),
                        const Spacer(),
                        _Igjen(key: Key('oh-fast-${o.storeId}'), tekst: OhCopy.kr(o.sum.round()), onTap: onIgjen, hoyde: 40, fontPx: 13.5, full: true),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // The logo over the banner's edge (`margin-top: -22px`).
            Positioned(
              left: 12,
              top: 64 - 22,
              child: CssBox(
                width: 44,
                height: 44,
                radius: BorderRadius.circular(14),
                clip: true,
                border: Border.all(color: const Color(0xFF1F5463), width: 3),
                shadows: const [CssShadow(0, 8, 14, -8, Color.fromRGBO(0, 10, 16, .9))],
                child: _Logo(navn: o.butikk, url: bilder?.logo, size: 38, ikon: 19),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// An order (L8069–8086).
class _OrdreKort extends StatelessWidget {
  const _OrdreKort({required this.o, required this.kroner, required this.bilder, required this.status, required this.onApne, required this.onIgjen});
  final _Ordre o;
  final int? kroner;
  final ButikkBilder? bilder;
  final _Status status;
  final VoidCallback onApne;
  final VoidCallback onIgjen;

  @override
  Widget build(BuildContext context) {
    final (bg, bd, c, ikBg, ikC) = status.gull
        ? (const Color.fromRGBO(242, 193, 78, .14), const Color.fromRGBO(242, 193, 78, .4), const Color(0xFFFFD98A), const [Color(0xFFFFE08A), Color(0xFFF2C14E)], const Color(0xFF5E4318))
        : status.oransje
        ? (const Color.fromRGBO(242, 109, 61, .16), const Color.fromRGBO(242, 109, 61, .45), const Color(0xFFFFB08A), const [Color(0xFFFFC29E), Color(0xFFF26D3D)], Colors.white)
        : (const Color.fromRGBO(92, 224, 184, .14), const Color.fromRGBO(92, 224, 184, .4), const Color(0xFF7FF0CB), const [Color(0xFFB4F9E2), Color(0xFF5CE0B8)], const Color(0xFF0F2B33));
    return AePress(
      key: Key('oh-ordre-${o.id}'),
      onTap: onApne,
      dy: 0,
      scale: .99,
      child: _glas(
        r: 22,
        padding: const EdgeInsets.all(12),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(color: Color.fromRGBO(255, 255, 255, .18), spreadRadius: 1),
                        BoxShadow(color: Color.fromRGBO(0, 10, 16, .9), offset: Offset(0, 8), blurRadius: 14 / 2 / .57735, spreadRadius: -8),
                      ],
                    ),
                    child: _Logo(navn: o.butikk, url: bilder?.logo, size: 48, ikon: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o.butikk, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, style: inter(15, weight: FontWeight.w800, em: -.01)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(o.kode, style: aeTab(inter(12, weight: FontWeight.w600, color: const Color.fromRGBO(255, 255, 255, .66)))),
                            const SizedBox(width: 6),
                            Container(width: 3, height: 3, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color.fromRGBO(255, 255, 255, .45))),
                            const SizedBox(width: 6),
                            Flexible(child: Text(OhCopy.dag(o.naar), maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, style: inter(12, weight: FontWeight.w600, color: const Color.fromRGBO(255, 255, 255, .66)))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(OhCopy.kr(o.sum.round()), style: aeTab(inter(17, weight: FontWeight.w800, em: -.02))),
                      if (kroner != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          height: 22,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.fromRGBO(255, 224, 138, .22), Color.fromRGBO(242, 193, 78, .14)]),
                            border: Border.all(color: const Color.fromRGBO(242, 193, 78, .45)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const AeIkon('M12 3l2.6 5.3 5.9.9-4.3 4.1 1 5.8L12 16.4 6.8 19.1l1-5.8L3.5 9.2l5.9-.9z', size: 11, stroke: 0, fill: Color(0xFFF2C14E)),
                              const SizedBox(width: 4),
                              Text(OhCopy.kroner(kroner!), style: inter(11, weight: FontWeight.w800, color: const Color(0xFFFFD98A))),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    height: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color.fromRGBO(255, 255, 255, .08),
                      border: Border.all(color: const Color.fromRGBO(255, 255, 255, .12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AeIkon('M5 7h14l-1.3 11H6.3z M9 7V5.5a3 3 0 0 1 6 0V7', size: 11, stroke: 2.4, color: Color(0xFFDCE9EC)),
                        const SizedBox(width: 4),
                        Text(OhCopy.antVarer(o.antall), style: inter(11, weight: FontWeight.w800, color: const Color(0xFFDCE9EC))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(child: Text(o.varer, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, style: inter(12.5, weight: FontWeight.w600, color: const Color(0xFFDCE9EC)))),
                ],
              ),
              Container(height: 1, margin: const EdgeInsets.only(top: 10), color: const Color.fromRGBO(255, 255, 255, .1)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                      key: Key('oh-status-${o.id}'),
                      height: 30,
                      padding: const EdgeInsets.fromLTRB(4, 0, 10, 0),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: bg, border: Border.all(color: bd)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: ikBg)),
                            alignment: Alignment.center,
                            child: AeIkon(status.ikon, size: 11, stroke: 3, color: ikC),
                          ),
                          const SizedBox(width: 6),
                          Flexible(child: Text(status.tekst, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, style: inter(11.5, weight: FontWeight.w800, color: c))),
                        ],
                      ),
                    ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Igjen(key: Key('oh-igjen-${o.id}'), tekst: OhCopy.bestillIgjen, onTap: onIgjen),
                ],
              ),
            ],
        ),
      ),
    );
  }
}

/// The dark sheet's glass card (`.14 → .05`, white .16, top light .22).
Widget _arkKort({required Widget child, EdgeInsets padding = const EdgeInsets.fromLTRB(14, 12, 14, 14), double r = 22, Clip clip = Clip.none}) => _glas(
  r: r,
  padding: padding,
  clip: clip != Clip.none,
  topp: .22,
  toppY: 1,
  fall: const CssShadow(0, 12, 20, -14, Color.fromRGBO(0, 10, 16, .85)),
  child: child,
);

/// «Ordre · status» (L9862): the mint glow, the status chip and the day, and
/// the five steps on the rail (`ordFyll .9s .15s`, steps `bpFlisInn`).
class _StatusKort extends StatelessWidget {
  const _StatusKort({required this.status, required this.dato, required this.ferdig, required this.avbestilt});
  final String status;
  final String dato;
  final int ferdig;
  final bool avbestilt;

  @override
  Widget build(BuildContext context) => _arkKort(
    padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
    clip: Clip.antiAlias,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        const Positioned(
          left: 0,
          right: 0,
          top: -54,
          child: Center(
            child: SizedBox(
              width: 240,
              height: 90,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.elliptical(120, 45)),
                  gradient: RadialGradient(colors: [Color.fromRGBO(92, 224, 184, .32), Color.fromRGBO(92, 224, 184, 0)]),
                ),
              ),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Container(
                    height: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: avbestilt ? const Color.fromRGBO(242, 109, 61, .18) : const Color.fromRGBO(92, 224, 184, .18),
                      border: Border.all(color: avbestilt ? const Color.fromRGBO(242, 109, 61, .45) : const Color.fromRGBO(92, 224, 184, .45)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: avbestilt ? const Color(0xFFF26D3D) : const Color(0xFF5CE0B8),
                            boxShadow: [BoxShadow(color: avbestilt ? const Color(0xFFF26D3D) : const Color(0xFF5CE0B8), blurRadius: 8 / 2 / .57735)],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(status, style: inter(12, weight: FontWeight.w800, color: avbestilt ? const Color(0xFFFFB08A) : const Color(0xFF7FF0CB))),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(dato, style: inter(12, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .66))),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 30 + 6 + 16,
              child: Stack(
                children: [
                  Positioned(
                    left: 2 + 26,
                    right: 2 + 26,
                    top: 13,
                    height: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: ColoredBox(
                        color: const Color.fromRGBO(255, 255, 255, .12),
                        child: LfOnce(
                          ms: 1050,
                          builder: (context, t, child) => FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: ((ferdig - 1) / 4).clamp(0.0, 1.0) * const Cubic(.2, .8, .2, 1).transform(kfP(t, 150, 900)),
                            child: child,
                          ),
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(999)),
                              gradient: LinearGradient(colors: [Color(0xFF7FF0CB), Color(0xFF5CE0B8)]),
                              boxShadow: [BoxShadow(color: Color.fromRGBO(92, 224, 184, .6), blurRadius: 10 / 2 / .57735)],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (final (i, s) in OhCopy.tid.indexed)
                            HbFlisInn(
                              ms: 450,
                              delayMs: 80 + i * 70.0,
                              child: SizedBox(
                                width: 56,
                                child: Column(
                                  children: [
                                    Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: i < ferdig ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB4F9E2), Color(0xFF5CE0B8)]) : null,
                                        color: i < ferdig ? null : const Color(0xFF2A5866),
                                        border: Border.all(color: const Color(0xFF1B4A57), width: 3),
                                        boxShadow: i < ferdig ? const [BoxShadow(color: Color.fromRGBO(92, 224, 184, .55), blurRadius: 12 / 2 / .57735)] : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: i < ferdig ? const AeIkon(_ikHake, size: 12, stroke: 3.6, color: Color(0xFF0F2B33)) : null,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      s,
                                      maxLines: 1,
                                      softWrap: false,
                                      overflow: TextOverflow.visible,
                                      style: inter(10.5, weight: FontWeight.w800, color: i == 4 && ferdig >= 5 ? const Color(0xFF7FF0CB) : const Color.fromRGBO(255, 255, 255, .78)),
                                    ),
                                  ],
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
          ],
        ),
      ],
    ),
  );
}

/// «Ordre · tall» (L9869): betalt, the points, the status — three glass tiles.
class _Tall extends StatelessWidget {
  const _Tall({required this.fliser});

  /// (number, label, kind 0 betalt / 1 points / 2 status).
  final List<(String, String, int)> fliser;

  static const List<(String, List<Color>, Color, Color, Color)> _slag = [
    ('M3 7h18v10H3z M3 11h18 M7 15h3', [Colors.white, Color(0xFFF2EFE8)], kAeTeal, Colors.white, Color.fromRGBO(255, 255, 255, .3)),
    ('M12 3l2.6 5.3 5.9.9-4.3 4.1 1 5.8L12 16.4 6.8 19.1l1-5.8L3.5 9.2l5.9-.9z', [Color(0xFFFFE08A), Color(0xFFF2C14E), Color(0xFFD49528)], Color(0xFF5E4318), Color(0xFFFFD98A), Color.fromRGBO(242, 193, 78, .45)),
    (_ikHake, [Color(0xFFB4F9E2), Color(0xFF5CE0B8)], Color(0xFF0F2B33), Color(0xFF7FF0CB), Color.fromRGBO(92, 224, 184, .45)),
  ];

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final (i, (n, navn, k)) in fliser.indexed) ...[
        if (i > 0) const SizedBox(width: 6),
        Expanded(
          child: HbFlisInn(
            delayMs: 120 + i * 80.0,
            child: _arkKort(
              r: 16,
              clip: Clip.antiAlias,
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 9),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Positioned(
                    top: -28,
                    child: SizedBox(
                      width: 60,
                      height: 40,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(Radius.elliptical(30, 20)),
                          gradient: RadialGradient(colors: [_slag[k].$5, const Color.fromRGBO(0, 0, 0, 0)]),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: _slag[k].$2),
                          boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 10, 16, .7), offset: Offset(0, 4), blurRadius: 8 / 2 / .57735, spreadRadius: -4)],
                        ),
                        alignment: Alignment.center,
                        child: AeIkon(_slag[k].$1, size: 15, stroke: 2.3, color: _slag[k].$3),
                      ),
                      const SizedBox(height: 5),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(n, maxLines: 1, softWrap: false, style: aeTab(inter(16, weight: FontWeight.w800, em: -.02, height: 1, color: _slag[k].$4))),
                      ),
                      const SizedBox(height: 5),
                      Text(navn, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, style: inter(10.5, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .7))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ],
  );
}

/// «Ordre · kvittering» (L9872): the receipt key, «Kvittering · N varer fra
/// …», the lines with their count chips, Levering, the dashed rule, Totalt.
class _Kvittering extends StatelessWidget {
  const _Kvittering({required this.o});
  final _Ordre o;

  @override
  Widget build(BuildContext context) {
    final varer = o.sum - o.levering;
    return _arkKort(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFF2EFE8)]),
                  boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 10, 16, .7), offset: Offset(0, 4), blurRadius: 8 / 2 / .57735, spreadRadius: -4)],
                ),
                alignment: Alignment.center,
                child: const AeIkon('M6 3h12v18l-3-2-3 2-3-2-3 2z M9 8h6 M9 12h6', size: 16, stroke: 2.3, color: kAeTeal),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(OhCopy.kvittering, style: inter(14, weight: FontWeight.w800)),
                    Text(OhCopy.antFra(o.linjer.length, o.butikk), maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(11.5, weight: FontWeight.w600, color: const Color.fromRGBO(255, 255, 255, .62))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final l in o.linjer)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Container(
                    constraints: const BoxConstraints(minWidth: 30),
                    height: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      color: const Color.fromRGBO(92, 224, 184, .16),
                      border: Border.all(color: const Color.fromRGBO(92, 224, 184, .4)),
                    ),
                    child: Text('${((l['quantity'] ?? l['qty'] ?? 1) as num).toInt()}', style: aeTab(inter(12, weight: FontWeight.w800, color: const Color(0xFF7FF0CB)))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text('${l['name'] ?? ''}', style: inter(14, weight: FontWeight.w700, height: 1.3))),
                  const SizedBox(width: 10),
                  Text(OhCopy.kr((((l['unit_price'] ?? 0) as num) * ((l['quantity'] ?? 1) as num)).round()), style: aeTab(inter(14, weight: FontWeight.w800))),
                ],
              ),
            ),
          if (o.levering > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      color: const Color.fromRGBO(255, 255, 255, .08),
                      border: Border.all(color: const Color.fromRGBO(255, 255, 255, .14)),
                    ),
                    child: const AeIkon(
                      'M5.5 17.5a2.5 2.5 0 1 0 0-.01 M18.5 17.5a2.5 2.5 0 1 0 0-.01 M8 17.5h7.5 M15.5 17.5 13 9h-3 M13 9l2.5-3h2.5 M5.5 17.5 9 11h5.5',
                      size: 15,
                      stroke: 2.2,
                      color: Color(0xFFDCE9EC),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(OhCopy.levering, style: inter(13.5, weight: FontWeight.w600, color: const Color.fromRGBO(255, 255, 255, .75)))),
                  Text(OhCopy.kr(o.levering.round()), style: aeTab(inter(13.5, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .8)))),
                ],
              ),
            ),
          const SizedBox(height: 12),
          CustomPaint(painter: _Stiplet(), child: const SizedBox(height: 1)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: Text(OhCopy.totalt, style: inter(14, weight: FontWeight.w800))),
              Text(OhCopy.kr((o.sum > varer ? o.sum : varer).round()), style: aeTab(inter(26, weight: FontWeight.w800, em: -.02))),
            ],
          ),
        ],
      ),
    );
  }
}

/// `border-top: 1px dashed rgba(255,255,255,.22)`.
class _Stiplet extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color.fromRGBO(255, 255, 255, .22)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 6) {
      canvas.drawLine(Offset(x, .5), Offset((x + 3).clamp(0, size.width), .5), p);
    }
  }

  @override
  bool shouldRepaint(_Stiplet old) => false;
}

/// The glass back key of the history and the league.
class OhTilbake extends StatelessWidget {
  const OhTilbake({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AePress(
    key: const Key('oh-tilbake'),
    onTap: onTap,
    dy: 0,
    scale: .94,
    child: const CssBox(
      width: 40,
      height: 40,
      radius: BorderRadius.all(Radius.circular(999)),
      bg: [
        CssLinear(180, [Color.fromRGBO(255, 255, 255, .24), Color.fromRGBO(255, 255, 255, .08)]),
      ],
      shadows: [
        CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .38)),
        CssShadow.inset(0, -2, 4, 0, Color.fromRGBO(0, 0, 0, .22)),
        CssShadow(0, 8, 14, -8, Color.fromRGBO(0, 0, 0, .6)),
      ],
      child: Center(child: AeIkon('M15 6l-6 6 6 6', size: 15, stroke: 2.2, color: Color(0xFFF5F3EF))),
    ),
  );
}

/// Copy for Ordrehistorikk.
abstract final class OhCopy {
  static const String tittel = 'Ordrehistorikk';
  static String under(int n, int kr) => kr > 0 ? '${antBestillinger(n)} · ${_nf(kr)} Ærend Poeng opptjent' : antBestillinger(n);
  static const String tom = 'Ingen bestillinger ennå';
  static const String tomSub = 'Når du har bestilt, ligger alt her, klart til å bestilles igjen.';
  static const String bestillIgjen = 'Bestill igjen';
  static const String dineFaste = 'Dine faste';
  static String bestillIgjenSum(int kr) => 'Bestill igjen · ${_nf(kr)} kr';
  static String antBestillinger(int n) => '$n ${n == 1 ? 'bestilling' : 'bestillinger'}';
  static String antVarer(int n) => '$n ${n == 1 ? 'vare' : 'varer'}';
  static String antFra(int n, String butikk) => '${antVarer(n)} fra $butikk';
  static String kr(int n) => '${_nf(n)} kr';
  static String kroner(int n) => '+$n poeng';
  static const String kronerNavn = 'Ærend-kroner';
  static const String betalt = 'betalt';
  static const String arkLinje = 'Kvittering og status for bestillingen';
  static const String levert = 'Levert';
  static const String avbestilt = 'Avbestilt';
  static const String paaVei = 'På vei';
  static const String sakLoest = 'Sak løst';
  static const String kvittering = 'Kvittering';
  static const String levering = 'Levering';
  static const String totalt = 'Totalt';
  static const List<String> tid = ['Bestilt', 'Bekreftet', 'Tilberedes', 'På vei', 'Levert'];
  static String lagtIKurven(int n, String butikk) => '$n ${n == 1 ? 'linje' : 'linjer'} fra $butikk lagt i kurven';

  static const List<String> _mnd = ['Januar', 'Februar', 'Mars', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Desember'];
  static const List<String> _dag = ['mandag', 'tirsdag', 'onsdag', 'torsdag', 'fredag', 'lørdag', 'søndag'];
  static const List<String> _mndKort = ['jan.', 'feb.', 'mars', 'apr.', 'mai', 'juni', 'juli', 'aug.', 'sep.', 'okt.', 'nov.', 'des.'];

  static String maaned(DateTime d) => DateTime.now().year == d.year ? _mnd[d.month - 1] : '${_mnd[d.month - 1]} ${d.year}';

  /// «i dag», «i går», «tirsdag», «forrige tirsdag», «12. sep.».
  static String dag(DateTime d) {
    final n = DateTime.now();
    final idag = DateTime(n.year, n.month, n.day);
    final dd = DateTime(d.year, d.month, d.day);
    final diff = idag.difference(dd).inDays;
    if (diff <= 0) return 'i dag';
    if (diff == 1) return 'i går';
    if (diff < 7) return _dag[d.weekday - 1];
    if (diff < 14) return 'forrige ${_dag[d.weekday - 1]}';
    return '${d.day}. ${_mndKort[d.month - 1]}';
  }

  static String _nf(int n) {
    final s = n.abs().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
      b.write(s[i]);
    }
    return n < 0 ? '-$b' : '$b';
  }
}
