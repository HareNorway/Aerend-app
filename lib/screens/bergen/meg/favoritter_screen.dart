import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/ops/butikk_models.dart';
import '../../../data/ops/favourite_products.dart';
import '../../../data/ops/favourite_stores.dart';
import '../../../data/points/points_rules.dart';
import '../../../networking/ops/ops_butikk_api.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../../../networking/ops/ops_kasse_api.dart';
import '../../../utils/utils.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../deliveryService/storeDetail/store_detail_repo.dart';
import '../aegil/aegil_bits.dart';
import '../butikk/kategori_kort.dart' show KatHolo, KatKortStag, KatMyntPille, KatRundKnapp;
import '../../../ui/kit/ae_haptic.dart';
import '../kit/bergen_faner.dart';
import '../kit/bergen_fav_heart.dart' show FavCopy;
import '../kit/bergen_kit.dart';
import '../kit/bergen_perf.dart';
import 'a3_services.dart';
import 'bestill_igjen.dart';
import 'bestillinger_screen.dart' show OhCopy;
import 'meg_copy.dart';

/// Favoritter (new Bergen `erFavoritter`, L8369–8457 + `favVals` L16766):
/// a plain title bar, the Butikker (N) / Produkter (N) tabs, and
///
/// * per favourite store a cream card: the banner (or the store's tint and
///   icon), «Åpen · 25 min», the heart (remove, with «Angre»), the logo,
///   name and line, the arrow, time · delivery fee, «+N» points, «SIST
///   BESTILT · dag» with the order and its sum, the often-ordered «+» chips,
///   and «Bestill igjen · sum»;
/// * per favourite product (Bergen Step 9, D4) a quick-add card: photo,
///   heart, name, the store with its logo, time, «+N», price and «+».
///
/// Two empty states. Data: `ops.customer.favourites` ([FavouriteStores]),
/// `ops.customer.favourite_products` ([FavouriteProducts]), the store page
/// for logo / banner / fee / open, `ops.customer.orders` for «Sist bestilt»
/// and the chips, `points/rules` for «+N».
class FavoritterScreen extends StatefulWidget {
  const FavoritterScreen({super.key, this.fane = 'butikker'});

  /// The tab to open on (`butikker` / `produkter`).
  final String fane;

  /// The data sources (tests swap them).
  static Future<BergenStoreInfo?> Function(int storeId) butikkInfo = (id) => OpsButikkApi().store(id);
  static Future<List<Map<String, dynamic>>> Function() ordrer = () => OpsCustomerApi().orders(limit: 50);
  static OpsKasseApi Function() kasse = () => OpsKasseApi();

  @visibleForTesting
  static void reset() {
    butikkInfo = (id) => OpsButikkApi().store(id);
    ordrer = () => OpsCustomerApi().orders(limit: 50);
    kasse = () => OpsKasseApi();
  }

  @override
  State<FavoritterScreen> createState() => _FavoritterScreenState();
}

/// What one store card shows besides the favourites row.
class _ButikkData {
  _ButikkData({this.info, this.sist, this.ofte = const []});
  final BergenStoreInfo? info;
  final _Ordre? sist;
  final List<_Ofte> ofte;
}

class _Ordre {
  const _Ordre({required this.naar, required this.linjer, required this.sum});
  final DateTime naar;
  final List<Map<String, dynamic>> linjer;
  final double sum;
  String get navn => linjer.map((l) => '${l['name'] ?? l['product_name'] ?? ''}').where((n) => n.isNotEmpty).join(', ');
}

class _Ofte {
  const _Ofte(this.id, this.navn, this.pris);
  final int id;
  final String navn;
  final double pris;
}

class _FavoritterScreenState extends State<FavoritterScreen> {
  final FavouriteStores _favs = FavouriteStores.instance;
  final FavouriteProducts _prod = FavouriteProducts.instance;
  late String _fane = widget.fane;
  bool _loading = true;
  final Map<int, _ButikkData> _data = {};
  PointsRules? _regler;

  /// What was just put in the basket (`favLagt`): the key turns to a check
  /// for 1.8 s.
  final Set<String> _lagt = {};

  @override
  void initState() {
    super.initState();
    _last();
  }

  Future<void> _last() async {
    await Future.wait<Object?>([_favs.refresh(), _prod.refresh()]);
    final r = await Future.wait<Object?>([a3Try(FavoritterScreen.ordrer), a3Try(A3Services.rules)]);
    final ordrer = (r[0] as List<Map<String, dynamic>>?) ?? const [];
    _regler = r[1] as PointsRules?;
    final ids = _favs.stores.map((s) => s.storeId).toList();
    final infos = await Future.wait([for (final id in ids) a3Try(() => FavoritterScreen.butikkInfo(id))]);
    for (var i = 0; i < ids.length; i++) {
      _data[ids[i]] = _fraOrdrer(ids[i], ordrer, infos[i]);
    }
    if (mounted) setState(() => _loading = false);
  }

