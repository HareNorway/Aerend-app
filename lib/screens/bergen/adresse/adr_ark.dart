import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/auth/launch/lf_widgets.dart' show LfPress;
import '../../common/manageAddress/manage_address_dl.dart';
import '../../snurre/snurre_launcher_policy.dart' show snurreLauncherHiddenRoutePrefix;
import 'adr_scene.dart';
import 'adr_tegning.dart';

// ── Adresse sheets (`sheet:'adresse'` L8382, `sheet:'nyAdresse'` L8493) ─────
// "Hvor skal ærendet?": the street scene with the chosen place, its door
// sign, coverage, the saved places (pick, delete with undo, add) and the
// door note for the courier. "Nytt sted på kartet": the plot, the three
// steps, what to call it, the address search, the door note and "Lagre og
// lever hit".

/// Coverage for one address (`/api/geo/coverage`).
class AdrDekning {
  const AdrDekning({required this.dekket, this.pauset = false, this.pausetTil, this.butikker = 0, this.gebyrKr, this.eta});
  final bool dekket, pauset;
  final String? pausetTil;
  final int butikker;
  final int? gebyrKr;
  final String? eta;

  /// From `/api/geo/coverage`: covered when the zone has placed stores that
  /// reach the cell; a paused zone still shows its stores.
  static AdrDekning fraJson(Map<String, dynamic> j) {
    final zone = j['zone'] is Map ? (j['zone'] as Map).cast<String, dynamic>() : null;
    final stores = (j['stores'] is List ? j['stores'] as List : const []).whereType<Map>().toList();
    final etas = stores.map((s) => (s['eta_minutes'] as num?)?.toInt()).whereType<int>().toList()..sort();
    final fee = (j['fee_ore'] as num?)?.toInt();
    return AdrDekning(
      dekket: j['covered'] == true,
      pauset: zone?['status'] == 'paused',
      butikker: stores.length,
      gebyrKr: fee == null ? null : (fee / 100).round(),
      eta: etas.isEmpty ? null : (etas.first == etas.last ? '${etas.first} min' : '${etas.first}–${etas.last} min'),
    );
  }

  /// The header's "· 25–35 min".
  String? get hodeEta => dekket && !pauset ? eta : null;

  String get linje => pauset
      ? 'Midlertidig pauset${pausetTil == null ? '' : ' · til $pausetTil'}'
      : '$butikker butikker leverer hit${gebyrKr == null ? '' : ' · $gebyrKr kr'}${eta == null ? '' : ' · $eta'}';
}

/// One address suggestion.
class AdrForslag {
  const AdrForslag({required this.gate, required this.sted, this.placeId, this.egen = false});
  final String gate, sted;
  final String? placeId;

  /// "Ny adresse i Bergen" — what the user typed, no suggestion behind it.
  final bool egen;

  String get full => sted.isEmpty ? gate : '$gate, $sted';
}

/// What the sheets need from the app.
abstract class AdrKilde {
  Stream<List<AddressListItem>?> get liste;
  Stream<AddressListItem?> get valgt;
  void velg(int addressId);
  Future<void> slett(int addressId);
  Future<AdrDekning?> dekning(AddressListItem a);

  /// Coverage for a place not saved yet.
  Future<AdrDekning?> dekningForslag(AdrForslag f);
  Future<void> siFra(AddressListItem a);

  /// The remembered door note for [a].
  String dor(AddressListItem a);

  /// Remembers the door note for [a].
  Future<bool> lagreDor(AddressListItem a, String tekst);
  Future<List<AdrForslag>> forslag(String q);

  /// Adds the place and selects it; returns the new id, or null.
  Future<int?> leggTil({required String adresse, required String type, required AdrForslag? fra, required String info});

  /// "Bruk posisjonen min": saves and selects where the phone is, then calls
  /// [ferdig].
  void minPosisjon(void Function() ferdig);
  void toast(String tekst);
}

// ── Helpers from the prototype (`adrVals`, `dorTolk`) ──────────────────────

String adrMerke(String type) {
  final t = type.toLowerCase();
  if (t.contains('jobb') || t.contains('work') || t.contains('office')) return 'Jobb';
  if (t.contains('hytte') || t.contains('cabin')) return 'Hytte';
  if (t.contains('hjem') || t.contains('home')) return 'Hjem';
  return 'Annet';
}

String adrType(String merke) => switch (merke) {
  'Hjem' => 'Hjemme',
  _ => merke,
};

/// (gate, nr) from "Nygårdsgaten 5, 5015 Bergen".
(String, String?) adrGateNr(String full) {
  final g0 = full.split(',').first.trim();
  final m = RegExp(r'^(.*?)\s+(\d+\s*[A-Za-z]?)$').firstMatch(g0);
  return m == null ? (g0, null) : (m.group(1)!, m.group(2)!.replaceAll(RegExp(r'\s+'), ''));
}

String _sted(String full) {
  final parts = full.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  if (parts.length < 2) return '';
  return parts[1].replaceFirst(RegExp(r'^\d{4}\s*'), '');
}

/// The courier's note as chips: Etasje, Ring på, Inngang, Kode.
List<(String, String, String)> dorTolk(String s) {
  final o = <(String, String, String)>[];
  const ord = {'første': '1', 'andre': '2', 'tredje': '3', 'fjerde': '4', 'femte': '5', 'sjette': '6'};
  final et = RegExp(r'(\d+)\.?\s*etasje', caseSensitive: false).firstMatch(s) ?? RegExp(r'(første|andre|tredje|fjerde|femte|sjette)\s+etasje', caseSensitive: false).firstMatch(s);
  if (et != null) o.add(('Etasje', ord[et.group(1)!.toLowerCase()] ?? et.group(1)!, 'M4 20h16M6 20V9l6-5 6 5v11M10 20v-5h4v5'));
  final ring = RegExp(r'ring(?:e)?\s+(?:på\s+)?(?:hos\s+)?([A-ZÆØÅ][\wæøåÆØÅ-]+)').firstMatch(s);
  if (ring != null) o.add(('Ring på', ring.group(1)!, 'M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9M10 21h4'));
  final inn = RegExp(r'(bakgård(?:en)?|bakdør(?:a|en)?|hovedinngang(?:en)?|sideinngang(?:en)?|port(?:en)?|kjeller(?:en)?|garasje(?:n)?)', caseSensitive: false).firstMatch(s);
  if (inn != null) o.add(('Inngang', inn.group(1)!.toLowerCase(), 'M5 21V4h10l4 4v13M12 12h.01'));
  final kode = RegExp(r'kode\s*:?\s*(\d{3,6})', caseSensitive: false).firstMatch(s);
  if (kode != null) o.add(('Kode', kode.group(1)!, 'M7 11V8a5 5 0 0 1 10 0v3M5 11h14v10H5z'));
  return o;
}

/// The door note stored on an address (`landmark`), unless it is just the
/// address again (older saves copy it there).
String adrDor(AddressListItem a) {
  final l = a.landmark.trim();
  if (l.isEmpty || l == 'N/A' || l == a.address.trim() || a.address.startsWith(l)) return '';
  return l;
}

/// "Møhlenpris · 3. etasje": the area and the floor when known.
String adrUnder(AddressListItem a) {
  final deler = <String>[_sted(a.address)];
  final f = a.flatNo.trim();
  if (f.isNotEmpty && f != 'N/A' && f != 'current-location') {
    deler.add(f);
  } else {
    final et = dorTolk(adrDor(a)).where((c) => c.$1 == 'Etasje').firstOrNull;
    if (et != null) deler.add('${et.$2}. etasje');
  }
  return deler.where((e) => e.isNotEmpty).join(' · ');
}

const Map<String, String> _kEyebrow = {'Hjem': 'HER BOR DU', 'Jobb': 'HER JOBBER DU', 'Hytte': 'HYTTA DI'};
const Map<String, String> _kAegTx = {
  'Hjem': 'Velkommen hjem! Jeg vet hvor døra er.',
  'Jobb': 'Lunsj på pulten? Jeg finner resepsjonen.',
  'Hytte': 'Hyttekos! Jeg tar med det du glemte.',
  'Annet': 'Merket på kartet. Jeg finner fram.',
};

// Icons.
const _kHus = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M3 11L12 3.5 21 11v10H3z" fill="#FFFFFF"/></svg>';
const _kSoppel =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#FFAD8F" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round"><path d="M4.5 7h15"/><path d="M9.5 7V5.2A1.2 1.2 0 0 1 10.7 4h2.6a1.2 1.2 0 0 1 1.2 1.2V7"/><path d="M6.5 7l.9 11.6A1.6 1.6 0 0 0 9 20h6a1.6 1.6 0 0 0 1.6-1.4L17.5 7"/><path d="M10.2 11v5M13.8 11v5"/></svg>';
const _kHake = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#1F8A66" stroke-width="3.4" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12l5 5 9-10"/></svg>';
const _kPil = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#1E4F5C" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 5.5l6.5 6.5-6.5 6.5"/></svg>';
const _kMik = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#5CE0B8" stroke-width="2.2" stroke-linecap="round"><rect x="9" y="3" width="6" height="11" rx="3"/><path d="M5.5 11a6.5 6.5 0 0 0 13 0M12 17.5V21"/></svg>';
const _kNaal = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#7FF0CB" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M12 21s-6.5-5.4-6.5-11a6.5 6.5 0 0 1 13 0c0 5.6-6.5 11-6.5 11z"/><circle cx="12" cy="10" r="2.4"/></svg>';

