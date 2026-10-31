import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kDebugMode;

import 'package:flutter/material.dart';
import 'package:location/location.dart';

import '../../../utils/shared_pref_utill.dart' show prefGetInt, prefCartCount;
import '../../common/home/bergen/bergen_nav.dart' show BergenTab;
import '../../common/homeMainV1/home_main_v1.dart' show HomeMainV1State;
import '../kit/bergen_routes.dart';
import '../kit/bergen_toast.dart';
import '../../../services/customer/client_flags.dart';
import 'onb_maal.dart';
import 'onb_status.dart';
import 'onb_steg.dart';
import 'onb_tips.dart';

/// Where the tour is in a step (`rt.fase`).
enum OnbFase {
  /// Moving to the next target (nothing marked yet).
  flytter,

  /// The card's content fades out before the step changes.
  skifte,

  /// Standing at the target, talking.
  her,

  /// The mission was done: sparks, Ægil hops, then the next step.
  jubel,

  /// A section stamp slams in and flies to the HUD.
  stempel,

  /// The done card.
  ferdig,

  /// «Start å handle»: Ægil jumps out of the card onto the quay (the layer
  /// runs the flight, then stops the run).
  kai,

  /// The layer fades out.
  ut,
}

/// Ægil-runden: the in-app tour (Onboarding plan §3 #1–#7, prototype
/// `rt*` L16568–16963). One instance; the overlay [OnbLag] listens to it.
///
/// The engine owns the step table, the phase, the measured target and the
/// timers. It finds the targets through [OnbMaalRegistry], switches tabs
/// through the shell ([HomeMainV1State]) and scrolls targets into view. The
/// 220 ms tracker (`rtSporTikk`) finishes missions, follows a target that
/// moves, and repairs the run when the user wanders off.
class OnbRunde extends ChangeNotifier {
  OnbRunde._();

  static final OnbRunde instance = OnbRunde._();

  /// A debug cap on the steps (tests); the whole run otherwise.
  static int maksSteg = 1 << 20;

  /// The design's `onbMinBio`: the Min Bio step exists (Step 3 reads the flag).
  static bool bioPaa = true;

  // ── State ──────────────────────────────────────────────────────────────
  bool _aktiv = false;
  int i = 0;
  OnbFase fase = OnbFase.flytter;

  /// The target as last measured (global px), null before it is found.
  OnbMaalRekt? m;

  /// Which anchor [m] belongs to (the `legg` step switches between two).
  String? malId;

  /// Step counter for the alternating A/B keyframes (`rt.n`).
  int n = 0;
  List<String> ferdigeSek = const [];
  String? stempel;
  bool stFly = false;
  String? nySek;

  /// The step before this one ended a section (longer text delay).
  bool etterSt = false;

  /// The run is in reduced motion (`onbRolig` / the still tier).
  bool rolig = false;

  /// The phone answered the position question (`pos`): `tillatt`, `avslatt`
  /// (kept in [OnbStatus]).
  String? get pos => OnbStatus.instance.pos;
  set pos(String? v) {
    if (v != null) OnbStatus.instance.merkPos(v);
  }

  /// When the run started (`ms_total` in `onboarding_completed`).
  int _startT = 0;

  /// After a skip without a position answer, the OS prompt comes once on Hjem
  /// (`_vkSporPos`).
  bool _sporPos = false;

  /// `_rtSesjon`: the run started once this session (Step 3 gates on it).
  bool sesjon = false;

  List<OnbSteg> _steg = const [];
  Timer? _t, _spor, _typ, _bolge;
  bool _bytter = false;
  int _gjN = 0, _avvik = 0;
  int _herT = 0, _navT = 0, _rullT = 0;
  OnbMaalRekt? _malK, _stab, _rullM;
  String? _malKId;
  int _stabN = 0;

  /// What the overlay should animate right now; bumps on every change.
  int get rev => _rev;
  int _rev = 0;

  bool get aktiv => _aktiv;
  List<OnbSteg> get steg => _steg;
  OnbSteg? get naa => _aktiv && i < _steg.length ? _steg[i] : null;
  int get antall => _steg.length;

