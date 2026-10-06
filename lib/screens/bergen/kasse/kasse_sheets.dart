import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../data/ops/kasse_models.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../../../utils/utils.dart';
import '../../../ui/kit/ae_address_drawer.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../../common/manageAddress/manage_address_dl.dart';
import '../../common/auth/launch/lf_css.dart' show LfFrame;
import '../../common/auth/onboarding_kit.dart' show OnbPressable, onbBlur;
import '../../snurre/snurre_launcher_policy.dart' show snurreLauncherHiddenRoutePrefix;
import '../kit/bergen_css.dart';
import '../kit/bergen_kit.dart';
import '../kit/svg_sti.dart';
import 'kasse_copy.dart';

/// The four Kasse sheets (≈L6913–7142 in `Ærend Kunde Bergen.dc.html`) via
/// [BergenArk]: **Adresse** ("Hvor skal ærendet?" + the door note),
/// **Ny adresse** (the existing address drawer inside), **Levering** ("Når vil
/// du ha det?"), **Betaling** (Vipps / Kort — the app's real methods).

/// Adresse: returns the chosen address, or null.
Future<AddressListItem?> showAdresseSheet(
  BuildContext context, {
  required List<AddressListItem> addresses,
  int? selectedId,
  required Future<void> Function() onAddNew,
  Future<Map<String, dynamic>?> Function(AddressListItem)? coverage,
  Future<void> Function(AddressListItem)? onWaitlist,
}) {
  return showBergenArk<AddressListItem>(
    context,
    title: KasseCopy.a1_kasse_adr_sheet_title,
    subtitle: KasseCopy.a1_kasse_adr_sheet_line,
    rows: [
      for (final a in addresses)
        BergenArkRow(
          label: '${a.type} · ${a.address.split(',').first}'.replaceFirst(RegExp(r'^ · '), ''),
          value: [if (a.flatNo.isNotEmpty) a.flatNo, if (a.landmark.isNotEmpty) a.landmark].join(' · '),
          icon: a.addressId == selectedId ? Icons.check_circle_rounded : Icons.place_outlined,
          onTap: () => Navigator.of(context).pop(a),
        ),
      BergenArkRow(
        label: KasseCopy.a1_kasse_adr_ny,
        value: KasseCopy.a1_kasse_adr_ny_line,
        icon: Icons.add_rounded,
        onTap: () async {
          Navigator.of(context).pop();
          await onAddNew();
        },
      ),
    ],
    body: Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            KasseCopy.a1_kasse_adr_dor_kicker,
            style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w800, color: BergenTokens.inkFaint),
          ),
          const SizedBox(height: 2),
          Text(
            KasseCopy.a1_kasse_adr_dor_line,
            style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w600, color: BergenTokens.inkSecondary),
          ),
        ],
      ),
    ),
  );
}

/// Ny adresse: the existing drawer, then the caller reloads the list.
Future<bool> showNyAdresseSheet(BuildContext context) async {
  final changed = await showAeAddressDrawer(context, parentContext: context);
  return changed == true;
}

/// Opens a Kasse sheet (`visSheet`, L8378): the scrim (`rgba(15,31,43,.32)`,
/// blur 5, `skjermInn .25s`) and the sheet rising on `arkOpp .38s
/// cubic-bezier(.2,.9,.3,1)` — teal for Levering, paper for Betaling.
Future<T?> visKasseArk<T>(
  BuildContext context, {
  required bool lys,
  required String navn,
  required WidgetBuilder builder,
}) {
  final reduce = MediaQuery.disableAnimationsOf(context);
  return Navigator.of(context, rootNavigator: true).push<T>(
    PageRouteBuilder<T>(
      settings: RouteSettings(name: '$snurreLauncherHiddenRoutePrefix$navn'),
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      transitionDuration: Duration(milliseconds: reduce ? 0 : 380),
      reverseTransitionDuration: Duration(milliseconds: reduce ? 0 : 260),
      pageBuilder: (context, a, _) => _KasseArkRute(anim: a, lys: lys, builder: builder),
    ),
  );
}

class _KasseArkRute extends StatelessWidget {
  const _KasseArkRute({required this.anim, required this.lys, required this.builder});