Color _husFarge(String merke) => merke == 'Annet' ? const Color(0xFFC98F3E) : const Color(0xFF3E8FA3);

/// Debug harness only: text typed into the address search / the door note
/// when the sheet opens.
abstract final class AdrArkProve {
  static String? sok, dor;

  /// Pick the first suggestion once they load.
  static bool velg = false;
}

/// Opens "Hvor skal ærendet?".
Future<void> visAdresseArk(BuildContext context, AdrKilde kilde, {bool ny = false}) {
  final reduce = MediaQuery.disableAnimationsOf(context);
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      settings: const RouteSettings(name: '${snurreLauncherHiddenRoutePrefix}adresse'),
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      transitionDuration: Duration(milliseconds: reduce ? 0 : 380),
      reverseTransitionDuration: Duration(milliseconds: reduce ? 0 : 260),
      pageBuilder: (context, a, _) => _AdrRute(anim: a, kilde: kilde, ny: ny),
    ),
  );
}

class _AdrRute extends StatelessWidget {
  const _AdrRute({required this.anim, required this.kilde, required this.ny});
  final Animation<double> anim;
  final AdrKilde kilde;
  final bool ny;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: LfFrame(
        child: Builder(
          builder: (context) {
            final mq = MediaQuery.of(context);
            return Stack(
              children: [
                // Scrim: rgba(15,31,43,.32) with a 5px backdrop blur (the
                // screen's one blur layer), skjermInn .25s.
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: FadeTransition(
                      opacity: CurvedAnimation(parent: anim, curve: const Interval(0, .66, curve: Curves.easeOut)),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                        child: const ColoredBox(color: Color.fromRGBO(15, 31, 43, .32)),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedBuilder(
                    animation: anim,
                    builder: (context, child) {
                      // arkOpp .38s cubic(.2,.9,.3,1)
                      final e = const Cubic(.2, .9, .3, 1).transform(anim.value);
                      return Opacity(
                        opacity: anim.status == AnimationStatus.reverse ? anim.value : .6 + .4 * e,
                        child: Transform.translate(
                          offset: Offset(0, anim.status == AnimationStatus.reverse ? (1 - anim.value) * 400 : 26 * (1 - e)),
                          child: child,
                        ),
                      );
                    },
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: mq.size.height - mq.padding.top - 6),
                      child: Padding(
                        padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
                        child: _AdrArk(kilde: kilde, ny: ny),
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
}

class _AdrArk extends StatefulWidget {
  const _AdrArk({required this.kilde, this.ny = false});
  final AdrKilde kilde;
  final bool ny;

  @override
  State<_AdrArk> createState() => _AdrArkState();
}

class _AdrArkState extends State<_AdrArk> {
  AdrKilde get k => widget.kilde;
  late bool _ny = widget.ny;

  // Adresse
  int _tikk = 0;
  int? _sletter;
  final Set<int> _borte = {};
  ({int id, String navn, int forrige})? _angre;
  Timer? _angreT, _lukkT;
  int? _nyId;
  DateTime? _nyNaa;
  AdrDekning? _dek;
  int? _dekFor;
  bool _sagtFra = false;

  // Dørbeskjed
  final TextEditingController _dor = TextEditingController();
  final FocusNode _dorFokus = FocusNode();
  String _dorLagret = '';
  int? _dorFor;
  bool _husk = true;
  bool _posisjon = false;

  @override
  void initState() {
    super.initState();
    _dorFokus.addListener(() => setState(() {}));
    _dor.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _angreT?.cancel();
    _lukkT?.cancel();
    // A pending delete goes through when the sheet closes.
    final a = _angre;
    if (a != null) k.slett(a.id);
    _dor.dispose();
    _dorFokus.dispose();
    super.dispose();
  }

  void _hentDekning(AddressListItem a) {
    if (_dekFor == a.addressId) return;
    _dekFor = a.addressId;
    _sagtFra = false;
    k.dekning(a).then((d) {
      if (mounted && _dekFor == a.addressId) setState(() => _dek = d);
    });
  }

  void _velg(AddressListItem a, AddressListItem? valgt) {
    HapticFeedback.selectionClick();
    _lukkT?.cancel();
    if (valgt?.addressId == a.addressId) {
      Navigator.of(context).pop();
      return;
    }
    k.velg(a.addressId);
    setState(() {
      _tikk++;
      _nyNaa = null;
      _dek = null;
    });
    k.dekning(a).then((d) {
      final (gate, nr) = adrGateNr(a.address);
      final navn = nr == null ? gate : '$gate $nr';
      if (d == null) return;
      k.toast(d.dekket ? (d.pauset ? d.linje : '${d.butikker} butikker leverer til $navn${d.gebyrKr == null ? '' : ' · ${d.gebyrKr} kr'}${d.eta == null ? '' : ' · ${d.eta}'}') : 'Vi leverer ikke hit ennå.');
    });
    // The sheet closes itself after 2s (`_adrLukk`).
    _lukkT = Timer(const Duration(seconds: 2), () {
      if (mounted && !_ny) Navigator.of(context).maybePop();
    });
  }

  void _slett(AddressListItem a, List<AddressListItem> synlig, AddressListItem? valgt) {
    if (_sletter != null) return;
    if (synlig.length <= 1) {
      k.toast('Du må ha minst ett sted å levere til');
      return;
    }
    HapticFeedback.mediumImpact();
    _lukkT?.cancel();
    // A previous undo window ends: that delete goes through now.
    final forrigeAngre = _angre;
    if (forrigeAngre != null) {
      _angreT?.cancel();
      k.slett(forrigeAngre.id);
    }
    setState(() => _sletter = a.addressId);
    Future.delayed(const Duration(milliseconds: 380), () {
      if (!mounted) return;
      final varValgt = valgt?.addressId == a.addressId;
      final rest = synlig.where((x) => x.addressId != a.addressId).toList();
      setState(() {
        _sletter = null;
        _borte.add(a.addressId);
        _angre = (id: a.addressId, navn: adrMerke(a.type), forrige: valgt?.addressId ?? 0);
      });
      if (varValgt && rest.isNotEmpty) {
        k.velg(rest.first.addressId);
        setState(() => _tikk++);
      }
      _angreT = Timer(const Duration(seconds: 5), () {
        final g = _angre;
        if (g == null) return;
        k.slett(g.id);
        if (mounted) setState(() => _angre = null);
      });
    });
  }

  void _angreSlett() {
    final g = _angre;
    if (g == null) return;
    _angreT?.cancel();
    setState(() {
      _borte.remove(g.id);
      _angre = null;
      _tikk++;
    });
    if (g.forrige != 0) k.velg(g.forrige);
  }

  @override
  Widget build(BuildContext context) {
    return CssBox(
      radius: const BorderRadius.vertical(top: Radius.circular(28)),
      bg: const [CssLinear(180, [Color(0xFF27596A), Color(0xFF1E4F5C), Color(0xFF173E48)], [0, .55, 1])],
      border: const Border(top: BorderSide(color: Color.fromRGBO(255, 255, 255, .9))),
      shadows: const [
        CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .95)),
        CssShadow(0, -24, 50, -20, Color.fromRGBO(15, 31, 43, .55)),
      ],
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 0, 16, 22 + MediaQuery.paddingOf(context).bottom * (MediaQuery.viewInsetsOf(context).bottom > 0 ? 0 : 1)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: Center(
                child: Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(color: const Color.fromRGBO(255, 255, 255, .35), borderRadius: BorderRadius.circular(3)),
                ),
              ),
            ),
            if (_ny)
              _NyAdresse(
                kilde: k,
                onTilbake: () => setState(() => _ny = false),
                onLagret: (id) {
                  setState(() {
                    _ny = false;
                    _nyId = id;
                    _nyNaa = DateTime.now();
                    _tikk++;
                    _dek = null;
                    _dekFor = null;
                  });
                },
              )
            else
              StreamBuilder<List<AddressListItem>?>(
                stream: k.liste,
                builder: (context, ls) => StreamBuilder<AddressListItem?>(
                  stream: k.valgt,
                  builder: (context, vs) => _adresse(ls.data ?? const [], vs.data),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _adresse(List<AddressListItem> alle, AddressListItem? valgt) {
    final synlig = alle.where((a) => !_borte.contains(a.addressId)).toList();
    final v = valgt != null && synlig.any((a) => a.addressId == valgt.addressId) ? valgt : (synlig.isEmpty ? null : synlig.first);
    if (v != null) _hentDekning(v);
    // The door note follows the chosen place.
    if (v != null && _dorFor != v.addressId) {
      _dorFor = v.addressId;
      _dorLagret = k.dor(v);
      _dor.text = kDebugMode && AdrArkProve.dor != null ? AdrArkProve.dor! : _dorLagret;
    }
    final merke = v == null ? 'Hjem' : adrMerke(v.type);
    final (gate, nr) = adrGateNr(v?.address ?? '');
    final ny = _nyNaa != null && DateTime.now().difference(_nyNaa!).inMilliseconds < 4200 && v?.addressId == _nyId;
    final d = _dek;
    final maal = synlig.length < 4 ? 4 : synlig.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 14),
        Text('Hvor skal ærendet?', style: jakarta(18, em: -.02)),
        const SizedBox(height: 2),
        Text('Butikker og priser følger adressen.', style: inter(11.5, color: const Color.fromRGBO(255, 255, 255, .66))),
        const SizedBox(height: 12),
        if (v != null) ...[
          AdrGatescene(
            key: ValueKey('scene-${v.addressId}-$_tikk'),
            type: adrTypeFor(merke),
            husFarge: _husFarge(merke),
            etasje: merke == 'Hjem',
            nr: nr ?? merke.substring(0, 1),
            tekst: ny ? 'Nytt sted på kartet! Nå vet jeg hvor jeg skal.' : (_kAegTx[merke] ?? _kAegTx['Annet']!),
            ny: ny,
          ),
          Transform.translate(
            offset: const Offset(0, -26),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: AdrDorskilt(
                key: ValueKey('skilt-${v.addressId}-$_tikk'),
                nr: nr ?? merke.substring(0, 1),
                eyebrow: _kEyebrow[merke] ?? 'DITT STED',
                gate: gate.isEmpty ? v.address : gate,
                sub: adrUnder(v),
              ),
            ),
          ),
          Transform.translate(offset: const Offset(0, -14), child: _dekningVis(d, v)),
        ],
        Transform.translate(
          offset: Offset(0, v == null ? 0 : -14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('DINE STEDER', style: inter(10.5, weight: FontWeight.w800, em: .08, color: const Color.fromRGBO(255, 255, 255, .66))),
                  const Spacer(),
                  for (var j = 0; j < maal; j++) ...[
                    if (j > 0) const SizedBox(width: 3),
                    SvgPicture.string(
                      j < synlig.length
                          ? '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M3 11L12 3.5 21 11v10H3z" fill="#5CE0B8" stroke="#5CE0B8" stroke-width="2" stroke-linejoin="round"/></svg>'
                          : '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M3 11L12 3.5 21 11v10H3z" fill="none" stroke="rgba(255,255,255,.42)" stroke-width="2" stroke-linejoin="round" stroke-dasharray="3 2.2"/></svg>',
                      width: 13,
                      height: 13,
                    ),
                  ],
                  const SizedBox(width: 7),
                  Text(
                    '${synlig.length} av $maal steder',
                    style: inter(11, weight: FontWeight.w800, color: const Color(0xFF9FF0D4)).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (var j = 0; j < synlig.length; j++) ...[
                if (j > 0) const SizedBox(height: 8),
                _AdrRad(
                  key: ValueKey('rad-${synlig[j].addressId}'),
                  a: synlig[j],
                  valgt: synlig[j].addressId == v?.addressId,
                  indeks: j,
                  ut: _sletter == synlig[j].addressId,
                  onTap: () => _velg(synlig[j], v),
                  onSlett: () => _slett(synlig[j], synlig, v),
                ),
              ],
              if (_angre != null) ...[
                const SizedBox(height: 8),
                _AngreRad(key: ValueKey('angre-${_angre!.id}'), tekst: '${_angre!.navn} er slettet', onAngre: _angreSlett),
              ],
              const SizedBox(height: 8),
              _LeggTilRad(onTap: () => setState(() => _ny = true)),
              if (v != null) _dorbeskjed(v),
              const SizedBox(height: 14),
              _GlassKnapp(
                hoyde: 50,
                onTap: () {
                  if (_posisjon) return;
                  setState(() => _posisjon = true);
                  k.minPosisjon(() {
                    if (!mounted) return;
                    setState(() => _posisjon = false);
                    Navigator.of(context).maybePop();
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(decoration: const BoxDecoration(shape: BoxShape.circle, color: Color.fromRGBO(92, 224, 184, .18))),
                          _Puls(farge: const Color.fromRGBO(127, 240, 203, .7), ms: _posisjon ? 900 : 2000),
                          SvgPicture.string(
                            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#7FF0CB" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="3"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3"/><circle cx="12" cy="12" r="8"/></svg>',
                            width: 15,
                            height: 15,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 9),
                    Text('Bruk posisjonen min', style: inter(13.5, weight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Coverage: dekket chip, Pauset or "Ikke dekket ennå".
  Widget _dekningVis(AdrDekning? d, AddressListItem v) {
    if (d == null) return const SizedBox(height: 0);
    if (d.dekket && !d.pauset) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Center(child: _DekChip(tekst: d.linje)),
      );
    }
    if (d.dekket && d.pauset) {
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(242, 193, 78, .18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color.fromRGBO(242, 193, 78, .4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(d.linje, style: inter(13, weight: FontWeight.w800, height: 1.4, color: const Color(0xFFF5F3EF))),
            const SizedBox(height: 3),
            Text('Du kan se butikkene, og vi åpner for bestilling igjen da.', style: inter(12, weight: FontWeight.w600, height: 1.4, color: const Color.fromRGBO(255, 255, 255, .75))),
          ],
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, .1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, .2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Vi leverer ikke hit ennå.', style: inter(15, weight: FontWeight.w800, color: const Color(0xFFF5F3EF))),
          if (_sagtFra)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(color: const Color.fromRGBO(92, 224, 184, .22), borderRadius: BorderRadius.circular(999)),
                  child: Text('Vi sier fra.', style: inter(12.5, weight: FontWeight.w800, color: const Color(0xFF7FF0CB))),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _SvevKnapp(
                tekst: 'Si fra når dere gjør det',
                onTap: () {
                  k.siFra(v);
                  setState(() => _sagtFra = true);
                  k.toast('Vi sier fra.');
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _dorbeskjed(AddressListItem v) {
    final tx = _dor.text, har = tx.trim().isNotEmpty, fok = _dorFokus.hasFocus;
    final chips = dorTolk(tx);
    final endret = tx.trim() != _dorLagret.trim();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('HVORDAN FINNER BUDET FRAM?', style: inter(10.5, weight: FontWeight.w800, em: .06, color: const Color.fromRGBO(255, 255, 255, .6))),
              const Spacer(),
              if (_dorLagret.isNotEmpty && !endret)
                _Inn(
                  key: ValueKey('lagret-$_dorLagret'),
                  child: Row(
                    children: [
                      SvgPicture.string(_kHake.replaceAll('#1F8A66', '#9FF0D4'), width: 10, height: 10),
                      const SizedBox(width: 4),
                      Text('Lagret', style: inter(10.5, weight: FontWeight.w800, color: const Color(0xFF9FF0D4))),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            constraints: const BoxConstraints(minHeight: 46),
            padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: fok
                    ? const [Color.fromRGBO(255, 255, 255, .18), Color.fromRGBO(255, 255, 255, .08)]
                    : const [Color.fromRGBO(255, 255, 255, .14), Color.fromRGBO(255, 255, 255, .07)],
              ),
              border: Border.all(color: fok ? const Color.fromRGBO(92, 224, 184, .6) : const Color.fromRGBO(255, 255, 255, .22)),
              boxShadow: [if (fok) const BoxShadow(color: Color.fromRGBO(92, 224, 184, .14), spreadRadius: 4)],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    // dorH; the browser lets the empty hint run to two lines.
                    height: tx.length > 40 || tx.contains('\n') ? 52 : (tx.isEmpty ? 40 : 32),
                    padding: const EdgeInsets.only(top: 7),
                    child: TextField(
                      controller: _dor,
                      focusNode: _dorFokus,
                      maxLines: null,
                      expands: true,
                      cursorColor: const Color(0xFF5CE0B8),
                      style: inter(13, weight: FontWeight.w700, height: 1.4),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        hintText: 'Skriv som til en venn: etasje, ring på, inngang, kode …',
                        hintMaxLines: 2,
                        hintStyle: inter(13, weight: FontWeight.w700, height: 1.4, color: const Color.fromRGBO(255, 255, 255, .45)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => har ? _dor.clear() : k.toast('Kommer snart'),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Color.fromRGBO(255, 255, 255, har ? .1 : .12)),
                    alignment: Alignment.center,
                    child: har
                        ? SvgPicture.string(
                            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="3" stroke-linecap="round"><path d="M6 6l12 12M18 6L6 18"/></svg>',
                            width: 10,
                            height: 10,
                          )
                        : SvgPicture.string(_kMik, width: 13, height: 13),
                  ),
                ),
              ],
            ),
          ),
          if (har) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < chips.length; i++)
                  _Inn(
                    key: ValueKey('chip-${chips[i].$1}-${chips[i].$2}'),
                    delayMs: i * 60.0,
                    child: CssBox(
                      height: 30,
                      radius: BorderRadius.circular(10),
                      bg: const [CssLinear(180, [Color.fromRGBO(255, 255, 255, .18), Color.fromRGBO(255, 255, 255, .07)])],
                      shadows: const [
                        CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .3)),
                        CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .12)),
                        CssShadow(0, 2, 0, 0, Color.fromRGBO(8, 28, 36, .5)),
                      ],
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.string(
                            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#9FF0D4" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="${chips[i].$3}"/></svg>',
                            width: 11,
                            height: 11,
                          ),
                          const SizedBox(width: 5),
                          Text(chips[i].$1, style: inter(11.5, weight: FontWeight.w700, color: const Color(0xFFBFD6DD))),
                          const SizedBox(width: 5),
                          Text(chips[i].$2, style: jakarta(11.5)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _husk = !_husk),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 34,
                        height: 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: _husk ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF5CE0B8), Color(0xFF2FB893)]) : null,
                          color: _husk ? null : const Color.fromRGBO(255, 255, 255, .16),
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 300),
                          curve: const Cubic(.3, 1.4, .5, 1),
                          alignment: _husk ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            width: 16,
                            height: 16,
                            margin: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [BoxShadow(color: Color.fromRGBO(0, 0, 0, .35), offset: Offset(0, 2), blurRadius: 3)],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Husk til neste gang', style: inter(11, weight: FontWeight.w700, color: const Color(0xFFDCE9EC))),
                    ],
                  ),
                ),
                const Spacer(),
                if (endret)
                  _Inn(
                    child: LfPress(
                      dy: 2,
                      onTap: () async {
                        final tekst = tx.trim();
                        FocusScope.of(context).unfocus();
                        if (_husk) {
                          final ok = await k.lagreDor(v, tekst);
                          if (!ok) return;
                        }
                        setState(() {
                          _dorLagret = tekst;
                          _dor.text = tekst;
                        });
                        k.toast(_husk ? 'Dørbeskjeden er lagret · budet ser den neste gang også' : 'Dørbeskjeden gjelder denne bestillingen');
                      },
                      child: CssBox(
                        height: 34,
                        radius: BorderRadius.circular(12),
                        bg: const [CssLinear(180, [Color(0xFFFF9466), Color(0xFFE95C2C)])],
                        shadows: const [
                          CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .45)),
                          CssShadow(0, 2.5, 0, 0, Color(0xFFA63A12)),
                          CssShadow(0, 8, 12, -6, Color.fromRGBO(3, 16, 24, .7)),
                        ],
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Center(widthFactor: 1, child: Text('Lagre', style: inter(12, weight: FontWeight.w800))),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The coverage pill with its live dot.
class _DekChip extends StatelessWidget {
  const _DekChip({required this.tekst, this.liten = false});
  final String tekst;
  final bool liten;

  @override
  Widget build(BuildContext context) {
    final p = liten ? 7.0 : 8.0;
    return CssBox(
      radius: BorderRadius.circular(999),
      bg: const [CssLinear(180, [Color.fromRGBO(255, 255, 255, .16), Color.fromRGBO(255, 255, 255, .06)])],
      shadows: const [
        CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .3)),
        CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .1)),
      ],
      padding: liten ? const EdgeInsets.fromLTRB(10, 4, 12, 4) : const EdgeInsets.fromLTRB(10, 5, 13, 5),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: p,
              height: p,
              child: const Stack(
                clipBehavior: Clip.none,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Color(0xFF5CE0B8), boxShadow: [BoxShadow(color: Color(0xFF5CE0B8), blurRadius: 4)]),
                    child: SizedBox.expand(),
                  ),
                  Positioned.fill(child: _Puls(farge: Color(0xFF5CE0B8), ms: 1800, fylt: true)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(tekst, style: inter(liten ? 11.5 : 12, weight: FontWeight.w700, color: const Color(0xFFE7F2F4))),
          ],
        ),
      ),
    );
  }
}

/// `vcKnapp` (.35–.45s) — small things popping in.
class _Inn extends StatelessWidget {
  const _Inn({super.key, required this.child, this.delayMs = 0}) : ms = 400, dy = 8, s0 = .85, kurve = const Cubic(.2, 1.3, .3, 1);
  final Widget child;
  final double delayMs, ms, dy, s0;
  final Curve kurve;

  /// `vcKort`: 14px up, from .96.
  const _Inn.kort({required this.child, this.delayMs = 0})
    : ms = 450,
      dy = 14,
      s0 = .96,
      kurve = const Cubic(.2, 1.15, .3, 1);

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: delayMs + ms,
    builder: (context, t, child) {
      final e = kurve.transform(kfP(t, delayMs, ms));
      final s = s0 + (1 - s0) * e;
      return Opacity(
        opacity: e.clamp(0.0, 1.0),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.translationValues(0, dy * (1 - e), 0)..scaleByDouble(s, s, 1, 1),
          child: child,
        ),
      );
    },
    child: child,
  );
}