  /// «SIST BESTILT»: the latest delivered order at the store; the chips: the
  /// three products ordered most often there.
  _ButikkData _fraOrdrer(int storeId, List<Map<String, dynamic>> ordrer, BergenStoreInfo? info) {
    _Ordre? sist;
    final teller = <int, int>{};
    final navn = <int, String>{};
    final pris = <int, double>{};
    for (final o in ordrer) {
      final store = o['store'] is Map ? o['store'] as Map : const {};
      if ((store['id'] as num?)?.toInt() != storeId) continue;
      if ('${o['state']}' != 'delivered') continue;
      final items = o['items'] is List ? (o['items'] as List).whereType<Map>().map((m) => m.cast<String, dynamic>()).toList() : <Map<String, dynamic>>[];
      if (items.isEmpty) continue;
      var sum = 0.0;
      for (final i in items) {
        final id = (i['product_id'] as num?)?.toInt() ?? 0;
        final ant = ((i['qty'] ?? i['quantity'] ?? i['num_of_items'] ?? 1) as num).toInt();
        final enhet = ((i['unit_price'] ?? i['price_for_one'] ?? i['price'] ?? 0) as num).toDouble();
        sum += enhet * ant;
        if (id > 0) {
          teller[id] = (teller[id] ?? 0) + 1;
          navn[id] = '${i['name'] ?? i['product_name'] ?? ''}';
          pris[id] = enhet;
        }
      }
      // No unit prices on the rows: the order's own total.
      if (sum <= 0) sum = ((o['total_pay'] ?? o['total'] ?? 0) as num).toDouble();
      final naar = DateTime.tryParse('${o['ordered_at'] ?? ''}')?.toLocal() ?? DateTime.now();
      if (sist == null || naar.isAfter(sist.naar)) {
        sist = _Ordre(
          naar: naar,
          sum: sum,
          linjer: [
            for (final i in items) {'product_id': i['product_id'], 'quantity': i['qty'] ?? i['quantity'] ?? i['num_of_items'] ?? 1, 'name': i['name'] ?? i['product_name']},
          ],
        );
      }
    }
    final topp = teller.keys.toList()..sort((a, b) => teller[b]!.compareTo(teller[a]!));
    return _ButikkData(
      info: info,
      sist: sist,
      ofte: [for (final id in topp.take(3)) if ((navn[id] ?? '').isNotEmpty) _Ofte(id, navn[id]!, pris[id] ?? 0)],
    );
  }

  /// `+N` on a sum: the purchase rule, whole 10 kr × the rate. No rule, no chip.
  int? _poeng(double kr) {
    final r = _regler;
    if (r == null || r.kjopPer10kr <= 0) return null;
    return (kr ~/ 10) * r.kjopPer10kr;
  }

