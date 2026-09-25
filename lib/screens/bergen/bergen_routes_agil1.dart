import 'package:flutter/widgets.dart';

/// agil-1 named routes (AGIL-CONTRACT §2.2, §3.4). Filled phase by phase by
/// the AGIL-1 v2 plan; agil-3 never edits it.
///
/// Reserved names: /bergen/sok, /bergen/butikk/{id}, /bergen/kategori/{slug},
/// /bergen/automat, /bergen/kurv, /bergen/bestilling/{id},
/// /bergen/sporing/{id}, /bergen/sporing/{id}/hjelp, /bergen/levert/{id},
/// /bergen/utforsk, /bergen/kundeservice.
Map<String, WidgetBuilder> bergenRoutesAgil1() => <String, WidgetBuilder>{};
