// ignore_for_file: non_constant_identifier_names
import 'package:flutter/material.dart';

import '../../../data/aegil/aegil_app_models.dart';
import '../../../data/aegil/against_interest_models.dart';
import '../../../utils/utils.dart' show resolveSelectedLanguage;
import '../../common/auth/launch/lf_css.dart';
import 'aegil_bits.dart';
import 'aegil_chat.dart';

// ── Customer Step 5: the chat's tool cards (`tool_cards`) ───────────────────
//
// The chat on the gateway answers with typed cards the commerce layer filled:
// an order's status (T14), the basket (T19), a cart change Ægil proposes —
// the tap applies it and the card turns into the receipt with «Angre» (T05,
// `agKvittering`) — a person (Hjelp), Min bio, products. Not in the design
// except T05 and T21: built from the chat's own card row (`AeKortRad`) and
// the reply states' white paper card.

abstract final class AeVerktoyCopy {
  static bool get _en => resolveSelectedLanguage() == 'en';
  static String _t(String no, String en) => _en ? en : no;

  static String get cus_aegil_folg => _t('Følg', 'Follow');
  static String get cus_aegil_se => _t('Se', 'View');
  static String get cus_aegil_aapne => _t('Åpne', 'Open');
  static String get cus_aegil_kurven => _t('Kurven', 'Basket');
  static String get cus_aegil_kurv_tom => _t('Kurven er tom', 'The basket is empty');
  static String cus_aegil_varer(int n) => _t(n == 1 ? '1 vare' : '$n varer', n == 1 ? '1 item' : '$n items');
  static String get cus_aegil_menneske => _t('Snakk med et menneske', 'Talk to a person');
  static String get cus_aegil_menneske_sub => _t('Hjelp · et menneske svarer', 'Help · a person answers');
  static String get cus_aegil_bio => _t('Lagre i bioen din?', 'Save it in your bio?');
  static String get cus_aegil_bio_sub => _t('Bare det du velger blir lagret', 'Only what you pick is saved');
  static String get cus_aegil_bio_cta => _t('Min bio', 'My bio');
  static String get cus_aegil_legg_eyebrow => _t('Legg i kurven', 'Add to basket');
  static String get cus_aegil_ta_ut_eyebrow => _t('Ta ut av kurven', 'Remove from basket');
  static String get cus_aegil_bytt_eyebrow => _t('Bytt i kurven', 'Swap in basket');
  static String get cus_aegil_legg => _t('Legg i kurven', 'Add');
  static String get cus_aegil_ta_ut => _t('Ta ut', 'Remove');
  static String get cus_aegil_bytt => _t('Bytt', 'Swap');
  static String get cus_aegil_nei_takk => _t('Nei takk', 'No thanks');
  static String get cus_aegil_kvittering => _t('Kvittering', 'Receipt');
  static String get cus_aegil_angre => _t('Angre', 'Undo');
  static String get cus_aegil_angret => _t('Angret', 'Undone');
  static String get cus_aegil_avslaatt => _t('Ikke gjort', 'Not done');
  static String get cus_aegil_utlopt => _t('Forslaget gjelder ikke lenger', 'The proposal no longer applies');
  static String get cus_aegil_feilet => _t('Det gikk ikke. Prøv i kurven.', 'That did not work. Try in the basket.');
  static String get cus_aegil_ai => _t('AI', 'AI');
  static String get cus_aegil_er_ai => _t('Ægil er en AI', 'Ægil is an AI');
  static String get cus_aegil_ny_samtale => _t('Ny prat', 'New chat');
  static String get cus_aegil_spor => _t('Spør Ægil', 'Ask Ægil');
  static String cus_aegil_ktx_ordre(String nr) => _t('Om $nr', 'About $nr');
}

/// One tool card, by type.
class AeVerktoyKort extends StatelessWidget {
  const AeVerktoyKort({super.key, required this.v, required this.h});

  final AeVerktoy v;
  final AeHandling h;

  static const String _bil = 'M6 17a3 3 0 1 0 0-.1M18 17a3 3 0 1 0 0-.1M6 17l4-8h5l3 8M10 9l-1-3H7';
  static const String _kurv = 'M5 8h14l-1.5 11h-11zM9 8a3 3 0 0 1 6 0';
  static const String _person = 'M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM4.5 20.5c1.3-4 4-6 7.5-6s6.2 2 7.5 6';
  static const String _blad = 'M5 19c0-8 5-13 14-14-1 9-6 14-14 14zM5 19l7-7';

  static String _kr(Map<String, dynamic> m) => (m['display'] as String?) ?? (m['amount_ore'] is num ? '${((m['amount_ore'] as num) / 100).round()} kr' : '');