  void _pop(String key) {
    setState(() => _lagt.add(key));
    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _lagt.remove(key));
    });
  }

  void _openButikk(int storeId, String name) => BergenRoutes.pushOr(
    context,
    '/bergen/butikk/$storeId',
    arguments: {'name': name},
    orElse: () => showBergenToast(context, BergenRoutes.kommerSnart),
  );

  /// One product into the basket, staying here (`leggTil` + `pop`). The
  /// basket holds one store, so another store's lines make way, as «Bestill
  /// igjen» does it.
  Future<bool> _leggEn(int storeId, int productId) async {
    HapticFeedback.selectionClick();
    final kasse = FavoritterScreen.kasse();
    try {
      var cart = await kasse.cart();
      if (!cart.isEmpty && cart.storeId != storeId) {
        for (final l in cart.lines) {
          await kasse.remove(l.cartId);
        }
      }
      prefSetInt('checkedSize', 0);
      prefSetInt('checkedColor', 0);
      prefSetString('checkedOptionList', jsonEncode(const <int>[]));
      await StoreDetailRepo().callOrderCartApi(storeId, productId, 1);
      cart = await kasse.cart();
      if (!mounted) return false;
      prefSetInt(prefCartCount, cart.lines.length);
      BergenCart.syncBadge(context, cart.lines.length);
      final lagt = cart.lines.any((l) => l.productId == productId);
      if (lagt) aeConfirm();
      return lagt;
    } catch (_) {
      return false;
    }
  }

  Future<void> _fjernButikk(FavouriteStore s) async {
    if (OpsCustomerApi.authParams() == null) return showBergenToast(context, FavCopy.loggInn);
    final ok = await _favs.set(s.storeId, false);
    if (!mounted) return;
    if (!ok) return showBergenToast(context, FavCopy.feil);
    showBergenToast(context, FavTekst.fjernet(s.name), angre: () => _favs.set(s.storeId, true));
  }

  Future<void> _fjernProdukt(FavouriteProduct p) async {
    if (OpsCustomerApi.authParams() == null) return showBergenToast(context, FavCopy.loggInn);
    final ok = await _prod.set(p.productId, false);
    if (!mounted) return;
    if (!ok) return showBergenToast(context, FavCopy.feil);
    showBergenToast(context, FavTekst.fjernet(p.name), angre: () => _prod.set(p.productId, true));
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: const Color(0xFF12333D),
      body: LfFrame(
        child: LfOnce(
          ms: 340,
          builder: (context, t, child) {
            // `skjermInn .34s cubic-bezier(.2,.9,.3,1)`.
            final p = const Cubic(.2, .9, .3, 1).transform(kfP(t, 0, 340));
            return Opacity(
              opacity: kf(p, const [0, .55, 1], const [0, 1, 1]),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.translationValues(0, 14 * (1 - p), 0)..scaleByDouble(.978 + .022 * p, .978 + .022 * p, 1, 1),
                child: child,
              ),
            );
          },
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF22596A), Color(0xFF1A4652), Color(0xFF12333D)],
                stops: [0, .38, 1],
              ),
            ),
            child: CustomPaint(
              painter: const _Glod(),
              child: AnimatedBuilder(
                animation: Listenable.merge([_favs.ids, _prod.ids]),
                builder: (context, _) {
                  final butikker = _favs.stores.where((s) => _favs.ids.value.contains(s.storeId)).toList();
                  final produkter = _prod.products.where((p) => _prod.ids.value.contains(p.productId)).toList();
                  return CustomScrollView(
                    key: const Key('fav-liste'),
                    slivers: [
                      SliverToBoxAdapter(child: SizedBox(height: top)),
                      SliverToBoxAdapter(child: _tittel()),
                      SliverPersistentHeader(pinned: true, delegate: _FanerDelegat(_faner(butikker.length, produkter.length))),
                      if (_fane == 'butikker')
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                          sliver: SliverList.list(
                            children: [
                              if (butikker.isEmpty && _loading)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                                ),
                              if (butikker.isEmpty && !_loading)
                                _Tom(
                                  key: const Key('fav-butikker-tom'),
                                  tittel: FavTekst.ingenButikker,
                                  linje: FavTekst.ingenButikkerLinje,
                                  knapp: FavTekst.finnButikker,
                                  onKnapp: () => BergenRoutes.push(context, '/bergen/utforsk', arguments: const {'tab': 'feed'}),
                                ),
                              for (final (i, s) in butikker.indexed) ...[
                                if (i > 0) const SizedBox(height: 24),
                                KatKortStag(durationMs: 550, delayMs: 60 + i * 90.0, child: _butikkKort(s)),
                              ],
                            ],
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                          sliver: SliverList.list(children: [_produkter(produkter)]),
                        ),
                      // The design's Ægil card («Favorittene dine dukker opp
                      // først i Bestill igjen på Hjem …») is left out: Hjem's
                      // «Bestill igjen» is newest-first, not favourites first.
                      const SliverToBoxAdapter(child: SizedBox(height: 120)),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tittel() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
    child: Row(
      children: [
        AePress(
          key: const Key('fav-tilbake'),
          onTap: () => Navigator.of(context).maybePop(),
          dy: 0,
          scale: .94,
          child: CssBox(
            width: 40,
            height: 40,
            radius: BorderRadius.circular(14),
            bg: const [
              CssLinear(180, [Color.fromRGBO(255, 255, 255, .2), Color.fromRGBO(255, 255, 255, .07)]),
            ],
            shadows: const [
              CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .32)),
              CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .12)),
              CssShadow(0, 2.5, 0, 0, Color.fromRGBO(6, 22, 30, .5)),
              CssShadow(0, 8, 12, -8, Color.fromRGBO(3, 16, 24, .8)),
            ],
            child: const Center(child: AeIkon('M15 6l-6 6 6 6', size: 20, stroke: 2.6)),
          ),
        ),
        const SizedBox(width: 12),
        Text(A3MegCopy.a3_meg_fav_title, style: jakarta(22, em: -.03)),
      ],
    ),
  );

  Widget _faner(int nButikker, int nProdukter) {
    BergenFane fane(String key, String navn, String ikon, int n) => BergenFane(
          key: Key('fav-fane-$key'),
          bygg: (context, t) {
            final fg = BergenFaner.farge(t, av: .7);
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AeIkon(ikon, size: 14, stroke: 2.3, color: fg),
                const SizedBox(width: 7),
                Text(navn, style: inter(12.5, weight: FontWeight.w800, color: fg)),
                const SizedBox(width: 7),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: Color.fromRGBO(255, 255, 255, .1 + .18 * t)),
                  child: Text('$n', style: aeTab(inter(10.5, weight: FontWeight.w800, color: fg))),
                ),
              ],
            );
          },
        );

    return BergenFaner(
      valgt: _fane == 'produkter' ? 1 : 0,
      onValg: (i) => setState(() => _fane = i == 1 ? 'produkter' : 'butikker'),
      faner: [
        fane('butikker', FavTekst.butikker, 'M4 10l1.2-5h13.6L20 10M4 10h16v10H4zM10 20v-5h4v5', nButikker),
        fane('produkter', FavTekst.produkter, 'M6 8h12l1 13H5zM9 8V6a3 3 0 0 1 6 0v2', nProdukter),
      ],
    );
  }

  // ── a store ────────────────────────────────────────────────────────────

  Widget _butikkKort(FavouriteStore s) {
    final d = _data[s.storeId];
    final info = d?.info;
    final apen = info?.open ?? s.open;
    final min = info?.deliveryMinutes ?? s.etaMinutes;
    final sist = d?.sist;
    final poeng = sist == null ? null : _poeng(sist.sum);
    final frakt = info?.deliveryChargeKr;
    final under = [
      if ((info?.categoryName ?? '').isNotEmpty) info!.categoryName!,
      if ((s.address ?? info?.address ?? '').isNotEmpty) (s.address ?? info!.address!).split(',').first.trim(),
    ].join(' · ');
    final lagtIgjen = _lagt.contains('s${s.storeId}');
    return Stack(
      key: Key('fav-store-${s.storeId}'),
      clipBehavior: Clip.none,
      children: [
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: _kremKort(30),
          child: Stack(
            children: [
              // The card's holo from 196 px down.
              const Positioned(left: 0, right: 0, top: 196, bottom: 0, child: IgnorePointer(child: KatHolo(farger: _holo, stopp: _holoStopp))),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      onTap: () => _openButikk(s.storeId, s.name),
                      child: _Banner(navn: s.name, url: info?.bannerUrl, apen: apen, min: min),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 50),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(76, 10, 4, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, style: jakarta(20, em: -.03, height: 1.1, color: _ink)),
                                  if (under.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(under, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, style: inter(12.5, weight: FontWeight.w500, color: _sub)),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            KatRundKnapp(
                              key: Key('fav-se-${s.storeId}'),
                              size: 50,
                              ikon: 'M5 12h13M13 6l6 6-6 6',
                              ikonPx: 20,
                              strek: 2.8,
                              onTap: () => _openButikk(s.storeId, s.name),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 13),
                      padding: const EdgeInsets.fromLTRB(6, 11, 6, 0),
                      decoration: const _Stiplet(),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                if (min != null) Text(FavTekst.min(min), style: aeTab(inter(12, weight: FontWeight.w700, color: const Color(0xFF3F3A33)))),
                                if (min != null && frakt != null) ...[
                                  const SizedBox(width: 7),
                                  Container(width: 3, height: 3, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFB5AC9F))),
                                  const SizedBox(width: 7),
                                ],
                                if (frakt != null)
                                  Flexible(
                                    child: Text(
                                      frakt <= 0 ? FavTekst.gratisLevering : FavTekst.levering(frakt),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: false,
                                      style: aeTab(inter(12, weight: FontWeight.w700, color: _sub)),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (poeng != null && poeng > 0) KatMyntPille(tekst: '+$poeng', hoyde: 32, mynt: 17, fontPx: 12.5, faseMs: 0),
                        ],
                      ),
                    ),
                    if (sist != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white,
                          boxShadow: const [
                            BoxShadow(color: Color.fromRGBO(60, 40, 20, .08), spreadRadius: 1),
                            BoxShadow(color: Color.fromRGBO(60, 40, 20, .35), offset: Offset(0, 6), blurRadius: 12 / 2 / .57735, spreadRadius: -8),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(FavTekst.sistBestilt(OhCopy.dag(sist.naar)), style: inter(10, weight: FontWeight.w800, em: .08, color: const Color(0xFF8C847C))),
                                      const SizedBox(height: 2),
                                      Text(sist.navn, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, style: inter(14, weight: FontWeight.w800, color: _ink)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(FavTekst.kr(sist.sum), style: aeTab(jakarta(15, color: _ink))),
                              ],
                            ),
                            if ((d?.ofte ?? const []).isNotEmpty) ...[
                              const SizedBox(height: 10),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                clipBehavior: Clip.none,
                                child: Row(
                                  children: [
                                    for (final (i, o) in d!.ofte.indexed) ...[
                                      if (i > 0) const SizedBox(width: 6),
                                      _OfteChip(
                                        key: Key('fav-ofte-${s.storeId}-${o.id}'),
                                        navn: o.navn,
                                        pris: FavTekst.kr(o.pris),
                                        lagt: _lagt.contains('o${o.id}'),
                                        onTap: () async {
                                          final ok = await _leggEn(s.storeId, o.id);
                                          if (!mounted) return;
                                          if (ok) {
                                            _pop('o${o.id}');
                                            showBergenToast(context, FavTekst.lagtIKurven(o.navn, s.name));
                                          } else {
                                            showBergenToast(context, BergenRoutes.ikkeIKurven);
                                          }
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      AePress(
                        key: Key('fav-igjen-${s.storeId}'),
                        onTap: () async {
                          _pop('s${s.storeId}');
                          await bestillIgjen(context, kasse: FavoritterScreen.kasse(), storeId: s.storeId, butikk: s.name, linjer: sist.linjer);
                        },
                        dy: 3,
                        child: CssBox(
                          height: 50,
                          radius: BorderRadius.circular(999),
                          bg: const [
                            CssLinear(180, [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], [0, .56, 1]),
                          ],
                          shadows: const [
                            CssShadow(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .45)),
                            CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .4)),
                            CssShadow(0, 3, 0, 0, Color(0xFFC4491A)),
                            CssShadow(0, 14, 18, -10, Color.fromRGBO(200, 70, 25, .8)),
                          ],
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const AeIkon('M20 11a8 8 0 1 0-2.3 5.7 M20 4v7h-7', size: 15, stroke: 2.6),
                              const SizedBox(width: 8),
                              Text(lagtIgjen ? FavTekst.lagtIKurvenKort : FavTekst.bestillIgjen(sist.sum), style: aeTab(inter(14.5, weight: FontWeight.w800))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        // The logo on the banner's edge.
        Positioned(left: 18, top: 160, child: _LogoRund(url: info?.logoUrl, navn: s.name, size: 58, pad: 6, ring: 4)),
        // The heart: un-heart (with «Angre»).
        Positioned(
          right: 18,
          top: 18,
          child: _Hjerte(key: Key('fav-fjern-${s.storeId}'), size: 40, ikon: 17, label: FavTekst.fjernAria(s.name), onTap: () => _fjernButikk(s)),
        ),
      ],
    );
  }

  // ── products ───────────────────────────────────────────────────────────

  Widget _produkter(List<FavouriteProduct> produkter) {
    if (produkter.isEmpty) {
      if (_loading) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
        );
      }
      return const _Tom(key: Key('fav-produkter-tom'), tittel: FavTekst.ingenProdukter, linje: FavTekst.ingenProdukterLinje);
    }
    final sum = produkter.fold<double>(0, (a, p) => a + p.priceKr);
    final antButikker = produkter.map((p) => p.storeId).toSet().length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: _kremKort(24),
          child: Stack(
            children: [
              const Positioned.fill(child: IgnorePointer(child: KatHolo(farger: _holo, stopp: _holoStopp))),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(FavTekst.antallProdukter(produkter.length), style: jakarta(15, em: -.01, color: _ink)),
                    const SizedBox(height: 1),
                    Text(FavTekst.altSammen(FavTekst.kr(sum), antButikker), style: inter(12, color: _sub)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, box) {
            final w = (box.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 16,
              children: [
                for (final (i, p) in produkter.indexed)
                  SizedBox(width: w, child: KatKortStag(durationMs: 500, delayMs: 60 + i * 70.0, child: _produktKort(p, i))),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _produktKort(FavouriteProduct p, int i) {
    final poeng = _poeng(p.priceKr);
    final lagt = _lagt.contains('p${p.productId}');
    // The store page's time when the store is a favourite too, so one store
    // says one time on this screen.
    final min = _data[p.storeId]?.info?.deliveryMinutes ?? p.etaMinutes;
    return Container(
      key: Key('fav-produkt-${p.productId}'),
      clipBehavior: Clip.antiAlias,
      decoration: _kremKort(26),
      child: Stack(
        children: [
          const Positioned(left: 0, right: 0, top: 120, bottom: 0, child: IgnorePointer(child: KatHolo(farger: _holo, stopp: _holoStopp))),
          Padding(
            padding: const EdgeInsets.fromLTRB(7, 7, 7, 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 112,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () => _openButikk(p.storeId, p.storeName),
                          child: _ProduktBilde(navn: p.name, url: p.image, i: i),
                        ),
                      ),
                      Positioned(
                        right: 7,
                        top: 7,
                        child: _Hjerte(key: Key('fav-fjern-p${p.productId}'), size: 32, ikon: 14, label: FavTekst.fjernAria(p.name), onTap: () => _fjernProdukt(p)),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 37,
                        child: Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: jakarta(15.5, em: -.02, height: 1.2, color: _ink)),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => _openButikk(p.storeId, p.storeName),
                        child: Row(
                          children: [
                            _LogoRund(url: p.storeLogo, navn: p.storeName, size: 20, pad: 2.5, ring: 0),
                            const SizedBox(width: 6),
                            Expanded(child: Text(p.storeName, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, style: inter(11.5, weight: FontWeight.w700, color: const Color(0xFF57534B)))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (min != null) ...[
                            const AeIkon('M12 3.5a8.5 8.5 0 1 0 0 17 8.5 8.5 0 0 0 0-17z M12 7.5V12l3 2', size: 12, stroke: 2.4, color: _sub),
                            const SizedBox(width: 4),
                            Expanded(child: Text(FavTekst.min(min), maxLines: 1, softWrap: false, style: aeTab(inter(11.5, weight: FontWeight.w700, color: _sub)))),
                          ] else
                            const Spacer(),
                          if (poeng != null && poeng > 0) KatMyntPille(tekst: '+$poeng', hoyde: 24, mynt: 14, fontPx: 11.5, faseMs: 300.0 * i),
                        ],
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.only(top: 10),
                        decoration: const _Stiplet(),
                        child: Row(
                          children: [
                            Expanded(child: Text(FavTekst.kr(p.priceKr), maxLines: 1, softWrap: false, style: aeTab(jakarta(19, em: -.03, color: _ink)))),
                            _LeggKnapp(
                              key: Key('fav-legg-${p.productId}'),
                              lagt: lagt,
                              onTap: () async {
                                final ok = await _leggEn(p.storeId, p.productId);
                                if (!mounted) return;
                                if (ok) {
                                  _pop('p${p.productId}');
                                } else {
                                  showBergenToast(context, BergenRoutes.ikkeIKurven);
                                }
                              },
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
        ],
      ),
    );
  }
}

const Color _ink = Color(0xFF23201D);
const Color _sub = Color(0xFF6E675D);

/// The card holo: `linear-gradient(115deg, transparent 28%, peach .34 40%,
/// gold .34 48%, pink .3 56%, transparent 68%)` on 260 %.
const List<Color> _holo = [
  Color.fromRGBO(255, 255, 255, 0),
  Color.fromRGBO(255, 190, 160, .34),
  Color.fromRGBO(255, 228, 150, .34),
  Color.fromRGBO(245, 185, 225, .3),
  Color.fromRGBO(255, 255, 255, 0),
];
const List<double> _holoStopp = [.28, .40, .48, .56, .68];

/// The photo's colour-dodge holo (opacity .3).
const List<Color> _holoFoto = [
  Color.fromRGBO(255, 255, 255, 0),
  Color.fromRGBO(255, 120, 80, .6),
  Color.fromRGBO(255, 214, 120, .6),
  Color.fromRGBO(255, 150, 190, .55),
  Color.fromRGBO(210, 150, 255, .45),
  Color.fromRGBO(255, 255, 255, 0),
];
const List<double> _holoFotoStopp = [.22, .36, .45, .54, .63, .76];

/// The cream card (`#FFFBF5 → #F7EEE2`, white ring, inner top light, the
/// 3 px base and the deep drop).
BoxDecoration _kremKort(double r) => BoxDecoration(
  borderRadius: BorderRadius.circular(r),
  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFFBF5), Color(0xFFF7EEE2)]),
  border: const Border(top: BorderSide(color: Colors.white, width: 1.5)),
  boxShadow: const [
    BoxShadow(color: Color.fromRGBO(255, 255, 255, .55), spreadRadius: 1),
    BoxShadow(color: Color.fromRGBO(4, 18, 26, .25), offset: Offset(0, 3)),
    BoxShadow(color: Color.fromRGBO(4, 18, 26, .85), offset: Offset(0, 30), blurRadius: 40 / 2 / .57735, spreadRadius: -22),
  ],
);

/// `border-top: 1px dashed rgba(60,40,20,.16)`.
class _Stiplet extends Decoration {
  const _Stiplet();

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _StipletMaler();
}

class _StipletMaler extends BoxPainter {
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration cfg) {
    final w = cfg.size!.width;
    final paint = Paint()
      ..color = const Color.fromRGBO(60, 40, 20, .16)
      ..strokeWidth = 1;
    final y = offset.dy + .5;
    for (var x = 0.0; x < w; x += 6) {
      canvas.drawLine(Offset(offset.dx + x, y), Offset(offset.dx + (x + 3).clamp(0, w), y), paint);
    }
  }
}

/// The background's light: `radial-gradient(90% 40% at 20% 0%, white .12, transparent 60%)`.
class _Glod extends CustomPainter {
  const _Glod();

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.drawRect(r, Paint()..shader = const CssRadial([Color.fromRGBO(255, 255, 255, .12), Color.fromRGBO(255, 255, 255, 0)], stops: [0, .6], rx: .9, ry: .4, cx: .2, cy: 0).shader(r));
  }

  @override
  bool shouldRepaint(_Glod o) => false;
}

/// The sticky tab bar (`position: sticky; top: 0`, blurred teal).
class _FanerDelegat extends SliverPersistentHeaderDelegate {
  _FanerDelegat(this.faner);
  final Widget faner;

  @override
  double get minExtent => 68;
  @override
  double get maxExtent => 68;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final innhold = Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.fromRGBO(34, 89, 106, .96), Color.fromRGBO(34, 89, 106, .86)]),
      ),
      child: faner,
    );
    if (!BergenPerf.blurOn(context, secondary: true)) return SizedBox.expand(child: innhold);
    return SizedBox.expand(child: ClipRect(child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8), child: innhold)));
  }

  @override
  bool shouldRebuild(_FanerDelegat o) => o.faner != faner;
}

/// The banner (180 px, 23 round): the store's banner photo, else its tint
/// with a big faint icon; the scrim, the dodge holo, the inner shade and
/// «Åpen · 25 min» / «Stengt nå».
class _Banner extends StatelessWidget {
  const _Banner({required this.navn, required this.url, required this.apen, required this.min});

  final String navn;
  final String? url;
  final bool apen;
  final int? min;

  @override
  Widget build(BuildContext context) {
    final slag = _slag(navn);
    return ClipRRect(
      borderRadius: BorderRadius.circular(23),
      child: SizedBox(
        height: 180,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: const Alignment(-.5, -1), end: const Alignment(.5, 1), colors: _tint[slag]!))),
            if (url != null && url!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: url!,
                memCacheWidth: BergenPerf.decodeWidth,
                fit: BoxFit.cover,
                alignment: const Alignment(-.3, -.2),
                fadeInDuration: const Duration(milliseconds: 200),
                errorWidget: (_, _, _) => _ikon(slag),
              )
            else
              _ikon(slag),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color.fromRGBO(20, 10, 4, .3), Color.fromRGBO(20, 10, 4, 0), Color.fromRGBO(20, 10, 4, 0), Color.fromRGBO(20, 10, 4, .22)],
                  stops: [0, .3, .75, 1],
                ),
              ),
            ),
            const IgnorePointer(child: KatHolo(farger: _holoFoto, stopp: _holoFotoStopp, dodge: .3)),
            const IgnorePointer(
              child: CssBox(
                radius: BorderRadius.all(Radius.circular(23)),
                shadows: [CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(0, 0, 0, .1)), CssShadow.inset(0, 2, 6, 0, Color.fromRGBO(0, 0, 0, .22))],
              ),
            ),
            Positioned(
              left: 10,
              top: 10,
              child: Container(
                padding: const EdgeInsets.fromLTRB(9, 6, 11, 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: const Color(0xFFFCFBF8),
                  boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, .45), offset: Offset(0, 8), blurRadius: 14 / 2 / .57735, spreadRadius: -4)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: apen ? const Color(0xFF5CE0B8) : const Color.fromRGBO(35, 32, 29, .3))),
                    const SizedBox(width: 6),
                    Text(apen ? (min == null ? FavTekst.aapen : FavTekst.aapenMin(min!)) : FavTekst.stengt, style: aeTab(inter(10, weight: FontWeight.w800, em: .06, color: _ink))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _ikon(_Slag slag) => Stack(
    children: [
      Positioned(
        right: -14,
        bottom: -22,
        child: Opacity(opacity: .28, child: AeIkon(_ikoner[slag]!, size: 170, stroke: 1.3)),
      ),
    ],
  );
}

