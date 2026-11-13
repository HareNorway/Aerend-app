import 'dart:async';

import 'package:flutter/material.dart';

import '../../../networking/ops/cus_api.dart';
import '../../../utils/shared_pref_utill.dart';
import '../../common/auth/launch/lf_css.dart';
import '../kit/bergen_routes.dart';
import '../kit/bergen_toast.dart';
import 'a3_scaffold.dart';

/// Notifications plan Step 7: «Varsler» under Meg — every notification type the customer can get, from the server
/// (`GET api/customer/notification-prefs`), so a new type shows up without an app release. CRITICAL and the types
/// one may not switch off are «Alltid på» with a sound switch only; the rest have push on/off. Marketing consent at
/// the bottom. NEW UI without a design: the Meg scaffold and the kit's type.
abstract final class VarslerInnstCopy {
  static const tittel = 'Varsler';
  static const sub = 'Velg hva som får sende deg push. Det du slår av, ser du fortsatt i Varsler.';
  static const alltidPaa = 'Alltid på';
  static const lyd = 'Lyd';
  static const push = 'Push';
  static const markedsforing = 'Tilbud og nyheter fra Ærend';
  static const markedsforingSub = 'Kampanjer som push. Uten dette ser du dem bare i Varsler.';
  static const tomt = 'Fikk ikke hentet innstillingene. Prøv igjen.';
  static const lagret = 'Lagret';
  static const gruppe = {'critical': 'Viktig', 'operational': 'Bestillinger og svar', 'insight': 'Forslag og nyheter'};
}

/// Where the screen reads and writes; tests swap it.
class VarslerInnstKilde {
  const VarslerInnstKilde({required this.hent, required this.lagre, required this.samtykke});

  final Future<CusVarselPrefs?> Function() hent;
  final Future<CusVarselPrefs?> Function(String type, {bool? push, bool? lyd}) lagre;
  final Future<bool> Function(bool ja) samtykke;

  static VarslerInnstKilde standard() => VarslerInnstKilde(
    hent: () => CusApi().varselInnstillinger(),
    lagre: (t, {push, lyd}) => CusApi().varselInnstillingLagre(t, push: push, lyd: lyd),
    samtykke: (ja) => CusApi().markedsSamtykke(ja),
  );
}

class VarslerInnstScreen extends StatefulWidget {
  const VarslerInnstScreen({super.key});

  static VarslerInnstKilde kilde = VarslerInnstKilde.standard();

  @override
  State<VarslerInnstScreen> createState() => _VarslerInnstScreenState();
}

class _VarslerInnstScreenState extends State<VarslerInnstScreen> {
  CusVarselPrefs? _p;
  bool _laster = true;

  @override
  void initState() {
    super.initState();
    unawaited(_hent());
  }

  Future<void> _hent() async {
    final p = await VarslerInnstScreen.kilde.hent().catchError((_) => null);
    if (!mounted) return;
    setState(() {
      _p = p;
      _laster = false;
    });
  }

  Future<void> _sett(CusVarselType t, {bool? push, bool? lyd}) async {
    final p = await VarslerInnstScreen.kilde.lagre(t.type, push: push, lyd: lyd).catchError((_) => null);
    if (!mounted) return;
    if (p == null) {
      showBergenToast(context, BergenRoutes.ikkeLagret);
      return;
    }
    setState(() => _p = CusVarselPrefs(types: p.types, marketing: _p?.marketing));
  }

  Future<void> _samtykke(bool ja) async {
    final ok = await VarslerInnstScreen.kilde.samtykke(ja).catchError((_) => false);
    if (!mounted) return;
    if (!ok) {
      showBergenToast(context, BergenRoutes.ikkeLagret);
      return;
    }
    setState(() => _p = CusVarselPrefs(types: _p?.types ?? const [], marketing: ja));
  }

