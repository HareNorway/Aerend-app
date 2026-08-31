import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../main.dart';
import '../../../utils/global_loading_overlay.dart';
import '../../../utils/utils.dart';
import '../dugnad_repo.dart';
import '../dugnad_state.dart';
import 'club_shop_cart.dart';
import 'club_shop_models.dart';
import 'club_shop_receipt_screen.dart';
import 'club_shop_screen.dart';

const String prefVippsPendingClubShopRef = 'vipps_pending_club_shop_ref';
const String prefVippsPendingClubShopMeta = 'vipps_pending_club_shop_meta';

bool _clubShopVippsConfirmInFlight = false;

void savePendingClubShopVippsCheckout({
  required String paymentRef,
  required int clubId,
}) {
  prefSetString(prefVippsPendingClubShopRef, paymentRef);
  prefSetString(
    prefVippsPendingClubShopMeta,
    jsonEncode({
      'started_at': DateTime.now().millisecondsSinceEpoch,
      'club_id': clubId,
    }),
  );
}

void clearPendingClubShopVippsCheckout() {
  prefSetString(prefVippsPendingClubShopRef, '');
  prefSetString(prefVippsPendingClubShopMeta, '');
}

Map<String, dynamic> _readClubShopVippsMeta() {
  try {
    final raw = prefGetString(prefVippsPendingClubShopMeta).trim();
    if (raw.isEmpty) return {};
    final decoded = jsonDecode(raw);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  } catch (_) {}
  return {};
}

bool clubShopOrderIsPaid(Map<String, dynamic>? body) {
  if (body == null) return false;
  if (body['status'] != 1 && body['status'] != '1') return false;
  final order = body['order'] is Map
      ? Map<String, dynamic>.from(body['order'] as Map)
      : <String, dynamic>{};
  if (order['collectible'] == true || order['collectible'] == 1) return true;
  final st = (order['status'] ?? '').toString();
  return st == 'klar' || st == 'utlevert';
}

Future<bool> completeClubShopVippsPayment(
  String paymentRef, {
  int? clubId,
  int retries = 4,
}) async {
  final trimmed = paymentRef.trim();
  if (trimmed.isEmpty || !isLoggedIn()) return false;
  if (_clubShopVippsConfirmInFlight) return false;
  _clubShopVippsConfirmInFlight = true;

  final meta = _readClubShopVippsMeta();
  final resolvedClub = clubId ??
      (meta['club_id'] as num?)?.toInt() ??
      DugnadState.instance.clubId;
  if (resolvedClub <= 0) {
    _clubShopVippsConfirmInFlight = false;
    return false;
  }

  try {
    ClubShopPaidOrder? paid;
    final ok = await withGlobalLoadingOverlay(() async {
      for (var attempt = 0; attempt <= retries; attempt++) {
        if (attempt > 0) {
          await Future.delayed(const Duration(seconds: 2));
        }
        final body = await DugnadRepo().clubShopConfirm(
          clubId: resolvedClub,
          paymentRef: trimmed,
        );
        if (!clubShopOrderIsPaid(body)) continue;

        clearPendingClubShopVippsCheckout();
        ClubShopCart.instance.clear();

        final paidJson = body!['order'] is Map
            ? Map<String, dynamic>.from(body['order'] as Map)
            : <String, dynamic>{};
        paid = ClubShopPaidOrder.fromJson(paidJson);
        return paid!.orderNumber.isNotEmpty;
      }
      return false;
    }, message: languages.dugnadClubShopProcessing);

    if (ok == true) {
      final receipt = paid;
      if (receipt != null && receipt.orderNumber.isNotEmpty) {
        final nav = navigatorKey.currentState;
        if (nav != null) {
          nav.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) =>
                  ClubShopReceiptScreen(order: receipt, fresh: true),
            ),
            (route) =>
                route.settings.name == ClubShopScreen.routeName ||
                route.isFirst,
          );
        }
        return true;
      }
    }
    return false;
  } finally {
    _clubShopVippsConfirmInFlight = false;
  }
}

Future<void> resumePendingClubShopVippsPaymentIfNeeded() async {
  final ref = prefGetString(prefVippsPendingClubShopRef).trim();
  if (ref.isEmpty || !isLoggedIn()) return;

  final meta = _readClubShopVippsMeta();
  final startedAt = meta['started_at'] as num?;
  if (startedAt != null) {
    final ageMs = DateTime.now().millisecondsSinceEpoch - startedAt.toInt();
    if (ageMs > const Duration(minutes: 45).inMilliseconds) {
      clearPendingClubShopVippsCheckout();
      return;
    }
  }

  await completeClubShopVippsPayment(ref);
}

class ClubShopVippsReturnScreen extends StatefulWidget {
  const ClubShopVippsReturnScreen({super.key, required this.paymentRef});

  final String paymentRef;

  @override
  State<ClubShopVippsReturnScreen> createState() =>
      _ClubShopVippsReturnScreenState();
}

class _ClubShopVippsReturnScreenState extends State<ClubShopVippsReturnScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _confirm());
  }

  Future<void> _confirm() async {
    final ref = widget.paymentRef.trim().isNotEmpty
        ? widget.paymentRef.trim()
        : prefGetString(prefVippsPendingClubShopRef);
    try {
      final ok = await completeClubShopVippsPayment(ref);
      if (!mounted) return;
      if (ok) return;
      openSimpleSnackbar(
        languages.dugnadClubShopPayFailed,
        kind: AeToastKind.error,
      );
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      openSimpleSnackbar(e.toString(), kind: AeToastKind.error);
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox.shrink(),
    );
  }
}
