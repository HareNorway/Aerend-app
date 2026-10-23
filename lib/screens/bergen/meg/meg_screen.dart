import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../networking/feed/feed_repo.dart';
import '../../common/home/bergen/bergen_nav.dart' show BergenTab;
import '../kit/fane_bytte.dart';
import '../../common/homeMainV1/home_main_v1.dart' show HomeMainV1State;
import '../utforsk/utforsk_screen.dart' show UtforskScreen;
import '../poeng/poeng_feil.dart';
import '../poeng/premie_ark.dart';
import '../../../data/aegil/aegil_app_models.dart';
import '../../../data/aegil/aegil_app_repo.dart';
import '../../../data/aegil/aegil_models.dart';
import '../../../data/aegil/aegil_repo.dart';
import '../../../data/points/league_models.dart';
import '../../../data/points/points_app_repo.dart';
import '../../../data/points/points_models.dart';
import '../../../data/points/points_rules.dart';
import '../../common/home/home_repo.dart';
import '../../../utils/shared_pref_utill.dart';
import '../../common/manageAddress/manage_address.dart';
import '../../common/manageCard/manage_card.dart';
import '../../common/manageAddress/add_new_address.dart';
import '../../common/manageAddress/manage_address_dl.dart';
import '../../common/notifications/notifications_dl.dart';
import '../../../utils/utils.dart' show setChangedLanguage, logout;
import '../../common/auth/launch/lf_css.dart';
import '../../common/home/bergen/bergen_kit.dart' show BergenWeatherLook;
import '../aegil/aegil_bits.dart';
import '../aegil/aegil_innst.dart';
import '../aegil/aegil_launch_copy.dart' show AeCopy;
import '../aegil/aegil_screen.dart';
import '../hjem/hjem_harness.dart';
import '../hjem/hjem_hero.dart' show HjemVaer;
import '../kit/bergen_kit.dart';
import 'a3_services.dart';
import 'borte_entry.dart';
import '../../../networking/ops/cus_api.dart';
import '../../../networking/ops/ops_customer_api.dart';
import 'bestillinger_screen.dart' show OhCopy;
import '../sporing/hjelp_sheet.dart';
import 'meg_ark.dart';
import 'meg_bergen.dart';
import 'meg_billett.dart';
import 'meg_copy_a4.dart';
import 'meg_hero.dart';
import 'meg_mark.dart';
import 'meg_nivaa_card.dart';
import 'meg_shine.dart';
import 'min_bio.dart';
import 'min_bio_ark.dart';
import 'min_bio_kort.dart';
import 'meg_sheets.dart';
import '../hjem/hjem_varsler.dart' show varslerLoader;
import 'meg_paaminnelser.dart';
import 'mork_rad.dart';
import '../../../services/customer/client_flags.dart';
import '../ai/ai_bits.dart';
import '../ai/ai_copy.dart';
import '../ai/ai_sheets.dart';
import '../ai/ai_store.dart';
import 'oppdrag_ark.dart';
import 'oppsummering_ark.dart';
import 'tillit_ark.dart';

/// The threshold the design quotes for "Av · kreves over N kr". Ops decides the
/// real one (an Ask of agil-1: policy `proof.value_threshold_ore`).
const int kA4CodeThresholdKr = 300;

/// Meg (design `meg` ≈L5912–6124, agil-4): the hero with Ægil's goal bubble,
/// the header (name · bydel, Premie: gratis levering, Gullbilletten), the Poeng
/// card, the four Meg-rader (Nivå, Bergen-ligaen, Ukens oppdrag, Gullbilletten)
/// and the settings rows (Anledninger … Hjelp og kontakt).
///
/// Data: `points/me`, `points/prizes` (goal), `points/mission`, `points/league`,
/// `points/me/referral`, `points/me/prefs`, `agent/me/settings`,
/// `agent/me/occasions`, `agent/me/shopping-list`, the address and card lists.
class MegScreenBody extends StatefulWidget {
  const MegScreenBody({super.key, this.api, this.aegil, this.aegilRepo});

  final PointsAppApi? api;
  final AegilAppApi? aegil;
  final AegilRepo? aegilRepo;

  @override
  State<MegScreenBody> createState() => _MegScreenBodyState();
}

class _MegScreenBodyState extends State<MegScreenBody> {
  late final PointsAppApi _api = widget.api ?? A3Services.points();
  late final AegilAppApi _aegil = widget.aegil ?? A3Services.aegil();
  late final AegilRepo _aegilRepo = widget.aegilRepo ?? A3Services.aegilRepo();

  PointsBalance? _balance;
  Premiehylla? _shelf;
  League? _league;
  Referral? _referral;
  CustomerPrefs? _prefs;
  AegilSettings? _settings;
  List<AegilLevel> _levels = const [];
  PointsRules? _regler;

  /// Debug harness: the points card opened (`megArk: poeng`).
  bool _poengApen = false;
  List<AddressListItem> _adresser = const [];

  /// Customer Step 5: this month's Tillitsregnskap (`agent/me/trust-ledger`).
  TrustLedger? _tillit;
  List<Occasion> _occasions = const [];
  String? _addressLine;
  String? _paymentLine;
  List<Map<String, dynamic>> _ordrer = const [];
  List<MemoryEntry> _minne = const [];
  // Customer Step 6: the server's bio (null while `cus.bio` is off).
  CusBio? _cusBio;
  // Customer Step 12: Ukens oppdrag (`points/mission`) and the month's summary.
  Mission? _oppdrag;
  MonthlySummary? _oppsummering;
  int _bioPuls = 0;
  bool _loading = true;

  /// Production only (tests inject their own data sources).
  bool get _brukerCache => widget.api == null && widget.aegil == null && widget.aegilRepo == null;

