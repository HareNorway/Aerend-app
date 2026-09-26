import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aerend_customer/l10n/app_localizations.dart';
import 'package:aerend_customer/main.dart' as app;
import 'package:aerend_customer/screens/bergen/fiske/fjordfiske_screen.dart';
import 'package:aerend_customer/utils/shared_pref_utill.dart';

/// Fjordfiske against the **live** local backend (no fakes): the screen is
/// pumped as the logged-in customer from `--dart-define=FISKE_USER=…` /
/// `FISKE_TOKEN=…`, held for a screenshot, then cast once. Local dev only.
///
///   flutter test integration_test/fiske_live_test.dart -d <sim> \
///     --dart-define=FISKE_USER=656 --dart-define=FISKE_TOKEN=…
const _user = int.fromEnvironment('FISKE_USER');
const _token = String.fromEnvironment('FISKE_TOKEN');

Future<void> _hold(WidgetTester tester, String state, [int ms = 5000]) async {
  await tester.pump();
  await tester.runAsync(() async {
    final dir = await getApplicationDocumentsDirectory();
    File('${dir.path}/fiske_state.txt').writeAsStringSync(state);
    await Future<void>.delayed(Duration(milliseconds: ms));
  });
  await tester.pump();
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('Fjordfiske with the live tray', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      prefUserId: _user,
      prefAccessToken: _token,
      'userName': 'Live',
    });
    await initSharedPreferences();
    app.languages = await AppLocalizations.delegate.load(const Locale('no'));

    await tester.pumpWidget(
      const MaterialApp(debugShowCheckedModeBanner: false, home: FjordfiskeScreen()),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 4)));
    await tester.pump();
    await _hold(tester, 'live_idle');

    final kast = find.byKey(const Key('a1_fiske_kast'));
    if (kast.evaluate().isNotEmpty) {
      await tester.tap(kast);
      for (var waited = 0; waited < 4000; waited += 100) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byKey(const Key('a1_fiske_dra')).evaluate().isNotEmpty) break;
      }
      await tester.tap(find.byKey(const Key('a1_fiske_dra')));
      await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
      await tester.pump();
      await _hold(tester, 'live_catch');
    }
    await _hold(tester, 'live_done', 500);
  });
}
