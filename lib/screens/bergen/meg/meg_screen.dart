import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/aegil/aegil_app_models.dart';
import '../../../data/aegil/aegil_app_repo.dart';
import '../../../data/aegil/aegil_models.dart';
import '../../../data/aegil/aegil_repo.dart';
import '../../../data/points/league_models.dart';
import '../../../data/points/points_app_repo.dart';
import '../../../data/points/points_models.dart';
import '../../../utils/shared_pref_utill.dart';
import '../../aegil/widgets/aegil_settings_panel.dart';
import '../../common/manageAddress/manage_address.dart';
import '../../common/manageCard/manage_card.dart';
import '../../common/manageAddress/add_new_address.dart';
import '../../../utils/utils.dart' show setChangedLanguage;
import '../../common/auth/launch/lf_css.dart';
import '../../common/home/bergen/bergen_kit.dart' show BergenWeatherLook;
import '../aegil/aegil_bits.dart';
import '../aegil/aegil_screen.dart';
import '../hjem/hjem_harness.dart';
import '../hjem/hjem_hero.dart' show HjemVaer;
import '../kit/bergen_kit.dart';
import 'a3_services.dart';
import 'borte_entry.dart';
import '../../../networking/ops/ops_customer_api.dart';
import 'bestillinger_screen.dart' show OhCopy;
import 'meg_ark.dart';
import 'meg_copy_a4.dart';
import 'meg_hero.dart';
import 'meg_mark.dart';
import 'meg_nivaa_card.dart';
import 'meg_pill.dart';
import 'meg_shine.dart';
import 'meg_sheets.dart';
import 'varsler_panel.dart';

/// The threshold the design quotes for "Av · kreves over N kr". Ops decides the
/// real one (an Ask of agil-1: policy `proof.value_threshold_ore`).
const int kA4CodeThresholdKr = 300;