  final Animation<double> anim;
  final bool lys;
  final WidgetBuilder builder;

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
                        color: lys ? const Color(0xF2FAF9F6) : null,
                        gradient: lys
                            ? null
                            : cssLinear(
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
                                        color: lys ? rgba(35, 32, 29, .28) : rgba(255, 255, 255, .35),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              builder(context),
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

/// The time shown on the Kurv row: «Så fort som mulig», else «Kl. 18:30».
String kasseTidNavn(KasseSlot slot) => slot.at == null ? slot.label : KasseCopy.a1_kasse_kl(slot.label);

/// Levering (`sheet:'levering'`, L8614): «Når vil du ha det?», the dark
/// Levering / Henting track with the white thumb (`.38s cubic-bezier(.34,
/// 1.3,.5,1)`), the three times as glass cards with their radio, «Bruk
/// dette». Returns the chosen slot; the mode is reported on «Bruk dette».
Future<KasseSlot?> showLeveringSheet(
  BuildContext context, {
  required List<KasseSlot> slots,
  KasseSlot? selected,
  required bool pickup,
  required ValueChanged<bool> onModeChanged,
}) {
  var mode = pickup;
  KasseSlot? chosen = selected ?? slots.firstOrNull;
  return visKasseArk<KasseSlot>(
    context,
    lys: false,
    navn: 'levering',
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final s = ctx.bs;
        return Column(
          key: const Key('a1_kasse_levering_sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 14 * s),
            Text(KasseCopy.a1_kasse_lev_sheet_title, style: bDisplay(ctx, 18, letterSpacingEm: -.02)),
            SizedBox(height: 12 * s),
            _ModusSpor(pickup: mode, onMode: (m) => setState(() => mode = m)),
            for (var i = 0; i < slots.length; i++) ...[
              SizedBox(height: (i == 0 ? 12 : 8) * s),
              _TidKort(
                key: Key('a1_kasse_slot_${slots[i].id}'),
                slot: slots[i],
                tittel: i == 0
                    ? slots[i].label
                    : (i == 1 ? KasseCopy.a1_kasse_lev_middag : KasseCopy.a1_kasse_lev_kveld),
                skip: i == 0,
                valgt: chosen?.id == slots[i].id,
                onTap: () => setState(() => chosen = slots[i]),
              ),
            ],
            SizedBox(height: 14 * s),
            OnbPressable(
              key: const Key('a1_kasse_bruk_dette'),
              onTap: () {
                onModeChanged(mode);
                Navigator.of(ctx).pop(chosen);
              },
              pressDy: 0,
              pressScale: .97,
              child: Container(
                height: 50 * s,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16 * s),
                  gradient: cssLinear(160, const [Color(0xFFF2884E), Color(0xFFE0662C)]),
                  boxShadow: [
                    BoxShadow(
                      color: rgba(120, 50, 10, .9),
                      offset: Offset(0, 14 * s),
                      blurRadius: onbBlur(22 * s),
                      spreadRadius: -12 * s,
                    ),
                    BoxShadow(color: rgba(150, 60, 15, .8), offset: Offset(0, 3 * s)),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const SizedBox.expand(),
                    bergenInsetTop(radius: 16 * s, height: 1.5 * s, alpha: .35),
                    Text(KasseCopy.a1_kasse_bruk_dette, style: bDisplay(ctx, 14)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _ModusSpor extends StatelessWidget {
  const _ModusSpor({required this.pickup, required this.onMode});

  final bool pickup;
  final ValueChanged<bool> onMode;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Container(
      padding: EdgeInsets.all(4 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [rgba(0, 0, 0, .45), rgba(0, 0, 0, .26), rgba(0, 0, 0, .26), rgba(255, 255, 255, .14)],
          stops: const [0, .16, .96, 1],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth / 2;
          return SizedBox(
            height: 34 * s,
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: BergenTokens.motion(context, const Duration(milliseconds: 380)),
                  curve: const Cubic(.34, 1.3, .5, 1),
                  left: pickup ? w : 0,
                  top: 0,
                  bottom: 0,
                  width: w,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: cssLinear(180, const [Color(0xFFFFFFFF), Color(0xFFF3EEE2)]),
                      boxShadow: [
                        BoxShadow(
                          color: rgba(4, 18, 26, .8),
                          offset: Offset(0, 8 * s),
                          blurRadius: onbBlur(14 * s),
                          spreadRadius: -8 * s,
                        ),
                        BoxShadow(color: const Color(0xFFCDB98E), offset: Offset(0, 3 * s)),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (final (m, label) in [(false, KasseCopy.a1_kasse_levering), (true, KasseCopy.a1_kasse_henting)])
                      Expanded(
                        child: GestureDetector(
                          key: Key(m ? 'a1_kasse_ark_henting' : 'a1_kasse_ark_levering'),
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onMode(m),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 240),
                              style: bText(
                                context,
                                12.5,
                                weight: FontWeight.w800,
                                color: pickup == m ? const Color(0xFF1E4F5C) : rgba(255, 255, 255, .75),
                              ),
                              child: Text(label),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TidKort extends StatelessWidget {
  const _TidKort({
    super.key,
    required this.slot,
    required this.tittel,
    required this.skip,
    required this.valgt,
    required this.onTap,
  });

  final KasseSlot slot;
  final String tittel;
  final bool skip;
  final bool valgt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    const mint = Color(0xFF5CE0B8);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 12 * s),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20 * s),
          gradient: cssLinear(180, [
            valgt ? rgba(92, 224, 184, .16) : rgba(255, 255, 255, .1),
            rgba(255, 255, 255, .05),
          ]),
          border: Border.all(color: valgt ? rgba(92, 224, 184, .7) : rgba(255, 255, 255, .2), width: valgt ? 1.5 : 1),
          boxShadow: [
            BoxShadow(
              color: rgba(4, 18, 26, valgt ? .9 : .8),
              offset: Offset(0, (valgt ? 14 : 12) * s),
              blurRadius: onbBlur((valgt ? 24 : 20) * s),
              spreadRadius: -(valgt ? 14 : 16) * s,
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 30 * s,
              child: skip
                  ? bergenSvg('longship3d', width: 30 * s, height: 20 * s)
                  : Text(
                      slot.label,
                      textAlign: TextAlign.center,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      style: bText(context, 12, weight: FontWeight.w800, color: mint),
                    ),
            ),
            SizedBox(width: 12 * s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tittel, style: bText(context, 13, weight: FontWeight.w800)),
                  Text(
                    slot.line,
                    style: bText(context, 10.5, weight: FontWeight.w600, color: rgba(255, 255, 255, .62)),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 20 * s,
              height: 20 * s,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: valgt ? mint : rgba(255, 255, 255, .45), width: 2 * s),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 10 * s,
                height: 10 * s,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: valgt ? mint : const Color(0x005CE0B8),
                  boxShadow: [BoxShadow(color: valgt ? mint : const Color(0x005CE0B8), blurRadius: onbBlur(8 * s))],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The legacy payment types: 3 = Vipps, 2 = card (the Stripe checkout); Apple
/// Pay (4) and Google Pay (5) take the card path, where Stripe offers them.
const kBetVipps = 3, kBetKort = 2, kBetApple = 4, kBetGoogle = 5;

String kasseBetalingNavn(int type) {
  final phone = prefGetString(prefContactNumber).trim();
  return switch (type) {
    kBetVipps => KasseCopy.a1_kasse_bet_vipps(phone),
    kBetApple => 'Apple Pay',
    kBetGoogle => 'Google Pay',
    _ => KasseCopy.a1_kasse_bet_kort,
  };
}

/// Betaling (`sheet:'betaling'`, L8822): «Hvordan vil du betale?» on paper,
/// one card per method with its brand tile and the radio that springs in.
/// Checked visually only — nothing here starts a payment. Returns the type.
Future<int?> showBetalingSheet(BuildContext context, {int? selected}) {
  final metoder = [
    kBetVipps,
    kBetKort,
    if (defaultTargetPlatform == TargetPlatform.iOS) kBetApple,
    if (defaultTargetPlatform == TargetPlatform.android) kBetGoogle,
  ];
  return visKasseArk<int>(
    context,
    lys: true,
    navn: 'betaling',
    builder: (ctx) {
      final s = ctx.bs;
      return Column(
        key: const Key('a1_kasse_betaling_sheet'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 14 * s),
          Text(
            KasseCopy.a1_kasse_bet_sheet_title,
            style: bDisplay(ctx, 18, letterSpacingEm: -.02, color: const Color(0xFF23201D)),
          ),
          SizedBox(height: 2 * s),
          Text(
            KasseCopy.a1_kasse_bet_sheet_line,
            style: bText(ctx, 11.5, weight: FontWeight.w600, color: const Color(0xFF57534B)),
          ),
          for (var i = 0; i < metoder.length; i++) ...[
            SizedBox(height: (i == 0 ? 14 : 8) * s),
            _BetKort(
              type: metoder[i],
              valgt: (selected ?? kBetVipps) == metoder[i],
              onTap: () {
                Navigator.of(ctx).pop(metoder[i]);
                showBergenToast(
                  context,
                  KasseCopy.a1_kasse_betaler_med(
                    metoder[i] == kBetKort
                        ? KasseCopy.a1_kasse_kort.toLowerCase()
                        : kasseBetalingNavn(metoder[i]).split(' · ').first,
                  ),
                );
              },
            ),
          ],
        ],
      );
    },
  );
}

class _BetKort extends StatelessWidget {
  const _BetKort({required this.type, required this.valgt, required this.onTap});

  final int type;
  final bool valgt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final (bg, merke) = switch (type) {
      kBetVipps => (
        cssLinear(160, const [Color(0xFFFF7A45), Color(0xFFE9501A)]),
        Text('v', style: bDisplay(context, 19, letterSpacingEm: -.04)),
      ),
      kBetKort => (
        cssLinear(160, const [Color(0xFF2A3A9C), Color(0xFF141B5E)]),
        Text('VISA', style: bDisplay(context, 11, letterSpacingEm: .02).copyWith(fontStyle: FontStyle.italic)),
      ),
      kBetApple => (
        cssLinear(160, const [Color(0xFF3A3A3C), Color(0xFF0F0F10)]),
        CustomPaint(size: Size(16 * s, 19 * s), painter: const _MerkePainter(_kEple, 20, 24, [Colors.white])),
      ),
      _ => (
        cssLinear(180, const [Color(0xFFFFFFFF), Color(0xFFEEF2F1)]),
        CustomPaint(
          size: Size.square(18 * s),
          painter: const _MerkePainter(_kG, 24, 24, [
            Color(0xFF4285F4),
            Color(0xFF34A853),
            Color(0xFFFBBC05),
            Color(0xFFEA4335),
          ]),
        ),
      ),
    };
    return GestureDetector(
      key: Key('a1_kasse_bet_$type'),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.fromLTRB(10 * s, 10 * s, 14 * s, 10 * s),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20 * s),
          gradient: valgt
              ? cssLinear(180, const [Color(0xFFF1FBF7), Color(0xFFE3F6EF)])
              : cssLinear(180, const [Color(0xFFFFFFFF), Color(0xFFFAF8F4)]),
          border: Border.all(color: valgt ? const Color(0xFF5CE0B8) : rgba(35, 32, 29, .05), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: rgba(8, 24, 32, .45),
              offset: Offset(0, 10 * s),
              blurRadius: onbBlur(18 * s),
              spreadRadius: -14 * s,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40 * s,
              height: 40 * s,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13 * s),
                gradient: bg,
                boxShadow: [
                  BoxShadow(
                    color: rgba(8, 24, 32, .6),
                    offset: Offset(0, 7 * s),
                    blurRadius: onbBlur(12 * s),
                    spreadRadius: -7 * s,
                  ),
                ],
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13 * s),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [rgba(0, 0, 0, 0), rgba(0, 0, 0, 0), rgba(0, 0, 0, .22)],
                  stops: const [0, .8, 1],
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const SizedBox.expand(),
                  bergenInsetTop(radius: 13 * s, height: 1.5 * s, alpha: .35),
                  merke,
                ],
              ),
            ),
            SizedBox(width: 12 * s),
            Expanded(
              child: Text(
                kasseBetalingNavn(type),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: bText(context, 14, weight: FontWeight.w800, color: const Color(0xFF23201D)),
              ),
            ),
            SizedBox(
              width: 26 * s,
              height: 26 * s,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFFDCD7CE),
                            const Color(0xFFF1EEE8),
                            const Color(0xFFF1EEE8),
                            rgba(255, 255, 255, .9),
                          ],
                          stops: const [0, .2, .94, 1],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: valgt ? 1 : 0,
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 350),
                        curve: const Cubic(.34, 1.56, .64, 1),
                        scale: valgt ? 1 : .5,
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              center: Alignment(-.32, -.44),
                              colors: [Color(0xFF4A93A4), Color(0xFF1E4F5C)],
                              stops: [0, .7],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: rgba(8, 24, 32, .5),
                                offset: Offset(0, 4 * s),
                                blurRadius: onbBlur(8 * s),
                                spreadRadius: -3 * s,
                              ),
                            ],
                          ),
                          child: CustomPaint(
                            size: Size.square(12 * s),
                            painter: const _MerkePainter(_kHake, 24, 24, [Color(0xFF5CE0B8)], strek: 3.6),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _kEple = [
  'M14.6 12.7c0-2.5 2-3.7 2.1-3.8-1.1-1.7-2.9-1.9-3.5-1.9-1.5-.1-2.8.9-3.5.9s-1.9-.9-3.1-.8C4.8 7.2 3 8.4 2 10.4c-1.1 2-.7 5.7 1 8.4.8 1.3 1.9 2.8 3.3 2.7 1.3 0 1.8-.8 3.4-.8s2 .8 3.4.8c1.4 0 2.3-1.3 3.2-2.6.9-1.4 1.3-2.7 1.3-2.8-.1 0-2.9-1.2-3-4.4zM12.2 4.9c.7-.9 1.2-2 1-3.2-1 0-2.3.7-3 1.5-.7.8-1.2 2-1.1 3.1 1.1.1 2.3-.6 3.1-1.4z',
];
const _kG = [
  'M21.6 12.2c0-.7-.06-1.37-.18-2H12v3.8h5.4a4.62 4.62 0 0 1-2 3.03v2.5h3.22c1.88-1.73 2.98-4.28 2.98-7.33z',
  'M12 22c2.7 0 4.96-.9 6.62-2.43l-3.22-2.5c-.9.6-2.04.95-3.4.95a5.98 5.98 0 0 1-5.62-4.13H3.04v2.6A10 10 0 0 0 12 22z',
  'M6.38 13.89a6 6 0 0 1 0-3.78v-2.6H3.04a10 10 0 0 0 0 8.98l3.34-2.6z',
  'M12 6.18c1.47 0 2.79.5 3.83 1.5l2.85-2.85A9.6 9.6 0 0 0 12 2a10 10 0 0 0-8.96 5.51l3.34 2.6A5.98 5.98 0 0 1 12 6.18z',
];
const _kHake = ['M5 12.5l4.5 4.5L19 7.5'];

/// Brand marks from their SVG paths: filled in [farger] (one per path), or
/// stroked when [strek] is given.
class _MerkePainter extends CustomPainter {
  const _MerkePainter(this.stier, this.vw, this.vh, this.farger, {this.strek});

  final List<String> stier;
  final double vw;
  final double vh;
  final List<Color> farger;
  final double? strek;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / vw, size.height / vh);
    for (var i = 0; i < stier.length; i++) {
      final paint = Paint()..color = farger[i % farger.length];
      if (strek != null) {
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = strek!
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
      }
      canvas.drawPath(svgSti(stier[i]), paint);
    }
  }

  @override
  bool shouldRepaint(_MerkePainter old) => false;
}

/// Coverage at address change (geo spec §4): a guarded read; 404 / flag off
/// skips silently. Returns false only when the answer says "not covered".
Future<bool> checkCoverage(OpsCustomerApi api, AddressListItem a) async {
  final lat = double.tryParse(a.lat);
  final lng = double.tryParse(a.long);
  if (lat == null || lng == null) return true;
  final json = await api.coverage(lat, lng);
  if (json == null) return true;
  final covered = json['covered'] ?? json['is_covered'] ?? json['eligible'];
  return covered != false;
}
