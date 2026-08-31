import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aerend_customer/blocs/bloc.dart';
import 'package:aerend_customer/commonView/no_record_found.dart';
import 'package:aerend_customer/theme/sc_saas_theme.dart';
import 'package:aerend_customer/screens/common/homeMainV1/home_main_v1.dart';
import 'package:aerend_customer/screens/common/manageAddress/manage_address.dart';
import 'package:aerend_customer/screens/common/orderCart/order_cart_repo.dart';
import 'package:aerend_customer/screens/deliveryService/storeDetail/add_on_repo.dart';
import 'package:aerend_customer/screens/deliveryService/storeDetail/store_detail_repo.dart';
import 'package:aerend_customer/screens/deliveryService/storeDetail/widget_size_color.dart';
import 'package:aerend_customer/screens/deliveryService/storeDetail/widget_topping_option.dart';

import '../../../utils/guest_auth_helper.dart';
import '../../../utils/utils.dart';
import '../../common/manageAddress/manage_address_dl.dart';
import '../../dugnad/dugnad_sheet.dart';
import '../../dugnad/widgets/dugnad_rise_in.dart';
import '../../dugnad/widgets/dugnad_subpage_shell.dart';
import '../../dugnad/widgets/dugnad_swipe_button.dart';
import 'checkout_bloc.dart';
import 'checkout_preview_utils.dart';
import 'co_styles.dart';

enum CheckoutPaymentMethod { cardKlarna, platformPay, vipps }

/// «Til kassen» — mirrors `dugnad/customer-screens.jsx` `DGCheckout` and the
/// matkasse checkout: `.co-head`, `.co-body`, `.co-card`, `.co-seg`, `.co-row`,
/// `.co-when`, `.co-item`, `.co-totals`, `.co-foot` (+ `.dg-swipe--purple`).
class CheckOut extends StatefulWidget {
  final bool isPaymentFailed;
  const CheckOut({super.key, this.isPaymentFailed = false});

  @override
  CheckOutState createState() => CheckOutState();
}