class _Puls extends StatelessWidget {
  const _Puls({required this.farge, required this.ms, this.fylt = false});
  final Color farge;
  final double ms;
  final bool fylt;

  @override
  Widget build(BuildContext context) => LfLoop(
    builder: (context, t, child) {
      final p = cssEaseOut.transform((t / ms) % 1.0);
      return Opacity(opacity: .9 * (1 - p), child: Transform.scale(scale: .6 + 1.3 * p, child: child));
    },
    child: DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fylt ? farge : null,
        border: fylt ? null : Border.all(color: farge, width: 1.5),
      ),
    ),
  );
}

class _GlassKnapp extends StatelessWidget {
  const _GlassKnapp({required this.hoyde, required this.onTap, required this.child});
  final double hoyde;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => LfPress(
    dy: 3,
    onTap: onTap,
    child: CssBox(
      height: hoyde,
      radius: BorderRadius.circular(17),
      bg: const [CssLinear(180, [Color.fromRGBO(255, 255, 255, .2), Color.fromRGBO(255, 255, 255, .07)])],
      shadows: const [
        CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .4)),
        CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .14)),
        CssShadow(0, 3, 0, 0, Color.fromRGBO(4, 20, 28, .55)),
        CssShadow(0, 12, 18, -10, Color.fromRGBO(3, 14, 20, .85)),
      ],
      child: Center(child: child),
    ),
  );
}