/// The logo disc: white with padding and a cream ring; the initial on teal
/// when there is no logo.
class _LogoRund extends StatelessWidget {
  const _LogoRund({required this.url, required this.navn, required this.size, required this.pad, required this.ring});

  final String? url;
  final String navn;
  final double size, pad, ring;

  @override
  Widget build(BuildContext context) {
    final indre = size - 2 * pad;
    final ini = Container(
      width: indre,
      height: indre,
      alignment: Alignment.center,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1E4F5C)),
      child: Text(navn.isEmpty ? '' : navn.characters.first.toUpperCase(), style: inter(indre * .46, weight: FontWeight.w800)),
    );
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          if (ring > 0) BoxShadow(color: const Color(0xFFFFFBF5), spreadRadius: ring) else const BoxShadow(color: Color.fromRGBO(60, 40, 20, .12), spreadRadius: 1.5),
          BoxShadow(color: Color.fromRGBO(4, 18, 26, ring > 0 ? .55 : .45), offset: Offset(0, ring > 0 ? 16 : 3), blurRadius: (ring > 0 ? 22 : 6) / 2 / .57735, spreadRadius: ring > 0 ? -8 : -2),
        ],
      ),
      child: ClipOval(
        child: url == null || url!.isEmpty
            ? ini
            : CachedNetworkImage(imageUrl: url!, memCacheWidth: 160, fit: BoxFit.contain, errorWidget: (_, _, _) => ini, placeholder: (_, _) => ini),
      ),
    );
  }
}

