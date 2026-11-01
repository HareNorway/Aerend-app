import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../main.dart' show languages;
import '../../../networking/ops/ops_customer_api.dart';
import '../../../services/customer/beacons.dart';
import '../../../services/customer/client_flags.dart';
import '../../common/homeMainV1/home_main_v1.dart' show HomeMainV1State;
import '../aegil/aegil_entry.dart' show kAegilRoute;
import '../hjem/hjem_varsler.dart' show HjemVarsler;
import '../kit/bergen_routes.dart';
import '../kit/fane_bytte.dart' show BergenFaneBytte;
import '../sporing/hjelp_sheet.dart' show HjelpScreen;
import 'onb_maal.dart';
import 'onb_runde.dart';
import 'onb_status.dart';

/// Ægil's small poses in a coach mark (the design's `pose`; `watch`,
/// `concerned` and `relieved` are not used by the catalogue).
enum OnbTipPose { idle, wave, point, present, think, nod, celebrate, peekTop, peekBottom }

/// One entry of the design's `CM` table (Onboarding plan §3 #12, docx §4.2).
class OnbTip {
  const OnbTip(
    this.id, {
    required this.pose,
    required this.naar,
    this.mal,
    this.handling = false,
    this.autoMs,
    this.flagg,
    this.skjerm,
  });

  final String id;
  final OnbTipPose pose;

  /// The anchor the soft spotlight marks (`mal`), null for a free bubble.
  final String? mal;

  /// The mark has an action chip (`handling`).
  final bool handling;

  /// Auto-close override in ms (`auto`; the peek's 3000), else the config's.
  final int? autoMs;

  /// A client flag that must be on (D5: `fleks` waits for the flex window).
  final String? flagg;

  /// The condition (`naar`), read against [OnbTips]' state.
  final bool Function(OnbTips t) naar;

  /// Where the harness goes to force this mark (`cmTving`'s `SKJ`).
  final String? skjerm;

  String get tekst => OnbTipsCopy.tekst(id);
  String get handlingTekst => OnbTipsCopy.handling(id);

  /// The picture (`POSE` → the four bundled files).
  String get bilde => switch (pose) {
    OnbTipPose.wave || OnbTipPose.point || OnbTipPose.present || OnbTipPose.peekTop || OnbTipPose.peekBottom => 'popup',
    OnbTipPose.think => 'find',
    OnbTipPose.celebrate => 'voucher',
    OnbTipPose.idle || OnbTipPose.nod => 'front',
  };
}

/// The mark on screen (`st.cm`): which, where, forced, when.
class OnbTipVisning {
  const OnbTipVisning(this.tip, this.m, this.tving, this.t);
  final OnbTip tip;
  final OnbMaalRekt? m;
  final bool tving;
  final int t;
}

/// The «?» dot (`cmPrikk`): the mark it reopens and its target.
class OnbPrikk {
  const OnbPrikk(this.id, this.m);
  final String id;
  final OnbMaalRekt m;
}

/// Ægil-tips: the coach marks (Onboarding plan Step 4, prototype `cm*`
/// L16964–17073, docx §4). One instance; [OnbTipsLag] listens to it.
///
/// Screens tell it what is up through [sett] (`tilstand`), the anchors
/// through [OnbMaalRegistry], and register the actions their mark needs in
/// [handlinger]. Every change plans a check 900 ms later (`cmPlan`); the
/// check walks the catalogue in the design's order and shows the first mark
/// whose condition, flag and anchor hold — at most one per session, three
/// per day, never one seen before (the peek and the hand-off excepted),
/// never while the tour is up or before it was finished or skipped.
class OnbTips extends ChangeNotifier {
  OnbTips._() {
    OnbMaalRegistry.endring.addListener(plan);
    BergenFaneBytte.aktiv.addListener(plan);
    // The flags arrive after the first screen: a check once they do.
    ClientFlags.agents.addListener(plan);
  }

  static final OnbTips instance = OnbTips._();