  /// The anchor the current step points at right now (`rt.mal`).
  String? get malNaa => malId;

  void _oppd() {
    _rev++;
    notifyListeners();
  }

  // ── Starting and stopping ──────────────────────────────────────────────

  /// `rtStart`: closes nothing yet (sheets are Step 3), goes Hjem, then the
  /// intro. [fra] = the step to start on (debug harness `onbRunde`).
  void start({int fra = 0, bool? rolig, String? auto}) {
    _rydd();
    this.auto = auto;
    _autoBrukt = false;
    sesjon = true;
    _startT = _naa();
    if (rolig != null) this.rolig = rolig;
    _steg = onbStegListe(bio: bioPaa, posisjonGitt: pos != null);
    _aktiv = true;
    i = 0;
    fase = OnbFase.flytter;
    m = null;
    malId = null;
    n = 0;
    ferdigeSek = const [];
    stempel = null;
    stFly = false;
    nySek = null;
    etterSt = false;
    _gjN = 0;
    _avvik = 0;
    _oppd();
    _antall0 = kurvAntall();
    final start = fra.clamp(0, math.min(_steg.length, maksSteg) - 1);
    // The run opens on the start step's screen (Hjem for the intro).
    final skjerm = _steg[start].skjerm;
    if (skjermNaa() != skjerm) {
      _navT = _naa();
      Future<void>.delayed(Duration.zero, () => gaaSkjerm(skjerm));
    }
    _t = Timer(const Duration(milliseconds: 200), () {
      if (start == 0) {
        _finn(0, 0);
      } else {
        // The harness jumps straight to a step: the sections before it count as done.
        final sek = _steg[start].sek;
        final k = kOnbSeksjoner.indexWhere((x) => x.id == sek);
        ferdigeSek = [for (var j = 0; j < k; j++) kOnbSeksjoner[j].id];
        i = start;
        _oppd();
        _finn(start, 0);
      }
    });
    debugPrint('ONB_RUNDE start $start');
  }

  void _rydd() {
    _t?.cancel();
    _spor?.cancel();
    _typ?.cancel();
    _bolge?.cancel();
    _bytter = false;
  }

  /// `rtStopp`: gone at once (no fade).
  void stopp() {
    _rydd();
    if (_aktiv) {
      _aktiv = false;
      m = null;
      _oppd();
      OnbTips.instance.plan();
    }
  }

  /// `rtLukk`: the whole layer fades out, then [etter].
  void lukk([VoidCallback? etter]) {
    if (!_aktiv) {
      etter?.call();
      return;
    }
    _rydd();
    fase = OnbFase.ut;
    _oppd();
    _t = Timer(Duration(milliseconds: rolig ? 40 : 440), () {
      stopp();
      etter?.call();
    });
  }

  // ── Steps ──────────────────────────────────────────────────────────────

  /// `rtGaa`: content out, a stamp when the section changes, the screen
  /// switch, then [_finn].
  void gaa(int til) {
    if (!_aktiv || til < 0 || _bytter) return;
    if (til >= _steg.length || til >= maksSteg) return _ferdig();
    _rydd();
    _bytter = true;
    _gjN = 0;
    _avvik = 0;
    final s = _steg[til], fra = _steg[i];
    final frem = til > i && !fra.intro && fra.sek != s.sek;
    fase = OnbFase.skifte;
    _oppd();
    _t = Timer(Duration(milliseconds: rolig ? 1 : 170), () {
      _bytter = false;
      void videre() {
        if (!_aktiv) return;
        final bytter = skjermNaa() != s.skjerm;
        i = til;
        fase = OnbFase.flytter;
        if (bytter) m = null;
        malId = null;
        stempel = null;
        stFly = false;
        etterSt = frem;
        _oppd();
        _antall0 = kurvAntall();
        if (bytter) {
          _navT = _naa();
          gaaSkjerm(s.skjerm);
        }
        _forbered(s.id);
        _t = Timer(Duration(milliseconds: bytter ? 160 : 30), () => _finn(til, 0));
      }

      if (frem) {
        _stempel(fra.sek, videre);
      } else {
        videre();
      }
    });
  }