  DateTime _sistLastet = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    // Meg opens with what it showed last (same user) and refreshes quietly;
    // the spinner is only for the very first load.
    final c = _brukerCache ? _MegCache.forUser(prefGetInt(prefUserId)) : null;
    if (c != null) _fra(c);
    BergenFaneBytte.aktiv.addListener(_faneVist);
    _load();
    // Debug: `megScroll` (design px) once the rows have loaded.
    final y = kDebugMode ? HjemHarness.megScroll : null;
    if (y != null) {
      Future<void>.delayed(const Duration(milliseconds: 3500), () {
        if (mounted && _rull.hasClients) _rull.jumpTo(y * MediaQuery.sizeOf(context).width / 390);
      });
    }
  }

  final ScrollController _rull = ScrollController();

  @override
  void dispose() {
    BergenFaneBytte.aktiv.removeListener(_faneVist);
    _rull.dispose();
    super.dispose();
  }

  /// The kept Meg tab shown again: refresh in place after 30 s away.
  void _faneVist() {
    if (BergenFaneBytte.aktiv.value != BergenTab.me.index || _loading) return;
    if (DateTime.now().difference(_sistLastet) < const Duration(seconds: 30)) return;
    _load();
  }

  void _fra(_MegCache c) {
    _balance = c.balance;
    _shelf = c.shelf;
    _league = c.league;
    _referral = c.referral;
    _prefs = c.prefs;
    _settings = c.settings;
    _levels = c.levels;
    _occasions = c.occasions;
    _addressLine = c.addressLine;
    _paymentLine = c.paymentLine;
    _ordrer = c.ordrer;
    _minne = c.minne;
    _regler = c.regler;
    _adresser = c.adresser;
    _loading = false;
  }

  /// «Hent premie» when the goal is reached (`hentMaal`, L19658): the claim
  /// sheet (`krev`) for the goal prize, as on Premiehylla (Gap Step 3).
  /// Without a goal prize on the shelf, Premiehylla.
  Future<void> _hentPremie() async {
    final id = _goal?.prizeId;
    final p = id == null ? null : _shelf?.prizes.where((x) => x.id == id).firstOrNull;
    if (p == null) {
      _go('/bergen/premiehylla');
      return;
    }
    final claimed = await PremieArk.krev(context, p: p, poeng: _balance?.available ?? 0, api: _api, gyldigDager: _regler?.claimExpiryDays);
    if (claimed == true && mounted) _load();
  }

  /// «Nytt fra butikkene»: new posts from the stores you follow (feed
  /// `unread?tab=folger`); 0 or no answer hides the badge.
  int _feedNye = 0;

  /// The row opens Utforsk on Feed › Nær and marks the posts read (design
  /// `tilFeed`, L16922: `utfSeg: 'feed', feedFane: 'naer', feedLest: true`).
  void _tilFeed() {
    unawaited(MegFeed.lest());
    setState(() => _feedNye = 0);
    final shell = HomeMainV1State.current;
    if (shell == null) {
      BergenRoutes.push(context, '/bergen/utforsk', arguments: const {'tab': 'feed'});
      return;
    }
    Navigator.of(context).popUntil((r) => r.isFirst);
    UtforskScreen.apneSegment = UtforskScreen.tabFeed;
    shell.switchToTab(BergenTab.explore.index);
  }

  /// Apart from [_load]: the feed service may be off (Docker), and Meg must
  /// not wait for it.
  Future<void> _lastFeedNye() async {
    final n = await a3Try(MegFeed.nye) ?? 0;
    if (mounted && n != _feedNye) setState(() => _feedNye = n);
  }

  /// One of [_load]'s answers into its field (null = no answer).
  void _sett(int i, Object? v) {
    switch (i) {
      case 0: _balance = v as PointsBalance?;
      case 1: _shelf = v as Premiehylla?;
      case 2: _league = v as League?;
      case 3: _referral = v as Referral?;
      case 4: _prefs = v as CustomerPrefs?;
      case 5:
        final settings = v as ({AegilSettings? settings, List<AegilLevel> levels})?;
        _settings = settings?.settings;
        _levels = settings?.levels ?? const [];
      case 6: _occasions = (v as List<Occasion>?) ?? const [];
      case 7: _addressLine = v as String?;
      case 8: _paymentLine = v as String?;
      case 9: _ordrer = (v as List<Map<String, dynamic>>?) ?? const [];
      case 10: _minne = (v as List<MemoryEntry>?) ?? const [];
      case 11: _regler = v as PointsRules?;
      case 12: _adresser = (v as List<AddressListItem>?) ?? const [];
      case 13: _tillit = v as TrustLedger?;
      case 14: _cusBio = v as CusBio?;
      case 15: _oppdrag = v as Mission?;
      case 16: _oppsummering = v as MonthlySummary?;
    }
  }

  Future<void> _load() async {
    _sistLastet = DateTime.now();
    unawaited(_lastFeedNye());
    final kall = <Future<Object?>>[
      a3Try(_api.balance),
      a3Try(_api.shelf),
      a3Try(_api.league),
      a3Try(_api.referral),
      a3Try(_api.prefs),
      a3Try(_aegilRepo.fetchSettings),
      a3Try(_aegil.occasions),
      a3Try(A3Services.addressLine),
      a3Try(A3Services.paymentLine),
      a3Try(() => OpsCustomerApi().orders(limit: 50)),
      a3Try(_aegilRepo.fetchMemory),
      a3Try(A3Services.rules),
      a3Try(A3Services.addressList),
      // Customer Step 5: Tillitsregnskap.
      a3Try(_aegil.trustLedger),
      // Customer Step 6: Min bio on the server.
      a3Try(CusApi().bio),
      // Customer Step 12: Ukens oppdrag and the month's summary.
      a3Try(_api.mission),
      a3Try(_aegil.monthlySummary),
    ];
    // Each section fills in as its answer arrives: the slowest call no longer
    // holds the whole sheet behind one spinner (only until the first answer).
    for (var i = 0; i < kall.length; i++) {
      unawaited(kall[i].then((v) {
        if (!mounted || v == null) return;
        setState(() {
          _sett(i, v);
          _loading = false;
        });
      }));
    }
    final r = await Future.wait<Object?>(kall);
    if (!mounted) return;
    setState(() {
      for (var i = 0; i < r.length; i++) {
        _sett(i, r[i]);
      }
      if (MegApne.poeng) {
        MegApne.poeng = false;
        _poengApen = true;
      }
      // Customer Step 12 harness: the mission row in a given state.
      if (kDebugMode && HjemHarness.megOppdrag != null) _oppdrag = harnessOppdrag(HjemHarness.megOppdrag!);
      _loading = false;
    });
    // Customer Step 14: the linked assistants for the rows; the harness opens a sheet (`ai`).
    unawaited(AiStore.instance.load());
    if (kDebugMode && HjemHarness.ai != null && !HjemHarness.ai!.startsWith('kurv')) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (mounted) unawaited(AiArk.harness(context));
    }
    if (_brukerCache) {
      _MegCache.lagre(_MegCache(
        userId: prefGetInt(prefUserId), balance: _balance, shelf: _shelf, league: _league, referral: _referral,
        prefs: _prefs, settings: _settings, levels: _levels, occasions: _occasions, addressLine: _addressLine,
        paymentLine: _paymentLine, ordrer: _ordrer, minne: _minne, regler: _regler, adresser: _adresser,
      ));
    }
    // Debug: `megArk` opens one of Meg's Ark sheets (parity Step 9, row 43).
    final ark = kDebugMode ? HjemHarness.megArk : null;
    if (ark != null) {
      HjemHarness.megArk = null;
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      final b = _balance;
      switch (ark) {
        case 'billett': _openBillett();
        case 'nivaa': _openNivaa();
        case 'slik': if (b != null) MegSheets.slikPoeng(context, b, regler: _regler);
        case 'vilkaar': MegSheets.vilkaar(context);
        case 'nivaa4': MegSheets.nivaa4(context);
        case 'adresser': _openAdresser();
        case 'betaling': _openBetaling();
        case 'sprak': _openSpraak();
        case 'kode': _toggleKode();
        case 'liga': _ligaNavn();
        case 'varsler': _varsler();
        case 'anledninger': _anledninger();
        case 'ukeshandel': _ukeshandel(steg: HjemHarness.ukeSteg, auto: HjemHarness.ukeAuto);
        case 'paaminnelser': visPaaminnelser(context, repo: _aegilRepo);
        // Customer Step 5: Tillitsregnskap.
        case 'tillit': TillitArk.vis(context, _tillit ?? const TrustLedger(month: ''));
        case 'bio':
          // Customer Step 6 harness: the consent ticked, or «Er du sikker?» open.
          MinBioHarness.samtykke = HjemHarness.bioSamtykke;
          MinBioHarness.slett = HjemHarness.bioSlett;
          MinBioHarness.scroll = HjemHarness.bioScroll;
          _openBio();
        case 'aegilInnst': _aegilInnstillinger();
        case 'gbDelt': _feirDelt();
        case 'krev': _hentPremie();
        case 'nytt': _tilFeed();
        case 'poeng': setState(() => _poengApen = true);
        // Customer Step 12: the mission sheet and the month's summary.
        case 'oppdrag': setState(() => _poengApen = true); _visOppdrag();
        case 'oppsummering': setState(() => _poengApen = true); _visOppsummering();
        case 'bioLagre': _openBio(autoLagre: const Duration(milliseconds: 1500));
      }
    }
  }

  // --- Customer Step 12: Ukens oppdrag (accept / decline from the row), the month's summary ---

  /// `megOppdrag`: `ny` (Godta / Ikke dette), `tatt` (0 av 1), `ferdig`
  /// (+50 poeng) or `nei` (no row) — the design's `oppdrag` states.
  static Mission? harnessOppdrag(String s) => switch (s) {
    'ny' => const Mission(id: 0, title: 'Prøv Nordnes Fisk', body: 'Én bestilling teller.', points: 50),
    'tatt' => const Mission(id: 0, title: 'Prøv Nordnes Fisk', body: 'Én bestilling teller.', points: 50, accepted: true),
    'ferdig' => const Mission(id: 0, title: 'Prøv Nordnes Fisk', body: 'Én bestilling teller.', points: 50, state: 'completed', progress: 1, accepted: true),
    _ => null,
  };

  bool get _harOppdrag => _oppdrag != null && _oppdrag!.state != 'declined' && _oppdrag!.state != 'expired';

  Future<void> _visOppdrag() async {
    final m = _oppdrag;
    if (m == null) return;
    final svar = await OppdragArk.vis(context, m);
    if (!mounted) return;
    switch (svar) {
      case 'godta': await _godtaOppdrag();
      case 'nei': await _neiOppdrag();
    }
  }

  /// `oppdragGodta`: «Oppdraget er ditt · …».
  Future<void> _godtaOppdrag() async {
    if (_oppdrag == null) return;
    final r = await _api.acceptMission();
    if (!mounted) return;
    final m = r.mission;
    if (m == null) {
      showBergenToast(context, CusPoengFeil.tekst(r.error, ellers: A4MegCopy.cus_meg_oppdrag_feil), icon: Icons.error_outline_rounded);
      return;
    }
    setState(() => _oppdrag = m);
    showBergenToast(context, A4MegCopy.a4_meg_oppdrag_ditt(m.title), icon: Icons.flag_rounded);
  }

  /// `oppdragNei`: «Greit · nytt oppdrag neste uke» (or the replacement's
  /// title); a second decline the same week is `MISSION_DECLINE_LIMIT`.
  Future<void> _neiOppdrag() async {
    if (_oppdrag == null) return;
    final r = await _api.declineMission();
    if (!mounted) return;
    if (r.error != null) {
      showBergenToast(context, CusPoengFeil.tekst(r.error, ellers: A4MegCopy.cus_meg_oppdrag_feil), icon: Icons.error_outline_rounded);
      return;
    }
    setState(() => _oppdrag = r.replacement);
    showBergenToast(context, r.replacement == null ? A4MegCopy.a4_meg_oppdrag_nei : A4MegCopy.cus_meg_oppdrag_nytt_toast(r.replacement!.title));
  }

  void _visOppsummering() {
    final s = _oppsummering;
    if (s == null) return;
    OppsummeringArk.vis(context, s: s, balance: _balance, league: _league, mission: _oppdrag);
  }

  MinBio get _bio => minBioVelg(_cusBio, _minne, _settings);

  /// Min Bio (Bergen Step 6): the sheet saves; Meg reloads what Ægil knows
  /// and the card glows once (`bioKortPuls`).
  Future<void> _openBio({Duration? autoLagre}) async {
    final n = await visMinBio(context, repo: _aegilRepo, bio: _bio, minne: _minne, autoLagre: autoLagre);
    if (n == null || !mounted) return;
    final r = await Future.wait<Object?>([a3Try(_aegilRepo.fetchMemory), a3Try(_aegilRepo.fetchSettings), a3Try(CusApi().bio)]);
    if (!mounted) return;
    final settings = r[1] as ({AegilSettings? settings, List<AegilLevel> levels})?;
    setState(() {
      _minne = (r[0] as List<MemoryEntry>?) ?? _minne;
      _settings = settings?.settings ?? _settings;
      _cusBio = r[2] as CusBio? ?? _cusBio;
      _bioPuls++;
    });
  }

  void _go(String route, {Object? arguments}) => Navigator.of(context).pushNamed(route, arguments: arguments);

  void _push(Widget w) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => w));

  String get _firstName => a3Pref(prefUserName).trim().split(' ').firstOrNull ?? '';

  PointGoal? get _goal => _shelf?.goal;

  String get _bubble {
    final g = _goal;
    if (g == null) return A4MegCopy.a4_meg_boble_ingen;
    return g.reached ? A4MegCopy.a4_meg_boble_klar(g.label) : A4MegCopy.a4_meg_boble_til(g.remaining, g.label);
  }


  /// The tier gift waiting to be used, for «Premie: …».

  String get _code => _referral?.code ?? a3Pref(prefReferralCode);

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: _code));
    if (mounted) showBergenToast(context, A4MegCopy.a4_meg_kopiert(_code), icon: Icons.copy_rounded);
  }

  Future<void> _openBillett() async {
    final r = _referral ?? Referral(code: _code);
    await MegSheets.billett(context, referral: r, onCopy: _copyCode, onShare: _share);
  }

  Future<void> _openNivaa() async {
    final b = _balance;
    if (b == null) return;
    await MegSheets.nivaa(context, b, opens: _shelf?.previews ?? const [], onOpenPremiehylla: () => _go('/bergen/premiehylla'));
  }

  Future<void> _openAdresser() async {
    final list = await a3Try(A3Services.addressList) ?? const <AddressListItem>[];
    if (!mounted) return;
    final id = prefGetInt(prefNewDeliveryAddressId);
    final valgtId = list.any((a) => a.addressId == id) ? id : (list.isEmpty ? 0 : list.first.addressId);
    String rens(String s) => s.trim().toUpperCase() == 'N/A' ? '' : s.trim();
    final rader = [
      for (final a in list)
        () {
          final deler = a.address.split(',').map(rens).where((d) => d.isNotEmpty).toList();
          final gate = deler.isEmpty ? a.address : deler.first;
          final merknad = rens(a.landmark);
          final detaljer = [
            if (rens(a.flatNo).isNotEmpty) rens(a.flatNo),
            if (merknad.isNotEmpty && !a.address.toLowerCase().startsWith(merknad.toLowerCase())) merknad,
          ].join(' · ');
          return MegAdresse(gate: gate, detaljer: detaljer, type: switch (a.type) { 'home' => 'Hjem', 'work' => 'Jobb', _ => 'Annen' }, valgt: a.addressId == valgtId);
        }(),
    ];
    await MegSheets.adresser(context, addresses: rader, onManage: () => _push(const ManageAddress()), onAdd: () => _push(const AddNewAddress()));
  }

  Future<void> _openBetaling() async {
    final list = await a3Try(A3Services.cards) ?? const <String>[];
    if (!mounted) return;
    await MegSheets.betaling(context, cards: list, onManage: () => _push(const ManageCard()), vippsNr: a3Pref(prefContactNumber));
  }

  Future<void> _openSpraak() async {
    final code = await MegSheets.spraak(context, current: _safeLanguage());
    if (code == null || !mounted || code == _safeLanguage()) return;
    setChangedLanguage(
      context,
      code,
      this,
      nextAction: () {
        if (mounted) setState(() {});
      },
    );
  }

  Future<void> _share() async {
    final code = _code;
    final text = A4MegCopy.a4_meg_del_tekst(_referral?.pointsForThem ?? 200, code, _referral?.link);
    try {
      final r = await Share.share(text, subject: A4MegCopy.a4_meg_gullbilletten);
      // New Bergen: «Gullbillett delt» once the share went out.
      if (r.status == ShareResultStatus.success && mounted) _feirDelt();
      return;
    } catch (_) {}
    await Clipboard.setData(ClipboardData(text: _referral?.link ?? code));
    if (mounted) showBergenToast(context, A4MegCopy.a4_meg_kopiert(code), icon: Icons.copy_rounded);
  }

  /// «Gullbillett delt» (L9963–10017); «Del med flere» shares again.
  void _feirDelt() {
    visGullbillettDelt(
      context,
      kode: _code,
      initial: _firstName.isEmpty ? 'D' : _firstName.substring(0, 1).toUpperCase(),
      poeng: _referral?.pointsForMe ?? 200,
      onIgjen: _share,
    );
  }

  /// «+47 400 12 345» for «Logget inn som …» (the saved phone, else the email).
  String get _kontakt {
    final tlf = a3Pref(prefContactNumber).trim();
    if (tlf.isNotEmpty) {
      final d = tlf.replaceAll(RegExp(r'\D'), '');
      final n = d.length > 8 ? d.substring(d.length - 8) : d;
      return n.length == 8 ? '+47 ${n.substring(0, 3)} ${n.substring(3, 5)} ${n.substring(5)}' : tlf;
    }
    return a3Pref(prefEmail).trim();
  }

  /// «Logg ut» (L7630–7648): the app's own logout, as Konto does it.
  Future<void> _loggUt() async {
    try {
      await HomeRepo().callLogoutApi();
    } catch (_) {}
    if (!mounted) return;
    logout(context);
  }

  /// «Hjem · Nygårdsgaten 5 · 2 steder» (`kMegRader` Adresser): the delivery
  /// address's kind, its street and how many places are saved.
  (String, String)? get _adresseRad {
    final list = _adresser;
    if (list.isEmpty) return null;
    final id = prefGetInt(prefNewDeliveryAddressId);
    final a = list.firstWhere((x) => x.addressId == id, orElse: () => list.first);
    String rens(String s) => s.trim().toUpperCase() == 'N/A' ? '' : s.trim();
    final deler = a.address.split(',').map(rens).where((d) => d.isNotEmpty).toList();
    final type = switch (a.type) { 'home' => 'Hjem', 'work' => 'Jobb', _ => 'Annen' };
    return (type, '$type · ${deler.isEmpty ? a.address : deler.first} · ${A4MegCopy.a4_meg_steder(list.length)}');
  }

  /// «Husk døra mi»: may the courier save a door note for next time
  /// (`door_profile_consent`, backend plan Step 6)? Off until the customer
  /// says yes; a failed save leaves the row as it was.
  Future<void> _toggleDora() async {
    final next = !(_prefs?.doorProfileConsent ?? false);
    final p = await _api.updatePrefs(doorProfileConsent: next);
    if (!mounted) return;
    if (p == null) {
      showBergenToast(context, A4MegCopy.a4_meg_lagret_feil, icon: Icons.error_outline_rounded);
      return;
    }
    setState(() => _prefs = p);
    // Customer Step 2: the door profiles the courier reads (every saved
    // address, from its door note; withdrawn = removed).
    final skrevet = await CusApi().dorProfil(samtykke: p.doorProfileConsent);
    if (!mounted) return;
    if (!skrevet) {
      showBergenToast(context, A4MegCopy.a4_meg_lagret_feil, icon: Icons.error_outline_rounded);
      return;
    }
    showBergenToast(context, p.doorProfileConsent ? A4MegCopy.a4_meg_dora_lagret_paa : A4MegCopy.a4_meg_dora_lagret_av, icon: Icons.door_front_door_outlined);
  }

  Future<void> _toggleKode() async {
    final on = _prefs?.alwaysCode ?? false;
    final next = await MegSheets.kodeInnst(context, on: on);
    if (next == null || !mounted) return;
    final p = await _api.updatePrefs(alwaysCode: next);
    if (!mounted) return;
    setState(() => _prefs = p ?? _prefs);
    showBergenToast(context, next ? A4MegCopy.a4_meg_kode_alltid : A4MegCopy.a4_meg_kode_bare(kA4CodeThresholdKr), icon: Icons.lock_rounded);
  }

  Future<void> _ligaNavn() async {
    final l = _league;
    if (l == null) return;
    final updated = await MegSheets.ligaNavn(context, api: _api, league: l, firstName: _firstName, bydel: l.bydel ?? A4MegCopy.a4_meg_bydel);
    if (!mounted) return;
    if (updated != null) {
      setState(() => _league = updated);
      showBergenToast(context, A4MegCopy.a4_meg_lagret, icon: Icons.check_rounded);
    }
  }

  Future<void> _varsler() async {
    final items = await a3Try(varslerLoader) ?? const <MassNotificationItem>[];
    if (!mounted) return;
    await MegSheets.varsler(context, items: items, seenAt: _prefs?.notificationsSeenAt, onOrdre: () => _go('/bergen/meg/bestillinger'));
    final p = await _api.updatePrefs(markNotificationsSeen: true);
    if (mounted) setState(() => _prefs = p ?? _prefs);
  }

  Future<void> _anledninger() async {
    final list = await MegSheets.anledninger(context, api: _aegil, initial: _occasions);
    if (list != null && mounted) setState(() => _occasions = list);
  }

  /// Customer Step 8: the Ark reads `agent/me/weekly` (the list, the dinner
  /// plan and the week's basket in one); off the flag it falls back to the
  /// plain list from `me/shopping-list`.
  Future<void> _ukeshandel({String? steg, String? auto}) async {
    final view = await a3Try(_aegil.weekly) ?? WeeklyView(items: await a3Try(_aegil.shoppingList) ?? const []);
    if (!mounted) return;
    await MegSheets.ukeshandel(
      context,
      api: _aegil,
      view: view,
      level: _settings?.level ?? 2,
      steg: steg ?? 'liste',
      auto: auto,
      onOpenAegilSettings: _aegilInnstillinger,
      onKurv: () => _go('/bergen/kurv'),
    );
  }

  /// «Innstillinger for Ægil» (new Bergen `aegilInnst`, L20363–20393): the
  /// dark Ark with the same list as the Ægil screen, «Hva Ægil vet» (→ Det
  /// Ægil vet om deg) and «Ferdig».
  Future<void> _aegilInnstillinger() async {
    var s = _settings;
    if (s == null) {
      final r = await a3Try(_aegilRepo.fetchSettings);
      if (!mounted) return;
      s = r?.settings;
      if (r != null) _levels = r.levels;
    }
    if (s == null) {
      _go('/bergen/aegil');
      return;
    }
    var naa = s;
    if (!mounted) return;
    await showMegArk<void>(
      context,
      key: const Key('meg-ark-aegil-innst'),
      mork: true,
      tastatur: true,
      title: AeInnstCopy.tittel,
      subtitle: AeInnstCopy.linjeMeg,
      body: (ctx, setArk) {
        Future<void> endre(Map<String, dynamic> endring, {String? toast}) async {
          final r = await a3Try(() => _aegilRepo.updateSettings(endring));
          if (!mounted) return;
          if (r?.settings != null) {
            naa = r!.settings!;
            setArk(() {});
            setState(() => _settings = naa);
            if (toast != null) showBergenToast(context, toast);
          } else if (r?.error == 'LEVEL_ABOVE_MAX') {
            // The cap moved since the list was drawn: say so and redraw with it.
            showBergenToast(context, AeInnstCopy.cus_aegil_nivaa_over_grense, icon: Icons.error_outline_rounded);
            final f = await a3Try(_aegilRepo.fetchSettings);
            if (!mounted || f?.settings == null) return;
            naa = f!.settings!;
            setArk(() {});
            setState(() => _settings = naa);
          } else {
            showBergenToast(context, r?.error == 'LEVEL_REQUIRES_RECURRING' ? AeInnstCopy.snartToast : A4MegCopy.a4_meg_lagret_feil, icon: Icons.error_outline_rounded);
          }
        }

        return AegilInnstListe(
          settings: naa,
          levels: _levels,
          onEndre: endre,
          onButikker: () async {
            if (naa.allowedStoreMode == 'allowlist') return endre({'allowed_store_mode': 'all', 'allowed_store_ids': <int>[]});
            final fav = await a3Try(() => OpsCustomerApi().favourites());
            final ids = [
              for (final f in ((fav?['favourites'] ?? fav?['stores'] ?? const []) as List).whereType<Map>()) (f['store_id'] ?? f['id']) as num?,
            ].whereType<num>().map((e) => e.toInt()).toList();
            if (!mounted) return;
            if (ids.isEmpty) return showBergenToast(context, AeCopy.ingenFavoritter);
            await endre({'allowed_store_mode': 'allowlist', 'allowed_store_ids': ids});
          },
        );
      },
      secondary: MegArkButton(
        key: const Key('meg-ark-aegil-hva-vet'),
        label: AeInnstCopy.hvaVet,
        onTap: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AegilScreen(steg: 'minne')));
        },
      ),
      primary: MegArkButton(
        key: const Key('meg-ark-aegil-ferdig'),
        label: AeInnstCopy.ferdig,
        onTap: () {
          Navigator.of(context).pop();
          showBergenToast(context, AeInnstCopy.lagretMeg(aeVisNivaa(naa)));
        },
      ),
    );
  }

  // ── Launch layout (`erMeg`, L7339–7500, design px) ─────────────────────────

  /// `megBobleTx`: the goal first, then Ægil's tips, one per tap on him.
  List<String> get _tips => [_bubble, A4MegCopy.a4_meg_tips_hylla, A4MegCopy.a4_meg_tips_nivaa, A4MegCopy.a4_meg_tips_verv, A4MegCopy.a4_meg_tips_trykk];

  int _aegN = 0;

  BergenWeatherLook get _look {
    if (kDebugMode && HjemHarness.vaer != null) {
      return switch (HjemHarness.vaer!) {
        HjemVaer.regn => BergenWeatherLook.regn,
        HjemVaer.sol => BergenWeatherLook.sol,
        HjemVaer.solnedgang => BergenWeatherLook.solnedgang,
        HjemVaer.natt => BergenWeatherLook.natt,
      };
    }
    return BergenWeatherLook.forHour(DateTime.now().hour);
  }

  @override
  Widget build(BuildContext context) {
    final b = _balance;
    final ref = _referral;
    final l = _league;
    final borte = mensDuVarBorteCard(context);
    final give = ref?.pointsForThem ?? 200;
    final get = ref?.pointsForMe ?? 200;
    final code = ref?.code ?? a3Pref(prefReferralCode);
    final lang = A4MegCopy.a4_meg_spraak_navn[_safeLanguage()] ?? 'Norsk bokmål';

    return ValueListenableBuilder<bool>(
      valueListenable: A3Services.reducedMotion,
      builder: (context, reduced, _) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduced || MediaQuery.of(context).disableAnimations),
        child: Scaffold(
          backgroundColor: const Color(0xFF173E48),
          body: LfFrame(
            child: Stack(
              children: [
                const Positioned.fill(
                  child: CssBox(
                    bg: [
                      CssRadial([Color.fromRGBO(255, 255, 255, .22), Color.fromRGBO(255, 255, 255, 0)], stops: [0, .6], rx: .8, ry: .5, cx: .14, cy: 0),
                      CssLinear(180, [Color(0xFF2A6272), Color(0xFF1E4F5C), Color(0xFF173E48)], [0, .42, 1]),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  width: 390,
                  height: 196,
                  child: MegHero(look: _look, bubble: _tips[_aegN % _tips.length], n: _aegN, onAegil: () => setState(() => _aegN++)),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 200,
                  bottom: 0,
                  child: CssBox(
                    radius: const BorderRadius.vertical(top: Radius.circular(28)),
                    clip: true,
                    bg: const [
                      CssLinear(180, [Color(0xFF22586A), Color(0xFF1B4854)]),
                    ],
                    shadows: const [
                      CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .28)),
                      CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .14)),
                      CssShadow(0, -12, 18, -10, Color.fromRGBO(4, 18, 26, .6)),
                      CssShadow(0, -34, 52, -26, Color.fromRGBO(4, 18, 26, .7)),
                    ],
                    child: _loading
                        ? const Center(child: CircularProgressIndicator(color: BergenTokens.mint))
                        : ListView(
                            controller: _rull,
                            key: const Key('meg-list'),
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 130),
                            children: [
                              // --- Header (new Bergen L7432–7457) --------------------------
                              Padding(
                                padding: const EdgeInsets.fromLTRB(2, 2, 2, 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: () => _go('/bergen/meg/konto'),
                                      child: Text(
                                        _firstName.isEmpty ? 'Meg' : A4MegCopy.a4_meg_fra(_firstName, A4MegCopy.a4_meg_bydel),
                                        key: const Key('meg-title'),
                                        style: jakarta(24, em: -.03, height: 1.05),
                                      ),
                                    ),
                                    const SizedBox(height: 7),
                                    Text(
                                      '${A4MegCopy.a4_meg_bydel} · ${A4MegCopy.a4_meg_region}',
                                      style: inter(11, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .66)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              // --- Gullbilletten (L7439) --------------------------------
                              MegGullBillett(kode: code, linje: A4MegCopy.a4_meg_gi_faa(give, get), onTap: _openBillett, onStubb: _share),
                              // --- Min Bio (L7458) --------------------------------------
                              const SizedBox(height: 14),
                              MinBioKort(bio: _bio, puls: _bioPuls, onTap: _openBio),
                              if (borte != null) ...[const SizedBox(height: 12), borte],
                              // --- Poeng, nivå og konkurranser (L7480) -------------------
                              if (b != null) ...[
                                const SizedBox(height: 14),
                                MegPoengKort(
                                  key: ValueKey('poeng-$_poengApen'),
                                  apen: _poengApen,
                                  poeng: b.available,
                                  tierName: b.tierName,
                                  pct: b.tierProgress,
                                  avstand: b.nextTierName == null || b.pointsToNextTier == null ? A4MegCopy.a4_meg_hoyeste : A4MegCopy.a4_meg_avstand(b.pointsToNextTier!, b.nextTierName!),
                                  ligaPlass: l?.optedIn == true ? l?.own?.rank : null,
                                  innhold: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      MegNivaaCard(
                                        balance: b,
                                        goal: _goal,
                                        onOpenPremiehylla: () => _go('/bergen/premiehylla'),
                                        onOpenNivaa: _openNivaa,
                                        onOpenSlik: () => MegSheets.slikPoeng(context, b, regler: _regler),
                                        onHentPremie: _hentPremie,
                                      ),
                                      const SizedBox(height: 12),
                                      _Gruppe(
                                        key: const Key('meg-rader'),
                                        children: [
                                          _Rad(
                                            key: const Key('meg-rad-nivaa'),
                                            sterk: true,
                                            tile: MegMedal(name: b.tierName, size: 36, animate: false),
                                            navn: '${A4MegCopy.a4_meg_rad_nivaa} · ${b.tierName}',
                                            under: A4MegCopy.a4_meg_nivaa_note,
                                            merke: b.nextTierName == null || b.pointsToNextTier == null ? A4MegCopy.a4_meg_hoyeste : A4MegCopy.a4_meg_avstand(b.pointsToNextTier!, b.nextTierName!),
                                            onTap: _openNivaa,
                                          ),
                                          _Rad(
                                            key: const Key('meg-rad-liga'),
                                            sterk: true,
                                            tile: const _LigaTile(),
                                            navn: A4MegCopy.a4_meg_rad_liga,
                                            under: l?.optedIn == true ? A4MegCopy.a4_meg_liga_med : A4MegCopy.a4_meg_liga_ute,
                                            merke: l?.optedIn == true && l?.own != null ? A4MegCopy.a4_meg_plass(l!.own!.rank) : null,
                                            knapp: l?.optedIn == true ? null : A4MegCopy.a4_meg_bli_med,
                                            onKnapp: () => _go('/bergen/liga'),
                                            onTap: () => _go('/bergen/liga'),
                                          ),
                                          // Customer Step 12: Ukens oppdrag — «Godta» on a new mission («Ikke dette»
                                          // in its sheet), «0 av 1» once taken, «+50 poeng» when done; no row without one.
                                          if (_harOppdrag)
                                            _Rad(
                                              key: const Key('cus-meg-rad-oppdrag'),
                                              sterk: true,
                                              tile: const _GlassTile(rot: -4, d: MorkIk.flagg),
                                              navn: A4MegCopy.cus_meg_oppdrag_rad,
                                              under: A4MegCopy.cus_meg_oppdrag_under(_oppdrag!.title, _oppdrag!.points),
                                              merke: OppdragArk.ny(_oppdrag!)
                                                  ? null
                                                  : (_oppdrag!.state == 'completed' ? A4MegCopy.a4_meg_pluss(_oppdrag!.points) : A4MegCopy.a4_meg_oppdrag_status(_oppdrag!.progress, _oppdrag!.target)),
                                              knapp: OppdragArk.ny(_oppdrag!) ? A4MegCopy.a4_meg_godta : null,
                                              knappKey: const Key('cus-meg-oppdrag-godta-rad'),
                                              onKnapp: _godtaOppdrag,
                                              onTap: _visOppdrag,
                                            ),
                                          _Rad(
                                            key: const Key('meg-rad-gullbillett'),
                                            sterk: true,
                                            tile: const _TicketStub(width: 46, height: 34, radius: 9, animate: true),
                                            navn: A4MegCopy.a4_meg_gullbilletten,
                                            under: A4MegCopy.a4_meg_gi_faa_kode(give, get, code),
                                            del: true,
                                            onKnapp: _openBillett,
                                            onTap: _openBillett,
                                          ),
                                          // Customer Step 12: the month's summary (Points spec §8) — hidden without data.
                                          if (_oppsummering != null && !_oppsummering!.tom)
                                            _Rad(
                                              key: const Key('cus-meg-rad-oppsummering'),
                                              sterk: true,
                                              tile: const _GlassTile(rot: 3, d: MorkIk.hist),
                                              navn: OppsummeringArk.tittel(_oppsummering!),
                                              under: A4MegCopy.cus_meg_oppsummering_under(_oppsummering!.earned, _oppsummering!.spent, _oppsummering!.savedKr),
                                              onTap: _visOppsummering,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              // --- kMegRader (L7604–7627) --------------------------------
                              const SizedBox(height: 12),
                              _Gruppe(
                                key: const Key('meg-innstillinger-rader'),
                                children: [
                                  _Rad(
                                    key: const Key('meg-rad-ordrer'),
                                    tile: const _GlassTile(rot: 3, d: 'M6 3h12v18l-3-2-3 2-3-2-3 2zM9 8h6M9 12h6M9 16h4'),
                                    navn: A4MegCopy.a4_meg_ordrer,
                                    under: _ordrer.isEmpty ? A4MegCopy.a4_meg_ordrer_tom : A4MegCopy.a4_meg_ordrer_sub(_ordrer.length, OhCopy.dag(DateTime.tryParse('${_ordrer.first['ordered_at'] ?? ''}')?.toLocal() ?? DateTime.now())),
                                    onTap: () => _go('/bergen/meg/bestillinger'),
                                  ),
                                  // Customer Step 14: «Bestill via AI-assistent» and «Koblede assistenter» (design 20324–20325).
                                  if (ClientFlags.on(ClientFlags.aiLinking) || AiStore.instance.harness)
                                    _Rad(
                                      key: const Key('cus-meg-rad-ai'),
                                      tile: const _GlassTile(rot: -3, d: AiIk.kobling),
                                      navn: AiCopy.cus_ai_meg_rad,
                                      under: AiCopy.cus_ai_meg_rad_sub,
                                      onTap: () => AiArk.flyt(context, 'inngang'),
                                    ),
                                  if (ClientFlags.on(ClientFlags.aiLinking) || AiStore.instance.harness)
                                    ListenableBuilder(
                                      listenable: AiStore.instance,
                                      builder: (_, __) => _Rad(
                                        key: const Key('cus-meg-rad-ai-koblede'),
                                        tile: const _GlassTile(rot: 3, d: AiIk.person),
                                        navn: AiCopy.cus_ai_meg_koblede,
                                        under: AiCopy.cus_ai_meg_koblede_sub(AiStore.instance.aktive.length),
                                        merke: AiStore.instance.aktive.isEmpty ? null : '${AiStore.instance.aktive.length}',
                                        merkePille: true,
                                        onTap: () => AiArk.flyt(context, 'koblede'),
                                      ),
                                    ),
                                  // Customer Step 5: «Ægil sparte deg N kr» → Tillitsregnskap (kMegRader[0]).
                                  _Rad(
                                    key: const Key('cus-meg-rad-tillit'),
                                    tile: const _GlassTile(rot: -4, d: 'M4 19V10M10 19V5M16 19v-7M21 19H3'),
                                    navn: A4MegCopy.a4_meg_sparte(_tillit?.savedKr ?? 0),
                                    under: A4MegCopy.a4_meg_tillit_sub(_tillit?.againstInterestShown ?? 0),
                                    onTap: () => TillitArk.vis(context, _tillit ?? const TrustLedger(month: '')),
                                  ),
                                  _Rad(
                                    key: const Key('meg-rad-aegil'),
                                    tile: const _GlassTile(rot: -3, d: 'M4 6h9M17 6h3M15 4v4M4 12h3M11 12h9M9 10v4M4 18h11M19 18h1M17 16v4'),
                                    navn: AeInnstCopy.tittel,
                                    under: '${AeInnstCopy.nivaa(aeVisNivaa(_settings ?? const AegilSettings()))} · ${aeNivaaNavn(_settings ?? const AegilSettings(), _levels)}',
                                    merke: AeInnstCopy.endreMerke,
                                    onTap: _aegilInnstillinger,
                                  ),
                                  _Rad(
                                    key: const Key('meg-rad-adresser'),
                                    tile: const _GlassTile(rot: -2, d: 'M12 21s7-6 7-12a7 7 0 1 0-14 0c0 6 7 12 7 12zM12 11a2 2 0 1 0 0-4 2 2 0 0 0 0 4'),
                                    navn: A4MegCopy.a4_meg_adresser,
                                    under: _adresseRad?.$2 ?? (_addressLine == null ? A4MegCopy.a4_meg_adresser_tom : '$_addressLine · ${A4MegCopy.a4_meg_adresser_bare}'),
                                    merke: _adresseRad?.$1,
                                    onTap: _openAdresser,
                                  ),
                                  _Rad(
                                    key: const Key('meg-rad-varsler'),
                                    tile: const _GlassTile(rot: -4, d: 'M12 4a5 5 0 0 1 5 5v4l2 3H5l2-3V9a5 5 0 0 1 5-5zM10 19h4'),
                                    navn: A4MegCopy.a4_meg_varsler,
                                    under: A4MegCopy.a4_meg_varsler_sub,
                                    merke: (_prefs?.notificationsUnseen ?? 0) > 0 ? '${_prefs!.notificationsUnseen}' : null,
                                    onTap: _varsler,
                                  ),
                                  _Rad(
                                    key: const Key('meg-rad-navn-liga'),
                                    tile: const _GlassTile(rot: 2, d: 'M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM4.5 20.5c1.3-4 4-6 7.5-6s6.2 2 7.5 6'),
                                    navn: A4MegCopy.a4_meg_navn_liga,
                                    under: l?.optedIn == true ? '${l!.displayName ?? _firstName} · ${_synLabel(l.visibility)}' : A4MegCopy.a4_meg_navn_liga_ute,
                                    merke: l?.optedIn == true ? null : A4MegCopy.a4_meg_velg_navn,
                                    onTap: _ligaNavn,
                                  ),
                                  _Rad(
                                    key: const Key('meg-rad-spraak'),
                                    tile: const _GlassTile(rot: -3, d: 'M12 3a9 9 0 1 0 9 9 9 9 0 0 0-9-9zM3.5 9h17M3.5 15h17'),
                                    navn: A4MegCopy.a4_meg_spraak,
                                    under: lang,
                                    onTap: _openSpraak,
                                  ),
                                  _Rad(
                                    key: const Key('meg-rad-favoritter'),
                                    tile: const _FargeTile(rot: -5, farger: [Color(0xFFFBD3BE), Color(0xFFF58A55)], d: 'M12 20.4l-7.2-7.2a4.9 4.9 0 1 1 7-7l.2.3.2-.3a4.9 4.9 0 1 1 7 7z', fyll: true),
                                    navn: A4MegCopy.a4_meg_favoritter,
                                    merke: '${_prefs?.favourites ?? 0}',
                                    merkeDempet: true,
                                    onTap: () => _go('/bergen/meg/favoritter'),
                                  ),
                                  _Rad(
                                    key: const Key('meg-rad-nytt'),
                                    tile: const _FargeTile(
                                      rot: -3,
                                      farger: [Color(0xFFFBE3AE), Color(0xFFE0A32C)],
                                      d: 'M7 4h10a3 3 0 0 1 3 3v10a3 3 0 0 1-3 3H7a3 3 0 0 1-3-3V7a3 3 0 0 1 3-3zM8 9h8M8 13h5',
                                    ),
                                    navn: A4MegCopy.a4_meg_nytt,
                                    merke: _feedNye > 0 ? '$_feedNye' : null,
                                    merkePille: true,
                                    onTap: _tilFeed,
                                  ),
                                  _Rad(
                                    key: const Key('meg-rad-hjelp'),
                                    tile: const _FargeTile(rot: 4, farger: [Color(0xFFDDE6EA), Color(0xFF8C9EA6)], d: 'M12 3a9 9 0 1 0 .01 0zM9.6 9.4a2.5 2.5 0 1 1 3.4 2.4V14M12 17.4h.01'),
                                    navn: A4MegCopy.a4_meg_hjelp,
                                    onTap: _hjelp,
                                  ),
                                ],
                              ),
                              // --- Not in the design: needs sign-off (D2) ----------------
                              // The rows new Bergen took out of Meg, kept in one group so
                              // they can go in one change once the manager approves.
                              const MegGruppeHode(MegB8Copy.flere),
                              _Gruppe(
                                key: const Key('meg-d2-rader'),
                                children: [
                                  _Rad(
                                    key: const Key('meg-rad-anledninger'),
                                    tile: const _GlassTile(rot: 2, d: 'M4 9h16v11H4zM4 9l2-4h4l2 4 2-4h4l2 4M12 9v11'),
                                    navn: A4MegCopy.a4_meg_anledninger,
                                    under: _occasions.isEmpty ? A4MegCopy.a4_meg_anledninger_tom : '${_occasions.map((o) => '${o.person} · ${MegSheets.pretty(o.next ?? o.date)}').join(' · ')} · ${A4MegCopy.a4_meg_anledninger_paaminnelse}',
                                    onTap: _anledninger,
                                  ),
                                  // Customer Step 0 (D-K20): the reminders Ægil keeps.
                                  _Rad(
                                    key: const Key('cus-meg-rad-paaminnelser'),
                                    tile: const _GlassTile(rot: -2, d: 'M6 16V11a6 6 0 0 1 12 0v5l1.5 2h-15zM10 20a2 2 0 0 0 4 0'),
                                    navn: CusPaaminnelserCopy.cus_meg_paaminnelser,
                                    under: CusPaaminnelserCopy.cus_meg_paaminnelser_sub,
                                    onTap: () => visPaaminnelser(context, repo: _aegilRepo),
                                  ),
                                  _Rad(
                                    key: const Key('meg-rad-ukeshandel'),
                                    tile: const _GlassTile(rot: 3, d: 'M5 8h14l-1.2 11.4a2 2 0 0 1-2 1.8H8.2a2 2 0 0 1-2-1.8Z M9 8V6a3 3 0 0 1 6 0v2'),
                                    navn: A4MegCopy.a4_meg_ukeshandel,
                                    under: A4MegCopy.a4_meg_ukeshandel_sub,
                                    onTap: _ukeshandel,
                                  ),
                                  _Rad(
                                    key: const Key('meg-rad-kode'),
                                    tile: const _GlassTile(rot: 4, d: 'M7 11V8a5 5 0 0 1 10 0v3M5 11h14v10H5z'),
                                    navn: A4MegCopy.a4_meg_krev_kode,
                                    under: _prefs?.alwaysCode == true ? A4MegCopy.a4_meg_kode_paa : A4MegCopy.a4_meg_kode_av(kA4CodeThresholdKr),
                                    merke: _prefs?.alwaysCode == true ? A4MegCopy.a4_meg_paa : A4MegCopy.a4_meg_av,
                                    merkeDempet: _prefs?.alwaysCode != true,
                                    onTap: _toggleKode,
                                  ),
                                  _Rad(
                                    key: const Key('meg-rad-dora'),
                                    tile: const _GlassTile(rot: -3, d: 'M6 21V3h12v18M4 21h16M15 12h.01'),
                                    navn: A4MegCopy.a4_meg_husk_dora,
                                    under: _prefs?.doorProfileConsent == true ? A4MegCopy.a4_meg_dora_paa : A4MegCopy.a4_meg_dora_av,
                                    merke: _prefs?.doorProfileConsent == true ? A4MegCopy.a4_meg_paa : A4MegCopy.a4_meg_av,
                                    merkeDempet: _prefs?.doorProfileConsent != true,
                                    onTap: _toggleDora,
                                  ),
                                  _Rad(
                                    key: const Key('meg-rad-betaling'),
                                    tile: const _GlassTile(rot: 3, d: 'M2 7h20v10H2zM6 12h1M17 12h1'),
                                    navn: A4MegCopy.a4_meg_betaling,
                                    under: _paymentLine ?? A4MegCopy.a4_meg_betaling_vipps,
                                    onTap: _openBetaling,
                                  ),
                                  _Rad(
                                    key: const Key('meg-rad-konto'),
                                    tile: const _FargeTile(rot: -2, farger: [Color(0xFFCFE6E0), Color(0xFF4E8C82)], d: 'M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM4 21a8 8 0 0 1 16 0'),
                                    navn: A4MegCopy.a4_meg_konto,
                                    under: A4MegCopy.a4_meg_konto_sub,
                                    onTap: () => _go('/bergen/meg/konto'),
                                  ),
                                ],
                              ),
                              // --- Logg ut (L7630–7648) -----------------------------------
                              MegLoggUt(konto: MegB8Copy.loggetInn(_firstName, _kontakt), onLoggUt: _loggUt),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// «Hjelp og kontakt» (`apneHjelp`): the Hjelp sheet.
  void _hjelp() => HjelpScreen.apne(context);

  String _safeLanguage() {
    try {
      return resolveSelectedLanguage();
    } catch (_) {
      return 'no';
    }
  }

  String _synLabel(String syn) {
    for (final s in A4MegCopy.a4_meg_ligasyn) {
      if (s[0] == syn) return s[1].toLowerCase();
    }
    return syn;
  }
}


/// The small perforated gold ticket (design: 46×32, notches, dashed tear line,
/// the Æ mark, three printed lines, the shine sweep).
class _TicketStub extends StatelessWidget {
  const _TicketStub({required this.width, required this.height, this.radius = 8, this.animate = true});

  final double width;
  final double height;
  final double radius;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final k = width / 46;
    final body = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(begin: Alignment(-.7, -1), end: Alignment(.7, 1), colors: [Color(0xFFFFF6D8), Color(0xFFF2D591), Color(0xFFD9A93A)], stops: [0, .46, 1]),
        border: Border.all(color: const Color(0xFFB4871E).withValues(alpha: .45)),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(120, 85, 10, .75), offset: Offset(0, 5), blurRadius: 10, spreadRadius: -5)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            // inset highlight / inset bottom shade
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white.withValues(alpha: .9), Colors.white.withValues(alpha: 0), Colors.transparent, const Color(0xFF785508).withValues(alpha: .24)],
                    stops: const [0, .08, .75, 1],
                  ),
                ),
              ),
            ),
            Positioned(left: -4 * k, top: height / 2 - 4 * k, child: _notch(8 * k, const Color(0xFFFBF7EB))),
            Positioned(right: -4 * k, top: height / 2 - 4 * k, child: _notch(8 * k, const Color(0xFFF6EFDC))),
            Positioned(
              left: 28 * k,
              top: 4 * k,
              bottom: 4 * k,
              child: CustomPaint(
                size: Size(1.5, height - 8 * k),
                painter: _DashedLine(color: const Color(0xFF785508).withValues(alpha: .45)),
              ),
            ),
            Positioned(
              left: 3 * k,
              top: height / 2 - 9 * k,
              child: MegMark(color: const Color(0xFF5A4010), accent: const Color(0xFFC4491A), size: 22 * k),
            ),
            Positioned(left: 33 * k, top: 8 * k, child: _line(6 * k, .45)),
            Positioned(left: 33 * k, top: 14 * k, child: _line(6 * k, .3)),
            Positioned(left: 33 * k, top: 20 * k, child: _line(4 * k, .2)),
          ],
        ),
      ),
    );
    return animate ? MegShine(borderRadius: BorderRadius.circular(radius), child: body) : body;
  }

  Widget _notch(double d, Color c) => Container(
    width: d,
    height: d,
    decoration: BoxDecoration(shape: BoxShape.circle, color: c),
  );

  Widget _line(double w, double a) => Container(
    width: w,
    height: 2,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(9),
      color: const Color(0xFF5A4010).withValues(alpha: a),
    ),
  );
}

