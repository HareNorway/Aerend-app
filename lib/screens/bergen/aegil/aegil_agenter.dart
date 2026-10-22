// ignore_for_file: non_constant_identifier_names
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../data/aegil/aegil_app_models.dart';
import '../../../utils/shared_pref_utill.dart';
import '../../../utils/utils.dart' show resolveSelectedLanguage;
import '../../common/auth/launch/lf_css.dart';
import 'aegil_bits.dart';
import 'aegil_chat.dart';

// ── Customer Step 9: the customer agents' cards in the chat ─────────────────
//
// Design «Ærend Kunde - agentfunksjoner C1-C4»: the gift brief as one card
// of chips (C1.2), the brief read back (C1.3), three gift cards rising up
// (C1.4/C1.5), the card text (C1.6), the honest empty card (C1.8); reorder
// by photo — the camera prompt (C3.2), one hit (C3.3), «Var det denne?»
// (C3.4), nothing recognised (C3.5). All on the chat's white paper card:
// `r18; white; 0 14px 26px −18px rgba(15,31,43,.5)`, keys teal `#1E4F5C`
// (`r999; 44pt`), secondary `rgba(35,32,29,.06)`.

abstract final class AeAgentCopy {
  static bool get _en => resolveSelectedLanguage() == 'en';
  static String _t(String no, String en) => _en ? en : no;

  // C1
  static String get cus_gave_fortell => _t('Fortell om den som skal få gaven.', 'Tell me about the one who gets the gift.');
  static String get cus_gave_til_hvem => _t('TIL HVEM', 'FOR WHOM');
  static String get cus_gave_anledning => _t('ANLEDNING', 'OCCASION');
  static String get cus_gave_budsjett => _t('BUDSJETT', 'BUDGET');
  static String get cus_gave_naar => _t('NÅR', 'WHEN');
  static String get cus_gave_liker => _t('Liker …', 'Likes …');
  static String get cus_gave_finn => _t('Finn gaver', 'Find gifts');
  static String get cus_gave_riktig => _t('Er det riktig?', 'Is that right?');
  static String get cus_gave_stemmer => _t('Stemmer', 'Correct');
  static String get cus_gave_endre => _t('Endre', 'Change');
  static String get cus_gave_velg => _t('Velg', 'Pick');
  static String get cus_gave_lagre => _t('Lagre', 'Save');
  static String get cus_gave_lagret => _t('Lagret', 'Saved');
  static String get cus_gave_se_tre_til => _t('Se tre til', 'Three more');
  static String get cus_gave_derfor => _t('Derfor:', 'Why:');
  static String get cus_gave_rekker => _t('Rekker fram', 'Arrives by');
  static String get cus_gave_kortet => _t('Kortet', 'The card');
  static String cus_gave_til(String navn) => _t('Til $navn', 'For $navn');
  static String get cus_gave_trykk => _t('Trykk i teksten for å endre', 'Tap the text to edit');
  static String get cus_gave_bruk_kortet => _t('Bruk kortet', 'Use the card');
  static String get cus_gave_skriv_om => _t('Skriv om', 'Rewrite');
  static String get cus_gave_uten_kort => _t('Uten kort', 'No card');
  static String get cus_gave_endre_budsjett => _t('Endre budsjett', 'Change budget');
  static String get cus_gave_i_kurven => _t('Gaven er i kurven · kortet følger med', 'The gift is in the basket · the card comes along');
  static String get cus_gave_ingen_flere => _t('Ingen flere som rekker fram', 'No more that arrive in time');
  static String get cus_gave_forrige => _t('Forrige tre er lagret under Lagret', 'The last three are kept under Saved');
  static String cus_gave_runde(int n) => _t('$n. runde', 'round $n');
  static const List<(String, String)> cus_gave_hvem = [('mamma', 'Mamma'), ('pappa', 'Pappa'), ('partner', 'Partner'), ('venn', 'Venn'), ('kollega', 'Kollega'), ('barn', 'Barn'), ('annet', 'Annet')];
  static const List<(String, String)> cus_gave_anledninger = [('bursdag', 'Bursdag'), ('jul', 'Jul'), ('takk', 'Takk'), ('bare_fordi', 'Bare fordi')];
  static const List<(String, String)> cus_gave_budsjetter = [('under_300', 'Under 300'), ('300_600', '300–600'), ('600_1000', '600–1 000'), ('more', 'Mer')];
  static const List<(String, String)> cus_gave_dager = [('today', 'I dag'), ('tomorrow', 'I morgen'), ('lørdag', 'Til lørdag'), ('date', 'Velg dato')];

