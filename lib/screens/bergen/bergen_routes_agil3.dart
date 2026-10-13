import 'package:flutter/widgets.dart';

import 'aegil/aegil_screen.dart';
import 'meg/bestillinger_screen.dart';
import 'meg/favoritter_screen.dart';
import 'meg/konto_screen.dart';
import 'meg/meg_screen.dart';
import 'hjem/hjem_varsler.dart';
import 'kit/bergen_routes.dart';
import 'kit/bergen_videre.dart';
import 'fiske/fjordfiske_screen.dart';
import 'poeng/liga_screen.dart';
import 'poeng/opprykk_screen.dart';
import 'poeng/premiehylla_screen.dart';

/// agil-3 named routes (AGIL-CONTRACT §2.2, §3.4). `main.dart` spreads it
/// into `MaterialApp.routes` next to [bergenRoutesAgil1].
///
/// Gap Step 4: three early pages are gone; their names stay as redirects so
/// old push deep links still land (gap plan G3):
/// - `/bergen/poeng` → Meg with «Poeng, nivå og konkurranser» open;
/// - `/bergen/premie/{id}` → Premiehylla (prizes are claimed there);
/// - `/bergen/meg/varsler` → the Varsler panel.
Map<String, WidgetBuilder> bergenRoutesAgil3() => <String, WidgetBuilder>{
      '/bergen/poeng': (_) => BergenVidere((nav) => BergenVidere.tilMeg(nav, poeng: true)),
      '/bergen/premiehylla': (_) => const PremiehyllaScreen(),
      '/bergen/premie': (_) => BergenVidere((nav) => nav.pushNamed('/bergen/premiehylla')),
      '/bergen/liga': (_) => const LigaScreen(),
      '/bergen/opprykk': (ctx) {
        final arg = ModalRoute.of(ctx)?.settings.arguments;
        final m = arg is Map ? arg : const {};
        return OpprykkScreen(tierName: m['tier_name'] as String?, giftName: m['gift'] as String?);
      },
      '/bergen/fjordfiske': (_) => const FjordfiskeScreen(),
      '/bergen/aegil': (_) => const AegilScreen(),
      '/bergen/aegil/minne': (_) => const AegilScreen(steg: 'minne'),
      // Gap Step 1: «Innstillinger for varsler» in the Varsler panel.
      '/bergen/aegil/nivaa': (_) => const AegilScreen(steg: 'nivaa'),
      '/bergen/meg': (_) => const MegScreenBody(),
      '/bergen/meg/favoritter': (ctx) {
        final a = BergenRoutes.argsOf(ctx);
        return FavoritterScreen(fane: (a['fane'] ?? a['id']) == 'produkter' ? 'produkter' : 'butikker');
      },
      '/bergen/meg/konto': (_) => const KontoScreen(),
      '/bergen/meg/bestillinger': (_) => const BestillingerScreen(),
      '/bergen/meg/varsler': (_) => BergenVidere((nav) => HjemVarsler.apne(nav.context)),
    };
