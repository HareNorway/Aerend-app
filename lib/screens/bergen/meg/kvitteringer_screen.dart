// ignore_for_file: non_constant_identifier_names
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../networking/ops/ops_customer_api.dart';
import '../../../utils/utils.dart';
import '../../common/auth/launch/lf_css.dart';
import '../kasse/kasse_copy.dart';
import '../kit/bergen_kit.dart';

/// Payments plan Step 5 (spec v1.3 §5): Meg → «Kvitteringer» — every numbered
/// kvittering and kreditnota (and each order's ordrebekreftelse) the customer
/// has been issued, newest first. A tap
/// fetches the stored PDF (the same bytes that were e-mailed) and hands it to
/// the share sheet. Empty while `money.documents` is off.
abstract final class KvitteringerCopy {
  static String get tittel => languages.ops_kv_tittel;
  static String get linje => languages.ops_kv_linje;
  static String get ingen => languages.ops_kv_ingen;
  static String get kvittering => languages.ops_kv_kvittering;
  static String get kreditnota => languages.ops_kv_kreditnota;
  static String get ordrebekreftelse => languages.ops_kv_ordrebekreftelse;
  static String get feil => languages.ops_kv_feil;
  static String get megUnder => languages.ops_kv_meg_under;
}

/// One row of `GET api/ops/customer/documents`.
class KvDokument {
  const KvDokument({required this.id, required this.type, required this.number, required this.issuedAt, required this.totalOre, this.storeName, this.orderCode, this.refersTo});

  final int id;
  final String type;
  final String number;
  final DateTime? issuedAt;
  final int totalOre;
  final String? storeName;
  final String? orderCode;
  final String? refersTo;

  bool get erKreditnota => type == 'kreditnota';
  bool get erBekreftelse => type == 'ordrebekreftelse';

  String get navn => erKreditnota ? KvitteringerCopy.kreditnota : (erBekreftelse ? KvitteringerCopy.ordrebekreftelse : KvitteringerCopy.kvittering);

  static KvDokument? fra(Map<String, dynamic> j) {
    final id = j['id'];
    final number = j['number'];
    if (id is! num || number is! String) return null;
    return KvDokument(
      id: id.toInt(),
      type: '${j['type'] ?? 'kvittering'}',
      number: number,
      issuedAt: DateTime.tryParse('${j['issued_at'] ?? ''}')?.toLocal(),
      totalOre: (j['total_ore'] is num) ? (j['total_ore'] as num).toInt() : 0,
      storeName: j['store_name'] as String?,
      orderCode: j['order_code'] as String?,
      refersTo: j['refers_to'] as String?,
    );
  }
}

class KvitteringerScreen extends StatefulWidget {
  const KvitteringerScreen({super.key, this.api, this.share});

  final OpsCustomerApi? api;

  /// Hands the PDF bytes on instead of the share sheet (tests pass their own).
  final Future<void> Function(List<int> pdf, String number)? share;

  @override
  State<KvitteringerScreen> createState() => _KvitteringerScreenState();
}

class _KvitteringerScreenState extends State<KvitteringerScreen> {
  late final OpsCustomerApi _api = widget.api ?? OpsCustomerApi();
  List<KvDokument>? _docs;
  int? _henter;

  @override
  void initState() {
    super.initState();
    _hent();
  }

  Future<void> _hent() async {
    final list = await _api.documents();
    if (mounted) setState(() => _docs = list.map(KvDokument.fra).whereType<KvDokument>().toList());
  }

  Future<void> _apne(KvDokument d) async {
    if (_henter != null) return;
    setState(() => _henter = d.id);
    try {
      final pdf = await _api.documentPdf(d.id);
      if (!mounted) return;
      if (pdf == null) {
        showBergenToast(context, KvitteringerCopy.feil, icon: Icons.error_outline_rounded);
        return;
      }
      if (widget.share != null) {
        await widget.share!(pdf, d.number);
        return;
      }
      final dir = await getTemporaryDirectory();
      final fil = File('${dir.path}/${d.number}.pdf');
      await fil.writeAsBytes(pdf, flush: true);
      if (!mounted) return;
      // iOS 26 refuses a share sheet without an anchor (sharePositionOrigin).
      final box = context.findRenderObject() as RenderBox?;
      final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
      await Share.shareXFiles(
        [XFile(fil.path, mimeType: 'application/pdf')],
        subject: d.number,
        sharePositionOrigin: origin,
      );
    } finally {
      if (mounted) setState(() => _henter = null);
    }
  }

  static String _dato(DateTime? t) => t == null ? '' : '${t.day}.${t.month}.${t.year}';

  @override
  Widget build(BuildContext context) {
    final docs = _docs;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F3EF),
        foregroundColor: const Color(0xFF23201D),
        elevation: 0,
        title: Text(
          KvitteringerCopy.tittel,
          style: inter(18, weight: FontWeight.w800, color: const Color(0xFF23201D)),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _hent,
        child: ListView(
          key: const Key('ops-kvitteringer'),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Text(KvitteringerCopy.linje, style: inter(13.5, color: const Color(0xFF6B655C), height: 1.4)),
            const SizedBox(height: 16),
            if (docs == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (docs.isEmpty)
              Text(
                KvitteringerCopy.ingen,
                key: const Key('ops-kv-ingen'),
                style: inter(14, color: const Color(0xFF6B655C)),
              )
            else
              for (final d in docs) _rad(d),
          ],
        ),
      ),
    );
  }

  Widget _rad(KvDokument d) {
    final under = [_dato(d.issuedAt), if ((d.storeName ?? '').isNotEmpty) d.storeName!, if (d.erKreditnota && d.refersTo != null) d.refersTo!].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          key: Key('ops-kv-${d.id}'),
          borderRadius: BorderRadius.circular(16),
          onTap: () => _apne(d),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE4E0D8)),
            ),
            child: Row(
              children: [
                Icon(d.erKreditnota ? Icons.undo_rounded : (d.erBekreftelse ? Icons.check_circle_outline_rounded : Icons.receipt_long_rounded), color: const Color(0xFF1E4F5C)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${d.navn} ${d.number}',
                        style: inter(14.5, weight: FontWeight.w800, color: const Color(0xFF23201D)),
                      ),
                      if (under.isNotEmpty) Text(under, style: inter(12, color: const Color(0xFF6B655C))),
                    ],
                  ),
                ),
                if (_henter == d.id)
                  const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                else
                  Text(
                    KasseCopy.kr(d.totalOre / 100),
                    style: inter(14.5, weight: FontWeight.w800, color: d.erKreditnota ? const Color(0xFF8A3B2E) : const Color(0xFF23201D)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