/// The heart key (`#FCFBF8`, orange heart; `scale(.85)` while pressed).
class _Hjerte extends StatelessWidget {
  const _Hjerte({super.key, required this.size, required this.ikon, required this.label, required this.onTap});

  final double size, ikon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: AePress(
      onTap: onTap,
      dy: 0,
      scale: .85,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFFCFBF8),
          boxShadow: [BoxShadow(color: Color.fromRGBO(0, 0, 0, .45), offset: Offset(0, 7), blurRadius: 13 / 2 / .57735, spreadRadius: -4)],
        ),
        child: AeIkon('M12 20.4l-7.2-7.2a4.9 4.9 0 1 1 7-7l.2.3.2-.3a4.9 4.9 0 1 1 7 7z', size: ikon, stroke: 1.6, color: const Color(0xFFC4491A), fill: const Color(0xFFF26D3D)),
      ),
    ),
  );
}

/// An often-ordered chip: the orange «+», the name and the price.
class _OfteChip extends StatelessWidget {
  const _OfteChip({super.key, required this.navn, required this.pris, required this.lagt, required this.onTap});

  final String navn;
  final String pris;
  final bool lagt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AePress(
    onTap: onTap,
    dy: 2,
    child: CssBox(
      height: 34,
      radius: BorderRadius.circular(999),
      bg: const [
        CssLinear(180, [Color(0xFFFFFBF5), Color(0xFFF4EADC)]),
      ],
      shadows: const [
        CssShadow.inset(0, 1, 0, 0, Colors.white),
        CssShadow(0, 0, 0, 1, Color.fromRGBO(60, 40, 20, .12)),
        CssShadow(0, 2, 0, 0, Color.fromRGBO(60, 40, 20, .12)),
      ],
      padding: const EdgeInsets.fromLTRB(5, 0, 11, 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: lagt ? const [Color(0xFFB4F9E2), Color(0xFF5CE0B8)] : const [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)],
              ),
              boxShadow: [BoxShadow(color: lagt ? const Color(0xFF2FB893) : const Color(0xFFC4491A), offset: const Offset(0, 2))],
            ),
            child: AeIkon(lagt ? 'M5 12.5l4.5 4.5L19 7.5' : 'M12 5v14M5 12h14', size: 11, stroke: 3.4, color: lagt ? const Color(0xFF0F2B33) : Colors.white),
          ),
          const SizedBox(width: 6),
          Text(navn, style: inter(12, weight: FontWeight.w800, color: _ink)),
          const SizedBox(width: 6),
          Text(pris, style: aeTab(inter(12, weight: FontWeight.w800, color: const Color(0xFF8C847C)))),
        ],
      ),
    ),
  );
}