  // C3
  static String get cus_bilde_ta => _t('Ta bilde av pakken eller strekkoden', 'Photograph the package or the barcode');
  static String get cus_bilde_slettes => _t('Bildet slettes etter 24 timer', 'The photo is deleted after 24 hours');
  static String get cus_bilde_ta_knapp => _t('Ta bilde', 'Take a photo');
  static String cus_bilde_fant(int ms) => _t('Fant den på ${(ms / 1000).toStringAsFixed(1).replaceAll('.', ',')} s', 'Found it in ${(ms / 1000).toStringAsFixed(1)} s');
  static String get cus_bilde_legg_til => _t('Legg til', 'Add');
  static String get cus_bilde_ikke_denne => _t('Ikke denne', 'Not this one');
  static String get cus_bilde_var_det => _t('Var det denne?', 'Was it this one?');
  static String get cus_bilde_ingen_av => _t('Ingen av disse', 'None of these');
  static String get cus_bilde_kjente_ikke => _t('Jeg kjente ikke igjen den.', 'I did not recognise it.');
  static String get cus_bilde_beklager => _t('Beklager.', 'Sorry.');
  static String get cus_bilde_prov => _t('Prøv strekkoden, eller skriv navnet.', 'Try the barcode, or type the name.');
  static String get cus_bilde_alder => _t('Den kan jeg ikke legge til for deg — aldersgrense.', 'I cannot add that for you — age restricted.');
  static String get cus_bilde_nytt => _t('Ta nytt bilde', 'New photo');
  static String get cus_bilde_strekkode => _t('Strekkode', 'Barcode');
  static String get cus_bilde_sok => _t('Søk', 'Search');
  static String get cus_bilde_lagt => _t('Lagt i kurven', 'Added to the basket');
  static String get cus_bilde_ingen_kamera => _t('Fant ikke kameraet · velg et bilde', 'No camera · pick a photo');

  // C4 (the chat's «Lagre»)
  static String cus_dor_lagret(String linje) => _t('Lagret · budet ser: $linje', 'Saved · the courier sees: $linje');
  static String get cus_dor_kode_denne => _t('Koden brukes bare på denne bestillingen', 'The code is used for this order only');
}

/// The gift the customer picked, waiting for the checkout: the Kasse shows
/// the gift line and attaches it to the order once placed.
abstract final class GiftPending {
  static const String _pref = 'a1_gave_venter';
  static GiftPendingInfo? _naa;