  /// The design's `CM_REKKE` order.
  static final List<OnbTip> katalog = List.unmodifiable([
    OnbTip('peek', pose: OnbTipPose.peekBottom, autoMs: 3000, skjerm: 'hjem', naar: (t) => t.skjerm == 'hjem' && t.peekVentes),
    OnbTip('handoff', pose: OnbTipPose.peekBottom, skjerm: 'hjem', naar: (t) => OnbStatus.instance.handoffKlar && t.skjerm != 'annet'),
    OnbTip('nytt', pose: OnbTipPose.wave, handling: true, skjerm: 'hjem', naar: (t) => t.skjerm == 'hjem' && OnbStatus.instance.nyVersjon),
    OnbTip('bio', pose: OnbTipPose.think, handling: true, skjerm: 'agent', naar: (t) => t.agent && OnbRunde.bioPaa && !OnbStatus.instance.sett.contains('bio')),
    OnbTip('kamera', pose: OnbTipPose.point, skjerm: 'agent', naar: (t) => t.agent && OnbMaalRegistry.har('kamera')),
    OnbTip('adresse', pose: OnbTipPose.think, mal: 'dor', skjerm: 'kurv', naar: (t) => t.kurv && (t.les('dor') as String? ?? '').length > 3),
    OnbTip('fleks', pose: OnbTipPose.nod, mal: 'lev', flagg: 'pricing.flex_window', skjerm: 'kurv', naar: (t) => t.kurv),
    OnbTip('gebyr', pose: OnbTipPose.point, mal: 'lev', handling: true, skjerm: 'kurv', naar: (t) => t.kurv),
    OnbTip('kode', pose: OnbTipPose.point, mal: 'leveringskode', skjerm: 'sporing', naar: (t) => t.sporingStadie >= 2),
    OnbTip('varsler', pose: OnbTipPose.peekBottom, handling: true, skjerm: 'varsler', naar: (t) => t.les('varsler') == true),
    OnbTip('hjelp', pose: OnbTipPose.wave, skjerm: 'hjelp', naar: (t) => t.les('hjelp') == true),
    OnbTip('ai', pose: OnbTipPose.present, mal: 'ai', handling: true, skjerm: 'meg', naar: (t) => t.skjerm == 'meg'),
    OnbTip('abo', pose: OnbTipPose.nod, handling: true, skjerm: 'levert', naar: (t) => t.sporingStadie >= 3 && t.ordreAntall >= 2),
    OnbTip('gaver', pose: OnbTipPose.present, handling: true, skjerm: 'kategori', naar: (t) => t.les('kategori') == 4),
    OnbTip('feed', pose: OnbTipPose.peekTop, skjerm: 'utforsk', naar: (t) => t.skjerm == 'utforsk' && t.les('utforskFane') == 'feed'),
    OnbTip('pose', pose: OnbTipPose.point, mal: 'karusell-u', handling: true, skjerm: 'utforsk', naar: (t) => t.skjerm == 'utforsk'),
  ]);

  static OnbTip? finn(String id) {
    for (final c in katalog) {
      if (c.id == id) return c;
    }
    return null;
  }

  // ── State ──────────────────────────────────────────────────────────────

  /// The mark on screen, or null.
  OnbTipVisning? naa;

  /// Marks shown this session by themselves (`_cmSesjon`; forced ones don't count).
  int sesjonAntall = 0;

  /// After «Hopp over»: the peek «Jeg er her om du trenger meg» waits (`_vkPeek`).
  bool peekVentes = false;

  /// The harness forced a mark: as if the tour were done (`cmTving` sets `onbFerdig`).
  bool tvunget = false;

  /// Delivered orders, for `abo` (read once when a delivery is on screen).
  int ordreAntall = 0;
  bool _ordreHentet = false;

  /// What the screens report (`tilstand`): `agent`, `kurvRute`, `dor`,
  /// `sporing` (stage), `varsler`, `hjelp`, `kategori` (slot), `utforskFane`.
  final Map<String, Object?> _tilstand = {};

  /// Actions the screens own, by mark id (`handling[1]`): `gebyr`
  /// (the fee sheet), `pose` (the first bag), `gaver`, `bio`, `ai`,
  /// `aegilInnst`, `ukeshandel`, `kurvFlere`.
  final Map<String, VoidCallback> handlinger = {};

  /// The band a target is scrolled into before it is measured (the layer
  /// sets these from the real screen; the design's 120…700).
  double Function() bandLo = () => 120;
  double Function() bandHi = () => 700;

  /// `GET ops/customer/orders` for `abo`; tests replace it.
  Future<List<Map<String, dynamic>>> Function() hentOrdrer = () => OpsCustomerApi().orders(limit: 3);

  Timer? _planT, _autoT, _tvT, _armT;

  /// The outside-tap catcher is armed 80 ms after a mark shows (`cmVis`).
  bool armet = false;

  String get skjerm => OnbRunde.instance.skjermNaa();
  bool get agent => les('agent') == true;
  bool get kurv => skjerm == 'kurv' || les('kurvRute') == true;
  int get sporingStadie => (les('sporing') as num?)?.toInt() ?? -1;

  Object? les(String k) => _tilstand[k];