class _DashedLine extends CustomPainter {
  const _DashedLine({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(0, (y + 2).clamp(0, size.height)), paint);
      y += 4;
    }
  }

  @override
  bool shouldRepaint(_DashedLine old) => old.color != color;
}


// ── Launch rows (`Meg-rader` L7430, `kMegRader`) ─────────────────────────────

/// The row group: `radius 22`, `padding 2px 14px`, white .13 → .06, a 1 px
/// .18 border, `inset 0 1.5px 0 .28`, `0 18px 32px -18px rgba(4,18,26,.9)`.
class _Gruppe extends StatelessWidget {
  const _Gruppe({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => CssBox(
    radius: BorderRadius.circular(22),
    bg: const [
      CssLinear(180, [Color.fromRGBO(255, 255, 255, .13), Color.fromRGBO(255, 255, 255, .06)]),
    ],
    shadows: const [CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .28)), CssShadow(0, 18, 32, -18, Color.fromRGBO(4, 18, 26, .9))],
    border: Border.all(color: const Color.fromRGBO(255, 255, 255, .18)),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
    child: Column(
      children: [
        for (final (i, c) in children.indexed)
          DecoratedBox(
            decoration: BoxDecoration(
              border: i == children.length - 1 ? null : const Border(bottom: BorderSide(color: Color.fromRGBO(255, 255, 255, .12))),
            ),
            child: c,
          ),
      ],
    ),
  );
}

