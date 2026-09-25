import 'package:flutter/widgets.dart';

/// agil-3 named routes (AGIL-CONTRACT §2.2, §3.4). Sync C ships this empty;
/// agil-3 fills it and nobody else edits it. `main.dart` spreads it into
/// `MaterialApp.routes` next to [bergenRoutesAgil1].
///
/// Reserved names: /bergen/poeng, /bergen/premiehylla, /bergen/premie/{id},
/// /bergen/liga, /bergen/opprykk, /bergen/fjordfiske, /bergen/aegil,
/// /bergen/aegil/minne, /bergen/meg, /bergen/meg/favoritter, /bergen/meg/konto,
/// /bergen/meg/bestillinger, /bergen/meg/varsler.
Map<String, WidgetBuilder> bergenRoutesAgil3() => <String, WidgetBuilder>{};
