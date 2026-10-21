import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../data/aegil/aegil_app_models.dart';
import '../../../data/ops/tracking_models.dart';
import '../../../networking/feed/feed_repo.dart';
import '../../../networking/ops/cus_api.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../../../services/push_deep_link.dart';
import '../../../services/push_notification_service.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/auth/launch/lf_widgets.dart';
import '../../common/notifications/notifications_dl.dart';
import '../kit/bergen_perf.dart';
import '../kit/bergen_routes.dart';
import '../kit/bergen_toast.dart';
import '../kit/live_aerend.dart';
import 'hjem_harness.dart';
import '../meg/a3_services.dart';
import '../../common/notifications/notifications_repo.dart';
import 'package:aerend_customer/utils/route_names.dart';

// ── Varsler panel (Gap Step 1) ──────────────────────────────────────────────
// New Bergen `vsAapent` (L8524–8627, logic `apneVarsler` / `varslerVals`
// L16345–16470): the bell on Hjem opens a teal panel over Hjem with a
// summary, «Lukk», six filters, «PÅ VEI NÅ» while an order is under way, and
// the cards grouped by day.
//
// Customer Step 3 (gap Step 2): the cards come from the per-user inbox
// (`GET api/customer/notifications`: order status and notices, the courier's
// replies, Ægil, broadcasts) with read state (read after ~1 s on screen),
// swipe to «Ikke slike varsler» / «Fjern» with «Angre», the rich «Ny på
// Ærend» card and «Velg». While the inbox is off or unreachable the panel
// shows its older sources (broadcasts, Ægil's unseen actions) without those
// actions (gap plan G1/G2).

/// The broadcasts source (`mass-notification-list`); tests swap it. It lived
/// in the old Varsler page, removed in Gap Step 4.
typedef VarslerLoader = Future<List<MassNotificationItem>> Function();

Future<List<MassNotificationItem>> _defaultLoader() async {
  final json = await NotificationsRepo().callNotificationsApi(1, perPage: 30);
  return NotificationsPojo.fromJson(json).massNotificationList;
}

VarslerLoader varslerLoader = _defaultLoader;

abstract final class VarslerCopy {
  static const tittel = 'Varsler';
  static const lukk = 'Lukk';
  static const filtre = ['Alle', 'Bestillinger', 'Tilbud', 'Nytt i byen', 'Belønninger', 'Fra Ærend'];
  static const paaVei = 'PÅ VEI NÅ';
  static const visSporing = 'Vis sporing';
  static const iDag = 'I DAG', iGaar = 'I GÅR', tidligere = 'TIDLIGERE';
  static const tomTittel = 'Ingenting nytt siden sist';
  static const tomSub = 'Fin utsikt.';
  static const innstillinger = 'Innstillinger for varsler';
  static const fraAerend = 'Fra Ærend';
  static const aegil = 'Ægil';
  static const ikkeSlike = 'Ikke slike varsler';
  static const fjern = 'Fjern';
  static const angre = 'Angre';
  static const dempet = 'Skrudde av slike varsler';
  static const folg = 'Følg', folger = 'Følger', seMeny = 'Se meny';
  static String fjernet(String tittel) => 'Fjernet: $tittel';
  static const _ord = ['Ingenting', 'Én', 'To', 'Tre', 'Fire', 'Fem', 'Seks', 'Sju', 'Åtte', 'Ni'];
  static const _dager = ['Man', 'Tir', 'Ons', 'Tor', 'Fre', 'Lør', 'Søn'];
  static const _mnd = ['jan.', 'feb.', 'mars', 'apr.', 'mai', 'juni', 'juli', 'aug.', 'sep.', 'okt.', 'nov.', 'des.'];

  static String oppsummering(int n) => n == 0 ? 'Ingenting nytt siden sist.' : '${n < 10 ? _ord[n] : n} ting siden sist.';

  static String kommer(DateTime a, DateTime? b, {required bool henting}) => '${henting ? 'Klar' : 'Kommer'} ${_hm(a)}${b == null ? '' : '–${_hm(b)}'}';

  static String paaVeiLinje({String? bud, String? butikk, required String stadie}) {
    if (bud != null && bud.isNotEmpty && butikk != null && butikk.isNotEmpty) return '$bud er på vei fra $butikk';
    return [if (butikk != null && butikk.isNotEmpty) butikk, if (stadie.isNotEmpty) stadie].join(' · ');
  }

  static String _hm(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// The card's time: «17:44» today and yesterday, «Man 08:10» this week,
  /// «3. okt.» before that.
  static String tid(DateTime t, DateTime naa) {
    final d = _dag(naa).difference(_dag(t)).inDays;
    if (d <= 1) return _hm(t);
    if (d < 7) return '${_dager[t.weekday - 1]} ${_hm(t)}';
    return '${t.day}. ${_mnd[t.month - 1]}';
  }

  static DateTime _dag(DateTime t) => DateTime(t.year, t.month, t.day);

  /// 0 = I DAG, 1 = I GÅR, 2 = TIDLIGERE.
  static int gruppe(DateTime t, DateTime naa) {
    final d = _dag(naa).difference(_dag(t)).inDays;
    return d <= 0 ? 0 : (d == 1 ? 1 : 2);
  }
}

/// One card. [type] uses the design's kinds (`VST` / `VFILT`).
class Varsel {
  const Varsel({
    required this.id,
    required this.type,
    required this.tittel,
    this.grunn = '',
    required this.avs,
    required this.tid,
    this.ulest = false,
    this.lenke,
    this.key,
    this.muteKey,
    this.handling,
    this.rik = false,
    this.bilder = const [],
    this.storeId,
    this.orderId,
  });

  /// A card from the inbox (Customer Step 3).
  factory Varsel.fraInbox(CusVarsel c) => Varsel(
    id: c.key,
    key: c.key,
    type: c.type,
    muteKey: c.muteKey,
    tittel: c.title,
    grunn: c.body,
    avs: c.sender,
    tid: c.at,
    ulest: !c.read,
    lenke: c.deepLink,
    handling: c.action,
    rik: c.rich,
    bilder: c.photos,
    storeId: c.storeId,
    orderId: c.orderId,
  );

  final String id;
  final String type;
  final String tittel;
  final String grunn;
  final String avs;
  final DateTime tid;
  final bool ulest;

  /// A `/bergen/…` route or an `aerend://` link to open on tap.
  final String? lenke;

  /// The inbox key (`n:12`); null for the older sources (no swipe, no read).
  final String? key;

  /// What «Ikke slike varsler» mutes (defaults to [type]).
  final String? muteKey;

  /// A button on the card («Velg»).
  final String? handling;

