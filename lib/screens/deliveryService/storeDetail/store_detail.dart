import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:aerend_customer/screens/common/homeMainV1/home_main_v1.dart';
import 'package:aerend_customer/screens/deliveryService/searchStore/search_store.dart';
import 'package:aerend_customer/screens/deliveryService/storeDetail/store_info.dart';
import 'package:aerend_customer/utils/discount_star.dart';

import '../../../commonView/no_record_found.dart';
import '../../../commonView/surface_decorations.dart';
import '../../../networking/api_base_helper.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import 'add_on_repo.dart';
import 'store_detail_bloc.dart';
import 'store_detail_dl.dart';
import 'store_detail_shimmer.dart';
import 'widget_size_color.dart';
import 'widget_topping_option.dart';

class StoreDetail extends StatefulWidget {
  final int storeId;
  final String storeName;

  const StoreDetail(
      {super.key, required this.storeId, required this.storeName});

  @override
  StoreDetailState createState() => StoreDetailState();
}

class StoreDetailState extends State<StoreDetail> {
  late StoreDetailBloc bloc;
  int prodQuantity = 1;
  int brandId = 0;
  bool inStock = true;
  String addOnsMessage = "";

  double _toPrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  double _resolvedOriginalAmount(ProductListItem product) {
    final explicitOriginal = _toPrice(product.originalAmount);
    if (explicitOriginal > 0) return explicitOriginal;
    final fromDiscountAmount = _toPrice(product.discountAmount);
    if (fromDiscountAmount > 0) return fromDiscountAmount;
    final current = _toPrice(product.productAmount);
    final offerDiscount = _toPrice(product.offerDiscount);
    if (offerDiscount > 0) return current + offerDiscount;
    return current;
  }

  bool _hasDiscount(ProductListItem product) {
    final current = _toPrice(product.productAmount);
    final original = _resolvedOriginalAmount(product);
    return original > current;
  }

  int _resolvedDiscountPercent(ProductListItem product) {
    if (product.discountPercent > 0) return product.discountPercent;
    final current = _toPrice(product.productAmount);
    final original = _resolvedOriginalAmount(product);
    if (original <= 0 || original <= current) return 0;
    return (((original - current) / original) * 100).round();
  }

