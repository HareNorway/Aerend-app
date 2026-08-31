import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../commonView/dugnad_club_loader.dart';
import '../../../theme/design_scale.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../club_crest.dart';
import '../dugnad_club_theme.dart';
import '../widgets/dugnad_subpage_shell.dart';
import '../widgets/mk_qty_stepper.dart';
import 'club_shop_cart.dart';
import 'club_shop_cart_screen.dart';
import 'club_shop_models.dart';

class ClubShopProductScreen extends StatefulWidget {
  const ClubShopProductScreen({
    super.key,
    required this.product,
    this.collectionName,
    this.member,
    this.partner,
    this.pointsPerOrder = 75,
  });

  final ClubShopProduct product;
  final String? collectionName;
  final ClubShopMemberInfo? member;
  final ClubShopPartnerInfo? partner;
  final int pointsPerOrder;

  String get collectionLabel {
    final name = collectionName;
    if (name == null || name.isEmpty || name == 'null') return '';
    return name;
  }

  @override
  State<ClubShopProductScreen> createState() => _ClubShopProductScreenState();
}

class _ClubShopProductScreenState extends State<ClubShopProductScreen> {
  static const _lowStockGold = Color(0xFFB4791B);

  String? _size;
  bool _sheetOpen = false;
  final ClubShopCart _cart = ClubShopCart.instance;

  ClubShopProduct get p => widget.product;

  @override
  void initState() {
    super.initState();
    _size = _firstAvailableSize();
    _cart.attachContext(
      member: widget.member,
      partner: widget.partner,
      pointsPerOrder: widget.pointsPerOrder,
    );
    _cart.addListener(_onCart);
  }

  @override
  void dispose() {
    _cart.removeListener(_onCart);
    super.dispose();
  }

  void _onCart() {
    if (!mounted) return;
    final selected = _size;
    if (selected != null && _remaining(selected) <= 0) {
      _size = _firstAvailableSize();
    }
    if (_cart.itemCount == 0) _sheetOpen = false;
    setState(() {});
  }

  String? _firstAvailableSize() {
    for (final s in p.sizes) {
      if (_remaining(s.label) > 0) return s.label;
    }
    return null;
  }

  int _remaining(String size) => _cart.remainingStock(p, size);

  String _stockText(ClubShopSize size) {
    final left = _remaining(size.label);
    if (left <= 0) return languages.dugnadClubShopSoldOut;
    if (left <= 4) return languages.dugnadClubShopLowStock;
    if (left == size.quantity && size.stockLabel.trim().isNotEmpty) {
      return size.stockLabel.trim();
    }
    return languages.dugnadClubShopInStock;
  }

  bool get _allOut {
    if (p.sizes.isEmpty) return p.soldOut;
    return p.sizes.every((s) => _remaining(s.label) <= 0);
  }

  void _addToCart() {
    final size = _size;
    if (size == null || _allOut) return;
    final ok = _cart.add(p, size);
    if (!ok || !mounted) return;
  }