  /// «Ny på Ærend»: [bilder] + «Følg» / «Se meny» for [storeId].
  final bool rik;
  final List<String> bilder;
  final int? storeId;
  final int? orderId;

  Varsel lest() => Varsel(
    id: id,
    type: type,
    tittel: tittel,
    grunn: grunn,
    avs: avs,
    tid: tid,
    lenke: lenke,
    key: key,
    muteKey: muteKey,
    handling: handling,
    rik: rik,
    bilder: bilder,
    storeId: storeId,
    orderId: orderId,
  );
}

/// The design's filter → kinds (`VFILT`, L16362).
const Map<String, List<String>> kVarselFilter = {
  'Bestillinger': ['ordre', 'valg', 'ai'],
  'Tilbud': ['tilbud', 'rytme', 'butikk'],
  'Nytt i byen': ['nybyen', 'nabolag'],
  'Belønninger': ['belonning', 'verving', 'liga', 'ukeshandel', 'agil'],
  'Fra Ærend': ['aerend', 'ai'],
};

/// The «PÅ VEI NÅ» card's data, from the order under way.
class VarselOrdre {
  const VarselOrdre({required this.orderId, required this.kode, required this.tittel, required this.linje});

  final int orderId;
  final String kode;
  final String tittel;
  final String linje;
}

/// Where the panel reads from; tests swap it.
class HjemVarslerKilde {
  const HjemVarslerKilde({
    required this.pushes,
    required this.aegil,
    required this.unseen,
    required this.markerSett,
    required this.ordre,
    this.inbox = _ingenInbox,
    this.antall = _ingenAntall,
    this.les = _ingenSvar,
    this.fjern = _ingenFjern,
    this.demp = _ingenDemp,
  });

  static Future<CusInbox?> _ingenInbox() async => null;
  static Future<int?> _ingenAntall() async => null;
  static Future<bool> _ingenSvar(String _) async => false;
  static Future<bool> _ingenFjern(String _, bool __) async => false;
  static Future<List<String>?> _ingenDemp(String _, bool __) async => null;

  /// The per-user inbox (Customer Step 3); null → the older sources.
  final Future<CusInbox?> Function() inbox;

  /// The bells' number from the inbox; null → the older count.
  final Future<int?> Function() antall;
  final Future<bool> Function(String key) les;

  /// «Fjern» / («Angre»: [angre] true).
  final Future<bool> Function(String key, bool angre) fjern;

  /// «Ikke slike varsler» ([av] true) / «Angre» ([av] false).
  final Future<List<String>?> Function(String muteKey, bool av) demp;

  final Future<List<MassNotificationItem>> Function() pushes;
  final Future<List<AwayItem>> Function() aegil;

  /// Broadcasts since `notifications_seen_at`, and that time.
  final Future<({int antall, DateTime? sett})> Function() unseen;
  final Future<void> Function() markerSett;
  final Future<VarselOrdre?> Function(int orderId) ordre;

  static HjemVarslerKilde standard() => HjemVarslerKilde(
    pushes: () => varslerLoader(),
    aegil: () => A3Services.aegil().away(),
    unseen: () async {
      final p = await A3Services.points().prefs();
      return (antall: p?.notificationsUnseen ?? 0, sett: p?.notificationsSeenAt);
    },
    markerSett: () async {
      await Future.wait([A3Services.points().updatePrefs(markNotificationsSeen: true), A3Services.aegil().awaySeen()]);
    },
    ordre: _ordreFraSporing,
    inbox: () => CusApi().varsler(limit: 50),
    antall: () => CusApi().varslerUleste(),
    les: (k) => CusApi().varselLest(k),
    fjern: (k, angre) => CusApi().varselFjern(k, angre: angre),
    demp: (k, av) async => CusApi().varselDemp(k, av: av),
  );

  static Future<VarselOrdre?> _ordreFraSporing(int orderId) async {
    final tr = OpsTracking.fromJson(await OpsCustomerApi().tracking(orderId));
    final start = tr.promisedStart ?? tr.promisedEnd;
    if (start == null) return null;
    final bud = tr.stage >= 2 ? tr.courier?.firstName : null;
    return VarselOrdre(
      orderId: orderId,
      kode: tr.code ?? '',
      tittel: VarslerCopy.kommer(start.toLocal(), tr.promisedStart == null ? null : tr.promisedEnd?.toLocal(), henting: tr.isPickup),
      linje: VarslerCopy.paaVeiLinje(bud: bud, butikk: tr.store?.name, stadie: tr.stageLabel),
    );
  }
}

abstract final class HjemVarsler {
  static HjemVarslerKilde kilde = HjemVarslerKilde.standard();

  /// The bell's count: broadcasts since last seen + Ægil's unseen actions.
  static final ValueNotifier<int> uleste = ValueNotifier<int>(0);

  @visibleForTesting
  static void reset() {
    kilde = HjemVarslerKilde.standard();
    uleste.value = 0;
  }

  static Future<void> oppdater() async {
    try {
      // The inbox's unread count when it is on; else broadcasts + Ægil.
      if (await kilde.antall().catchError((_) => null) case final n?) {
        uleste.value = n;
        return;
      }
      final r = await Future.wait([kilde.unseen(), kilde.aegil()]);
      uleste.value = (r[0] as ({int antall, DateTime? sett})).antall + (r[1] as List<AwayItem>).length;
    } catch (_) {}
  }

  /// Opens the panel over the current screen (`apneVarsler(filter)`).
  static Future<void> apne(BuildContext context, {String filter = 'Alle'}) async {
    final rolig = MediaQuery.maybeDisableAnimationsOf(context) == true;
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: false,
        settings: const RouteSettings(name: '${appRoutePrefix}bergen/varsler'),
        transitionDuration: Duration(milliseconds: rolig ? 0 : 440),
        reverseTransitionDuration: Duration(milliseconds: rolig ? 0 : 220),
        pageBuilder: (_, a, __) => VarslerPanel(filter: filter, inn: a),
      ),
    );
    unawaited(oppdater());
  }
}

/// The panel. [inn] is the route animation (backdrop `skjermInn .26s`, panel
/// `arkOpp .44s cubic(.2,.9,.3,1)`).
class VarslerPanel extends StatefulWidget {
  const VarslerPanel({super.key, this.filter = 'Alle', this.inn, this.naa});

  final String filter;
  final Animation<double>? inn;

  /// Tests pin the clock.
  final DateTime? naa;

  @override
  State<VarslerPanel> createState() => _VarslerPanelState();
}

