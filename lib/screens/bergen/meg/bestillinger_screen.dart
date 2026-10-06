import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../networking/ops/ops_customer_api.dart';
import '../../../networking/ops/ops_kasse_api.dart';
import '../../../utils/utils.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/homeMainV1/home_main_v1.dart';
import '../../deliveryService/storeDetail/store_detail_repo.dart';
import '../aegil/aegil_bits.dart';
import '../kit/bergen_kit.dart';
import 'meg_ark.dart';
import 'meg_nav.dart';

/// Ordrehistorikk (`erOrdrer`, L7841–7896 in `Ærend Kunde Launch.dc.html`,
/// design px): the orders the customer has placed (`ops.customer.orders`),
/// «Bestill igjen · Dine faste» — the stores ordered from most, floating —
/// then the orders by month, each with its store tile, code and day, the sum,
/// the Ærend-kroner it earned (from the points ledger, when any), the items,
/// the status and «Bestill igjen». A tap opens the order: the timeline and the
/// receipt. «Bestill igjen» only fills the basket; paying stays in Kurv.
class BestillingerScreen extends StatefulWidget {
  const BestillingerScreen({super.key, this.api, this.kasse});

  final OpsCustomerApi? api;
  final OpsKasseApi? kasse;

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
  bool get levert => state == 'delivered' || state == 'completed';
  bool get avbestilt => state == 'cancelled';
  bool get aktiv => raw['paid'] == true && !levert && !avbestilt;
  List<Map> get linjer => raw['items'] is List ? (raw['items'] as List).whereType<Map>().toList() : const [];
  int get antall => linjer.fold<int>(0, (a, l) => a + ((l['quantity'] ?? l['qty'] ?? 1) as num).toInt());
  String get varer => linjer.map((l) => '${l['name'] ?? ''}').where((x) => x.isNotEmpty).join(' · ');
}