  /// A screen reports its state; null forgets it. Plans a check.
  void sett(String k, Object? v) {
    if (v == null) {
      if (_tilstand.remove(k) == null) return;
    } else {
      if (_tilstand[k] == v) return;
      _tilstand[k] = v;
    }
    plan();
  }

  /// `cmKan`: the tips flag, no tour up, and the tour out of the way
  /// (finished, skipped, an arrival that skipped it, or its flag off).
  bool get kan {
    if (OnbRunde.instance.aktiv) return false;
    if (tvunget) return true;
    if (!OnbStatus.tipsPaa) return false;
    final st = OnbStatus.instance;
    return st.ferdig || st.hoppet || st.ankomst != null || !OnbStatus.paa;
  }

  /// Three marks today already (docx §4.1; the config's `daily_cap`).
  bool get dagsKvoteBrukt {
    final st = OnbStatus.instance;
    final n = DateTime.now();
    final d0 = DateTime(n.year, n.month, n.day).millisecondsSinceEpoch;
    return st.cm.values.where((t) => t >= d0).length >= st.cmDag;
  }

  /// `cmPlan`: a check 900 ms from now (the docx's «screen visible ≥ 600 ms»).
  /// Nothing is armed while no mark may show ([kan]): the tour's end, the
  /// flags and the status each call again when that changes.
  void plan() {
    _planT?.cancel();
    if (!kan) return;
    _planT = Timer(const Duration(milliseconds: 900), sjekk);
  }

  /// The first mark that may show now, or null (`cmSjekk` without showing).
  String? velg() {
    if (!kan || naa != null) return null;
    final st = OnbStatus.instance;
    if (sesjonAntall >= st.cmSesjon || dagsKvoteBrukt) return null;
    for (final c in katalog) {
      if (st.cm.containsKey(c.id) && c.id != 'peek' && c.id != 'handoff') continue;
      if (c.flagg != null && !ClientFlags.on(c.flagg!)) continue;
      var ok = false;
      try {
        ok = c.naar(this);
      } catch (_) {}
      if (!ok) continue;
      if (c.mal != null && !OnbMaalRegistry.har(c.mal!)) continue;
      return c.id;
    }
    return null;
  }

  void sjekk() {
    if (!_ordreHentet && sporingStadie >= 3) _hentOrdrer();
    final id = velg();
    if (id != null) vis(id);
  }

  Future<void> _hentOrdrer() async {
    _ordreHentet = true;
    try {
      ordreAntall = (await hentOrdrer()).length;
      plan();
    } catch (_) {
      _ordreHentet = false;
    }
  }

  /// `cmVis`: scrolls the target into the band first (once), measures it,
  /// counts the session, remembers the mark as seen and shows it. False when
  /// a target is needed and cannot be found on screen.
  bool vis(String id, {bool tving = false, int forsok = 0}) {
    final c = finn(id);
    if (c == null) return false;
    OnbMaalRekt? m;
    if (c.mal != null) {
      m = OnbMaalRegistry.maal(c.mal!);
      final lo = bandLo(), hi = bandHi();
      if (forsok == 0 && (m == null || m.y < lo || m.y + m.h > hi)) {
        final flytt = OnbMaalRegistry.rull(c.mal!, lo: lo, hi: hi, rolig: true, fortrinn: 160);
        if (flytt != 0) {
          Timer(const Duration(milliseconds: 120), () => vis(id, tving: tving, forsok: 1));
          return true;
        }
      }
      if (m == null) {
        debugPrint('ONB_TIPS $id: målet ${c.mal} er ikke på skjermen');
        return false;
      }
    }
    _tvT?.cancel();
    _autoT?.cancel();
    if (!tving) sesjonAntall++;
    final st = OnbStatus.instance;
    st.merkCm(id);
    if (id == 'peek') peekVentes = false;
    if (id == 'handoff') st.handoffKlar = false;
    naa = OnbTipVisning(c, m, tving, DateTime.now().millisecondsSinceEpoch);
    armet = false;
    _armT?.cancel();
    _armT = Timer(const Duration(milliseconds: 80), () => armet = true);
    _autoT = Timer(Duration(milliseconds: c.autoMs ?? st.cmAutoSek * 1000), () => lukk(grunn: 'auto'));
    CusBeacons.melde('coach_mark_shown', screen: 'onb', data: {'id': id, 'forced': tving});
    debugPrint('ONB_TIPS vis $id${m != null ? ' @${m.rect}' : ''}${tving ? ' (tvunget)' : ''}');
    notifyListeners();
    return true;
  }