class _VarslerPanelState extends State<VarslerPanel> {
  late String _filter = VarslerCopy.filtre.contains(widget.filter) ? widget.filter : 'Alle';
  List<Varsel> _alle = const [];
  VarselOrdre? _ordre;
  bool _lastet = false;

  /// The cards came from the inbox (read, swipe, remove, mute work).
  bool _inbox = false;

  /// The open card (swiped to −166) and the toast with «Angre».
  String? _aap;
  ({String tekst, VoidCallback angre})? _bekreft;
  Timer? _bekreftT;

  /// Read-on-view: a card counts as seen after two 500 ms ticks on screen.
  final Map<String, GlobalKey> _kortNokler = {};
  final Map<String, int> _sett = {};
  final GlobalKey _listeNokkel = GlobalKey();
  Timer? _lesT;

  /// Stores followed from a «Ny på Ærend» card.
  final Set<int> _folger = {};

  @override
  void initState() {
    super.initState();
    _last();
  }

  @override
  void dispose() {
    _lesT?.cancel();
    _bekreftT?.cancel();
    super.dispose();
  }

  Future<void> _last() async {
    final k = HjemVarsler.kilde;
    final live = hjemLiveOrdre.value;
    final ordre = live == null ? Future<VarselOrdre?>.value() : k.ordre(live.orderId).catchError((_) => null);
    final inbox = await k.inbox().catchError((_) => null);
    if (inbox != null) {
      final o = await ordre;
      if (!mounted) return;
      setState(() {
        _alle = [for (final c in inbox.items) Varsel.fraInbox(c)];
        _ordre = o;
        _inbox = true;
        _lastet = true;
      });
      HjemVarsler.uleste.value = inbox.unread;
      _lesT = Timer.periodic(const Duration(milliseconds: 500), (_) => _lesSynlige());
      _harness();
      unawaited(k.markerSett().catchError((_) {}));
      return;
    }
    final r = await Future.wait<Object?>([
      k.pushes().catchError((_) => const <MassNotificationItem>[]),
      k.aegil().catchError((_) => const <AwayItem>[]),
      k.unseen().catchError((_) => (antall: 0, sett: null)),
      ordre,
    ]);
    if (!mounted) return;
    final pushes = r[0] as List<MassNotificationItem>;
    final away = r[1] as List<AwayItem>;
    final sett = (r[2] as ({int antall, DateTime? sett})).sett;
    final naa = widget.naa ?? DateTime.now();
    final liste = <Varsel>[
      for (final n in pushes)
        if (DateTime.tryParse(n.datetime) case final t?)
          Varsel(id: 'p${n.id}', type: 'aerend', tittel: n.title, grunn: n.message, avs: VarslerCopy.fraAerend, tid: t, ulest: sett == null || t.isAfter(sett)),
      for (final a in away) Varsel(id: 'a${a.id}', type: 'agil', tittel: a.text, avs: VarslerCopy.aegil, tid: a.at ?? naa, ulest: true, lenke: a.deepLink),
    ]..sort((x, y) => y.tid.compareTo(x.tid));
    setState(() {
      _alle = liste;
      _ordre = r[3] as VarselOrdre?;
      _lastet = true;
    });
    // Opening Varsler counts as seeing them (the older sources have one
    // «seen» time, not per card).
    unawaited(k.markerSett().catchError((_) {}));
  }

  /// Debug harness (`kunde_state.json`): a card swiped open, or removed.
  void _harness() {
    if (!kDebugMode) return;
    final kort = _alle.where((v) => v.key != null).toList();
    if (HjemHarness.varslerSveip case final i? when i < kort.length) setState(() => _aap = kort[i].key);
    if (HjemHarness.varslerFjern case final i? when i < kort.length) _fjern(kort[i], varighet: const Duration(seconds: 30));
  }