/// The product's «+» (orange) / «Lagt i kurven» (mint check) key.
class _LeggKnapp extends StatelessWidget {
  const _LeggKnapp({super.key, required this.lagt, required this.onTap});

  final bool lagt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: lagt ? FavTekst.lagtIKurvenKort : FavTekst.leggIKurven,
    child: AePress(
      onTap: onTap,
      dy: 3,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: lagt ? const [Color(0xFFB4F9E2), Color(0xFF5CE0B8)] : const [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)],
          ),
          boxShadow: lagt
              ? const [
                  BoxShadow(color: Color.fromRGBO(255, 255, 255, .5), spreadRadius: 1),
                  BoxShadow(color: Color(0xFF2FB893), offset: Offset(0, 3)),
                  BoxShadow(color: Color.fromRGBO(47, 184, 147, .8), offset: Offset(0, 10), blurRadius: 14 / 2 / .57735, spreadRadius: -8),
                ]
              : const [
                  BoxShadow(color: Color.fromRGBO(255, 255, 255, .45), spreadRadius: 1),
                  BoxShadow(color: Color(0xFFC4491A), offset: Offset(0, 3)),
                  BoxShadow(color: Color.fromRGBO(120, 45, 15, .22), offset: Offset(0, 5)),
                  BoxShadow(color: Color.fromRGBO(200, 70, 25, .8), offset: Offset(0, 12), blurRadius: 16 / 2 / .57735, spreadRadius: -9),
                ],
        ),
        child: AeIkon(lagt ? 'M5 12.5l4.5 4.5L19 7.5' : 'M12 5v14M5 12h14', size: 18, stroke: 3, color: lagt ? const Color(0xFF0F2B33) : Colors.white),
      ),
    ),
  );
}