  /// `rtStempel`: slams in (900 ms), flies to the HUD (520), the station pops (380).
  void _stempel(String sek, VoidCallback etter) {
    fase = OnbFase.stempel;
    stempel = sek;
    stFly = false;
    _oppd();
    final t0 = _naa();
    debugPrint('ONB_RUNDE stempel $sek slam (rolig $rolig)');
    _t = Timer(Duration(milliseconds: rolig ? 200 : 900), () {
      if (!_aktiv) return;
      stFly = true;
      _oppd();
      debugPrint('ONB_RUNDE stempel $sek fly +${_naa() - t0}');
      _t = Timer(Duration(milliseconds: rolig ? 40 : 520), () {
        if (!_aktiv) return;
        nySek = sek;
        ferdigeSek = [...ferdigeSek.where((x) => x != sek), sek];
        _oppd();
        debugPrint('ONB_RUNDE stempel $sek ok +${_naa() - t0}');
        _t = Timer(Duration(milliseconds: rolig ? 40 : 380), etter);
      });
    });
  }

  /// `rtFinn`: wait for the screen and the target (up to 3 s), scroll it into
  /// the band, mark the step seen, then talk.
  void _finn(int steg, int forsok) {
    if (!_aktiv || i != steg) return;
    final s = _steg[steg];
    final klar = skjermNaa() == s.skjerm && (s.mal == null || OnbMaalRegistry.har(s.mal!));
    final ventNav = _naa() - _navT < 650;
    if (forsok == 4 && !klar) _forbered(s.id);
    if ((!klar || ventNav) && forsok < 30) {
      _t = Timer(const Duration(milliseconds: 100), () => _finn(steg, forsok + 1));
      return;
    }
    final id = _malIdFor(s);
    var maal = id == null ? null : OnbMaalRegistry.maal(id);
    if (id != null && OnbMaalRegistry.har(id)) {
      final d = _rull(id);
      if (d != 0 && _rullM != null) maal = _rullM;
    }
    if (maal != null && (maal.y + maal.h < 0 || maal.w < 2)) maal = null;
    _herT = _naa();
    _malK = null;
    m = maal;
    malId = id;
    fase = OnbFase.her;
    n++;
    sett.add(s.id);
    OnbStatus.instance.merkSett(s.id);
    _oppd();
    _sporStart(steg);
    // Debug harness `onbAuto`: press the card's button by itself once.
    // (`start` presses «Neste» / «Fullfør» here first; the done card then presses itself.)
    if (kDebugMode && auto != null && !_autoBrukt && (auto == 'neste' || auto == 'vismeg' || auto == 'start' || auto == 'hopp')) {
      _autoBrukt = true;
      final a = auto;
      Timer(const Duration(milliseconds: 1500), () {
        if (!_aktiv || fase != OnbFase.her) return;
        if (a == 'neste' || a == 'start') neste();
        if (a == 'vismeg') visMeg();
        if (a == 'hopp') avslutt();
      });
    }
    debugPrint('ONB_RUNDE ${s.id} her${maal == null ? ' (uten mål)' : ''}');
  }

  /// Debug harness: `neste` | `vismeg` | `start` pressed by itself (see
  /// `HjemHarness.onbAuto`); `start` is the done card's button, the layer
  /// presses it.
  String? auto;
  bool _autoBrukt = false;

  /// Seen steps (`sett`), for the state sync in Step 3.
  final Set<String> sett = {};

  /// What a screen does before its step is measured (`s.forbered`): Utforsk
  /// switches to the feed / bag segment, Meg collapses the points card. The
  /// screens register by step id while they are mounted.
  final Map<String, VoidCallback> forbered = {};

  /// Stores on screen (pushed `/bergen/butikk/…` routes), for [skjermNaa].
  static int butikkerOppe = 0;

  /// The store the Butikk section opens: the first open restaurant Hjem
  /// shows (the design always rows to Burger King). Set by Hjem.
  int? butikkId;

  /// The quay Ægil is hidden while the kai-hopp flies (`skjul` / `vis`).
  final ValueNotifier<bool> kaiSkjult = ValueNotifier<bool>(false);

