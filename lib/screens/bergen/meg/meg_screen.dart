import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
import '../../common/selectLanguageAndCurrency/select_language_and_currency.dart';
import '../kit/bergen_kit.dart';
import 'a3_scaffold.dart';
import 'a3_services.dart';
import 'borte_entry.dart';
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
  Mission? _mission;
  League? _league;
  Referral? _referral;
  CustomerPrefs? _prefs;
  AegilSettings? _settings;
  List<AegilLevel> _levels = const [];
  List<Occasion> _occasions = const [];
  List<PrizeClaim> _claims = const [];
  String? _addressLine;
  String? _paymentLine;
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
      a3Try(_api.mission),
      a3Try(_api.league),
      a3Try(_api.referral),
      a3Try(_api.prefs),
      a3Try(_aegilRepo.fetchSettings),
      a3Try(_aegil.occasions),
      a3Try(_api.claims),
      a3Try(A3Services.addressLine),
      a3Try(A3Services.paymentLine),
    ]);
    if (!mounted) return;
    final settings =
        r[6] as ({AegilSettings? settings, List<AegilLevel> levels})?;
    setState(() {
      _balance = r[0] as PointsBalance?;
      _shelf = r[1] as Premiehylla?;
      _mission = r[2] as Mission?;
      _league = r[3] as League?;
      _referral = r[4] as Referral?;
      _prefs = r[5] as CustomerPrefs?;
      _settings = settings?.settings;
      _levels = settings?.levels ?? const [];
      _occasions = (r[7] as List<Occasion>?) ?? const [];
      _claims = (r[8] as List<PrizeClaim>?) ?? const [];
      _addressLine = r[9] as String?;
      _paymentLine = r[10] as String?;
      _loading = false;
    });
  }

  void _go(String route, {Object? arguments}) =>
      Navigator.of(context).pushNamed(route, arguments: arguments);

  void _push(Widget w) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => w));

  String get _firstName =>
      a3Pref(prefUserName).trim().split(' ').firstOrNull ?? '';

  PointGoal? get _goal => _shelf?.goal;

  String get _bubble {
    final g = _goal;
    if (g == null) return A4MegCopy.a4_meg_boble_ingen;
    return g.reached
        ? A4MegCopy.a4_meg_boble_klar(g.label)
        : A4MegCopy.a4_meg_boble_til(g.remaining, g.label);
  }

  bool get _hasDeliveryGift =>
      _claims.any((c) => c.isGift && c.state == 'claimed');

  Future<void> _share() async {
    final code = _referral?.code ?? a3Pref(prefReferralCode);
    await Clipboard.setData(ClipboardData(text: _referral?.link ?? code));
    if (mounted)
      showBergenToast(
        context,
        A4MegCopy.a4_meg_kopiert(code),
        icon: Icons.copy_rounded,
      );
  }

  Future<void> _godta() async {
    final m = await _api.acceptMission();
    if (!mounted) return;
    setState(() => _mission = m ?? _mission);
    showBergenToast(
      context,
      A4MegCopy.a4_meg_oppdrag_ditt(_mission?.title ?? ''),
      icon: Icons.flag_rounded,
    );
  }

  Future<void> _ikkeDette() async {
    final r = await _api.declineMission();
    if (!mounted) return;
    setState(() => _mission = r.replacement);
    showBergenToast(context, A4MegCopy.a4_meg_oppdrag_nei);
  }

  Future<void> _toggleKode() async {
    final on = _prefs?.alwaysCode ?? false;
    final next = await MegSheets.kodeInnst(context, on: on);
    if (next == null || !mounted) return;
    final p = await _api.updatePrefs(alwaysCode: next);
    if (!mounted) return;
    setState(() => _prefs = p ?? _prefs);
    showBergenToast(
      context,
      next
          ? A4MegCopy.a4_meg_kode_alltid
          : A4MegCopy.a4_meg_kode_bare(kA4CodeThresholdKr),
      icon: Icons.lock_rounded,
    );
  }

  Future<void> _ligaNavn() async {
    final l = _league;
    if (l == null) return;
    final updated = await MegSheets.ligaNavn(
      context,
      api: _api,
      league: l,
      firstName: _firstName,
      bydel: l.bydel ?? A4MegCopy.a4_meg_bydel,
    );
    if (!mounted) return;
    if (updated != null) {
      setState(() => _league = updated);
      showBergenToast(
        context,
        A4MegCopy.a4_meg_lagret,
        icon: Icons.check_rounded,
      );
    }
  }

  Future<void> _anledninger() async {
    final list = await MegSheets.anledninger(
      context,
      api: _aegil,
      initial: _occasions,
    );
    if (list != null && mounted) setState(() => _occasions = list);
  }

  Future<void> _ukeshandel() async {
    final items = await a3Try(_aegil.shoppingList) ?? const [];
    if (!mounted) return;
    await MegSheets.ukeshandel(
      context,
      items: items,
      level: _settings?.level ?? 2,
      onOpenAegilSettings: _aegilInnstillinger,
    );
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

  Future<void> _varsler() async {
    await showVarslerPanel(context);
    final p = await _api.updatePrefs(markNotificationsSeen: true);
    if (mounted) setState(() => _prefs = p ?? _prefs);
  }

  @override
  Widget build(BuildContext context) {
    final b = _balance;
    final ref = _referral;
    final l = _league;
    final m = _mission;
    final borte = mensDuVarBorteCard(context);
    final give = ref?.pointsForThem ?? 200;
    final get = ref?.pointsForMe ?? 200;
    final code = ref?.code ?? a3Pref(prefReferralCode);
    final lang =
        A4MegCopy.a4_meg_spraak_navn[_safeLanguage()] ?? 'Norsk bokmål';

    return ValueListenableBuilder<bool>(
      valueListenable: A3Services.reducedMotion,
      builder: (context, reduced, _) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations:
              reduced || MediaQuery.of(context).disableAnimations,
        ),
        child: Scaffold(
          backgroundColor: BergenTokens.tealDeep,
          body: DecoratedBox(
            decoration: const BoxDecoration(gradient: BergenTokens.screen),
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: BergenTokens.mint),
                  )
                : ListView(
                    key: const Key('meg-list'),
                    padding: EdgeInsets.zero,
                    children: [
                      MegHero(bubble: _bubble),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // --- Header ---------------------------------------------------
                            Text(
                              _firstName.isEmpty
                                  ? 'Meg'
                                  : A4MegCopy.a4_meg_fra(
                                      _firstName,
                                      A4MegCopy.a4_meg_bydel,
                                    ),
                              key: const Key('meg-title'),
                              style: BergenTokens.display(
                                26,
                                weight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacingEm: -0.025,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '${A4MegCopy.a4_meg_bydel} · ${A4MegCopy.a4_meg_region}',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white.withValues(
                                        alpha: .66,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (_hasDeliveryGift)
                                  const Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: _PremieChip(),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _GullbillettCard(
                                    give: give,
                                    get: get,
                                    onDel: _share,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _RoundButton(
                                  key: const Key('meg-innstillinger'),
                                  icon: Icons.light_mode_outlined,
                                  onTap: () => _go('/bergen/meg/konto'),
                                ),
                              ],
                            ),
                            if (borte != null) ...[
                              const SizedBox(height: 12),
                              borte,
                            ],
                            const SizedBox(height: 12),

                            // --- Poeng ----------------------------------------------------
                            if (b != null)
                              MegNivaaCard(
                                balance: b,
                                goal: _goal,
                                onOpenPremiehylla: () =>
                                    _go('/bergen/premiehylla'),
                                onOpenNivaa: () => MegSheets.nivaa(
                                  context,
                                  b,
                                  onOpenPremiehylla: () =>
                                      _go('/bergen/premiehylla'),
                                ),
                                onOpenSlik: () =>
                                    MegSheets.slikPoeng(context, b),
                                onHentPremie: () => _goal?.prizeId != null
                                    ? _go(
                                        '/bergen/premie',
                                        arguments: _goal!.prizeId,
                                      )
                                    : _go('/bergen/premiehylla'),
                              ),
                            const SizedBox(height: 12),

                            // --- Meg-rader ------------------------------------------------
                            _Group(
                              key: const Key('meg-rader'),
                              children: [
                                if (b != null)
                                  _MegRow(
                                    key: const Key('meg-rad-nivaa'),
                                    leading: MegMedal(
                                      name: b.tierName,
                                      size: 34,
                                      animate: false,
                                    ),
                                    title:
                                        '${A4MegCopy.a4_meg_rad_nivaa} · ${b.tierName}',
                                    subtitle: A4MegCopy.a4_meg_nivaa_note,
                                    trailingText:
                                        b.nextTierName == null ||
                                            b.pointsToNextTier == null
                                        ? A4MegCopy.a4_meg_hoyeste
                                        : A4MegCopy.a4_meg_avstand(
                                            b.pointsToNextTier!,
                                            b.nextTierName!,
                                          ),
                                    onTap: () => MegSheets.nivaa(
                                      context,
                                      b,
                                      onOpenPremiehylla: () =>
                                          _go('/bergen/premiehylla'),
                                    ),
                                  ),
                                _MegRow(
                                  key: const Key('meg-rad-liga'),
                                  leading: const _IconBox(
                                    icon: Icons.terrain_rounded,
                                    color: BergenTokens.orange,
                                  ),
                                  title: A4MegCopy.a4_meg_rad_liga,
                                  subtitle: l?.optedIn == true
                                      ? A4MegCopy.a4_meg_liga_med
                                      : A4MegCopy.a4_meg_liga_ute,
                                  trailingText:
                                      l?.optedIn == true && l?.own != null
                                      ? A4MegCopy.a4_meg_plass(l!.own!.rank)
                                      : null,
                                  badge: l?.optedIn == true
                                      ? null
                                      : A4MegCopy.a4_meg_bli_med,
                                  onTap: () => _go('/bergen/liga'),
                                ),
                                if (m != null)
                                  _MissionRow(
                                    mission: m,
                                    onGodta: _godta,
                                    onIkke: _ikkeDette,
                                  ),
                                _MegRow(
                                  key: const Key('meg-rad-gullbillett'),
                                  leading: const _TicketStub(
                                    width: 40,
                                    height: 28,
                                    radius: 7,
                                    animate: false,
                                  ),
                                  title: A4MegCopy.a4_meg_gullbilletten,
                                  subtitle: A4MegCopy.a4_meg_gi_faa_kode(
                                    give,
                                    get,
                                    code,
                                  ),
                                  trailing: MegPill(
                                    key: const Key('meg-del-2'),
                                    label: A4MegCopy.a4_meg_del,
                                    icon: Icons.ios_share_rounded,
                                    expand: false,
                                    onPressed: _share,
                                  ),
                                  showChevron: false,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // --- Innstillinger-rader ----------------------------------------
                            _Group(
                              key: const Key('meg-innstillinger-rader'),
                              children: [
                                _MegRow(
                                  key: const Key('meg-rad-anledninger'),
                                  leading: const _IconBox(
                                    icon: Icons.card_giftcard_rounded,
                                  ),
                                  title: A4MegCopy.a4_meg_anledninger,
                                  subtitle: _occasions.isEmpty
                                      ? A4MegCopy.a4_meg_anledninger_tom
                                      : '${_occasions.map((o) => '${o.person} · ${MegSheets.pretty(o.next ?? o.date)}').join(' · ')} · ${A4MegCopy.a4_meg_anledninger_paaminnelse}',
                                  onTap: _anledninger,
                                ),
                                _MegRow(
                                  key: const Key('meg-rad-ukeshandel'),
                                  leading: const _IconBox(
                                    icon: Icons.shopping_bag_outlined,
                                  ),
                                  title: A4MegCopy.a4_meg_ukeshandel,
                                  subtitle: A4MegCopy.a4_meg_ukeshandel_sub,
                                  onTap: _ukeshandel,
                                ),
                                _MegRow(
                                  key: const Key('meg-rad-aegil'),
                                  leading: const _IconBox(
                                    icon: Icons.navigation_rounded,
                                  ),
                                  title: A4MegCopy.a4_meg_saa_mye,
                                  subtitle: A4MegCopy.a4_meg_nivaa_n(
                                    _settings?.level ?? 2,
                                    _settings?.levelName ?? '',
                                  ),
                                  trailingText: (_settings?.level ?? 2) >= 4
                                      ? A4MegCopy.a4_meg_fast
                                      : A4MegCopy.a4_meg_nivaa4,
                                  trailingAccent: true,
                                  onTap: _aegilInnstillinger,
                                ),
                                _MegRow(
                                  key: const Key('meg-rad-kode'),
                                  leading: const _IconBox(
                                    icon: Icons.lock_outline_rounded,
                                  ),
                                  title: A4MegCopy.a4_meg_krev_kode,
                                  subtitle: _prefs?.alwaysCode == true
                                      ? A4MegCopy.a4_meg_kode_paa
                                      : A4MegCopy.a4_meg_kode_av(
                                          kA4CodeThresholdKr,
                                        ),
                                  trailingText: _prefs?.alwaysCode == true
                                      ? A4MegCopy.a4_meg_paa
                                      : A4MegCopy.a4_meg_av,
                                  trailingAccent: _prefs?.alwaysCode == true,
                                  onTap: _toggleKode,
                                ),
                                _MegRow(
                                  key: const Key('meg-rad-adresser'),
                                  leading: const _IconBox(
                                    icon: Icons.place_outlined,
                                  ),
                                  title: A4MegCopy.a4_meg_adresser,
                                  subtitle:
                                      _addressLine == null ||
                                          _addressLine!.isEmpty
                                      ? A4MegCopy.a4_meg_adresser_tom
                                      : '$_addressLine · ${A4MegCopy.a4_meg_adresser_bare}',
                                  onTap: () => _push(const ManageAddress()),
                                ),
                                _MegRow(
                                  key: const Key('meg-rad-betaling'),
                                  leading: const _IconBox(
                                    icon: Icons.credit_card_rounded,
                                  ),
                                  title: A4MegCopy.a4_meg_betaling,
                                  subtitle:
                                      _paymentLine == null ||
                                          _paymentLine!.isEmpty
                                      ? A4MegCopy.a4_meg_betaling_vipps
                                      : '${A4MegCopy.a4_meg_betaling_vipps} · $_paymentLine',
                                  onTap: () => _push(const ManageCard()),
                                ),
                                _MegRow(
                                  key: const Key('meg-rad-varsler'),
                                  leading: const _IconBox(
                                    icon: Icons.notifications_none_rounded,
                                  ),
                                  title: A4MegCopy.a4_meg_varsler,
                                  subtitle: A4MegCopy.a4_meg_varsler_sub,
                                  count: _prefs?.notificationsUnseen ?? 0,
                                  onTap: _varsler,
                                ),
                                _MegRow(
                                  key: const Key('meg-rad-navn-liga'),
                                  leading: const _IconBox(
                                    icon: Icons.person_outline_rounded,
                                  ),
                                  title: A4MegCopy.a4_meg_navn_liga,
                                  subtitle:
                                      l?.optedIn == true &&
                                          (l?.displayName?.isNotEmpty ?? false)
                                      ? '${l!.displayName} · ${_synLabel(l.visibility)}'
                                      : A4MegCopy.a4_meg_navn_liga_ute,
                                  trailingText:
                                      l?.optedIn == true &&
                                          (l?.displayName?.isNotEmpty ?? false)
                                      ? null
                                      : A4MegCopy.a4_meg_velg_navn,
                                  trailingAccent: true,
                                  onTap: _ligaNavn,
                                ),
                                _MegRow(
                                  key: const Key('meg-rad-spraak'),
                                  leading: const _IconBox(
                                    icon: Icons.language_rounded,
                                  ),
                                  title: A4MegCopy.a4_meg_spraak,
                                  subtitle: lang,
                                  onTap: () => _push(
                                    const SelectLanguageAndCurrency(
                                      isFromHome: true,
                                    ),
                                  ),
                                ),
                                _MegRow(
                                  key: const Key('meg-rad-favoritter'),
                                  leading: const _IconBox(
                                    icon: Icons.favorite_rounded,
                                    color: Color(0xFFF08A7A),
                                  ),
                                  title: A4MegCopy.a4_meg_favoritter,
                                  count: _prefs?.favourites ?? 0,
                                  onTap: () => _go('/bergen/meg/favoritter'),
                                ),
                                _MegRow(
                                  key: const Key('meg-rad-nytt'),
                                  leading: const _IconBox(
                                    icon: Icons.article_outlined,
                                    color: BergenTokens.lantern,
                                  ),
                                  title: A4MegCopy.a4_meg_nytt,
                                  onTap: () => BergenRoutes.push(
                                    context,
                                    '/bergen/utforsk',
                                    arguments: const {'tab': 'feed'},
                                  ),
                                ),
                                _MegRow(
                                  key: const Key('meg-rad-hjelp'),
                                  leading: const _IconBox(
                                    icon: Icons.help_outline_rounded,
                                  ),
                                  title: A4MegCopy.a4_meg_hjelp,
                                  onTap: () => MegSheets.hjelp(
                                    context,
                                    onAegil: () => _go('/bergen/aegil'),
                                    onHuman: () => BergenRoutes.pushOr(
                                      context,
                                      '/bergen/kundeservice',
                                      orElse: () => _go('/bergen/aegil'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

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
  const _GullbillettCard({
    required this.give,
    required this.get,
    required this.onDel,
  });

  final int give;
  final int get;
  final VoidCallback onDel;

  @override
  Widget build(BuildContext context) {
    return MegShine(
      key: const Key('meg-gullbillett'),
      borderRadius: BorderRadius.circular(999),
      bandFraction: .28,
      opacity: .5,
      child: Container(
        padding: const EdgeInsets.fromLTRB(7, 6, 7, 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFDF4), Color(0xFFF6EFDC)],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: .95)),
          boxShadow: const [
            BoxShadow(color: Color(0xFFE7DCC0), offset: Offset(0, 1.5)),
            BoxShadow(
              color: Color.fromRGBO(150, 115, 25, .22),
              offset: Offset(0, 3),
            ),
            BoxShadow(
              color: Color.fromRGBO(120, 85, 10, .7),
              offset: Offset(0, 10),
              blurRadius: 16,
              spreadRadius: -11,
            ),
          ],
        ),
        child: Row(
          children: [
            const _TicketStub(width: 46, height: 32, animate: false),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    A4MegCopy.a4_meg_gullbilletten,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BergenTokens.display(
                      13,
                      weight: FontWeight.w800,
                      color: const Color(0xFF3A2708),
                      letterSpacingEm: -0.01,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    A4MegCopy.a4_meg_gi_faa(give, get),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BergenTokens.text(
                      10,
                      weight: FontWeight.w700,
                      color: const Color(0xFF8A6A2A),
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            MegPill(
              key: const Key('meg-del'),
              label: A4MegCopy.a4_meg_del,
              icon: Icons.ios_share_rounded,
              expand: false,
              height: 34,
              fontSize: 12.5,
              onPressed: onDel,
            ),
          ],
        ),
      ),
    );
  }
}

/// The small perforated gold ticket (design: 46×32, notches, dashed tear line,
/// the Æ mark, three printed lines, the shine sweep).
class _TicketStub extends StatelessWidget {
  const _TicketStub({
    required this.width,
    required this.height,
    this.radius = 8,
    this.animate = true,
  });

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
        gradient: const LinearGradient(
          begin: Alignment(-.7, -1),
          end: Alignment(.7, 1),
          colors: [Color(0xFFFFF6D8), Color(0xFFF2D591), Color(0xFFD9A93A)],
          stops: [0, .46, 1],
        ),
        border: Border.all(
          color: const Color(0xFFB4871E).withValues(alpha: .45),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(120, 85, 10, .75),
            offset: Offset(0, 5),
            blurRadius: 10,
            spreadRadius: -5,
          ),
        ],
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
                    colors: [
                      Colors.white.withValues(alpha: .9),
                      Colors.white.withValues(alpha: 0),
                      Colors.transparent,
                      const Color(0xFF785508).withValues(alpha: .24),
                    ],
                    stops: const [0, .08, .75, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              left: -4 * k,
              top: height / 2 - 4 * k,
              child: _notch(8 * k, const Color(0xFFFBF7EB)),
            ),
            Positioned(
              right: -4 * k,
              top: height / 2 - 4 * k,
              child: _notch(8 * k, const Color(0xFFF6EFDC)),
            ),
            Positioned(
              left: 28 * k,
              top: 4 * k,
              bottom: 4 * k,
              child: CustomPaint(
                size: Size(1.5, height - 8 * k),
                painter: _DashedLine(
                  color: const Color(0xFF785508).withValues(alpha: .45),
                ),
              ),
            ),
            Positioned(
              left: 3 * k,
              top: height / 2 - 9 * k,
              child: MegMark(
                color: const Color(0xFF5A4010),
                accent: const Color(0xFFC4491A),
                size: 22 * k,
              ),
            ),
            Positioned(left: 33 * k, top: 8 * k, child: _line(6 * k, .45)),
            Positioned(left: 33 * k, top: 14 * k, child: _line(6 * k, .3)),
            Positioned(left: 33 * k, top: 20 * k, child: _line(4 * k, .2)),
          ],
        ),
      ),
    );
    return animate
        ? MegShine(borderRadius: BorderRadius.circular(radius), child: body)
        : body;
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
      canvas.drawLine(
        Offset(0, y),
        Offset(0, (y + 2).clamp(0, size.height)),
        paint,
      );
      y += 4;
    }
  }

  @override
  bool shouldRepaint(_DashedLine old) => old.color != color;
}

/// "Premie: gratis levering" (design: the green-mint pill with the varde).
class _PremieChip extends StatelessWidget {
  const _PremieChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 3, 9, 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFF3F8F5F).withValues(alpha: .14),
        border: Border.all(
          color: const Color(0xFF3F8F5F).withValues(alpha: .45),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.landscape_rounded, size: 11, color: BergenTokens.mint),
          SizedBox(width: 4),
          Text(
            A4MegCopy.a4_meg_premie_levering,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: BergenTokens.mint,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: .16),
              Colors.white.withValues(alpha: .07),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: .26)),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(4, 18, 26, .8),
              offset: Offset(0, 10),
              blurRadius: 18,
              spreadRadius: -12,
            ),
          ],
        ),
        child: Icon(icon, color: BergenTokens.mint, size: 17),
      ),
    );
  }
}