  /// `apneVarsler`'s 500 ms check: a card at least 12 px inside the list for
  /// two ticks in a row is read.
  void _lesSynlige() {
    final liste = _listeNokkel.currentContext?.findRenderObject() as RenderBox?;
    if (!mounted || liste == null || !liste.hasSize) return;
    final top = liste.localToGlobal(Offset.zero).dy, bunn = top + liste.size.height;
    final nye = <String>[];
    for (final v in _alle) {
      final key = v.key;
      if (key == null || !v.ulest) continue;
      final box = _kortNokler[key]?.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached || !box.hasSize) continue;
      final y = box.localToGlobal(Offset.zero).dy;
      if (y < bunn - 12 && y + box.size.height > top + 12) {
        _sett[key] = (_sett[key] ?? 0) + 1;
        if (_sett[key] == 2) nye.add(key);
      } else {
        _sett[key] = 0;
      }
    }
    if (nye.isEmpty) return;
    setState(() => _alle = [for (final v in _alle) nye.contains(v.key) ? v.lest() : v]);
    HjemVarsler.uleste.value = _alle.where((v) => v.ulest).length;
    for (final key in nye) {
      unawaited(HjemVarsler.kilde.les(key).catchError((_) => false));
    }
  }

  void _visBekreftelse(String tekst, VoidCallback angre, {Duration varighet = const Duration(seconds: 5)}) {
    _bekreftT?.cancel();
    setState(() => _bekreft = (tekst: tekst, angre: angre));
    _bekreftT = Timer(varighet, () => mounted ? setState(() => _bekreft = null) : null);
  }

  /// «Fjern» (`vsFjernet`), with «Angre».
  void _fjern(Varsel v, {Duration varighet = const Duration(seconds: 5)}) {
    final key = v.key;
    if (key == null) return;
    final i = _alle.indexOf(v);
    setState(() {
      _alle = [..._alle]..remove(v);
      _aap = null;
    });
    unawaited(HjemVarsler.kilde.fjern(key, false).catchError((_) => false));
    _visBekreftelse(varighet: varighet, VarslerCopy.fjernet(v.tittel), () {
      _bekreftT?.cancel();
      setState(() {
        _alle = [..._alle]..insert(i.clamp(0, _alle.length), v);
        _bekreft = null;
      });
      unawaited(HjemVarsler.kilde.fjern(key, true).catchError((_) => false));
    });
  }

  /// «Ikke slike varsler» (`vsDempet`): the kind goes, here and on the phone.
  void _demp(Varsel v) {
    final mute = v.muteKey ?? v.type;
    final bort = _alle.where((x) => (x.muteKey ?? x.type) == mute).toList();
    final for_ = _alle;
    setState(() {
      _alle = _alle.where((x) => (x.muteKey ?? x.type) != mute).toList();
      _aap = null;
    });
    unawaited(HjemVarsler.kilde.demp(mute, true).catchError((_) => null));
    _visBekreftelse(VarslerCopy.dempet, () {
      _bekreftT?.cancel();
      setState(() {
        _alle = [for (final x in for_) if (bort.contains(x) || _alle.contains(x)) x];
        _bekreft = null;
      });
      unawaited(HjemVarsler.kilde.demp(mute, false).catchError((_) => null));
    });
  }

  Future<void> _folg(Varsel v) async {
    final id = v.storeId;
    if (id == null) return;
    final pa = _folger.contains(id);
    setState(() => pa ? _folger.remove(id) : _folger.add(id));
    try {
      if (pa) {
        await FeedRepo().unfollowStore('$id');
      } else {
        await FeedRepo().followStore('$id');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => pa ? _folger.add(id) : _folger.remove(id));
      showBergenToast(context, BergenRoutes.ikkeSendt);
    }
  }

  void _lukk() => Navigator.of(context).maybePop();

  /// Where a card goes (`vsMaal`): its link, else by kind.
  void _apneKort(Varsel v) {
    if (_aap != null) {
      setState(() => _aap = null);
      return;
    }
    final lenke = v.lenke;
    _lukk();
    if (lenke != null && lenke.startsWith('/bergen/')) {
      BergenRoutes.push<void>(context, lenke);
      return;
    }
    if (lenke != null && lenke.startsWith(PushDeepLink.scheme)) {
      if (PushDeepLink.fromLink(lenke) case final r?) {
        PushNotificationService.openPushRoute(r);
        return;
      }
    }
    final rute = switch (v.type) {
      'ordre' || 'valg' || 'ai' => v.orderId == null ? null : '/bergen/sporing/${v.orderId}',
      'tilbud' => '/bergen/aegil',
      'nybyen' => v.storeId == null ? null : '/bergen/butikk/${v.storeId}',
      'belonning' || 'verving' || 'liga' => '/bergen/meg',
      'ukeshandel' || 'agil' => '/bergen/kurv',
      _ => null,
    };
    if (rute != null) BergenRoutes.pushOr(context, rute, orElse: () {});
  }

  void _handling(Varsel v) {
    if (v.orderId != null) {
      _tilSporing(v.orderId!);
    } else {
      _apneKort(v);
    }
  }

  void _seMeny(Varsel v) {
    _lukk();
    if (v.storeId != null) BergenRoutes.pushOr(context, '/bergen/butikk/${v.storeId}', orElse: () {});
  }

  void _tilSporing(int id) {
    _lukk();
    BergenRoutes.push<dynamic>(context, '/bergen/sporing/$id');
  }

  void _innstillinger() {
    _lukk();
    BergenRoutes.push<void>(context, '/bergen/aegil/nivaa');
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final s = mq.size.width / 390;
    final h = mq.size.height / s;
    final topp = (mq.padding.top / s).clamp(48.0, 80.0);
    final bunn = mq.padding.bottom / s;
    final a = widget.inn ?? const AlwaysStoppedAnimation<double>(1);
    final naa = widget.naa ?? DateTime.now();

    final synlig = _alle.where((v) => _filter == 'Alle' || (kVarselFilter[_filter] ?? const []).contains(v.type)).toList();
    final n = _alle.where((v) => v.ulest).length;
    final visOrdre = _ordre != null && (_filter == 'Alle' || _filter == 'Bestillinger');

    return Material(
      type: MaterialType.transparency,
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.fitWidth,
          alignment: Alignment.topCenter,
          child: MediaQuery(
            data: mq.copyWith(size: Size(390, h), padding: EdgeInsets.zero, viewPadding: EdgeInsets.zero, devicePixelRatio: mq.devicePixelRatio * s),
            child: SizedBox(
              width: 390,
              height: h,
              child: AnimatedBuilder(
                animation: a,
                builder: (context, _) {
                  // Backdrop: skjermInn .26s ease-out of the .44s route.
                  final tb = Curves.easeOut.transform((a.value * 440 / 260).clamp(0.0, 1.0));
                  final tp = const Cubic(.2, .9, .3, 1).transform(a.value);
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: _lukk,
                          child: Opacity(
                            opacity: tb,
                            child: BackdropFilter(
                              enabled: BergenPerf.blurOn(context),
                              filter: BergenPerf.blur(context, 2),
                              child: const ColoredBox(color: Color.fromRGBO(15, 31, 43, .42)),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: topp,
                        bottom: 0,
                        child: Opacity(
                          opacity: .6 + .4 * tp,
                          child: Transform.translate(offset: Offset(0, 26 * (1 - tp)), child: _panel(context, synlig, n, visOrdre, bunn, naa)),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _panel(BuildContext context, List<Varsel> synlig, int n, bool visOrdre, double bunn, DateTime naa) {
    final grupper = <int, List<Varsel>>{};
    for (final v in synlig) {
      grupper.putIfAbsent(VarslerCopy.gruppe(v.tid, naa), () => []).add(v);
    }
    const navn = [VarslerCopy.iDag, VarslerCopy.iGaar, VarslerCopy.tidligere];
    final tomt = _lastet && synlig.isEmpty;

    return CssBox(
      key: const Key('varsler-panel'),
      radius: const BorderRadius.vertical(top: Radius.circular(30)),
      clip: true,
      bg: const [
        CssRadial([Color.fromRGBO(255, 255, 255, .18), Color.fromRGBO(255, 255, 255, 0)], stops: [0, .6], rx: .8, ry: .5, cx: .14, cy: 0),
        CssLinear(180, [Color(0xFF2A6272), Color(0xFF1E4F5C), Color(0xFF173E48)], [0, .42, 1]),
      ],
      shadows: const [CssShadow(0, -26, 50, -22, Color.fromRGBO(4, 18, 26, .9))],
      child: Stack(
        children: [
          // ── Header (96 px) ─────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 96,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 9,
                  child: Center(
                    child: GestureDetector(
                      onTap: _lukk,
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(color: const Color.fromRGBO(255, 255, 255, .4), borderRadius: BorderRadius.circular(3)),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  top: 30,
                  right: 118,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(VarslerCopy.tittel, style: jakarta(22, em: -.025, height: 1.05)),
                      const SizedBox(height: 4),
                      Text(
                        _lastet ? VarslerCopy.oppsummering(n) : ' ',
                        key: const Key('varsler-oppsummering'),
                        style: inter(11.5, weight: FontWeight.w700, color: const Color(0xFF9FD3DE)),
                      ),
                    ],
                  ),
                ),
                Positioned(top: 32, right: 16, child: _LukkKnapp(onTap: _lukk)),
              ],
            ),
          ),
          // ── Filters ─────────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            top: 96,
            height: 50,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final f in VarslerCopy.filtre) ...[
                    _Filter(key: Key('varsler-filter-$f'), tekst: f, valgt: f == _filter, onTap: () => setState(() => _filter = f)),
                    if (f != VarslerCopy.filtre.last) const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
          ),
          // ── List ────────────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            top: 146,
            bottom: 0,
            child: KeyedSubtree(
              key: _listeNokkel,
              child: ListView(
              key: const Key('varsler-liste'),
              padding: EdgeInsets.fromLTRB(16, 4, 16, 96 + bunn),
              children: [
                if (visOrdre) _PaaVeiKort(ordre: _ordre!, onTap: () => _tilSporing(_ordre!.orderId)),
                for (final g in [0, 1, 2])
                  if (grupper[g] case final del?) ...[
                    _Overskrift(navn[g]),
                    for (final v in del)
                      _SveipKort(
                        key: _kortNokler.putIfAbsent(v.key ?? v.id, GlobalKey.new),
                        aapen: _aap == v.key,
                        kanSveipe: _inbox && v.key != null,
                        onAapen: (a) => setState(() => _aap = a ? v.key : null),
                        onDemp: () => _demp(v),
                        onFjern: () => _fjern(v),
                        child: _Kort(
                          key: Key('varsel-${v.id}'),
                          v: v,
                          naa: naa,
                          onTap: () => _apneKort(v),
                          onHandling: () => _handling(v),
                          folger: v.storeId != null && _folger.contains(v.storeId),
                          onFolg: () => _folg(v),
                          onSeMeny: () => _seMeny(v),
                        ),
                      ),
                  ],
                if (tomt) const _Tomt(),
              ],
            ),
            ),
          ),
          // ── Footer ──────────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 18 + bunn),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color.fromRGBO(23, 62, 72, 0), Color(0xFF173E48)],
                  stops: [0, .42],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_bekreft case final b?) ...[_Bekreftelse(key: ValueKey(b.tekst), tekst: b.tekst, onAngre: b.angre), const SizedBox(height: 9)],
                  _Innstillinger(onTap: _innstillinger),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Parts ───────────────────────────────────────────────────────────────────

const _hvitGlass = [
  CssLinear(180, [Color.fromRGBO(255, 255, 255, .18), Color.fromRGBO(255, 255, 255, .08)]),
];
const _hvitSkygge = [CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .28)), CssShadow(0, 3, 0, 0, Color.fromRGBO(4, 18, 26, .4))];
const _oransje = [
  CssLinear(180, [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], [0, .56, 1]),
];
const _oransjeSkygge = [
  CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .45)),
  CssShadow(0, 3, 0, 0, Color.fromRGBO(160, 60, 20, .55)),
  CssShadow(0, 10, 18, -8, Color.fromRGBO(242, 109, 61, .8)),
];

const _kPil =
    '<svg viewBox="0 0 24 24" fill="none" stroke="#FFF" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 6l6 6-6 6"/></svg>';

Widget _pil(Color c, [double size = 13]) => SvgPicture.string(_kPil, width: size, height: size, colorFilter: ColorFilter.mode(c, BlendMode.srcIn));

/// Glass behind a card: `backdrop-filter: blur(20px)` (full tier only).
Widget _glass(BuildContext context, double r, Widget child) {
  if (!BergenPerf.blurOn(context, secondary: true)) return child;
  return ClipRRect(
    borderRadius: BorderRadius.circular(r),
    child: BackdropFilter(filter: BergenPerf.blur(context, 10), child: child),
  );
}

class _LukkKnapp extends StatelessWidget {
  const _LukkKnapp({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LfPress(
    key: const Key('varsler-lukk'),
    scale: .94,
    onTap: onTap,
    child: CssBox(
      radius: BorderRadius.circular(999),
      bg: _hvitGlass,
      border: Border.all(color: const Color.fromRGBO(255, 255, 255, .25)),
      shadows: _hvitSkygge,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 13),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(VarslerCopy.lukk, style: inter(11.5, weight: FontWeight.w800)),
          const SizedBox(width: 5),
          SvgPicture.string(
            '<svg viewBox="0 0 24 24" fill="none" stroke="#FFF" stroke-width="2.6" stroke-linecap="round"><path d="M6 6l12 12M18 6L6 18"/></svg>',
            width: 11,
            height: 11,
          ),
        ],
      ),
    ),
  );
}

class _Filter extends StatelessWidget {
  const _Filter({super.key, required this.tekst, required this.valgt, required this.onTap});

  final String tekst;
  final bool valgt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LfPress(
    scale: .95,
    onTap: onTap,
    child: CssBox(
      radius: BorderRadius.circular(999),
      bg: valgt
          ? _oransje
          : const [
              CssLinear(180, [Color.fromRGBO(255, 255, 255, .16), Color.fromRGBO(255, 255, 255, .07)]),
            ],
      border: Border.all(color: Color.fromRGBO(255, 255, 255, valgt ? .3 : .2)),
      shadows: valgt
          ? _oransjeSkygge
          : const [CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .25)), CssShadow(0, 3, 0, 0, Color.fromRGBO(4, 18, 26, .35))],
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 13),
      child: Text(
        tekst,
        style: inter(11.5, weight: FontWeight.w800, color: valgt ? Colors.white : const Color.fromRGBO(255, 255, 255, .75)),
      ),
    ),
  );
}

