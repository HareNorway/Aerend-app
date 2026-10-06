import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/ops/butikk_models.dart';
import '../../common/auth/launch/lf_css.dart' show LfFrame;
import '../../common/auth/onboarding_kit.dart' show OnbPressable, onbBlur;
import '../../common/home/bergen/bergen_kit.dart';
import '../../deliveryService/home/ds_home_store_list_pojo.dart';
import '../../snurre/snurre_launcher_policy.dart' show snurreLauncherHiddenRoutePrefix;
import '../kit/bergen_css.dart';
import '../kit/bergen_kit.dart';
import '../sok/sok_oversikt.dart' show SokIkon;
import 'butikk_copy.dart';

/// The store's Info sheet (`sheetInfo`, L8584): the shared teal sheet with
/// the store's name, the sliding Allergener / Åpningstider / Mer switch, and
/// below it the allergens the menu can contain, the opening hours with
/// today's row lit, or the facts and «Del butikken».
enum InfoTab { allergener, apningstider, mer }

Future<void> showInfoSheet(
  BuildContext context, {
  required BergenStoreInfo store,
  InfoTab initial = InfoTab.allergener,
  List<String> allergens = const [],
}) {
  final reduce = MediaQuery.disableAnimationsOf(context);
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      settings: const RouteSettings(name: '${snurreLauncherHiddenRoutePrefix}info'),
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      transitionDuration: Duration(milliseconds: reduce ? 0 : 380),
      reverseTransitionDuration: Duration(milliseconds: reduce ? 0 : 260),
      pageBuilder: (context, a, _) => _InfoRute(
        anim: a,
        child: InfoSheet(store: store, initial: initial, allergens: allergens),
      ),
    ),
  );
}

/// The scrim (`rgba(15,31,43,.32)`, `blur(5px)`, `skjermInn .25s`) and the
/// teal sheet rising (`arkOpp .38s`).
class _InfoRute extends StatelessWidget {
  const _InfoRute({required this.anim, required this.child});

