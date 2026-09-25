import 'package:flutter/widgets.dart';

import '../../data/points/points_models.dart';
import 'aegil/aegil_screen.dart';
import 'aegil/minne_screen.dart';
import 'meg/bestillinger_screen.dart';
import 'meg/favoritter_screen.dart';
import 'meg/konto_screen.dart';
import 'meg/meg_screen.dart';
import 'meg/varsler_panel.dart';
import 'poeng/fjordfiske_screen.dart';
import 'poeng/liga_screen.dart';
import 'poeng/opprykk_screen.dart';
import 'poeng/poeng_screen.dart';
import 'poeng/premie_screen.dart';
import 'poeng/premiehylla_screen.dart';

/// agil-3 named routes (AGIL-CONTRACT §2.2, §3.4). `main.dart` spreads it
/// into `MaterialApp.routes` next to [bergenRoutesAgil1].
///
/// `/bergen/premie/{id}`: pushed as `/bergen/premie` with a [Prize] or an
/// `int` id as the route argument (Flutter's route table has no path params).
Map<String, WidgetBuilder> bergenRoutesAgil3() => <String, WidgetBuilder>{
      '/bergen/poeng': (_) => const PoengScreen(),
      '/bergen/premiehylla': (_) => const PremiehyllaScreen(),
      '/bergen/premie': (ctx) {
        final arg = ModalRoute.of(ctx)?.settings.arguments;
        return PremieScreen(prize: arg is Prize ? arg : null, prizeId: arg is int ? arg : null);
      },
      '/bergen/liga': (_) => const LigaScreen(),
      '/bergen/opprykk': (ctx) {
        final arg = ModalRoute.of(ctx)?.settings.arguments;
        final m = arg is Map ? arg : const {};
        return OpprykkScreen(tierName: m['tier_name'] as String?, giftName: m['gift'] as String?);
      },
      '/bergen/fjordfiske': (_) => const FjordfiskeScreen(),
      '/bergen/aegil': (_) => const AegilScreen(),
      '/bergen/aegil/minne': (_) => const MinneScreen(),
      '/bergen/meg': (_) => const MegScreenBody(),
      '/bergen/meg/favoritter': (_) => const FavoritterScreen(),
      '/bergen/meg/konto': (_) => const KontoScreen(),
      '/bergen/meg/bestillinger': (_) => const BestillingerScreen(),
      '/bergen/meg/varsler': (_) => const VarslerScreen(),
    };
