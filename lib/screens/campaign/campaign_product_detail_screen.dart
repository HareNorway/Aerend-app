import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/sc_saas_theme.dart';
import 'bloc/campaign_detail_bloc.dart';
import 'campaign_checkout_screen.dart';
import 'campaign_media.dart';
import 'campaign_product_utils.dart';
import 'campaign_strings.dart';
import 'models/campaign_detail_pojo.dart';

/// Figma product detail — full description, contents, and add-to-cart bar.
class CampaignProductDetailScreen extends StatefulWidget {
  final CampaignDetail campaign;
  final CampaignProduct product;
  final CampaignDetailBloc bloc;
  final String? fallbackImageUrl;

  const CampaignProductDetailScreen({
    super.key,
    required this.campaign,
    required this.product,
    required this.bloc,
    this.fallbackImageUrl,
  });

  @override
  State<CampaignProductDetailScreen> createState() =>
      _CampaignProductDetailScreenState();
}

class _CampaignProductDetailScreenState
    extends State<CampaignProductDetailScreen> {
  late final PageController _pageController;
  int _imageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> get _images {
    final productImages = widget.product.displayImages;
    if (productImages.isNotEmpty) return productImages;
    final fallback = CampaignMedia.resolveUrl(widget.fallbackImageUrl);
    if (fallback != null && fallback.isNotEmpty) return [fallback];
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final images = _images;
    final hasMultiple = images.length > 1;
    final audience = CampaignProductUtils.audienceLabel(
      clubName: widget.campaign.club?.name,
      distributionLocation: widget.campaign.distributionLocation,
    );
    final contents = CampaignProductUtils.parseContents(
      widget.product.contentsDescription,
    );

    return Scaffold(
      backgroundColor:
          isDark ? Theme.of(context).scaffoldBackgroundColor : ScSaasThemeTokens.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.maybePop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: isDark
                                ? null
                                : [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 8,
                                    ),
                                  ],
                          ),
                          child: Icon(
                            Icons.chevron_left,
                            color: ScSaasThemeTokens.primary,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _buildImageCarousel(images, hasMultiple, isDark),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (audience.isNotEmpty) ...[
                        Text(
                          audience,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: ScSaasThemeTokens.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        widget.product.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : ScSaasThemeTokens.text,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.product.price.toInt()} kr',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: ScSaasThemeTokens.primary,
                        ),
                      ),
                      if (widget.product.description != null &&
                          widget.product.description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _sectionHeading(
                          CampaignStrings.descriptionHeading,
                          isDark,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.product.description!.trim(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            height: 1.6,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.82)
                                : const Color(0xFF4A4A5A),
                          ),
                        ),
                      ],
                      if (contents.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _sectionHeading(
                          CampaignStrings.contentsHeading,
                          isDark,
                        ),
                        const SizedBox(height: 8),
                        ...contents.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.7)
                                          : const Color(0xFF4A4A5A),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      height: 1.5,
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.82)
                                          : const Color(0xFF4A4A5A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      _supplierBadge(isDark),
                    ],
                  ),
                ),
              ),
            ],
          ),
          _buildBottomBars(isDark),
        ],
      ),
    );
  }

  Widget _sectionHeading(String text, bool isDark) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: isDark
            ? Colors.white.withValues(alpha: 0.55)
            : const Color(0xFF8A8A9A),
      ),
    );
  }

  Widget _supplierBadge(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? ScSaasThemeTokens.accent.withValues(alpha: 0.14)
            : const Color(0xFFE4F5EC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ScSaasThemeTokens.accent.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: ScSaasThemeTokens.accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              size: 16,
              color: ScSaasThemeTokens.accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              CampaignStrings.suppliedBy,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : ScSaasThemeTokens.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel(
    List<String> images,
    bool hasMultiple,
    bool isDark,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 240,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (images.isEmpty)
              ColoredBox(
                color: ScSaasThemeTokens.primaryTint,
                child: Icon(
                  Icons.image_outlined,
                  size: 48,
                  color: ScSaasThemeTokens.primary.withValues(alpha: 0.35),
                ),
              )
            else
              PageView.builder(
                controller: _pageController,
                itemCount: images.length,
                onPageChanged: (i) => setState(() => _imageIndex = i),
                itemBuilder: (_, i) => CachedNetworkImage(
                  imageUrl: images[i],
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 200),
                  placeholder: (_, __) =>
                      ColoredBox(color: ScSaasThemeTokens.primaryTint),
                  errorWidget: (_, __, ___) => ColoredBox(
                    color: ScSaasThemeTokens.primaryTint,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: ScSaasThemeTokens.primary.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            if (hasMultiple) ...[
              Positioned(
                left: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _carouselArrow(
                    Icons.chevron_left,
                    () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOut,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _carouselArrow(
                    Icons.chevron_right,
                    () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOut,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(images.length, (i) {
                    final active = i == _imageIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _carouselArrow(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: ScSaasThemeTokens.primary, size: 22),
      ),
    );
  }

  Widget _buildBottomBars(bool isDark) {
    return StreamBuilder<List<CampaignCartItem>>(
      stream: widget.bloc.cartStream,
      builder: (context, snap) {
        final cart = snap.data ?? [];
        final qty = widget.bloc.getQty(widget.product.id);
        return Positioned(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionBarContent(isDark, qty),
              if (cart.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildCheckoutBarContent(context),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCheckoutBarContent(BuildContext context) {
    final total = widget.bloc.cartTotal;
    final count = widget.bloc.cartItemCount;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CampaignCheckoutScreen(campaign: widget.bloc),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: ScSaasThemeTokens.primary,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: ScSaasThemeTokens.primary.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$count × ${CampaignStrings.chooseBox.toLowerCase()}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    '${total.toInt()} kr',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                CampaignStrings.goToCheckout,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: ScSaasThemeTokens.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBarContent(bool isDark, int qty) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2540) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  CampaignStrings.pricePerBox,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : const Color(0xFF8A8A9A),
                  ),
                ),
                Text(
                  '${widget.product.price.toInt()} kr',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : ScSaasThemeTokens.text,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (qty == 0)
            _addToCartButton(
              onTap: () => widget.bloc.addToCart(widget.product),
            )
          else
            _qtyStepper(qty),
        ],
      ),
    );
  }

  Widget _addToCartButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              ScSaasThemeTokens.primary,
              ScSaasThemeTokens.primaryHover,
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: ScSaasThemeTokens.shadowButton,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Text(
              CampaignStrings.addToCart,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyStepper(int qty) {
    return Container(
      decoration: BoxDecoration(
        color: ScSaasThemeTokens.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => widget.bloc.decrementQty(widget.product.id),
            icon: const Icon(Icons.remove, size: 20),
            color: ScSaasThemeTokens.primary,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          Text(
            '$qty',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: ScSaasThemeTokens.primary,
            ),
          ),
          IconButton(
            onPressed: () => widget.bloc.incrementQty(widget.product.id),
            icon: const Icon(Icons.add, size: 20),
            color: ScSaasThemeTokens.primary,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ],
      ),
    );
  }
}