  @override
  Widget build(BuildContext context) => switch (v.type) {
    'order_status' => _ordre(v.map('order')),
    'order_list' => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, o) in ((v.data['orders'] as List?) ?? const []).whereType<Map>().take(3).indexed) ...[
          if (i > 0) const SizedBox(height: 8),
          _ordreRad(o.cast<String, dynamic>()),
        ],
      ],
    ),
    'cart' => _kurvKort(),
    'handoff' => AeKortRad(
      tile: const AeTile(d: _person),
      tittel: AeVerktoyCopy.cus_aegil_menneske,
      sub: AeVerktoyCopy.cus_aegil_menneske_sub,
      cta: AeVerktoyCopy.cus_aegil_aapne,
      lagt: false,
      onTap: h.menneske,
    ),
    'bio_offer' => AeKortRad(
      tile: const AeTile(d: _blad),
      tittel: AeVerktoyCopy.cus_aegil_bio,
      sub: AeVerktoyCopy.cus_aegil_bio_sub,
      cta: AeVerktoyCopy.cus_aegil_bio_cta,
      lagt: false,
      onTap: h.minBio,
    ),
    'products' => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, p) in ((v.data['items'] as List?) ?? const []).whereType<Map>().take(3).indexed) ...[
          if (i > 0) const SizedBox(height: 8),
          _vare(p.cast<String, dynamic>()),
        ],
      ],
    ),
    'cart_proposal' => AeEndringKort(v: v, h: h),
    'gate' || 'error' => _notis((v.data['copy'] as String?) ?? AeVerktoyCopy.cus_aegil_feilet),
    _ => const SizedBox.shrink(),
  };

  Widget _ordre(Map<String, dynamic> o) => AeKortRad(
    tile: const AeTile(d: _bil),
    tittel: [o['number'], o['store']].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
    sub: [o['status'], o['window']].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
    cta: AeVerktoyCopy.cus_aegil_folg,
    lagt: false,
    onTap: () => h.sporing((o['id'] as num?)?.toInt() ?? 0),
  );

  Widget _ordreRad(Map<String, dynamic> o) {
    final store = o['store'] is Map ? (o['store'] as Map)['name'] : o['store'];
    final status = o['status'] is Map ? (o['status'] as Map)['label'] : o['status'];
    final total = o['total'] is Map ? _kr((o['total'] as Map).cast<String, dynamic>()) : '';
    return AeKortRad(
      tile: const AeTile(d: _bil),
      tittel: [o['number'], store].whereType<String>().join(' · '),
      sub: [status, total].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
      cta: AeVerktoyCopy.cus_aegil_se,
      lagt: false,
      onTap: () => h.sporing((o['id'] as num?)?.toInt() ?? 0),
    );
  }

  Widget _kurvKort() {
    final lines = ((v.data['lines'] as List?) ?? const []).whereType<Map>().toList();
    final n = lines.fold<int>(0, (a, l) => a + ((l['quantity'] as num?)?.toInt() ?? 1));
    final store = v.map('store')['name'] as String?;
    return AeKortRad(
      tile: const AeTile(d: _kurv),
      tittel: [AeVerktoyCopy.cus_aegil_kurven, if (store != null && store.isNotEmpty) store].join(' · '),
      sub: lines.isEmpty ? AeVerktoyCopy.cus_aegil_kurv_tom : '${AeVerktoyCopy.cus_aegil_varer(n)} · ${_kr(v.map('subtotal'))}',
      cta: AeVerktoyCopy.cus_aegil_aapne,
      lagt: false,
      onTap: () => h.app(AeApp.kurv),
    );
  }

  Widget _vare(Map<String, dynamic> p) {
    final store = p['store'] is Map ? (p['store'] as Map).cast<String, dynamic>() : const <String, dynamic>{};
    final pris = p['price'] is Map ? _kr((p['price'] as Map).cast<String, dynamic>()) : null;
    final storeId = (store['id'] as num?)?.toInt();
    return AeKortRad(
      tile: const AeTile(d: _kurv),
      tittel: '${p['name'] ?? ''}',
      sub: '${store['name'] ?? ''}',
      pris: pris,
      cta: AeVerktoyCopy.cus_aegil_se,
      lagt: false,
      onTap: () => storeId == null ? null : h.aapneButikk(storeId),
    );
  }

  Widget _notis(String tekst) => CssBox(
    radius: BorderRadius.circular(16),
    bg: kAeRadGlass,
    shadows: kAeRadGlassSh,
    border: Border.all(color: const Color.fromRGBO(255, 255, 255, .18)),
    padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
    child: Text(tekst, style: inter(12.5, weight: FontWeight.w700, height: 1.4, color: kAeSub)),
  );
}