/// The white key that floats (`aeKnSvev` 3.4s) over its shadow.
class _SvevKnapp extends StatelessWidget {
  const _SvevKnapp({required this.tekst, required this.onTap});
  final String tekst;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LfLoop(
    builder: (context, t, child) {
      final p = (((t - -3000) / 3400) % 1.0);
      final y = kf(p, const [0, .5, 1], const [0, -5, 0], cssEaseInOut);
      final sx = kf(p, const [0, .5, 1], const [1, .82, 1], cssEaseInOut);
      final so = kf(p, const [0, .5, 1], const [1, .6, 1], cssEaseInOut);
      return SizedBox(
        height: 46,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 47,
              height: 15,
              child: FractionallySizedBox(
                widthFactor: .8,
                child: Opacity(
                  opacity: so,
                  // The shadow rides on the key (−5px) and moves +5px itself,
                  // so it stays put on the page.
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.diagonal3Values(sx, 1, 1),
                    child: const CssBox(bg: [CssRadial.closestSide([Color.fromRGBO(8, 26, 32, .5), Color.fromRGBO(8, 26, 32, 0)], stops: [0, .72])]),
                  ),
                ),
              ),
            ),
            Positioned.fill(child: Transform.translate(offset: Offset(0, y), child: child)),
          ],
        ),
      );
    },
    child: GestureDetector(
      onTap: onTap,
      child: CssBox(
        radius: BorderRadius.circular(999),
        bg: const [CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFE9EEED)])],
        shadows: const [CssShadow.inset(0, -3, 6, 0, Color.fromRGBO(30, 79, 92, .14))],
        child: Center(child: Text(tekst, style: inter(14, weight: FontWeight.w800, color: const Color(0xFF1E4F5C)))),
      ),
    ),
  );
}

/// One saved place.
class _AdrRad extends StatelessWidget {
  const _AdrRad({super.key, required this.a, required this.valgt, required this.indeks, required this.ut, required this.onTap, required this.onSlett});
  final AddressListItem a;
  final bool valgt, ut;
  final int indeks;
  final VoidCallback onTap, onSlett;

