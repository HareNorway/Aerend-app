import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/customer/beacons.dart';
import '../../../services/customer/client_flags.dart';
import '../../../utils/shared_pref_utill.dart';
import '../../common/auth/launch/lf_css.dart';
import '../aegil/aegil_bits.dart' show AeIkon;
import '../ai/ai_bits.dart' show AiIk;
import '../meg/meg_ark.dart';

/// Customer Step 16: the server banner from `agents/flags` (a line the
/// operators set per app version: info / warning / critical), shown at the
/// top of the shell over every tab; the customer can tuck it away for this
/// run. Styled as the design's banner (`aiBanner` tones).
class CusServerBanner extends StatefulWidget {
  const CusServerBanner({super.key});

  /// Hidden for this run once the customer closed it (the text stays the key).
  static String? lukket;

  @override
  State<CusServerBanner> createState() => _CusServerBannerState();
}

class _CusServerBannerState extends State<CusServerBanner> {
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<CusClientFlags?>(
    valueListenable: ClientFlags.agents,
    builder: (context, f, _) {
      final lang = prefGetStringWithDefaultValue(prefSelectedLanguageCode, 'no');
      final tekst = f?.banner(lang);
      if (tekst == null || tekst == CusServerBanner.lukket) return const SizedBox.shrink();
      final (bg, bd, c, ik) = switch (f!.bannerLevel) {
        'critical' => (const Color.fromRGBO(242, 109, 61, .22), const Color.fromRGBO(249, 162, 115, .6), const Color(0xFFFFC8A8), AiIk.advarsel),
        'warning' => (const Color.fromRGBO(245, 196, 81, .2), const Color.fromRGBO(245, 196, 81, .55), const Color(0xFFFFE08A), AiIk.advarsel),
        _ => (const Color.fromRGBO(23, 62, 72, .92), const Color.fromRGBO(255, 255, 255, .22), Colors.white, AiIk.info),
      };
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
        child: Container(
          key: const Key('cus-server-banner'),
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: bg,
            border: Border.all(color: bd),
            boxShadow: const [BoxShadow(color: Color.fromRGBO(4, 18, 26, .5), offset: Offset(0, 8), blurRadius: 16 / 2 / .57735, spreadRadius: -8)],
          ),
          child: Row(children: [
            AeIkon(ik, size: 15, stroke: 2.4, color: c),
            const SizedBox(width: 9),
            Expanded(child: Text(tekst, maxLines: 3, overflow: TextOverflow.ellipsis, style: inter(12.5, weight: FontWeight.w700, height: 1.3, color: c))),
            const SizedBox(width: 6),
            Semantics(
              button: true,
              label: 'Lukk',
              child: GestureDetector(
                key: const Key('cus-server-banner-lukk'),
                onTap: () => setState(() => CusServerBanner.lukket = tekst),
                behavior: HitTestBehavior.opaque,
                child: Padding(padding: const EdgeInsets.all(6), child: AeIkon(AiIk.kryss, size: 12, stroke: 2.6, color: c)),
              ),
            ),
          ]),
        ),
      );
    },
  );
}

/// The `min_version` prompt: a dark Ark that cannot be swiped away while the
/// installed version is older than what the server allows. «Åpne App Store»
/// opens the store listing.
abstract final class CusOppdaterArk {
  static bool _vist = false;

  static String get storeUrl => Platform.isAndroid ? 'market://details?id=no.aerend.customer' : 'https://apps.apple.com/app/id6825240770';

  /// Shows the prompt once per run when [f] requires an update for [version].
  static Future<void> visHvis(BuildContext context, CusClientFlags? f, String version) async {
    if (f == null || _vist || !f.needsUpdate(version)) return;
    _vist = true;
    await vis(context, f.minVersion ?? '');
  }

  @visibleForTesting
  static void reset() => _vist = false;

  static Future<void> vis(BuildContext context, String minVersion) => showMegArk<void>(
    context,
    key: const Key('cus-oppdater'),
    mork: true,
    title: _t('Oppdater Ærend', 'Update Ærend'),
    subtitle: _t('Denne versjonen er for gammel til å bestille trygt. Hent den nye fra App Store, så er du i gang igjen.', 'This version is too old to order safely. Get the new one from the App Store and you are back on.'),
    body: (ctx, _) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: const Color.fromRGBO(255, 255, 255, .08), border: Border.all(color: const Color.fromRGBO(255, 255, 255, .14))),
        child: Row(children: [
          const AeIkon(AiIk.lyn, size: 16, stroke: 2.4, color: Color(0xFFF2C14E)),
          const SizedBox(width: 10),
          Expanded(child: Text(minVersion.isEmpty ? _t('En ny versjon venter.', 'A new version is waiting.') : _t('Krever versjon $minVersion eller nyere.', 'Needs version $minVersion or newer.'), style: inter(13, weight: FontWeight.w700))),
        ]),
      ),
    ]),
    primary: MegArkButton(
      key: const Key('cus-oppdater-cta'),
      label: _t('Åpne App Store', 'Open the App Store'),
      onTap: () => launchUrl(Uri.parse(storeUrl), mode: LaunchMode.externalApplication).catchError((_) => false),
    ),
  );

  static String _t(String no, String en) => prefGetStringWithDefaultValue(prefSelectedLanguageCode, 'no') == 'en' ? en : no;
}