  /// `cmLukk`; [handlet] when the control or the chip was used.
  void lukk({String grunn = 'trykk', bool handlet = false}) {
    _autoT?.cancel();
    _armT?.cancel();
    armet = false;
    final v = naa;
    if (v == null) return;
    naa = null;
    if (handlet) OnbStatus.instance.merkCm(v.tip.id, handlet: true);
    CusBeacons.melde(handlet ? 'coach_mark_acted' : 'coach_mark_dismissed', screen: 'onb', data: {'id': v.tip.id, 'reason': grunn});
    debugPrint('ONB_TIPS lukk ${v.tip.id} ($grunn)');
    notifyListeners();
  }

  /// A tap outside the bubble (the design's `pointerdown` listener, 60 ms).
  void utenfor() {
    if (!armet || naa == null) return;
    Timer(const Duration(milliseconds: 60), () => lukk(grunn: 'utenfor'));
  }

  /// The action chip (`cmHandling`): close, then the action 80 ms later.
  void handling() {
    final v = naa;
    if (v == null) return;
    lukk(grunn: 'handling', handlet: true);
    Timer(const Duration(milliseconds: 80), () => utfor(v.tip.id));
  }

  /// The mark's action: the screen's own when registered, else the app's.
  void utfor(String id) {
    final egen = handlinger[id];
    if (egen != null) {
      try {
        egen();
      } catch (_) {}
      return;
    }
    switch (id) {
      case 'nytt':
        OnbRunde.instance.spillAv();
      case 'varsler':
        // «Innstillinger»: the panel away, Meg, then Ægil's settings sheet.
        _tilShell();
        _tilMeg('aegilInnst', ellers: () => _push(kAegilRoute));
      case 'abo':
        _tilMeg('ukeshandel');
      case 'bio':
        _tilMeg('megBio');
      case 'ai':
        _tilMeg('megAi');
      case 'gaver':
        _push(kAegilRoute, {'intent': 'gift', 'category': 'Gaver'});
      default:
        break;
    }
  }

  void _tilMeg(String h, {VoidCallback? ellers}) {
    OnbRunde.instance.gaaSkjerm('meg');
    Timer(const Duration(milliseconds: 600), () {
      final f = handlinger[h];
      if (f != null) {
        f();
      } else {
        ellers?.call();
      }
    });
  }

  void _tilShell() {
    final shell = HomeMainV1State.current;
    if (shell == null || !shell.mounted) return;
    final route = ModalRoute.of(shell.context);
    if (route != null && !route.isCurrent) Navigator.of(shell.context).popUntil((r) => r == route || r.isFirst);
  }

  void _push(String rute, [Map<String, String>? args]) {
    final c = HomeMainV1State.current?.context;
    if (c == null || !c.mounted) return;
    BergenRoutes.push<dynamic>(c, rute, arguments: args);
  }

  // ── The harness (`cmTving`) ─────────────────────────────────────────────

  /// Forces [id]: stops the tour, goes to the mark's screen, waits until the
  /// screen and the anchor are there (6 × 150 ms settled, 40 at most), then
  /// shows it as forced (no session count). `kode` / `abo` need Sporing open
  /// through the harness's own `sporing` / `levert` keys.
  void tving(String id) {
    final c = finn(id);
    if (c == null) return debugPrint('ONB_TIPS tving: ukjent id $id');
    lukk(grunn: 'tving');
    _planT?.cancel();
    _tvT?.cancel();
    tvunget = true;
    OnbRunde.instance.stopp();
    if (id == 'peek') peekVentes = true;
    if (id == 'handoff') OnbStatus.instance.handoffKlar = true;
    Timer(const Duration(milliseconds: 60), () {
      _gaaFor(id);
      var n = 0;
      void vent() {
        final klar = _klarFor(c);
        if ((klar && n >= 6) || n > 40) {
          if (!vis(id, tving: true)) debugPrint('ONB_TIPS tving $id: ikke klar (skjerm $skjerm, mål ${c.mal})');
          return;
        }
        n++;
        _tvT = Timer(const Duration(milliseconds: 150), vent);
      }

      vent();
    });
  }

  bool _klarFor(OnbTip c) {
    final ok = switch (c.skjerm) {
      null => true,
      'kurv' => kurv,
      'agent' => agent,
      'sporing' || 'levert' => les('sporing') != null,
      'varsler' => les('varsler') == true,
      'hjelp' => les('hjelp') == true,
      'kategori' => les('kategori') != null,
      final s => skjerm == s,
    };
    if (!ok) return false;
    return c.mal == null || OnbMaalRegistry.har(c.mal!);
  }

