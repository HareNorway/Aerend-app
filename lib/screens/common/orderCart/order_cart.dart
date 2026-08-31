import 'package:flutter/material.dart';
import 'package:aerend_customer/networking/api_base_helper.dart';
import 'package:aerend_customer/screens/common/homeMainV1/home_main_v1.dart';
import 'package:aerend_customer/screens/common/orderCart/order_cart_repo.dart';
import 'package:aerend_customer/screens/deliveryService/storeDetail/add_on_repo.dart';
import 'package:aerend_customer/theme/sc_saas_theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../../commonView/load_image_with_placeholder.dart';
import '../../../commonView/surface_decorations.dart';
import 'package:aerend_customer/screens/deliveryService/storeDetail/widget_topping_option.dart';
import 'package:aerend_customer/screens/deliveryService/storeDetail/widget_size_color.dart';
import './order_cart_bloc.dart';
import '../../../utils/utils.dart';
import '../../../ui/kit/ae_rise_in.dart';
import '../../deliveryService/checkout/checkout.dart';
import '../../deliveryService/checkout/co_styles.dart';

class OrderCart extends StatefulWidget {
  final bool fromStore;
  const OrderCart({super.key, this.fromStore = false});

  @override
  OrderCartState createState() => OrderCartState();
}

class OrderCartState extends State<OrderCart> {
  OrderCartBloc? bloc;

  int numberOfCart = 0;
  int prodQuantity = 1;
  double cartAmount = 0;
  bool inStock = true;
  String addOnsMessage = '';
  bool _isCheckoutLoading = false;