  void _forbered(String id) {
    final f = forbered[id];
    if (f == null) return;
    try {
      f();
    } catch (_) {}
  }

  String? _malIdFor(OnbSteg s) {
    if (s.malAlt != null && OnbMaalRegistry.har(s.malAlt!)) return s.malAlt;
    return s.mal;
  }

  /// The band a target is scrolled into, in global px: the prototype's
  /// 90 … 640 of the 844 frame, shifted for the real status bar.
  double Function()? bandLo, bandHi;

  double _rull(String id) {
    final lo = bandLo?.call() ?? 90, hi = bandHi?.call() ?? 640;
    final d = OnbMaalRegistry.rull(id, lo: lo, hi: hi, rolig: rolig);
    if (d == 0) {
      _rullM = null;
      return 0;
    }
    final r = OnbMaalRegistry.maal(id);
    _rullM = r == null ? null : OnbMaalRekt(r.rect.shift(Offset(0, -d)), r.radius);
    return d;
  }

  void _sporStart(int steg) {
    _spor?.cancel();
    _stab = null;
    _stabN = 0;
    _spor = Timer.periodic(const Duration(milliseconds: 220), (_) => _sporTikk(steg));
  }

  /// `rtSporTikk`.
  void _sporTikk(int steg) {
    if (!_aktiv || i != steg || fase != OnbFase.her) return;
    final s = _steg[steg];
    if (s.harOppdrag && oppdragFerdig(s)) return suksess(steg);
    // The target changed within the step (the product sheet opened): wait
    // until it stands still, then move the mark and say the other text.
    final idNaa = _malIdFor(s);
    if (idNaa != null && malId != null && idNaa != malId) {
      final r = OnbMaalRegistry.maal(idNaa);
      if (r == null || r.w < 2) {
        _malK = null;
        return;
      }
      if (_malK != null && _malKId == idNaa && _avstand(_malK!, r) < 6) {
        _malK = null;
        _herT = _naa();
        _avvik = 0;
        m = r;
        malId = idNaa;
        n++;
        _oppd();
        return;
      }
      _malK = r;
      _malKId = idNaa;
      return;
    }
    final siden = _naa() - _herT;
    // Self-repair: the screen changed under the run, or the target is gone.
    if (siden > 820) {
      final feilSkjerm = skjermNaa() != s.skjerm, borte = s.mal != null && OnbMaalRegistry.maal(_malIdFor(s)!) == null;
      _avvik = (feilSkjerm || borte) ? _avvik + 1 : 0;
      if (_avvik >= (feilSkjerm ? 2 : 4) && _gjN < 3) {
        _avvik = 0;
        _gjN++;
        return _gjenopprett(steg);
      }
    }
    // Follow the target once it stands still; scroll it back in when it left the band.
    if (s.mal != null && siden > 820) {
      final id = _malIdFor(s)!;
      final r = OnbMaalRegistry.maal(id);
      final r0 = r ?? (OnbMaalRegistry.har(id) ? const OnbMaalRekt(Rect.fromLTWH(0, -9999, 0, 0), 22) : null);
      if (r0 == null) {
        _stab = null;
        return;
      }
      final k = _stab;
      _stab = r0;
      if (k == null || _avstand(k, r0) >= 6) {
        _stabN = 0;
        return;
      }
      _stabN++;
      if (_stabN >= 2 && _naa() - _rullT > 1200) {
        final d = _rull(id);
        if (d != 0 && _rullM != null) {
          _rullT = _naa();
          _stab = null;
          _avvik = 0;
          m = _rullM;
          _oppd();
          return;
        }
      }
      if (r == null || r.w <= 1) return;
      if (m == null || _avstand(m!, r) > 4) {
        m = r;
        _oppd();
      }
    }
  }

  double _avstand(OnbMaalRekt a, OnbMaalRekt b) =>
      (a.x - b.x).abs() + (a.y - b.y).abs() + (a.w - b.w).abs() + (a.h - b.h).abs();