/// One row: the tile, the name (14, 800 in Meg-rader / 700 below), the line
/// (12, 600, .82), the mint mark or an orange key, and the chevron.
class _Rad extends StatelessWidget {
  const _Rad({
    super.key,
    required this.tile,
    required this.navn,
    this.under,
    this.merke,
    this.merkeDempet = false,
    this.merkePille = false,
    this.knapp,
    this.knappKey,
    this.del = false,
    this.onKnapp,
    this.sterk = false,
    required this.onTap,
  });

  final Widget tile;
  final String navn;
  final String? under;
  final String? merke;
  final bool merkeDempet;

  /// The mint count pill (`feedUlest`, L7620): «Nytt fra butikkene».
  final bool merkePille;
  final String? knapp;
  final Key? knappKey;
  final bool del;
  final VoidCallback? onKnapp;
  final bool sterk;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AePress(
    onTap: onTap,
    dy: 1.5,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: sterk ? 12 : 11),
        child: Row(
          children: [
            tile,
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(navn, style: inter(14, weight: sterk ? FontWeight.w800 : FontWeight.w700)),
                  if (under != null)
                    Text(
                      under!,
                      style: inter(12, weight: FontWeight.w600, height: 1.35, color: const Color.fromRGBO(255, 255, 255, .82)),
                    ),
                ],
              ),
            ),
            if (merke != null) ...[
              const SizedBox(width: 11),
              if (merkePille)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                  decoration: BoxDecoration(color: const Color(0xFF5CE0B8), borderRadius: BorderRadius.circular(999)),
                  child: Text(merke!, style: aeTab(inter(11, weight: FontWeight.w800, color: const Color(0xFF0F1F2B)))),
                )
              else
                Text(
                  merke!,
                  style: aeTab(inter(12.5, weight: FontWeight.w800, color: merkeDempet ? const Color.fromRGBO(255, 255, 255, .7) : const Color(0xFF7FF0CB))),
                ),
            ],
            if (knapp != null) ...[
              const SizedBox(width: 11),
              AePress(
                key: knappKey ?? const Key('meg-bli-med'),
                onTap: onKnapp,
                dy: 1.5,
                child: CssBox(
                  radius: BorderRadius.circular(999),
                  bg: const [
                    CssLinear(160, [Color(0xFFF2884E), Color(0xFFE0662C)]),
                  ],
                  shadows: const [CssShadow(0, 1.5, 0, 0, Color(0xFF123640)), CssShadow(0, 6, 10, -7, Color.fromRGBO(15, 45, 55, .8))],
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                  child: Text(knapp!, style: inter(12.5, weight: FontWeight.w800)),
                ),
              ),
            ],
            if (del) ...[
              const SizedBox(width: 11),
              AePress(
                key: const Key('meg-del-2'),
                onTap: onKnapp,
                dy: 3,
                child: CssBox(
                  height: 40,
                  radius: BorderRadius.circular(999),
                  bg: const [
                    CssLinear(180, [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], [0, .56, 1]),
                  ],
                  shadows: const [
                    CssShadow(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .5)),
                    CssShadow(0, 1.5, 0, 0, Color(0xFFC4491A)),
                    CssShadow(0, 3.5, 0, 0, Color.fromRGBO(120, 45, 15, .42)),
                    CssShadow(0, 11, 16, -9, Color.fromRGBO(200, 70, 25, .8)),
                  ],
                  padding: const EdgeInsets.symmetric(horizontal: 17),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(A4MegCopy.a4_meg_del, style: inter(13, weight: FontWeight.w800)),
                      const SizedBox(width: 6),
                      const AeIkon('M12 16V4M12 4l-4 4M12 4l4 4M5 15v3a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-3', size: 13, stroke: 2.6),
                    ],
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(width: 11),
              const AeIkon('M9 6l6 6-6 6', size: 13, stroke: 2.2, color: Color.fromRGBO(255, 255, 255, .85)),
            ],
          ],
        ),
      ),
    ),
  );
}