  String _resolvedProductImage(ProductListItem product) {
    final primary = product.productImage.trim();
    if (primary.isNotEmpty) return primary;
    for (final dynamic image in product.productImageList) {
      final url = (image ?? '').toString().trim();
      if (url.isNotEmpty) return url;
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    bloc = StoreDetailBloc(context, widget.storeId, this);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ApiResponse<StoreDetailsPojo>>(
      stream: bloc.subject,
      builder: (context, snap) {
        final Widget child;

        if (snap.hasData) {
          switch (snap.data?.status) {
            case Status.loading:
              child = KeyedSubtree(
                key: const ValueKey('store-detail-loading'),
                child: shimmerView(context, true),
              );
              break;
            case Status.completed:
              final StoreDetailsPojo data = snap.data!.data!;
              child = KeyedSubtree(
                key: const ValueKey('store-detail-content'),
                child: _storeDetailView(context, data, bloc),
              );
              break;
            case Status.error:
              child = KeyedSubtree(
                key: const ValueKey('store-detail-error'),
                child: noRecordView(context, snap.data?.message ?? ""),
              );
              break;
            default:
              child = KeyedSubtree(
                key: const ValueKey('store-detail-loading-default'),
                child: shimmerView(context, true),
              );
              break;
          }
        } else {
          child = KeyedSubtree(
            key: const ValueKey('store-detail-loading-initial'),
            child: shimmerView(context, true),
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              children: [
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            );
          },
          child: child,
        );
      },
    );
  }

  // ── MAIN STORE DETAIL VIEW ──────────────────────────────────────
  Widget _storeDetailView(
      BuildContext context, StoreDetailsPojo data, StoreDetailBloc bloc) {
    return Scaffold(
      backgroundColor: ScSaasThemeTokens.background,
      body: Stack(
        children: [
          DefaultTabController(
            initialIndex: 0,
            length: data.categoryWiseProductList.length,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  // ── Warm gradient photo hero ──
                  SliverAppBar(
                    expandedHeight: 220,
                    pinned: true,
                    automaticallyImplyLeading: false,
                    backgroundColor: ScSaasThemeTokens.background,
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.parallax,
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Store banner image
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(24),
                              bottomRight: Radius.circular(24),
                            ),
                            child: ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Color(0x99000000)],
                                stops: [0.3, 1.0],
                              ).createShader(bounds),
                              blendMode: BlendMode.darken,
                              child: LoadImageSimple(
                                image: data.storeBanner,
                                height: double.infinity,
                                imageFit: BoxFit.cover,
                              ),
                            ),
                          ),
                          // Status badge
                          Positioned(
                            top: MediaQuery.of(context).padding.top + 12,
                            right: 20,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: data.storeStatus == 1
                                    ? ScSaasThemeTokens.success
                                    : ScSaasThemeTokens.danger,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                data.storeStatus == 1 ? languages.open : languages.closed,
                                style: aeCaption(color: Colors.white).copyWith(
                                    fontWeight: FontWeight.w700, fontSize: 11),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Floating back pill
                    leading: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.82),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              color: ScSaasThemeTokens.text, size: 20),
                        ),
                      ),
                    ),
                  ),

                  // ── Store header info ──
                  SliverToBoxAdapter(
                    child: Transform.translate(
                      offset: const Offset(0, -30),
                      child: Column(
                        children: [
                          // Logo overlay
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: ScSaasThemeTokens.shadowCard,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: ClipOval(
                              child: LoadImageSimple(
                                image: data.storeLogo,
                                height: 64,
                                width: 64,
                                imageFit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Store name
                          Text(data.storeName, style: aeH2()),
                          const SizedBox(height: 6),
                          // Rating + address row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.star_rounded,
                                  color: Colors.amber.shade600, size: 16),
                              const SizedBox(width: 2),
                              Text('${data.averageRating}',
                                  style: aeLabel()),
                              const SizedBox(width: 12),
                              Text(data.address,
                                  style: aeCaption()),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Action pills row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _actionPill(
                                icon: Icons.info_outline_rounded,
                                label: 'Info',
                                onTap: () => openScreenWithResult(
                                  context,
                                  StoreInfo(
                                    storeId: widget.storeId,
                                    storeName: widget.storeName,
                                  ),
                                ),
                              ),
                              // Lagre (favorite) and Del (share) hidden — no backend action.
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Search bar
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              height: 44,
                              decoration: AeSurface.card(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: TextFormField(
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (value) =>
                                    openScreenWithResult(
                                  context,
                                  SearchStore(
                                      latLng: prefGetLatLng(), keyword: value),
                                ),
                                style: aeBody(),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  prefixIcon: const Icon(Icons.search_rounded,
                                      color: ScSaasThemeTokens.gray500,
                                      size: 20),
                                  hintText: languages.storeSearchIn(data.storeName),
                                  hintStyle: aeCaption(),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Category tabs ──
                  if (data.categoryWiseProductList.isNotEmpty)
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _TabBarDelegate(
                        TabBar(
                          isScrollable: true,
                          indicatorColor: ScSaasThemeTokens.primary,
                          indicatorWeight: 3,
                          labelColor: ScSaasThemeTokens.text,
                          unselectedLabelColor: ScSaasThemeTokens.gray500,
                          labelStyle: aeLabel(),
                          unselectedLabelStyle:
                              aeLabel(color: ScSaasThemeTokens.gray500),
                          labelPadding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 16),
                          tabs: data.categoryWiseProductList
                              .map((c) => Text(c.categoryName))
                              .toList(),
                        ),
                      ),
                    ),
                ];
              },
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: data.categoryWiseProductList.isNotEmpty
                    ? TabBarView(
                        children: data.categoryWiseProductList.map((category) {
                          return category.subCategoryList.isNotEmpty
                              ? subCategoryView(
                                  category.subCategoryList,
                                  data.storeStatus == 1,
                                  data.deliveryTime)
                              : const NoRecordFound(
                                  message:
                                      'No any subcategory found in this category',
                                );
                        }).toList(),
                      )
                    : const NoRecordFound(
                        message: "No any category found in this service",
                      ),
              ),
            ),
          ),
          // ── Sticky cart bar ──
          _stickyCartBar(bloc),
        ],
      ),
    );
  }

  Widget _actionPill({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: AeSurface.card(
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: ScSaasThemeTokens.primaryHover),
            const SizedBox(width: 6),
            Text(label, style: aeCaption(color: ScSaasThemeTokens.text)),
          ],
        ),
      ),
    );
  }

  Widget _stickyCartBar(StoreDetailBloc bloc) {
    return StreamBuilder<ApiResponse<UserOrderCartPojo>>(
      stream: bloc.orderCartSubject,
      builder: (context, snap) {
        if (snap.hasData && snap.data?.status == Status.completed) {
          final cart = snap.data?.data;
          if (cart == null || cart.countOrder == 0) {
            return const SizedBox.shrink();
          }
          return Positioned(
            right: 20,
            left: 20,
            bottom: 30,
            child: GestureDetector(
              onTap: () => openScreenWithResult(
                context,
                const HomeMainV1(homeIndex: 1, fromStore: true),
              ),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: ScSaasThemeTokens.primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: ScSaasThemeTokens.shadowButton,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Center(
                        child: Text(
                          '${cart.countOrder}',
                          style: aeLabel(color: ScSaasThemeTokens.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(languages.storeViewCart,
                        style: aeTitle(color: Colors.white)),
                    const Spacer(),
                    Text('NOK ${cart.orderAmount}',
                        style: aeTitle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  // ── SUBCATEGORY VIEW (preserved logic, restyled chips) ──────────
  Widget subCategoryView(List<SubCategoryWiseProductListItem> subCategoryList,
      bool storeStatus, deliveryTime) {
    int subCategoryId = subCategoryList[0].subCategoryId;
    List<ProductListItem> productList = subCategoryList[0].productList;
    return StatefulBuilder(builder: (context, setState) {
      return ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          // Sub-category chips
          if (subCategoryList.length > 1)
            Container(
              height: 44,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: subCategoryList.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final isSelected =
                      subCategoryId == subCategoryList[index].subCategoryId;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        subCategoryId = subCategoryList[index].subCategoryId;
                        productList = subCategoryList[index].productList;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? ScSaasThemeTokens.primary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow:
                            isSelected ? ScSaasThemeTokens.shadowButton : ScSaasThemeTokens.shadowCard,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        subCategoryList[index].subCategoryName,
                        style: aeLabel(
                          color: isSelected ? Colors.white : ScSaasThemeTokens.text,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          // Product list
          if (productList.isNotEmpty)
            ...List.generate(
              productList.length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _productCard(productList[index], storeStatus,
                    deliveryTime, widget.storeName),
              ),
            )
          else
            NoRecordFound(message: languages.noAnyProductsFound),
        ],
      );
    });
  }

  // ── PRODUCT CARD (restyled per design) ──────────────────────────
  Widget _productCard(
      ProductListItem product, bool storeStatus, deliveryTime, storeName) {
    final hasDiscount = _hasDiscount(product);
    final originalAmount = _resolvedOriginalAmount(product);
    final discountPercent = _resolvedDiscountPercent(product);
    final productImage = _resolvedProductImage(product);

    return GestureDetector(
      onTap: () async {
        var response =
            await AddOnRepo().getToppingsAndOptions(product.productId);
        if (!mounted) return;
        if (response['status'] == 1) {
          _openFoodSheet(context, storeStatus, product, response['options_list'],
              response['size_list'], response['color_list']);
        }
      },
      child: Container(
        decoration: AeSurface.card(),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // Product image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                  ),
                  child: LoadImageWithPlaceHolder(
                    image: productImage,
                    defaultAssetImage: 'assets/images/app_iconback.png',
                    width: 100,
                    height: 100,
                    imageFit: BoxFit.cover,
                  ),
                ),
                if (hasDiscount && discountPercent > 0)
                  DiscountStar(discount: discountPercent, scale: 0.7),
              ],
            ),
            const SizedBox(width: 12),
            // Product info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: aeTitle()),
                    if (product.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(product.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: aeCaption()),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            if (hasDiscount)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Text(
                                  '${originalAmount.toStringAsFixed(0)} kr',
                                  style: aeCaption().copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: ScSaasThemeTokens.gray500,
                                  ),
                                ),
                              ),
                            Text(
                              '${_toPrice(product.productAmount).toStringAsFixed(0)} kr',
                              style: aeLabel(),
                            ),
                          ],
                        ),
                        // Add button
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: ScSaasThemeTokens.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  // ── PRODUCT MODAL (logic preserved, visuals restyled) ───────────
  void _showDescriptionModal(BuildContext context, ProductListItem item) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)),
            content: SizedBox(
              width: deviceWidth,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: deviceHeight * 0.75),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.close_rounded,
                                color: ScSaasThemeTokens.text, size: 22),
                          ),
                          const Spacer(),
                          Text(languages.storeProductDetails, style: aeTitle()),
                          const Spacer(),
                          const SizedBox(width: 22),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(item.productName, style: aeH2()),
                      const SizedBox(height: 4),
                      Text(widget.storeName, style: aeCaption()),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (_hasDiscount(item))
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                '${_resolvedOriginalAmount(item).toStringAsFixed(0)} kr',
                                style: aeCaption().copyWith(
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                          Text(
                            '${_toPrice(item.productAmount).toStringAsFixed(0)} kr',
                            style: aeH3(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(color: ScSaasThemeTokens.gray100),
                      const SizedBox(height: 12),
                      Text(item.description, style: aeBody()),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }

  shimmerView(BuildContext context, bool isLoading) => Scaffold(
        backgroundColor: ScSaasThemeTokens.background,
        appBar: AppBar(
          elevation: 0,
          automaticallyImplyLeading: false,
          toolbarHeight: 150,
          backgroundColor: ScSaasThemeTokens.primarySoft,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              color: ScSaasThemeTokens.primaryTint,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(24),
              bottomLeft: Radius.circular(24),
            ),
          ),
        ),
        body: StoreDetailShimmer(enabled: isLoading),
      );

  noRecordView(BuildContext context, String message) => Scaffold(
        backgroundColor: ScSaasThemeTokens.background,
        appBar: AppBar(
          automaticallyImplyLeading: true,
          centerTitle: false,
          titleSpacing: 0,
          elevation: 0,
          title: Text(languages.restaurant.toUpperCase(), style: aeH3()),
        ),
        body: NoRecordFound(
          message: message,
          height: deviceAverageSize * 0.1,
        ),
      );

  void _openFoodSheet(BuildContext context, bool storeStatus,
      ProductListItem product, List optionList, List sizeList, List colorList) {
    final hasDiscount = _hasDiscount(product);
    final originalAmount = _resolvedOriginalAmount(product);
    final fallbackImage = _resolvedProductImage(product);
    final List<String> productImageList = product.productImageList
        .map((e) => (e ?? '').toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (productImageList.isEmpty && fallbackImage.isNotEmpty) {
      productImageList.add(fallbackImage);
    }

    List<Widget> sliderList = productImageList
        .map((item) => ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: LoadImageSimple(
                width: deviceWidth,
                height: deviceHeight * 0.33,
                image: item,
                imageFit: BoxFit.contain,
              ),
            ))
        .toList();
    if (sliderList.isEmpty) {
      sliderList = [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.asset(
            'assets/images/app_iconback.png',
            width: deviceWidth,
            height: deviceHeight * 0.33,
            fit: BoxFit.contain,
          ),
        ),
      ];
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(minWidth: double.infinity),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24), topRight: Radius.circular(24))),
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (BuildContext context, setState) {
          return SizedBox(
            height: deviceHeight * 0.83,
            child: Stack(
              children: [
                // Product images
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: sliderList),
                ),
                // Product details
                Positioned(
                  left: 20,
                  right: 20,
                  top: deviceHeight * 0.35,
                  bottom: 80,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + quantity stepper
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product.productName, style: aeH2()),
                                  const SizedBox(height: 6),
                                  Text(widget.storeName, style: aeCaption()),
                                ],
                              ),
                            ),
                            // Quantity stepper
                            Row(
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
                                  onPressed: () =>
                                      setState(() => prodQuantity++),
                                  icon: const Icon(Icons.add_circle_rounded,
                                      color: ScSaasThemeTokens.primary,
                                      size: 28),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Description
                        LayoutBuilder(builder: (context, constraints) {
                          final textPainter = TextPainter(
                            text: TextSpan(
                                text: product.description,
                                style: aeCaption()),
                            maxLines: 2,
                            textDirection: TextDirection.ltr,
                          )..layout(maxWidth: constraints.maxWidth);
                          final isOverflowing = textPainter.didExceedMaxLines;
                          return RichText(
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: isOverflowing
                                      ? product.description.substring(
                                          0,
                                          textPainter
                                              .getPositionForOffset(Offset(
                                                  constraints.maxWidth - 100,
                                                  textPainter.height))
                                              .offset)
                                      : product.description,
                                  style: aeCaption(),
                                ),
                                if (isOverflowing)
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: GestureDetector(
                                      onTap: () => _showDescriptionModal(
                                          context, product),
                                      child: Text('   ${languages.storeReadMore}',
                                          style: aeLabel(
                                              color:
                                                  ScSaasThemeTokens.primary)),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                        Divider(color: ScSaasThemeTokens.gray100),
                        if (addOnsMessage != '')
                          Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 4),
                            child: Text(addOnsMessage,
                                style: aeCaption(
                                    color: ScSaasThemeTokens.danger)),
                          ),
                        const SizedBox(height: 8),
                        // Add-on widgets (logic untouched)
                        if (getAddOnsType() == typeSizeColor)
                          SizeColorWidget(
                              sizeOptional: product.sizeOptional,
                              colorOptional: product.colorOptional,
                              sizeList: sizeList,
                              colorList: colorList,
                              validate: (value) {
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  setState(() => inStock = value);
                                });
                              })
                        else if (getAddOnsType() == typeToppingOption)
                          ToppingOptionWidget(
                            optionList: optionList,
                            validate: (value) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                setState(() => addOnsMessage = value);
                              });
                            },
                          )
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
                      child: const Icon(Icons.close_rounded,
                          color: ScSaasThemeTokens.text, size: 20),
                    ),
                  ),
                ),
                // Bottom add-to-cart bar
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasDiscount)
                              Text(
                                'NOK ${originalAmount.toStringAsFixed(0)}',
                                style: aeCaption().copyWith(
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            Text(
                              'NOK ${_toPrice(product.productAmount).toStringAsFixed(0)}',
                              style: aeH3(),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 50,
                          width: deviceWidth * 0.5,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ScSaasThemeTokens.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: !inStock || addOnsMessage != ''
                                ? null
                                : () {
                                    if (!storeStatus) {
                                      openSimpleSnackbar(
                                          'This store is not available for now.');
                                    }
                                    bloc.addOrderCart(
                                        product.productId, prodQuantity);
                                    Navigator.pop(context);
                                  },
                            child: Text(languages.storeAddToCart, style: aeTitle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}

/// Delegate for pinning the tab bar.
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);

  @override
  Widget build(context, shrinkOffset, overlapsContent) {
    return Container(
      color: ScSaasThemeTokens.background,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}