  void _gaaFor(String id) {
    final r = OnbRunde.instance;
    final shell = HomeMainV1State.current;
    switch (id) {
      case 'feed' || 'pose':
        r.gaaSkjerm('utforsk');
        Timer(const Duration(milliseconds: 350), () => r.forbered[id == 'feed' ? 'feed' : 'poser']?.call());
      case 'gaver':
        _push('/bergen/kategori/gaver', {'slug': 'gaver', 'name': 'Gaver'});
      case 'kamera':
        _push(kAegilRoute, {'intent': 'photo'});
      case 'bio':
        _push(kAegilRoute);
      case 'fleks' || 'gebyr' || 'adresse':
        r.gaaSkjerm('kurv');
        if (id == 'adresse') Timer(const Duration(milliseconds: 500), () => handlinger['kurvFlere']?.call());
      case 'varsler':
        if (shell != null && shell.mounted) HjemVarsler.apne(shell.context);
      case 'hjelp':
        if (shell != null && shell.mounted) HjelpScreen.apne(shell.context);
      case 'ai':
        r.gaaSkjerm('meg');
        Timer(const Duration(milliseconds: 400), () => r.forbered['ai']?.call());
      case 'nytt' || 'peek' || 'handoff':
        r.gaaSkjerm('hjem');
      default:
        break;
    }
  }

  // ── The «?» dot (`cmPrikk`) ─────────────────────────────────────────────

  /// The lighter variant: a seen mark with a target, not acted on, younger
  /// than `dot_days`, whose condition holds and whose target is on screen.
  OnbPrikk? prikk() {
    if (naa != null || OnbRunde.instance.aktiv || !(OnbStatus.tipsPaa || tvunget)) return null;
    final st = OnbStatus.instance;
    final n = DateTime.now().millisecondsSinceEpoch;
    for (final e in st.cm.entries) {
      final c = finn(e.key);
      if (c == null || c.mal == null || st.cmHandlet.contains(e.key)) continue;
      if (n - e.value > st.cmPrikkDager * 86400000) continue;
      var ok = false;
      try {
        ok = c.naar(this);
      } catch (_) {}
      if (!ok) continue;
      final m = OnbMaalRegistry.maal(c.mal!);
      if (m != null) return OnbPrikk(e.key, m);
    }
    return null;
  }

  @visibleForTesting
  void reset() {
    for (final t in [_planT, _autoT, _tvT, _armT]) {
      t?.cancel();
    }
    naa = null;
    sesjonAntall = 0;
    peekVentes = false;
    tvunget = false;
    armet = false;
    ordreAntall = 0;
    _ordreHentet = false;
    _tilstand.clear();
    handlinger.clear();
    bandLo = () => 120;
    bandHi = () => 700;
    hentOrdrer = () => OpsCustomerApi().orders(limit: 3);
  }
}

/// The strings (ARB `onb_tips_*`, `onb_cm_<id>`, `onb_cm_<id>_act`; NB from
/// the design's `CM` table, EN alongside).
abstract final class OnbTipsCopy {
  static String get merkelapp => languages.onb_tips_label;
  static String get lukk => languages.onb_tips_lukk;
  static String get prikk => languages.onb_tips_dot;

  static String tekst(String id) => switch (id) {
    'feed' => languages.onb_cm_feed,
    'pose' => languages.onb_cm_pose,
    'gaver' => languages.onb_cm_gaver,
    'kamera' => languages.onb_cm_kamera,
    'fleks' => languages.onb_cm_fleks,
    'gebyr' => languages.onb_cm_gebyr,
    'adresse' => languages.onb_cm_adresse,
    'kode' => languages.onb_cm_kode,
    'varsler' => languages.onb_cm_varsler,
    'hjelp' => languages.onb_cm_hjelp,
    'ai' => languages.onb_cm_ai,
    'abo' => languages.onb_cm_abo,
    'bio' => languages.onb_cm_bio,
    'nytt' => languages.onb_cm_nytt,
    'peek' => languages.onb_cm_peek,
    'handoff' => languages.onb_cm_handoff,
    _ => '',
  };

  static String handling(String id) => switch (id) {
    'pose' => languages.onb_cm_pose_act,
    'gaver' => languages.onb_cm_gaver_act,
    'gebyr' => languages.onb_cm_gebyr_act,
    'varsler' => languages.onb_cm_varsler_act,
    'ai' => languages.onb_cm_ai_act,
    'abo' => languages.onb_cm_abo_act,
    'bio' => languages.onb_cm_bio_act,
    'nytt' => languages.onb_cm_nytt_act,
    _ => '',
  };
}