  @override
  Widget build(BuildContext context) {
    final merke = adrMerke(a.type);
    final win = valgt ? const Color(0xFFFFD27A) : const Color(0xFF2C5562);
    final winB = valgt ? const Color(0xFFBFF5E4) : const Color(0xFF2C5562);
    final tile = switch (adrTypeFor(merke)) {
      AdrType.jobb => kTileJobb,
      AdrType.hytte => kTileHytte,
      AdrType.hus => kTileHus,
    };
    final (gate, nr) = adrGateNr(a.address);
    final kort = LfPress(
      dy: 2,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.fromLTRB(9, 9, 12, 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: valgt
                ? const [Color.fromRGBO(92, 224, 184, .2), Color.fromRGBO(92, 224, 184, .06)]
                : const [Color.fromRGBO(255, 255, 255, .1), Color.fromRGBO(255, 255, 255, .04)],
          ),
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: valgt ? const Color.fromRGBO(92, 224, 184, .7) : const Color.fromRGBO(255, 255, 255, .14), width: valgt ? 1.5 : 1),
        ),
        child: Row(
          children: [
            CssBox(
              width: 46,
              height: 46,
              radius: BorderRadius.circular(15),
              clip: true,
              bg: [
                valgt
                    ? const CssLinear(180, [Color(0xFF4A97A9), Color(0xFF24596A)])
                    : const CssLinear(180, [Color.fromRGBO(255, 255, 255, .16), Color.fromRGBO(255, 255, 255, .05)]),
              ],
              shadows: const [
                CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .35)),
                CssShadow.inset(0, -3, 0, 0, Color.fromRGBO(4, 20, 28, .25)),
                CssShadow(0, 3, 0, 0, Color.fromRGBO(4, 20, 28, .45)),
                CssShadow(0, 8, 12, -6, Color.fromRGBO(3, 14, 20, .7)),
              ],
              child: Stack(
                children: [
                  const Positioned(left: 0, right: 0, bottom: 0, height: 7, child: ColoredBox(color: Color.fromRGBO(8, 28, 36, .4))),
                  AdrTegning(bilde: tile, t: 0, vars: {'win': win, 'winB': winB}),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(merke, style: jakarta(14, em: -.01)),
                      if (valgt) ...[
                        const SizedBox(width: 6),
                        _Inn(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(92, 224, 184, .2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color.fromRGBO(92, 224, 184, .45)),
                            ),
                            child: Text('LEVERES HIT', style: inter(8.5, weight: FontWeight.w800, em: .1, color: const Color(0xFF9FF0D4))),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(nr == null ? gate : '$gate $nr', maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(12, weight: FontWeight.w700, color: const Color(0xFFE7F2F4))),
                  Text(adrUnder(a), maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(10.5, color: const Color.fromRGBO(255, 255, 255, .64))),
                ],
              ),
            ),
            const SizedBox(width: 12),
            LfPress(
              dy: 2,
              onTap: onSlett,
              child: CssBox(
                width: 32,
                height: 32,
                radius: BorderRadius.circular(11),
                bg: const [CssLinear(180, [Color.fromRGBO(255, 255, 255, .16), Color.fromRGBO(255, 255, 255, .05)])],
                shadows: const [
                  CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .3)),
                  CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 148, 102, .32)),
                  CssShadow(0, 2.5, 0, 0, Color.fromRGBO(4, 20, 28, .45)),
                ],
                child: Center(child: SvgPicture.string(_kSoppel, width: 15, height: 15)),
              ),
            ),
            const SizedBox(width: 12),
            if (valgt)
              _Inn(
                child: CssBox(
                  width: 28,
                  height: 28,
                  radius: BorderRadius.circular(14),
                  bg: const [CssLinear(180, [Color(0xFFA6F8DD), Color(0xFF3CC79F)])],
                  shadows: const [
                    CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .65)),
                    CssShadow(0, 2.5, 0, 0, Color(0xFF23946F)),
                    CssShadow(0, 6, 10, -4, Color.fromRGBO(20, 110, 80, .6)),
                  ],
                  child: Center(child: SvgPicture.string(_kHake, width: 13, height: 13)),
                ),
              )
            else
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color.fromRGBO(255, 255, 255, .42), width: 2),
                ),
              ),
          ],
        ),
      ),
    );
    // kortStag on appear (staggered), adrUt while being deleted.
    if (ut) {
      return LfOnce(
        ms: 380,
        builder: (context, t, child) {
          final p = const Cubic(.5, 0, .75, 0).transform((t / 380).clamp(0.0, 1.0));
          final x = kf(p, const [0, .3, 1], const [0, -4, 46]);
          final s = kf(p, const [0, .3, 1], const [1, 1.02, .86]);
          final r = kf(p, const [0, .3, 1], const [0, -1, 3]);
          final o = kf(p, const [0, .3, 1], const [1, 1, 0]);
          return Opacity(
            opacity: o.clamp(0.0, 1.0),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.translationValues(x, 0, 0)
                ..rotateZ(rad(r))
                ..scaleByDouble(s, s, 1, 1),
              child: child,
            ),
          );
        },
        child: kort,
      );
    }
    final d = 100 + indeks * 50.0;
    return LfOnce(
      ms: d + 400,
      builder: (context, t, child) {
        final e = const Cubic(.2, .9, .3, 1).transform(kfP(t, d, 400));
        return Opacity(
          opacity: e,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.translationValues(0, 18 * (1 - e), 0)..scaleByDouble(.97 + .03 * e, .97 + .03 * e, 1, 1),
            child: child,
          ),
        );
      },
      child: kort,
    );
  }
}

class _AngreRad extends StatelessWidget {
  const _AngreRad({super.key, required this.tekst, required this.onAngre});
  final String tekst;
  final VoidCallback onAngre;

  @override
  Widget build(BuildContext context) {
    final kort = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CssBox(
        radius: BorderRadius.circular(16),
        bg: const [CssLinear(180, [Color.fromRGBO(242, 109, 61, .2), Color.fromRGBO(242, 109, 61, .1)])],
        shadows: const [
          CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .18)),
          CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 148, 102, .42)),
        ],
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(color: const Color.fromRGBO(242, 109, 61, .22), borderRadius: BorderRadius.circular(10)),
                  alignment: Alignment.center,
                  child: SvgPicture.string(_kSoppel, width: 15, height: 15),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(tekst, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(12.5, weight: FontWeight.w800))),
                const SizedBox(width: 10),
                LfPress(
                  dy: 2,
                  onTap: onAngre,
                  child: CssBox(
                    height: 34,
                    radius: BorderRadius.circular(12),
                    bg: const [CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFE4EDEF)])],
                    shadows: const [
                      CssShadow.inset(0, 1, 0, 0, Color(0xFFFFFFFF)),
                      CssShadow(0, 2.5, 0, 0, Color(0xFF8FA6AD)),
                      CssShadow(0, 8, 12, -6, Color.fromRGBO(3, 14, 20, .6)),
                    ],
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.string(
                          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#1E4F5C" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12a9 9 0 1 0 3-6.7L3 8M3 3v5h5"/></svg>',
                          width: 12,
                          height: 12,
                        ),
                        const SizedBox(width: 6),
                        Text('Angre', style: inter(12, weight: FontWeight.w800, color: const Color(0xFF1E4F5C))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // adrAngreTid 5s: the time left to undo.
            Positioned(
              left: -12,
              right: -8,
              bottom: -8,
              height: 3,
              child: LfOnce(
                ms: 5000,
                builder: (context, t, child) => Transform(
                  alignment: Alignment.centerLeft,
                  transform: Matrix4.diagonal3Values(1 - (t / 5000).clamp(0.0, 1.0), 1, 1),
                  child: child,
                ),
                child: const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFFB089), Color(0xFFF26D3D)]))),
              ),
            ),
          ],
        ),
      ),
    );
    // kortStag .35s
    return LfOnce(
      ms: 350,
      builder: (context, t, child) {
        final e = const Cubic(.2, .9, .3, 1).transform((t / 350).clamp(0.0, 1.0));
        return Opacity(
          opacity: e,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.translationValues(0, 18 * (1 - e), 0)..scaleByDouble(.97 + .03 * e, .97 + .03 * e, 1, 1),
            child: child,
          ),
        );
      },
      child: kort,
    );
  }
}