/// A glass group of rows (design "Meg-rader" card).
class _Group extends StatelessWidget {
  const _Group({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final kids = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0)
        kids.add(const Divider(height: 1, color: BergenTokens.glassBorder));
      kids.add(children[i]);
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: .13),
            Colors.white.withValues(alpha: .06),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: .18)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(4, 18, 26, .9),
            offset: Offset(0, 18),
            blurRadius: 32,
            spreadRadius: -18,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Column(children: kids),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, this.color});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: (color ?? Colors.white).withValues(
          alpha: color == null ? .12 : .9,
        ),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(
        icon,
        size: 18,
        color: color == null ? const Color(0xFFEAF6F4) : Colors.white,
      ),
    );
  }
}

/// One Meg row: icon, title, subtitle, and a trailing text / badge / count.
class _MegRow extends StatelessWidget {
  const _MegRow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailingText,
    this.trailingAccent = false,
    this.badge,
    this.count,
    this.trailing,
    this.onTap,
    this.showChevron = true,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final bool trailingAccent;
  final String? badge;
  final int? count;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: BergenTokens.text(
                      BergenTokens.textBody,
                      weight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: BergenTokens.text(
                        12.5,
                        weight: FontWeight.w600,
                        color: A3Ink.sub,
                      ),
                    ),
                ],
              ),
            ),
            if (trailingText != null) ...[
              const SizedBox(width: 8),
              Flexible(
                flex: 2,
                child: Text(
                  trailingText!,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BergenTokens.text(
                    BergenTokens.textSmall,
                    weight: FontWeight.w800,
                    color: trailingAccent ? BergenTokens.mint : A3Ink.sub,
                  ),
                ),
              ),
            ],
            if (badge != null) ...[
              const SizedBox(width: 8),
              MegPill(
                label: badge!,
                expand: false,
                height: 38,
                fontSize: BergenTokens.textSmall,
                onPressed: onTap,
              ),
            ],
            if (count != null && count! > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: BergenTokens.mint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: BergenTokens.text(
                    BergenTokens.textMicro,
                    weight: FontWeight.w800,
                    color: BergenTokens.tealNight,
                  ),
                ),
              ),
            ],
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            if (showChevron && onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: A3Ink.muted),
            ],
          ],
        ),
      ),
    );
  }
}