/// The league tile: the orange square with the mint mountain and the sun.
class _LigaTile extends StatelessWidget {
  const _LigaTile();

  @override
  Widget build(BuildContext context) => Container(
    width: 34,
    height: 34,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      gradient: const LinearGradient(begin: Alignment(-.34, -.94), end: Alignment(.34, .94), colors: [Color(0xFFF2884E), Color(0xFFE0662C)]),
    ),
    alignment: Alignment.center,
    child: SvgPicture.string(
      '<svg viewBox="0 0 40 24"><path d="M2 22 L14 6 L21 15 L27 8 L38 22 Z" fill="rgba(92,224,184,.3)" fill-opacity="1" stroke="#5CE0B8" stroke-width="1.8" stroke-linejoin="round"/><circle cx="14" cy="6" r="2.4" fill="#F2C14E"/></svg>',
      width: 20,
      height: 13,
    ),
  );
}

/// `kMegRader`'s glass tile, turned a few degrees, with a stroked icon.
class _GlassTile extends StatelessWidget {
  const _GlassTile({required this.rot, required this.d});

  final double rot;
  final String d;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: rad(rot),
    child: CssBox(
      width: 38,
      height: 38,
      radius: BorderRadius.circular(13),
      bg: const [
        CssLinear(180, [Color.fromRGBO(255, 255, 255, .26), Color.fromRGBO(255, 255, 255, .12)]),
      ],
      shadows: const [
        CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .35)),
        CssShadow(0, 2, 3, -1, Color.fromRGBO(35, 32, 29, .18)),
        CssShadow(0, 6, 12, -8, Color.fromRGBO(35, 32, 29, .35)),
      ],
      child: Center(child: AeIkon(d, size: 18, stroke: 2, color: const Color(0xFFEAF6F4))),
    ),
  );
}

