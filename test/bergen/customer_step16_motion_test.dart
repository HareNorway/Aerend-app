// Customer Step 16 — the lite / still pass: every animated widget this plan
// added honours reduced motion (nothing animates, no delayed start, no timer
// outlives disposal), through the shared contract in test/layout.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/ai/ai_bits.dart';
import 'package:aerend_customer/screens/bergen/ai/ai_tilbud.dart';
import 'package:aerend_customer/screens/bergen/hjem/hjem_kort.dart';
import 'package:aerend_customer/screens/bergen/kit/server_banner.dart';
import 'package:aerend_customer/services/customer/beacons.dart';
import 'package:aerend_customer/services/customer/client_flags.dart';

import '../layout/reduced_motion_harness.dart';

void main() {
  setUpAll(() => bootstrapGlobals(locale: 'no'));

  testWidgets('AiHandshake — kobler / koblet / brutt / ukoblet', (tester) async {
    for (final m in ['kobler', 'koblet', 'brutt', 'ukoblet']) {
      await expectRespectsReducedMotion(tester, () => AiHandshake(modus: m, navn: 'Claude', linje: 'Venter på svaret ditt'), reason: 'AiHandshake $m');
    }
  });

  testWidgets('AiFrist — the countdown ring', (tester) async {
    await expectRespectsReducedMotion(tester, () => const AiFrist(sekunder: 540, label: 'Bekreft innen'));
  });

  testWidgets('AiTilbud — the offer card with the live countdown', (tester) async {
    await expectRespectsReducedMotion(tester, () => SizedBox(width: 360, height: 560, child: SingleChildScrollView(child: AiTilbud(r: aiSampleRequest(), venter: false))));
  });

  testWidgets('AiBanner, AiViaChip, AiMerke', (tester) async {
    await expectRespectsReducedMotion(tester, () => const AiBanner(tone: 'gul', tittel: 'Tilbudet har utløpt', tekst: 'Vi har hentet et nytt.', ikon: AiIk.lyn));
    await expectRespectsReducedMotion(tester, () => const AiViaChip('Claude'));
    await expectRespectsReducedMotion(tester, () => const AiMerke('Claude', size: 36));
  });

  testWidgets('Hjem\'s AI marks pill', (tester) async {
    await expectRespectsReducedMotion(tester, () => HjemAiMerker(onTap: () {}));
  });

  testWidgets('the server banner', (tester) async {
    ClientFlags.applyAgents(const CusClientFlags(bannerNo: 'Vi oppgraderer i natt.', bannerLevel: 'warning'));
    await expectRespectsReducedMotion(tester, () => const SizedBox(width: 360, child: CusServerBanner()));
    ClientFlags.resetAgents();
  });
}