/// UKENS OPPDRAG with Godta / Ikke dette, or the status once accepted.
class _MissionRow extends StatelessWidget {
  const _MissionRow({
    required this.mission,
    required this.onGodta,
    required this.onIkke,
  });

  final Mission mission;
  final VoidCallback onGodta;
  final VoidCallback onIkke;

  @override
  Widget build(BuildContext context) {
    final m = mission;
    return Padding(
      key: const Key('meg-rad-oppdrag'),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _IconBox(icon: Icons.flag_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      A4MegCopy.a4_meg_oppdrag,
                      style: BergenTokens.text(
                        BergenTokens.textMicro,
                        weight: FontWeight.w800,
                        color: A3Ink.muted,
                      ).copyWith(letterSpacing: 1.2),
                    ),
                    Text(
                      m.title,
                      style: BergenTokens.text(
                        BergenTokens.textBody,
                        weight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                A4MegCopy.a4_meg_pluss(m.points),
                style: BergenTokens.display(
                  BergenTokens.textSmall,
                  weight: FontWeight.w800,
                  color: BergenTokens.lantern,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (m.accepted || m.state == 'completed')
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Text(
                m.state == 'completed'
                    ? A4MegCopy.a4_meg_pluss(m.points)
                    : A4MegCopy.a4_meg_oppdrag_status(m.progress, m.target),
                key: const Key('meg-oppdrag-status'),
                style: BergenTokens.text(
                  BergenTokens.textMicro,
                  weight: FontWeight.w800,
                  color: BergenTokens.mint,
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: MegPill(
                    key: const Key('meg-godta'),
                    label: A4MegCopy.a4_meg_godta,
                    onPressed: onGodta,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: MegPillGhost(
                    key: const Key('meg-ikke-dette'),
                    label: A4MegCopy.a4_meg_ikke_dette,
                    onPressed: onIkke,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
