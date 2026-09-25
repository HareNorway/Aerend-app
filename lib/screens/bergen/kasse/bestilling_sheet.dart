import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../networking/ops/ops_customer_api.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../kit/bergen_kit.dart';
import 'kasse_copy.dart';

/// Bestillingsdetaljer (≈L5641 in `Ærend Kunde Bergen.dc.html`) at
/// `/bergen/bestilling/{id}`: Sammendrag / Detaljer tabs, the Vipps
/// timestamp, ORDRENUMMER + ÆREND-ID, the store's address, Kvittering,
/// "Meg · Bestillinger" (agil-3's route) and "Kontakt kundeservice"
/// (`/bergen/kundeservice`). Data: `ops.customer.orders`.
class BestillingScreen extends StatefulWidget {
  const BestillingScreen({super.key, this.orderId, this.api, this.preloaded});

  final int? orderId;
  final OpsCustomerApi? api;

  /// Tests inject the order summary.
  final Map<String, dynamic>? preloaded;

  @override
  State<BestillingScreen> createState() => _BestillingScreenState();
}

class _BestillingScreenState extends State<BestillingScreen> {
  bool _routeRead = false;
  int _id = 0;
  Map<String, dynamic>? _order;
  bool _missing = false;
  bool _details = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeRead) return;
    _routeRead = true;
    _id =
        widget.orderId ??
        int.tryParse(BergenRoutes.argsOf(context)['id'] ?? '') ??
        0;
    if (widget.preloaded != null) {
      _order = widget.preloaded;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    final orders = await (widget.api ?? OpsCustomerApi()).orders(limit: 100);
    if (!mounted) return;
    final found = orders
        .where((o) => int.tryParse('${o['order_id']}') == _id)
        .firstOrNull;
    setState(() {
      _order = found;
      _missing = found == null;
    });
  }

  String _clock(String? iso) {
    final t = DateTime.tryParse(iso ?? '')?.toLocal();
    if (t == null) return '';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  String _date(String? iso) {
    final t = DateTime.tryParse(iso ?? '')?.toLocal();
    if (t == null) return '';
    return '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}.${t.year}';
  }

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final safeTop = MediaQuery.paddingOf(context).top;
    final o = _order;
    if (_missing) {
      return Scaffold(
        backgroundColor: BergenTokens.paper,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: BergenTokens.ink,
        ),
        body: Center(
          child: Text(
            KasseCopy.a1_kasse_best_ikke_funnet,
            key: const Key('a1_kasse_best_ikke_funnet'),
            style: bText(
              context,
              13,
              weight: FontWeight.w700,
              color: BergenTokens.inkSecondary,
            ),
          ),
        ),
      );
    }
    if (o == null) {
      return const Scaffold(
        backgroundColor: BergenTokens.paper,
        body: Center(
          child: CircularProgressIndicator(color: BergenTokens.teal),
        ),
      );
    }
    final items = (o['items'] is List)
        ? (o['items'] as List).whereType<Map>().toList()
        : const <Map>[];
    final store = o['store'] is Map ? o['store'] as Map : const {};
    final total = (o['total_pay'] as num?)?.toDouble() ?? 0;
    final orderNo = '${o['order_no'] ?? o['order_id'] ?? ''}';
    final code = '${o['code'] ?? ''}';
    final ordered = '${o['ordered_at'] ?? ''}';
    final count = items.fold<int>(
      0,
      (a, i) =>
          a +
          ((i['qty'] ?? i['quantity'] ?? i['num_of_items'] ?? 1) as num)
              .toInt(),
    );

    return Scaffold(
      backgroundColor: BergenTokens.paper,
      body: ListView(
        padding: EdgeInsets.fromLTRB(16 * s, safeTop + 10 * s, 16 * s, 40 * s),
        children: [
          Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: 40 * s,
                  height: 40 * s,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: BergenTokens.paperWarm),
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    size: 20 * s,
                    color: BergenTokens.ink,
                  ),
                ),
              ),
              SizedBox(width: 10 * s),
              Expanded(
                child: Text(
                  '${o['stage_label'] ?? ''}',
                  key: const Key('a1_kasse_best_stage'),
                  style: bDisplay(
                    context,
                    20,
                    weight: FontWeight.w800,
                    color: BergenTokens.ink,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12 * s),
          Row(
            children: [
              BergenChip(
                key: const Key('a1_kasse_best_tab_sammendrag'),
                label: KasseCopy.a1_kasse_best_sammendrag,
                selected: !_details,
                onTap: () => setState(() => _details = false),
              ),
              SizedBox(width: 8 * s),
              BergenChip(
                key: const Key('a1_kasse_best_tab_detaljer'),
                label: KasseCopy.a1_kasse_best_detaljer,
                selected: _details,
                onTap: () => setState(() => _details = true),
              ),
            ],
          ),
          SizedBox(height: 12 * s),
          if (!_details)
            BergenCard(
              key: const Key('a1_kasse_best_sammendrag'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${o['mode'] == 'pickup' ? KasseCopy.a1_kasse_henting : KasseCopy.a1_kasse_levering}'
                        .toUpperCase(),
                    style: bText(
                      context,
                      10,
                      weight: FontWeight.w800,
                      color: BergenTokens.inkFaint,
                    ),
                  ),
                  Text(
                    '${o['delivery_address'] ?? store['address'] ?? ''}',
                    style: bText(
                      context,
                      13,
                      weight: FontWeight.w700,
                      color: BergenTokens.ink,
                    ),
                  ),
                  SizedBox(height: 12 * s),
                  Text(
                    KasseCopy.a1_kasse_best_bestilling,
                    style: bText(
                      context,
                      10,
                      weight: FontWeight.w800,
                      color: BergenTokens.inkFaint,
                    ),
                  ),
                  Text(
                    items
                        .map((i) => '${i['name'] ?? i['product_name'] ?? ''}')
                        .where((e) => e.isNotEmpty)
                        .join(', '),
                    style: bText(
                      context,
                      12.5,
                      weight: FontWeight.w600,
                      color: BergenTokens.inkSecondary,
                    ),
                  ),
                  SizedBox(height: 6 * s),
                  Row(
                    children: [
                      Text(
                        KasseCopy.a1_kasse_best_antall(count),
                        style: bText(
                          context,
                          12,
                          weight: FontWeight.w700,
                          color: BergenTokens.inkFaint,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        KasseCopy.kr(total),
                        style: bDisplay(
                          context,
                          18,
                          weight: FontWeight.w800,
                          color: BergenTokens.ink,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12 * s),
                  Container(
                    padding: EdgeInsets.all(10 * s),
                    decoration: BoxDecoration(
                      color: BergenTokens.paperBright,
                      borderRadius: BorderRadius.circular(14 * s),
                      border: Border.all(color: BergenTokens.paperWarm),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 26 * s,
                          height: 26 * s,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5B24),
                            borderRadius: BorderRadius.circular(8 * s),
                          ),
                          child: Center(
                            child: Text(
                              'V',
                              style: bText(
                                context,
                                13,
                                weight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10 * s),
                        Expanded(
                          child: Text(
                            KasseCopy.a1_kasse_best_betalt_vipps,
                            style: bText(
                              context,
                              10.5,
                              weight: FontWeight.w800,
                              color: BergenTokens.inkFaint,
                            ),
                          ),
                        ),
                        Text(
                          '${KasseCopy.kr(total)} · ${_clock(ordered)}',
                          style: bText(
                            context,
                            12,
                            weight: FontWeight.w800,
                            color: BergenTokens.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12 * s),
                  Row(
                    children: [
                      Expanded(
                        child: BergenCta3d(
                          label: KasseCopy.a1_kasse_best_kvittering,
                          expand: true,
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: orderNo),
                            );
                            if (context.mounted)
                              showBergenToast(
                                context,
                                KasseCopy.a1_kasse_best_kopiert,
                              );
                          },
                        ),
                      ),
                      SizedBox(width: 8 * s),
                      BergenChip(
                        label: KasseCopy.a1_kasse_best_klar,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else ...[
            BergenCard(
              key: const Key('a1_kasse_best_detaljer'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Kicker(KasseCopy.a1_kasse_best_status),
                  Text(
                    '${o['stage_label'] ?? ''}',
                    style: bText(
                      context,
                      13,
                      weight: FontWeight.w800,
                      color: BergenTokens.ink,
                    ),
                  ),
                  SizedBox(height: 10 * s),
                  _Kicker(KasseCopy.a1_kasse_best_din),
                  for (final i in items)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 3 * s),
                      child: Row(
                        children: [
                          Text(
                            '${i['qty'] ?? i['quantity'] ?? i['num_of_items'] ?? 1}×',
                            style: bText(
                              context,
                              12,
                              weight: FontWeight.w800,
                              color: BergenTokens.inkFaint,
                            ),
                          ),
                          SizedBox(width: 8 * s),
                          Expanded(
                            child: Text(
                              '${i['name'] ?? i['product_name'] ?? ''}',
                              style: bText(
                                context,
                                12.5,
                                weight: FontWeight.w700,
                                color: BergenTokens.ink,
                              ),
                            ),
                          ),
                          if (i['price'] != null || i['price_for_one'] != null)
                            Text(
                              KasseCopy.kr(
                                ((i['price'] ?? i['price_for_one']) as num)
                                    .toDouble(),
                              ),
                              style: bText(
                                context,
                                12,
                                weight: FontWeight.w700,
                                color: BergenTokens.inkSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  Divider(color: BergenTokens.paperWarm, height: 16 * s),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          KasseCopy.a1_kasse_best_total,
                          style: bText(
                            context,
                            13,
                            weight: FontWeight.w800,
                            color: BergenTokens.ink,
                          ),
                        ),
                      ),
                      Text(
                        KasseCopy.kr(total),
                        style: bDisplay(
                          context,
                          16,
                          weight: FontWeight.w800,
                          color: BergenTokens.ink,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10 * s),
                  _Kicker(KasseCopy.a1_kasse_best_betaling),
                  Text(
                    'Vipps · ${_date(ordered)} ${_clock(ordered)} · ${KasseCopy.a1_kasse_best_betalt}',
                    style: bText(
                      context,
                      12.5,
                      weight: FontWeight.w600,
                      color: BergenTokens.inkSecondary,
                    ),
                  ),
                  SizedBox(height: 10 * s),
                  _Kicker(KasseCopy.a1_kasse_best_butikken),
                  Text(
                    '${store['name'] ?? ''}',
                    style: bText(
                      context,
                      13,
                      weight: FontWeight.w800,
                      color: BergenTokens.ink,
                    ),
                  ),
                  if (store['address'] != null)
                    Text(
                      '${store['address']}',
                      style: bText(
                        context,
                        12,
                        weight: FontWeight.w600,
                        color: BergenTokens.inkSecondary,
                      ),
                    ),
                  SizedBox(height: 10 * s),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Kicker(KasseCopy.a1_kasse_best_ordrenr),
                            Text(
                              orderNo,
                              key: const Key('a1_kasse_best_ordrenr'),
                              style: bText(
                                context,
                                13,
                                weight: FontWeight.w800,
                                color: BergenTokens.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Kicker(KasseCopy.a1_kasse_best_aerend_id),
                            Text(
                              code,
                              key: const Key('a1_kasse_best_kode'),
                              style: bText(
                                context,
                                13,
                                weight: FontWeight.w800,
                                color: BergenTokens.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10 * s),
                  _Kicker(KasseCopy.a1_kasse_best_tid),
                  Text(
                    '${_date(ordered)} · ${_clock(ordered)}',
                    style: bText(
                      context,
                      12.5,
                      weight: FontWeight.w600,
                      color: BergenTokens.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12 * s),
            BergenCard(
              onTap: () =>
                  BergenRoutes.push(context, '/bergen/meg/bestillinger'),
              padding: EdgeInsets.symmetric(
                horizontal: 14 * s,
                vertical: 12 * s,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      KasseCopy.a1_kasse_best_meg,
                      style: bText(
                        context,
                        13,
                        weight: FontWeight.w800,
                        color: BergenTokens.ink,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: BergenTokens.inkFaint,
                    size: 20 * s,
                  ),
                ],
              ),
            ),
            SizedBox(height: 8 * s),
            BergenCard(
              key: const Key('a1_kasse_best_kundeservice'),
              onTap: () => BergenRoutes.push(
                context,
                '/bergen/kundeservice',
                arguments: {'order_id': '$_id'},
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 14 * s,
                vertical: 12 * s,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      KasseCopy.a1_kasse_best_kundeservice,
                      style: bText(
                        context,
                        13,
                        weight: FontWeight.w800,
                        color: BergenTokens.ink,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: BergenTokens.inkFaint,
                    size: 20 * s,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Kicker extends StatelessWidget {
  const _Kicker(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: bText(
      context,
      10,
      weight: FontWeight.w800,
      color: BergenTokens.inkFaint,
    ),
  );
}