/// The product photo (112 px): the photo with a slow Ken Burns (`bpKB 16s`),
/// else the tint with a faint icon; the dodge holo and the inner shade.
class _ProduktBilde extends StatelessWidget {
  const _ProduktBilde({required this.navn, required this.url, required this.i});

  final String navn;
  final String? url;
  final int i;

  @override
  Widget build(BuildContext context) {
    final slag = _slag(navn);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: const Alignment(-.5, -1), end: const Alignment(.5, 1), colors: _tint[slag]!))),
          if (url != null && url!.isNotEmpty)
            LfLoop(
              builder: (context, t, child) {
                final ping = (t / (14000 + (i % 3) * 3000)) % 2;
                final p = cssEaseInOut.transform(ping <= 1 ? ping : 2 - ping);
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..scaleByDouble(1.04 + .13 * p, 1.04 + .13 * p, 1, 1),
                  child: child,
                );
              },
              child: CachedNetworkImage(imageUrl: url!, memCacheWidth: BergenPerf.decodeWidth, fit: BoxFit.cover, errorWidget: (_, _, _) => const SizedBox.shrink()),
            )
          else
            Center(child: AeIkon(_ikoner[slag]!, size: 56, stroke: 1.6, color: const Color.fromRGBO(35, 32, 29, .45))),
          const IgnorePointer(child: KatHolo(farger: _holoFoto, stopp: _holoFotoStopp, dodge: .3)),
          const IgnorePointer(
            child: CssBox(
              radius: BorderRadius.all(Radius.circular(20)),
              shadows: [CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(0, 0, 0, .08)), CssShadow.inset(0, -10, 18, -10, Color.fromRGBO(0, 0, 0, .35))],
            ),
          ),
        ],
      ),
    );
  }
}

