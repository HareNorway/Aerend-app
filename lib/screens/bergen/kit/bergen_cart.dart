import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../ui/kit/ae_haptic.dart';
import '../../../utils/guest_auth_helper.dart';
import '../../../utils/utils.dart';
import '../../common/homeMainV1/home_main_v1.dart';
import '../../deliveryService/storeDetail/store_detail_dl.dart';
import '../../deliveryService/storeDetail/store_detail_repo.dart';
import '../../common/orderCart/order_cart_repo.dart';
import '../butikk/butikk_copy.dart';
import '../onboarding/onb_runde.dart';
import '../aegil/aegil_guide.dart' show aegilGuideFerdig, kAeTipButikkPluss;
import 'bergen_ark.dart';
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
    int sizeId = 0,
    int colourId = 0,
    List<int> optionIds = const [],
    /// No toast when it goes through (the caller shows its own).
    bool stille = false,
    /// The firm «in the basket» tap; off when the caller plays its own.
    bool haptic = true,
    /// The retry after the customer emptied the other store's cart (once).
    bool etterTom = false,
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
    AeHaptikk.tikk();
    // The legacy cart call reads the chosen variant from prefs (and clears
    // them after): set them the same way the old sheets do.
    prefSetInt('checkedSize', sizeId);
    prefSetInt('checkedColor', colourId);
    prefSetString('checkedOptionList', jsonEncode(optionIds));
    try {
      final response = UserOrderCartPojo.fromJson(
        await StoreDetailRepo().callOrderCartApi(storeId, productId, quantity),
      );
      if (!context.mounted) return false;
      if (response.messageCode == 1) {
        if (haptic) aeConfirm();
        prefSetInt(prefCartCount, response.countOrder);
        syncBadge(context, response.countOrder);
        // Onboarding: the tour's «Legg til» mission counts successful adds.
        OnbRunde.instance.kurvLagt++;
        // The Ægil tip «Trykk + ved en rett …» has done its job.
        aegilGuideFerdig(const [kAeTipButikkPluss]);
        if (!stille) showBergenToast(context, toast ?? response.message);
        return true;
      }
      // 412: the cart holds another store's lines. Ask, empty, add again
      // (the legacy sheets did this with a dialog; Bergen asks in an Ark).
      if (response.messageCode == 412 && !etterTom) {
        final tom = await showBergenArk<bool>(
          context,
          title: ButikkCopy.a1_butikk_kurv_annen,
          subtitle: ButikkCopy.a1_butikk_kurv_annen_linje,
          primary: BergenArkAction(label: ButikkCopy.a1_butikk_kurv_annen_tom, onTap: () => Navigator.of(context).pop(true)),
          secondary: BergenArkAction(label: ButikkCopy.a1_butikk_kurv_annen_behold, onTap: () => Navigator.of(context).pop(false)),
        );
        if (tom != true || !context.mounted) return false;
        await OrderCartRepo().clearAllCartItems();
        if (!context.mounted) return false;
        prefSetInt(prefCartCount, 0);
        syncBadge(context, 0);
        return add(
          context,
          storeId: storeId,
          productId: productId,
          quantity: quantity,
          toast: toast,
          sizeId: sizeId,
          colourId: colourId,
          optionIds: optionIds,
          stille: stille,
          haptic: haptic,
          etterTom: true,
        );
      }
      // Kunde Glatt D6: the basket said no — a short buzz.
      if (haptic) AeHaptikk.feil();
      showBergenToast(context, response.message);
      return false;
    } catch (e) {
      if (haptic && context.mounted) AeHaptikk.feil();
      if (context.mounted) showBergenToast(context, e.toString());
      return false;
    }
  }

  /// Push the count into the shell's nav pill when the shell is an ancestor.
  static void syncBadge(BuildContext context, [int? count]) {
    // 03 test pass (CUS-A18): a screen pushed over the shell (Kassen from a store, Sporing) has no shell above it —
    // the shell itself is the fallback, or the badge kept the paid basket's «3 varer».
    final shell = context.findAncestorStateOfType<HomeMainV1State>() ?? HomeMainV1State.current;
    if (shell != null) {
      shell.badgeCountNotifier.value = count ?? prefGetInt(prefCartCount);
    }
  }
}