class _BestillingerScreenState extends State<BestillingerScreen> {
  late final OpsCustomerApi _api = widget.api ?? OpsCustomerApi();
  late final OpsKasseApi _kasse = widget.kasse ?? OpsKasseApi();
  List<_Ordre> _ordrer = const [];
  final Map<int, int> _kroner = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
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
  }

  /// «Bestill igjen»: the order's lines into the basket, then the basket. The
  /// basket holds one store, so another store's lines make way.
  Future<void> _igjen(_Ordre o) async {
    var cart = await _kasse.cart();
    if (!cart.isEmpty && cart.storeId != o.storeId) {
      for (final l in cart.lines) {
        await _kasse.remove(l.cartId);
      }
    }
    for (final l in o.linjer) {
      final pid = (l['product_id'] as num?)?.toInt();
      if (pid == null) continue;
      prefSetInt('checkedSize', 0);
      prefSetInt('checkedColor', 0);
      prefSetString('checkedOptionList', jsonEncode(const <int>[]));
      try {
        await StoreDetailRepo().callOrderCartApi(o.storeId, pid, ((l['quantity'] ?? 1) as num).toInt());
      } catch (_) {}
    }
    cart = await _kasse.cart();
    if (!mounted) return;
    prefSetInt(prefCartCount, cart.lines.length);
    BergenCart.syncBadge(context, cart.lines.length);
    if (cart.isEmpty) {
      showBergenToast(context, BergenRoutes.kommerSnart);
      return;
    }
    showBergenToast(context, OhCopy.lagtIKurven(o.linjer.length, o.butikk));
    final shell = HomeMainV1State.current;
    Navigator.of(context).popUntil((r) => r.isFirst);
    shell?.switchToTab(2);
  }

  void _apne(_Ordre o) {
    if (o.aktiv) {
      BergenRoutes.push(context, '/bergen/sporing/${o.id}');
      return;
    }
    final kr = _kroner[o.id];
    final steg = o.avbestilt ? 1 : 5;
    showMegArk<void>(
      context,
      key: const Key('oh-ordre-sheet'),
      title: '${o.kode} · ${o.butikk}',
      subtitle: [OhCopy.dag(o.naar), _status(o).$1, if (kr != null) OhCopy.kronerLinje(kr)].join(' · '),
      body: (ctx, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Tidslinje(ferdig: steg),
          const SizedBox(height: 8),
          _Kvittering(o: o),
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

  (String, Color, Color) _status(_Ordre o) {
    if (o.levert) return (OhCopy.levert, const Color.fromRGBO(92, 224, 184, .16), const Color(0xFF7FF0CC));
    if (o.avbestilt) return (OhCopy.avbestilt, const Color.fromRGBO(242, 109, 61, .2), const Color(0xFFFFB08A));
    return (o.stageLabel.isEmpty ? OhCopy.paaVei : o.stageLabel, const Color.fromRGBO(92, 224, 184, .16), const Color(0xFF7FF0CC));
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
                        : ListView(
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
                                const SizedBox(height: 22),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Expanded(child: Text(OhCopy.bestillIgjen, style: jakarta(17, em: -.02))),
                                      Text(OhCopy.dineFaste, style: inter(11.5, weight: FontWeight.w700, color: const Color(0xFF9FC2CC))),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: 8 + 10 + 149 + 26,
                                  child: OverflowBox(
                                    maxWidth: 390,
                                    child: ListView(
                                      key: const Key('oh-faste'),
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 26),
                                      children: [
                                        for (final (i, l) in faste.take(4).indexed) ...[
                                          if (i > 0) const SizedBox(width: 12),
                                          _Fast(o: l.first, ganger: l.length, delayMs: i * 900.0, onApne: () => _apne(l.first), onIgjen: () => _igjen(l.first)),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                for (final g in grupper.entries) ...[
                                  const SizedBox(height: 6),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Expanded(child: Text(g.key.toUpperCase(), style: inter(11, weight: FontWeight.w800, em: .12, color: const Color(0xFF7FF0CC)))),
                                        Text(
                                          '${OhCopy.antBestillinger(g.value.length)} · ${OhCopy.kr(g.value.fold<num>(0, (a, o) => a + o.sum).round())}',
                                          style: aeTab(inter(11, weight: FontWeight.w700, color: const Color(0xFF9FC2CC))),
                                        ),
                                      ],
                                    ),
                                  ),
                                  for (final (i, o) in g.value.indexed) ...[
                                    if (i > 0) const SizedBox(height: 12),
                                    _OrdreKort(o: o, kroner: _kroner[o.id], status: _status(o), onApne: () => _apne(o), onIgjen: () => _igjen(o)),
                                  ],
                                ],
                              ],
                            ],
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

/// The store tile colour (`PAL`, by the store's name).
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

class _Tile extends StatelessWidget {
  const _Tile({required this.navn, required this.size, required this.r, required this.font});
  final String navn;
  final double size;
  final double r;
  final double font;

  @override
  Widget build(BuildContext context) => CssBox(
    width: size,
    height: size,
    radius: BorderRadius.circular(r),
    bg: [CssLinear(160, _farge(navn))],
    shadows: const [
      CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .35)),
      CssShadow.inset(0, -3, 5, 0, Color.fromRGBO(0, 0, 0, .22)),
      CssShadow(0, 8, 12, -6, Color.fromRGBO(3, 14, 20, .7)),
    ],
    child: Center(
      child: Text(navn.isEmpty ? '?' : navn.characters.first, style: jakarta(font).copyWith(shadows: const [Shadow(color: Color.fromRGBO(0, 0, 0, .2), offset: Offset(0, 1), blurRadius: 1)])),
    ),
  );
}

const List<CssBg> _glass = [
  CssLinear(180, [Color.fromRGBO(255, 255, 255, .16), Color.fromRGBO(255, 255, 255, .06)]),
];
const List<CssShadow> _glassSh = [
  CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .3)),
  CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .1)),
  CssShadow(0, 18, 28, -18, Color.fromRGBO(3, 14, 20, .8)),
];

