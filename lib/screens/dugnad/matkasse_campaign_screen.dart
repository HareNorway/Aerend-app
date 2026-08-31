import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../blocs/bloc.dart';
import '../../theme/design_scale.dart';
import '../../commonView/common_circular_progress_indicator.dart';
import '../../theme/ae_typography.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/utils.dart';
import '../campaign/bloc/campaign_detail_bloc.dart';
import '../campaign/campaign_media.dart';
import 'matkasse_product_screen.dart';
import '../campaign/campaign_strings.dart';
import '../campaign/models/campaign_detail_pojo.dart';
import '../../ui/kit/ae_club_crest.dart';
import 'dugnad_club_branding.dart';
import '../../ui/kit/ae_theme.dart';
import 'dugnad_points_widgets.dart';
import '../../services/dugnad_data_cache.dart';
import 'widgets/campaign_countdown.dart';
import '../../ui/kit/ae_subpage_shell.dart';
import 'widgets/mk_cart_bar.dart';
import '../../ui/kit/ae_rise_in.dart';

// Aliases the token rather than repeating its hex. A shared constant is
// verified once or not at all: when every site holds the same wrong value
// they stay consistent with each other and diverge only from the source.
const _kSuccessGreen = ScSaasThemeTokens.success;

/// Dugnad campaign detail — mirrors prototype `MatkasseCampaign`.
class MatkasseCampaignScreen extends StatefulWidget {
  const MatkasseCampaignScreen({
    super.key,
    required this.slug,
    this.campaignName,
  });

  final String slug;
  final String? campaignName;

  @override
  State<MatkasseCampaignScreen> createState() => _MatkasseCampaignScreenState();
}

class _MatkasseCampaignScreenState extends State<MatkasseCampaignScreen> {
  late CampaignDetailBloc _bloc;

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

  String _formatDate(String? iso, {bool short = false}) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final locale = Localizations.localeOf(context).languageCode;
      final pattern = short
          ? (locale == 'no' ? 'd. MMMM' : 'd MMMM')
          : (locale == 'no' ? 'd. MMMM yyyy' : 'd MMMM yyyy');
      return DateFormat(pattern, locale == 'no' ? 'nb_NO' : 'en_US')
          .format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  String _greenBannerTitle() => languages.dugnadCampaignSupportBuyTitle;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;

