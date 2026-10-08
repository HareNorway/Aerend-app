import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../dialogs/simple_dialog_util.dart';
import '../../../screens/common/home/home_repo.dart';
import '../../../utils/utils.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/editProfile/edit_profile.dart';
import '../../common/manageAddress/add_new_address.dart';
import '../../common/manageAddress/manage_address_dl.dart';
import '../../common/manageCard/manage_card.dart';
import '../aegil/aegil_bits.dart';
import 'a3_services.dart';
import '../kit/bergen_kit.dart';
import 'meg_copy.dart';
import 'meg_torg.dart';
import '../sporing/hjelp_sheet.dart';

const String kPrefA3KrysningAv = 'a3_konto_krysning_varsler_av';
const String kPrefA3Rolig = 'a3_konto_rolig';

/// Konto (`erKonto`, L8211–8270 in `Ærend Kunde Launch.dc.html`, design px):
/// the Torg header with «{navn} · Vipps-verifisert» (tap: edit the profile),
/// Adresser (the saved addresses as radios — a tap makes one the delivery
/// address, as Velg leveringsadresse does — and «Legg til adresse»),
/// Betaling (Vipps as the standard, the saved cards, Apple Pay), and
/// Innstillinger (varsler om krysningen, roligere bevegelse, hjelp og
/// personvern), then «Logg ut». The existing address, card and profile
/// screens do the editing; nothing here touches how an order is paid.
class KontoScreen extends StatefulWidget {
  const KontoScreen({super.key});

  @override
  State<KontoScreen> createState() => _KontoScreenState();
}

class _KontoScreenState extends State<KontoScreen> {
  bool _krysning = true;
  bool _rolig = false;
  int _valgt = 0;
  List<AddressListItem> _adresser = const [];
  List<String> _kort = const [];

  @override
  void initState() {
    super.initState();
    try {
      _krysning = !prefGetBool(kPrefA3KrysningAv);
      _rolig = prefGetBool(kPrefA3Rolig);
      _valgt = prefGetInt(prefNewDeliveryAddressId);
    } catch (_) {}
    A3Services.reducedMotion.value = _rolig;
    _hent();
  }

  Future<void> _hent() async {
    final a = await a3Try(() => A3Services.addressList());
    final k = await a3Try(() => A3Services.cards());
    if (!mounted) return;
    setState(() {
      _adresser = a ?? const [];
      _kort = k ?? const [];
    });
  }

