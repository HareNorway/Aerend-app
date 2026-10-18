import 'package:flutter/widgets.dart';

import 'butikk/automat_screen.dart';
import 'butikk/butikk_screen.dart';
import 'butikk/kategori_screen.dart';
import 'hurtig/hurtig_screen.dart';
import 'kasse/bestilling_sheet.dart';
import 'kasse/kurv_screen.dart';
import 'kit/bergen_routes.dart';
import 'sok/sok_screen.dart';
import 'sporing/hjelp_sheet.dart';
import 'sporing/sporing_screen.dart';
import 'utforsk/butikk_profil.dart';
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
  // Bergen Step 4: the store's page in Ærend Feed (`/bergen/butikkprofil/{id}`).
  '/bergen/butikkprofil': (_) => const ButikkProfilScreen(),
  '/bergen/automat': (_) => const AutomatScreen(),
  // Phase 5
  '/bergen/kurv': (_) => const KurvScreen(embedded: false),
  // Step 7 (Launch): Hurtigbestilling.
  '/bergen/hurtig': (_) => const HurtigScreen(),
  '/bergen/bestilling': (_) => const BestillingScreen(),
  // Phase 6
  '/bergen/sporing': (_) => const SporingScreen(),
  '/bergen/sporing/hjelp': (_) => const HjelpScreen(),
  // The separate «Levert» page is removed; the name stays reserved and opens
  // Sporing for the order, which shows the delivered state.
  '/bergen/levert': (_) => const SporingScreen(),
  '/bergen/kundeservice': (_) => const KundeserviceScreen(),
  // Phase 2: Utforsk on the segment in `?tab=` (feed / fiske / pose). The
  // old separate «Nytt fra butikkene» page is gone (Gap Step 4).
  '/bergen/utforsk': (ctx) => UtforskScreen(embedded: false, initialTab: BergenRoutes.argsOf(ctx)['tab']),
};
