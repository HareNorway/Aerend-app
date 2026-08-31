import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../blocs/bloc.dart';
import '../../commonView/surface_decorations.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/guest_auth_helper.dart';
import '../../utils/stripe_payment_helper.dart';
import '../../utils/global_loading_overlay.dart';
import '../../utils/utils.dart';
import '../common/manageAddress/manage_address_dl.dart';
import '../dugnad/club_crest.dart';
import '../dugnad/dugnad_celebration_orchestrator.dart';
import '../dugnad/dugnad_club_branding.dart';
import '../dugnad/dugnad_club_theme.dart';
import '../dugnad/dugnad_repo.dart';
import '../dugnad/dugnad_state.dart';
import '../dugnad/points_team_sheet.dart';
import '../dugnad/referral_capture_helper.dart';
import '../dugnad/widgets/dugnad_checkout_payment_selector.dart';
import '../dugnad/widgets/dugnad_points_earn.dart';
import '../dugnad/widgets/mk_qty_stepper.dart';
import '../common/vipps/vipps_return_screens.dart';
import 'bloc/campaign_detail_bloc.dart';
import 'bloc/campaign_checkout_bloc.dart';
import '../dugnad/widgets/dugnad_address_drawer.dart';
import 'campaign_delivery_utils.dart';
import 'campaign_media.dart';
import 'campaign_repo.dart';
import 'campaign_order_success_screen.dart';
import 'campaign_strings.dart';
import 'models/campaign_detail_pojo.dart';
import 'widgets/campaign_swipe_pay_bar.dart';

enum _StripePayMode { card, platformWallet }

/// Matches backend default `CAMPAIGN_HOME_DELIVERY_FEE_NOK`.
const double _kCampaignDeliveryFeeNok = 49;

class CampaignCheckoutScreen extends StatefulWidget {
  final CampaignDetailBloc campaign;

  const CampaignCheckoutScreen({super.key, required this.campaign});

  @override
  State<CampaignCheckoutScreen> createState() => _CampaignCheckoutScreenState();
}

class _CampaignCheckoutScreenState extends State<CampaignCheckoutScreen> {
  late CampaignCheckoutBloc _bloc;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _postalController = TextEditingController();
  final _cityController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _deliveryMethod = 'delivery';
  DugnadCheckoutPayMethod _selectedPaymentMethod =
      dugnadCheckoutDefaultPayMethod();

  /// Flat points per purchase from points summary — null until loaded.
  int? _campaignEarnRate;

  bool get _useClubTheme => DugnadState.instance.isDugnadMode;

  DugnadClubThemePalette _clubTheme(BuildContext context) =>
      context.dugnadTheme;

  Color _accent(BuildContext context) => _useClubTheme
      ? _clubTheme(context).primary
      : ScSaasThemeTokens.primary;

  Color _accentHover(BuildContext context) => _useClubTheme
      ? _clubTheme(context).primaryHover
      : ScSaasThemeTokens.primaryHover;

  Color _accentTint(BuildContext context) => _useClubTheme
      ? _clubTheme(context).primaryTint
      : ScSaasThemeTokens.primaryTint;

  Color _accentDisabled(BuildContext context) => _useClubTheme
      ? _clubTheme(context).primaryDisabled
      : ScSaasThemeTokens.primaryDisabled;

  List<BoxShadow> _accentButtonShadow(BuildContext context) => _useClubTheme
      ? _clubTheme(context).shadowButton
      : ScSaasThemeTokens.shadowButton;

  Color _pageBackground(BuildContext context, bool isDark) {
    if (isDark) return Theme.of(context).scaffoldBackgroundColor;
    if (_useClubTheme) return _clubTheme(context).background;
    return ScSaasThemeTokens.background;
  }