/// A cart change Ægil proposes (`cart_proposal`): the white card with the
/// change and the tap; applied, the receipt with «Angre» (T05 `agKvittering`:
/// 30 px tile, «Kvittering», − old / + new, the pill); undone or refused, dim.
class AeEndringKort extends StatelessWidget {
  const AeEndringKort({super.key, required this.v, required this.h});

  final AeVerktoy v;
  final AeHandling h;

  static const Color _minus = Color(0xFFB9441A);
  static const Color _pluss = Color(0xFF2E6B47);

  String get _handling => (v.data['action'] as String?) ?? 'add';

  String get _vare => (v.map('product')['name'] as String?) ?? '';
  String get _linje => (v.map('line')['name'] as String?) ?? '';
  int get _qty => (v.data['qty'] as num?)?.toInt() ?? 1;
  String? get _pris {
    final ore = (v.map('product')['price_ore'] as num?)?.toInt();
    return ore == null || ore <= 0 ? null : '${(ore * (_handling == 'add' ? _qty : 1) / 100).round()} kr';
  }

  @override
  Widget build(BuildContext context) {
    final status = v.status;
    if (status == 'applied' || status == 'undone') return _kvittering(status == 'undone');
    final dempet = status != 'proposed';
    final venter = h.venter(v.id ?? '');
    final (eyebrow, knapp) = switch (_handling) {
      'remove' => (AeVerktoyCopy.cus_aegil_ta_ut_eyebrow, AeVerktoyCopy.cus_aegil_ta_ut),
      'swap' => (AeVerktoyCopy.cus_aegil_bytt_eyebrow, AeVerktoyCopy.cus_aegil_bytt),
      _ => (AeVerktoyCopy.cus_aegil_legg_eyebrow, AeVerktoyCopy.cus_aegil_legg),
    };
    final tekst = switch (_handling) {
      'remove' => _linje,
      'swap' => '$_linje → $_vare',
      _ => _qty > 1 ? '$_qty× $_vare' : _vare,
    };
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: dempet ? .55 : 1,
      child: CssBox(
        key: Key('cus-aegil-forslag-${v.id}'),
        radius: BorderRadius.circular(18),
        bg: const [CssSolid(Colors.white)],
        shadows: kAePapirSh,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(eyebrow, style: inter(11, weight: FontWeight.w800, color: const Color(0xFF8C847C))),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(child: Text(tekst, style: inter(13.5, weight: FontWeight.w800, height: 1.35, color: kAeInk))),
                if (_pris != null && _handling != 'remove') ...[const SizedBox(width: 8), Text(_pris!, style: aeTab(inter(13, weight: FontWeight.w800, color: kAeInk)))],
              ],
            ),
            if (dempet) ...[
              const SizedBox(height: 6),
              Text(
                switch (status) {
                  'expired' => AeVerktoyCopy.cus_aegil_utlopt,
                  'declined' => AeVerktoyCopy.cus_aegil_avslaatt,
                  _ => (v.data['error_copy'] as String?) ?? AeVerktoyCopy.cus_aegil_feilet,
                },
                style: inter(11.5, weight: FontWeight.w700, color: const Color(0xFF57534B)),
              ),
            ] else ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: AePress(
                      key: Key('cus-aegil-forslag-bruk-${v.id}'),
                      onTap: venter ? () {} : () => h.brukForslag(v),
                      dy: 0,
                      scale: .97,
                      child: Container(
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: const Color(0xFFF26D3D)),
                        child: venter
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: kAeInk))
                            : Text(knapp, style: inter(12.5, weight: FontWeight.w800, color: kAeInk)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  AePress(
                    onTap: () => h.avslaa(v),
                    dy: 0,
                    scale: .95,
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: const Color(0xFFDCE9EC)),
                      child: Text(AeVerktoyCopy.cus_aegil_nei_takk, style: inter(12.5, weight: FontWeight.w800, color: kAeInk)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// T05: `border-radius:18px; padding:10px 12px; gap:10px`, the 30 px tile
  /// (`rgba(30,79,92,.1)`, r10), «Kvittering» 11/800 `#8C847C`, the change
  /// 12.5/700 tabular (− `#B9441A`, + `#2E6B47`), «Angre» `#DCE9EC` 12/800.
  Widget _kvittering(bool angret) {
    final venter = h.venter(v.id ?? '');
    final pris = _pris;
    final linjeOre = ((v.map('line')['price_ore'] as num?)?.toInt() ?? 0) * ((v.map('line')['qty'] as num?)?.toInt() ?? 1);
    final minus = switch (_handling) {
      'remove' || 'swap' => '− $_linje${linjeOre > 0 ? ' · ${(linjeOre / 100).round()} kr' : ''}',
      _ => null,
    };
    final pluss = switch (_handling) {
      'remove' => null,
      _ => '+ ${_qty > 1 && _handling == 'add' ? '$_qty× ' : ''}$_vare${pris == null ? '' : ' · $pris'}',
    };
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: angret ? .6 : 1,
      child: AeOnce(
        kind: AeInn.vcKort,
        ms: 500,
        curve: const Cubic(.3, 1.2, .5, 1),
        child: CssBox(
          key: Key('cus-aegil-kvittering-${v.id}'),
          radius: BorderRadius.circular(18),
          bg: const [CssSolid(Colors.white)],
          shadows: kAePapirSh,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: const Color.fromRGBO(30, 79, 92, .1)),
                alignment: Alignment.center,
                child: const AeIkon('M4 7h16M4 12h10M4 17h7', size: 14, stroke: 2.2, color: kAeTeal),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AeVerktoyCopy.cus_aegil_kvittering, style: inter(11, weight: FontWeight.w800, color: const Color(0xFF8C847C))),
                    const SizedBox(height: 1),
                    Text.rich(
                      TextSpan(
                        children: [
                          if (minus != null) TextSpan(text: minus, style: const TextStyle(color: _minus)),
                          if (minus != null && pluss != null) const TextSpan(text: '   '),
                          if (pluss != null) TextSpan(text: pluss, style: const TextStyle(color: _pluss)),
                        ],
                      ),
                      style: aeTab(inter(12.5, weight: FontWeight.w700, height: 1.35, color: kAeInk)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (angret)
                Text(AeVerktoyCopy.cus_aegil_angret, style: inter(12, weight: FontWeight.w800, color: const Color(0xFF8C847C)))
              else
                AePress(
                  key: Key('cus-aegil-angre-${v.id}'),
                  onTap: venter ? () {} : () => h.angre(v),
                  dy: 0,
                  scale: .94,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color(0xFFDCE9EC)),
                    child: Text(AeVerktoyCopy.cus_aegil_angre, style: inter(12, weight: FontWeight.w800, color: kAeInk)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// T21 «Mot egen interesse» (locked): Ægil's mark and the line, bold, above
/// the item it is about — what Ægil found against the sale, as the server
/// rendered it.
class AeMotInteresse extends StatelessWidget {
  const AeMotInteresse({super.key, required this.line});

  final AgainstInterestLine line;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.only(top: 4), child: AeGevir(color: kAeMintLys, w: 16, h: 10)),
        const SizedBox(width: 7),
        Expanded(child: Text(line.line, style: inter(13, weight: FontWeight.w800, height: 1.4, em: -.01, color: Colors.white))),
      ],
    ),
  );
}

/// «Ægil er en AI» in the sheet header (Customer §4.1): a small pill after
/// the name. Not in the design.
class AeAiMerke extends StatelessWidget {
  const AeAiMerke({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: AeVerktoyCopy.cus_aegil_er_ai,
    excludeSemantics: true,
    child: CssBox(
      key: const Key('cus-aegil-ai-merke'),
      height: 18,
      radius: BorderRadius.circular(999),
      bg: const [CssSolid(Color.fromRGBO(255, 255, 255, .12))],
      border: Border.all(color: const Color.fromRGBO(159, 240, 212, .45)),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Center(widthFactor: 1, child: Text(AeVerktoyCopy.cus_aegil_ai, style: inter(10, weight: FontWeight.w800, height: 1, em: .04, color: kAeMintLys))),
    ),
  );
}

/// The chat's top row (Customer Step 5): «Ny prat», «Snakk med et menneske»
/// (→ Hjelp), and «Ægil er en AI» under them.
class AeChatTopp extends StatelessWidget {
  const AeChatTopp({super.key, required this.onNy, required this.onMenneske});

  final VoidCallback onNy;
  final VoidCallback onMenneske;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          AeNyPrat(onTap: onNy),
          AePress(
            key: const Key('cus-aegil-menneske'),
            onTap: onMenneske,
            dy: 1.5,
            child: CssBox(
              radius: BorderRadius.circular(999),
              bg: const [CssSolid(Color.fromRGBO(255, 255, 255, .08))],
              shadows: const [CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .14))],
              padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AeIkon('M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM4.5 20.5c1.3-4 4-6 7.5-6s6.2 2 7.5 6', size: 11, stroke: 2.8, color: kAeMintLys),
                  const SizedBox(width: 6),
                  Text(AeVerktoyCopy.cus_aegil_menneske, style: inter(11, weight: FontWeight.w800, color: kAeSub)),
                ],
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 7),
      Text(AeVerktoyCopy.cus_aegil_er_ai, key: const Key('cus-aegil-er-ai'), style: inter(10.5, weight: FontWeight.w700, color: const Color.fromRGBO(191, 214, 221, .7))),
    ],
  );
}
