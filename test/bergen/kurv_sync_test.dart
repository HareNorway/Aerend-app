import 'dart:async';

import 'package:aerend_customer/data/ops/kasse_models.dart';
import 'package:aerend_customer/screens/bergen/kasse/kurv_sync.dart';
import 'package:flutter_test/flutter_test.dart';

/// Bug-10 (TestFlight feedback 2026-11-14, «These functions are lagging a lot»): the basket's − / + move the number at
/// once and the queue sends them — one request per line at a time, quick taps merged, one reload when all are in.
void main() {
  const linje = KurvLine(cartId: 7, productId: 1, name: 'Tempura Scampi Roll', quantity: 1, unitPrice: 5, storeId: 43);

  test('apply: the new quantity at once; 0 removes the line', () {
    expect(KurvSync.apply(const [linje], 7, 3).single.quantity, 3);
    expect(KurvSync.apply(const [linje], 7, 3).single.sum, 15);
    expect(KurvSync.apply(const [linje], 7, 0), isEmpty);
  });

  test('taps while a request is on its way merge into the latest quantity; one reload when settled', () async {
    final sendt = <int>[];
    final svar = <Completer<bool>>[];
    var lastet = 0, feilet = 0;
    final sync = KurvSync(
      change: (id, q) {
        sendt.add(q);
        final c = Completer<bool>();
        svar.add(c);
        return c.future;
      },
      remove: (id) async => true,
      onSettled: () => lastet++,
      onFailed: () => feilet++,
    );
    sync.set(7, 2); // the first tap goes out
    sync.set(7, 3); // these two wait …
    sync.set(7, 4); // … and merge
    expect(sendt, [2]);
    expect(sync.busy, isTrue);
    svar.first.complete(true);
    await Future<void>.delayed(Duration.zero);
    expect(sendt, [2, 4], reason: 'one request for the latest quantity, not one per tap');
    svar.last.complete(true);
    await Future<void>.delayed(Duration.zero);
    expect(sync.busy, isFalse);
    expect([lastet, feilet], [1, 0]);
  });

  test('a refused change reloads the server basket instead (onFailed), and 0 removes', () async {
    final fjernet = <int>[];
    var lastet = 0, feilet = 0;
    final sync = KurvSync(
      change: (id, q) async => false,
      remove: (id) async {
        fjernet.add(id);
        return true;
      },
      onSettled: () => lastet++,
      onFailed: () => feilet++,
    );
    sync.set(7, 5);
    await Future<void>.delayed(Duration.zero);
    expect([lastet, feilet], [0, 1]);
    sync.set(9, 0);
    await Future<void>.delayed(Duration.zero);
    expect(fjernet, [9]);
    expect([lastet, feilet], [1, 1]);
  });
}
