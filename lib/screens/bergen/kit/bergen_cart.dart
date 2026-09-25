import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/guest_auth_helper.dart';
import '../../../utils/utils.dart';
import '../../common/homeMainV1/home_main_v1.dart';
import '../../deliveryService/storeDetail/store_detail_dl.dart';
import '../../deliveryService/storeDetail/store_detail_repo.dart';
import 'bergen_toast.dart';

/// One add-to-cart for every Bergen product surface (AGIL-1 v2 Phase 2–4).
///
/// The existing cart API and the nav pill's badge, so "add-to-cart from every
/// product surface changes the nav pill count" is one code path rather than
/// five. Guests are asked to log in first; a rejected add shows the server's
/// message and leaves the badge alone.
abstract final class BergenCart {
  static Future<bool> add(
    BuildContext context, {
    required int storeId,
    required int productId,
    int quantity = 1,
    String? toast,
  }) async {
    if (storeId == 0 || productId == 0) {
      showBergenToast(context, 'Kommer snart');
      return false;
    }
    if (!await showGuestLoginSheet(
      context,
      prompt: GuestLoginPrompt.checkout,
    )) {
      return false;
    }
    if (!context.mounted) return false;
    HapticFeedback.selectionClick();
    try {
      final response = UserOrderCartPojo.fromJson(
        await StoreDetailRepo().callOrderCartApi(storeId, productId, quantity),
      );
      if (!context.mounted) return false;
      if (response.messageCode == 1) {
        prefSetInt(prefCartCount, response.countOrder);
        syncBadge(context, response.countOrder);
        showBergenToast(context, toast ?? response.message);
        return true;
      }
      showBergenToast(context, response.message);
      return false;
    } catch (e) {
      if (context.mounted) showBergenToast(context, e.toString());
      return false;
    }
  }

  /// Push the count into the shell's nav pill when the shell is an ancestor.
  static void syncBadge(BuildContext context, [int? count]) {
    final shell = context.findAncestorStateOfType<HomeMainV1State>();
    if (shell != null) {
      shell.badgeCountNotifier.value = count ?? prefGetInt(prefCartCount);
    }
  }
}