/// Favoritter / Nytt / Hjelp: the glass frame with a coloured inner tile and
/// a white icon.
class _FargeTile extends StatelessWidget {
  const _FargeTile({required this.rot, required this.farger, required this.d, this.fyll = false});

  final double rot;
  final List<Color> farger;
  final String d;
  final bool fyll;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: rad(rot),
    child: CssBox(
      width: 38,
      height: 38,
      radius: BorderRadius.circular(13),
      bg: const [
        CssLinear(180, [Color.fromRGBO(255, 255, 255, .14), Color.fromRGBO(255, 255, 255, .06)]),
      ],
      shadows: const [CssShadow(0, 2, 3, -1, Color.fromRGBO(35, 32, 29, .14)), CssShadow(0, 8, 14, -8, Color.fromRGBO(90, 60, 30, .5))],
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(begin: const Alignment(-.34, -.94), end: const Alignment(.34, .94), colors: farger),
        ),
        alignment: Alignment.center,
        child: fyll ? AeIkon(d, size: 17, stroke: 0, fill: Colors.white) : AeIkon(d, size: 17, stroke: 2.2),
      ),
    ),
  );
}

/// One-shot: Meg opens with «Poeng, nivå og konkurranser» unfolded (the
/// old `/bergen/poeng` route lands here, Gap Step 4).
abstract final class MegApne {
  static bool poeng = false;
}

