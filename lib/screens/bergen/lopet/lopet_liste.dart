import 'package:flutter/material.dart';

import '../../../networking/api_base_helper.dart';
import '../../../networking/api_constant.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../kit/bergen_kit.dart';
import 'lopet_copy.dart';

/// Points plan Step 12 (game spec §6.2, §5.4): the server's Ukens led (`GET /game/ladder`) and the summary for Levert
/// and Meg (`GET /game/summary`). Null offline or when the game is off.
class LopetListeApi {
  LopetListeApi({ApiBaseHelper? helper}) : _helper = helper ?? ApiBaseHelper(baseUrl: BaseUrl.domain);

  final ApiBaseHelper _helper;

  Future<Map<String, dynamic>?> _get(String path, [Map<String, String> extra = const {}]) async {
    final auth = OpsCustomerApi.authParams();
    if (auth == null || !OpsCustomerApi.networkEnabled) return null;
    try {
      final json = await _helper.get('$path?${Uri(queryParameters: {...auth, ...extra}).query}');
      return json is Map<String, dynamic> && json['status'] == 1 ? json : null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> ladder({String? week}) async => (await _get('api/game/ladder', {if (week != null) 'week': week}))?['ladder'] as Map<String, dynamic>?;

  Future<Map<String, dynamic>?> summary() async => (await _get('api/game/summary'))?['summary'] as Map<String, dynamic>?;
}

/// «Ukens liste» (game spec §6.2): the prizes on top, the top ten with names from Bergen-ligaen («Seiler N» for the
/// rest), metres and losgrad, your own place.
abstract final class LopetListe {
  static Future<void> vis(BuildContext context, {LopetListeApi? api}) async {
    final data = await (api ?? LopetListeApi()).ladder();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF123640),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (ctx) => _Ark(data: data),
    );
  }

  static String premie(Map p) {
    final fra = (p['from'] as num?)?.toInt() ?? 0;
    final til = (p['to'] as num?)?.toInt() ?? 0;
    final plass = fra == til ? '$fra.' : '$fra.–$til.';
    final hva = p['kind'] == 'voucher' ? LopetCopy.premieHylle('${p['shelf'] ?? ''}') : LopetCopy.premiePoeng((p['points'] as num?)?.toInt() ?? 0);
    return '$plass $hva';
  }
}

class _Ark extends StatelessWidget {
  const _Ark({required this.data});
  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context) {
    final d = data;
    final top = ((d?['top'] as List?) ?? const []).whereType<Map>().toList();
    final own = d?['own'] as Map?;
    final premier = ((d?['prizes'] as List?) ?? const []).whereType<Map>().toList();
    final medEgen = own != null && !top.any((r) => r['me'] == true);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .86),
        child: ListView(
          key: const Key('lopet-ukeliste'),
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: [
            Text(LopetCopy.ukeliste, style: BergenTokens.display(24, weight: FontWeight.w800, color: Colors.white, letterSpacingEm: -0.02)),
            const SizedBox(height: 4),
            Text(d == null ? LopetCopy.ukelisteTom : LopetCopy.ukelisteLinje((d['sailors'] as num?)?.toInt() ?? 0), style: BergenTokens.text(13, weight: FontWeight.w600, color: Colors.white70)),
            if (premier.isNotEmpty && d?['prizes_enabled'] != false) ...[
              const SizedBox(height: 14),
              Container(
                key: const Key('lopet-ukeliste-premier'),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(color: const Color(0x22F2C14E), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x55F2C14E))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final p in premier)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text(LopetListe.premie(p), style: BergenTokens.text(13, weight: FontWeight.w700, color: const Color(0xFFF7D57E))),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            for (final r in top) _Rad(r: r),
            if (medEgen) ...[
              const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Center(child: Text('···', style: TextStyle(color: Colors.white38)))),
              _Rad(r: own),
            ],
            if (top.isEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(LopetCopy.ukelisteIngen, style: BergenTokens.text(13, weight: FontWeight.w600, color: Colors.white60))),
          ],
        ),
      ),
    );
  }
}

class _Rad extends StatelessWidget {
  const _Rad({required this.r});
  final Map r;

  @override
  Widget build(BuildContext context) {
    final meg = r['me'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(color: meg ? const Color(0x33E5532D) : const Color(0x14FFFFFF), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('${r['place']}', style: BergenTokens.text(14, weight: FontWeight.w800, color: Colors.white))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${r['name'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: BergenTokens.text(13.5, weight: FontWeight.w800, color: Colors.white)),
                Text('${r['losgrad'] ?? ''}', style: BergenTokens.text(11.5, weight: FontWeight.w600, color: Colors.white60)),
              ],
            ),
          ),
          Text('${r['best_m']} m', style: BergenTokens.text(14, weight: FontWeight.w800, color: const Color(0xFF7FF0CB))),
        ],
      ),
    );
  }
}
