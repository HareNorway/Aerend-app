import 'package:flutter/widgets.dart';

import 'kit/bergen_routes.dart';
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
  // Phase 2
  '/bergen/utforsk': (_) => const UtforskScreen(embedded: false),
};