/// The feed calls behind «Nytt fra butikkene»; tests swap them.
abstract final class MegFeed {
  static Future<int> Function() nye = () async => (await FeedRepo().fetchUnread(tab: 'folger')).unread;
  static Future<void> Function() lest = () => FeedRepo().markSeen(tab: 'folger');
}

/// Meg's last loaded data for this app session, per user (in memory only:
/// a new user or a restart starts empty). Meg shows it at once and refreshes.
class _MegCache {
  _MegCache({
    required this.userId,
    this.balance,
    this.shelf,
    this.league,
    this.referral,
    this.prefs,
    this.settings,
    this.levels = const [],
    this.occasions = const [],
    this.addressLine,
    this.paymentLine,
    this.ordrer = const [],
    this.minne = const [],
    this.regler,
    this.adresser = const [],
  });

  final int userId;
  final PointsBalance? balance;
  final Premiehylla? shelf;
  final League? league;
  final Referral? referral;
  final CustomerPrefs? prefs;
  final AegilSettings? settings;
  final List<AegilLevel> levels;
  final List<Occasion> occasions;
  final String? addressLine;
  final String? paymentLine;
  final List<Map<String, dynamic>> ordrer;
  final List<MemoryEntry> minne;
  final PointsRules? regler;
  final List<AddressListItem> adresser;

  static _MegCache? _siste;

  static _MegCache? forUser(int userId) => (_siste != null && _siste!.userId == userId && userId > 0) ? _siste : null;

  static void lagre(_MegCache c) => _siste = c;
}
