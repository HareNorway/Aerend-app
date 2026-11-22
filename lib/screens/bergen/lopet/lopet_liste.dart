import 'package:flutter/material.dart';

import '../../../networking/api_base_helper.dart';
import '../../../networking/api_constant.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../kit/bergen_kit.dart';
import 'lopet_copy.dart';
import 'lopet_data.dart';
import 'lopet_kai.dart' show LopetArk;

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

/// «Ukeliste» (game spec §6.2; Design 21 Nov plan Step 7, design `Fjordløpet · Ukeliste`): Ukens premier from the
/// server's ladder awards, «Dine merker denne uken» (the week's three badges as rings), the top ten (names from
/// Bergen-ligaen, «Seiler N» for the rest), and outside it the «Rivalen» card and the customer's own row.
abstract final class LopetListe {
  static Future<void> vis(BuildContext context, {LopetListeApi? api, LopetState? s}) async {
    final data = await (api ?? LopetListeApi()).ladder();
    if (!context.mounted) return;
    await LopetArk.vis(context, (ctx) => _Ark(data: data, s: s));
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
  const _Ark({required this.data, this.s});
  final Map<String, dynamic>? data;
  final LopetState? s;

  @override
  Widget build(BuildContext context) {
    final d = data;
    final top = ((d?['top'] as List?) ?? const []).whereType<Map>().toList();
    final own = d?['own'] as Map?;
    final rival = d?['rival'] as Map?;
    final premier = ((d?['prizes'] as List?) ?? const []).whereType<Map>().toList();
    final medEgen = own != null && !top.any((r) => r['me'] == true);
    final week = '${d?['week'] ?? s?.week ?? ''}';
    final badges = s?.badges ?? const <LopetBadge>[];
    final tatt = badges.where((b) => b.done).length;
    return LopetArk(
      arkKey: const Key('lopet-ukeliste'),
      tittel: LopetCopy.ukeliste,
      linje: week.isEmpty ? (d == null ? LopetCopy.ukelisteTom : LopetCopy.ukelisteLinje((d['sailors'] as num?)?.toInt() ?? 0)) : LopetCopy.kaiUke(week),
      children: [
        if (premier.isNotEmpty && d?['prizes_enabled'] != false) ...[
          _Boks(
            key: const Key('lopet-ukeliste-premier'),
            children: [
              Text(LopetCopy.listePremier, style: _kick()),
              const SizedBox(height: 8),
              for (var i = 0; i < premier.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(
                      width: 96,
                      child: Text(
                        LopetCopy.listePlass((premier[i]['from'] as num?)?.toInt() ?? 0, (premier[i]['to'] as num?)?.toInt() ?? 0),
                        style: BergenTokens.text(14, weight: FontWeight.w800, color: i == 0 ? const Color(0xFFF2C14E) : premier[i]['kind'] == 'voucher' ? Colors.white : const Color(0xFF7FF0CB)),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        premier[i]['kind'] == 'voucher' ? LopetCopy.listeHylle('${premier[i]['shelf'] ?? ''}') : LopetCopy.listePoeng((premier[i]['points'] as num?)?.toInt() ?? 0),
                        style: BergenTokens.text(14, weight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ]),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (badges.isNotEmpty) ...[
          _Boks(
            key: const Key('lopet-merker'),
            children: [
              Row(children: [
                Expanded(child: Text(LopetCopy.listeMerker, style: _kick())),
                Text(LopetCopy.listeAv(tatt, badges.length), style: BergenTokens.text(12.5, weight: FontWeight.w800, color: const Color(0xFFF7D57E))),
              ]),
              const SizedBox(height: 12),
              Row(children: [for (final b in badges.take(3)) Expanded(child: LopetMerkeRing(b: b))]),
            ],
          ),
          const SizedBox(height: 12),
        ],
        for (final r in top) _Rad(r: r),
        if (medEgen) ...[
          if (rival != null && ((rival['place'] as num?)?.toInt() ?? 0) > 10)
            Container(
              key: const Key('lopet-ukeliste-rival'),
              margin: const EdgeInsets.only(top: 4, bottom: 8),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: const Color.fromRGBO(255, 156, 122, .1), border: Border.all(color: const Color.fromRGBO(255, 156, 122, .5))),
              child: Row(children: [
                SizedBox(width: 40, child: Text('${rival['place']}.', style: BergenTokens.text(15, weight: FontWeight.w800, color: Colors.white))),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${rival['name'] ?? ''}', style: BergenTokens.text(14, weight: FontWeight.w800, color: Colors.white)),
                    Text(LopetCopy.listeRival(((rival['distance_m'] as num?)?.toInt() ?? 0) - ((own['best_m'] as num?)?.toInt() ?? 0)), style: BergenTokens.text(12, weight: FontWeight.w700, color: const Color(0xFFFF9C7A))),
                  ]),
                ),
                Text('${LopetCopy.tallTekst((rival['distance_m'] as num?)?.toInt() ?? 0)} m', style: BergenTokens.display(15, weight: FontWeight.w800, color: Colors.white)),
              ]),
            )
          else
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Center(child: Text('···', style: TextStyle(color: Colors.white38)))),
          _Rad(r: own),
        ],
        if (top.isEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(LopetCopy.ukelisteIngen, style: BergenTokens.text(13, weight: FontWeight.w600, color: Colors.white60))),
      ],
    );
  }
}

TextStyle _kick() => BergenTokens.text(12, weight: FontWeight.w800, color: Colors.white.withValues(alpha: .7)).copyWith(letterSpacing: 1.1);

class _Boks extends StatelessWidget {
  const _Boks({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: const Color.fromRGBO(4, 18, 26, .32), border: Border.all(color: const Color.fromRGBO(255, 255, 255, .1))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
  );
}

/// A badge as the design's ring: progress in mint (gold when taken), the icon, the name and «22 / 40 kasser».
class LopetMerkeRing extends StatelessWidget {
  const LopetMerkeRing({super.key, required this.b, this.pluss = 0});
  final LopetBadge b;