/// The orange «+ N kr» / «+ Bestill igjen» key.
class _Igjen extends StatelessWidget {
  const _Igjen({super.key, required this.tekst, required this.onTap, this.full = false});
  final String tekst;
  final VoidCallback onTap;
  final bool full;

  @override
  Widget build(BuildContext context) => AePress(
    onTap: onTap,
    child: CssBox(
      height: 36,
      radius: BorderRadius.circular(999),
      bg: const [
        CssLinear(180, [Color(0xFFF68450), Color(0xFFE65A28)]),
      ],
      shadows: const [
        CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .4)),
        CssShadow.inset(0, -3, 6, 0, Color.fromRGBO(150, 40, 10, .3)),
      ],
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisSize: full ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AeIkon('M12 5v14M5 12h14', size: 11, stroke: 3.2),
          const SizedBox(width: 5),
          Text(tekst, style: aeTab(inter(full ? 12.5 : 12, weight: FontWeight.w800))),
        ],
      ),
    ),
  );
}

/// A «Dine faste» card (156 wide, floating `aeKnSvev 3.4s`, .9 s apart, over
/// its shadow).
class _Fast extends StatelessWidget {
  const _Fast({required this.o, required this.ganger, required this.delayMs, required this.onApne, required this.onIgjen});
  final _Ordre o;
  final int ganger;
  final double delayMs;
  final VoidCallback onApne;
  final VoidCallback onIgjen;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 156,
    child: RepaintBoundary(
      child: LfLoop(
        builder: (context, t, _) {
          final p = ((t + delayMs) / 3400) % 1.0;
          final y = kf(p, const [0, .5, 1], const [0, -5, 0], cssEaseInOut);
          final sx = kf(p, const [0, .5, 1], const [1, .82, 1], cssEaseInOut);
          final op = kf(p, const [0, .5, 1], const [1, .6, 1], cssEaseInOut);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 156 * .12,
                right: 156 * .12,
                bottom: -16 + 5 * (1 - (sx - .82) / .18),
                height: 14,
                child: Opacity(
                  opacity: op,
                  child: Transform.scale(
                    scaleX: sx,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.elliptical(60, 7)),
                        gradient: RadialGradient(colors: [Color.fromRGBO(0, 10, 14, .55), Color.fromRGBO(0, 0, 0, 0)], stops: [0, .72]),
                      ),
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, y),
                child: AePress(
                  onTap: onApne,
                  dy: 0,
                  scale: .98,
                  child: CssBox(
                    height: 149,
                    radius: BorderRadius.circular(22),
                    bg: _glass,
                    shadows: _glassSh,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            _Tile(navn: o.butikk, size: 38, r: 13, font: 15),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(o.butikk, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(13, weight: FontWeight.w800)),
                                  Text('$ganger× · ${OhCopy.dag(o.naar)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(11, color: const Color(0xFF9FC2CC))),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(height: 31, child: Text(o.varer, maxLines: 2, overflow: TextOverflow.clip, style: inter(11.5, height: 1.35, color: const Color(0xFFDCE9EC)))),
                        const Spacer(),
                        _Igjen(key: Key('oh-fast-${o.storeId}'), tekst: OhCopy.kr(o.sum.round()), onTap: onIgjen, full: true),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

/// An order (L7867–7886).
class _OrdreKort extends StatelessWidget {
  const _OrdreKort({required this.o, required this.kroner, required this.status, required this.onApne, required this.onIgjen});
  final _Ordre o;
  final int? kroner;
  final (String, Color, Color) status;
  final VoidCallback onApne;
  final VoidCallback onIgjen;

  @override
  Widget build(BuildContext context) => AePress(
    key: Key('oh-ordre-${o.id}'),
    onTap: onApne,
    dy: 0,
    scale: .99,
    child: CssBox(
      radius: BorderRadius.circular(24),
      bg: _glass,
      shadows: _glassSh,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Tile(navn: o.butikk, size: 46, r: 15, font: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.butikk, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(14.5, weight: FontWeight.w800, em: -.01)),
                    const SizedBox(height: 2),
                    Text('${o.kode} · ${OhCopy.dag(o.naar)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: aeTab(inter(11.5, color: const Color(0xFF9FC2CC)))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(OhCopy.kr(o.sum.round()), style: aeTab(jakarta(17, em: -.02))),
                  if (kroner != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: const Color.fromRGBO(242, 193, 78, .18),
                        border: Border.all(color: const Color.fromRGBO(242, 193, 78, .3)),
                      ),
                      child: Text(OhCopy.kroner(kroner!), style: inter(10.5, weight: FontWeight.w800, color: const Color(0xFFF7D27A))),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color.fromRGBO(255, 255, 255, .1)),
                child: Text(OhCopy.antVarer(o.antall), style: inter(10.5, weight: FontWeight.w800, color: const Color(0xFFCFE3E9))),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(o.varer, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(12, color: const Color(0xFFDCE9EC)))),
            ],
          ),
          Container(height: 1, margin: const EdgeInsets.only(top: 12), color: const Color.fromRGBO(255, 255, 255, .1)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: status.$2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AeIkon('M5 12.5l4.5 4.5L19 7.5', size: 11, stroke: 3.4, color: status.$3),
                      const SizedBox(width: 5),
                      Flexible(child: Text(status.$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(11, weight: FontWeight.w800, color: status.$3))),
                    ],
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

/// The order's timeline (`kOrdreTid`): five mint steps on a mint rail.
class _Tidslinje extends StatelessWidget {
  const _Tidslinje({required this.ferdig});
  final int ferdig;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: Stack(
      children: [
        Positioned(
          left: 28,
          right: 28,
          top: 6 + 10,
          height: 4,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(colors: [Color(0xFF5CE0B8), Color(0xFF2FB893)]),
            ),
          ),
        ),
        Positioned.fill(
          top: 6,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final (i, s) in OhCopy.tid.indexed)
                SizedBox(
                  width: 56,
                  child: Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: i < ferdig ? const RadialGradient(center: Alignment(-.32, -.44), radius: .9, colors: [Color(0xFFA8F5DC), Color(0xFF3FCB9F), Color(0xFF23A07C)], stops: [0, .58, 1]) : null,
                          color: i < ferdig ? null : const Color(0xFFDDD8CE),
                          boxShadow: const [BoxShadow(color: Color(0xFFF5F3EF), spreadRadius: 3), BoxShadow(color: Color.fromRGBO(10, 90, 66, .45), offset: Offset(0, 4), blurRadius: 4, spreadRadius: -2)],
                        ),
                        alignment: Alignment.center,
                        child: i < ferdig ? const AeIkon('M5 12.5l4.5 4.5L19 7.5', size: 11, stroke: 3.6) : null,
                      ),
                      const SizedBox(height: 6),
                      Text(s, maxLines: 1, softWrap: false, overflow: TextOverflow.visible, style: inter(10.5, weight: FontWeight.w800, color: const Color(0xFF2E6B47))),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// The mono receipt (KVITTERING, the lines with dotted leaders, delivery, the
/// double rule and Totalt).
class _Kvittering extends StatelessWidget {
  const _Kvittering({required this.o});
  final _Ordre o;

  TextStyle _mono(double px, {FontWeight w = FontWeight.w600, Color c = const Color(0xFF24231F), double em = 0}) =>
      GoogleFonts.ibmPlexMono(fontSize: px, fontWeight: w, color: c, letterSpacing: px * em, fontFeatures: const [FontFeature.tabularFigures()]);

  Widget _rad(Widget a, String b, TextStyle s) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        a,
        Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(8, 0, 8, 4), child: CustomPaint(painter: _Prikker(), child: const SizedBox(height: 1.5)))),
        Text(b, style: s.copyWith(fontWeight: FontWeight.w700)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final varer = o.sum - o.levering;
    return CssBox(
      radius: BorderRadius.circular(22),
      bg: const [
        CssLinear(180, [Colors.white, Color(0xFFFAF8F4)]),
      ],
      shadows: const [
        CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .95)),
        CssShadow(0, 0, 0, 1, Color.fromRGBO(35, 32, 29, .04)),
        CssShadow(0, 12, 20, -14, Color.fromRGBO(8, 24, 32, .45)),
      ],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(OhCopy.kvittering, style: _mono(10.5, w: FontWeight.w700, c: const Color(0xFF8C847C), em: .2)),
          ),
          CustomPaint(painter: _Strek(), child: const SizedBox(height: 1.5)),
          for (final l in o.linjer)
            _rad(
              Flexible(
                flex: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${((l['quantity'] ?? 1) as num).toInt()}', style: _mono(13, w: FontWeight.w700, c: kAeTeal)),
                    const SizedBox(width: 8),
                    ConstrainedBox(constraints: const BoxConstraints(maxWidth: 170), child: Text('${l['name'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: _mono(13))),
                  ],
                ),
              ),
              OhCopy.kr((((l['unit_price'] ?? 0) as num) * ((l['quantity'] ?? 1) as num)).round()),
              _mono(13),
            ),
          if (o.levering > 0) _rad(Text(OhCopy.levering, style: _mono(12.5, c: const Color(0xFF57534B))), OhCopy.kr(o.levering.round()), _mono(12.5, c: const Color(0xFF57534B))),
          const SizedBox(height: 10),
          Container(height: 3, decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color.fromRGBO(43, 42, 39, .28)), bottom: BorderSide(color: Color.fromRGBO(43, 42, 39, .28))))),
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: Text(OhCopy.totalt, style: jakarta(15, color: const Color(0xFF24231F)))),
              Text(OhCopy.kr(math.max(o.sum, varer).round()), style: _mono(20, w: FontWeight.w700, c: const Color(0xFF1B2A2E), em: -.03)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Prikker extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color.fromRGBO(43, 42, 39, .28);
    for (double x = 0; x < size.width; x += 4) {
      canvas.drawCircle(Offset(x + .75, .75), .75, p);
    }
  }

  @override
  bool shouldRepaint(_Prikker old) => false;
}