  @override
  Widget build(BuildContext context) {
    final p = _p;
    return A3Scaffold(
      title: VarslerInnstCopy.tittel,
      subtitle: VarslerInnstCopy.sub,
      child: _laster
          ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          : p == null
          ? Padding(padding: const EdgeInsets.all(16), child: Text(VarslerInnstCopy.tomt, key: const Key('varsler-innst-tomt'), style: inter(13)))
          : Column(
              key: const Key('varsler-innst'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final cls in const ['critical', 'operational', 'insight'])
                  if (p.types.where((t) => t.cls == cls).toList() case final del when del.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 18, 4, 6),
                      child: Text(VarslerInnstCopy.gruppe[cls]!.toUpperCase(), style: inter(11, weight: FontWeight.w800, em: .08, color: const Color(0xFF9FD3DE))),
                    ),
                    for (final t in del) _Rad(t: t, onPush: (v) => _sett(t, push: v), onLyd: (v) => _sett(t, lyd: v)),
                  ],
                const SizedBox(height: 18),
                SwitchListTile(
                  key: const Key('varsler-innst-markedsforing'),
                  value: p.marketing == true,
                  onChanged: _samtykke,
                  title: Text(VarslerInnstCopy.markedsforing, style: inter(13.5, weight: FontWeight.w700)),
                  subtitle: Text(VarslerInnstCopy.markedsforingSub, style: inter(11.5, color: const Color(0xFFDCE9EC))),
                ),
              ],
            ),
    );
  }
}

class _Rad extends StatelessWidget {
  const _Rad({required this.t, required this.onPush, required this.onLyd});

  final CusVarselType t;
  final ValueChanged<bool> onPush, onLyd;

  @override
  Widget build(BuildContext context) => Padding(
    key: Key('varsler-innst-${t.type}'),
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(child: Text(t.label, style: inter(13.5, weight: FontWeight.w700))),
        if (t.alwaysOn) ...[
          Text(VarslerInnstCopy.alltidPaa, key: Key('alltid-${t.type}'), style: inter(11, weight: FontWeight.w700, color: const Color(0xFF9FE0C8))),
          const SizedBox(width: 10),
          Text(VarslerInnstCopy.lyd, style: inter(11)),
          Switch(key: Key('lyd-${t.type}'), value: t.sound, onChanged: onLyd),
        ] else ...[
          Text(VarslerInnstCopy.push, style: inter(11)),
          Switch(key: Key('push-${t.type}'), value: t.push && t.mutedUntil == null, onChanged: onPush),
        ],
      ],
    ),
  );
}

/// Notifications plan Step 7 (D-10, Q-9): the marketing question, once — after the customer's first delivered order,
/// and only when they have never answered. Without a yes, campaigns reach them in-app only.
abstract final class NtfSamtykke {
  static const tittel = 'Vil du få tilbud fra Ærend?';
  static const tekst = 'Vi sender av og til et tilbud eller en nyhet fra butikkene i nærheten. Du kan skru det av under Meg › Varsler.';
  static const ja = 'Ja, gjerne';
  static const nei = 'Nei takk';

  /// The «asked» memory (a pref in the app; tests swap it).
  static const _prefKey = 'ntf_samtykke_spurt';
  static bool Function() spurt = () => prefGetInt(_prefKey) == 1;
  static void Function() markerSpurt = () => prefSetInt(_prefKey, 1);

  static VarslerInnstKilde Function() kilde = () => VarslerInnstScreen.kilde;

  /// True when the question was shown.
  static Future<bool> kanskje(BuildContext context) async {
    if (spurt()) return false;
    final p = await kilde().hent().catchError((_) => null);
    if (p == null || p.marketing != null) {
      if (p != null) markerSpurt();
      return false;
    }
    markerSpurt();
    if (!context.mounted) return false;
    final svar = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF0E2F3A),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            key: const Key('ntf-samtykke'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(tittel, style: inter(17, weight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(tekst, style: inter(13, color: const Color(0xFFDCE9EC), height: 1.4)),
              const SizedBox(height: 16),
              FilledButton(key: const Key('ntf-samtykke-ja'), onPressed: () => Navigator.pop(ctx, true), child: const Text(ja)),
              TextButton(key: const Key('ntf-samtykke-nei'), onPressed: () => Navigator.pop(ctx, false), child: const Text(nei)),
            ],
          ),
        ),
      ),
    );
    if (svar != null) await kilde().samtykke(svar).catchError((_) => false);
    return true;
  }
}