  /// The gift waiting for the checkout; kept in prefs so it survives a relaunch.
  static GiftPendingInfo? get current {
    if (_naa != null) return _naa;
    final raw = prefGetString(_pref);
    if (raw.isEmpty) return null;
    try {
      return _naa = GiftPendingInfo.fromJson((jsonDecode(raw) as Map).cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }

  static set current(GiftPendingInfo? v) {
    _naa = v;
    if (v == null) {
      prefRemove(_pref);
    } else {
      prefSetString(_pref, jsonEncode(v.toJson()));
    }
  }
}

class GiftPendingInfo {
  const GiftPendingInfo({required this.requestId, required this.storeId, required this.toLabel, this.cardText, required this.name});

  final int requestId;
  final int storeId;
  final String? toLabel;
  final String? cardText;
  final String name;

  Map<String, dynamic> toJson() => {'request_id': requestId, 'store_id': storeId, 'to_label': toLabel, 'card_text': cardText, 'name': name};

  factory GiftPendingInfo.fromJson(Map<String, dynamic> j) => GiftPendingInfo(
    requestId: (j['request_id'] as num?)?.toInt() ?? 0,
    storeId: (j['store_id'] as num?)?.toInt() ?? 0,
    toLabel: j['to_label'] as String?,
    cardText: j['card_text'] as String?,
    name: '${j['name'] ?? ''}',
  );
}

/// The brief the chips make (`to`, `occasion`, `budget`, `deliver_by`, `interests`).
class GiftBriefFields {
  String? to, occasion, budget, deliverBy;
  final TextEditingController liker = TextEditingController();

  int get valgt => [to, occasion, budget, deliverBy].whereType<String>().length;

  Map<String, dynamic> toMap() => {
    if (to != null) 'to': to,
    if (occasion != null) 'occasion': occasion,
    if (budget != null) 'budget': budget,
    if (deliverBy != null) 'deliver_by': deliverBy,
    if (liker.text.trim().isNotEmpty) 'interests': [liker.text.trim().replaceFirst(RegExp(r'^liker\s+', caseSensitive: false), '')],
  };
}

// ── Shared bits ─────────────────────────────────────────────────────────────

const Color _kPapir = Colors.white;
const Color _kMuted = Color(0xFF8C847C);
const Color _kGronn = Color(0xFF2E6B47);

Widget _papir({required Widget child, Key? key, EdgeInsets padding = const EdgeInsets.fromLTRB(14, 12, 14, 12)}) => ClipRRect(
  key: key,
  borderRadius: BorderRadius.circular(18),
  child: CssBox(
    radius: BorderRadius.circular(18),
    bg: const [CssSolid(_kPapir)],
    shadows: kAePapirSh,
    padding: padding,
    child: child,
  ),
);

Widget _eyebrow(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 6, top: 2),
  child: Text(t, style: inter(10.5, weight: FontWeight.w800, color: _kMuted).copyWith(letterSpacing: 1.1)),
);

/// A 44 pt chip (`r999`), teal when picked.
class AeChip extends StatelessWidget {
  const AeChip({super.key, required this.label, required this.on, required this.onTap});

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AePress(
    onTap: onTap,
    dy: 0,
    scale: .96,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: on ? kAeTeal : const Color(0xFFF5F3EF),
        border: Border.all(color: on ? kAeTeal : const Color.fromRGBO(35, 32, 29, .08)),
      ),
      child: Text(label, style: inter(12.5, weight: FontWeight.w800, color: on ? Colors.white : kAeInk)),
    ),
  );
}

/// The teal key (`r999; 44pt`) and its quiet sibling.
class AeNokkel extends StatelessWidget {
  const AeNokkel({super.key, required this.label, required this.onTap, this.sekundaer = false, this.av = false, this.smal = false, this.glass = false});

  final String label;
  final VoidCallback? onTap;
  final bool sekundaer;
  final bool av;
  final bool smal;

  /// Outside the paper card, on the chat's teal: white glass instead of the quiet grey.
  final bool glass;

  @override
  Widget build(BuildContext context) => AePress(
    onTap: av ? null : onTap,
    dy: sekundaer ? 0 : 2,
    scale: .97,
    child: Container(
      height: smal ? 38 : 44,
      padding: EdgeInsets.symmetric(horizontal: smal ? 14 : 18),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: glass ? Color.fromRGBO(255, 255, 255, av ? .08 : .16) : (sekundaer ? const Color.fromRGBO(35, 32, 29, .06) : (av ? const Color.fromRGBO(30, 79, 92, .35) : kAeTeal)),
        border: glass ? Border.all(color: const Color.fromRGBO(255, 255, 255, .22)) : null,
        boxShadow: sekundaer || av || glass ? null : const [BoxShadow(color: Color.fromRGBO(15, 31, 43, .35), offset: Offset(0, 8), blurRadius: 16, spreadRadius: -10)],
      ),
      child: Text(label, style: inter(smal ? 12.5 : 13.5, weight: FontWeight.w800, color: sekundaer && !glass ? kAeInk : Colors.white)),
    ),
  );
}