class _Strek extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color.fromRGBO(43, 42, 39, .2)
      ..strokeWidth = 1.5;
    for (double x = 0; x < size.width; x += 6) {
      canvas.drawLine(Offset(x, .75), Offset(math.min(x + 3, size.width), .75), p);
    }
  }

  @override
  bool shouldRepaint(_Strek old) => false;
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
  static String under(int n, int kr) => kr > 0 ? '${antBestillinger(n)} · ${_nf(kr)} Ærend-kroner opptjent' : antBestillinger(n);
  static const String tom = 'Ingen bestillinger ennå';
  static const String tomSub = 'Når du har bestilt, ligger alt her, klart til å bestilles igjen.';
  static const String bestillIgjen = 'Bestill igjen';
  static const String dineFaste = 'Dine faste';
  static String bestillIgjenSum(int kr) => 'Bestill igjen · ${_nf(kr)} kr';
  static String antBestillinger(int n) => '$n ${n == 1 ? 'bestilling' : 'bestillinger'}';
  static String antVarer(int n) => '$n ${n == 1 ? 'vare' : 'varer'}';
  static String kr(int n) => '${_nf(n)} kr';
  static String kroner(int n) => '+$n Ærend-kr';
  static String kronerLinje(int n) => '+$n Ærend-kroner';
  static const String levert = 'Levert';
  static const String avbestilt = 'Avbestilt';
  static const String paaVei = 'På vei';
  static const String kvittering = 'KVITTERING';
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