  final Animation<double> anim;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: LfFrame(
        child: Builder(
          builder: (context) {
            final s = context.bs;
            final mq = MediaQuery.of(context);
            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: FadeTransition(
                      opacity: CurvedAnimation(
                        parent: anim,
                        curve: const Interval(0, .66, curve: Curves.easeOut),
                      ),
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
                      final e = const Cubic(.2, .9, .3, 1).transform(anim.value);
                      final ut = anim.status == AnimationStatus.reverse;
                      return Opacity(
                        opacity: ut ? anim.value : .6 + .4 * e,
                        child: Transform.translate(
                          offset: Offset(0, ut ? (1 - anim.value) * 400 : 26 * (1 - e)),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.fromLTRB(16 * s, 0, 16 * s, 22 * s + mq.padding.bottom * .5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(28 * s)),
                        gradient: cssLinear(
                          180,
                          const [Color(0xFF27596A), Color(0xFF1E4F5C), Color(0xFF173E48)],
                          const [0, .55, 1],
                        ),
                        border: const Border(top: BorderSide(color: Color.fromRGBO(255, 255, 255, .9))),
                        boxShadow: [
                          BoxShadow(
                            color: rgba(15, 31, 43, .55),
                            offset: Offset(0, -24 * s),
                            blurRadius: onbBlur(50 * s),
                            spreadRadius: -20 * s,
                          ),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          bergenInsetTop(
                            radius: 28 * s,
                            height: 1.5 * s,
                            alpha: .95,
                            pad: EdgeInsets.symmetric(
                              horizontal: 16 * s,
                            ).copyWith(bottom: 22 * s + mq.padding.bottom * .5),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: Padding(
                                  padding: EdgeInsets.only(top: 10 * s),
                                  child: Center(
                                    child: Container(
                                      width: 44 * s,
                                      height: 5 * s,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(3 * s),
                                        color: rgba(255, 255, 255, .35),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              child,
                            ],
                          ),
                        ],
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

class InfoSheet extends StatefulWidget {
  const InfoSheet({super.key, required this.store, this.initial = InfoTab.allergener, this.allergens = const []});

  final BergenStoreInfo store;
  final InfoTab initial;

  /// Overrides the allergens gathered from the menu.
  final List<String> allergens;

  @override
  State<InfoSheet> createState() => _InfoSheetState();
}

class _InfoSheetState extends State<InfoSheet> {
  late InfoTab _tab = widget.initial;

  /// What the menu can contain: every item's allergens, once each.
  List<String> get _allergener {
    if (widget.allergens.isNotEmpty) return widget.allergens;
    final sett = <String>{};
    final ut = <String>[];
    for (final i in widget.store.allItems) {
      for (final a in i.allergens) {
        final t = a.trim();
        if (t.isEmpty) continue;
        final navn = t[0].toUpperCase() + t.substring(1);
        if (sett.add(navn.toLowerCase())) ut.add(navn);
      }
    }
    return ut;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final store = widget.store;
    const tabs = [InfoTab.allergener, InfoTab.apningstider, InfoTab.mer];
    return Column(
      key: const Key('a1_butikk_info_sheet'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 14 * s),
        Text(store.name, style: bDisplay(context, 18, letterSpacingEm: -.02)),
        SizedBox(height: 12 * s),
        // The switch: a dark well with the orange pill gliding under the
        // chosen tab (`.38s cubic-bezier(.34,1.3,.5,1)`).
        Container(
          height: 42 * s,
          padding: EdgeInsets.all(4 * s),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: rgba(0, 0, 0, .22)),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [rgba(4, 18, 26, .45), rgba(4, 18, 26, 0), rgba(255, 255, 255, 0), rgba(255, 255, 255, .12)],
              stops: const [0, .12, .96, 1],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth / 3;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 380),
                    curve: const Cubic(.34, 1.3, .5, 1),
                    left: w * tabs.indexOf(_tab),
                    top: 0,
                    bottom: 0,
                    width: w,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)],
                          stops: [0, .56, 1],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: rgba(200, 70, 25, .8),
                            offset: Offset(0, 8 * s),
                            blurRadius: onbBlur(14 * s),
                            spreadRadius: -8 * s,
                          ),
                          BoxShadow(color: const Color(0xFFC4491A), offset: Offset(0, 2.5 * s)),
                        ],
                      ),
                      child: Stack(children: [bergenInsetTop(radius: 999, height: 1.5 * s, alpha: .4)]),
                    ),
                  ),
                  Row(
                    children: [
                      for (final (t, label) in [
                        (InfoTab.allergener, ButikkCopy.a1_butikk_allergener),
                        (InfoTab.apningstider, ButikkCopy.a1_butikk_apningstider),
                        (InfoTab.mer, ButikkCopy.a1_butikk_mer),
                      ])
                        Expanded(
                          child: GestureDetector(
                            key: Key('a1_butikk_info_${t.name}'),
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _tab = t);
                            },
                            child: Center(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 240),
                                style: bText(
                                  context,
                                  12,
                                  weight: FontWeight.w800,
                                  letterSpacingEm: -.01,
                                  color: _tab == t ? Colors.white : rgba(255, 255, 255, .7),
                                ),
                                child: Text(label),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: switch (_tab) {
            InfoTab.allergener => _allergenFane(context),
            InfoTab.apningstider => _tiderFane(context),
            InfoTab.mer => _merFane(context),
          },
        ),
      ],
    );
  }

  Widget _allergenFane(BuildContext context) {
    final s = context.bs;
    final a = _allergener;
    return Column(
      key: const ValueKey('a'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 16 * s),
        if (a.isEmpty)
          Text(
            ButikkCopy.a1_butikk_info_allergen_missing,
            style: bText(context, 12.5, weight: FontWeight.w600, height: 1.4, color: rgba(255, 255, 255, .75)),
          )
        else ...[
          Text(
            ButikkCopy.a1_butikk_info_kan_inneholde,
            style: bText(context, 10.5, weight: FontWeight.w800, letterSpacingEm: .06, color: rgba(255, 255, 255, .6)),
          ),
          SizedBox(height: 10 * s),
          for (var i = 0; i < a.length; i += 3) ...[
            if (i > 0) SizedBox(height: 6 * s),
            Row(
              children: [
                for (var j = i; j < i + 3; j++) ...[
                  if (j > i) SizedBox(width: 6 * s),
                  Expanded(
                    child: j < a.length
                        ? Container(
                            height: 36 * s,
                            alignment: Alignment.center,
                            padding: EdgeInsets.symmetric(horizontal: 6 * s),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12 * s),
                              color: rgba(255, 255, 255, .08),
                              border: Border.all(color: rgba(255, 255, 255, .12)),
                            ),
                            child: Text(
                              a[j],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: bText(context, 12, weight: FontWeight.w700),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ],
        ],
      ],
    );
  }

  static String _hm(String t) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(t.trim());
    return m == null ? t : '${m.group(1)!.padLeft(2, '0')}:${m.group(2)}';
  }

  static const _kort = {
    'mandag': 'Man',
    'tirsdag': 'Tir',
    'onsdag': 'Ons',
    'torsdag': 'Tor',
    'fredag': 'Fre',
    'lørdag': 'Lør',
    'søndag': 'Søn',
    'monday': 'Mon',
    'tuesday': 'Tue',
    'wednesday': 'Wed',
    'thursday': 'Thu',
    'friday': 'Fri',
    'saturday': 'Sat',
    'sunday': 'Sun',
  };

  static const _ukedag = ['mandag', 'tirsdag', 'onsdag', 'torsdag', 'fredag', 'lørdag', 'søndag'];

  Widget _tiderFane(BuildContext context) {
    final s = context.bs;
    final store = widget.store;
    // Consecutive days with the same hours share a row ("Man–tor").
    final rader = <({List<String> dager, String tid})>[];
    for (final h in store.hours) {
      final tid = h.opens.isEmpty || h.closes.isEmpty
          ? ButikkCopy.a1_butikk_info_stengt
          : '${_hm(h.opens)}–${_hm(h.closes)}';
      if (rader.isNotEmpty && rader.last.tid == tid) {
        rader.last.dager.add(h.day);
      } else {
        rader.add((dager: [h.day], tid: tid));
      }
    }
    final idag = _ukedag[DateTime.now().weekday - 1];
    String navn(List<String> d) {
      if (d.length == 1) return d.first;
      String k(String x) => _kort[x.toLowerCase()] ?? x;
      final siste = k(d.last);
      return '${k(d.first)}–${siste[0].toLowerCase()}${siste.substring(1)}';
    }

    return Column(
      key: const ValueKey('t'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 16 * s),
        Row(
          children: [
            Container(
              width: 8 * s,
              height: 8 * s,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: store.open ? BergenColors.mint : const Color(0xFFF7D57E),
                boxShadow: [
                  BoxShadow(
                    color: store.open ? rgba(92, 224, 184, .8) : rgba(247, 213, 126, .8),
                    blurRadius: onbBlur(8 * s),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8 * s),
            Text(
              store.open ? ButikkCopy.a1_butikk_info_apen_naa : ButikkCopy.a1_butikk_info_stengt_naa,
              style: bText(context, 14, weight: FontWeight.w800),
            ),
            if (store.open ? store.closeTime != null : store.openTime != null) ...[
              SizedBox(width: 6 * s),
              Text(
                store.open
                    ? ButikkCopy.a1_butikk_info_stenger(_hm(store.closeTime!))
                    : ButikkCopy.a1_butikk_info_aapner(_hm(store.openTime!)),
                style: bText(context, 12.5, weight: FontWeight.w600, color: rgba(255, 255, 255, .65)),
              ),
            ],
          ],
        ),
        if (rader.isNotEmpty) ...[
          SizedBox(height: 12 * s),
          _Tabell(rader: [for (final r in rader) (navn(r.dager), r.tid, r.dager.any((d) => d.toLowerCase() == idag))]),
        ],
      ],
    );
  }

  Widget _merFane(BuildContext context) {
    final s = context.bs;
    final store = widget.store;
    final adr = (store.address ?? '').split(',').first.trim();
    final fee = store.deliveryChargeKr;
    final rader = <(String, String, bool)>[
      if (adr.isNotEmpty) (ButikkCopy.a1_butikk_info_adresse, adr, false),
      if ((store.minOrderKr ?? 0) > 0) (ButikkCopy.a1_butikk_info_minsteordre, ButikkCopy.kr(store.minOrderKr!), false),
      if (fee != null)
        (ButikkCopy.a1_butikk_info_lev, fee <= 0 ? ButikkCopy.a1_butikk_info_gratis : ButikkCopy.kr(fee), fee <= 0),
      (
        ButikkCopy.a1_butikk_info_henting_rad,
        store.pickupPossible ? ButikkCopy.a1_butikk_info_ja : ButikkCopy.a1_butikk_info_nei,
        false,
      ),
    ];
    return Column(
      key: const ValueKey('m'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 14 * s),
        _Tabell(fakta: rader),
        SizedBox(height: 14 * s),
        OnbPressable(
          pressDy: 2.5,
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: 'aerend://bergen/butikk/${store.id}'));
            if (context.mounted) showBergenToast(context, ButikkCopy.a1_butikk_info_kopiert);
          },
          child: BergenCssShadow(
            key: const Key('a1_butikk_info_del'),
            radius: 999,
            shadows: [
              BoxShadow(
                color: rgba(4, 18, 26, .6),
                offset: Offset(0, 9 * s),
                blurRadius: onbBlur(13 * s),
                spreadRadius: -7 * s,
              ),
              BoxShadow(color: rgba(90, 74, 48, .35), offset: Offset(0, 3.5 * s)),
              BoxShadow(color: const Color(0xFFD9D2C4), offset: Offset(0, 2 * s)),
            ],
            child: Container(
              height: 46 * s,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [rgba(255, 255, 255, .14), rgba(255, 255, 255, .06)],
                ),
                border: Border.all(color: rgba(255, 255, 255, .95)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SokIkon(
                    'M12 16V4M12 4 7.5 8.5M12 4l4.5 4.5M5 14v4.5a1.5 1.5 0 0 0 1.5 1.5h11a1.5 1.5 0 0 0 1.5-1.5V14',
                    size: 14 * s,
                    color: Colors.white,
                    stroke: 2.3,
                  ),
                  SizedBox(width: 7 * s),
                  Text(
                    ButikkCopy.a1_butikk_info_del,
                    style: bText(context, 12.5, weight: FontWeight.w800, color: const Color(0xFF7FF0CB)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The glass table (`rgba(255,255,255,.06)`, a 1px ring, hairlines between
/// rows): hours (`rader`: day, time, lit) or facts (`fakta`: label, value,
/// mint).
class _Tabell extends StatelessWidget {
  const _Tabell({this.rader = const [], this.fakta = const []});

  final List<(String, String, bool)> rader;
  final List<(String, String, bool)> fakta;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final timer = rader.isNotEmpty;
    final liste = timer ? rader : fakta;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16 * s),
        color: rgba(255, 255, 255, .06),
        border: Border.all(color: rgba(255, 255, 255, .1)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < liste.length; i++)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 11 * s),
              decoration: BoxDecoration(
                border: i == 0 ? null : Border(top: BorderSide(color: rgba(255, 255, 255, .08))),
              ),
              child: Row(
                children: [
                  Text(
                    liste[i].$1,
                    style: bText(
                      context,
                      13,
                      weight: timer && liste[i].$3 ? FontWeight.w700 : FontWeight.w600,
                      color: timer
                          ? (liste[i].$3 ? const Color(0xFF7FF0CB) : rgba(255, 255, 255, .8))
                          : rgba(255, 255, 255, .65),
                    ),
                  ),
                  SizedBox(width: 12 * s),
                  Expanded(
                    child: Text(
                      liste[i].$2,
                      textAlign: TextAlign.right,
                      style: bText(
                        context,
                        13,
                        weight: liste[i].$3 ? FontWeight.w800 : FontWeight.w700,
                        color: liste[i].$3 ? const Color(0xFF7FF0CB) : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The category sheet (`arkAapent` ≈L7143): the category's name, "Åpne nå ·
/// {bydel}", and its stores and products as rows.
Future<void> showKategoriArk(
  BuildContext context, {
  required String name,
  required String bydel,
  required List<StoreListItem> stores,
  required ValueChanged<StoreListItem> onStore,
}) {
  return showBergenArk<void>(
    context,
    title: name,
    subtitle: ButikkCopy.a1_butikk_ark_under(bydel),
    rows: [
      for (final st in stores)
        BergenArkRow(
          label: st.storeName ?? '',
          value: [
            if ((st.storeStatus ?? 1) == 1) ButikkCopy.a1_butikk_ark_open,
            if ((st.orderDeliveryTime ?? 0) > 0) ButikkCopy.a1_butikk_kat_eta(st.orderDeliveryTime!),
            if (st.averageRatings != null) '★ ${st.averageRatings}',
          ].join(' · '),
          onTap: () {
            Navigator.of(context).pop();
            onStore(st);
          },
        ),
    ],
  );
}
