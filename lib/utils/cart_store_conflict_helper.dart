import 'package:flutter/material.dart';

import '../dialogs/simple_dialog_util.dart';
import '../screens/common/homeMainV1/home_main_v1.dart';
import '../screens/common/orderCart/order_cart_repo.dart';
import '../screens/deliveryService/storeDetail/store_detail_dl.dart';
import '../screens/deliveryService/storeDetail/store_detail_repo.dart';
import 'utils.dart';

/// Handles API `message_code` 412 — cart already has items from another store.
Future<bool> addToCartResolvingStoreConflict({
  required BuildContext context,
  required int storeId,
  required int productId,
  int quantity = 1,
}) async {
  Future<UserOrderCartPojo> callAdd() async {
    return UserOrderCartPojo.fromJson(
      await StoreDetailRepo().callOrderCartApi(storeId, productId, quantity),
    );
  }

  var response = await callAdd();
  if (response.messageCode == 1) {
    _applyCartAddSuccess(context, response);
    return true;
  }

  if (response.messageCode != 412) {
    if (response.message.isNotEmpty) {
      openSimpleSnackbar(response.message);
    }
    return false;
  }

  if (!context.mounted) return false;

  final bool? shouldClear = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return SimpleDialogUtil(
        title: 'Different restaurant in cart',
        message:
            'Your cart has items from another restaurant. Clear the cart and add from this restaurant instead?',
        positiveButtonTxt: 'Clear cart & add',
        negativeButtonTxt: languages.cancel,
        onPositivePress: () => Navigator.pop(dialogContext, true),
        onNegativePress: () => Navigator.pop(dialogContext, false),
      );
    },
  );

  if (shouldClear != true || !context.mounted) return false;

  await OrderCartRepo().clearAllCartItems();
  _syncCartBadge(0);

  response = await callAdd();
  if (response.messageCode == 1) {
    _applyCartAddSuccess(context, response);
    return true;
  }

  if (response.message.isNotEmpty) {
    openSimpleSnackbar(response.message);
  }
  return false;
}

void _applyCartAddSuccess(BuildContext context, UserOrderCartPojo response) {
  if (response.message.isNotEmpty) {
    openSimpleSnackbar(response.message, duration: 1);
  }
  _syncCartBadge(response.countOrder);
}

void _syncCartBadge(int count) {
  prefSetInt(prefCartCount, count);
  final HomeMainV1State? homeState =
      navigatorKey.currentContext?.findAncestorStateOfType<HomeMainV1State>();
  if (homeState != null) {
    homeState.badgeCountNotifier.value = count;
  }
}
