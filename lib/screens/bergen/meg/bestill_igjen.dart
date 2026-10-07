import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../networking/ops/ops_kasse_api.dart';
import '../../../utils/utils.dart';
import '../../common/homeMainV1/home_main_v1.dart';
import '../../deliveryService/storeDetail/store_detail_repo.dart';
import '../kit/bergen_kit.dart';

/// «Bestill igjen»: an earlier order's lines into the basket, then the
/// basket. Shared by Ordrehistorikk and Hjem's Vindu (backend plan Step 8).
/// The basket holds one store, so another store's lines make way. Paying
/// stays in Kurv.
///
/// [linjer] are the order's rows from `ops.customer.orders` (`product_id`,
/// `quantity`). Returns false when nothing could be added (the toast says
/// «Kommer snart», as before).
Future<bool> bestillIgjen(
  BuildContext context, {
  required OpsKasseApi kasse,
  required int storeId,
  required String butikk,
  required List<Map<String, dynamic>> linjer,
}) async {
  var cart = await kasse.cart();
  if (!cart.isEmpty && cart.storeId != storeId) {
    for (final l in cart.lines) {
      await kasse.remove(l.cartId);
    }
  }
  for (final l in linjer) {
    final pid = (l['product_id'] as num?)?.toInt();
    if (pid == null) continue;
    prefSetInt('checkedSize', 0);
    prefSetInt('checkedColor', 0);
    prefSetString('checkedOptionList', jsonEncode(const <int>[]));
    try {
      await StoreDetailRepo().callOrderCartApi(storeId, pid, ((l['quantity'] ?? 1) as num).toInt());
    } catch (_) {}
  }
  cart = await kasse.cart();
  if (!context.mounted) return false;
  prefSetInt(prefCartCount, cart.lines.length);
  BergenCart.syncBadge(context, cart.lines.length);
  if (cart.isEmpty) {
    showBergenToast(context, BergenRoutes.kommerSnart);
    return false;
  }
  final n = linjer.length;
  showBergenToast(context, '$n ${n == 1 ? 'linje' : 'linjer'} fra $butikk lagt i kurven');
  final shell = HomeMainV1State.current;
  Navigator.of(context).popUntil((r) => r.isFirst);
  shell?.switchToTab(2);
  return true;
}