/// Meg (design `meg` ≈L5912–6124, agil-4): the hero with Ægil's goal bubble,
/// the header (name · bydel, Premie: gratis levering, Gullbilletten), the Poeng
/// card, the four Meg-rader (Nivå, Fløyen-ligaen, Ukens oppdrag, Gullbilletten)
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
  List<Occasion> _occasions = const [];
  List<PrizeClaim> _claims = const [];
  String? _addressLine;
  String? _paymentLine;
  List<Map<String, dynamic>> _ordrer = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await Future.wait<Object?>([
      a3Try(_api.balance),
      a3Try(_api.shelf),
      a3Try(_api.league),
      a3Try(_api.referral),
      a3Try(_api.prefs),
      a3Try(_aegilRepo.fetchSettings),
      a3Try(_aegil.occasions),
      a3Try(_api.claims),
      a3Try(A3Services.addressLine),
      a3Try(A3Services.paymentLine),
      a3Try(() => OpsCustomerApi().orders(limit: 50)),
    ]);
    if (!mounted) return;
    final settings = r[5] as ({AegilSettings? settings, List<AegilLevel> levels})?;
    setState(() {
      _balance = r[0] as PointsBalance?;
      _shelf = r[1] as Premiehylla?;
      _league = r[2] as League?;
      _referral = r[3] as Referral?;
      _prefs = r[4] as CustomerPrefs?;
      _settings = settings?.settings;
      _levels = settings?.levels ?? const [];
      _occasions = (r[6] as List<Occasion>?) ?? const [];
      _claims = (r[7] as List<PrizeClaim>?) ?? const [];
      _addressLine = r[8] as String?;
      _paymentLine = r[9] as String?;
      _ordrer = (r[10] as List<Map<String, dynamic>>?) ?? const [];
      _loading = false;
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

  bool get _hasDeliveryGift => _claims.any((c) => c.isGift && c.state == 'claimed');

  /// The tier gift waiting to be used, for «Premie: …».
  String get _giftName => _claims.where((c) => c.isGift && c.state == 'claimed').firstOrNull?.prizeName ?? '';

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
    final list = await a3Try(A3Services.addresses) ?? const <String>[];
    if (!mounted) return;
    await MegSheets.adresser(context, addresses: list, onManage: () => _push(const ManageAddress()), onAdd: () => _push(const AddNewAddress()));
  }

  Future<void> _openBetaling() async {
    final list = await a3Try(A3Services.cards) ?? const <String>[];
    if (!mounted) return;
    await MegSheets.betaling(context, cards: list, onManage: () => _push(const ManageCard()));
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
      await Share.share(text, subject: A4MegCopy.a4_meg_gullbilletten);
      return;
    } catch (_) {}
    await Clipboard.setData(ClipboardData(text: _referral?.link ?? code));
    if (mounted) showBergenToast(context, A4MegCopy.a4_meg_kopiert(code), icon: Icons.copy_rounded);
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
    await showVarslerPanel(context);
    final p = await _api.updatePrefs(markNotificationsSeen: true);
    if (mounted) setState(() => _prefs = p ?? _prefs);
  }

  Future<void> _anledninger() async {
    final list = await MegSheets.anledninger(context, api: _aegil, initial: _occasions);
    if (list != null && mounted) setState(() => _occasions = list);
  }

  Future<void> _ukeshandel() async {
    final items = await a3Try(_aegil.shoppingList) ?? const [];
    if (!mounted) return;
    await MegSheets.ukeshandel(context, items: items, level: _settings?.level ?? 2, onOpenAegilSettings: _aegilInnstillinger);
  }

  void _aegilInnstillinger() {
    final s = _settings;
    if (s == null) {
      _go('/bergen/aegil');
      return;
    }
    showBergenSheet<void>(
      context,
      onDark: true,
      builder: (ctx) => AegilSettingsPanel(
        settings: s,
        levels: _levels,
        onLevelChanged: (level) async {
          final r = await _aegilRepo.updateSettings({'level': level});
          if (mounted) setState(() => _settings = r.settings ?? _settings);
        },
        onToggle: (field, value) async {
          final r = await _aegilRepo.updateSettings({field: value});
          if (mounted) setState(() => _settings = r.settings ?? _settings);
        },
        onPause: (days) async {
          final r = await _aegilRepo.updateSettings({'pause_days': days});
          if (mounted) setState(() => _settings = r.settings ?? _settings);
        },
        onResume: () async {
          final r = await _aegilRepo.updateSettings({'pause_days': 0});
          if (mounted) setState(() => _settings = r.settings ?? _settings);
        },
        onForgetAll: () => _go('/bergen/aegil/minne'),
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
    final niv = _settings?.level ?? 2;
    final nivNavn = _levels.where((x) => x.level == niv).firstOrNull?.name ?? _settings?.levelName ?? '';

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
                            key: const Key('meg-list'),
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 130),
                            children: [
                              // --- Header ---------------------------------------------
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
                                    Wrap(
                                      spacing: 7,
                                      runSpacing: 4,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          '${A4MegCopy.a4_meg_bydel} · ${A4MegCopy.a4_meg_region}',
                                          style: inter(11, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .66)),
                                        ),
                                        if (_hasDeliveryGift) GestureDetector(onTap: () => _go('/bergen/premiehylla'), child: _PremieChip(navn: _giftName)),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    _GullbillettCard(give: give, get: get, onDel: _openBillett, onOpen: _openBillett),
                                  ],
                                ),
                              ),
                              if (borte != null) ...[const SizedBox(height: 12), borte],
                              const SizedBox(height: 14),
                              // --- Poeng (L7377) ----------------------------------------
                              if (b != null)
                                MegNivaaCard(
                                  balance: b,
                                  goal: _goal,
                                  onOpenPremiehylla: () => _go('/bergen/premiehylla'),
                                  onOpenNivaa: _openNivaa,
                                  onOpenSlik: () => MegSheets.slikPoeng(context, b),
                                  onHentPremie: () => _goal?.prizeId != null ? _go('/bergen/premie', arguments: _goal!.prizeId) : _go('/bergen/premiehylla'),
                                ),
                              // --- Meg-rader (L7430) -------------------------------------
                              const SizedBox(height: 12),
                              _Gruppe(
                                key: const Key('meg-rader'),
                                children: [
                                  if (b != null)
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
                                ],
                              ),
                              // --- kMegRader --------------------------------------------
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
                                  _Rad(
                                    key: const Key('meg-rad-anledninger'),
                                    tile: const _GlassTile(rot: 2, d: 'M4 9h16v11H4zM4 9l2-4h4l2 4 2-4h4l2 4M12 9v11'),
                                    navn: A4MegCopy.a4_meg_anledninger,
                                    under: _occasions.isEmpty ? A4MegCopy.a4_meg_anledninger_tom : '${_occasions.map((o) => '${o.person} · ${MegSheets.pretty(o.next ?? o.date)}').join(' · ')} · ${A4MegCopy.a4_meg_anledninger_paaminnelse}',
                                    onTap: _anledninger,
                                  ),
                                  _Rad(
                                    key: const Key('meg-rad-ukeshandel'),
                                    tile: const _GlassTile(rot: 3, d: 'M5 8h14l-1.2 11.4a2 2 0 0 1-2 1.8H8.2a2 2 0 0 1-2-1.8Z M9 8V6a3 3 0 0 1 6 0v2'),
                                    navn: A4MegCopy.a4_meg_ukeshandel,
                                    under: A4MegCopy.a4_meg_ukeshandel_sub,
                                    onTap: _ukeshandel,
                                  ),
                                  _Rad(
                                    key: const Key('meg-rad-aegil'),
                                    tile: const _GlassTile(rot: -3, d: 'M12 3l8 18-8-5-8 5z'),
                                    navn: A4MegCopy.a4_meg_saa_mye,
                                    under: '${A4MegCopy.a4_meg_rad_nivaa} $niv${nivNavn.isEmpty ? '' : ' · $nivNavn'}',
                                    merke: niv >= 4 ? A4MegCopy.a4_meg_fast : A4MegCopy.a4_meg_nivaa4,
                                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AegilScreen(steg: 'nivaa'))),
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
                                    key: const Key('meg-rad-adresser'),
                                    tile: const _GlassTile(rot: -2, d: 'M12 21s7-6 7-12a7 7 0 1 0-14 0c0 6 7 12 7 12zM12 11a2 2 0 1 0 0-4 2 2 0 0 0 0 4'),
                                    navn: A4MegCopy.a4_meg_adresser,
                                    under: _addressLine == null ? A4MegCopy.a4_meg_adresser_tom : '$_addressLine · ${A4MegCopy.a4_meg_adresser_bare}',
                                    onTap: _openAdresser,
                                  ),
                                  _Rad(
                                    key: const Key('meg-rad-betaling'),
                                    tile: const _GlassTile(rot: 3, d: 'M2 7h20v10H2zM6 12h1M17 12h1'),
                                    navn: A4MegCopy.a4_meg_betaling,
                                    under: _paymentLine ?? A4MegCopy.a4_meg_betaling_vipps,
                                    onTap: _openBetaling,
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
                                    onTap: () => BergenRoutes.push(context, '/bergen/utforsk', arguments: const {'tab': 'feed'}),
                                  ),
                                  _Rad(
                                    key: const Key('meg-rad-hjelp'),
                                    tile: const _FargeTile(rot: 4, farger: [Color(0xFFDDE6EA), Color(0xFF8C9EA6)], d: 'M12 3a9 9 0 1 0 .01 0zM9.6 9.4a2.5 2.5 0 1 1 3.4 2.4V14M12 17.4h.01'),
                                    navn: A4MegCopy.a4_meg_hjelp,
                                    onTap: _hjelp,
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

  void _hjelp() => MegSheets.hjelp(
    context,
    onAegil: () => _go('/bergen/aegil'),
    onHuman: () => BergenRoutes.pushOr(context, '/bergen/kundeservice', orElse: () => _go('/bergen/aegil')),
  );

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

/// The gold ticket (design "Gullbilletten · Gi 200 · få 200 poeng · Del"): the
/// cream pill on its ridge, the perforated ticket with the Æ mark and the
/// shine sweep, the two text lines and the Del cta3d.
class _GullbillettCard extends StatelessWidget {
  const _GullbillettCard({required this.give, required this.get, required this.onDel, required this.onOpen});

  final int give;
  final int get;
  final VoidCallback onDel;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        key: const Key('meg-gullbillett'),
        behavior: HitTestBehavior.opaque,
        onTap: onOpen,
        child: MegShine(
          borderRadius: BorderRadius.circular(999),
          bandFraction: .28,
          opacity: .5,
          child: Container(
            padding: const EdgeInsets.fromLTRB(7, 6, 7, 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFFDF4), Color(0xFFF6EFDC)]),
              border: Border.all(color: Colors.white.withValues(alpha: .95)),
              boxShadow: const [
                BoxShadow(color: Color(0xFFE7DCC0), offset: Offset(0, 1.5)),
                BoxShadow(color: Color.fromRGBO(150, 115, 25, .22), offset: Offset(0, 3)),
                BoxShadow(color: Color.fromRGBO(120, 85, 10, .25), offset: Offset(0, 6), blurRadius: 10, spreadRadius: -4),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _TicketStub(width: 46, height: 32, animate: true),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        A4MegCopy.a4_meg_gullbilletten,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BergenTokens.display(13, weight: FontWeight.w800, color: const Color(0xFF3A2708), letterSpacingEm: -0.01, height: 1.1),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        A4MegCopy.a4_meg_gi_faa(give, get),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BergenTokens.text(10, weight: FontWeight.w700, color: const Color(0xFF8A6A2A), height: 1.1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                MegPill(key: const Key('meg-del'), label: A4MegCopy.a4_meg_del, icon: Icons.ios_share_rounded, expand: false, height: 34, fontSize: 12.5, onPressed: onDel),
              ],
            ),
          ),
        ),
      ),
    );
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

/// "Premie: gratis levering" (design: the green-mint pill with the varde).
class _PremieChip extends StatelessWidget {
  const _PremieChip({required this.navn});

  final String navn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 3, 9, 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFF3F8F5F).withValues(alpha: .14),
        border: Border.all(color: const Color(0xFF3F8F5F).withValues(alpha: .45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.landscape_rounded, size: 11, color: BergenTokens.mint),
          const SizedBox(width: 4),
          Text(navn.isEmpty ? A4MegCopy.a4_meg_premie_levering : A4MegCopy.a4_meg_premie(navn), style: megInter(9.5, FontWeight.w800, color: BergenTokens.mint)),
        ],
      ),
    );
  }
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
    this.knapp,
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
  final String? knapp;
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
              Text(
                merke!,
                style: aeTab(inter(12.5, weight: FontWeight.w800, color: merkeDempet ? const Color.fromRGBO(255, 255, 255, .7) : const Color(0xFF7FF0CB))),
              ),
            ],
            if (knapp != null) ...[
              const SizedBox(width: 11),
              AePress(
                key: const Key('meg-bli-med'),
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