class _LeggTilRad extends StatelessWidget {
  const _LeggTilRad({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LfPress(
      dy: 2,
      onTap: onTap,
      child: CustomPaint(
        foregroundPainter: const _Stiplet(radius: 20, farge: Color.fromRGBO(255, 255, 255, .32), bredde: 1.5),
        child: Container(
          padding: const EdgeInsets.fromLTRB(9, 9, 12, 9),
          decoration: BoxDecoration(color: const Color.fromRGBO(255, 255, 255, .04), borderRadius: BorderRadius.circular(20)),
          child: Row(
            children: [
              SizedBox(
                width: 46,
                height: 46,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CssBox(
                        radius: BorderRadius.circular(15),
                        clip: true,
                        bg: const [CssLinear(180, [Color(0xFF1B4A57), Color(0xFF1B4A57)])],
                        shadows: const [
                          CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .2)),
                          CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(159, 240, 212, .25)),
                        ],
                        child: const CustomPaint(painter: _Rutenett()),
                      ),
                    ),
                    Positioned.fill(child: LfLoop(builder: (context, t, _) => AdrTegning(bilde: kTileNy, t: t))),
                    Positioned(
                      right: -6,
                      bottom: -6,
                      width: 22,
                      height: 22,
                      child: CssBox(
                        radius: BorderRadius.circular(11),
                        bg: const [CssLinear(180, [Color(0xFFFFA77C), Color(0xFFE95C2C)])],
                        shadows: const [
                          CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .5)),
                          CssShadow(0, 0, 0, 2, Color(0xFF1E4F5C)),
                          CssShadow(0, 2.5, 0, 2, Color(0xFFA63A12)),
                        ],
                        child: Center(
                          child: SvgPicture.string(
                            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="3.6" stroke-linecap="round"><path d="M12 5v14M5 12h14"/></svg>',
                            width: 10,
                            height: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Legg til et nytt sted', style: jakarta(14, em: -.01)),
                    const SizedBox(height: 1),
                    Text('Hytta, kjæresten, foreldrene …', style: inter(10.5, color: const Color.fromRGBO(255, 255, 255, .64))),
                  ],
                ),
              ),
              const _PilDisk(size: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _PilDisk extends StatelessWidget {
  const _PilDisk({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => CssBox(
    width: size,
    height: size,
    radius: BorderRadius.circular(size / 2),
    bg: const [CssRadial([Color(0xFFFFFFFF), Color(0xFFEEF4F5), Color(0xFFD5E1E4)], stops: [0, .55, 1], rx: .7, ry: .6, cx: .4, cy: .25)],
    shadows: const [CssShadow.inset(0, 1.5, 0, 0, Color(0xFFFFFFFF)), CssShadow(0, 2, 0, 0, Color.fromRGBO(4, 20, 28, .4))],
    child: Center(child: SvgPicture.string(_kPil, width: 11, height: 11)),
  );
}

/// `border: 1.5px dashed` on a rounded box.
class _Stiplet extends CustomPainter {
  const _Stiplet({required this.radius, required this.farge, required this.bredde});
  final double radius, bredde;
  final Color farge;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius((Offset.zero & size).deflate(bredde / 2), Radius.circular(radius));
    final p = Path()..addRRect(r);
    final out = Path();
    for (final m in p.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        out.addPath(m.extractPath(d, d + bredde * 3), Offset.zero);
        d += bredde * 6;
      }
    }
    canvas.drawPath(
      out,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = bredde
        ..color = farge,
    );
  }

  @override
  bool shouldRepaint(covariant _Stiplet old) => false;
}

class _Rutenett extends CustomPainter {
  const _Rutenett();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color.fromRGBO(159, 240, 212, .16);
    for (var x = 0.0; x < size.width; x += 8) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 1, size.height), p);
    }
    for (var y = 0.0; y < size.height; y += 8) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Nytt sted på kartet ─────────────────────────────────────────────────────

class _NyAdresse extends StatefulWidget {
  const _NyAdresse({required this.kilde, required this.onTilbake, required this.onLagret});
  final AdrKilde kilde;
  final VoidCallback onTilbake;
  final ValueChanged<int?> onLagret;

  @override
  State<_NyAdresse> createState() => _NyAdresseState();
}

class _NyAdresseState extends State<_NyAdresse> {
  String _merke = 'Hjem';
  int _merkeN = 0;
  final TextEditingController _adr = TextEditingController();
  final TextEditingController _info = TextEditingController();
  final FocusNode _adrFokus = FocusNode();
  List<AdrForslag> _forslag = const [];
  AdrForslag? _valgt;
  AdrDekning? _dek;
  bool _endret = false;
  bool _lagrer = false;
  Timer? _sokT;
  int _sokN = 0;

  @override
  void initState() {
    super.initState();
    _adrFokus.addListener(() => setState(() {}));
    _info.addListener(() => setState(() {}));
    _adr.addListener(_skriv);
    if (kDebugMode && AdrArkProve.sok != null) {
      _adr.text = AdrArkProve.sok!;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _adrFokus.requestFocus();
    });
  }

  @override
  void dispose() {
    _sokT?.cancel();
    _adr.dispose();
    _info.dispose();
    _adrFokus.dispose();
    super.dispose();
  }

  void _skriv() {
    if (_valgt != null && _adr.text == _valgt!.full) return;
    setState(() => _valgt = null);
    _sokT?.cancel();
    final q = _adr.text.trim();
    if (q.isEmpty) {
      setState(() => _forslag = const []);
      return;
    }
    final n = ++_sokN;
    _sokT = Timer(const Duration(milliseconds: 250), () async {
      final l = await widget.kilde.forslag(q);
      if (!mounted || n != _sokN) return;
      final harNr = RegExp(r'\d').hasMatch(q);
      final fl = l.where((f) => f.full.toLowerCase() != q.toLowerCase()).take(3).toList();
      if (harNr && q.length > 4 && !l.any((f) => f.full.toLowerCase().startsWith(q.toLowerCase()))) {
        fl.add(AdrForslag(gate: q, sted: 'Ny adresse i Bergen', egen: true));
      }
      setState(() => _forslag = fl);
      if (kDebugMode && AdrArkProve.velg && fl.isNotEmpty) {
        AdrArkProve.velg = false;
        _velg(fl.first);
        if (AdrArkProve.dor case final d?) _info.text = d;
      }
    });
  }

  void _velg(AdrForslag f) {
    HapticFeedback.selectionClick();
    _sokT?.cancel();
    _sokN++;
    setState(() {
      _valgt = f;
      _dek = null;
      _forslag = const [];
      _endret = false;
    });
    widget.kilde.dekningForslag(f).then((d) {
      if (mounted && _valgt == f) setState(() => _dek = d);
    });
    _adr.text = f.full;
    FocusScope.of(context).unfocus();
  }

  Future<void> _lagre() async {
    if (_lagrer) return;
    final adresse = _valgt?.full ?? _adr.text.trim();
    if (adresse.length <= 3) return;
    setState(() => _lagrer = true);
    final id = await widget.kilde.leggTil(adresse: adresse, type: adrType(_merke), fra: _valgt, info: _info.text.trim());
    if (!mounted) return;
    setState(() => _lagrer = false);
    if (id == null) return;
    widget.kilde.toast('Lagret · leverer til ${_valgt?.gate ?? adresse}');
    widget.onLagret(id);
  }

  @override
  Widget build(BuildContext context) {
    final valgt = _valgt != null;
    final info = _info.text.trim().isNotEmpty;
    final skriver = _adr.text.trim().isNotEmpty && !valgt;
    const lav = {'Hjem': 'hjemmet ditt', 'Jobb': 'jobben din', 'Hytte': 'hytta di', 'Annet': 'stedet ditt'};
    final tekst = valgt
        ? (info ? 'Lyset er på! Nå finner budet fram.' : 'Der står det! Fortell budet hvor døra er, så skrur jeg på lyset.')
        : skriver
        ? 'Jeg leter på kartet …'
        : 'Hvor ligger ${lav[_merke]}? Skriv adressen, så bygger jeg.';
    final (gate, nr) = adrGateNr(_valgt?.full ?? _adr.text);
    final klar = _adr.text.trim().length > 3;
    final steg = [('Navn', true, false), ('Adresse', valgt, !valgt), ('Lys på', valgt && info, valgt && !info)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 14),
        Row(
          children: [
            LfPress(
              dy: 2.5,
              onTap: widget.onTilbake,
              child: CssBox(
                width: 40,
                height: 40,
                radius: BorderRadius.circular(14),
                clip: true,
                bg: const [CssLinear(180, [Color.fromRGBO(255, 255, 255, .2), Color.fromRGBO(255, 255, 255, .07)])],
                shadows: const [
                  CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .4)),
                  CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .14)),
                  CssShadow(0, 3, 0, 0, Color.fromRGBO(4, 20, 28, .55)),
                  CssShadow(0, 12, 18, -10, Color.fromRGBO(3, 14, 20, .85)),
                ],
                child: Center(
                  child: SvgPicture.string(
                    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round"><path d="M15 5.5l-6.5 6.5 6.5 6.5"/></svg>',
                    width: 15,
                    height: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nytt sted på kartet', style: jakarta(18, em: -.02)),
                  const SizedBox(height: 1),
                  Text('Lagres på kontoen din og kan velges neste gang.', style: inter(11.5, color: const Color.fromRGBO(255, 255, 255, .66))),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AdrByggeplass(
          type: adrTypeFor(_merke),
          bygd: valgt,
          lys: info,
          husFarge: _husFarge(_merke),
          nr: nr ?? _merke.substring(0, 1),
          tekst: tekst,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var k = 0; k < 3; k++)
              if (k < 2) Expanded(child: _Steg(nr: k + 1, navn: steg[k].$1, ferdig: steg[k].$2, aktiv: steg[k].$3, sist: false)) else _Steg(nr: 3, navn: steg[k].$1, ferdig: steg[k].$2, aktiv: steg[k].$3, sist: true),
          ],
        ),
        const SizedBox(height: 16),
        Text('HVA KALLER DU DEN?', style: inter(10.5, weight: FontWeight.w800, em: .08, color: const Color.fromRGBO(255, 255, 255, .66))),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final (i, m) in const ['Hjem', 'Jobb', 'Hytte', 'Annet'].indexed) ...[
              if (i > 0) const SizedBox(width: 7),
              Expanded(
                child: _MerkeFlis(
                  key: ValueKey('merke-$m-${m == _merke ? _merkeN : 0}'),
                  navn: m,
                  valgt: m == _merke,
                  onTap: () => setState(() {
                    if (_merke != m) _merkeN++;
                    _merke = m;
                  }),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Text('ADRESSE', style: inter(10.5, weight: FontWeight.w800, em: .08, color: const Color.fromRGBO(255, 255, 255, .66))),
        const SizedBox(height: 8),
        if (!valgt) _sokFelt() else _valgtKort(gate, nr),
        const SizedBox(height: 16),
        Row(
          children: [
            Text.rich(
              TextSpan(
                text: 'TIL BUDET ',
                style: inter(10.5, weight: FontWeight.w800, em: .08, color: const Color.fromRGBO(255, 255, 255, .66)),
                children: [TextSpan(text: '· valgfritt', style: inter(10.5, color: const Color.fromRGBO(255, 255, 255, .5)))],
              ),
            ),
            const Spacer(),
            SvgPicture.string(
              '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M12 3a6 6 0 0 0-3.5 10.9V17h7v-3.1A6 6 0 0 0 12 3z" fill="${info ? '#FFD27A' : 'none'}" stroke="${info ? '#FFD27A' : 'rgba(255,255,255,.5)'}" stroke-width="2" stroke-linejoin="round"/><path d="M9.5 20.5h5" stroke="${info ? '#FFD27A' : 'rgba(255,255,255,.5)'}" stroke-width="2" stroke-linecap="round"/></svg>',
              width: 12,
              height: 12,
            ),
            const SizedBox(width: 5),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 400),
              style: inter(10.5, weight: FontWeight.w800, color: info ? const Color(0xFFFFD27A) : const Color.fromRGBO(255, 255, 255, .5)),
              child: Text(info ? 'Lyset er på' : 'Tenner lyset'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        CssBox(
          height: 50,
          radius: BorderRadius.circular(16),
          bg: const [CssLinear(180, [Color.fromRGBO(255, 255, 255, .15), Color.fromRGBO(255, 255, 255, .07)])],
          border: Border.all(color: const Color.fromRGBO(255, 255, 255, .22)),
          shadows: const [CssShadow.inset(0, 2, 4, 0, Color.fromRGBO(3, 16, 24, .25)), CssShadow(0, 2.5, 0, 0, Color.fromRGBO(4, 20, 28, .4))],
          padding: const EdgeInsets.fromLTRB(14, 0, 9, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _info,
                  cursorColor: const Color(0xFF5CE0B8),
                  style: jakarta(13.5, weight: FontWeight.w600),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'Etasje, ring på, inngang, kode …',
                    hintStyle: jakarta(13.5, weight: FontWeight.w600, color: const Color.fromRGBO(255, 255, 255, .45)),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              GestureDetector(
                onTap: () => widget.kilde.toast('Kommer snart'),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color.fromRGBO(255, 255, 255, .12)),
                  alignment: Alignment.center,
                  child: SvgPicture.string(_kMik, width: 13, height: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (klar)
          _Inn(
            key: const ValueKey('lagre'),
            child: LfPress(
              dy: 3.5,
              onTap: _lagre,
              child: CssBox(
                height: 54,
                radius: BorderRadius.circular(17),
                clip: true,
                bg: const [CssLinear(180, [Color(0xFFFFA77C), Color(0xFFF26D3D), Color(0xFFE95C2C)], [0, .55, 1])],
                shadows: const [
                  CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .5)),
                  CssShadow.inset(0, -2, 0, 0, Color.fromRGBO(0, 0, 0, .08)),
                  CssShadow(0, 4, 0, 0, Color(0xFFA63A12)),
                  CssShadow(0, 14, 20, -8, Color.fromRGBO(120, 40, 10, .6)),
                ],
                child: Stack(
                  children: [
                    const Positioned(
                      left: 12,
                      right: 12,
                      top: 2,
                      height: 54 * .46,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.elliptical(14, 14),
                            topRight: Radius.elliptical(14, 14),
                            bottomLeft: Radius.elliptical(30, 10),
                            bottomRight: Radius.elliptical(30, 10),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color.fromRGBO(255, 255, 255, .3), Color.fromRGBO(255, 255, 255, 0)],
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.string(_kHus, width: 16, height: 16),
                          const SizedBox(width: 9),
                          Text(
                            _lagrer ? 'Lagrer …' : 'Lagre og lever hit',
                            style: jakarta(15, shadows: const [Shadow(color: Color.fromRGBO(120, 40, 10, .4), offset: Offset(0, 1))]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          CustomPaint(
            foregroundPainter: const _Stiplet(radius: 17, farge: Color.fromRGBO(255, 255, 255, .24), bredde: 1.5),
            child: Container(
              height: 54,
              decoration: BoxDecoration(color: const Color.fromRGBO(255, 255, 255, .06), borderRadius: BorderRadius.circular(17)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.string(
                    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,.66)" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><rect x="5" y="11" width="14" height="10" rx="2.5"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/></svg>',
                    width: 14,
                    height: 14,
                  ),
                  const SizedBox(width: 8),
                  Text('Skriv adressen først', style: inter(13, weight: FontWeight.w800, color: const Color.fromRGBO(255, 255, 255, .66))),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _sokFelt() {
    final fok = _adrFokus.hasFocus;
    Widget felt = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 54,
      padding: const EdgeInsets.fromLTRB(7, 0, 12, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.fromRGBO(255, 255, 255, .15), Color.fromRGBO(255, 255, 255, .07)],
        ),
        border: Border.all(color: fok ? const Color.fromRGBO(92, 224, 184, .6) : const Color.fromRGBO(255, 255, 255, .26)),
        boxShadow: [
          const BoxShadow(color: Color.fromRGBO(4, 20, 28, .4), offset: Offset(0, 2.5)),
          if (fok) const BoxShadow(color: Color.fromRGBO(92, 224, 184, .14), spreadRadius: 4),
        ],
      ),
      child: Row(
        children: [
          CssBox(
            width: 38,
            height: 38,
            radius: BorderRadius.circular(12),
            bg: const [CssRadial([Color(0xFF3A8296), Color(0xFF1E4F5C)], rx: .7, ry: .6, cx: .4, cy: .25)],
            shadows: const [CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .3)), CssShadow(0, 2, 0, 0, Color.fromRGBO(4, 20, 28, .5))],
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: LfLoop(
                      builder: (context, t, child) {
                        final p = cssEaseOut.transform((t / 2200) % 1.0);
                        return Opacity(opacity: .9 * (1 - p), child: Transform.scale(scale: .6 + 1.3 * p, child: child));
                      },
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: const Color.fromRGBO(127, 240, 203, .5), width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ),
                SvgPicture.string(_kNaal, width: 14, height: 14),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _adr,
              focusNode: _adrFokus,
              cursorColor: const Color(0xFF5CE0B8),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                final q = _adr.text.trim();
                if (RegExp(r'\d').hasMatch(q) && q.length > 4) {
                  final m = _forslag.where((f) => !f.egen && f.full.toLowerCase().startsWith(q.toLowerCase())).firstOrNull;
                  _velg(m ?? AdrForslag(gate: q, sted: 'Ny adresse i Bergen', egen: true));
                }
              },
              style: jakarta(14, weight: FontWeight.w700),
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: 'Gateadresse og nummer',
                hintStyle: jakarta(14, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .45)),
              ),
            ),
          ),
        ],
      ),
    );
    final innhold = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        felt,
        if (_forslag.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            child: CssBox(
              radius: BorderRadius.circular(16),
              bg: const [CssLinear(180, [Color.fromRGBO(255, 255, 255, .12), Color.fromRGBO(255, 255, 255, .05)])],
              shadows: const [
                CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .22)),
                CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .1)),
                CssShadow(0, 14, 22, -14, Color.fromRGBO(3, 14, 20, .85)),
              ],
              padding: const EdgeInsets.all(4),
              child: Column(
                children: [
                  for (var n = 0; n < _forslag.length; n++)
                    _ForslagRad(key: ValueKey('f-${_forslag[n].full}'), f: _forslag[n], delayMs: n * 50.0, onTap: () => _velg(_forslag[n])),
                ],
              ),
            ),
          ),
      ],
    );
    if (!_endret) return innhold;
    // naTilbake .45s when coming back from the chosen card.
    return LfOnce(
      ms: 450,
      builder: (context, t, child) {
        final e = const Cubic(.2, 1.2, .3, 1).transform((t / 450).clamp(0.0, 1.0));
        return Opacity(
          opacity: e.clamp(0.0, 1.0),
          child: Transform(
            alignment: Alignment.topCenter,
            transform: Matrix4.identity()
              ..setEntry(3, 2, -1 / 700)
              ..rotateX(rad(60 * (1 - e)))
              ..scaleByDouble(.96 + .04 * e, .96 + .04 * e, 1, 1),
            child: child,
          ),
        );
      },
      child: innhold,
    );
  }

  Widget _valgtKort(String gate, String? nr) {
    final sted = _valgt!.egen ? 'Ny adresse i Bergen' : _valgt!.sted;
    return LfOnce(
      ms: 1100,
      builder: (context, t, child) {
        // naFlipp .7s
        final p = (t / 700).clamp(0.0, 1.0);
        const c = Cubic(.2, 1.2, .3, 1);
        final rx = kf(p, const [0, 1], const [-75, 0], c);
        final y = kf(p, const [0, 1], const [-10, 0], c);
        final s = kf(p, const [0, 1], const [.94, 1], c);
        final o = kf(p, const [0, .6, 1], const [0, 1, 1], c);
        return Opacity(
          opacity: o.clamp(0.0, 1.0),
          child: Transform(
            alignment: Alignment.topCenter,
            transform: Matrix4.identity()
              ..setEntry(3, 2, -1 / 700)
              ..rotateX(rad(rx))
              ..translateByDouble(0, y, 0, 1)
              ..scaleByDouble(s, s, 1, 1),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdrDorskilt(
            delayMs: 0,
            nr: nr ?? _merke.substring(0, 1),
            eyebrow: _kEyebrow[_merke] ?? 'DITT STED',
            gate: gate.isEmpty ? _valgt!.gate : gate,
            sub: sted.replaceFirst(RegExp(r',?\s*Norge$|,?\s*Norway$'), ''),
            hoyre: LfPress(
              dy: 2,
              onTap: () {
                setState(() {
                  _valgt = null;
                  _endret = true;
                });
                _adrFokus.requestFocus();
              },
              child: CssBox(
                height: 34,
                radius: BorderRadius.circular(12),
                bg: const [CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFE4EDEF)])],
                shadows: const [
                  CssShadow.inset(0, 1, 0, 0, Color(0xFFFFFFFF)),
                  CssShadow(0, 2.5, 0, 0, Color(0xFF9FB2B6)),
                  CssShadow(0, 6, 10, -5, Color.fromRGBO(30, 60, 70, .45)),
                ],
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(widthFactor: 1, child: Text('Endre', style: inter(12, weight: FontWeight.w800, color: const Color(0xFF1E4F5C)))),
              ),
            ),
          ),
          if (_dek case final d? when d.dekket && !d.pauset)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Center(
                child: _Inn.kort(
                  delayMs: 600,
                  child: _DekChip(tekst: 'Ægil leverer hit${d.eta == null ? '' : ' · ${d.eta}'}', liten: true),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ForslagRad extends StatelessWidget {
  const _ForslagRad({super.key, required this.f, required this.delayMs, required this.onTap});
  final AdrForslag f;
  final double delayMs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: delayMs + 380,
    builder: (context, t, child) {
      final e = const Cubic(.2, 1.15, .3, 1).transform(kfP(t, delayMs, 380));
      return Opacity(
        opacity: e.clamp(0.0, 1.0),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.translationValues(0, 14 * (1 - e), 0)..scaleByDouble(.96 + .04 * e, .96 + .04 * e, 1, 1),
          child: child,
        ),
      );
    },
    child: LfPress(
      scale: .98,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            CssBox(
              width: 30,
              height: 30,
              radius: BorderRadius.circular(10),
              bg: const [CssLinear(160, [Color(0xFF3F8798), Color(0xFF27606F), Color(0xFF1A4654)], [0, .52, 1])],
              shadows: const [
                CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .3)),
                CssShadow.inset(0, -2, 4, 0, Color.fromRGBO(4, 20, 28, .4)),
                CssShadow(0, 6, 8, -5, Color.fromRGBO(3, 16, 24, .8)),
              ],
              child: Center(child: SvgPicture.string(_kNaal.replaceAll('#7FF0CB', '#FFFFFF'), width: 13, height: 13)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.gate, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(13, weight: FontWeight.w800)),
                  Text(f.sted, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(10.5, weight: FontWeight.w700, color: const Color(0xFFBFD6DD))),
                ],
              ),
            ),
            SvgPicture.string(
              '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,.5)" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"><path d="M9 6l6 6-6 6"/></svg>',
              width: 12,
              height: 12,
            ),
          ],
        ),
      ),
    ),
  );
}

