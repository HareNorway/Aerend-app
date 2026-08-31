import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/ae_typography.dart';
import '../../theme/design_scale.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/utils.dart';
import '../campaign/bloc/campaign_detail_bloc.dart';
import '../campaign/campaign_checkout_screen.dart';
import '../campaign/campaign_media.dart';
import '../campaign/campaign_product_utils.dart';
import '../campaign/campaign_strings.dart';
import '../campaign/models/campaign_detail_pojo.dart';
import 'dugnad_repo.dart';
import 'dugnad_supplier_sheet.dart';
import 'dugnad_club_branding.dart';
import 'dugnad_club_theme.dart';
import 'widgets/campaign_countdown.dart';
import 'widgets/dugnad_points_earn.dart';
import 'widgets/dugnad_subpage_shell.dart';
import 'widgets/mk_cart_bar.dart';
import 'widgets/dugnad_rise_in.dart';

// Aliases the token rather than repeating its hex. A shared constant is
// verified once or not at all: when every site holds the same wrong value
// they stay consistent with each other and diverge only from the source.
const _kSuccessGreen = ScSaasThemeTokens.success;

/// Dugnad product detail — mirrors prototype `MatkasseProduct`.
class MatkasseProductScreen extends StatefulWidget {
  const MatkasseProductScreen({
    super.key,
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
  State<MatkasseProductScreen> createState() => _MatkasseProductScreenState();
}

class _MatkasseProductScreenState extends State<MatkasseProductScreen> {
  /// `campState(c).state === "expired"` — derived from the campaign's own
  /// deadline. An expired campaign must not accept orders, so this gates the
  /// stepper, the points estimate and the CTA together.
  bool get _expired {
    final end = DateTime.tryParse(widget.campaign.salesWindowEnd ?? '');
    return end != null && end.isBefore(DateTime.now());
  }

  late final PageController _pageController;
  int _imageIndex = 0;

  /// Configured campaign earn rate (points per box) from the config API via
  /// PointsSummary — the same source the app awards on. Null until loaded; the
  /// points display stays hidden rather than show an estimate.
  int? _campaignEarnRate;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadEarnRate();
  }

  Future<void> _loadEarnRate() async {
    try {
      final summary = await DugnadRepo().getPointsSummary();
      if (mounted && summary != null) {
        setState(() => _campaignEarnRate = summary.campaignPurchasePoints);
      }
    } catch (_) {
      // Leave null — points display stays hidden.
    }
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

  String _audienceLabel() {
    final club = (widget.campaign.club?.name ?? '').trim();
    final team = (widget.campaign.team?.name ?? '').trim();
    final parts = [club, team].where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    return parts.join(' · ').toUpperCase();
  }

  String _shareNote() {
    final club = widget.campaign.club?.name ?? DugnadClubBranding.fullName();
    return languages.dugnadPurchaseShareToClub(club);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final images = _images;
    final hasMultiple = images.length > 1;
    final audience = _audienceLabel();
    final contents = CampaignProductUtils.parseContents(
      widget.product.contentsDescription,
    );
    final description = (widget.product.description?.trim().isNotEmpty ?? false)
        ? widget.product.description!.trim()
        : (widget.campaign.landingIntroText?.trim() ?? '');
    final intro = widget.campaign.landingIntroText?.trim() ?? '';
    final note = intro.isNotEmpty && intro != description ? intro : '';

    return Scaffold(
      backgroundColor: theme.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeroImage(images, hasMultiple, theme)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(context.dp(18), context.dp(16), context.dp(18), context.dp(0)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Entrance stagger — the title group (audience, name,
                      // price) shares index 0 so it rises as one block.
                      if (audience.isNotEmpty) ...[
                        _riseIn(
                          0,
                          Text(
                            audience,
                            style: aeOverline(color: theme.primary).copyWith(
                              fontSize: 11,
                              letterSpacing: 11 * 0.02,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        SizedBox(height: context.dp(4)),
                      ],
                      _riseIn(
                        0,
                        Text(
                          widget.product.name,
                          style: AeDugnadText.sectionTitle(color: theme.text),
                        ),
                      ),
                      SizedBox(height: context.dp(6)),
                      _riseIn(
                        0,
                        Text(
                          '${widget.product.price.toInt()} kr',
                          style: aeH2(color: theme.primaryHover).copyWith(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        SizedBox(height: context.dp(20)),
                        _riseIn(
                          1,
                          _sectionHeading(CampaignStrings.descriptionHeading),
                        ),
                        SizedBox(height: context.dp(10)),
                        _riseIn(
                          1,
                          Text(
                            description,
                            style: aeBody(color: ScSaasThemeTokens.ink).copyWith(
                              fontSize: context.dp(17),
                              fontWeight: FontWeight.w600,
                              height: 1.55,
                            ),
                          ),
                        ),
                      ],
                      if (contents.isNotEmpty) ...[
                        SizedBox(height: context.dp(20)),
                        _riseIn(
                          2,
                          _sectionHeading(CampaignStrings.contentsHeading),
                        ),
                        SizedBox(height: context.dp(10)),
                        ...contents.map(
                          (item) => _riseIn(2, _contentBullet(item, theme)),
                        ),
                      ],
                      if (note.isNotEmpty) ...[
                        SizedBox(height: context.dp(18)),
                        _riseIn(3, _supplierBanner(note, theme)),
                      ],
                      if (widget.campaign.salesWindowEnd?.isNotEmpty ?? false) ...[
                        SizedBox(height: context.dp(18)),
                        _riseIn(
                          4,
                          CampaignCountdownPanel(
                            salesWindowEnd: widget.campaign.salesWindowEnd!,
                          ),
                        ),
                      ],
                      SizedBox(height: context.dp(20)),
                      _riseIn(5, _buildBuyCard(theme)),
                      SizedBox(height: context.dp(120)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          MkCartBar(bloc: widget.bloc),
        ],
      ),
    );
  }

  Widget _sectionHeading(String text) {
    final size = context.dp(13);
    return Text(
      text.toUpperCase(),
      style: aeOverline(color: ScSaasThemeTokens.gray700).copyWith(
        fontSize: size,
        letterSpacing: size * 0.05,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _contentBullet(String item, DugnadClubThemePalette theme) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.dp(9)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: context.dp(9), left: context.dp(2)),
            child: Container(
              width: context.dp(6),
              height: context.dp(6),
              decoration: BoxDecoration(
                color: theme.primarySoft,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SizedBox(width: context.dp(10)),
          Expanded(
            child: Text(
              item,
              style: aeBody(color: ScSaasThemeTokens.ink).copyWith(
                fontSize: context.dp(17),
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _supplierBanner(String note, DugnadClubThemePalette theme) {
    // Tappable — opens the supplier detail sheet (prototype: banner → SupplierSheet).
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        showDugnadSupplierSheet(context, heading: note);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: context.dp(13), vertical: context.dp(11)),
        decoration: BoxDecoration(
          color: _kSuccessGreen.withValues(alpha: 0.10),
          // Prototype `.dg-green-banner`: radius 16, 1px border.
          borderRadius: BorderRadius.circular(context.dp(16)),
          border: Border.all(color: _kSuccessGreen.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            Container(
              width: context.dp(38),
              height: context.dp(38),
              decoration: BoxDecoration(
                color: _kSuccessGreen.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(context.dp(11)),
              ),
              child:
                  Icon(Icons.shield_outlined, size: context.dp(17), color: theme.primaryHover),
            ),
            SizedBox(width: context.dp(12)),
            Expanded(
              child: Text(
                note,
                style: aeLabel(color: theme.text).copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SizedBox(width: context.dp(10)),
            // Prototype chevron circle (24×24, green tint).
            Container(
              width: context.dp(24),
              height: context.dp(24),
              decoration: BoxDecoration(
                color: _kSuccessGreen.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.chevron_right_rounded,
                  size: context.dp(15), color: _kSuccessGreen),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage(
    List<String> images,
    bool hasMultiple,
    DugnadClubThemePalette theme,
  ) {
    return AspectRatio(
      // `.mk-pcar { aspect-ratio: 16/10 }`
      aspectRatio: 16 / 10,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (images.isEmpty)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.primaryTint, theme.primaryTint.withValues(alpha: 0.65)],
                ),
              ),
              child: Icon(
                Icons.image_outlined,
                size: context.dp(48),
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
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 16,
            child: DugnadLbBackButton(
              onPressed: () => Navigator.maybePop(context),
            ),
          ),
          if (hasMultiple) ...[
            Positioned(
              left: 10,
              top: 0,
              bottom: 0,
              child: Center(child: _navBtn(Icons.chevron_left_rounded, -1, theme)),
            ),
            Positioned(
              right: 10,
              top: 0,
              bottom: 0,
              child: Center(child: _navBtn(Icons.chevron_right_rounded, 1, theme)),
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
                      color: active ? Colors.white : Colors.white.withValues(alpha: 0.6),
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

  Widget _navBtn(IconData icon, int delta, DugnadClubThemePalette theme) {
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
        // `.mk-pcar-nav` icon is 16.
        child: Icon(icon, size: context.dp(16), color: theme.text),
      ),
    );
  }

  Widget _buildBuyCard(DugnadClubThemePalette theme) {
    return StreamBuilder<List<CampaignCartItem>>(
      stream: widget.bloc.cartStream,
      builder: (context, snap) {
        final rate = _campaignEarnRate;
        // Campaign purchase points are awarded FLAT per order (backend:
        // PointsService::awardCampaignPurchasePoints — no qty multiplier), so
        // the display must NOT scale with box count.
        final points = rate ?? 0;
        // Cart quantity — used only for the stepper / in-cart button / label,
        // NOT for points (which are flat per order).
        final qty = widget.bloc.getQty(widget.product.id);

        return Container(
          padding: EdgeInsets.all(context.dp(16)),
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
                color: theme.text.withValues(alpha: 0.24),
                blurRadius: context.dp(30),
                offset: const Offset(0, 16),
                spreadRadius: -16,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          CampaignStrings.pricePerBox,
                          style: aeCaption(color: ScSaasThemeTokens.gray500).copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: context.dp(2)),
                        Text(
                          '${widget.product.price.toInt()} kr',
                          style: aeH2(color: theme.text).copyWith(fontSize: 22),
                        ),
                      ],
                    ),
                  ),
                  if (qty > 0 && !_expired) _qtyStepper(qty, theme),
                ],
              ),
              // Only shown once the real earn rate has loaded — never an estimate.
              if (rate != null && rate > 0 && !_expired) ...[
                SizedBox(height: context.dp(14)),
                DugnadPointsEarn(
                  points: points,
                  title: languages.dugnadEarnPointsOnPurchaseTitle,
                  subtitle: languages.dugnadEarnPointsOnPurchaseSub,
                ),
              ],
              SizedBox(height: context.dp(13)),
              if (_expired)
                // Disabled `ae-btn` -- gray-100 on gray-500, no tap handler.
                Opacity(
                  opacity: 0.6,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: context.dp(14)),
                    decoration: BoxDecoration(
                      color: ScSaasThemeTokens.border,
                      borderRadius: BorderRadius.circular(context.dp(14)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.close_rounded,
                            size: context.dp(17), color: ScSaasThemeTokens.gray500),
                        SizedBox(width: context.dp(8)),
                        Text(
                          languages.campaignCountdownClosed,
                          style: aeLabel(color: ScSaasThemeTokens.gray500)
                              .copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (qty == 0)
                _primaryButton(
                  label: CampaignStrings.addToCart,
                  icon: Icons.add_rounded,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    widget.bloc.addToCart(widget.product);
                  },
                  theme: theme,
                )
              else
                _secondaryButton(
                  label: languages.dugnadInCartBoxes(qty),
                  icon: Icons.check_rounded,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    openScreen(
                      context,
                      CampaignCheckoutScreen(campaign: widget.bloc),
                    );
                  },
                  theme: theme,
                ),
              SizedBox(height: context.dp(12)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_rounded, size: context.dp(14), color: _kSuccessGreen),
                  SizedBox(width: context.dp(7)),
                  Flexible(
                    child: Text(
                      _shareNote(),
                      textAlign: TextAlign.center,
                      style: aeCaption(color: _kSuccessGreen).copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required DugnadClubThemePalette theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: context.dp(14)),
        decoration: BoxDecoration(
          gradient: theme.shinyGradient,
          borderRadius: BorderRadius.circular(context.dp(14)),
          boxShadow: theme.shadowButton,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: context.dp(18)),
            SizedBox(width: context.dp(8)),
            Text(
              label,
              style: aeLabel(color: Colors.white).copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _secondaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required DugnadClubThemePalette theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: context.dp(14)),
        decoration: BoxDecoration(
          color: theme.primaryTint,
          borderRadius: BorderRadius.circular(context.dp(14)),
          border: Border.all(color: theme.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.primaryHover, size: context.dp(17)),
            SizedBox(width: context.dp(8)),
            Text(
              label,
              style: aeLabel(color: theme.primaryHover).copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyStepper(int qty, DugnadClubThemePalette theme) {
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

  Widget _stepBtn(IconData icon, VoidCallback onTap, DugnadClubThemePalette theme) {
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
}

/// Canonical `au-rise` entrance cadence (dugnad.css / splash.css): the first
/// block rises at 120ms, then roughly 70ms apart; trailing blocks use the
/// 550ms duration and ~50ms spacing of the `.auth-bottom` group. Blocks past
/// the first screenful render immediately rather than animating out of view.
Widget _riseIn(int index, Widget child) {
  if (index > 6) return child;
  return DugnadRiseIn(
    delay: Duration(
      milliseconds: index < 4 ? 120 + index * 70 : 400 + (index - 4) * 50,
    ),
    duration: Duration(milliseconds: index < 4 ? 600 : 550),
    child: child,
  );
}