class CheckOutState extends State<CheckOut>
    with SingleTickerProviderStateMixin {
  late CheckOutBloc _bloc;
  late TabController _tabController;
  int tabIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.isPaymentFailed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        openSimpleSnackbar(languages.checkoutPaymentFailed);
      });
    }
    _tabController = TabController(initialIndex: 0, length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    if (prefGetString(prefTip) == '') {
      prefSetString(prefTip, '0');
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resumeGuestCheckoutPaymentIfNeeded();
    });
  }

  void _resumeGuestCheckoutPaymentIfNeeded() {
    if (!prefGetBool(prefGuestCheckoutResume)) return;
    final int paymentType = guestCheckoutResumePaymentType();
    final int takenType = guestCheckoutResumeTakenType();
    final bool spendCredit = guestCheckoutResumeSpendCredit();
    clearGuestStoreCheckoutResume();
    if (!isLoggedIn()) return;
    _executePendingStorePayment(
      paymentType: paymentType,
      takenType: takenType,
      spendCredit: spendCredit,
    );
  }

  void _executePendingStorePayment({
    required int paymentType,
    required int takenType,
    required bool spendCredit,
  }) {
    if (prefGetInt(prefNewDeliveryAddressId) == 0) return;
    prefSetInt('bookedOrderId', 0);
    _bloc.placeOrderApiCall(
      paymentType,
      prefGetInt(prefNewDeliveryAddressId),
      takenType: takenType,
      credit: spendCredit,
    );
  }

  @override
  void didChangeDependencies() {
    _bloc = CheckOutBloc(context, this);
    super.didChangeDependencies();
  }

  void _handleTabSelection() {
    setState(() {
      tabIndex = _tabController.index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScSaasThemeTokens.background,
      body: DugnadFixedTypography(
        child: SafeArea(
          bottom: false,
          child: StreamBuilder<bool>(
            stream: _bloc.loadingPlaceOrder,
            builder: (context, snapshot) {
              final bool busy = snapshot.data ?? false;
              return Stack(
                children: [
                  Column(
                    children: [
                      _buildCoHead(context),
                      // `.co-card` wrapping the `.co-seg` delivery/pickup toggle.
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          kCoBodyPadH,
                          4,
                          kCoBodyPadH,
                          kCoBodyGap,
                        ),
                        child: DugnadRiseIn(
                          delay: const Duration(milliseconds: 120),
                          child: CoCard(child: _buildCoSeg()),
                        ),
                      ),
                      StreamBuilder<List<AddressListItem>?>(
                        stream: _bloc.addressList,
                        builder: (context, snapshot) {
                          List<AddressListItem> addressList =
                              snapshot.data ?? [];
                          return Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                Delivery(bloc: _bloc, addressList: addressList),
                                SelfPickup(
                                  bloc: _bloc,
                                  addressList: addressList,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  if (busy)
                    ModalBarrier(
                      color: colorBlack.withValues(alpha: 0.5),
                      dismissible: false,
                    ),
                  if (busy) const Center(child: CircularProgressIndicator()),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// `.co-head` — grid `40px 1fr 40px`, padding `4px 18px 12px`, h1 18/800.
  Widget _buildCoHead(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(kCoBodyPadH, 4, kCoBodyPadH, 12),
      child: Row(
        children: [
          DugnadLbBackButton(
            onPressed: () => openScreenWithResult(
              context,
              const HomeMainV1(homeIndex: 1),
            ),
          ),
          Expanded(
            child: Text(
              languages.checkoutTitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: coHeadTitle,
            ),
          ),
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  /// `.co-seg` — lavender track, padding 4, radius 12; the selected chip is
  /// white, radius 9, `0 1px 3px rgba(45,27,91,.1)`, label purple-700.
  Widget _buildCoSeg() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: ScSaasThemeTokens.background,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        labelColor: ScSaasThemeTokens.primaryHover,
        unselectedLabelColor: ScSaasThemeTokens.gray500,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A2D1B5B),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        padding: EdgeInsets.zero,
        indicatorPadding: EdgeInsets.zero,
        labelPadding: EdgeInsets.zero,
        tabs: [
          _coSegTab(
            label: languages.checkoutDeliveryTab,
            asset: 'assets/svgs/delivery.svg',
            selected: tabIndex == 0,
          ),
          _coSegTab(
            label: languages.checkoutPickupTab,
            asset: 'assets/svgs/box-time.svg',
            selected: tabIndex == 1,
          ),
        ],
      ),
    );
  }

  Widget _coSegTab({
    required String label,
    required String asset,
    required bool selected,
  }) {
    final Color color =
        selected ? ScSaasThemeTokens.primaryHover : ScSaasThemeTokens.gray500;
    return Tab(
      height: 37,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            asset,
            width: 16,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: coSegLabel(color),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bloc.dispose();
    super.dispose();
  }
}

class Delivery extends StatefulWidget {
  final CheckOutBloc? bloc;
  final List<AddressListItem>? addressList;
  const Delivery({super.key, this.bloc, this.addressList});

  @override
  State<Delivery> createState() => _DeliveryState();
}

class _DeliveryState extends State<Delivery> {
  bool spendReenCredit = false;
  CheckoutPaymentMethod _selectedPaymentMethod =
      CheckoutPaymentMethod.cardKlarna;

  /// Bumped after every place-order attempt so the swipe slider resets to idle
  /// instead of staying latched on "done" when placement is aborted.
  int _payAttempt = 0;

  int _deliveryMinutesFromOrder(dynamic orderData) {
    if (orderData is! Map) return 0;

    final List<dynamic> orderList =
        (orderData['order_list'] as List?) ?? const <dynamic>[];
    int maxProductMinutes = 0;
    for (final dynamic item in orderList) {
      if (item is! Map) continue;
      final int prepareMinutes = (item['prepare_time'] as num?)?.toInt() ?? 0;
      final int deliveryMinutes = (item['delivery_time'] as num?)?.toInt() ?? 0;
      final int totalProductMinutes = prepareMinutes + deliveryMinutes;
      if (totalProductMinutes > maxProductMinutes) {
        maxProductMinutes = totalProductMinutes;
      }
    }
    if (maxProductMinutes > 0) return maxProductMinutes;

    final int fallbackDeliveryMinutes =
        (orderData['delivery_time'] as num?)?.toInt() ?? 0;
    final int fallbackPrepareMinutes =
        (orderData['prepare_time'] as num?)?.toInt() ?? 0;
    return fallbackDeliveryMinutes + fallbackPrepareMinutes;
  }

  String _estimatedDeliveryLabel(int totalMinutes) {
    if (totalMinutes <= 0) return '-';

    final DateTime etaTime = DateTime.now().add(
      Duration(minutes: totalMinutes),
    );
    final String hour = etaTime.hour.toString().padLeft(2, '0');
    final String minute = etaTime.minute.toString().padLeft(2, '0');
    return '$hour.$minute ($totalMinutes Mnt)';
  }

  int _selectedPaymentType() {
    if (_selectedPaymentMethod == CheckoutPaymentMethod.platformPay) return 2;
    if (_selectedPaymentMethod == CheckoutPaymentMethod.vipps) return 3;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.fromLTRB(kCoBodyPadH, 0, kCoBodyPadH, 130),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Leveringsadresse (.co-card > .co-row + .co-when) ───────
                DugnadRiseIn(
                  delay: const Duration(milliseconds: 190),
                  child: CoCard(child: _buildAddressSection()),
                ),
                const SizedBox(height: kCoBodyGap),
                // ── Din bestilling (.co-label + .co-item) ─────────────────
                DugnadRiseIn(
                  delay: const Duration(milliseconds: 260),
                  child: CoCard(
                    child: orderSummaryWidget(
                      context,
                      widget.bloc,
                      onEditItem: (orderItem) =>
                          _openOrderItemEditor(context, widget.bloc, orderItem),
                    ),
                  ),
                ),
                const SizedBox(height: kCoBodyGap),
                // ── Tips ──────────────────────────────────────────────────
                DugnadRiseIn(
                  delay: const Duration(milliseconds: 330),
                  child: CoCard(child: _buildTipSection()),
                ),
                const SizedBox(height: kCoBodyGap),
                // ── Betaling (.co-label + .co-row + «Endre») ──────────────
                DugnadRiseIn(
                  delay: const Duration(milliseconds: 400),
                  child: CoCard(
                    child: _paymentSection(
                      context,
                      selectedMethod: _selectedPaymentMethod,
                      onSelect: (method) =>
                          setState(() => _selectedPaymentMethod = method),
                    ),
                  ),
                ),
                const SizedBox(height: kCoBodyGap),
                // ── .co-card.co-totals ────────────────────────────────────
                DugnadRiseIn(
                  delay: const Duration(milliseconds: 470),
                  child: _buildTotals(),
                ),
                _termsOfSaleLink(context),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: CoFoot(child: _buildPayAction()),
        ),
      ],
    );
  }

  /// `.co-row` (pin + address + «Endre») and `.co-when` (estimated delivery).
  Widget _buildAddressSection() {
    return StreamBuilder<AddressListItem?>(
      stream: widget.bloc?.selectedAddress,
      builder: (context, snap) {
        final bool hasAddress = prefGetInt(prefNewDeliveryAddressId) != 0;
        final AddressListItem? address = snap.data;
        String title = languages.checkoutSelectDeliveryAddress;
        String? subtitle;
        if (hasAddress && address != null) {
          final List<String> parts = address.address
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
          title = parts.isEmpty ? address.address : parts.first;
          if (parts.length > 1) subtitle = parts.sublist(1).join(', ');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CoRow(
              icon: hasAddress
                  ? Icons.location_on_rounded
                  : Icons.location_on_outlined,
              title: title,
              subtitle: subtitle,
              onEdit: () => _openAddressPicker(context, widget.bloc),
            ),
            StreamBuilder<ApiResponse>(
              stream: widget.bloc?.subject,
              builder: (context, snapshot) {
                final int minutes =
                    _deliveryMinutesFromOrder(snapshot.data?.data);
                return CoWhen(
                  icon: Icons.local_shipping_outlined,
                  label: '${languages.checkoutEstimatedDelivery} ',
                  strong: _estimatedDeliveryLabel(minutes),
                );
              },
            ),
          ],
        );
      },
    );
  }

  /// `.co-label` + tip chips — unchanged `prefTip` plumbing.
  Widget _buildTipSection() {
    const List<String> tips = ['0', '10', '20', '50'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CoLabel(languages.tip),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final String amount in tips)
              _tipOption(
                'NOK $amount',
                () {
                  setState(() {
                    prefSetString(prefTip, amount);
                    widget.bloc?.syncTotalPayFromPreview(
                      widget.bloc?.subject.valueOrNull?.data,
                    );
                  });
                },
                isSelected: prefGetString(prefTip) == amount,
              ),
          ],
        ),
      ],
    );
  }

  /// `.co-card.co-totals` — Delsum / Leveringsgebyr / Ordregebyr / Tips / Totalt.
  Widget _buildTotals() {
    return StreamBuilder<ApiResponse>(
      stream: widget.bloc!.subject,
      builder: (context, snap) {
        final dynamic data = snap.data?.data;
        final double subtotal = checkoutPreviewSubtotal(data);
        final double deliveryFee =
            (data is Map ? (data['delivery_fee'] as num?)?.toDouble() : null) ??
                0.0;
        final double orderFee =
            (data is Map ? (data['order_fee'] as num?)?.toDouble() : null) ??
                0.0;
        final double tip = double.parse(
          prefGetStringWithDefaultValue(prefTip, '0.0'),
        );
        final double total = subtotal + deliveryFee + orderFee + tip;
        return CoTotals(
          lines: [
            CoTotalsEntry(languages.subTotal, formatNok(subtotal)),
            CoTotalsEntry(
              languages.deliveryCharges,
              deliveryFee == 0 ? 'Gratis' : formatNok(deliveryFee), // TODO(l10n)
            ),
            CoTotalsEntry(languages.checkoutOrderFee, formatNok(orderFee)),
            if (tip > 0) CoTotalsEntry(languages.tip, formatNok(tip)),
          ],
          grandLabel: languages.total,
          grandValue: formatNok(total),
        );
      },
    );
  }

  /// `.co-foot` — `.dg-swipe--purple` «Sveip for å betale».
  Widget _buildPayAction() {
    return StreamBuilder<ApiResponse>(
      stream: widget.bloc!.subject,
      builder: (context, snapshot) {
        final double tip = double.parse(
          prefGetStringWithDefaultValue(prefTip, '0.0'),
        );
        final bool awaitingAddress = checkoutSummaryAwaitingAddress(
          orderType: 0,
        );
        final double grossTotal = checkoutPreviewGrossTotal(
          snapshot.data?.data,
          orderType: 0,
          tip: tip,
        );
        final reenCredit = double.parse(
          prefGetStringWithDefaultValue(prefAerendCredit, '0.0'),
        );
        final noPaymentRequired =
            spendReenCredit && grossTotal > 0 && reenCredit >= grossTotal;
        final String payLabel = awaitingAddress && isGuestUser()
            ? languages.signInToCompleteOrder
            : 'Sveip for å betale'; // TODO(l10n)

        Future<void> placeOrder(int paymentType) async {
          if (isGuestUser()) {
            saveGuestStoreCheckoutResume(
              paymentType: paymentType,
              takenType: 1,
              spendCredit: spendReenCredit,
            );
            final authed = await showGuestLoginSheet(
              context,
              prompt: GuestLoginPrompt.checkout,
            );
            if (!authed || !context.mounted) return;
            await widget.bloc!.refreshAfterGuestAuth();
            if (!context.mounted) return;
          }
          clearGuestStoreCheckoutResume();
          if (prefGetInt(prefNewDeliveryAddressId) != 0) {
            prefSetInt('bookedOrderId', 0);
            widget.bloc!.placeOrderApiCall(
              paymentType,
              prefGetInt(prefNewDeliveryAddressId),
              takenType: 1,
              credit: spendReenCredit,
            );
          } else {
            await _openAddressPicker(context, widget.bloc);
          }
        }

        return DugnadSwipeButton(
          key: ValueKey<int>(_payAttempt),
          variant: DugnadSwipeVariant.purple,
          label: payLabel,
          amount: grossTotal > 0 ? formatNok(grossTotal) : null,
          doneLabel: 'Betaler…', // TODO(l10n)
          onComplete: () async {
            await placeOrder(noPaymentRequired ? 1 : _selectedPaymentType());
            if (mounted) setState(() => _payAttempt++);
          },
        );
      },
    );
  }
}

class SelfPickup extends StatefulWidget {
  final CheckOutBloc? bloc;
  final List<AddressListItem>? addressList;
  const SelfPickup({super.key, this.bloc, this.addressList});

  @override
  State<SelfPickup> createState() => _SelfPickupState();
}

class _SelfPickupState extends State<SelfPickup> {
  bool spendReenCredit = false;
  CheckoutPaymentMethod _selectedPaymentMethod =
      CheckoutPaymentMethod.cardKlarna;
  int _payAttempt = 0;

  int _selectedPaymentType() {
    if (_selectedPaymentMethod == CheckoutPaymentMethod.platformPay) return 2;
    if (_selectedPaymentMethod == CheckoutPaymentMethod.vipps) return 3;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.fromLTRB(kCoBodyPadH, 0, kCoBodyPadH, 130),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DugnadRiseIn(
                  delay: const Duration(milliseconds: 190),
                  child: CoCard(child: _buildPickupSection()),
                ),
                const SizedBox(height: kCoBodyGap),
                DugnadRiseIn(
                  delay: const Duration(milliseconds: 260),
                  child: CoCard(
                    child: orderSummaryWidget(
                      context,
                      widget.bloc,
                      orderType: 1,
                      onEditItem: (orderItem) =>
                          _openOrderItemEditor(context, widget.bloc, orderItem),
                    ),
                  ),
                ),
                const SizedBox(height: kCoBodyGap),
                DugnadRiseIn(
                  delay: const Duration(milliseconds: 330),
                  child: CoCard(
                    child: _paymentSection(
                      context,
                      selectedMethod: _selectedPaymentMethod,
                      onSelect: (method) =>
                          setState(() => _selectedPaymentMethod = method),
                    ),
                  ),
                ),
                const SizedBox(height: kCoBodyGap),
                DugnadRiseIn(
                  delay: const Duration(milliseconds: 400),
                  child: _buildTotals(),
                ),
                _termsOfSaleLink(context),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: CoFoot(child: _buildPayAction()),
        ),
      ],
    );
  }

  /// `.co-row` (store) + `.co-when` (klar om … min).
  Widget _buildPickupSection() {
    return StreamBuilder<ApiResponse>(
      stream: widget.bloc!.subject,
      builder: (context, snap) {
        final dynamic data = snap.data?.data;
        final String storeAddress =
            (data is Map ? data['store_address'] : null)?.toString() ?? '';
        final dynamic distance =
            (data is Map ? data['total_distance'] : null) ?? '-';
        final int prepareTime =
            (data is Map ? (data['prepare_time'] as num?)?.toInt() : null) ?? 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CoRow(
              icon: Icons.storefront_rounded,
              title: storeAddress.isEmpty ? '—' : storeAddress,
              subtitle: languages.checkoutDistanceKm(distance.toString()),
            ),
            CoWhen(
              icon: Icons.schedule_rounded,
              label: '',
              strong: languages.checkoutPickupInMin(
                prepareTime > 0 ? prepareTime.toString() : '-',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTotals() {
    return StreamBuilder<ApiResponse>(
      stream: widget.bloc!.subject,
      builder: (context, snap) {
        final dynamic data = snap.data?.data;
        final double subtotal = checkoutPreviewSubtotal(data);
        final double orderFee =
            (data is Map ? (data['order_fee'] as num?)?.toDouble() : null) ??
                0.0;
        final double total = subtotal + orderFee;
        return CoTotals(
          lines: [
            CoTotalsEntry(languages.subTotal, formatNok(subtotal)),
            CoTotalsEntry(languages.checkoutOrderFee, formatNok(orderFee)),
          ],
          grandLabel: languages.total,
          grandValue: formatNok(total),
        );
      },
    );
  }

  Widget _buildPayAction() {
    return StreamBuilder<ApiResponse>(
      stream: widget.bloc!.subject,
      builder: (context, snapshot) {
        final double grossTotal = checkoutPreviewGrossTotal(
          snapshot.data?.data,
          orderType: 1,
        );
        final reenCredit = double.parse(
          prefGetStringWithDefaultValue(prefAerendCredit, '0.0'),
        );
        final noPaymentRequired =
            spendReenCredit && grossTotal > 0 && reenCredit >= grossTotal;

        Future<void> placeOrder(int paymentType) async {
          if (isGuestUser()) {
            saveGuestStoreCheckoutResume(
              paymentType: paymentType,
              takenType: 2,
              spendCredit: spendReenCredit,
            );
            final authed = await showGuestLoginSheet(
              context,
              prompt: GuestLoginPrompt.checkout,
            );
            if (!authed || !context.mounted) return;
            await widget.bloc!.refreshAfterGuestAuth();
            if (!context.mounted) return;
          }
          clearGuestStoreCheckoutResume();
          if (prefGetInt(prefNewDeliveryAddressId) != 0) {
            prefSetInt('bookedOrderId', 0);
            widget.bloc!.placeOrderApiCall(
              paymentType,
              prefGetInt(prefNewDeliveryAddressId),
              takenType: 2,
              credit: spendReenCredit,
            );
          } else {
            await _openAddressPicker(context, widget.bloc);
          }
        }

        return DugnadSwipeButton(
          key: ValueKey<int>(_payAttempt),
          variant: DugnadSwipeVariant.purple,
          label: 'Sveip for å betale', // TODO(l10n)
          amount: grossTotal > 0 ? formatNok(grossTotal) : null,
          doneLabel: 'Betaler…', // TODO(l10n)
          onComplete: () async {
            await placeOrder(noPaymentRequired ? 1 : _selectedPaymentType());
            if (mounted) setState(() => _payAttempt++);
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Address «Endre» — opens the full address screen (manage_address.dart), which
// writes `prefNewDeliveryAddressId`; the bloc reload picks the new address up.
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _openAddressPicker(
  BuildContext context,
  CheckOutBloc? bloc,
) async {
  if (isGuestUser()) {
    final authed = await showGuestLoginSheet(
      context,
      prompt: GuestLoginPrompt.address,
    );
    if (!authed || !context.mounted) return;
  }
  await openScreenWithResult(context, const ManageAddress(showSelect: true));
  await bloc?.getAddressList();
}

// ─────────────────────────────────────────────────────────────────────────────
// Betaling — `.co-label` + `.co-row` with a live «Endre» entry point.
// The picker writes back into the same [CheckoutPaymentMethod] state the old
// inline radio group used, so `placeOrderApiCall(paymentType)` is unchanged.
// ─────────────────────────────────────────────────────────────────────────────

List<CheckoutPaymentMethod> _availablePaymentMethods() {
  return [
    CheckoutPaymentMethod.cardKlarna,
    if (Platform.isAndroid || Platform.isIOS)
      CheckoutPaymentMethod.platformPay,
    if (AppFeatureFlags.showVippsPay) CheckoutPaymentMethod.vipps,
  ];
}

String _paymentMethodName(CheckoutPaymentMethod method) {
  switch (method) {
    case CheckoutPaymentMethod.cardKlarna:
      return 'Kort / Klarna'; // TODO(l10n)
    case CheckoutPaymentMethod.platformPay:
      return Platform.isIOS ? 'Apple Pay' : 'Google Pay';
    case CheckoutPaymentMethod.vipps:
      return 'Vipps';
  }
}

String _paymentMethodSubtitle(CheckoutPaymentMethod method) {
  switch (method) {
    case CheckoutPaymentMethod.cardKlarna:
      return 'Velg kort eller Klarna i betalingsvinduet'; // TODO(l10n)
    case CheckoutPaymentMethod.platformPay:
      return 'Rask betaling på denne enheten'; // TODO(l10n)
    case CheckoutPaymentMethod.vipps:
      return 'Åpne Vipps for å godkjenne betalingen'; // TODO(l10n)
  }
}

/// `.co-row .ic` per method — Vipps uses `.dg-vipps-ic` (bare logo, no tint).
Widget _paymentMethodIcon(CheckoutPaymentMethod method) {
  if (method == CheckoutPaymentMethod.vipps) {
    return Container(
      width: 40,
      height: 40,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: kDgspBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Image.asset(
          'assets/images/vipps_logo.png',
          filterQuality: FilterQuality.high,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
  return CoRowIcon(
    method == CheckoutPaymentMethod.platformPay
        ? (Platform.isIOS ? Icons.phone_iphone_rounded : Icons.android_rounded)
        : Icons.credit_card_rounded,
  );
}

Widget _paymentSection(
  BuildContext context, {
  required CheckoutPaymentMethod selectedMethod,
  required Function(CheckoutPaymentMethod method) onSelect,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CoLabel(languages.checkoutPaymentMethod),
      CoRow(
        leading: _paymentMethodIcon(selectedMethod),
        title: _paymentMethodName(selectedMethod),
        subtitle: _paymentMethodSubtitle(selectedMethod),
        onEdit: () async {
          final CheckoutPaymentMethod? picked =
              await _openPaymentMethodSheet(context, selectedMethod);
          if (picked != null) onSelect(picked);
        },
      ),
    ],
  );
}

/// `.dgsp-row` list from `checkout-screens.jsx` `SelectPaymentScreen`,
/// presented in the shared dugnad sheet with a `.dg-mem-head` header.
Future<CheckoutPaymentMethod?> _openPaymentMethodSheet(
  BuildContext context,
  CheckoutPaymentMethod selected,
) {
  final List<CheckoutPaymentMethod> methods = _availablePaymentMethods();
  return showDugnadSheet<CheckoutPaymentMethod>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DugnadSheetHandle(),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: kAeShinyPurple,
                    ),
                    child: const Icon(
                      Icons.credit_card_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          languages.checkoutPaymentMethod,
                          style: coSans(
                            size: 18,
                            weight: FontWeight.w800,
                            height: 1.2,
                            letterSpacingEm: -0.02,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Velg hvordan du vil betale', // TODO(l10n)
                          style: coSans(
                            size: 12.5,
                            weight: FontWeight.w600,
                            height: 1.3,
                            color: ScSaasThemeTokens.gray500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              for (int i = 0; i < methods.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _DgspRow(
                  method: methods[i],
                  selected: methods[i] == selected,
                  onTap: () => Navigator.pop(sheetContext, methods[i]),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

/// `.dgsp-row` — 1.5px border, radius 16, padding 14, gap 12; `.on` switches
/// the border to purple-600 and the fill to lavender.
class _DgspRow extends StatefulWidget {
  const _DgspRow({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final CheckoutPaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_DgspRow> createState() => _DgspRowState();
}

class _DgspRowState extends State<_DgspRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool on = widget.selected;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.99 : 1,
        duration: const Duration(milliseconds: 60),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: on ? ScSaasThemeTokens.background : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: on ? ScSaasThemeTokens.primary : kDgspBorder,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              // `.dgsp-row .rb` — 21px ring with an 11px dot.
              Container(
                width: 21,
                height: 21,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: on ? ScSaasThemeTokens.primary : kDgspRadio,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: AnimatedScale(
                    scale: on ? 1 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: ScSaasThemeTokens.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _DgspLogo(method: widget.method),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // `.dgsp-row .nm` — 15/800 midnight.
                    Text(
                      _paymentMethodName(widget.method),
                      style: coSans(
                        size: 15,
                        weight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // `.dgsp-row .s` — 12.5/600 gray-500.
                    Text(
                      _paymentMethodSubtitle(widget.method),
                      style: coSans(
                        size: 12.5,
                        weight: FontWeight.w600,
                        height: 1.25,
                        color: ScSaasThemeTokens.gray500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.dgsp-row .lg` — 42×30, radius 8, midnight; `.lg.vipps` is white + border.
class _DgspLogo extends StatelessWidget {
  const _DgspLogo({required this.method});

  final CheckoutPaymentMethod method;

  @override
  Widget build(BuildContext context) {
    final bool vipps = method == CheckoutPaymentMethod.vipps;
    return Container(
      width: 42,
      height: 30,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: vipps ? Colors.white : ScSaasThemeTokens.text,
        borderRadius: BorderRadius.circular(8),
        border: vipps ? Border.all(color: kDgspBorder) : null,
      ),
      child: vipps
          ? Padding(
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                'assets/images/vipps_logo.png',
                filterQuality: FilterQuality.high,
                fit: BoxFit.contain,
              ),
            )
          : Icon(
              method == CheckoutPaymentMethod.platformPay
                  ? (Platform.isIOS
                      ? Icons.phone_iphone_rounded
                      : Icons.android_rounded)
                  : Icons.credit_card_rounded,
              size: 17,
              color: Colors.white,
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Order summary («Din bestilling»)
// ─────────────────────────────────────────────────────────────────────────────

Widget _termsOfSaleLink(BuildContext context) {
  final TextStyle textStyle = coSans(
    size: 12,
    weight: FontWeight.w500,
    height: 1.4,
    color: ScSaasThemeTokens.gray500,
  );
  return Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(languages.checkoutPlacingOrderTerms, style: textStyle),
          GestureDetector(
            onTap: () => openUrl('${BaseUrl.domain}terms-of-sale'),
            child: Text(
              languages.termsAndConditions,
              style: coSans(
                size: 12,
                weight: FontWeight.w700,
                height: 1.4,
                color: ScSaasThemeTokens.primaryHover,
              ).copyWith(decoration: TextDecoration.underline),
            ),
          ),
          Text('.', style: textStyle),
        ],
      ),
    ),
  );
}

/// `.dg-info` — purple-100, radius 14, padding 13×14, gap 11, 12.5/600 p-700.
Widget _checkoutSummaryPlaceholder(
  BuildContext context, {
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
          decoration: BoxDecoration(
            color: ScSaasThemeTokens.primaryTint,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: ScSaasThemeTokens.primary,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  message,
                  style: coSans(
                    size: 12.5,
                    weight: FontWeight.w600,
                    height: 1.45,
                    color: ScSaasThemeTokens.primaryHover,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onAction,
            child: Container(
              width: double.infinity,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ScSaasThemeTokens.primary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: ScSaasThemeTokens.shadowButton,
              ),
              child: Text(
                actionLabel,
                style: coSans(
                  size: 15,
                  weight: FontWeight.w700,
                  height: 1.2,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

/// `.co-card` body — `.co-label` «Din bestilling» + `.co-item` rows.
Widget orderSummaryWidget(
  BuildContext context,
  CheckOutBloc? bloc, {
  int orderType = 0,
  bool spendReenCredit = false,
  Function(dynamic orderItem)? onEditItem,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CoLabel(languages.checkoutOrderSummary),
      StreamBuilder<ApiResponse>(
        stream: bloc!.subject,
        builder: (context, snap) {
          if (checkoutSummaryAwaitingAddress(orderType: orderType)) {
            if (isGuestUser()) {
              return _checkoutSummaryPlaceholder(
                context,
                message: languages.signInToCompleteOrderMessage,
                actionLabel: languages.signInToCompleteOrder,
                onAction: () {
                  showGuestLoginSheet(
                    context,
                    prompt: GuestLoginPrompt.checkout,
                  );
                },
              );
            }
            return _checkoutSummaryPlaceholder(
              context,
              message: languages.addOrSelectAddress,
            );
          }

          if (snap.data?.status == Status.loading) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snap.hasData &&
              snap.data?.status == Status.completed &&
              snap.data?.data != null) {
            final dynamic data = snap.data!.data;
            final List orderList = data?['order_list'] ?? [];

            return Column(
              children: [
                for (int i = 0; i < orderList.length; i++)
                  _CheckoutOrderRow(
                    key: ValueKey<Object>(
                      (orderList[i]['id'] as num?)?.toInt() ?? i,
                    ),
                    orderItem: orderList[i],
                    bloc: bloc,
                    showTopRule: i > 0,
                    onEdit: onEditItem == null
                        ? null
                        : () => onEditItem(orderList[i]),
                  ),
              ],
            );
          }
          if (snap.data?.status == Status.error) {
            return _checkoutSummaryPlaceholder(
              context,
              message: snap.data?.message ?? languages.cartEmptyMsg,
            );
          }
          return const NoRecordFound(message: 'No Order found!');
        },
      ),
    ],
  );
}

/// `.co-item` — grid `48px 1fr auto`, gap 12, padding `10px 0`,
/// `+ .co-item` separated by a 1px gray-100 rule, `.dg-foodstep.sm` stepper.
class _CheckoutOrderRow extends StatefulWidget {
  const _CheckoutOrderRow({
    super.key,
    required this.orderItem,
    required this.bloc,
    required this.showTopRule,
    this.onEdit,
  });

  final dynamic orderItem;
  final CheckOutBloc? bloc;
  final bool showTopRule;
  final VoidCallback? onEdit;

  @override
  State<_CheckoutOrderRow> createState() => _CheckoutOrderRowState();
}

class _CheckoutOrderRowState extends State<_CheckoutOrderRow> {
  bool _busy = false;

  int get _cartId => (widget.orderItem['id'] as num?)?.toInt() ?? 0;
  int get _quantity => (widget.orderItem['quantity'] as num?)?.toInt() ?? 1;

  Future<void> _changeQuantity(int next) async {
    if (_busy || _cartId == 0) return;
    setState(() => _busy = true);
    try {
      if (next <= 0) {
        await OrderCartRepo().deleteOrderCartApi(_cartId);
      } else {
        await OrderCartRepo().callChangeQuantityApi(_cartId, next);
      }
      await widget.bloc?.getOrderPreview();
    } catch (e) {
      openSimpleSnackbar(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dynamic item = widget.orderItem;
    final String productName = (item['product_name'] ?? '').toString();
    final double productAmount =
        (item['product_amount'] as num?)?.toDouble() ?? 0.0;
    final double discountAmount =
        (item['discount_amount'] as num?)?.toDouble() ?? 0.0;
    final double addonTotal = (item['addon_total'] as num?)?.toDouble() ?? 0.0;
    final double lineTotal = productAmount - discountAmount + addonTotal;

    final List<String> details = <String>[];
    if (getAddOnsType() == typeSizeColor) {
      final String size = (item['size'] ?? '').toString();
      final String color = (item['color'] ?? '').toString();
      if (size.isNotEmpty) details.add(size);
      if (color.isNotEmpty) details.add(color);
    } else {
      for (final dynamic option in (item['options'] as List?) ?? const []) {
        final String name = (option['option_names'] ?? '').toString();
        if (name.isNotEmpty) details.add(name);
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: widget.showTopRule
          ? const BoxDecoration(
              border: Border(top: BorderSide(color: ScSaasThemeTokens.gray100)),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // `.co-item .ph` — 48×48, radius 11.
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: LoadImageSimple(
              image: item['product_image'] ?? '',
              width: 48,
              height: 48,
              imageFit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: coItemName,
                ),
                if (details.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      details.join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: coItemQty,
                    ),
                  ),
                const SizedBox(height: 8),
                CoQtyStepper(
                  quantity: _quantity,
                  busy: _busy,
                  onMinus: () => _changeQuantity(_quantity - 1),
                  onPlus: () => _changeQuantity(_quantity + 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatNok(lineTotal), style: coItemPrice),
              if (widget.onEdit != null) CoEditLink(onTap: widget.onEdit!),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tip chip — pill, purple-100 fill + purple-600 border when selected.
Widget _tipOption(
  String label,
  VoidCallback onPressed, {
  bool isSelected = false,
}) {
  return GestureDetector(
    onTap: onPressed,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: isSelected ? ScSaasThemeTokens.primaryTint : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isSelected ? ScSaasThemeTokens.primary : kDgspBorder,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Text(
        label,
        style: coSans(
          size: 13.5,
          weight: FontWeight.w800,
          height: 1.2,
          color: isSelected
              ? ScSaasThemeTokens.primaryHover
              : ScSaasThemeTokens.text,
        ),
      ),
    ),
  );
}

Future<void> _openOrderItemEditor(
  BuildContext context,
  CheckOutBloc? bloc,
  dynamic orderItem,
) async {
  final int productId = (orderItem['product_id'] as num?)?.toInt() ?? 0;
  if (productId == 0) {
    openSimpleSnackbar(languages.checkoutUnableToEdit);
    return;
  }

  final List<dynamic> existingOptions =
      (orderItem['options'] as List?) ?? const <dynamic>[];
  final List<int> selectedOptionIds = existingOptions
      .map<int?>((option) {
        if (option is! Map) return null;
        return (option['option_id'] as num?)?.toInt() ??
            (option['id'] as num?)?.toInt();
      })
      .whereType<int>()
      .toList();
  if (selectedOptionIds.isEmpty) {
    final dynamic rawOptionIds =
        orderItem['option_ids'] ?? orderItem['option_id'];
    if (rawOptionIds is List) {
      selectedOptionIds.addAll(
        rawOptionIds
            .map<int?>((id) => (id as num?)?.toInt() ?? int.tryParse('$id'))
            .whereType<int>(),
      );
    } else if (rawOptionIds is String && rawOptionIds.trim().isNotEmpty) {
      selectedOptionIds.addAll(
        rawOptionIds
            .split(',')
            .map((e) => int.tryParse(e.trim()))
            .whereType<int>(),
      );
    }
  }

  prefSetInt('checkedSize', (orderItem['size_id'] as num?)?.toInt() ?? 0);
  prefSetInt('checkedColor', (orderItem['color_id'] as num?)?.toInt() ?? 0);
  prefSetString('checkedOptionList', jsonEncode(selectedOptionIds));

  dynamic addOnResponse;
  try {
    addOnResponse = await AddOnRepo().getToppingsAndOptions(productId);
  } catch (e) {
    openSimpleSnackbar(languages.checkoutUnableToLoadEdit);
    return;
  }
  final List sizeList = addOnResponse['size_list'] ?? [];
  final List colorList = addOnResponse['color_list'] ?? [];
  final List optionList = addOnResponse['option_list'] ?? [];

  int quantity = (orderItem['quantity'] as num?)?.toInt() ?? 1;
  bool inStock = true;
  String addOnsMessage = '';
  bool isSaving = false;

  if (!context.mounted) return;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(minWidth: double.infinity),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(kDugnadSheetRadius),
        topRight: Radius.circular(kDugnadSheetRadius),
      ),
    ),
    builder: (BuildContext bottomSheetContext) {
      return StatefulBuilder(
        builder: (BuildContext _, StateSetter setSheetState) {
          return SizedBox(
            height: deviceHeight * 0.83,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(kDugnadSheetRadius),
                  child: LoadImageSimple(
                    image: orderItem['product_image'] ?? '',
                    imageFit: BoxFit.contain,
                    height: deviceHeight * 0.33,
                    width: double.infinity,
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  top: deviceHeight * 0.35,
                  bottom: 100,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(orderItem["product_name"] ?? '', style: aeH2()),
                        const SizedBox(height: 10),
                        Text(
                          orderItem['description'] ?? '',
                          style: aeBody(color: ScSaasThemeTokens.gray500),
                        ),
                        const SizedBox(height: 8),
                        const Divider(color: ScSaasThemeTokens.gray100),
                        if (addOnsMessage.isNotEmpty)
                          Text(
                            addOnsMessage,
                            style: aeCaption(color: ScSaasThemeTokens.danger),
                          ),
                        const SizedBox(height: 8),
                        if (sizeList.isNotEmpty || colorList.isNotEmpty)
                          SizeColorWidget(
                            sizeOptional: orderItem['size_optional'] ?? 0,
                            colorOptional: orderItem['color_optional'] ?? 0,
                            sizeList: sizeList,
                            colorList: colorList,
                            validate: (value) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                setSheetState(() {
                                  inStock = value;
                                });
                              });
                            },
                          )
                        else
                          const SizedBox.shrink(),
                        if (optionList.isNotEmpty) const SizedBox(height: 8),
                        if (optionList.isNotEmpty)
                          ToppingOptionWidget(
                            optionList: optionList,
                            validate: (value) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                setSheetState(() {
                                  addOnsMessage = value;
                                });
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(bottomSheetContext),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: ScSaasThemeTokens.shadowCard,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: ScSaasThemeTokens.text,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 25,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CoQtyStepper(
                        quantity: quantity,
                        onMinus: () => setSheetState(() {
                          if (quantity > 0) quantity--;
                        }),
                        onPlus: () => setSheetState(() => quantity++),
                      ),
                      SizedBox(
                        height: 50,
                        width: deviceWidth * 0.55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ScSaasThemeTokens.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed:
                              !inStock || addOnsMessage.isNotEmpty || isSaving
                              ? null
                              : () async {
                                  setSheetState(() {
                                    isSaving = true;
                                  });
                                  try {
                                    final int storeId =
                                        (bloc
                                                    ?.subject
                                                    .valueOrNull
                                                    ?.data?['store_id']
                                                as num?)
                                            ?.toInt() ??
                                        0;
                                    if (storeId == 0) {
                                      openSimpleSnackbar(
                                        'Unable to edit item right now.',
                                      );
                                      return;
                                    }

                                    final int cartId =
                                        (orderItem['id'] as num?)?.toInt() ?? 0;
                                    if (quantity == 0) {
                                      if (cartId != 0) {
                                        await OrderCartRepo()
                                            .deleteOrderCartApi(cartId);
                                      }
                                      await bloc?.getOrderPreview();
                                      if (bottomSheetContext.mounted) {
                                        Navigator.pop(bottomSheetContext);
                                      }
                                      return;
                                    }

                                    final dynamic addResponse =
                                        await StoreDetailRepo()
                                            .callOrderCartApi(
                                              storeId,
                                              productId,
                                              quantity,
                                            );
                                    final int addStatus =
                                        (addResponse['status'] as num?)
                                            ?.toInt() ??
                                        0;
                                    if (addStatus != 1) {
                                      openSimpleSnackbar(
                                        addResponse['message'] ??
                                            'Failed to update item.',
                                      );
                                      return;
                                    }

                                    if (cartId != 0) {
                                      await OrderCartRepo().deleteOrderCartApi(
                                        cartId,
                                      );
                                    }
                                    await bloc?.getOrderPreview();
                                    if (bottomSheetContext.mounted) {
                                      Navigator.pop(bottomSheetContext);
                                    }
                                  } catch (e) {
                                    openSimpleSnackbar(e.toString());
                                  } finally {
                                    if (bottomSheetContext.mounted) {
                                      setSheetState(() {
                                        isSaving = false;
                                      });
                                    }
                                  }
                                },
                          child: Text(
                            isSaving
                                ? '${languages.processing}...'
                                : (quantity == 0
                                      ? languages.remove
                                      : languages.updateCart),
                            style: aeTitle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