class _PaaVeiKort extends StatelessWidget {
  const _PaaVeiKort({required this.ordre, required this.onTap});

  final VarselOrdre ordre;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: LfPress(
      key: const Key('varsler-paa-vei'),
      scale: .99,
      onTap: onTap,
      child: _glass(
        context,
        20,
        CssBox(
          radius: BorderRadius.circular(20),
          clip: true,
          bg: const [
            CssLinear(160, [Color.fromRGBO(92, 224, 184, .22), Color.fromRGBO(92, 224, 184, .08)]),
          ],
          border: Border.all(color: const Color.fromRGBO(92, 224, 184, .45)),
          shadows: const [CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .3)), CssShadow(0, 16, 26, -16, Color.fromRGBO(4, 18, 26, .9))],
          child: Stack(
            children: [
              const Positioned(
                right: -20,
                top: -30,
                width: 120,
                height: 120,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [Color.fromRGBO(255, 255, 255, .16), Color.fromRGBO(255, 255, 255, 0)], stops: [0, .7]),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // `glod 1.6s ease-in-out infinite` (opacity .7 ↔ 1).
                        LfLoop(
                          frozenMs: 800,
                          builder: (context, t, child) {
                            final p = (t % 1600) / 1600;
                            final e = Curves.easeInOut.transform(p < .5 ? p * 2 : (1 - p) * 2);
                            return Opacity(opacity: .7 + .3 * e, child: child);
                          },
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF5CE0B8),
                              boxShadow: [BoxShadow(color: Color.fromRGBO(92, 224, 184, .9), blurRadius: 8)],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          VarslerCopy.paaVei,
                          style: inter(9.5, weight: FontWeight.w800, em: .1, color: const Color(0xFF9FD9CC)),
                        ),
                        const Spacer(),
                        Text(
                          ordre.kode,
                          style: inter(
                            10.5,
                            weight: FontWeight.w800,
                            color: const Color(0xFFDCE9EC),
                          ).copyWith(fontFeatures: const [ui.FontFeature.tabularFigures()]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(ordre.tittel, style: jakarta(16, em: -.02)),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ordre.linje,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: inter(11, weight: FontWeight.w700, color: const Color(0xFFB9CBD5)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        CssBox(
                          radius: BorderRadius.circular(999),
                          bg: _oransje,
                          border: Border.all(color: const Color.fromRGBO(255, 255, 255, .3)),
                          shadows: _oransjeSkygge,
                          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
                          child: Text(VarslerCopy.visSporing, style: inter(11.5, weight: FontWeight.w800)),
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

class _Overskrift extends StatelessWidget {
  const _Overskrift(this.tekst);

  final String tekst;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 15, bottom: 9),
    child: Row(
      children: [
        Text(
          tekst,
          style: inter(9.5, weight: FontWeight.w800, em: .12, color: const Color.fromRGBO(255, 255, 255, .55)),
        ),
        const SizedBox(width: 9),
        const Expanded(
          child: SizedBox(height: 1, child: ColoredBox(color: Color.fromRGBO(255, 255, 255, .14))),
        ),
      ],
    ),
  );
}

/// The design's kind → tile colour, icon and tilt (`VST`, L16363).
const Map<String, (Color, String, double)> _kVst = {
  'nybyen': (Color(0xFFF2C14E), 'Lykt', -4),
  'nabolag': (Color(0xFFA9CDB6), 'Lykt', 3),
  'tilbud': (Color(0xFFF26D3D), 'Tag', -3),
  'butikk': (Color(0xFFC99B62), 'Tag', 3),
  'rytme': (Color(0xFF7FB4C4), 'Tag', -2),
  'ordre': (Color(0xFF1E4F5C), 'Ordre', 2),
  'valg': (Color(0xFFE0913A), 'Ordre', -3),
  'belonning': (Color(0xFFF0A86A), 'Varde', 3),
  'liga': (Color(0xFF8FBF9F), 'Varde', -3),
  'verving': (Color(0xFF7FB4C4), 'Baat', 2),
  'ukeshandel': (Color(0xFFA9CDB6), 'Baat', -2),
  'agil': (Color(0xFFC7B8E8), 'Aegil', 3),
  'aerend': (Color(0xFFDCE9EC), 'Merke', -2),
};

const Map<String, String> _kIkon = {
  'Lykt':
      '<svg viewBox="0 0 24 26" fill="none" stroke="#3A3128" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M8 3h8"/><rect x="6" y="6" width="12" height="13" rx="3"/><path d="M12 9.5v6"/><path d="M9.5 22h5"/></svg>',
  'Tag':
      '<svg viewBox="0 0 24 24" fill="none" stroke="#FFF" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20.5 12.5l-8 8-9-9V3.5H11z"/><circle cx="7.8" cy="7.8" r="1.4"/></svg>',
  'Ordre':
      '<svg viewBox="0 0 24 24" fill="none" stroke="#FFF" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 17c2.5 2 4.5 2 7 0s4.5-2 7 0 4 1.6 4 1.6"/><path d="M5 14l1.5-6h11L19 14"/><path d="M12 8V4.5"/></svg>',
  'Varde':
      '<svg viewBox="0 0 24 24" fill="none" stroke="#4A2E14" stroke-width="1.9" stroke-linejoin="round"><path d="M9.5 5.5h5l1 3h-7z"/><path d="M7.5 10h9l1.2 3.6H6.3z"/><path d="M5.5 15.5h13L20 19.5H4z"/></svg>',
  'Baat':
      '<svg viewBox="0 0 24 24" fill="none" stroke="#0F3542" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M4 15h16l-2.5 4.5h-11z"/><path d="M12 14V4l6 8z"/></svg>',
  // `#gevir` in #3A2E5C.
  'Aegil':
      '<svg viewBox="0 0 40 24"><path d="M14 22 L9 12 L4 4 M9 12 L14 5 M26 22 L31 12 L36 4 M31 12 L26 5 M14 22 L20 19 L26 22" fill="none" stroke="#3A2E5C" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/></svg>',
  // `#merke-flat`.
  'Merke':
      '<svg viewBox="-30 -14 172 138"><g transform="rotate(-5 60 53)"><path d="M14 90 L60 16 V90 M34 58 H60 M62 16 H104 M62 53 H96 M62 90 H104" fill="none" stroke="#FFFFFF" stroke-width="25" stroke-linecap="round" stroke-linejoin="round"/><path d="M-14 60 H8 M-8 76 H4" fill="none" stroke="#FFFFFF" stroke-width="16" stroke-linecap="round"/><path d="M14 90 L60 16 V90 M34 58 H60 M62 16 H104 M62 53 H96 M62 90 H104" fill="none" stroke="#3A7D8C" stroke-width="15" stroke-linecap="round" stroke-linejoin="round"/><path d="M-14 60 H8 M-8 76 H4" fill="none" stroke="#F26D3D" stroke-width="6.5" stroke-linecap="round"/></g></svg>',
};

const Map<String, Size> _kIkonStr = {
  'Lykt': Size(15, 16),
  'Tag': Size(16, 16),
  'Ordre': Size(17, 17),
  'Varde': Size(16, 16),
  'Baat': Size(17, 17),
  'Aegil': Size(18, 11),
  'Merke': Size(20, 16),
};

class _Kort extends StatelessWidget {
  const _Kort({super.key, required this.v, required this.naa, required this.onTap, this.onHandling, this.folger = false, this.onFolg, this.onSeMeny});

  final Varsel v;
  final DateTime naa;
  final VoidCallback onTap;
  final VoidCallback? onHandling, onFolg, onSeMeny;
  final bool folger;

  @override
  Widget build(BuildContext context) {
    final (stBg, ik, rot) = _kVst[v.type] ?? (const Color(0xFFDCE9EC), 'Merke', 0.0);
    final fjord = v.type == 'aerend';
    final mFg = fjord ? const Color(0xFF9FE0C8) : const Color(0xFF9FD3DE);
    final str = _kIkonStr[ik]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: LfPress(
        scale: .99,
        onTap: onTap,
        child: _glass(
          context,
          20,
          CssBox(
            radius: BorderRadius.circular(20),
            bg: fjord
                ? const [
                    CssLinear(160, [Color.fromRGBO(92, 224, 184, .2), Color.fromRGBO(92, 224, 184, .07)]),
                  ]
                : const [
                    CssLinear(180, [Color.fromRGBO(255, 255, 255, .14), Color.fromRGBO(255, 255, 255, .06)]),
                  ],
            border: Border.all(color: fjord ? const Color.fromRGBO(92, 224, 184, .45) : const Color.fromRGBO(255, 255, 255, .2)),
            shadows: const [
              CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .26)),
              CssShadow(0, 2, 0, 0, Color.fromRGBO(4, 18, 26, .25)),
              CssShadow(0, 16, 26, -18, Color.fromRGBO(4, 18, 26, .9)),
            ],
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.rotate(
                  angle: rot * 3.14159265 / 180,
                  child: CssBox(
                    width: 34,
                    height: 34,
                    radius: BorderRadius.circular(12),
                    bg: [CssSolid(stBg)],
                    shadows: const [
                      CssShadow(0, 0, 0, 2, Color.fromRGBO(255, 255, 255, .9)),
                      CssShadow(0, 3, 0, 2, Color.fromRGBO(4, 18, 26, .3)),
                      CssShadow(0, 8, 12, -6, Color.fromRGBO(4, 18, 26, .7)),
                    ],
                    child: Center(
                      child: SvgPicture.string(_kIkon[ik]!, width: str.width, height: str.height),
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.tittel, style: inter(13.5, weight: FontWeight.w800, em: -.01, height: 1.25)),
                      if (v.grunn.isNotEmpty) ...[const SizedBox(height: 3), Text(v.grunn, style: inter(11.5, height: 1.4, color: const Color(0xFFDCE9EC)))],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            v.avs,
                            style: inter(10, weight: FontWeight.w700, color: mFg),
                          ),
                          const SizedBox(width: 6),
                          Opacity(
                            opacity: .6,
                            child: Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: mFg),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            VarslerCopy.tid(v.tid, naa),
                            style: inter(10, weight: FontWeight.w700, color: mFg),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  height: v.handling != null ? 44 : 34 + 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (v.ulest) ...[
                        Container(
                          key: const Key('varsel-ulest'),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFF26D3D),
                            boxShadow: [BoxShadow(color: Color.fromRGBO(242, 109, 61, .9), blurRadius: 8)],
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (v.handling case final h?)
                        _Handling(tekst: h, oransje: v.type == 'valg', onTap: onHandling ?? onTap)
                      else if (!v.rik)
                        _pil(mFg),
                    ],
                  ),
                ),
              ],
            ),
            if (v.rik) ...[
              const SizedBox(height: 11),
              _Bilder(urls: v.bilder),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _RikKnapp(key: const Key('varsel-folg'), tekst: folger ? VarslerCopy.folger : VarslerCopy.folg, oransje: folger, onTap: onFolg ?? () {}),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RikKnapp(key: const Key('varsel-se-meny'), tekst: VarslerCopy.seMeny, onTap: onSeMeny ?? onTap),
                  ),
                ],
              ),
            ],
          ],
          ),
          ),
        ),
      ),
    );
  }
}