  Future<void> _push(Widget w) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => w));
    if (!mounted) return;
    try {
      _valgt = prefGetInt(prefNewDeliveryAddressId);
    } catch (_) {}
    _hent();
  }

  /// The same as picking it in Velg leveringsadresse.
  Future<void> _velg(AddressListItem a) async {
    setState(() => _valgt = a.addressId);
    await prefSetInt(prefNewDeliveryAddressId, a.addressId);
    await prefSetString(prefNewDeliveryAddress, jsonEncode(a.toJson()));
    final la = double.tryParse(a.lat);
    final lo = double.tryParse(a.long);
    if (la != null && lo != null && la.abs() > 1e-7 && lo.abs() > 1e-7) {
      await prefSetLatLng(LatLng(la, lo));
    }
  }

  Future<void> _logout() async {
    await showBergenSheet<void>(
      context,
      builder: (ctx) => LogoutSheet(
        onConfirm: () async {
          try {
            await HomeRepo().callLogoutApi();
          } catch (_) {}
          if (!ctx.mounted) return;
          Navigator.of(ctx).pop();
          if (!mounted) return;
          logout(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navn = a3Pref(prefUserName).trim().split(RegExp(r'\s+')).first;
    final vipps = KontoTekst.vipps(a3Pref(prefContactNumber));
    // The delivery address in use; the first one when none is picked yet.
    final valgt = _adresser.any((a) => a.addressId == _valgt) ? _valgt : (_adresser.isEmpty ? 0 : _adresser.first.addressId);

    return Scaffold(
      backgroundColor: const Color(0xFF173E48),
      body: LfFrame(
        child: MegTorgSkjerm(
          tittel: A3MegCopy.a3_meg_konto_title,
          pille: navn.isEmpty ? A3MegCopy.a3_meg_konto_verifisert : '$navn · ${A3MegCopy.a3_meg_konto_verifisert}',
          pilleKey: const Key('konto-profil'),
          onPille: () => _push(const EditProfile()),
          listKey: const Key('konto-liste'),
          glod: const [
            MegGlod(top: 40, left: -70, size: 250, color: Color.fromRGBO(58, 125, 140, .26)),
            MegGlod(top: 380, right: -80, size: 260, color: Color.fromRGBO(242, 193, 78, .3)),
          ],
          children: [
            const _Overskrift(A3MegCopy.a3_meg_konto_adresser, top: 0),
            MegLysKort(
              key: const Key('konto-adresser'),
              child: Column(
                children: [
                  for (final a in _adresser)
                    _Rad(
                      key: Key('konto-adresse-${a.addressId}'),
                      tittel: KontoTekst.adresse(a),
                      under: KontoTekst.merknad(a),
                      radio: a.addressId == valgt,
                      onTap: () => _velg(a),
                    ),
                  _Rad(
                    key: const Key('konto-legg-adresse'),
                    tittel: A3MegCopy.a3_meg_konto_legg_adresse,
                    pluss: true,
                    siste: true,
                    onTap: () => _push(const AddNewAddress()),
                  ),
                ],
              ),
            ),
            const _Overskrift(A3MegCopy.a3_meg_konto_betaling),
            MegLysKort(
              key: const Key('konto-betaling'),
              child: Column(
                children: [
                  _Rad(tittel: vipps, under: A3MegCopy.a3_meg_konto_vipps_std, radio: true),
                  for (final k in _kort)
                    _Rad(tittel: k, under: KontoTekst.kortUnder, radio: false, onTap: () => _push(const ManageCard())),
                  if (_kort.isEmpty)
                    _Rad(key: const Key('konto-kort'), tittel: KontoTekst.leggKort, pluss: true, onTap: () => _push(const ManageCard())),
                  const _Rad(tittel: KontoTekst.applePay, under: KontoTekst.applePaySub, radio: false, siste: true),
                ],
              ),
            ),
            const _Overskrift(A3MegCopy.a3_meg_konto_innstillinger),
            MegLysKort(
              child: Column(
                children: [
                  _Rad(
                    key: const Key('konto-krysning'),
                    tittel: A3MegCopy.a3_meg_konto_varsler,
                    under: A3MegCopy.a3_meg_konto_varsler_sub,
                    bryter: _krysning,
                    onTap: () {
                      setState(() => _krysning = !_krysning);
                      prefSetBool(kPrefA3KrysningAv, !_krysning);
                    },
                  ),
                  // UI-TEMP #26: no «Nytt fra Ærend» row yet (a push when Ærend
                  // itself publishes; opt-in). The backend is ready (backend plan
                  // Step 9): FeedRepo.fetchAerendFollow / setAerendFollow
                  // (GET/PUT/DELETE /v1/me/aerend-follow). Until the row exists
                  // nobody is opted in, so Ærend posts push no one.
                  _Rad(
                    key: const Key('konto-rolig'),
                    tittel: A3MegCopy.a3_meg_konto_rolig,
                    under: A3MegCopy.a3_meg_konto_rolig_sub,
                    bryter: _rolig,
                    bryterKey: const Key('konto-rolig-switch'),
                    onTap: () {
                      setState(() => _rolig = !_rolig);
                      A3Services.reducedMotion.value = _rolig;
                      prefSetBool(kPrefA3Rolig, _rolig);
                    },
                  ),
                  _Rad(
                    key: const Key('konto-hjelp'),
                    tittel: A3MegCopy.a3_meg_konto_hjelp,
                    under: A3MegCopy.a3_meg_konto_data,
                    pil: true,
                    siste: true,
                    onTap: () => HjelpScreen.apne(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            MegLysKort(
              child: _Rad(
                key: const Key('konto-logg-ut'),
                tittel: A3MegCopy.a3_meg_konto_logg_ut,
                farge: const Color(0xFFC4491A),
                siste: true,
                onTap: _logout,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Overskrift extends StatelessWidget {
  const _Overskrift(this.tekst, {this.top = 16});
  final String tekst;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(6, top, 6, 8),
    child: Text(tekst, style: jakarta(14, color: MegTorgSkjerm.blekk)),
  );
}

/// One row of a Konto card (`padding:10px 0`, `gap:11px`, the hairline
/// under all but the last): a radio, a «+», or a switch / chevron at the end.
class _Rad extends StatelessWidget {
  const _Rad({
    super.key,
    required this.tittel,
    this.under,
    this.radio,
    this.pluss = false,
    this.bryter,
    this.bryterKey,
    this.pil = false,
    this.siste = false,
    this.farge,
    this.onTap,
  });

  final String tittel;
  final String? under;
  final bool? radio;
  final bool pluss;
  final bool? bryter;
  final Key? bryterKey;
  final bool pil;
  final bool siste;
  final Color? farge;
  final VoidCallback? onTap;

  static const Color _teal = Color(0xFF1E4F5C);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: siste ? null : const Border(bottom: BorderSide(color: Color.fromRGBO(35, 32, 29, .07))),
        ),
        child: Row(
          children: [
            if (radio != null) ...[
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _teal, width: 2)),
                alignment: Alignment.center,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: radio! ? _teal : const Color(0x001E4F5C)),
                ),
              ),
              const SizedBox(width: 11),
            ],
            if (pluss) ...[
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color.fromRGBO(30, 79, 92, .1)),
                alignment: Alignment.center,
                child: const AeIkon('M12 5v14M5 12h14', size: 11, stroke: 3, color: _teal),
              ),
              const SizedBox(width: 11),
            ],
            Expanded(
              child: pluss
                  ? Text(tittel, style: inter(12.5, weight: FontWeight.w800, color: _teal))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tittel, maxLines: 2, overflow: TextOverflow.ellipsis, style: inter(12.5, weight: farge == null ? FontWeight.w700 : FontWeight.w800, color: farge ?? MegTorgSkjerm.blekk)),
                        if (under != null) Text(under!, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(10.5, weight: FontWeight.w400, color: const Color(0xFF6E6862))),
                      ],
                    ),
            ),
            if (bryter != null) ...[const SizedBox(width: 11), _Bryter(key: bryterKey, paa: bryter!)],
            if (pil) ...[const SizedBox(width: 11), const AeIkon('M9 6l6 6-6 6', size: 13, stroke: 2, color: Color(0xFF6E6862))],
          ],
        ),
      ),
    );
  }
}

/// The switch (`44×26`, `#3F8F5F` when on, the white knob at 21 / 3,
/// `transition: .2s`).
class _Bryter extends StatelessWidget {
  const _Bryter({super.key, required this.paa});
  final bool paa;

  @override
  Widget build(BuildContext context) => Semantics(
    toggled: paa,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.ease,
      width: 44,
      height: 26,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: paa ? const Color(0xFF3F8F5F) : const Color.fromRGBO(35, 32, 29, .15),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(35, 32, 29, .15), offset: Offset(0, 2), blurRadius: 4, blurStyle: BlurStyle.inner)],
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.ease,
            top: 3,
            left: paa ? 21 : 3,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [BoxShadow(color: Color.fromRGBO(35, 32, 29, .4), offset: Offset(0, 3), blurRadius: 6, spreadRadius: -2)],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Copy for Konto that A3MegCopy does not carry.
abstract final class KontoTekst {
  static const String applePay = 'Apple Pay';
  static const String applePaySub = 'Face ID ved betaling';
  static const String kortUnder = 'Lagret kort';
  static const String leggKort = 'Legg til kort';

  /// «Vipps · 412 34 567» from the number on the account.
  static String vipps(String nr) {
    final d = nr.replaceAll(RegExp(r'\D'), '');
    if (d.length != 8) return 'Vipps';
    return 'Vipps · ${d.substring(0, 3)} ${d.substring(3, 5)} ${d.substring(5)}';
  }

  /// «Hjem · Nygårdsgaten 5, 3. etasje».
  static String adresse(AddressListItem a) {
    final type = switch (a.type) { home => 'Hjem', work => 'Jobb', _ => 'Annen' };
    final linje = _rens(a.address).replaceAll(RegExp(r'(,\s*N/A)+$', caseSensitive: false), '');
    final flat = _rens(a.flatNo);
    return '$type · $linje${flat.isEmpty ? '' : ', $flat'}';
  }

  /// The landmark («Ring på hos Didrik»), unless it is empty or repeats the address.
  static String? merknad(AddressListItem a) {
    final m = _rens(a.landmark);
    if (m.isEmpty || a.address.toLowerCase().startsWith(m.toLowerCase())) return null;
    return m;
  }

  static String _rens(String s) => s.trim().toUpperCase() == 'N/A' ? '' : s.trim();
}