  /// What the last run added (the end card), not yet on the server.
  final int pluss;

  IconData get _ikon => switch (b.metric) {
        'crates' => Icons.grid_view_rounded,
        'near_misses' => Icons.bolt_rounded,
        'metres' => Icons.straighten_rounded,
        'buoy1_no_vest' => Icons.water_drop_outlined,
        'records' => Icons.star_outline_rounded,
        _ => Icons.keyboard_double_arrow_right_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final p = (b.progress + pluss).clamp(0, b.target);
    final ferdig = b.done || p >= b.target;
    final f = ferdig ? 1.0 : (p / (b.target == 0 ? 1 : b.target)).clamp(0.0, 1.0);
    final farge = ferdig ? const Color(0xFFF2C14E) : const Color(0xFF5CE0B8);
    return Column(children: [
      SizedBox(
        width: 58,
        height: 58,
        child: Stack(alignment: Alignment.center, children: [
          SizedBox.expand(child: CircularProgressIndicator(value: f, strokeWidth: 4, backgroundColor: Colors.white.withValues(alpha: .1), color: farge)),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3F8798), Color(0xFF1A4654)])),
            child: Icon(_ikon, size: 20, color: Colors.white.withValues(alpha: .9)),
          ),
        ]),
      ),
      const SizedBox(height: 8),
      Text(b.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: BergenTokens.text(13, weight: FontWeight.w800, color: Colors.white)),
      Text(ferdig ? LopetCopy.listeTatt : LopetCopy.merkeUnder(b.metric, p, b.target), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: BergenTokens.text(11.5, weight: FontWeight.w700, color: ferdig ? const Color(0xFFFFE3A3) : Colors.white.withValues(alpha: .7))),
    ]);
  }
}

class _Rad extends StatelessWidget {
  const _Rad({required this.r});
  final Map r;

  @override
  Widget build(BuildContext context) {
    final meg = r['me'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: meg ? const Color.fromRGBO(242, 109, 61, .2) : Colors.white.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: meg ? const Color.fromRGBO(242, 109, 61, .6) : Colors.white.withValues(alpha: .08)),
      ),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text('${r['place']}.', style: BergenTokens.text(15, weight: FontWeight.w800, color: Colors.white.withValues(alpha: .8)))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${r['name'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: BergenTokens.text(14.5, weight: FontWeight.w800, color: Colors.white)),
                Text('${r['losgrad'] ?? ''}', style: BergenTokens.text(12, weight: FontWeight.w600, color: Colors.white.withValues(alpha: .65))),
              ],
            ),
          ),
          Text('${LopetCopy.tallTekst((r['best_m'] as num?)?.toInt() ?? 0)} m', style: BergenTokens.display(15.5, weight: FontWeight.w800, color: Colors.white)),
        ],
      ),
    );
  }
}