/// The empty state: the cream card, the line, and (stores) «Finn butikker».
class _Tom extends StatelessWidget {
  const _Tom({super.key, required this.tittel, required this.linje, this.knapp, this.onKnapp});

  final String tittel;
  final String linje;
  final String? knapp;
  final VoidCallback? onKnapp;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
    decoration: _kremKort(26),
    child: Column(
      children: [
        Text(tittel, textAlign: TextAlign.center, style: inter(15, weight: FontWeight.w800, color: _ink)),
        const SizedBox(height: 4),
        Text(linje, textAlign: TextAlign.center, style: inter(13, weight: FontWeight.w400, height: 1.45, color: _sub)),
        if (knapp != null) ...[
          const SizedBox(height: 12),
          AePress(
            key: const Key('fav-finn-butikker'),
            onTap: onKnapp,
            dy: 3,
            child: CssBox(
              height: 44,
              radius: BorderRadius.circular(999),
              bg: const [
                CssLinear(180, [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], [0, .56, 1]),
              ],
              shadows: const [CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .4)), CssShadow(0, 3, 0, 0, Color(0xFFC4491A))],
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(mainAxisSize: MainAxisSize.min, children: [Text(knapp!, style: inter(13.5, weight: FontWeight.w800))]),
            ),
          ),
        ],
      ],
    ),
  );
}

/// The store's kind read from its name (the favourites list carries no
/// category), with the design's tint and icon for it.
enum _Slag { mat, fisk, burger, bakeri }

_Slag _slag(String navn) {
  final n = navn.toLowerCase();
  if (RegExp(r'fisk|sjømat|reke|laks|sushi|fish').hasMatch(n)) return _Slag.fisk;
  if (RegExp(r'burger').hasMatch(n)) return _Slag.burger;
  if (RegExp(r'bakeri|brød|bolle|kanel').hasMatch(n)) return _Slag.bakeri;
  return _Slag.mat;
}

const Map<_Slag, List<Color>> _tint = {
  _Slag.mat: [Color(0xFFF6D9B4), Color(0xFFD2854A)],
  _Slag.fisk: [Color(0xFFCFE3E8), Color(0xFF6FA3B2)],
  _Slag.burger: [Color(0xFFF6E7C8), Color(0xFFD9A254)],
  _Slag.bakeri: [Color(0xFFFBEFDA), Color(0xFFEBD3A6)],
};

const Map<_Slag, String> _ikoner = {
  _Slag.fisk: 'M3 12c3-4 8-5 12-3l4-3v12l-4-3c-4 2-9 1-12-3z M15.5 11v.01',
  _Slag.bakeri: 'M4 14c0-4 3.6-7 8-7s8 3 8 7v3H4z M8 10l1 4 M12 9v5 M16 10l-1 4',
  _Slag.mat: 'M3 13h18a9 9 0 0 1-18 0z M12 4v3',
  _Slag.burger: 'M4 11a8 5 0 0 1 16 0z M3.5 14.5h17 M4.5 17.5h15',
};

abstract final class FavTekst {
  static String steder(int n) => '$n ${n == 1 ? 'sted' : 'steder'}';
  static const String aapen = 'Åpen nå';
  static const String stengt = 'Stengt nå';
  static String aapenMin(int min) => 'Åpen · $min min';
  static String min(int min) => '$min min';
  static String levering(double kr) => 'Levering ${kr.round()} kr';
  static const String gratisLevering = 'Gratis levering';
  static String sistBestilt(String dag) => 'SIST BESTILT · ${dag.toUpperCase()}';
  static String kr(num v) => '${v.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ')} kr';
  static String bestillIgjen(double sum) => 'Bestill igjen · ${kr(sum)}';
  static const String lagtIKurvenKort = 'Lagt i kurven ✓';
  static const String leggIKurven = 'Legg i kurven';
  static String lagtIKurven(String vare, String butikk) => '$vare fra $butikk er lagt i kurven';
  static String fjernet(String navn) => '$navn er fjernet fra favoritter';
  static String fjernAria(String navn) => 'Fjern $navn fra favoritter';
  static const String butikker = 'Butikker';
  static const String produkter = 'Produkter';
  static const String ingenButikker = 'Ingen favorittbutikker ennå';
  static const String ingenButikkerLinje = 'Trykk på hjertet i en butikk, så havner den her med «Bestill igjen».';
  static const String finnButikker = 'Finn butikker';
  static const String ingenProdukter = 'Ingen favorittprodukter ennå';
  static const String ingenProdukterLinje = 'Trykk på hjertet på et produkt, så kan du legge det i kurven herfra med ett trykk.';
  static String antallProdukter(int n) => '$n ${n == 1 ? 'favorittprodukt' : 'favorittprodukter'}';
  static String altSammen(String sum, int butikker) => 'Alt sammen: $sum · fra $butikker ${butikker == 1 ? 'butikk' : 'butikker'}';
}