// ── C1 · the brief (C1.2 / C1.9) ────────────────────────────────────────────

/// «Fortell om den som skal få gaven.» — chips, one free line, «Finn gaver»
/// (live after two chips). Prefilled from the chat line («mamma», «lørdag»).
class AeGaveBrief extends StatefulWidget {
  const AeGaveBrief({super.key, required this.v, required this.h});

  final AeVerktoy v;
  final AeHandling h;

  @override
  State<AeGaveBrief> createState() => _AeGaveBriefState();
}

class _AeGaveBriefState extends State<AeGaveBrief> {
  final GiftBriefFields _f = GiftBriefFields();
  bool _sendt = false;

  @override
  void initState() {
    super.initState();
    final p = widget.v.map('prefill');
    _f.to = p['to'] as String?;
    _f.occasion = p['occasion'] as String?;
    final max = (p['budget_max_ore'] as num?)?.toInt();
    _f.budget = max == null ? null : (max <= 30000 ? 'under_300' : (max <= 60000 ? '300_600' : (max <= 100000 ? '600_1000' : 'more')));
    final d = p['deliver_by'] as String?;
    if (d != null) {
      final dt = DateTime.tryParse(d);
      final now = DateTime.now();
      if (dt != null) {
        final diff = DateTime(dt.year, dt.month, dt.day).difference(DateTime(now.year, now.month, now.day)).inDays;
        _f.deliverBy = diff <= 0 ? 'today' : (diff == 1 ? 'tomorrow' : (dt.weekday == DateTime.saturday ? 'lørdag' : d));
      }
    }
    final interests = (p['interests'] as List?)?.whereType<String>().toList() ?? const [];
    if (interests.isNotEmpty) _f.liker.text = 'Liker ${interests.first}';
    _f.liker.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _f.liker.dispose();
    super.dispose();
  }