  void _openCart() {
    openScreen(context, const ClubShopCartScreen());
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final url = p.imageUrls.isEmpty
        ? null
        : ClubCrest.resolveClubMediaUrl(p.imageUrls.first);
    final inCart = _cart.qtyFor(productId: p.id);
    final cartQty = _cart.itemCount;
    final canAdd = !_allOut && _size != null;

    final viewBottom = MediaQuery.viewPaddingOf(context).bottom;
    final footerReserve = context.dp(72) +
        viewBottom +
        (cartQty > 0 ? context.dp(70) : 0);

    return Scaffold(
      backgroundColor: theme.background,
      body: Stack(
        children: [
          Column(
            children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.dp(18),
              MediaQuery.paddingOf(context).top + context.dp(8),
              context.dp(18),
              context.dp(8),
            ),
            child: Row(
              children: [
                DugnadLbBackButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: Text(
                    p.category,
                    textAlign: TextAlign.center,
                    style: aeH2(color: theme.text)
                        .copyWith(fontSize: 18, fontWeight: FontWeight.w800)
                        .dp(context),
                  ),
                ),
                SizedBox(width: context.dp(38)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(bottom: footerReserve),
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(context.dp(22)),
                    ),
                    child: ColoredBox(
                      color: theme.primaryTint,
                      child: url == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  size: context.dp(28),
                                  color: theme.primaryHover,
                                ),
                                SizedBox(height: context.dp(6)),
                                Text(
                                  languages.dugnadClubShopProductImage,
                                  style: aeCaption(color: theme.primaryHover)
                                      .copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      )
                                      .dp(context),
                                ),
                              ],
                            )
                          : CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                              progressIndicatorBuilder: (_, __, ___) =>
                                  const DugnadClubImageLoader(size: 44),
                            ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.dp(18),
                    context.dp(16),
                    context.dp(18),
                    context.dp(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: aeH2(color: theme.text)
                            .copyWith(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              height: 1.22,
                            )
                            .dp(context),
                      ),
                      SizedBox(height: context.dp(5)),
                      Text(
                        widget.collectionLabel.isEmpty
                            ? p.category
                            : languages.dugnadClubShopCategoryCollection(
                                p.category,
                                widget.collectionLabel,
                              ),
                        style: aeCaption(color: ScSaasThemeTokens.gray500)
                            .copyWith(fontWeight: FontWeight.w700, fontSize: 12)
                            .dp(context),
                      ),
                      SizedBox(height: context.dp(13)),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: context.dp(10),
                        runSpacing: context.dp(8),
                        children: [
                          Text(
                            shopKr(p.memberPrice),
                            style: aeH2(color: theme.text)
                                .copyWith(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w800,
                                )
                                .dp(context),
                          ),
                          if (p.memberPrice < p.ordinaryPrice)
                            Text(
                              shopKr(p.ordinaryPrice),
                              style: aeBody(color: ScSaasThemeTokens.gray500)
                                  .copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.lineThrough,
                                  )
                                  .dp(context),
                            ),
                          if (p.discountPct > 0)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.dp(10),
                                vertical: context.dp(4),
                              ),
                              decoration: BoxDecoration(
                                color: theme.primaryHover,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                languages.dugnadClubShopMemberDiscount(
                                  p.discountPct,
                                ),
                                style: aeCaption(color: Colors.white)
                                    .copyWith(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                    )
                                    .dp(context),
                              ),
                            ),
                        ],
                      ),
                      if (p.description.trim().isNotEmpty) ...[
                        SizedBox(height: context.dp(14)),
                        Text(
                          p.description,
                          style: aeBody(color: ScSaasThemeTokens.gray600)
                              .copyWith(
                                fontSize: 14,
                                height: 1.6,
                                fontWeight: FontWeight.w500,
                              )
                              .dp(context),
                        ),
                      ],
                      if (p.sizes.isNotEmpty) ...[
                        SizedBox(height: context.dp(20)),
                        Text(
                          languages.dugnadClubShopChooseSize.toUpperCase(),
                          style: aeOverline(color: ScSaasThemeTokens.gray500)
                              .copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 12 * 0.04,
                              )
                              .dp(context),
                        ),
                        SizedBox(height: context.dp(10)),
                        Wrap(
                          spacing: context.dp(10),
                          runSpacing: context.dp(10),
                          children: p.sizes
                              .map((s) => _sizeChip(context, theme, s))
                              .toList(),
                        ),
                      ],
                      if (_allOut) ...[
                        SizedBox(height: context.dp(16)),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: context.dp(16),
                              color: theme.primaryHover,
                            ),
                            SizedBox(width: context.dp(8)),
                            Expanded(
                              child: Text(
                                languages.dugnadClubShopAllSoldOut,
                                style: aeBody(color: ScSaasThemeTokens.gray600)
                                    .copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      height: 1.4,
                                    )
                                    .dp(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (inCart > 0) ...[
                        SizedBox(height: context.dp(16)),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: context.dp(16),
                              color: theme.primaryHover,
                            ),
                            SizedBox(width: context.dp(8)),
                            Expanded(
                              child: Text(
                                languages.dugnadClubShopInCartHint(inCart),
                                style: aeBody(color: ScSaasThemeTokens.gray600)
                                    .copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      height: 1.4,
                                    )
                                    .dp(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              color: Colors.white,
              elevation: 0,
              clipBehavior: Clip.antiAlias,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(context.dp(22)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (cartQty > 0 && _sheetOpen)
                    _miniCartSheet(context, theme),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.dp(16),
                      context.dp(10),
                      context.dp(16),
                      cartQty > 0 ? context.dp(8) : 8 + viewBottom,
                    ),
                child: GestureDetector(
                  onTap: canAdd ? _addToCart : null,
                  child: Opacity(
                    opacity: canAdd ? 1 : 0.45,
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(vertical: context.dp(15)),
                      decoration: BoxDecoration(
                        gradient: canAdd ? theme.shinyGradient : null,
                        color: canAdd ? null : ScSaasThemeTokens.gray300,
                        borderRadius: BorderRadius.circular(context.dp(16)),
                        boxShadow: canAdd ? theme.shadowButton : null,
                      ),
                      child: Text(
                        _allOut
                            ? languages.dugnadClubShopSoldOut
                            : languages.dugnadClubShopAddToCart(
                                shopKr(p.memberPrice),
                              ),
                        style: aeBody(color: Colors.white)
                            .copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            )
                            .dp(context),
                      ),
                    ),
                  ),
                ),
              ),
              if (cartQty > 0)
                ColoredBox(
                  color: Colors.white,
                  child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.dp(14),
                    context.dp(4),
                    context.dp(14),
                    8 + viewBottom,
                  ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _sheetOpen = !_sheetOpen),
                      child: Row(
                        children: [
                          Container(
                            width: context.dp(42),
                            height: context.dp(42),
                            decoration: BoxDecoration(
                              color: theme.primaryTint,
                              borderRadius:
                                  BorderRadius.circular(context.dp(13)),
                              border: Border.all(
                                color: theme.primary.withValues(alpha: 0.16),
                              ),
                            ),
                            child: Icon(
                              Icons.shopping_bag_outlined,
                              size: context.dp(20),
                              color: theme.primaryHover,
                            ),
                          ),
                          SizedBox(width: context.dp(6)),
                          AnimatedRotation(
                            turns: _sheetOpen ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: context.dp(15),
                              color: theme.primaryHover.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: context.dp(12)),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _sheetOpen = !_sheetOpen),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              languages.dugnadClubShopCartCount(cartQty),
                              style:
                                  aeCaption(color: ScSaasThemeTokens.gray500)
                                      .copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11.5,
                                      )
                                      .dp(context),
                            ),
                            SizedBox(height: context.dp(2)),
                            Text(
                              shopKr(_cart.totalMember),
                              style: aeH2(color: theme.text)
                                  .copyWith(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  )
                                  .dp(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _cart.clear,
                      child: Padding(
                        padding: EdgeInsets.only(right: context.dp(8)),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: context.dp(22),
                          color: ScSaasThemeTokens.danger,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _openCart,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.dp(16),
                          vertical: context.dp(13),
                        ),
                        decoration: BoxDecoration(
                          gradient: theme.shinyGradient,
                          borderRadius: BorderRadius.circular(context.dp(13)),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primary.withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: Offset(0, context.dp(6)),
                            ),
                          ],
                        ),
                        child: Text(
                          languages.dugnadClubShopGoToCart,
                          style: aeBody(color: Colors.white)
                              .copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              )
                              .dp(context),
                        ),
                      ),
                    ),
                  ],
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
  }

  Widget _miniCartSheet(BuildContext context, DugnadClubThemePalette theme) {
    return ColoredBox(
      color: Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: context.dp(220)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.dp(16),
                context.dp(12),
                context.dp(16),
                context.dp(8),
              ),
              child: Row(
                children: [
                  Text(
                    languages.campaignCartTitle,
                    style: aeBody(color: theme.text)
                        .copyWith(fontSize: 13, fontWeight: FontWeight.w800)
                        .dp(context),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _cart.clear,
                    child: Text(
                      languages.campaignCartClear,
                      style: aeCaption(color: ScSaasThemeTokens.danger)
                          .copyWith(fontSize: 12, fontWeight: FontWeight.w700)
                          .dp(context),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.fromLTRB(
                  context.dp(16),
                  0,
                  context.dp(16),
                  context.dp(8),
                ),
                itemCount: _cart.lines.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  color: ScSaasThemeTokens.gray100,
                ),
                itemBuilder: (context, index) {
                  final line = _cart.lines[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: context.dp(8)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                line.product.name,
                                style: aeBody(color: theme.text)
                                    .copyWith(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                    )
                                    .dp(context),
                              ),
                              Text(
                                languages.dugnadClubShopSizeLine(line.size),
                                style: aeCaption(
                                  color: ScSaasThemeTokens.gray500,
                                )
                                    .copyWith(fontSize: 11)
                                    .dp(context),
                              ),
                            ],
                          ),
                        ),
                        MkQtyStepper(
                          qty: line.qty,
                          theme: theme,
                          small: true,
                          onDecrement: () => _cart.setQty(
                            line.product,
                            line.size,
                            line.qty - 1,
                          ),
                          onIncrement:
                              _cart.remainingStock(line.product, line.size) > 0
                                  ? () => _cart.setQty(
                                        line.product,
                                        line.size,
                                        line.qty + 1,
                                      )
                                  : () {},
                        ),
                        SizedBox(width: context.dp(6)),
                        GestureDetector(
                          onTap: () =>
                              _cart.removeLine(line.product, line.size),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            size: context.dp(20),
                            color: ScSaasThemeTokens.danger,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sizeChip(
    BuildContext context,
    DugnadClubThemePalette theme,
    ClubShopSize size,
  ) {
    final left = _remaining(size.label);
    final sold = left <= 0;
    final selected = !sold && _size == size.label;
    final low = left > 0 && left <= 4;

    return GestureDetector(
      onTap: sold
          ? null
          : () => setState(() => _size = size.label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, selected ? -1 : 0, 0),
        constraints: BoxConstraints(minWidth: context.dp(60)),
        padding: EdgeInsets.symmetric(
          horizontal: context.dp(13),
          vertical: context.dp(10),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.dp(15)),
          gradient: sold
              ? null
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    selected ? theme.primaryTint : const Color(0xFFFBFBFD),
                  ],
                ),
          color: sold ? ScSaasThemeTokens.gray100 : null,
          boxShadow: sold
              ? [
                  BoxShadow(
                    color: const Color(0x172D1B5B),
                    blurRadius: 2,
                    offset: Offset(0, context.dp(1)),
                  ),
                ]
              : [
                  BoxShadow(
                    color: selected
                        ? theme.primary.withValues(alpha: 0.35)
                        : const Color(0x4D2D1B5B),
                    blurRadius: selected ? 20 : 14,
                    offset: Offset(0, context.dp(selected ? 6 : 4)),
                  ),
                  BoxShadow(
                    color: selected
                        ? theme.primary.withValues(alpha: 0.85)
                        : const Color(0x122D1B5B),
                    blurRadius: 0,
                    spreadRadius: selected ? 2 : 1,
                  ),
                ],
        ),
        child: Column(
          children: [
            Text(
              size.label,
              style: aeBody(
                color: sold
                    ? ScSaasThemeTokens.gray500
                    : selected
                        ? theme.primaryHover
                        : theme.text,
              )
                  .copyWith(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    decoration: sold ? TextDecoration.lineThrough : null,
                  )
                  .dp(context),
            ),
            SizedBox(height: context.dp(2)),
            Text(
              _stockText(size),
              style: aeCaption(
                color: sold
                    ? ScSaasThemeTokens.gray500
                    : low
                        ? _lowStockGold
                        : ScSaasThemeTokens.gray500,
              )
                  .copyWith(fontSize: 10.5, fontWeight: FontWeight.w700)
                  .dp(context),
            ),
          ],
        ),
      ),
    );
  }
}