  /// `rtGjenopprett`: softly back to the right screen and find the target again.
  void _gjenopprett(int steg) {
    if (!_aktiv || i != steg || _bytter) return;
    final s = _steg[steg];
    _spor?.cancel();
    _bytter = true;
    fase = OnbFase.skifte;
    _oppd();
    _t = Timer(Duration(milliseconds: rolig ? 1 : 170), () {
      _bytter = false;
      if (!_aktiv) return;
      final bytter = skjermNaa() != s.skjerm;
      fase = OnbFase.flytter;
      m = null;
      etterSt = false;
      _oppd();
      if (bytter) {
        _navT = _naa();
        gaaSkjerm(s.skjerm);
      }
      _forbered(s.id);
      _t = Timer(Duration(milliseconds: bytter ? 160 : 30), () => _finn(steg, 0));
    });
  }

  /// `rtSuksess`: the mission is done.
  void suksess(int steg) {
    _spor?.cancel();
    if (!_aktiv) return;
    fase = OnbFase.jubel;
    _oppd();
    debugPrint('ONB_RUNDE ${_steg[steg].id} fullført');
    _t = Timer(Duration(milliseconds: rolig ? 300 : 1150), () => gaa(steg + 1));
  }

  /// «Neste» / a tap on the hole or the dim (never on a mission).
  void neste() {
    if (!_aktiv || fase != OnbFase.her) return;
    final s = naa;
    if (s == null || s.harOppdrag) return;
    gaa(i + 1);
  }

  /// A tap on the dim: like «Neste», but not on the intro.
  void bak() {
    final s = naa;
    if (s == null || s.intro) return;
    neste();
  }

  /// «Tilbake»: skips the mission steps.
  void tilbake() {
    if (!_aktiv || fase != OnbFase.her) return;
    final j = tilbakeTil(_steg, i);
    if (j >= 1) gaa(j);
  }

  /// The step «Tilbake» lands on from [i]: the previous one that is not a
  /// mission, never the intro (−1 when there is none).
  static int tilbakeTil(List<OnbSteg> steg, int i) {
    var j = i - 1;
    while (j > 1 && steg[j].harOppdrag) {
      j--;
    }
    return j >= 1 ? j : -1;
  }

  /// «Vis meg»: a navigation mission completes at once; another runs its
  /// action ([autoHandler], set by the screen that owns the mission).
  void visMeg() {
    if (!_aktiv || fase != OnbFase.her) return;
    final s = naa;
    if (s == null || !s.harOppdrag) return;
    if (s.navAuto) {
      suksess(i);
      return;
    }
    autoHandler?.call(s);
  }

  /// The action of a mission's «Vis meg» that is not a navigation (`legg`,
  /// Step 2 sets it from the store screen).
  void Function(OnbSteg s)? autoHandler;

  /// «Hopp over» / the HUD's ×: `rtAvslutt`.
  void avslutt() {
    hoppet = !ferdig;
    debugPrint('ONB_RUNDE hoppet over ved ${naa?.id}');
    OnbStatus.instance.merkHoppet(i, naa?.id ?? '');
    _sporPos = pos == null;
    // Step 4: the peek «Jeg er her om du trenger meg» on Hjem afterwards (`_vkPeek`).
    OnbTips.instance.peekVentes = true;
    lukk(() {
      if (_sporPos) _posEtterHopp();
    });
  }

  /// The position prompt once on Hjem after a skip (`_vkSporPos` → `vkDialog`),
  /// 900 ms after the layer is gone: the real OS prompt (D3).
  void _posEtterHopp() {
    _sporPos = false;
    Timer(const Duration(milliseconds: 900), () async {
      if (_aktiv || pos != null || skjermNaa() != 'hjem') return;
      final c = HomeMainV1State.current?.context;
      if (c == null || !c.mounted) return;
      await _sporrPos(c, spor: true);
    });
  }

  bool hoppet = false, ferdig = false;