  @override
  void initState() {
    super.initState();
    DugnadCelebrationOrchestrator.instance.holdCriticalFlow();
    _bloc = CampaignCheckoutBloc(context, this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resumeGuestCampaignPaymentIfNeeded();
    });
    _nameController.text = prefGetString(prefUserName);
    _emailController.text = prefGetString(prefEmail);
    _phoneController.text = prefGetString(prefContactNumber);
    _prefillAddressFromPrefs();
    _loadEarnRate();
  }

  Future<void> _loadEarnRate() async {
    if (!DugnadState.instance.isDugnadMode) return;
    try {
      final summary = await DugnadRepo().getPointsSummary();
      if (!mounted || summary == null) return;
      setState(() => _campaignEarnRate = summary.campaignPurchasePoints);
    } catch (_) {
      // Leave null — points card stays hidden rather than guessing.
    }
  }

  void _prefillAddressFromPrefs() {
    try {
      final raw = prefGetString(prefNewDeliveryAddress).trim();
      if (raw.isEmpty) return;
      if (raw.startsWith('{')) {
        final item = AddressListItem.fromJson(jsonDecode(raw));
        if (_streetController.text.isEmpty && item.address.isNotEmpty) {
          _streetController.text = item.address;
        }
        _prefillPostalAndCity(item.address);
      } else if (_streetController.text.isEmpty) {
        _streetController.text = raw;
        _prefillPostalAndCity(raw);
      }
    } catch (_) {}
  }

  void _prefillPostalAndCity(String address) {
    if (address.trim().isEmpty) return;

    final parts = address
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .where((part) => !_isCountrySegment(part))
        .where((part) => !_isPlusCodeSegment(part))
        .toList();
    final postcodePattern = RegExp(r'\b\d{4,6}\b');

    String postal = '';
    String city = '';
    for (final part in parts.reversed) {
      final match = postcodePattern.firstMatch(part);
      if (match == null) continue;

      postal = match.group(0) ?? '';
      city = part.replaceFirst(match.group(0) ?? '', '').trim();
      if (city.isEmpty) {
        final partIndex = parts.indexOf(part);
        if (partIndex > 0) city = parts[partIndex - 1];
      }
      break;
    }

    if (city.isEmpty && parts.isNotEmpty) {
      city = parts.last;
    }

    if (_postalController.text.isEmpty && postal.isNotEmpty) {
      _postalController.text = postal;
    }
    if (_cityController.text.isEmpty && city.isNotEmpty) {
      _cityController.text = city;
    }
  }

  bool _isPlusCodeSegment(String part) {
    return RegExp(
      r'^[2-9CFGHJMPQRVWX]{4,}\+[2-9CFGHJMPQRVWX]{2,}',
      caseSensitive: false,
    ).hasMatch(part.trim());
  }

  bool _isCountrySegment(String part) {
    const countries = {
      'india',
      'norway',
      'norge',
      'usa',
      'united states',
      'united kingdom',
      'uk',
    };
    return countries.contains(part.trim().toLowerCase());
  }

  @override
  void dispose() {
    DugnadCelebrationOrchestrator.instance.releaseCriticalFlow();
    _bloc.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _postalController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _resumeGuestCampaignPaymentIfNeeded() async {
    if (!prefGetBool(prefGuestCampaignCheckoutResume)) return;
    final method = guestCampaignResumePaymentMethod();
    final payMode = guestCampaignResumePayMode();
    consumeGuestCampaignCheckoutResume();
    if (!isLoggedIn() || !mounted) return;
    if (method.isEmpty) return;
    final mode = payMode == 'platformWallet'
        ? _StripePayMode.platformWallet
        : _StripePayMode.card;
    await _submit(
      paymentMethod: method,
      stripePayMode: mode,
      skipGuestAuth: true,
    );
  }

  Future<bool> _ensureAuthenticatedForPayment() async {
    if (!isGuestUser()) return true;
    return showGuestLoginSheet(
      context,
      prompt: GuestLoginPrompt.campaignCheckout,
    );
  }

  Future<Map<String, dynamic>?> _confirmCampaignPayment(String orderNo) async {
    if (orderNo.isEmpty || !isLoggedIn()) return null;
    try {
      final response = await CampaignRepo().confirmPayment(orderNo);
      if (response is Map && response['status'] == 1) {
        await capturePendingDugnadReferralIfNeeded();
        await DugnadState.instance.syncPointsTeamFromServer();
        return Map<String, dynamic>.from(response);
      }
    } catch (_) {}
    return null;
  }

  Future<void> _openOrderSuccess({
    required CampaignDetail campaignData,
    required dynamic order,
    Map<String, dynamic>? paymentConfirm,
    required List<CampaignCartItem> cartItems,
    required String email,
    required double totalPayNok,
  }) async {
    if (!mounted) return;
    final pointsEarned = (paymentConfirm?['points_earned'] as num?)?.toInt();
    final pointsTeamName = paymentConfirm?['points_team_name'] as String?;
    final lineItems = cartItems
        .map(
          (item) => CampaignOrderSuccessLineItem(
            name: item.product.name,
            quantity: item.quantity,
            lineTotalNok: item.lineTotal,
          ),
        )
        .toList();
    final boxCount =
        cartItems.fold<int>(0, (sum, item) => sum + item.quantity);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CampaignOrderSuccessScreen(
          orderNo: order?.orderNo ?? '',
          distributionDate: campaignData.distributionDate,
          clubShareAmount: order?.clubShareAmount,
          clubName: order?.clubName,
          clubLogo: order?.clubLogo,
          teamName: order?.teamName,
          teamLogo: order?.teamLogo,
          pointsEarned: pointsEarned,
          pointsTeamName: pointsTeamName,
          email: email,
          totalPayNok: totalPayNok,
          lineItems: lineItems,
          boxCount: boxCount,
        ),
      ),
    );
  }

  Future<void> _submit({
    required String paymentMethod,
    _StripePayMode stripePayMode = _StripePayMode.card,
    bool skipGuestAuth = false,
  }) async {
    if (!skipGuestAuth) {
      if (isGuestUser()) {
        saveGuestCampaignCheckoutResume(
          paymentMethod: paymentMethod,
          payMode: stripePayMode == _StripePayMode.platformWallet
              ? 'platformWallet'
              : 'card',
        );
        final authed = await _ensureAuthenticatedForPayment();
        if (!authed || !mounted) return;
        clearGuestCampaignCheckoutResume();
      }
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_deliveryMethod == 'delivery' && _streetController.text.trim().isEmpty) {
      await _pickDeliveryAddress();
      if (_streetController.text.trim().isEmpty) {
        openSimpleSnackbar(CampaignStrings.addressRequired);
        return;
      }
    }
    if (widget.campaign.currentCart.isEmpty) {
      openSimpleSnackbar(CampaignStrings.emptyCart);
      return;
    }

    final detail = widget.campaign;
    final campaignData = (await detail.detailStream.first).data?.campaign;
    if (campaignData == null) return;

    final result = await _bloc.submitOrder(
      slug: campaignData.slug,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      deliveryMethod: _deliveryMethod,
      paymentMethod: paymentMethod,
      streetAddress: _deliveryMethod == 'delivery'
          ? _streetController.text.trim()
          : null,
      postalCode: _deliveryMethod == 'delivery'
          ? _postalController.text.trim()
          : null,
      city: _deliveryMethod == 'delivery' ? _cityController.text.trim() : null,
      cartItems: detail.currentCart,
    );

    if (result == null || !mounted) return;

    final payment = result.payment;
    final order = result.order;
    final cartItems = detail.currentCart;
    final email = _emailController.text.trim();
    final subtotal = cartItems.fold(0.0, (sum, item) => sum + item.lineTotal);
    final totalPayNok = subtotal + _deliveryFee();
    final lineItems = cartItems
        .map(
          (item) => CampaignOrderSuccessLineItem(
            name: item.product.name,
            quantity: item.quantity,
            lineTotalNok: item.lineTotal,
          ),
        )
        .toList();
    final boxCount =
        cartItems.fold<int>(0, (sum, item) => sum + item.quantity);

    if (payment != null && payment.isVipps && payment.redirectUrl != null) {
      savePendingCampaignVippsCheckout(
        orderNo: order?.orderNo ?? '',
        distributionDate: campaignData.distributionDate,
        clubShareAmount: order?.clubShareAmount,
        clubName: order?.clubName,
        clubLogo: order?.clubLogo,
        teamName: order?.teamName,
        teamLogo: order?.teamLogo,
        email: email,
        totalPayNok: totalPayNok,
        boxCount: boxCount,
        lineItems: lineItems,
      );
      final uri = Uri.parse(payment.redirectUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      _bloc.setLoading(false);
      return;
    }

    if (payment != null && payment.isStripe && payment.clientSecret != null) {
      try {
        if (stripePayMode == _StripePayMode.platformWallet) {
          await StripePaymentHelper.confirmPlatformPay(
            clientSecret: payment.clientSecret!,
            orderNo: order?.orderNo ?? '',
            totalPay: order?.totalPay ?? 0,
            platform: Theme.of(context).platform,
          );
          _bloc.setLoading(false);
        } else {
          // Hold "Behandling…" through initPaymentSheet (the 2–3s gap), then
          // drop it right before presentPaymentSheet so the sheet isn't covered.
          await StripePaymentHelper.presentPaymentSheet(
            clientSecret: payment.clientSecret!,
            orderNo: order?.orderNo ?? '',
            totalPay: order?.totalPay ?? 0,
            onReadyToPresent: () => _bloc.setLoading(false),
          );
        }
        if (!mounted) return;
        final confirm = await withGlobalLoadingOverlay(() async {
          return _confirmCampaignPayment(order?.orderNo ?? '');
        }, message: CampaignStrings.processing);
        if (!mounted) return;
        await _openOrderSuccess(
          campaignData: campaignData,
          order: order,
          paymentConfirm: confirm,
          cartItems: cartItems,
          email: email,
          totalPayNok: totalPayNok,
        );
      } catch (e) {
        if (!mounted) return;
        _bloc.setLoading(false);
        openSimpleSnackbar(CampaignStrings.paymentFailed);
      }
      return;
    }

    if (payment != null &&
        payment.required_ == false &&
        order != null &&
        mounted) {
      _bloc.setLoading(false);
      final confirm = await withGlobalLoadingOverlay(() async {
        return _confirmCampaignPayment(order.orderNo);
      }, message: CampaignStrings.processing);
      if (!mounted) return;
      await _openOrderSuccess(
        campaignData: campaignData,
        order: order,
        paymentConfirm: confirm,
        cartItems: cartItems,
        email: email,
        totalPayNok: totalPayNok,
      );
      return;
    }

    if (mounted) {
      _bloc.setLoading(false);
      openSimpleSnackbar(CampaignStrings.paymentInitFailed);
    }
  }

  void _onSwipePay() {
    if (_selectedPaymentMethod == DugnadCheckoutPayMethod.vipps) {
      _submit(paymentMethod: 'vipps');
      return;
    }
    if (_selectedPaymentMethod == DugnadCheckoutPayMethod.platformWallet) {
      _submit(
        paymentMethod: 'stripe',
        stripePayMode: _StripePayMode.platformWallet,
      );
    } else {
      _submit(paymentMethod: 'stripe', stripePayMode: _StripePayMode.card);
    }
  }

  double _deliveryFee() =>
      _deliveryMethod == 'delivery' ? _kCampaignDeliveryFeeNok : 0;

  double _grandTotal(double subtotal) => subtotal + _deliveryFee();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cart = widget.campaign.currentCart;
    final subtotal = widget.campaign.cartTotal;
    final deliveryFee = _deliveryFee();
    final grandTotal = _grandTotal(subtotal);
    final accent = _accent(context);

    return Scaffold(
      backgroundColor: _pageBackground(context, isDark),
      body: Form(
        key: _formKey,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.maybePop(context),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.chevron_left,
                                color: accent,
                                size: 28,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              CampaignStrings.yourOrder,
                              textAlign: TextAlign.center,
                              style: aeH3(),
                            ),
                          ),
                          const SizedBox(width: 40),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildOrderCard(cart),
                      const SizedBox(height: 14),
                      StreamBuilder(
                        stream: widget.campaign.detailStream,
                        builder: (context, snap) {
                          final campaign = snap.data?.data?.campaign;
                          if (campaign == null) return const SizedBox.shrink();
                          return Column(
                            children: [
                              _buildClubBanner(campaign, isDark),
                              const SizedBox(height: 14),
                              _buildDeliveryCard(campaign, isDark),
                            ],
                          );
                        },
                      ),
                      if (DugnadState.instance.isDugnadMode &&
                          isLoggedIn() &&
                          !DugnadState.instance.hasPointsTeam) ...[
                        // Gap between `.co-card` (Leveringsmåte) and the team nudge —
                        // without this the two green/white cards sit flush.
                        const SizedBox(height: 14),
                        _buildPointsTeamNudge(isDark),
                        const SizedBox(height: 14),
                      ],
                      Offstage(
                        offstage: true,
                        child: _buildContactAndAddressFields(),
                      ),
                      const SizedBox(height: 14),
                      DugnadCheckoutPaymentSelector(
                        value: _selectedPaymentMethod,
                        accent: accent,
                        onChanged: (method) => setState(
                          () => _selectedPaymentMethod = method,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildSummaryCard(
                        subtotal,
                        deliveryFee,
                        grandTotal,
                        isDark,
                      ),
                      if (_campaignEarnRate != null &&
                          _campaignEarnRate! > 0 &&
                          widget.campaign.cartItemCount > 0) ...[
                        const SizedBox(height: 14),
                        DugnadPointsEarn(
                          points: _campaignEarnRate!,
                          title: languages.dugnadEarnPointsOnPurchaseTitle,
                          subtitle: languages.dugnadEarnPointsOnPurchaseSub,
                        ),
                      ],
                      const SizedBox(height: 12),
                      StreamBuilder<String?>(
                        stream: _bloc.errorStream,
                        builder: (context, snap) {
                          if (snap.data == null) return const SizedBox.shrink();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: ScSaasThemeTokens.danger.withValues(
                                alpha: 0.08,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              snap.data!,
                              style: GoogleFonts.plusJakartaSans(
                                color: ScSaasThemeTokens.danger,
                                fontSize: 14,
                              ),
                            ),
                          );
                        },
                      ),
                      StreamBuilder<bool>(
                        stream: _bloc.loadingStream,
                        builder: (context, snap) {
                          if (snap.data != true) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: Text(
                                CampaignStrings.processing,
                                style: aeLabel(color: accent),
                              ),
                            ),
                          );
                        },
                      ),
                    ]),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: _pageBackground(context, isDark),
                padding: EdgeInsets.fromLTRB(
                  16,
                  14,
                  16,
                  MediaQuery.of(context).padding.bottom + 12,
                ),
                child: StreamBuilder<bool>(
                  stream: _bloc.loadingStream,
                  builder: (context, snap) {
                    final loading = snap.data == true;
                    return CampaignSwipePayBar(
                      label: CampaignStrings.swipeToPay,
                      amountText: '${grandTotal.toInt()} kr',
                      enabled: !loading && cart.isNotEmpty,
                      onConfirmed: _onSwipePay,
                      accent: accent,
                      accentHover: _accentHover(context),
                      accentDisabled: _accentDisabled(context),
                      buttonShadow: _accentButtonShadow(context),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(List<CampaignCartItem> cart) {
    final theme = _clubTheme(context);
    // Mock uses campaign `short` ("Sædalen"), not full club name.
    final shortClub = DugnadClubBranding.compactName();
    return Container(
      // `.co-card` — 16px pad, 16px radius
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: AeSurface.card(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // `.co-label` — 10.5 / 800 / .08em, margin-bottom 10
          Text(
            CampaignStrings.yourOrder.toUpperCase(),
            style: aeOverline(color: ScSaasThemeTokens.gray500),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < cart.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 1,
                color: ScSaasThemeTokens.gray100,
              ),
            _buildOrderItemRow(cart[i], shortClub, theme),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderItemRow(
    CampaignCartItem item,
    String shortClub,
    DugnadClubThemePalette theme,
  ) {
    // `.mk-coitem .qty` — "{price} kr · {short}"
    final meta = shortClub.isNotEmpty
        ? '${item.product.price.toInt()} kr · $shortClub'
        : '${item.product.price.toInt()} kr';
    final imageUrl = _orderItemImageUrl(item);
    // `.co-item.mk-coitem` — gap 11, columns 44 | 1fr | auto | auto
    // Vertical padding lives on the card + label gap (not doubled here).
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _orderThumb(imageUrl),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.product.name,
                // `.co-item .nm` — 14 / 700; mock reads bold → w800
                style: aeLabel(color: theme.text).copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                meta,
                style: aeCaption(color: ScSaasThemeTokens.gray500).copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 11),
        MkQtyStepper(
          qty: item.quantity,
          theme: theme,
          small: true,
          onDecrement: () {
            widget.campaign.decrementQty(item.product.id);
            if (mounted) setState(() {});
          },
          onIncrement: () {
            widget.campaign.incrementQty(item.product.id);
            if (mounted) setState(() {});
          },
        ),
        const SizedBox(width: 11),
        Text(
          '${item.lineTotal.toInt()} kr',
          // `.co-item .pr` — 14 / 800
          style: aeLabel(color: theme.text).copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
      ],
    );
  }

  String? _orderItemImageUrl(CampaignCartItem item) {
    // Same resolution as `_MkProductCard` / product detail: product images
    // first, then campaign hero as fallback.
    final productImages = item.product.displayImages;
    if (productImages.isNotEmpty) return productImages.first;
    final hero = widget.campaign.currentCampaign?.heroImageUrl;
    return CampaignMedia.resolveUrl(hero);
  }

  Widget _orderThumb(String? imageUrl) {
    // `.mk-cart-thumb` — 44×44, radius 10
    const size = 44.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl != null && imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 200),
                placeholder: (_, __) => const ColoredBox(
                  color: ScSaasThemeTokens.gray100,
                ),
                errorWidget: (_, __, ___) => const ColoredBox(
                  color: ScSaasThemeTokens.gray100,
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 18,
                    color: ScSaasThemeTokens.gray500,
                  ),
                ),
              )
            : const ColoredBox(
                color: ScSaasThemeTokens.gray100,
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 18,
                  color: ScSaasThemeTokens.gray500,
                ),
              ),
      ),
    );
  }

  Widget _buildPointsTeamNudge(bool isDark) {
    final clubId = DugnadState.instance.hasClub ? DugnadState.instance.clubId : 0;
    final accent = _accent(context);
    final tint = _accentTint(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? accent.withValues(alpha: 0.12) : tint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.emoji_events_outlined, color: accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(languages.dugnadPointsTeamCheckoutNudge, style: aeBody()),
                const SizedBox(height: 4),
                Text(
                  languages.dugnadPointsTeamPurchasePoints(50),
                  style: aeCaption(color: accent),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: clubId <= 0
                ? null
                : () async {
                    await showPointsTeamSheet(context, clubId: clubId);
                    if (mounted) setState(() {});
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                languages.dugnadPointsTeamSelect,
                style: aeCaption(color: Colors.white)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClubBanner(CampaignDetail campaign, bool isDark) {
    final clubName = campaign.club?.name.trim() ?? '';
    final teamName = campaign.team?.name.trim() ?? '';
    // Prototype `.dg-donate` / `MkCrest` uses the club crest — never the
    // campaign `logo_url` (Hare «kampanjer» mark), which is a product brand.
    final crestName = clubName.isNotEmpty
        ? clubName
        : (teamName.isNotEmpty ? teamName : 'klubben');
    final logoCandidates = <String?>[
      campaign.club?.logo,
      campaign.team?.logoUrl,
      DugnadState.instance.clubLogo,
    ];
    final logoUrl = logoCandidates
        .map((e) => e?.trim() ?? '')
        .firstWhere((e) => e.isNotEmpty, orElse: () => '');
    final crestLogo = logoUrl.isEmpty ? null : logoUrl;
    // Mock: "{club} · {team}" — no distribution location in the subtitle.
    final subtitle = [
      if (clubName.isNotEmpty) clubName,
      if (teamName.isNotEmpty) teamName,
    ].join(' · ');
    // Fixed "går til klubben" (not team name) — matches `.dg-donate` copy.
    final title = languages.campaignPurchaseClubShare
        .replaceAll(RegExp(r'[💖❤️]'), '')
        .trim();
    final textColor = isDark ? Colors.white : ScSaasThemeTokens.text;
    final subColor = isDark
        ? Colors.white.withValues(alpha: 0.7)
        : ScSaasThemeTokens.gray500;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        gradient: isDark
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0x2422A769),
                  Color(0x0F22A769),
                ],
              ),
        color: isDark
            ? ScSaasThemeTokens.accent.withValues(alpha: 0.12)
            : null,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ScSaasThemeTokens.accent.withValues(alpha: 0.26),
        ),
      ),
      child: Row(
        children: [
          ClubCrest(name: crestName, logoUrl: crestLogo, size: 42),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: aeLabel(color: textColor).copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: aeCaption(color: subColor).copyWith(
                      fontSize: 11.5,
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

  Future<void> _pickDeliveryAddress() async {
    HapticFeedback.lightImpact();
    await showDugnadAddressDrawer(
      context,
      parentContext: context,
      onAddressChanged: () {
        _prefillAddressFromPrefs();
        if (mounted) setState(() {});
      },
    );
    _prefillAddressFromPrefs();
    if (mounted) setState(() {});
  }

  ({String title, String subtitle}) _deliveryAddressLines() {
    final street = _streetController.text.trim();
    if (street.isNotEmpty) {
      return splitSavedAddress(street);
    }
    try {
      final raw = prefGetString(prefNewDeliveryAddress).trim();
      if (raw.startsWith('{')) {
        final item = AddressListItem.fromJson(jsonDecode(raw));
        return splitSavedAddress(item.address);
      }
      return splitSavedAddress(raw);
    } catch (_) {
      return (title: '', subtitle: '');
    }
  }

  Widget _buildDeliveryCard(CampaignDetail campaign, bool isDark) {
    final accent = _accent(context);
    final accentTint = _accentTint(context);
    final schedule =
        CampaignDistributionSchedule.fromIso(campaign.distributionDate);
    final clubName = campaign.club?.name ?? '';
    final pickupLocation = campaign.distributionLocation?.trim() ?? '';
    final address = _deliveryAddressLines();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AeSurface.card(borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            CampaignStrings.deliveryMethod.toUpperCase(),
            style: aeOverline(),
          ),
          const SizedBox(height: 12),
          _segmentedDeliveryToggle(accentTint),
          const SizedBox(height: 14),
          if (_deliveryMethod == 'delivery') ...[
            _deliveryDetailRow(
              accent: accent,
              icon: Icons.location_on_outlined,
              title: address.title.isNotEmpty
                  ? address.title
                  : CampaignStrings.streetAddress,
              subtitle: address.subtitle.isNotEmpty
                  ? address.subtitle
                  : languages.dugnadSelectAddress,
              trailing: GestureDetector(
                onTap: _pickDeliveryAddress,
                child: Text(
                  CampaignStrings.change,
                  style: aeLabel(color: accent)
                      .copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            if (schedule.dateLabel.isNotEmpty) ...[
              const SizedBox(height: 12),
              Divider(color: ScSaasThemeTokens.border.withValues(alpha: 0.7)),
              const SizedBox(height: 10),
              _deliveryWhenRow(
                accent: accent,
                accentTint: accentTint,
                icon: Icons.local_shipping_outlined,
                label: schedule.deliveryLine,
                bold: schedule.dateLabel,
              ),
            ],
          ] else ...[
            _deliveryDetailRow(
              accent: accent,
              icon: Icons.storefront_outlined,
              title: languages.campaignPickupAtClubName(clubName),
              subtitle: pickupLocation.isNotEmpty
                  ? pickupLocation
                  : CampaignStrings.pickupAtClub,
            ),
            if (schedule.dateLabel.isNotEmpty) ...[
              const SizedBox(height: 12),
              Divider(color: ScSaasThemeTokens.border.withValues(alpha: 0.7)),
              const SizedBox(height: 10),
              _deliveryWhenRow(
                accent: accent,
                accentTint: accentTint,
                icon: Icons.schedule_rounded,
                label: schedule.pickupLine,
                bold: schedule.dateLabel,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _deliveryDetailRow({
    required Color accent,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: accent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: aeTitle().copyWith(fontSize: 15),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: aeCaption(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _deliveryWhenRow({
    required Color accent,
    required Color accentTint,
    required IconData icon,
    required String label,
    required String bold,
  }) {
    final parts = label.split(bold);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: accentTint,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: accent, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: aeCaption().copyWith(height: 1.4),
              children: [
                if (parts.isNotEmpty) TextSpan(text: parts.first),
                TextSpan(
                  text: bold,
                  style: aeLabel(color: accent)
                      .copyWith(fontWeight: FontWeight.w800),
                ),
                if (parts.length > 1) TextSpan(text: parts.sublist(1).join(bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _segmentedDeliveryToggle(Color trackColor) {
    final accent = _accent(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 4.0;
          final segmentWidth = (constraints.maxWidth - gap) / 2;
          final left = _deliveryMethod == 'delivery' ? 0.0 : segmentWidth + gap;
          return SizedBox(
            height: 40,
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  left: left,
                  top: 0,
                  bottom: 0,
                  width: segmentWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    _deliverySegment(
                      label: CampaignStrings.deliveryTab,
                      icon: Icons.local_shipping_outlined,
                      selected: _deliveryMethod == 'delivery',
                      activeColor: accent,
                      onTap: () => setState(() => _deliveryMethod = 'delivery'),
                    ),
                    const SizedBox(width: gap),
                    _deliverySegment(
                      label: CampaignStrings.pickupTab,
                      icon: Icons.storefront_outlined,
                      selected: _deliveryMethod == 'pickup',
                      activeColor: accent,
                      onTap: () => setState(() => _deliveryMethod = 'pickup'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _deliverySegment({
    required String label,
    required IconData icon,
    required bool selected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? activeColor : ScSaasThemeTokens.gray500,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: aeLabel(
                  color: selected ? activeColor : ScSaasThemeTokens.gray500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    double subtotal,
    double deliveryFee,
    double grandTotal,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AeSurface.card(borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          _summaryRow(CampaignStrings.subtotal, '${subtotal.toInt()} NOK'),
          if (deliveryFee > 0) ...[
            const SizedBox(height: 10),
            _summaryRow(
              CampaignStrings.deliveryTab,
              '${deliveryFee.toInt()} NOK',
            ),
          ],
          const SizedBox(height: 10),
          Divider(
            color: ScSaasThemeTokens.gray300.withValues(alpha: 0.6),
            height: 1,
          ),
          const SizedBox(height: 10),
          _summaryRow(
            CampaignStrings.total,
            '${grandTotal.toInt()} NOK',
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: isBold ? aeH3() : aeBody()),
        Text(value, style: isBold ? aeH3() : aeLabel()),
      ],
    );
  }

  Widget _buildContactAndAddressFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(CampaignStrings.contactInfo, style: aeTitle()),
        const SizedBox(height: 8),
        _textField(
          _nameController,
          CampaignStrings.fullName,
          validator: (v) => v == null || v.trim().isEmpty
              ? CampaignStrings.nameRequired
              : null,
        ),
        _textField(
          _emailController,
          CampaignStrings.email,
          keyboardType: TextInputType.emailAddress,
          validator: (v) => v == null || v.trim().isEmpty
              ? CampaignStrings.emailRequired
              : null,
        ),
        _textField(
          _phoneController,
          CampaignStrings.phone,
          keyboardType: TextInputType.phone,
          validator: (v) => v == null || v.trim().isEmpty
              ? CampaignStrings.phoneRequired
              : null,
        ),
        if (_deliveryMethod == 'delivery') ...[
          const SizedBox(height: 8),
          Text(CampaignStrings.deliveryAddress, style: aeTitle()),
          const SizedBox(height: 8),
          _textField(
            _streetController,
            CampaignStrings.streetAddress,
            validator: (v) =>
                _deliveryMethod == 'delivery' && (v == null || v.trim().isEmpty)
                ? CampaignStrings.addressRequired
                : null,
            onChanged: (_) => setState(() {}),
          ),
          Row(
            children: [
              Expanded(
                child: _textField(
                  _postalController,
                  CampaignStrings.postalCode,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _textField(
                  _cityController,
                  CampaignStrings.city,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        onChanged: onChanged,
        style: aeBody(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: aeCaption(color: ScSaasThemeTokens.muted),
          filled: true,
          fillColor: ScSaasThemeTokens.gray50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: ScSaasThemeTokens.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _accent(context)),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