    return Scaffold(
      backgroundColor: theme.background,
      body: StreamBuilder<ApiResponse<CampaignDetailPojo>>(
        stream: _bloc.detailStream,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data?.status == Status.loading) {
            return _buildLoading(theme);
          }
          if (snapshot.hasData && snapshot.data?.status == Status.error) {
            return _buildError(theme, snapshot.data?.message ?? '');
          }

          final data = snapshot.data?.data;
          if (data == null) return _buildLoading(theme);

          if (data.isEnded) {
            return _buildMessage(
              theme,
              CampaignStrings.campaignEnded,
              CampaignStrings.campaignEndedBody,
            );
          }
          if (data.isUpcoming) {
            return _buildMessage(
              theme,
              CampaignStrings.campaignUpcoming,
              CampaignStrings.campaignUpcomingBody,
            );
          }
          if (!data.isLive || data.campaign == null) {
            return _buildError(theme, 'Campaign unavailable');
          }

          return _buildLive(data.campaign!, theme);
        },
      ),
    );
  }

  Widget _buildLive(CampaignDetail campaign, AeThemePalette theme) {
    final clubName = campaign.club?.name ?? DugnadClubBranding.fullName();
    final teamName = campaign.team?.name ?? '';
    final logoUrl = (campaign.team?.logoUrl?.isNotEmpty ?? false)
        ? campaign.team!.logoUrl
        : (campaign.logoUrl?.isNotEmpty ?? false)
            ? campaign.logoUrl
            : campaign.club?.logo;
    final showProgress = (campaign.fundraisingGoalNok ?? 0) > 0;
    final goalPct = (campaign.goalPercent ?? 0).clamp(0, 100);
    final raised = formatNok(campaign.totalRevenueNok).split(' ').first;

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _MkCampHero(
                campaign: campaign,
                clubName: clubName,
                teamName: teamName,
                logoUrl: logoUrl,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(context.dp(18), context.dp(16), context.dp(18), context.dp(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (campaign.landingIntroText?.trim().isNotEmpty ?? false)
                      _riseIn(
                        0,
                        Text(
                          campaign.landingIntroText!.trim(),
                          textAlign: TextAlign.center,
                          style:
                              aeBody(color: ScSaasThemeTokens.gray600).copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: context.dp(1.5),
                          ),
                        ),
                      ),
                    SizedBox(height: context.dp(13)),
                    _riseIn(
                      1,
                      _DgGreenBanner(
                        title: _greenBannerTitle(),
                        subtitle: showProgress
                            ? '${languages.dugnadCampaignRaised(raised)} · ${languages.dugnadTeamDetailGoalPercent(goalPct)}'
                            : CampaignStrings.clubEarns,
                      ),
                    ),
                    if (campaign.salesWindowEnd?.isNotEmpty ?? false) ...[
                      SizedBox(height: context.dp(13)),
                      _riseIn(
                        2,
                        CampaignCountdownPanel(
                          salesWindowEnd: campaign.salesWindowEnd!,
                        ),
                      ),
                    ],
                    SizedBox(height: context.dp(9)),
                    _riseIn(
                      3,
                      Row(
                        children: [
                          Expanded(
                            child: _SessionCard(
                              icon: Icons.schedule_outlined,
                              label: CampaignStrings.orderBy,
                              value: _formatDate(
                                campaign.salesWindowEnd,
                                short: true,
                              ),
                            ),
                          ),
                          SizedBox(width: context.dp(9)),
                          Expanded(
                            child: _SessionCard(
                              icon: Icons.local_shipping_outlined,
                              label: CampaignStrings.deliveryDay,
                              value: _formatDate(campaign.distributionDate),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(context.dp(18), context.dp(8), context.dp(18), context.dp(12)),
                child: _riseIn(
                  4,
                  Text(
                    CampaignStrings.chooseYourMatkasse.toUpperCase(),
                    style:
                        aeOverline(color: ScSaasThemeTokens.gray500).copyWith(
                      letterSpacing: 11 * 0.08,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
            if (campaign.products.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.dp(18)),
                  child: Text(
                    CampaignStrings.noActiveCampaigns,
                    style: aeBody(color: ScSaasThemeTokens.gray500),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(context.dp(18), context.dp(0), context.dp(18), context.dp(120)),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: EdgeInsets.only(
                        bottom: index < campaign.products.length - 1 ? 14 : 0,
                      ),
                      child: _MkProductCard(
                        campaign: campaign,
                        product: campaign.products[index],
                        bloc: _bloc,
                        fallbackImageUrl: campaign.heroImageUrl,
                      ),
                    ),
                    childCount: campaign.products.length,
                  ),
                ),
              ),
          ],
        ),
        MkCartBar(bloc: _bloc),
      ],
    );
  }

  Widget _buildLoading(AeThemePalette theme) {
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        elevation: 0,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: AeBackButton(
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
      ),
      body: Center(
        child: CommonCircularProgressIndicator(
          color: theme.primary,
          size: context.dp(36),
          strokeWidth: 3,
        ),
      ),
    );
  }

  Widget _buildError(AeThemePalette theme, String message) {
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        elevation: 0,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: AeBackButton(
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(context.dp(32)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: context.dp(48), color: theme.primary),
              SizedBox(height: context.dp(12)),
              Text(message, style: aeBody(color: ScSaasThemeTokens.gray500)),
              SizedBox(height: context.dp(16)),
              TextButton(
                onPressed: _bloc.refresh,
                child: Text(
                  CampaignStrings.tryAgain,
                  style: aeLabel(color: theme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(AeThemePalette theme, String title, String body) {
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        elevation: 0,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: AeBackButton(
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(context.dp(32)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _riseIn(
                0,
                Icon(Icons.calendar_today, size: context.dp(48), color: theme.primary),
              ),
              SizedBox(height: context.dp(16)),
              _riseIn(1, Text(title, style: aeH2(color: theme.text))),
              SizedBox(height: context.dp(8)),
              _riseIn(
                2,
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: aeBody(color: ScSaasThemeTokens.gray500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MkCampHero extends StatelessWidget {
  const _MkCampHero({
    required this.campaign,
    required this.clubName,
    required this.teamName,
    required this.logoUrl,
  });

  final CampaignDetail campaign;
  final String clubName;
  final String teamName;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: theme.bannerGradient,
        // Prototype `.mk-chero`: rounded bottom corners (0 0 24 24).
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(context.dp(24))),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: Text(
                  clubName.toUpperCase(),
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withValues(alpha: 0.10),
                    letterSpacing: 38 * -0.02,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(context.dp(16), context.dp(8), context.dp(16), context.dp(20)),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AeBackButton(
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  ),
                  SizedBox(height: context.dp(22)),
                  AeClubCrest(
                    name: clubName,
                    logoUrl: logoUrl,
                    size: context.dp(70),
                    backgroundColor: Colors.white,
                  ),
                  SizedBox(height: context.dp(10)),
                  Text(
                    '${CampaignStrings.support} ${clubName.toUpperCase()}',
                    style: aeOverline(color: Colors.white.withValues(alpha: 0.92))
                        .copyWith(
                      fontSize: 10.5,
                      letterSpacing: 10.5 * 0.05,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: context.dp(4)),
                  Text(
                    campaign.displayHeading,
                    textAlign: TextAlign.center,
                    style: aeH2(color: Colors.white).copyWith(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 21 * -0.02,
                    ),
                  ),
                  if (teamName.isNotEmpty) ...[
                    SizedBox(height: context.dp(10)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: context.dp(10),
                            offset: const Offset(0, 3),
                            spreadRadius: -3,
                          ),
                        ],
                      ),
                      child: Text(
                        teamName,
                        style: aeLabel(color: theme.text).copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DgGreenBanner extends StatelessWidget {
  const _DgGreenBanner({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.dp(13), vertical: context.dp(11)),
      decoration: BoxDecoration(
        color: _kSuccessGreen.withValues(alpha: 0.10),
        // Prototype `.dg-green-banner`: radius 16, 1px border.
        borderRadius: BorderRadius.circular(context.dp(16)),
        border: Border.all(color: _kSuccessGreen.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: context.dp(38),
            height: context.dp(38),
            decoration: BoxDecoration(
              color: _kSuccessGreen.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(context.dp(11)),
            ),
            child: Icon(Icons.favorite_rounded, color: _kSuccessGreen, size: context.dp(18)),
          ),
          SizedBox(width: context.dp(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: aeLabel(color: theme.text).copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 13.5 * -0.01,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: context.dp(2)),
                Text(
                  subtitle,
                  style: aeCaption(color: _kSuccessGreen).copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    return Container(
      padding: EdgeInsets.all(context.dp(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.dp(14)),
        boxShadow: [
          // Prototype `.dg-session`: 0 1px 2px rgba(45,27,91,.05).
          BoxShadow(
            color: theme.text.withValues(alpha: 0.05),
            blurRadius: context.dp(2),
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: context.dp(32),
            height: context.dp(32),
            decoration: BoxDecoration(
              color: theme.primaryTint,
              borderRadius: BorderRadius.circular(context.dp(9)),
            ),
            child: Icon(icon, size: context.dp(16), color: theme.primaryHover),
          ),
          SizedBox(width: context.dp(11)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: aeCaption(color: ScSaasThemeTokens.gray700).copyWith(
                    fontSize: context.dp(13),
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: context.dp(2)),
                Text(
                  value,
                  style: aeLabel(color: ScSaasThemeTokens.ink).copyWith(
                    fontSize: context.dp(15),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.01 * context.dp(15),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MkProductCard extends StatefulWidget {
  const _MkProductCard({
    required this.campaign,
    required this.product,
    required this.bloc,
    this.fallbackImageUrl,
  });

  final CampaignDetail campaign;
  final CampaignProduct product;
  final CampaignDetailBloc bloc;
  final String? fallbackImageUrl;

  @override
  State<_MkProductCard> createState() => _MkProductCardState();
}

class _MkProductCardState extends State<_MkProductCard> {
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
    final theme = context.aeTheme;
    final images = _images;
    final hasMultiple = images.length > 1;

    return StreamBuilder<List<CampaignCartItem>>(
      stream: widget.bloc.cartStream,
      builder: (context, snap) {
        final qty = widget.bloc.getQty(widget.product.id);
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.dp(18)),
            boxShadow: [
              BoxShadow(
                color: theme.text.withValues(alpha: 0.05),
                blurRadius: context.dp(4),
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: theme.text.withValues(alpha: 0.22),
                blurRadius: context.dp(26),
                offset: const Offset(0, 14),
                spreadRadius: -16,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCarousel(images, hasMultiple, theme),
              Padding(
                padding: EdgeInsets.fromLTRB(context.dp(15), context.dp(14), context.dp(15), context.dp(15)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: aeLabel(color: theme.text).copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 16 * -0.01,
                      ),
                    ),
                    if (widget.product.contentsDescription?.trim().isNotEmpty ??
                        false) ...[
                      SizedBox(height: context.dp(6)),
                      Text(
                        '${CampaignStrings.contains}: ${widget.product.contentsDescription!.trim()}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: aeCaption(color: ScSaasThemeTokens.gray500).copyWith(
                          fontSize: 12,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    SizedBox(height: context.dp(13)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Prototype `.mk-pprice-wrap`: price + gold PointsChip.
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.product.price.toInt()} kr',
                                style: aeLabel(color: theme.text).copyWith(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (!_expired) ...[
                                SizedBox(height: context.dp(6)),
                                DugnadPointsChip(
                                  points: DugnadDataCache.instance
                                          .peekPointsSummary()
                                          ?.campaignPurchasePoints ??
                                      50,
                                  small: true,
                                ),
                              ],
                            ],
                          ),
                        ),
                        _buildQtyControl(qty, theme),
                      ],
                    ),
                    SizedBox(height: context.dp(13)),
                    Container(
                      padding: EdgeInsets.only(top: context.dp(12)),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: ScSaasThemeTokens.gray100),
                        ),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _openProductDetail();
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  CampaignStrings.viewDetails,
                                  style: aeLabel(color: theme.primaryHover).copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: context.dp(14),
                                  color: theme.primaryHover,
                                ),
                              ],
                            ),
                          ),
                          if (qty > 0) ...[
                            const Spacer(),
                            Text(
                              '$qty i kurv',
                              style: aeCaption(color: _kSuccessGreen).copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
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
        );
      },
    );
  }

  Widget _buildCarousel(
    List<String> images,
    bool hasMultiple,
    AeThemePalette theme,
  ) {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (images.isEmpty)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.primaryTint, theme.primaryTint.withValues(alpha: 0.6)],
                ),
              ),
              child: Icon(
                Icons.image_outlined,
                size: context.dp(40),
                color: theme.primary.withValues(alpha: 0.35),
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
                placeholder: (_, __) => ColoredBox(color: theme.primaryTint),
                errorWidget: (_, __, ___) => ColoredBox(
                  color: theme.primaryTint,
                  child: Icon(Icons.broken_image_outlined, color: theme.primary),
                ),
              ),
            ),
          if (hasMultiple) ...[
            Positioned(
              left: 10,
              top: 0,
              bottom: 0,
              child: Center(child: _navBtn(Icons.chevron_left_rounded, -1)),
            ),
            Positioned(
              right: 10,
              top: 0,
              bottom: 0,
              child: Center(child: _navBtn(Icons.chevron_right_rounded, 1)),
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
                    margin: EdgeInsets.symmetric(horizontal: context.dp(2.5)),
                    width: active ? 18 : 6,
                    height: context.dp(6),
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _navBtn(IconData icon, int delta) {
    return GestureDetector(
      onTap: () {
        final next = _imageIndex + delta;
        if (next >= 0 && next < _images.length) {
          _pageController.animateToPage(
            next,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
          );
        }
      },
      child: Container(
        width: context.dp(32),
        height: context.dp(32),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: context.dp(6),
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: context.dp(18), color: context.aeTheme.text),
      ),
    );
  }

  /// `campState(c).state === "expired"` — derived from the deadline, not a
  /// flag, which is why the whole state was absent rather than half-built.
  bool get _expired {
    final end = DateTime.tryParse(widget.campaign.salesWindowEnd ?? '');
    return end != null && end.isBefore(DateTime.now());
  }

  Widget _buildQtyControl(int qty, AeThemePalette theme) {
    if (_expired) {
      // `disabled`, gray-100 on gray-500 at opacity .6 with no shadow. The
      // button must not accept a tap either -- a disabled-looking control
      // that still fires is worse than one that looks enabled.
      return Opacity(
        opacity: 0.6,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: context.dp(15), vertical: context.dp(9)),
          decoration: BoxDecoration(
            color: ScSaasThemeTokens.border,
            borderRadius: BorderRadius.circular(context.dp(11)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.close_rounded,
                  color: ScSaasThemeTokens.gray500, size: context.dp(14)),
              SizedBox(width: context.dp(6)),
              Text(
                languages.campaignCountdownClosed,
                style: aeLabel(color: ScSaasThemeTokens.gray500).copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (qty == 0) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          widget.bloc.addToCart(widget.product);
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: context.dp(15), vertical: context.dp(9)),
          decoration: BoxDecoration(
            gradient: theme.shinyGradient,
            borderRadius: BorderRadius.circular(context.dp(11)),
            boxShadow: theme.shadowButton,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: Colors.white, size: context.dp(14)),
              SizedBox(width: context.dp(6)),
              Text(
                CampaignStrings.addToCart,
                style: aeLabel(color: Colors.white).copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(context.dp(3)),
      decoration: BoxDecoration(
        color: theme.primaryTint.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepBtn(Icons.remove_rounded, () => widget.bloc.decrementQty(widget.product.id), theme),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.dp(8)),
            child: Text(
              '$qty',
              style: aeLabel(color: theme.text).copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _stepBtn(Icons.add_rounded, () => widget.bloc.incrementQty(widget.product.id), theme),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap, AeThemePalette theme) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: context.dp(30),
        height: context.dp(30),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: context.dp(16), color: theme.primaryHover),
      ),
    );
  }

  void _openProductDetail() {
    openScreen(
      context,
      MatkasseProductScreen(
        campaign: widget.campaign,
        product: widget.product,
        bloc: widget.bloc,
        fallbackImageUrl: widget.fallbackImageUrl,
      ),
    );
  }
}

/// Canonical `au-rise` entrance cadence (dugnad.css / splash.css): the first
/// block rises at 120ms, then roughly 70ms apart; trailing blocks use the
/// 550ms duration and ~50ms spacing of the `.auth-bottom` group. Blocks past
/// the first screenful render immediately rather than animating out of view.
Widget _riseIn(int index, Widget child) {
  if (index > 6) return child;
  return AeRiseIn(
    delay: Duration(
      milliseconds: index < 4 ? 120 + index * 70 : 400 + (index - 4) * 50,
    ),
    duration: Duration(milliseconds: index < 4 ? 600 : 550),
    child: child,
  );
}