  /// After the last step: `rtFerdig` — the last section's stamp, then the
  /// done card. (A debug cap below the table's length closes softly.)
  void _ferdig() {
    if (maksSteg < _steg.length) {
      debugPrint('ONB_RUNDE slutt (maksSteg $maksSteg)');
      lukk();
      return;
    }
    ferdig = true;
    debugPrint('ONB_RUNDE ferdig');
    _rydd();
    _bytter = true;
    final sist = _steg.last.sek;
    fase = OnbFase.skifte;
    _oppd();
    _t = Timer(Duration(milliseconds: rolig ? 1 : 170), () {
      _bytter = false;
      _stempel(sist, () {
        if (!_aktiv) return;
        fase = OnbFase.ferdig;
        stempel = null;
        stFly = false;
        ferdigeSek = [for (final x in kOnbSeksjoner) x.id];
        _oppd();
      });
    });
  }

  /// «Start å handle» (`rtSlutt`): the run is done. With motion, the layer
  /// plays the kai-hopp (fase `kai`) and stops the run when Ægil has landed;
  /// otherwise the layer fades and Hjem comes back.
  void slutt() {
    if (!_aktiv || fase != OnbFase.ferdig) return;
    ferdig = true;
    hoppet = false;
    debugPrint('ONB_RUNDE slutt');
    OnbStatus.instance.merkFerdig(msTotal: _naa() - _startT);
    if (rolig || !kaiHoppKan) {
      lukk(() => gaaSkjerm('hjem'));
      return;
    }
    _rydd();
    fase = OnbFase.kai;
    _oppd();
    // The flight's 230 ms: Hjem comes back under Ægil.
    _t = Timer(const Duration(milliseconds: 230), () => gaaSkjerm('hjem'));
  }

  /// The layer says whether it can fly (it needs the done card's Ægil).
  bool kaiHoppKan = true;

  /// The layer calls this when the kai-hopp has landed or gave up.
  void kaiFerdig() {
    kaiSkjult.value = false;
    stopp();
  }

  // ── The action chip (step 1: the position) ─────────────────────────────

  /// «Bruk posisjonen min»: the real OS prompt, the answer kept as `pos`
  /// (decision D3). The toasts are the design's.
  Future<void> handling(BuildContext context) async {
    final s = naa;
    if (s == null || s.handling == null) return;
    await _sporrPos(context);
    _oppd();
  }

  /// Asks the OS once (when it still can) and keeps the answer; the design's
  /// two toasts. [spor]: the prompt after a skip, silent when the phone
  /// already answered before.
  Future<void> _sporrPos(BuildContext context, {bool spor = false}) async {
    var svar = 'avslatt';
    var spurt = false;
    try {
      final loc = Location();
      var p = await loc.hasPermission();
      if (p == PermissionStatus.denied) {
        spurt = true;
        p = await loc.requestPermission();
      }
      svar = (p == PermissionStatus.granted || p == PermissionStatus.grantedLimited) ? 'tillatt' : 'avslatt';
    } catch (_) {}
    pos = svar;
    if (spor && !spurt) return;
    final c = HomeMainV1State.current?.context ?? context;
    if (c.mounted) showBergenToast(c, svar == 'tillatt' ? OnbCopy.posTillatt : OnbCopy.posAvslatt);
  }

  /// Reads the position permission without asking: an earlier «yes» hides
  /// step 1's chip (`onbPosisjonGitt`).
  Future<void> lesPos() async {
    if (pos != null) return;
    try {
      final p = await Location().hasPermission();
      if (p == PermissionStatus.granted || p == PermissionStatus.grantedLimited) pos = 'tillatt';
    } catch (_) {}
  }

  // ── The trigger (`vkKanskjeStart`) ──────────────────────────────────────

  /// Starts the run once per session for a customer who has neither finished
  /// nor skipped it (decision D2: existing accounts too), never on an
  /// arrival from an assistant or a push, never over a sheet, dialog or
  /// pushed screen (retries every 800 ms), only with the `cus.onboarding`
  /// flag. [harness]: the debug harness starts the run itself.
  static Future<void> kanskjeStart({bool harness = false, int forsok = 0}) async {
    final r = instance, st = OnbStatus.instance;
    if (r._aktiv || r.sesjon || harness) return;
    await st.last();
    if (!ClientFlags.known(OnbStatus.flagg)) await ClientFlags.refresh();
    final hvorfor = hindring(st);
    if (hvorfor != null) return debugPrint('ONB_RUNDE ikke start ($hvorfor)');
    if (!r._shellFri()) {
      if (forsok < 40) Timer(const Duration(milliseconds: 800), () => kanskjeStart(forsok: forsok + 1));
      return;
    }
    await r.lesPos();
    if (r._aktiv || r.sesjon || st.ankomst != null) return;
    debugPrint('ONB_RUNDE auto-start');
    r.start();
  }