  Widget _gruppe(String tittel, List<(String, String)> valg, String? naa, void Function(String?) sett, {String? Function(String)? annet}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: _eyebrow(tittel)),
      // The chip rows run under the card's side padding and cut at its rounded edge (the design's C1.2 cuts «Venn» there too).
      SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          children: [
            for (final (i, (k, l)) in valg.indexed) ...[
              if (i > 0) const SizedBox(width: 6),
              AeChip(key: Key('gave-$tittel-$k'), label: l, on: naa == k || (k == 'date' && naa != null && RegExp(r'^\d{4}-').hasMatch(naa)), onTap: () => sett(naa == k ? null : k)),
            ],
          ],
        ),
      ),
      const SizedBox(height: 10),
    ],
  );

  Future<void> _dato() async {
    final d = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 2)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 60)));
    if (d != null && mounted) setState(() => _f.deliverBy = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
  }

  @override
  Widget build(BuildContext context) {
    final klar = _f.valgt >= 2 && !_sendt;
    return _papir(
      key: const Key('ae-gave-brief'),
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text(AeAgentCopy.cus_gave_fortell, style: inter(13.5, weight: FontWeight.w800, color: kAeInk))),
          const SizedBox(height: 10),
          _gruppe(AeAgentCopy.cus_gave_til_hvem, AeAgentCopy.cus_gave_hvem, _f.to, (v) => setState(() => _f.to = v)),
          _gruppe(AeAgentCopy.cus_gave_anledning, AeAgentCopy.cus_gave_anledninger, _f.occasion, (v) => setState(() => _f.occasion = v)),
          _gruppe(AeAgentCopy.cus_gave_budsjett, AeAgentCopy.cus_gave_budsjetter, _f.budget, (v) => setState(() => _f.budget = v)),
          _gruppe(AeAgentCopy.cus_gave_naar, AeAgentCopy.cus_gave_dager, _f.deliverBy, (v) {
            if (v == 'date') {
              _dato();
            } else {
              setState(() => _f.deliverBy = v);
            }
          }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: const Color(0xFFF5F3EF), border: Border.all(color: const Color.fromRGBO(35, 32, 29, .08))),
              alignment: Alignment.centerLeft,
              child: TextField(
                key: const Key('gave-liker'),
                controller: _f.liker,
                style: inter(13, weight: FontWeight.w700, color: kAeInk),
                decoration: InputDecoration(isCollapsed: true, border: InputBorder.none, hintText: AeAgentCopy.cus_gave_liker, hintStyle: inter(13, weight: FontWeight.w700, color: _kMuted)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: AeNokkel(
              key: const Key('gave-finn'),
              label: AeAgentCopy.cus_gave_finn,
              av: !klar,
              onTap: () {
                setState(() => _sendt = true);
                widget.h.giftBrief(_f.toMap(), (widget.v.data['text'] as String?) ?? '');
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── C1 · the brief read back (C1.3) ─────────────────────────────────────────

class AeGaveLest extends StatelessWidget {
  const AeGaveLest({super.key, required this.v, required this.h});

  final AeVerktoy v;
  final AeHandling h;

  @override
  Widget build(BuildContext context) {
    final r = GiftResult.fromJson(v.map('gift'));
    final svart = v.data['svart'] == true;
    return _papir(
      key: const Key('ae-gave-lest'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(r.readback, style: inter(14, weight: FontWeight.w800, color: kAeInk, height: 1.35)),
          const SizedBox(height: 10),
          Row(
            children: [
              AeNokkel(key: const Key('gave-stemmer'), label: AeAgentCopy.cus_gave_stemmer, smal: true, av: svart, onTap: () => h.giftConfirm(r)),
              const SizedBox(width: 8),
              AeNokkel(key: const Key('gave-endre'), label: AeAgentCopy.cus_gave_endre, smal: true, sekundaer: true, onTap: () => h.giftEdit(r)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── C1 · three gift cards (C1.4 / C1.5) ─────────────────────────────────────

class AeGaveSett extends StatelessWidget {
  const AeGaveSett({super.key, required this.v, required this.h});

  final AeVerktoy v;
  final AeHandling h;

  @override
  Widget build(BuildContext context) {
    final r = GiftResult.fromJson(v.map('gift'));
    final valgt = (v.data['valgt'] as num?)?.toInt();
    final lagret = ((v.data['lagret'] as List?) ?? const []).map((e) => (e as num).toInt()).toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (r.round > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text('${AeAgentCopy.cus_gave_forrige} · ${AeAgentCopy.cus_gave_runde(r.round)}', style: inter(11.5, weight: FontWeight.w700, color: kAeSub)),
          ),
        for (final (i, c) in r.cards.indexed) ...[
          if (i > 0) const SizedBox(height: 8),
          _papir(
            key: Key('gave-kort-${c.storeProductId}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 60, height: 60, decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: LinearGradient(colors: kAeTintGaveList[i % kAeTintGaveList.length]))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.store, style: inter(11, weight: FontWeight.w700, color: _kMuted)),
                          const SizedBox(height: 1),
                          Text(c.name, style: inter(14, weight: FontWeight.w800, color: kAeInk)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(c.price, style: inter(13.5, weight: FontWeight.w800, color: kAeInk)),
                              if (c.deliver.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text('${AeAgentCopy.cus_gave_rekker} ${c.deliver}', style: inter(11.5, weight: FontWeight.w800, color: _kGronn)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: inter(11.5, weight: FontWeight.w700, color: const Color(0xFF57534B), height: 1.4),
                    children: [TextSpan(text: '${AeAgentCopy.cus_gave_derfor} ', style: inter(11.5, weight: FontWeight.w800, color: kAeInk)), TextSpan(text: c.reason)],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: AeNokkel(key: Key('gave-velg-${c.storeProductId}'), label: AeAgentCopy.cus_gave_velg, smal: true, av: valgt != null, onTap: () => h.giftChoose(r, c))),
                    const SizedBox(width: 8),
                    Expanded(child: AeNokkel(key: Key('gave-lagre-${c.storeProductId}'), label: lagret.contains(c.storeProductId) ? AeAgentCopy.cus_gave_lagret : AeAgentCopy.cus_gave_lagre, smal: true, sekundaer: true, onTap: () => h.giftSave(v, c))),
                  ],
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: AeNokkel(key: const Key('gave-tre-til'), label: AeAgentCopy.cus_gave_se_tre_til, smal: true, sekundaer: true, glass: true, av: !r.more && r.exhausted, onTap: () => h.giftMore(r))),
            const SizedBox(width: 8),
            Expanded(child: AeNokkel(key: const Key('gave-endre-sett'), label: AeAgentCopy.cus_gave_endre, smal: true, sekundaer: true, glass: true, onTap: () => h.giftEdit(r))),
          ],
        ),
      ],
    );
  }
}

const List<List<Color>> kAeTintGaveList = [
  [Color(0xFFCFE6D4), Color(0xFF9FCBAA)],
  [Color(0xFFEBDCC5), Color(0xFFD6B993)],
  [Color(0xFFCDE2E8), Color(0xFF9EC5D1)],
];

// ── C1 · the card text (C1.6) ───────────────────────────────────────────────

class AeGaveKort extends StatefulWidget {
  const AeGaveKort({super.key, required this.v, required this.h});

  final AeVerktoy v;
  final AeHandling h;

  @override
  State<AeGaveKort> createState() => _AeGaveKortState();
}

class _AeGaveKortState extends State<AeGaveKort> {
  late final TextEditingController _tekst = TextEditingController(text: GiftResult.fromJson(widget.v.map('gift')).cardText ?? '');

  @override
  void didUpdateWidget(AeGaveKort old) {
    super.didUpdateWidget(old);
    final ny = GiftResult.fromJson(widget.v.map('gift')).cardText ?? '';
    if (ny != (GiftResult.fromJson(old.v.map('gift')).cardText ?? '')) _tekst.text = ny;
  }

  @override
  void dispose() {
    _tekst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = GiftResult.fromJson(widget.v.map('gift'));
    final til = (widget.v.data['til'] as String?) ?? '';
    final brukt = widget.v.data['brukt'] == true;
    return _papir(
      key: const Key('ae-gave-kortet'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(AeAgentCopy.cus_gave_kortet, style: inter(14, weight: FontWeight.w800, color: kAeInk)),
              const Spacer(),
              if (til.isNotEmpty) Text(AeAgentCopy.cus_gave_til(til), style: inter(11.5, weight: FontWeight.w700, color: _kMuted)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: const Color(0xFFFBF7EE), border: Border.all(color: const Color.fromRGBO(35, 32, 29, .08))),
            child: TextField(
              key: const Key('gave-kort-tekst'),
              controller: _tekst,
              maxLines: null,
              readOnly: brukt,
              style: inter(13.5, weight: FontWeight.w700, color: kAeInk, height: 1.5),
              decoration: const InputDecoration(isCollapsed: true, border: InputBorder.none),
            ),
          ),
          const SizedBox(height: 6),
          Text(AeAgentCopy.cus_gave_trykk, style: inter(11, weight: FontWeight.w700, color: _kMuted)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: AeNokkel(key: const Key('gave-bruk-kortet'), label: AeAgentCopy.cus_gave_bruk_kortet, smal: true, av: brukt, onTap: () => widget.h.giftCard(r, 'use', _tekst.text))),
              const SizedBox(width: 8),
              Expanded(child: AeNokkel(key: const Key('gave-skriv-om'), label: AeAgentCopy.cus_gave_skriv_om, smal: true, sekundaer: true, av: brukt, onTap: () => widget.h.giftCard(r, 'rewrite', null))),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: AePress(
              onTap: brukt ? null : () => widget.h.giftCard(r, 'none', null),
              dy: 0,
              child: Padding(padding: const EdgeInsets.all(4), child: Text(AeAgentCopy.cus_gave_uten_kort, key: const Key('gave-uten-kort'), style: inter(12.5, weight: FontWeight.w800, color: kAeTeal))),
            ),
          ),
        ],
      ),
    );
  }
}

// ── C1 · the honest empty card (C1.8) ───────────────────────────────────────

class AeGaveTom extends StatelessWidget {
  const AeGaveTom({super.key, required this.v, required this.h});

  final AeVerktoy v;
  final AeHandling h;

  @override
  Widget build(BuildContext context) {
    final r = GiftResult.fromJson(v.map('gift'));
    return _papir(
      key: const Key('ae-gave-tom'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(r.text, style: inter(14, weight: FontWeight.w800, color: kAeInk, height: 1.35)),
          const SizedBox(height: 4),
          Text(r.sub, style: inter(12.5, weight: FontWeight.w700, color: const Color(0xFF57534B), height: 1.4)),
          const SizedBox(height: 10),
          Row(
            children: [
              if (r.nextDay != null) ...[
                Expanded(child: AeNokkel(key: const Key('gave-neste-dag'), label: r.nextLabel ?? r.nextDay!, smal: true, onTap: () => h.giftRetry(r, r.nextDay!))),
                const SizedBox(width: 8),
              ],
              Expanded(child: AeNokkel(key: const Key('gave-endre-budsjett'), label: AeAgentCopy.cus_gave_endre_budsjett, smal: true, sekundaer: true, onTap: () => h.giftEdit(r))),
            ],
          ),
        ],
      ),
    );
  }
}

// ── C3 · the camera prompt (C3.2) ───────────────────────────────────────────

class AeBildePrompt extends StatelessWidget {
  const AeBildePrompt({super.key, required this.v, required this.h});

  final AeVerktoy v;
  final AeHandling h;

  @override
  Widget build(BuildContext context) => _papir(
    key: const Key('ae-bilde-prompt'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 120,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: const Color(0xFF1A1917)),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(width: 150, height: 86, decoration: BoxDecoration(border: Border.all(color: Colors.white.withValues(alpha: .7), width: 2), borderRadius: BorderRadius.circular(8))),
              Text(AeAgentCopy.cus_bilde_ta, textAlign: TextAlign.center, style: inter(11.5, weight: FontWeight.w800, color: Colors.white)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        AeNokkel(key: const Key('bilde-ta'), label: AeAgentCopy.cus_bilde_ta_knapp, onTap: h.reorderShoot),
        const SizedBox(height: 6),
        Center(child: Text((v.data['note'] as String?) ?? AeAgentCopy.cus_bilde_slettes, style: inter(11, weight: FontWeight.w700, color: _kMuted))),
      ],
    ),
  );
}

// ── C3 · the result (C3.3 / C3.4 / C3.5) ────────────────────────────────────

class AeBildeSvar extends StatefulWidget {
  const AeBildeSvar({super.key, required this.v, required this.h});

  final AeVerktoy v;
  final AeHandling h;

  @override
  State<AeBildeSvar> createState() => _AeBildeSvarState();
}

class _AeBildeSvarState extends State<AeBildeSvar> {
  late final TextEditingController _sok = TextEditingController(text: ReorderResult.fromJson(widget.v.map('scan')).ocrText ?? '');

  @override
  void dispose() {
    _sok.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = ReorderResult.fromJson(widget.v.map('scan'));
    final gjort = widget.v.data['gjort'] as String?; // 'lagt' | 'nei'
    if (r.hit == 'one') {
      final c = r.candidates.first;
      return _papir(
        key: const Key('ae-bilde-treff'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 56, height: 56, decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: const LinearGradient(colors: [Color(0xFFCDE2E8), Color(0xFF9EC5D1)]))),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.store, style: inter(11, weight: FontWeight.w700, color: _kMuted)),
                      Text(c.name, style: inter(14, weight: FontWeight.w800, color: kAeInk)),
                      Text(c.price, style: inter(13.5, weight: FontWeight.w800, color: kAeInk)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: inter(11.5, weight: FontWeight.w700, color: const Color(0xFF57534B), height: 1.4),
                children: [TextSpan(text: '${AeAgentCopy.cus_gave_derfor} ', style: inter(11.5, weight: FontWeight.w800, color: kAeInk)), TextSpan(text: c.reason)],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: AeNokkel(key: const Key('bilde-legg-til'), label: gjort == 'lagt' ? AeAgentCopy.cus_bilde_lagt : AeAgentCopy.cus_bilde_legg_til, smal: true, av: gjort != null, onTap: () => widget.h.reorderChoose(widget.v, r, c))),
                const SizedBox(width: 8),
                Expanded(child: AeNokkel(key: const Key('bilde-ikke-denne'), label: AeAgentCopy.cus_bilde_ikke_denne, smal: true, sekundaer: true, av: gjort != null, onTap: () => widget.h.reorderChoose(widget.v, r, null))),
              ],
            ),
          ],
        ),
      );
    }
    if (r.hit == 'ask') {
      return _papir(
        key: const Key('ae-bilde-spor'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AeAgentCopy.cus_bilde_var_det, style: inter(14, weight: FontWeight.w800, color: kAeInk)),
            const SizedBox(height: 8),
            for (final (i, c) in r.candidates.indexed) ...[
              if (i > 0) const SizedBox(height: 6),
              Row(
                children: [
                  Container(width: 40, height: 40, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0xFFD9C3A8))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name, style: inter(13, weight: FontWeight.w800, color: kAeInk)),
                        Text('${c.store} · ${c.price}', style: inter(11, weight: FontWeight.w700, color: _kMuted)),
                      ],
                    ),
                  ),
                  AeNokkel(key: Key('bilde-velg-${c.storeProductId}'), label: AeAgentCopy.cus_gave_velg, smal: true, av: gjort != null, onTap: () => widget.h.reorderChoose(widget.v, r, c)),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Center(
              child: AePress(
                onTap: gjort != null ? null : () => widget.h.reorderChoose(widget.v, r, null),
                dy: 0,
                child: Padding(padding: const EdgeInsets.all(4), child: Text(AeAgentCopy.cus_bilde_ingen_av, key: const Key('bilde-ingen-av'), style: inter(12.5, weight: FontWeight.w800, color: kAeTeal))),
              ),
            ),
          ],
        ),
      );
    }
    return _papir(
      key: const Key('ae-bilde-ingen'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(r.blocked == 'age' ? AeAgentCopy.cus_bilde_alder : AeAgentCopy.cus_bilde_kjente_ikke, style: inter(14, weight: FontWeight.w800, color: kAeInk)),
          if (r.blocked != 'age') ...[
            const SizedBox(height: 2),
            Text(AeAgentCopy.cus_bilde_prov, style: inter(12.5, weight: FontWeight.w700, color: const Color(0xFF57534B))),
            const SizedBox(height: 10),
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: const Color(0xFFF5F3EF), border: Border.all(color: const Color.fromRGBO(35, 32, 29, .08))),
              alignment: Alignment.centerLeft,
              child: TextField(
                key: const Key('bilde-sok'),
                controller: _sok,
                textInputAction: TextInputAction.search,
                onSubmitted: (t) => widget.h.reorderSearch(t),
                style: inter(13, weight: FontWeight.w700, color: kAeInk),
                decoration: InputDecoration(isCollapsed: true, border: InputBorder.none, hintText: AeAgentCopy.cus_bilde_sok, hintStyle: inter(13, weight: FontWeight.w700, color: _kMuted)),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: AeNokkel(key: const Key('bilde-nytt'), label: AeAgentCopy.cus_bilde_nytt, smal: true, sekundaer: true, onTap: widget.h.reorderShoot)),
                const SizedBox(width: 8),
                Expanded(child: AeNokkel(key: const Key('bilde-strekkode'), label: AeAgentCopy.cus_bilde_strekkode, smal: true, sekundaer: true, onTap: widget.h.reorderShoot)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
