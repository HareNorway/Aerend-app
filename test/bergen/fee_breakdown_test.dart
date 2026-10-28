import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aerend_customer/data/ops/fee_quote.dart';
import 'package:aerend_customer/data/ops/tracking_models.dart';
import 'package:aerend_customer/networking/ops/cus_api.dart';
import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/screens/bergen/ai/ai_tilbud.dart';
import 'package:aerend_customer/screens/bergen/sporing/sporing_panel.dart';

import '../layout/reduced_motion_harness.dart';

/// Customer v2 Step 1: the engine's fee lines read the same in Kassen, the
/// agentic basket and the tracking details (`FeeBreakdown` on the backend).
Map<String, dynamic> _breakdown({bool flex = false}) => {
  'quote_id': 'fq_abc',
  'total_ore': flex ? 3100 : 4100,
  'total': flex ? '31 kr' : '41 kr',
  'flex': flex,
  'lines': [
    {'key': 'base', 'label': 'Grunnpris', 'amount_ore': 3500, 'amount': '35 kr', 'detail': 'inkl. 2,0 km'},
    {'key': 'distance', 'label': 'Avstand', 'amount_ore': 600, 'amount': '6 kr', 'detail': '2,8 km'},
    if (flex) {'key': 'flex', 'label': 'Innen 2 timer', 'amount_ore': -1000, 'amount': '−10 kr', 'detail': ''},
  ],
};

void _frame(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() async {
    await bootstrapGlobals();
    OpsCustomerApi.networkEnabled = false;
  });
  tearDownAll(() => OpsCustomerApi.networkEnabled = true);

  test('the three shapes parse to one view; a preview without a quote is null', () {
    final p = FeeQuoteView.fromPreview({
      'quote_id': 'fq_p',
      'fee_total_ore': 4100,
      'fee_components': _breakdown()['lines'],
      'quote_expires_at': '2026-10-28T12:10:00+00:00',
      'flex': true,
    })!;
    expect(p.quoteId, 'fq_p');
    expect(p.totalKr, 41);
    expect(p.lines.map((l) => l.key), ['base', 'distance']);
    expect(p.flex, isTrue);
    expect(p.isExpired(DateTime.utc(2026, 10, 28, 12, 11)), isTrue);
    expect(FeeQuoteView.fromPreview({'status': 1, 'delivery_cost': 39}), isNull);

    final a = FeeQuoteView.fromApi({'quote_id': 'fq_a', 'total_ore': 4900, 'components': _breakdown()['lines'], 'expires_at': '2026-10-28T12:10:00Z'})!;
    expect(a.totalOre, 4900);
    expect(a.lines, hasLength(2));

    final b = FeeQuoteView.fromBreakdown(_breakdown(flex: true))!;
    expect(b.lines.last.amountOre, -1000);
    expect(b.flex, isTrue);
    expect(FeeQuoteView.fromBreakdown(null), isNull);
  });

  testWidgets('the agentic basket: «Levering ›» opens the engine\'s lines', (tester) async {
    _frame(tester);
    final r = CusAiRequest.fromJson({
      'id': 'req_1',
      'assistant': {'name': 'Claude', 'vendor': 'anthropic'},
      'store': {'name': 'Sandviken Bakeri'},
      'quote': {
        'subtotal': {'ore': 4900, 'display': '49 kr'},
        'delivery_fee': {'ore': 4100, 'display': '41 kr'},
        'service_fee': {'ore': 0, 'display': '0 kr'},
        'total': {'ore': 9000, 'display': '90 kr'},
        'delivery_breakdown': _breakdown(),
      },
    });
    expect(r.deliveryBreakdown?.quoteId, 'fq_abc');
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: AiTilbud(r: r, venter: false, visFrist: false)))));
    await tester.pump(const Duration(seconds: 2));
    await tester.ensureVisible(find.byKey(const Key('cus-ai-levering')));
    await tester.tap(find.byKey(const Key('cus-ai-levering')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('fee_breakdown_sheet')), findsOneWidget);
    expect(find.text('Grunnpris'), findsOneWidget);
    expect(find.text('Avstand'), findsOneWidget);
  });

  testWidgets('the agentic basket without the engine keeps the plain row', (tester) async {
    _frame(tester);
    final r = CusAiRequest.fromJson({
      'id': 'req_2',
      'quote': {'delivery_fee': {'ore': 3900, 'display': '39 kr'}, 'total': {'ore': 3900, 'display': '39 kr'}},
    });
    expect(r.deliveryBreakdown, isNull);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: AiTilbud(r: r, venter: false, visFrist: false)))));
    await tester.pump(const Duration(seconds: 2));
    expect(find.byKey(const Key('cus-ai-levering')), findsNothing);
  });

  testWidgets('the tracking details: «Levering ›» with the 2-hour window opens the charged quote', (tester) async {
    _frame(tester);
    final t = OpsTracking.fromJson({
      'order_id': '4471',
      'code': 'Æ-42K',
      'mode': 'delivery',
      'state': 'picked_up',
      'stage': 2,
      'stage_label': 'På vei',
      'store': {'id': 45, 'name': 'Sandviken Bakeri', 'address': 'Bryggen 7'},
      'delivery_address': 'Nygårdsgaten 5',
      'fee_breakdown': _breakdown(flex: true),
    });
    final ordre = SpOrdre(
      linjer: const [SpLinje(navn: 'Kanelbolle', antall: 2, sum: 78)],
      total: 109,
      adresse: 'Nygårdsgaten 5, 5015 Bergen',
      bestilt: DateTime(2026, 10, 21, 18, 4),
      butikk: 'Sandviken Bakeri',
      butikkAdresse: 'Bryggen 7',
      ordreNr: 'ÆR-1234',
      kode: 'Æ-42K',
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SpDetaljerArk(
          ark: SpArk.detaljer,
          tracking: t,
          ordre: ordre,
          height: 844,
          onLukk: () {},
          onDetaljer: () {},
          onKvittering: () {},
          onKundeservice: () {},
          onRingButikk: () {},
        ),
      ),
    ));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Innen 2 timer'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('a1_sporing_levering')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('a1_sporing_levering')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('fee_breakdown_sheet')), findsOneWidget);
    expect(find.text('−10 kr'), findsOneWidget);
  });
}
