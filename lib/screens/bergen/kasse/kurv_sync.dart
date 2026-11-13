import 'dart:async';

import '../../../data/ops/kasse_models.dart';

/// Bug-10 (TestFlight feedback 2026-11-14, «These functions are lagging a lot»): the basket's − / + used to wait for
/// the server twice (the change, then the whole basket) before the number moved — up to five requests in Kassen.
///
/// The screen now shows the new quantity at once ([apply]) and this queue sends it: one request per line at a time,
/// and taps that come while one is on its way are merged into the latest quantity (three quick + taps = one request
/// for +3). When every line is settled, [onSettled] runs once (the screen reloads the basket for prices and fees); a
/// refused change runs [onFailed] (the screen reloads the server's basket — the truth — and says so).
class KurvSync {
  KurvSync({required this.change, required this.remove, required this.onSettled, required this.onFailed});

  /// `changeQuantity(cartId, quantity)` / `remove(cartId)`: true when the server took it.
  final Future<bool> Function(int cartId, int quantity) change;
  final Future<bool> Function(int cartId) remove;
  final void Function() onSettled;
  final void Function() onFailed;

  final Map<int, int> _onsket = <int, int>{};
  final Set<int> _sender = <int>{};
  bool _feilet = false;

  /// Something is still on its way (the screen keeps its own numbers until it is not).
  bool get busy => _sender.isNotEmpty || _onsket.isNotEmpty;

  /// The basket with [cartId] at [quantity] (0 or less: the line is gone) — what the screen shows now.
  static List<KurvLine> apply(List<KurvLine> lines, int cartId, int quantity) => <KurvLine>[
        for (final KurvLine l in lines)
          if (l.cartId != cartId)
            l
          else if (quantity > 0)
            KurvLine(
              cartId: l.cartId,
              productId: l.productId,
              name: l.name,
              quantity: quantity,
              unitPrice: l.unitPrice,
              storeId: l.storeId,
              imageUrl: l.imageUrl,
              description: l.description,
              addedByAegil: l.addedByAegil,
            ),
      ];

  /// Ask for [cartId] at [quantity]; sends now, or after the request already on its way for that line.
  void set(int cartId, int quantity) {
    _onsket[cartId] = quantity;
    unawaited(_pump(cartId));
  }

  Future<void> _pump(int cartId) async {
    if (_sender.contains(cartId)) return;
    _sender.add(cartId);
    try {
      while (_onsket.containsKey(cartId)) {
        final int q = _onsket.remove(cartId)!;
        bool ok;
        try {
          ok = q <= 0 ? await remove(cartId) : await change(cartId, q);
        } catch (_) {
          ok = false;
        }
        if (!ok) {
          _onsket.remove(cartId);
          _feilet = true;
          break;
        }
      }
    } finally {
      _sender.remove(cartId);
    }
    if (!busy) {
      final bool feil = _feilet;
      _feilet = false;
      feil ? onFailed() : onSettled();
    }
  }
}
