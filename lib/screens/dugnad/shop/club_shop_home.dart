import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../commonView/circle_nav_bar.dart';
import '../../../ui/kit/ae_loader.dart';
import '../../../theme/design_scale.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../../common/account/settings_design_kit.dart';
import '../../common/homeMainV1/home_main_v1.dart';
import '../../../ui/kit/ae_club_crest.dart';
import '../dugnad_club_branding.dart';
import '../../../ui/kit/ae_theme.dart';
import '../dugnad_repo.dart';
import '../dugnad_state.dart';
import '../../../ui/kit/ae_subpage_shell.dart';
import 'club_shop_cart.dart';
import 'club_shop_models.dart';
import 'club_shop_orders_screen.dart';
import 'club_shop_product_screen.dart';

/// Unlocked shop browse — `ShopHome` in `dugnad/shop.jsx`.
class ClubShopHome extends StatefulWidget {
  const ClubShopHome({super.key, required this.member});

  final ClubShopMemberInfo member;

  @override
  State<ClubShopHome> createState() => _ClubShopHomeState();
}

class _ClubShopHomeState extends State<ClubShopHome> {
  static const _apiAudiences = ['Herre', 'Dame', 'Barn'];

  final DugnadRepo _repo = DugnadRepo();
  ClubShopCatalog? _catalog;
  bool _loading = true;
  String _audience = _apiAudiences.first;
  String _category = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final catalog = await _repo.clubShopCatalog(
      clubId: DugnadState.instance.clubId,
    );
    if (!mounted) return;
    ClubShopCart.instance.attachContext(
      member: widget.member,
      partner: catalog?.partner,
      pointsPerOrder: catalog?.pointsPerOrder ?? 75,
    );
    setState(() {
      _catalog = catalog;
      _loading = false;
      _category = languages.dugnadClubShopCategoryAll;
    });
  }

  List<String> get _audienceLabels => [
        languages.dugnadClubShopAudienceMen,
        languages.dugnadClubShopAudienceWomen,
        languages.dugnadClubShopAudienceKids,
      ];

  List<ClubShopProduct> get _forAudience {
    final products = _catalog?.products ?? const <ClubShopProduct>[];
    return products.where((p) => p.matchesAudience(_audience)).toList();
  }

  List<String> get _categories {
    final all = languages.dugnadClubShopCategoryAll;
    final cats = <String>[];
    for (final p in _forAudience) {
      if (p.category.isNotEmpty && !cats.contains(p.category)) {
        cats.add(p.category);
      }
    }
    return [all, ...cats];
  }

  List<ClubShopProduct> get _shown {
    final all = languages.dugnadClubShopCategoryAll;
    final active = _categories.contains(_category) ? _category : all;
    if (active == all) return _forAudience;
    return _forAudience.where((p) => p.category == active).toList();
  }

  void _onBack() {
    final home = context.findAncestorStateOfType<HomeMainV1State>();
    if (home != null) {
      home.backOrHome();
      return;
    }
    Navigator.maybePop(context);
  }

  void _openProduct(ClubShopProduct product) {
    openScreen(
      context,
      ClubShopProductScreen(
        product: product,
        collectionName: _catalog?.collection?.name,
        member: widget.member,
        partner: _catalog?.partner,
        pointsPerOrder: _catalog?.pointsPerOrder ?? 75,
      ),
    );
  }

  void _openOrders() {
    openScreen(context, const ClubShopOrdersScreen());
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    if (_loading) {
      return const AeLoaderScreen();
    }

    final catalog = _catalog;
    final collection = catalog?.collection;
    final partner = catalog?.partner;
    final club = DugnadClubBranding.fullName();
    final shown = _shown;
    final cats = _categories;
    final activeCat = cats.contains(_category)
        ? _category
        : languages.dugnadClubShopCategoryAll;

    return ColoredBox(
      color: theme.background,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _ShopHero(
              clubName: club,
              collectionName: collection?.name.isNotEmpty == true
                  ? collection!.name
                  : languages.dugnadClubShopTitle,
              partnerName: partner?.name ?? '',
              heroImageUrl: collection?.heroImageUrl,
              onBack: _onBack,
              onOrders: _openOrders,
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              context.dp(18),
              context.dp(16),
              context.dp(18),
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if ((collection?.blurb ?? '').trim().isNotEmpty)
                    Text(
                      collection!.blurb,
                      textAlign: TextAlign.center,
                      style: aeBody(color: ScSaasThemeTokens.gray500)
                          .copyWith(
                            fontSize: 13.5,
                            height: 1.55,
                            fontWeight: FontWeight.w600,
                          )
                          .dp(context),
                    ),
                  if ((collection?.blurb ?? '').trim().isNotEmpty)
                    SizedBox(height: context.dp(16)),
                  _VerifiedBanner(member: widget.member),
                  SizedBox(height: context.dp(16)),
                  _AudienceSegment(
                    labels: _audienceLabels,
                    apiKeys: _apiAudiences,
                    selected: _audience,
                    onSelect: (key) => setState(() {
                      _audience = key;
                      _category = languages.dugnadClubShopCategoryAll;
                    }),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.fromLTRB(
                context.dp(18),
                context.dp(12),
                context.dp(18),
                0,
              ),
              child: Row(
                children: [
                  for (var i = 0; i < cats.length; i++) ...[
                    if (i > 0) SizedBox(width: context.dp(9)),
                    _CatPill(
                      label: cats[i],
                      selected: cats[i] == activeCat,
                      onTap: () => setState(() => _category = cats[i]),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              context.dp(18),
              context.dp(16),
              context.dp(18),
              aePillNavReservedHeight(context) + context.dp(16),
            ),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final gap = context.dp(11);
                final cardW = (constraints.crossAxisExtent - gap) / 2;
                final imgH = cardW * 4 / 5;
                final textH = context.dp(108);
                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: gap,
                    mainAxisSpacing: gap,
                    mainAxisExtent: imgH + textH,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => ClubShopProductCard(
                      product: shown[i],
                      onTap: () => _openProduct(shown[i]),
                    ),
                    childCount: shown.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopHero extends StatelessWidget {
  const _ShopHero({
    required this.clubName,
    required this.collectionName,
    required this.partnerName,
    required this.heroImageUrl,
    required this.onBack,
    required this.onOrders,
  });

  final String clubName;
  final String collectionName;
  final String partnerName;
  final String? heroImageUrl;
  final VoidCallback onBack;
  final VoidCallback onOrders;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final logo = DugnadState.instance.clubLogo;
    final top = MediaQuery.paddingOf(context).top;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(context.dp(24))),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: const Alignment(-0.4, -0.9),
                  end: const Alignment(0.5, 1),
                  colors: [theme.primary, theme.primaryHover],
                ),
              ),
            ),
          ),
          if (heroImageUrl != null && heroImageUrl!.isNotEmpty)
            Positioned.fill(
              child: Opacity(
                opacity: 0.9,
                child: CachedNetworkImage(
                  imageUrl: AeClubCrest.resolveClubMediaUrl(heroImageUrl) ??
                      heroImageUrl!,
                  fit: BoxFit.cover,
                  progressIndicatorBuilder: (_, __, ___) =>
                      const AeImageLoader(),
                ),
              ),
            ),
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0x9E140C28),
                      Color(0x42140C28),
                      Color(0x6B140C28),
                    ],
                    stops: [0, 0.55, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Center(
              child: Text(
                clubName.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: context.dp(34),
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.dp(18),
              top + context.dp(8),
              context.dp(18),
              context.dp(26),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    AeBackButton(onPressed: onBack),
                    const Spacer(),
                    AeBackButton(
                      onPressed: onOrders,
                      iconWidget: SvgPicture.asset(
                        'assets/svgs/order_history.svg',
                        width: context.dp(20),
                        height: context.dp(20),
                        fit: BoxFit.contain,
                        colorFilter: ColorFilter.mode(
                          theme.text,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.dp(18)),
                AeClubCrest(
                  name: clubName,
                  logoUrl: logo.isEmpty ? null : logo,
                  size: context.dp(70),
                  backgroundColor: logo.isEmpty ? null : Colors.white,
                ),
                SizedBox(height: context.dp(10)),
                Text(
                  languages.dugnadClubShopTitle.toUpperCase(),
                  style: aeOverline(color: Colors.white.withValues(alpha: 0.92))
                      .copyWith(
                        fontSize: 10.5,
                        letterSpacing: 10.5 * 0.05,
                        fontWeight: FontWeight.w800,
                      )
                      .dp(context),
                ),
                SizedBox(height: context.dp(4)),
                Text(
                  collectionName,
                  textAlign: TextAlign.center,
                  style: aeH2(color: Colors.white)
                      .copyWith(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 21 * -0.02,
                      )
                      .dp(context),
                ),
                if (partnerName.isNotEmpty) ...[
                  SizedBox(height: context.dp(12)),
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      context.dp(13),
                      context.dp(7),
                      context.dp(13),
                      context.dp(7),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x3D140C28),
                          blurRadius: context.dp(4),
                          offset: Offset(0, context.dp(2)),
                        ),
                        BoxShadow(
                          color: const Color(0x73140C28),
                          blurRadius: context.dp(20),
                          offset: Offset(0, context.dp(10)),
                          spreadRadius: context.dp(-8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.storefront_outlined,
                          size: context.dp(13),
                          color: theme.text,
                        ),
                        SizedBox(width: context.dp(6)),
                        Flexible(
                          child: Text(
                            languages.dugnadClubShopWithPartner(partnerName),
                            style: aeCaption(color: theme.text)
                                .copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                )
                                .dp(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifiedBanner extends StatelessWidget {
  const _VerifiedBanner({required this.member});

  final ClubShopMemberInfo member;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.dp(13),
        context.dp(10),
        context.dp(13),
        context.dp(10),
      ),
      decoration: BoxDecoration(
        color: const Color(0x1A22A769),
        border: Border.all(color: const Color(0x3322A769)),
        borderRadius: BorderRadius.circular(context.dp(14)),
      ),
      child: Row(
        children: [
          Container(
            width: context.dp(28),
            height: context.dp(28),
            decoration: BoxDecoration(
              color: ScSaasThemeTokens.success,
              borderRadius: BorderRadius.circular(context.dp(9)),
            ),
            child: Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: context.dp(15),
            ),
          ),
          SizedBox(width: context.dp(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  languages.dugnadClubShopVerifiedLine(member.number),
                  style: aeBody(color: const Color(0xFF14663F))
                      .copyWith(fontWeight: FontWeight.w800, fontSize: 13)
                      .dp(context),
                ),
                SizedBox(height: context.dp(1)),
                Text(
                  languages.dugnadClubShopVerifiedSub,
                  style: aeCaption(color: const Color(0xB814663F))
                      .copyWith(fontWeight: FontWeight.w700, fontSize: 11.5)
                      .dp(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AudienceSegment extends StatelessWidget {
  const _AudienceSegment({
    required this.labels,
    required this.apiKeys,
    required this.selected,
    required this.onSelect,
  });

  final List<String> labels;
  final List<String> apiKeys;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    // CSS `.sh-aud` is `rgba(45,27,91,.055)` over the mint page. Keep that
    // mix opaque so the selected pill's drop shadow cannot show through.
    final track = Color.alphaBlend(
      const Color(0x0E2D1B5B),
      theme.background,
    );
    return Container(
      padding: EdgeInsets.all(context.dp(3)),
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(context.dp(14)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < apiKeys.length; i++)
            Expanded(
              child: _AudienceTab(
                label: labels[i],
                selected: selected == apiKeys[i],
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelect(apiKeys[i]);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _AudienceTab extends StatelessWidget {
  const _AudienceTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final radius = BorderRadius.circular(context.dp(11));
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          // Snap opaque white with the shadow — never animate the fill, or
          // the drop shadow shows through while opacity is between 0 and 1.
          color: selected ? const Color(0xFFFFFFFF) : Colors.transparent,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: theme.text.withValues(alpha: 0.16),
                    blurRadius: context.dp(2),
                    offset: Offset(0, context.dp(1)),
                  ),
                  BoxShadow(
                    color: theme.text.withValues(alpha: 0.3),
                    blurRadius: context.dp(10),
                    offset: Offset(0, context.dp(4)),
                    spreadRadius: context.dp(-4),
                  ),
                ]
              : const [],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: context.dp(9)),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: dgText(
                13.5,
                FontWeight.w800,
                height: 1.2,
                color: selected
                    ? theme.primaryHover
                    : ScSaasThemeTokens.gray500,
              ).copyWith(letterSpacing: 13.5 * -0.01),
            ),
          ),
        ),
      ),
    );
  }
}

class _CatPill extends StatelessWidget {
  const _CatPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: const Color(0xFFFFFFFF),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: theme.primary.withValues(alpha: 0.7),
                    blurRadius: context.dp(20),
                    offset: Offset(0, context.dp(10)),
                    spreadRadius: context.dp(-12),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x0A2D1B5B),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  opacity: selected ? 1 : 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: theme.shinyGradient),
                  ),
                ),
              ),
              if (!selected)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: ScSaasThemeTokens.gray100,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.dp(16),
                  vertical: context.dp(9),
                ),
                child: Text(
                  label,
                  style: dgText(
                    12.5,
                    FontWeight.w800,
                    height: 1.2,
                    color: selected
                        ? Colors.white
                        : ScSaasThemeTokens.gray500,
                  ).copyWith(letterSpacing: 12.5 * -0.01),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClubShopProductCard extends StatefulWidget {
  const ClubShopProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  final ClubShopProduct product;
  final VoidCallback onTap;

  @override
  State<ClubShopProductCard> createState() => _ClubShopProductCardState();
}

class _ClubShopProductCardState extends State<ClubShopProductCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final p = widget.product;
    final url = p.imageUrls.isEmpty
        ? null
        : AeClubCrest.resolveClubMediaUrl(p.imageUrls.first);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: const Duration(milliseconds: 140),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.dp(18)),
            boxShadow: [
              BoxShadow(
                color: theme.text.withValues(alpha: 0.05),
                blurRadius: 0,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: theme.text.withValues(alpha: 0.10),
                blurRadius: context.dp(2),
                offset: Offset(0, context.dp(1)),
              ),
              BoxShadow(
                color: theme.text.withValues(alpha: 0.42),
                blurRadius: context.dp(28),
                offset: Offset(0, context.dp(14)),
                spreadRadius: context.dp(-12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 5 / 4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: theme.primaryTint),
                    if (url != null)
                      CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        progressIndicatorBuilder: (_, __, ___) =>
                            const AeImageLoader(),
                      )
                    else
                      _ImagePlaceholder(),
                    if (p.discountPct > 0 && !p.soldOut)
                      Positioned(
                        top: context.dp(9),
                        left: context.dp(9),
                        child: Container(
                          padding: EdgeInsets.fromLTRB(
                            context.dp(9),
                            context.dp(4),
                            context.dp(9),
                            context.dp(4),
                          ),
                          decoration: BoxDecoration(
                            color: theme.primaryHover,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '−${p.discountPct} %',
                            style: aeCaption(color: Colors.white)
                                .copyWith(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                )
                                .dp(context),
                          ),
                        ),
                      ),
                    if (p.soldOut)
                      ColoredBox(
                        color: Colors.white.withValues(alpha: 0.72),
                        child: Center(
                          child: Text(
                            languages.dugnadClubShopSoldOut,
                            style: aeCaption(color: ScSaasThemeTokens.gray500)
                                .copyWith(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                )
                                .dp(context),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.dp(11),
                    context.dp(9),
                    context.dp(11),
                    context.dp(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: context.dp(13) * 2.56,
                        child: Text(
                          p.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: aeBody(color: theme.text)
                              .copyWith(
                                fontSize: 13,
                                height: 1.28,
                                fontWeight: FontWeight.w800,
                              )
                              .dp(context),
                        ),
                      ),
                      Text(
                        p.category,
                        style: aeCaption(color: ScSaasThemeTokens.gray500)
                            .copyWith(fontSize: 11, fontWeight: FontWeight.w700)
                            .dp(context),
                      ),
                      const Spacer(),
                      const Divider(height: 1, color: ScSaasThemeTokens.gray100),
                      SizedBox(height: context.dp(8)),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Flexible(
                                  child: Text(
                                    shopKr(p.memberPrice),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: aeBody(color: theme.text)
                                        .copyWith(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w800,
                                        )
                                        .dp(context),
                                  ),
                                ),
                                if (p.memberPrice < p.ordinaryPrice) ...[
                                  SizedBox(width: context.dp(5)),
                                  Text(
                                    p.ordinaryPrice.toString(),
                                    style: aeCaption(
                                      color: ScSaasThemeTokens.gray500,
                                    )
                                        .copyWith(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          decoration: TextDecoration.lineThrough,
                                        )
                                        .dp(context),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.fromLTRB(
                              context.dp(9),
                              context.dp(4),
                              context.dp(7),
                              context.dp(4),
                            ),
                            decoration: BoxDecoration(
                              color: _pressed
                                  ? theme.primary
                                  : theme.primaryTint,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  languages.dugnadClubShopSeeMore,
                                  style: aeCaption(
                                    color: _pressed
                                        ? Colors.white
                                        : theme.primaryHover,
                                  )
                                      .copyWith(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                      )
                                      .dp(context),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: context.dp(13),
                                  color: _pressed
                                      ? Colors.white
                                      : theme.primaryHover,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashPainter(color: context.aeTheme.primary.withValues(alpha: 0.28)),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_outlined,
              size: context.dp(22),
              color: context.aeTheme.primaryHover.withValues(alpha: 0.55),
            ),
            SizedBox(height: context.dp(4)),
            Text(
              languages.dugnadClubShopProductImage,
              style: aeCaption(color: ScSaasThemeTokens.gray500)
                  .copyWith(fontSize: 11, fontWeight: FontWeight.w700)
                  .dp(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    const dash = 5.0;
    const gap = 4.0;
    final rect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashPainter oldDelegate) =>
      oldDelegate.color != color;
}