  @override
  void initState() {
    super.initState();
    bloc = OrderCartBloc(context, this);
    bloc?.subject.listen((response) {
      if (response.data != null && response.status == Status.completed) {
        List orderList = response.data!['order_list'];
        setState(() {
          numberOfCart = orderList.length;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    bloc!.dispose();
    super.dispose();
  }

  Future<void> _openCheckoutOnce() async {
    if (_isCheckoutLoading) return;
    if (!mounted) return;
    setState(() => _isCheckoutLoading = true);
    try {
      if (!mounted) return;
      await openScreenWithResult(context, const CheckOut());
    } finally {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) setState(() => _isCheckoutLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ApiResponse>(
      stream: bloc?.subject,
      builder: (context, snapshot) {
        Widget body;

        if (snapshot.hasData) {
          switch (snapshot.data!.status!) {
            case Status.loading:
              body = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [Expanded(child: OrderCartShimmer(enabled: true))],
              );
              break;
            case Status.completed:
              final map = snapshot.data!.data!;
              final List orderList = map['order_list'];
              final List recommendationList =
                  (map['recommendation_list'] as List?) ?? [];
              cartAmount = (map['order_amount'] as num?)?.toDouble() ?? 0.0;

              if (orderList.isNotEmpty) {
                body = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRect(
                        child: _orderCartListBody(
                          context,
                          orderList,
                          recommendationList,
                        ),
                      ),
                    ),
                    _checkoutButtonStrip(
                      context,
                      itemCount: orderList.length,
                      totalAmount: cartAmount,
                    ),
                  ],
                );
              } else {
                body = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [Expanded(child: _blankCartBody(context))],
                );
              }
              break;
            case Status.error:
              body = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [Expanded(child: _blankCartBody(context))],
              );
              break;
          }
        } else {
          body = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [Expanded(child: OrderCartShimmer(enabled: true))],
          );
        }

        const pageBg = ScSaasThemeTokens.background;

        return Scaffold(
          backgroundColor: pageBg,
          appBar: AppBar(
            elevation: 0,
            automaticallyImplyLeading: false,
            backgroundColor: pageBg,
            leading: widget.fromStore
                ? Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: ScSaasThemeTokens.shadowCard,
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: ScSaasThemeTokens.text,
                          size: 20,
                        ),
                      ),
                    ),
                  )
                : null,
            titleSpacing: widget.fromStore ? 0 : 20,
            title: Text(
              numberOfCart > 0
                  ? languages.cartTitle(numberOfCart)
                  : languages.cart,
              style: coHeadTitle.copyWith(color: theme?.text),
            ),
            centerTitle: false,
          ),
          body: MediaQuery.removePadding(
            context: context,
            removeBottom: true,
            child: SizedBox.expand(child: body),
          ),
        );
      },
    );
  }

  // ── Cart items + recommendations ────────────────────────────────
  /// `.co-body` — padding `4px 18px 18px`, gap 14. The cart lines live in one
  /// `.co-card` under a `.co-label`, exactly like the matkasse «Din bestilling».
  Widget _orderCartListBody(
    BuildContext context,
    List orderList,
    List recommendationList,
  ) {
    return ColoredBox(
      color: ScSaasThemeTokens.background,
      child: SingleChildScrollView(
        clipBehavior: Clip.hardEdge,
        padding: const EdgeInsets.fromLTRB(kCoBodyPadH, 4, kCoBodyPadH, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AeRiseIn(
              delay: const Duration(milliseconds: 120),
              child: CoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CoLabel(languages.checkoutOrderSummary),
                    ...List.generate(
                      orderList.length,
                      (i) => orderCartCard(orderList[i], showTopRule: i > 0),
                    ),
                  ],
                ),
              ),
            ),
            if (recommendationList.isNotEmpty) ...[
              const SizedBox(height: kCoBodyGap),
              AeRiseIn(
                delay: const Duration(milliseconds: 190),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CoLabel(languages.cartRecommendations),
                    ...List.generate(
                      recommendationList.length,
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: productCard(recommendationList[i]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// `.mk-cartbar` — white sheet pinned to the bottom: radius `20px 20px 0 0`,
  /// padding `12px 14px calc(safe-area + 14px)`, gap 12, upward shadow
  /// `0 -2px 6px rgba(45,27,91,.05), 0 -16px 36px -16px rgba(45,27,91,.28)`.
  Widget _checkoutButtonStrip(
    BuildContext context, {
    required int itemCount,
    required double totalAmount,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        12,
        14,
        MediaQuery.paddingOf(context).bottom + 14,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D2D1B5B),
            blurRadius: 6,
            offset: Offset(0, -2),
          ),
          BoxShadow(
            color: Color(0x472D1B5B),
            blurRadius: 36,
            offset: Offset(0, -16),
            spreadRadius: -16,
          ),
        ],
      ),
      child: Row(
        children: [
          // `.mk-cart-toggle .ic` — 42×42, radius 13, purple-100 + count badge.
          SizedBox(
            width: 42,
            height: 42,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: ScSaasThemeTokens.primaryTint,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: ScSaasThemeTokens.primary.withValues(alpha: 0.16),
                    ),
                  ),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    size: 19,
                    color: ScSaasThemeTokens.primaryHover,
                  ),
                ),
                // `.mk-cart-toggle .ic .ct`
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    height: 20,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: ScSaasThemeTokens.success,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      '$itemCount',
                      style: coSans(
                        size: 11,
                        weight: FontWeight.w800,
                        height: 1,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // `.mk-cartbar .items`
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  languages.cartTitle(itemCount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: coCartBarSum,
                ),
                const SizedBox(height: 2),
                Text(
                  formatNok(totalAmount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: coCartBarTotal,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // `.mk-cart-go` — shiny-purple, radius 13, padding 13×20, 14/800.
          GestureDetector(
            onTap: _isCheckoutLoading ? null : _openCheckoutOnce,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: _isCheckoutLoading ? null : kAeShinyPurple,
                color: _isCheckoutLoading
                    ? ScSaasThemeTokens.primaryDisabled
                    : null,
                borderRadius: BorderRadius.circular(13),
                boxShadow: _isCheckoutLoading
                    ? null
                    : const [
                        BoxShadow(
                          color: Color(0x8C7F5FC4),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                          spreadRadius: -6,
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isCheckoutLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 17,
                      color: Colors.white,
                    ),
                  const SizedBox(width: 7),
                  Text(
                    _isCheckoutLoading
                        ? languages.cartOpening
                        : languages.cartToCheckout,
                    style: coSans(
                      size: 14,
                      weight: FontWeight.w800,
                      height: 1.2,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty cart ──────────────────────────────────────────────────
  Widget _blankCartBody(BuildContext context) {
    return ColoredBox(
      color: ScSaasThemeTokens.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Transform.translate(
            offset: const Offset(0, -28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: theme?.primaryTint ?? ScSaasThemeTokens.primaryTint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shopping_cart_outlined,
                    color: theme?.primaryHover ?? ScSaasThemeTokens.primaryHover,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  languages.cartEmpty,
                  textAlign: TextAlign.center,
                  style: aeH3(),
                ),
                const SizedBox(height: 8),
                Text(
                  languages.cartAddProducts,
                  textAlign: TextAlign.center,
                  style: aeBody(
                    color: ScSaasThemeTokens.gray500,
                  ).copyWith(height: 1.35),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => _handleEmptyCartCta(context),
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    constraints: const BoxConstraints(maxWidth: 270),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFF8D61D8), Color(0xFF5E35B1)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: ScSaasThemeTokens.shadowButton,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.storefront_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          languages.cartBackToStores,
                          style: aeTitle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleEmptyCartCta(BuildContext context) {
    final homeState = context.findAncestorStateOfType<HomeMainV1State>();
    if (homeState != null) {
      homeState.switchToTab(0);
      return;
    }

    openScreenWithResult(context, const HomeMainV1(homeIndex: 2));
  }

  /// `.co-item` — 48px thumb (radius 11), name 14/700, `.mk-cstep.sm` stepper,
  /// price 14/800; consecutive rows separated by a 1px gray-100 rule.
  Widget orderCartCard(dynamic order, {bool showTopRule = false}) {
    int quantity = order['quantity'];
    return StatefulBuilder(
      builder: (context, setCardState) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: showTopRule
              ? const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: ScSaasThemeTokens.gray100),
                  ),
                )
              : null,
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // `.co-item .ph`
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: LoadImageSimple(
                      image: order['product_image'] ?? '',
                      width: 48,
                      height: 48,
                      imageFit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order['product_name'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: coItemName,
                        ),
                        const SizedBox(height: 2),
                        if ((order['description'] ?? '').toString().isNotEmpty)
                          Text(
                            order['description'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: coItemQty,
                          ),
                        // Snurre review badge.
                        if (order['snurre_flag_review'] == true ||
                            order['snurre_flag_review'] == 1) ...[
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () {
                              final requested =
                                  order['snurre_requested_label'] ??
                                  'the requested item';
                              final matched =
                                  order['snurre_matched_label'] ??
                                  order['product_name'] ??
                                  'this item';
                              final reason = order['snurre_match_reason'] ?? '';
                              showDialog<void>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  title: Text(
                                    languages.cartReviewSubstitution,
                                    style: aeTitle(),
                                  ),
                                  content: Text(
                                    reason.toString().isNotEmpty
                                        ? reason.toString()
                                        : languages.cartSubstitutionDetail(
                                            requested.toString(),
                                            matched.toString(),
                                          ),
                                    style: aeBody(),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: Text(
                                        languages.ok,
                                        style: aeLabel(
                                          color: ScSaasThemeTokens.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: ScSaasThemeTokens.warning.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                languages.cartReviewSubstitution,
                                style:
                                    aeCaption(
                                      color: ScSaasThemeTokens.warning,
                                    ).copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        // `.mk-cstep.sm` quantity stepper
                        CoQtyStepper(
                          quantity: quantity,
                          onMinus: () {
                            setCardState(() {
                              if (quantity > 1) quantity--;
                              OrderCartRepo().callChangeQuantityApi(
                                order['id'],
                                quantity,
                              );
                            });
                          },
                          onPlus: () {
                            setCardState(() {
                              quantity++;
                              OrderCartRepo().callChangeQuantityApi(
                                order['id'],
                                quantity,
                              );
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // `.co-item .pr` + remove
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatNok(
                          order['product_amount'].toDouble() /
                              order['quantity'] *
                              quantity,
                        ),
                        style: coItemPrice,
                      ),
                      if (order['discount_amount'].toDouble() > 0)
                        Text(
                          formatNok(
                            order['product_amount'].toDouble() +
                                order['discount_amount'].toDouble(),
                          ),
                          style: coItemQty.copyWith(
                            decoration: TextDecoration.lineThrough,
                            decorationColor: ScSaasThemeTokens.gray500,
                          ),
                        ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () =>
                            bloc!.removeCartItem((order['id'] as num).toInt()),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: ScSaasThemeTokens.danger.withValues(
                              alpha: 0.08,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: ScSaasThemeTokens.danger,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Recommendation card ────────────────────────────────────────
  Widget productCard(dynamic product) {
    final double productAmount = getDoubleFromDynamic(
      product["product_amount"],
    );
    final double discountAmount = getDoubleFromDynamic(
      product["discount_amount"],
    );
    final int rateCount = (product["rate_count"] as num?)?.toInt() ?? 0;
    final double rateSum = getDoubleFromDynamic(product["rate_sum"]);
    final int deliveryTime = (product["delivery_time"] as num?)?.toInt() ?? 0;
    final int prepareTime = (product["prepare_time"] as num?)?.toInt() ?? 0;
    final double displayPrice = productAmount - discountAmount;
    final double displayRating = rateCount > 0 ? (rateSum / rateCount) : 0.0;

    return GestureDetector(
      onTap: () async {
        final int productId =
            (product['id'] as num?)?.toInt() ??
            (product['product_id'] as num?)?.toInt() ??
            0;
        if (productId == 0) {
          openSimpleSnackbar(languages.cartCannotLoadProduct);
          return;
        }
        var response = await AddOnRepo().getToppingsAndOptions(productId);
        if (!mounted) return;
        if (response['status'] == 1) {
          final int serviceCategoryId =
              (response['service_category_id'] as num?)?.toInt() ??
              prefGetInt(prefSelectedServiceCateId);
          prefSetInt(prefSelectedServiceCateId, serviceCategoryId);
          _openFoodSheet(
            context,
            product,
            response['size_list'],
            response['color_list'],
            response['options_list'],
          );
        }
      },
      child: Container(
        decoration: AeSurface.card(),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
              child: LoadImageSimple(
                image: product["product_image"] ?? '',
                width: 90,
                height: 90,
                imageFit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product["product_name"] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: aeTitle(),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product["description"] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: aeCaption(),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(formatNok(displayPrice), style: aeLabel()),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (rateCount > 0) ...[
                              Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: Colors.amber.shade600,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                displayRating.toStringAsFixed(1),
                                style: aeCaption(),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: ScSaasThemeTokens.gray500,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${deliveryTime + prepareTime} min',
                              style: aeCaption(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Add button
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: ScSaasThemeTokens.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Product modal (logic UNTOUCHED) ────────────────────────────
  void _openFoodSheet(
    BuildContext context,
    dynamic product,
    List sizeList,
    List colorList,
    List optionList,
  ) {
    final double productAmount = getDoubleFromDynamic(
      product['product_amount'],
    );
    final double discountAmount = getDoubleFromDynamic(
      product['discount_amount'],
    );
    final int sizeOptional = (product['size_optional'] as num?)?.toInt() ?? 1;
    final int colorOptional = (product['color_optional'] as num?)?.toInt() ?? 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(minWidth: double.infinity),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SizedBox(
              height: deviceHeight * 0.83,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: LoadImageSimple(
                      image: product['product_image'] ?? '',
                      imageFit: BoxFit.cover,
                      height: deviceHeight * 0.31,
                      width: double.infinity,
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    top: deviceHeight * 0.33,
                    bottom: 90,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product["product_name"] ?? '', style: aeH2()),
                          const SizedBox(height: 8),
                          if (discountAmount > 0)
                            Text(
                              formatNok(discountAmount),
                              style: aeCaption().copyWith(
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          Text(
                            formatNok(productAmount - discountAmount),
                            style: aeH3(),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            product['description'] ?? '',
                            style: aeBody(color: ScSaasThemeTokens.gray500),
                          ),
                          const SizedBox(height: 8),
                          Divider(color: ScSaasThemeTokens.gray100),
                          if (addOnsMessage != '')
                            Text(
                              addOnsMessage,
                              style: aeCaption(color: ScSaasThemeTokens.danger),
                            ),
                          const SizedBox(height: 8),
                          if (getAddOnsType() == typeSizeColor)
                            SizeColorWidget(
                              sizeOptional: sizeOptional,
                              colorOptional: colorOptional,
                              sizeList: sizeList,
                              colorList: colorList,
                              validate: (value) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  setState(() => inStock = value);
                                });
                              },
                            )
                          else if (getAddOnsType() == typeToppingOption)
                            ToppingOptionWidget(
                              optionList: optionList,
                              validate: (value) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  setState(() => addOnsMessage = value);
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Close button
                  Positioned(
                    top: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
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
                  // Bottom bar: qty + add
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      color: Colors.white,
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => setState(() {
                              if (prodQuantity > 1) prodQuantity--;
                            }),
                            icon: Icon(
                              Icons.remove_circle_rounded,
                              color: prodQuantity > 1
                                  ? ScSaasThemeTokens.primary
                                  : ScSaasThemeTokens.primaryDisabled,
                              size: 28,
                            ),
                          ),
                          Text('$prodQuantity', style: aeH3()),
                          IconButton(
                            onPressed: () => setState(() => prodQuantity++),
                            icon: const Icon(
                              Icons.add_circle_rounded,
                              color: ScSaasThemeTokens.primary,
                              size: 28,
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            height: 50,
                            width: deviceWidth * 0.5,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ScSaasThemeTokens.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: !inStock || addOnsMessage != ''
                                  ? null
                                  : () {
                                      final int productId =
                                          (product["id"] as num?)?.toInt() ??
                                          (product["product_id"] as num?)
                                              ?.toInt() ??
                                          0;
                                      if (productId == 0) {
                                        openSimpleSnackbar(
                                          languages.cartCannotAddNow,
                                        );
                                        return;
                                      }
                                      bloc!.addOrderCart(
                                        productId,
                                        prodQuantity,
                                      );
                                      Navigator.pop(context);
                                    },
                              child: Text(
                                languages.storeAddToCart,
                                style: aeTitle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
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
}

// ── Shimmer (unchanged) ──────────────────────────────────────────
class OrderCartShimmer extends StatelessWidget {
  final bool enabled;
  const OrderCartShimmer({super.key, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Shimmer.fromColors(
        baseColor: colorShimmerBg,
        highlightColor: Colors.grey.shade100,
        enabled: enabled,
        period: const Duration(milliseconds: 1500),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: 8,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (_, __) => const ItemOrderListShimmer(),
        ),
      ),
    );
  }
}

class ItemOrderListShimmer extends StatelessWidget {
  const ItemOrderListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: deviceWidth * 0.02),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 0,
            child: Stack(
              fit: StackFit.loose,
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.all(
                    Radius.circular(deviceAverageSize * 0.012),
                  ),
                  child: Container(
                    width: deviceAverageSize * 0.13,
                    height: deviceAverageSize * 0.13,
                    color: Colors.black,
                  ),
                ),
                Container(
                  width: deviceAverageSize * 0.13,
                  margin: EdgeInsetsDirectional.only(
                    top: deviceAverageSize * 0.11,
                  ),
                  child: Center(
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          deviceAverageSize * 0.005,
                        ),
                      ),
                      elevation: deviceAverageSize * 0.009,
                      child: Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: deviceAverageSize * 0.008,
                        ),
                        width: deviceAverageSize * 0.06,
                        color: Colors.black,
                        height: deviceHeight * 0.02,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: deviceWidth * 0.025),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: deviceWidth * 0.4,
                  height: deviceHeight * 0.022,
                  color: Colors.black,
                ),
                Container(
                  constraints: BoxConstraints(maxHeight: deviceHeight * 0.066),
                  child: Wrap(
                    clipBehavior: Clip.antiAlias,
                    children: "Fast Food, Combo"
                        .split(",")
                        .map<Widget>(
                          (s) => Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                deviceAverageSize * 0.006,
                              ),
                              color: colorGray,
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: deviceWidth * 0.01,
                            ),
                            margin: EdgeInsetsDirectional.only(
                              end: deviceWidth * 0.01,
                              top: deviceHeight * 0.004,
                              bottom: deviceHeight * 0.004,
                            ),
                            child: Text(
                              s,
                              style: bodyText(
                                fontSize: textSizeSmallest,
                                textColor: colorTextCommonLight,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      FaIcon(
                        FontAwesomeIcons.clock,
                        size: deviceAverageSize * 0.02,
                        color: colorTextCommonLight,
                      ),
                      SizedBox(width: deviceWidth * 0.01),
                      Flexible(
                        child: Container(
                          width: deviceWidth * 0.2,
                          height: deviceHeight * 0.02,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsetsDirectional.only(
                    top: deviceWidth * 0.005,
                    bottom: deviceHeight * 0.005,
                  ),
                  child: Row(
                    children: [
                      FaIcon(
                        CustomIcons.offer,
                        size: deviceAverageSize * 0.021,
                        color: colorOfferDiscountGray,
                      ),
                      SizedBox(width: deviceWidth * 0.005),
                      Expanded(
                        flex: 1,
                        child: Container(
                          width: deviceWidth * 0.3,
                          height: deviceHeight * 0.02,
                          color: Colors.black,
                        ),
                      ),
                      Container(
                        height: deviceAverageSize * 0.012,
                        width: deviceAverageSize * 0.012,
                        margin: EdgeInsetsDirectional.only(
                          start: deviceWidth * 0.02,
                          end: deviceWidth * 0.02,
                        ),
                        decoration: const BoxDecoration(
                          color: colorRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: deviceWidth * 0.2,
                        height: deviceHeight * 0.02,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
                Divider(color: colorGray, thickness: deviceHeight * 0.0015),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