class _Tomt extends StatelessWidget {
  const _Tomt();

  @override
  Widget build(BuildContext context) => Padding(
    key: const Key('varsler-tom'),
    padding: const EdgeInsets.fromLTRB(20, 34, 20, 0),
    child: Column(
      children: [
        Image.asset('assets/images/dashboard/rear.png', width: 74),
        const SizedBox(height: 12),
        Text(VarslerCopy.tomTittel, textAlign: TextAlign.center, style: jakarta(16)),
        const SizedBox(height: 4),
        Text(
          VarslerCopy.tomSub,
          textAlign: TextAlign.center,
          style: inter(12, color: const Color(0xFF9FD3DE)),
        ),
      ],
    ),
  );
}

class _Innstillinger extends StatelessWidget {
  const _Innstillinger({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LfPress(
    key: const Key('varsler-innstillinger'),
    scale: .99,
    onTap: onTap,
    child: _glass(
      context,
      16,
      CssBox(
        radius: BorderRadius.circular(16),
        bg: const [
          CssLinear(180, [Color.fromRGBO(255, 255, 255, .16), Color.fromRGBO(255, 255, 255, .07)]),
        ],
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, .22)),
        shadows: const [
          CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .28)),
          CssShadow(0, 3, 0, 0, Color.fromRGBO(4, 18, 26, .4)),
          CssShadow(0, 12, 20, -14, Color.fromRGBO(4, 18, 26, .9)),
        ],
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        child: Row(
          children: [
            SvgPicture.string(
              '<svg viewBox="0 0 24 24" fill="none" stroke="#5CE0B8" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.6 1.6 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.6 1.6 0 0 0-2.7 1.1V21a2 2 0 1 1-4 0v-.1A1.6 1.6 0 0 0 7.9 19l-.1.1A2 2 0 1 1 5 16.3l.1-.1a1.6 1.6 0 0 0-1.1-2.7H3a2 2 0 1 1 0-4h.1A1.6 1.6 0 0 0 5 7.9L4.9 7.8A2 2 0 1 1 7.7 5l.1.1a1.6 1.6 0 0 0 2.7-1.1V3a2 2 0 1 1 4 0v.1a1.6 1.6 0 0 0 2.7 1.1l.1-.1A2 2 0 1 1 20.1 7l-.1.1a1.6 1.6 0 0 0-.3 1.8"/></svg>',
              width: 15,
              height: 15,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(VarslerCopy.innstillinger, style: inter(12.5, weight: FontWeight.w800)),
            ),
            _pil(const Color.fromRGBO(255, 255, 255, .55)),
          ],
        ),
      ),
    ),
  );
}