  /// Why the run must not start by itself, or null: the flag is off, it was
  /// finished or skipped before, or the session arrived on a task.
  static String? hindring(OnbStatus st) {
    if (!OnbStatus.paa) return 'flagget er av';
    if (st.ferdig) return 'fullført før';
    if (st.hoppet) return 'hoppet over før';
    if (st.ankomst != null) return 'ankomst ${st.ankomst}';
    return null;
  }

  /// A replay from Meg or the Hjem card: reads the position first.
  Future<void> spillAv() async {
    OnbStatus.instance.merkReplay();
    await lesPos();
    start();
  }

  /// The shell is up and nothing (a sheet, a dialog, a pushed screen) is over it.
  bool _shellFri() {
    final shell = HomeMainV1State.current;
    if (shell == null || !shell.mounted) return false;
    return ModalRoute.of(shell.context)?.isCurrent ?? true;
  }

  // ── Screens ────────────────────────────────────────────────────────────

  /// Which design screen is up: `hjem` / `utforsk` / `kurv` / `meg` for the
  /// shell's tabs, `butikk` for a pushed store, else `annet`.
  String skjermNaa() {
    final shell = HomeMainV1State.current;
    if (shell == null || !shell.mounted) return 'annet';
    final route = ModalRoute.of(shell.context);
    if (route != null && !route.isCurrent) return butikkerOppe > 0 ? 'butikk' : 'annet';
    return switch (shell.selectedPos) {
      0 => 'hjem',
      1 => 'utforsk',
      2 => 'kurv',
      3 => 'meg',
      _ => 'annet',
    };
  }

  /// `gaa(s)`: back to the shell, then the tab; `butikk` pushes the store
  /// (Menisk) over the shell when it is not already up.
  void gaaSkjerm(String s) {
    final shell = HomeMainV1State.current;
    if (shell == null || !shell.mounted) return;
    final nav = Navigator.of(shell.context);
    final route = ModalRoute.of(shell.context);
    if (s == 'butikk') {
      if (butikkerOppe > 0) return;
      final id = butikkId;
      if (id == null) return;
      if (route != null && !route.isCurrent) nav.popUntil((r) => r == route || r.isFirst);
      BergenRoutes.push<dynamic>(shell.context, '/bergen/butikk/$id');
      return;
    }
    if (route != null && !route.isCurrent) nav.popUntil((r) => r == route || r.isFirst);
    final tab = switch (s) {
      'hjem' => BergenTab.home.index,
      'utforsk' => BergenTab.explore.index,
      'kurv' => BergenTab.cart.index,
      'meg' => BergenTab.me.index,
      _ => -2,
    };
    if (tab >= 0) shell.switchToTab(tab);
  }

  /// `s.ferdig(st)`: the mission's condition. Navigation missions check the
  /// screen; `legg` (Step 2) asks [kurvSum].
  bool oppdragFerdig(OnbSteg s) => switch (s.id) {
    'utforsk' => skjermNaa() == 'utforsk',
    'tilkurv' => skjermNaa() == 'kurv',
    'legg' => kurvAntall() > _antall0,
    _ => false,
  };

  /// The cart's line count, for the `legg` mission (the design compares the
  /// sum; the count is what the app keeps at hand). Tests replace it.
  int Function() kurvAntall = () {
    try {
      return prefGetInt(prefCartCount);
    } catch (_) {
      return 0;
    }
  };
  int _antall0 = 0;

  int _naa() => DateTime.now().millisecondsSinceEpoch;

  @visibleForTesting
  void reset() {
    stopp();
    sesjon = false;
    _sporPos = false;
    hoppet = ferdig = false;
    sett.clear();
    rolig = false;
    kaiSkjult.value = false;
    autoHandler = null;
    butikkId = null;
  }
}
