import 'package:flutter/widgets.dart';

import 'butikk/automat_screen.dart';
import 'butikk/butikk_screen.dart';
import 'butikk/kategori_screen.dart';
import 'kasse/bestilling_sheet.dart';
import 'kasse/kurv_screen.dart';
import 'kit/bergen_routes.dart';
import 'sok/sok_screen.dart';
import 'sporing/hjelp_sheet.dart';
import 'sporing/levert_screen.dart';
import 'sporing/sporing_screen.dart';
import 'utforsk/feed_nyheter_screen.dart';
import 'utforsk/utforsk_screen.dart';

/// agil-1 named routes (AGIL-CONTRACT §2.2, §3.4). Filled phase by phase by
/// the AGIL-1 v2 plan; agil-3 never edits it.
///
/// Parameters travel in `RouteSettings.arguments` (a `Map<String, String>`
/// with `id` / `slug` / the query), resolved by `BergenRoutes` in the kit —
/// so `/bergen/butikk/{id}` is registered as `/bergen/butikk`.
///
/// Reserved names: /bergen/sok, /bergen/butikk/{id}, /bergen/kategori/{slug},
/// /bergen/automat, /bergen/kurv, /bergen/bestilling/{id},
/// /bergen/sporing/{id}, /bergen/sporing/{id}/hjelp, /bergen/levert/{id},
/// /bergen/utforsk, /bergen/kundeservice.
Map<String, WidgetBuilder> bergenRoutesAgil1() => <String, WidgetBuilder>{
  // Phase 3
  '/bergen/sok': (_) => const SokScreen(),
  // Phase 4 — parameters arrive as `RouteSettings.arguments` (see BergenRoutes).
  '/bergen/kategori': (_) => const KategoriScreen(),
  '/bergen/butikk': (_) => const ButikkScreen(),
  '/bergen/automat': (_) => const AutomatScreen(),
  // Phase 5
  '/bergen/kurv': (_) => const KurvScreen(embedded: false),
  '/bergen/bestilling': (_) => const BestillingScreen(),
  // Phase 6
  '/bergen/sporing': (_) => const SporingScreen(),
  '/bergen/sporing/hjelp': (_) => const HjelpScreen(),
  '/bergen/levert': (_) => const LevertScreen(),
  '/bergen/kundeservice': (_) => const KundeserviceScreen(),
  // Phase 2. `?tab=feed` (agil-3's Meg row "Nytt fra butikkene") is the
  // design's `feed` screen; any other tab opens Utforsk on that segment.
  '/bergen/utforsk': (ctx) {
    final tab = BergenRoutes.argsOf(ctx)['tab'];
    if (tab == UtforskScreen.tabFeed) return const FeedNyheterScreen();
    return UtforskScreen(embedded: false, initialTab: tab);
  },
};