// ── Customer Step 3: swipe, toast, actions ─────────────────────────────────

/// A card that swipes left to −166 px (`vsAap`) over «Ikke slike varsler»
/// (92 px) and «Fjern» (74 px); let go past −70 to keep it open.
class _SveipKort extends StatefulWidget {
  const _SveipKort({
    super.key,
    required this.child,
    required this.aapen,
    required this.kanSveipe,
    required this.onAapen,
    required this.onDemp,
    required this.onFjern,
  });

  final Widget child;
  final bool aapen, kanSveipe;
  final ValueChanged<bool> onAapen;
  final VoidCallback onDemp, onFjern;

  @override
  State<_SveipKort> createState() => _SveipKortState();
}

class _SveipKortState extends State<_SveipKort> {
  static const double _bredde = 166;
  double? _drag;

  @override
  Widget build(BuildContext context) {
    if (!widget.kanSveipe) return widget.child;
    final base = widget.aapen ? -_bredde : 0.0;
    final dx = _drag ?? base;
    final bak = dx < -2;
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: 9,
          child: IgnorePointer(
            ignoring: !bak,
            child: AnimatedOpacity(
              opacity: bak ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      key: const Key('varsel-demp'),
                      onTap: widget.onDemp,
                      child: Container(
                        width: 92,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        color: const Color.fromRGBO(255, 255, 255, .14),
                        child: Text(VarslerCopy.ikkeSlike, textAlign: TextAlign.center, style: inter(10, weight: FontWeight.w800, height: 1.25)),
                      ),
                    ),
                    GestureDetector(
                      key: const Key('varsel-fjern'),
                      onTap: widget.onFjern,
                      child: Container(
                        width: 74,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF26D3D), Color(0xFFC94A22)]),
                        ),
                        child: Text(VarslerCopy.fjern, style: inter(11.5, weight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        GestureDetector(
          onHorizontalDragStart: (_) => setState(() => _drag = base),
          onHorizontalDragUpdate: (d) => setState(() => _drag = ((_drag ?? base) + d.delta.dx).clamp(-_bredde, 0.0)),
          onHorizontalDragEnd: (_) {
            final aapne = (_drag ?? base) < -70;
            setState(() => _drag = null);
            widget.onAapen(aapne);
          },
          onHorizontalDragCancel: () => setState(() => _drag = null),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: dx),
            // `transform .3s cubic-bezier(.2,.9,.3,1)`, none while dragging.
            duration: _drag != null ? Duration.zero : BergenPerf.oneShot(context, 300),
            curve: const Cubic(.2, .9, .3, 1),
            builder: (context, x, child) => Transform.translate(offset: Offset(x, 0), child: child),
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

/// «Fjernet: …» / «Skrudde av slike varsler» with «Angre» (`vsBekr`, 5 s;
/// `klask .34s cubic-bezier(.3,1.4,.5,1)` — the design's stamp, which ends at −5°).
class _Bekreftelse extends StatelessWidget {
  const _Bekreftelse({super.key, required this.tekst, required this.onAngre});

  final String tekst;
  final VoidCallback onAngre;

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: 340,
    builder: (context, t, child) {
      const c = Cubic(.3, 1.4, .5, 1);
      final u = (t / 340).clamp(0.0, 1.0);
      final double rot, skala, op;
      if (u < .6) {
        final e = c.transform(u / .6);
        rot = -5 + -2 * e;
        skala = 1.15 + (.98 - 1.15) * e;
        op = e.clamp(0.0, 1.0);
      } else {
        final e = c.transform((u - .6) / .4);
        rot = -7 + 2 * e;
        skala = .98 + .02 * e;
        op = 1;
      }
      return Opacity(
        opacity: op,
        child: Transform(alignment: Alignment.center, transform: Matrix4.rotationZ(rot * 3.14159265 / 180)..scaleByDouble(skala, skala, 1, 1), child: child),
      );
    },
    child: Container(
      key: const Key('varsler-bekreftelse'),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1F2B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, .14)),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(4, 18, 26, .9), offset: Offset(0, 12), blurRadius: 22, spreadRadius: -12)],
      ),
      child: Row(
        children: [
          Expanded(child: Text(tekst, maxLines: 2, overflow: TextOverflow.ellipsis, style: inter(11.5, weight: FontWeight.w700))),
          const SizedBox(width: 10),
          GestureDetector(
            key: const Key('varsler-angre'),
            onTap: onAngre,
            child: Text(VarslerCopy.angre, style: inter(11.5, weight: FontWeight.w800, color: const Color(0xFFF2C14E))),
          ),
        ],
      ),
    ),
  );
}

