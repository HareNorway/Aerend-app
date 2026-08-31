import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../blocs/bloc.dart';
import '../../theme/sc_saas_theme.dart';
import '../../commonView/common_circular_progress_indicator.dart';
import '../../ui/kit/ae_club_crest.dart';
import 'bloc/campaign_detail_bloc.dart';
import 'campaign_checkout_screen.dart';
import 'campaign_media.dart';
import 'campaign_product_detail_screen.dart';
import 'campaign_strings.dart';
import 'campaign_supplier_content.dart';
import 'models/campaign_detail_pojo.dart';

/// Figma-aligned campaign blue header.
const Color _kCampaignHeaderBlue = Color(0xFF3A6FA8);
const Color _kProfitBannerBg = Color(0xFFE4F5EC);
const Color _kProfitBannerText = Color(0xFF1B6B45);
const Color _kProfitBannerMuted = Color(0xFF3D8A62);

class CampaignDetailScreen extends StatefulWidget {
  final String slug;
  final String? campaignName;

  const CampaignDetailScreen({
    super.key,
    required this.slug,
    this.campaignName,
  });

  @override
  State<CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends State<CampaignDetailScreen> {
  late CampaignDetailBloc _bloc;
  bool _supplierExpanded = false;

  @override
  void initState() {
    super.initState();
    _bloc = CampaignDetailBloc(context, this, widget.slug);
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      return DateFormat('d. MMMM yyyy', 'nb_NO').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF7F8FA),
      body: StreamBuilder<ApiResponse<CampaignDetailPojo>>(
        stream: _bloc.detailStream,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data?.status == Status.loading) {
            return _buildLoading();
          }
          if (snapshot.hasData && snapshot.data?.status == Status.error) {
            return _buildError(snapshot.data?.message ?? '');
          }
          final data = snapshot.data?.data;
          if (data == null) return _buildLoading();

          if (data.isEnded) {
            return _buildEnded(
                CampaignStrings.campaignEnded, CampaignStrings.campaignEndedBody);
          }
          if (data.isUpcoming) {
            return _buildEnded(CampaignStrings.campaignUpcoming,
                CampaignStrings.campaignUpcomingBody);
          }
          if (!data.isLive || data.campaign == null) {
            return _buildError('Campaign unavailable');
          }

          final campaign = data.campaign!;
          return _buildLive(campaign, isDark);
        },
      ),
    );
  }

  Widget _buildLive(CampaignDetail campaign, bool isDark) {
    final logoUrl = (campaign.team?.logoUrl != null &&
            campaign.team!.logoUrl!.isNotEmpty)
        ? campaign.team!.logoUrl
        : (campaign.logoUrl != null && campaign.logoUrl!.isNotEmpty)
            ? campaign.logoUrl
            : campaign.club?.logo;
    final clubName = campaign.club?.name ?? '';

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(campaign, logoUrl, clubName)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (campaign.landingIntroText != null &&
                        campaign.landingIntroText!.isNotEmpty) ...[
                      Text(
                        campaign.landingIntroText!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.85)
                              : const Color(0xFF4A4A5A),
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildProfitBanner(campaign, isDark),
                    const SizedBox(height: 14),
                    _buildDateCardsRow(campaign, isDark),
                    const SizedBox(height: 28),
                    Text(
                      CampaignStrings.chooseYourMatkasse.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.55)
                            : const Color(0xFF8A8A9A),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (campaign.products.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    CampaignStrings.noActiveCampaigns,
                    style: GoogleFonts.plusJakartaSans(
                      color: ScSaasThemeTokens.muted,
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _CampaignProductCard(
                      campaign: campaign,
                      product: campaign.products[index],
                      bloc: _bloc,
                      isDark: isDark,
                      fallbackImageUrl: campaign.heroImageUrl,
                    ),
                    childCount: campaign.products.length,
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  children: [
                    _buildSupplierPanel(isDark),
                    const SizedBox(height: 10),
                    _trustMarker(_clubEarnsLabel(campaign), isDark),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
        _buildStickyCheckoutBar(),
      ],
    );
  }

  Widget _buildHeader(CampaignDetail campaign, String? logoUrl, String clubName) {
    final heroUrl = CampaignMedia.resolveUrl(campaign.heroImageUrl);
    final hasHero = heroUrl != null && heroUrl.isNotEmpty;
    final teamName = campaign.team?.name ?? '';
    final supportName = teamName.isNotEmpty ? teamName : clubName;
    final supportMeta = [
      if (clubName.isNotEmpty) clubName,
      if (teamName.isNotEmpty) teamName,
    ].join(' · ');

    return ClipRect(
      child: Stack(
        children: [
          Positioned.fill(
            child: hasHero
                ? CachedNetworkImage(
                    imageUrl: heroUrl,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 200),
                    placeholder: (_, __) =>
                        const ColoredBox(color: _kCampaignHeaderBlue),
                    errorWidget: (_, __, ___) =>
                        const ColoredBox(color: _kCampaignHeaderBlue),
                  )
                : const ColoredBox(color: _kCampaignHeaderBlue),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: hasHero
                      ? [
                          _kCampaignHeaderBlue.withValues(alpha: 0.52),
                          _kCampaignHeaderBlue.withValues(alpha: 0.78),
                        ]
                      : [
                          _kCampaignHeaderBlue,
                          _kCampaignHeaderBlue,
                        ],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chevron_left,
                          color: _kCampaignHeaderBlue,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AeClubCrest(
                    name:
                        supportName.isNotEmpty ? supportName : campaign.displayHeading,
                    logoUrl: logoUrl,
                    size: 80,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${CampaignStrings.support} ${supportMeta.toUpperCase()}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.85),
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      campaign.displayHeading,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                  ),
                  if (campaign.distributionLocation != null &&
                      campaign.distributionLocation!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        campaign.distributionLocation!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitBanner(CampaignDetail campaign, bool isDark) {
    final subtitle = _clubEarnsLabel(campaign);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? ScSaasThemeTokens.accent.withValues(alpha: 0.14)
            : _kProfitBannerBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? ScSaasThemeTokens.accent.withValues(alpha: 0.25)
              : const Color(0xFFB8E6CE),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark
                  ? ScSaasThemeTokens.accent.withValues(alpha: 0.25)
                  : const Color(0xFF6CC985),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.favorite, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CampaignStrings.allProfitToSupport(
                    campaign.team?.name ?? '',
                  ),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : _kProfitBannerText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.72)
                        : _kProfitBannerMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateCardsRow(CampaignDetail campaign, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _dateCard(
            icon: Icons.schedule,
            label: CampaignStrings.orderBy,
            value: _formatDate(campaign.salesWindowEnd),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _dateCard(
            icon: Icons.local_shipping_outlined,
            label: CampaignStrings.deliveryDay,
            value: _formatDate(campaign.distributionDate),
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _dateCard({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: ScSaasThemeTokens.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: ScSaasThemeTokens.primary),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.6)
                  : const Color(0xFF8A8A9A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : ScSaasThemeTokens.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierPanel(bool isDark) {
    final lang = Localizations.localeOf(context).languageCode;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? ScSaasThemeTokens.accent.withValues(alpha: 0.12)
            : ScSaasThemeTokens.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ScSaasThemeTokens.accent.withValues(alpha: 0.2),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _supplierExpanded = !_supplierExpanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 20, color: ScSaasThemeTokens.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      CampaignStrings.suppliedBy,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : ScSaasThemeTokens.text,
                      ),
                    ),
                  ),
                  Icon(
                    _supplierExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: ScSaasThemeTokens.primary,
                  ),
                ],
              ),
            ),
          ),
          if (_supplierExpanded) ...[
            Divider(
              height: 1,
              color: ScSaasThemeTokens.accent.withValues(alpha: 0.25),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _supplierSection(
                    CampaignSupplierContent.historyTitle(lang),
                    CampaignSupplierContent.historyBody(lang),
                    isDark,
                  ),
                  const SizedBox(height: 14),
                  _supplierSection(
                    CampaignSupplierContent.spekematTitle(lang),
                    CampaignSupplierContent.spekematBody(lang),
                    isDark,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _supplierSection(String title, String body, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : ScSaasThemeTokens.text,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            height: 1.55,
            color: isDark
                ? Colors.white.withValues(alpha: 0.75)
                : const Color(0xFF5A5A6A),
          ),
        ),
      ],
    );
  }

  Widget _trustMarker(String text, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? ScSaasThemeTokens.accent.withValues(alpha: 0.12)
            : ScSaasThemeTokens.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ScSaasThemeTokens.accent.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline,
              size: 20, color: ScSaasThemeTokens.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : ScSaasThemeTokens.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyCheckoutBar() {
    return StreamBuilder<List<CampaignCartItem>>(
      stream: _bloc.cartStream,
      builder: (context, snap) {
        final cart = snap.data ?? [];
        if (cart.isEmpty) return const SizedBox.shrink();
        final total = _bloc.cartTotal;
        final count = _bloc.cartItemCount;
        return Positioned(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CampaignCheckoutScreen(campaign: _bloc),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
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
          ),
        );
      },
    );
  }

  String _clubEarnsLabel(CampaignDetail c) {
    if (c.clubPayoutType == 'percent' &&
        c.clubPayoutValue != null &&
        c.clubPayoutValue! > 0) {
      final v = c.clubPayoutValue!;
      final formatted = v == v.roundToDouble()
          ? v.toInt().toString()
          : v.toStringAsFixed(1).replaceAll('.', ',');
      final supportName = c.team?.name ?? c.club?.name ?? 'klubben';
      return '$formatted% av kjøpet går til $supportName';
    }
    return CampaignStrings.clubEarns;
  }

  Widget _buildLoading() {
    return Scaffold(
      appBar: AppBar(title: Text(widget.campaignName ?? '')),
      body: Center(
        child: CommonCircularProgressIndicator(
          color: ScSaasThemeTokens.primary,
          size: 36,
          strokeWidth: 3,
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: ScSaasThemeTokens.danger),
            const SizedBox(height: 12),
            Text(message,
                style: GoogleFonts.plusJakartaSans(
                    color: ScSaasThemeTokens.muted)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _bloc.refresh(),
              child: Text(CampaignStrings.tryAgain,
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: ScSaasThemeTokens.primary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnded(String title, String body) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today,
                  size: 48, color: ScSaasThemeTokens.primary),
              const SizedBox(height: 16),
              Text(title,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(body,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                      color: ScSaasThemeTokens.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CampaignProductCard extends StatefulWidget {
  final CampaignDetail campaign;
  final CampaignProduct product;
  final CampaignDetailBloc bloc;
  final bool isDark;
  final String? fallbackImageUrl;

  const _CampaignProductCard({
    required this.campaign,
    required this.product,
    required this.bloc,
    required this.isDark,
    this.fallbackImageUrl,
  });

  @override
  State<_CampaignProductCard> createState() => _CampaignProductCardState();
}

class _CampaignProductCardState extends State<_CampaignProductCard> {
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
    final images = _images;
    final hasMultiple = images.length > 1;

    return StreamBuilder<List<CampaignCartItem>>(
      stream: widget.bloc.cartStream,
      builder: (context, snap) {
        final qty = widget.bloc.getQty(widget.product.id);
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: widget.isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: widget.isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageArea(images, hasMultiple),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: widget.isDark
                            ? Colors.white
                            : ScSaasThemeTokens.text,
                      ),
                    ),
                    if (widget.product.contentsDescription != null &&
                        widget.product.contentsDescription!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${CampaignStrings.contains}: ${widget.product.contentsDescription!}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: widget.isDark
                              ? Colors.white.withValues(alpha: 0.72)
                              : const Color(0xFF6B6B7B),
                          height: 1.45,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '${widget.product.price.toInt()} kr',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: ScSaasThemeTokens.primary,
                          ),
                        ),
                        _buildQtyControl(qty),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _openProductDetail,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            CampaignStrings.viewDetails,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: ScSaasThemeTokens.primary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: ScSaasThemeTokens.primary,
                          ),
                        ],
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
  }

  void _openProductDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CampaignProductDetailScreen(
          campaign: widget.campaign,
          product: widget.product,
          bloc: widget.bloc,
          fallbackImageUrl: widget.fallbackImageUrl,
        ),
      ),
    );
  }

  Widget _buildImageArea(List<String> images, bool hasMultiple) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (images.isEmpty)
              Container(
                color: ScSaasThemeTokens.primaryTint,
                child: Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 48,
                    color: ScSaasThemeTokens.primary.withValues(alpha: 0.35),
                  ),
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
                  placeholder: (_, __) => Container(
                    color: ScSaasThemeTokens.primaryTint,
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: ScSaasThemeTokens.primaryTint,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: ScSaasThemeTokens.primary.withValues(alpha: 0.4),
                      size: 40,
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

  Widget _buildQtyControl(int qty) {
    if (qty == 0) {
      return GestureDetector(
        onTap: () => widget.bloc.addToCart(widget.product),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: ScSaasThemeTokens.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, color: Colors.white, size: 18),
              const SizedBox(width: 4),
              Text(
                CampaignStrings.addToCart,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

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