class _Steg extends StatelessWidget {
  const _Steg({required this.nr, required this.navn, required this.ferdig, required this.aktiv, required this.sist});
  final int nr;
  final String navn;
  final bool ferdig, aktiv, sist;

  @override
  Widget build(BuildContext context) {
    final sirkel = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: ferdig
            ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFA6F8DD), Color(0xFF3CC79F)])
            : aktiv
            ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFA77C), Color(0xFFE95C2C)])
            : null,
        color: ferdig || aktiv ? null : const Color.fromRGBO(255, 255, 255, .1),
        border: ferdig || aktiv ? null : Border.all(color: const Color.fromRGBO(255, 255, 255, .3), width: 1.5),
        boxShadow: ferdig
            ? const [BoxShadow(color: Color(0xFF23946F), offset: Offset(0, 2))]
            : aktiv
            ? const [BoxShadow(color: Color(0xFFA63A12), offset: Offset(0, 2)), BoxShadow(color: Color.fromRGBO(242, 109, 61, .18), spreadRadius: 4)]
            : null,
      ),
      alignment: Alignment.center,
      child: ferdig
          ? SvgPicture.string(_kHake.replaceAll('#1F8A66', '#0F3A40'), width: 11, height: 11)
          : Text('$nr', style: jakarta(10.5, color: aktiv ? Colors.white : const Color.fromRGBO(255, 255, 255, .7))),
    );
    final tekst = AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 300),
      style: inter(11, weight: FontWeight.w800, color: ferdig ? const Color(0xFF9FF0D4) : aktiv ? Colors.white : const Color.fromRGBO(255, 255, 255, .55)),
      child: Text(navn, maxLines: 1),
    );
    return Row(
      mainAxisSize: sist ? MainAxisSize.min : MainAxisSize.max,
      children: [
        sirkel,
        const SizedBox(width: 6),
        tekst,
        if (!sist) ...[
          const SizedBox(width: 6),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              height: 3,
              decoration: BoxDecoration(color: ferdig ? const Color(0xFF5CE0B8) : const Color.fromRGBO(255, 255, 255, .16), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _MerkeFlis extends StatelessWidget {
  const _MerkeFlis({super.key, required this.navn, required this.valgt, required this.onTap});
  final String navn;
  final bool valgt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final win = valgt ? const Color(0xFFFFD27A) : const Color(0xFF2C5562);
    final winB = valgt ? const Color(0xFFBFF5E4) : const Color(0xFF2C5562);
    final bilde = switch (navn) {
      'Jobb' => kMerkeJobb,
      'Hytte' => kMerkeHytte,
      'Annet' => kMerkeAnnet,
      _ => kMerkeHus,
    };
    Widget flis = CssBox(
      width: 38,
      height: 38,
      radius: BorderRadius.circular(12),
      clip: true,
      bg: [
        valgt
            ? const CssLinear(180, [Color(0xFF4A97A9), Color(0xFF24596A)])
            : const CssLinear(180, [Color.fromRGBO(255, 255, 255, .16), Color.fromRGBO(255, 255, 255, .05)]),
      ],
      shadows: const [
        CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .35)),
        CssShadow.inset(0, -2.5, 0, 0, Color.fromRGBO(4, 20, 28, .25)),
        CssShadow(0, 2.5, 0, 0, Color.fromRGBO(4, 20, 28, .35)),
      ],
      child: Stack(
        children: [
          const Positioned(left: 0, right: 0, bottom: 0, height: 6, child: ColoredBox(color: Color.fromRGBO(8, 28, 36, .4))),
          AdrTegning(bilde: bilde, t: 0, vars: {'win': win, 'winB': winB}, width: 38, height: 38),
        ],
      ),
    );
    if (valgt) {
      // naTile .5s
      flis = LfOnce(
        ms: 500,
        builder: (context, t, child) {
          final p = (t / 500).clamp(0.0, 1.0);
          const c = Cubic(.3, 1.4, .5, 1);
          final s = kf(p, const [0, .35, .7, 1], const [1, 1.18, .96, 1], c);
          final r = kf(p, const [0, .35, .7, 1], const [0, -4, 2, 0], c);
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..scaleByDouble(s, s, 1, 1)
              ..rotateZ(rad(r)),
            child: child,
          );
        },
        child: flis,
      );
    }
    return LfPress(
      dy: 2,
      onTap: onTap,
      child: CssBox(
        radius: BorderRadius.circular(16),
        bg: [
          valgt
              ? const CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFF3EEE2)])
              : const CssLinear(180, [Color.fromRGBO(255, 255, 255, .13), Color.fromRGBO(255, 255, 255, .05)]),
        ],
        shadows: valgt
            ? const [
                CssShadow.inset(0, 1.5, 0, 0, Color(0xFFFFFFFF)),
                CssShadow(0, 0, 0, 2, Color(0xFFF26D3D)),
                CssShadow(0, 3, 0, 2, Color(0xFFA63A12)),
                CssShadow(0, 10, 16, -8, Color.fromRGBO(4, 18, 26, .8)),
              ]
            : const [
                CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .26)),
                CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .14)),
                CssShadow(0, 3, 0, 0, Color.fromRGBO(4, 20, 28, .35)),
              ],
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Column(
          children: [
            flis,
            const SizedBox(height: 5),
            Text(navn, maxLines: 1, style: inter(12, weight: FontWeight.w800, color: valgt ? const Color(0xFF1E4F5C) : const Color.fromRGBO(255, 255, 255, .85))),
          ],
        ),
      ),
    );
  }
}