/// The card's button («Velg»): 44 high, orange for `valg`.
class _Handling extends StatelessWidget {
  const _Handling({required this.tekst, required this.oransje, required this.onTap});

  final String tekst;
  final bool oransje;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LfPress(
    key: const Key('varsel-handling'),
    scale: .94,
    onTap: onTap,
    child: CssBox(
      height: 44,
      radius: BorderRadius.circular(999),
      bg: oransje ? _oransje : _hvitGlass,
      border: Border.all(color: const Color.fromRGBO(255, 255, 255, .25)),
      shadows: oransje ? _oransjeSkygge : _hvitSkygge,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Center(widthFactor: 1, child: Text(tekst, style: inter(11.5, weight: FontWeight.w800))),
    ),
  );
}

/// «Ny på Ærend»: three photos (64 high, 1.4 : 1 : 1); the design's warm
/// gradients stand in until a photo loads, or when the store has none.
class _Bilder extends StatelessWidget {
  const _Bilder({required this.urls});

  final List<String> urls;

  static const _fyll = [
    [Color(0xFFE9D6B4), Color(0xFFC99B62)],
    [Color(0xFFDCE9EC), Color(0xFF8FB3BE)],
    [Color(0xFFEFE7D8), Color(0xFFB9A98C)],
  ];

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < 3; i++) ...[
        if (i > 0) const SizedBox(width: 6),
        Expanded(
          flex: i == 0 ? 14 : 10,
          child: CssBox(
            height: 64,
            radius: BorderRadius.circular(13),
            clip: true,
            bg: [CssLinear(160, _fyll[i])],
            shadows: const [CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .5)), CssShadow(0, 6, 12, -8, Color.fromRGBO(4, 18, 26, .8))],
            child: i < urls.length
                ? Image.network(urls[i], fit: BoxFit.cover, width: double.infinity, height: 64, errorBuilder: (_, __, ___) => const SizedBox.shrink())
                : const SizedBox.expand(),
          ),
        ),
      ],
    ],
  );
}

/// «Følg» / «Følger» (orange) and «Se meny».
class _RikKnapp extends StatelessWidget {
  const _RikKnapp({super.key, required this.tekst, required this.onTap, this.oransje = false});

  final String tekst;
  final VoidCallback onTap;
  final bool oransje;

  @override
  Widget build(BuildContext context) => LfPress(
    scale: .97,
    onTap: onTap,
    child: CssBox(
      height: 44,
      radius: BorderRadius.circular(999),
      bg: oransje ? _oransje : _hvitGlass,
      border: Border.all(color: Color.fromRGBO(255, 255, 255, oransje ? .28 : .22)),
      shadows: oransje ? _oransjeSkygge : _hvitSkygge,
      child: Center(child: Text(tekst, style: inter(12.5, weight: FontWeight.w800))),
    ),
  );
}
