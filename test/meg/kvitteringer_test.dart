import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/screens/bergen/meg/kvitteringer_screen.dart';

import '../a3/a3_fakes.dart';

/// Payments plan Step 5: Meg → «Kvitteringer» lists the numbered kvitteringer
/// and kreditnotaer and opens the stored PDF; an empty list says so.
class _Kunde extends OpsCustomerApi {
  _Kunde(this.docs, {this.pdf});

  final List<Map<String, dynamic>> docs;
  final List<int>? pdf;
  final hentet = <int>[];

  @override
  Future<List<Map<String, dynamic>>> documents() async => docs;

  @override
  Future<List<int>?> documentPdf(int documentId) async {
    hentet.add(documentId);
    return pdf;
  }
}

Widget _app(_Kunde api, {Future<void> Function(List<int>, String)? share}) => MaterialApp(home: KvitteringerScreen(api: api, share: share));

void main() {
  setUpAll(() async {
    await a3Bootstrap();
    OpsCustomerApi.networkEnabled = false;
  });

  testWidgets('lists both kinds newest first and opens the stored PDF', (tester) async {
    final api = _Kunde([
      {'id': 9, 'type': 'kreditnota', 'number': 'KN-2026-000001', 'issued_at': '2026-11-13T10:00:00+01:00', 'store_name': 'Torgboden AS', 'total_ore': -3800, 'refers_to': 'KV-2026-000004'},
      {'id': 4, 'type': 'kvittering', 'number': 'KV-2026-000004', 'issued_at': '2026-11-12T18:30:00+01:00', 'store_name': 'Torgboden AS', 'total_ore': 30800},
      {'id': 3, 'type': 'ordrebekreftelse', 'number': 'OB-77', 'issued_at': '2026-11-12T17:00:00+01:00', 'store_name': 'Torgboden AS', 'total_ore': 30800},
      {'type': 'kvittering'},
    ], pdf: const [37, 80, 68, 70]);
    final delt = <String>[];
    await tester.pumpWidget(_app(api, share: (pdf, nr) async => delt.add('$nr:${pdf.length}')));
    await tester.pump();

    expect(find.byKey(const Key('ops-kv-9')), findsOneWidget);
    expect(find.byKey(const Key('ops-kv-4')), findsOneWidget);
    expect(find.textContaining('KN-2026-000001'), findsOneWidget);
    expect(find.textContaining('KV-2026-000004'), findsNWidgets(2), reason: 'its own row and the credit note that refers to it');
    expect(find.textContaining('308'), findsNWidgets(2));
    expect(find.textContaining('OB-77'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);

    await tester.tap(find.byKey(const Key('ops-kv-4')));
    await tester.pump();
    expect(api.hentet, [4]);
    expect(delt, ['KV-2026-000004:4']);
  });

  testWidgets('no documents yet says so', (tester) async {
    await tester.pumpWidget(_app(_Kunde(const [])));
    await tester.pump();
    expect(find.byKey(const Key('ops-kv-ingen')), findsOneWidget);
  });
}
