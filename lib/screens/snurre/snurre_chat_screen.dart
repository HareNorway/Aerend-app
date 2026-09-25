import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../deliveryService/storeDetail/store_detail_dl.dart';
import '../../theme/sc_saas_theme.dart';
import '../../commonView/surface_decorations.dart';
import '../../utils/utils.dart';
import '../common/homeMainV1/home_main_v1.dart';
import '../common/orderCart/order_cart.dart';
import '../common/orderCart/order_cart_repo.dart';
import '../common/swipeAerend/swipe_aerend_dl.dart';
import '../common/swipeAerend/swipe_aerend_repo.dart';
import '../deliveryService/checkout/checkout.dart';
import '../deliveryService/storeDetail/store_detail.dart';
import 'snurre_launcher_policy.dart';
import 'snurre_repo.dart';

/// In-app AI assistant (Snurre) for the Ærend customer app. Backend: Laravel Snurre API.
class SnurreChatScreen extends StatefulWidget {
  /// Text copied from the home search field when opening via the sparkle control.
  final String draftFromHomeSearch;

  const SnurreChatScreen({super.key, this.draftFromHomeSearch = ''});

  @override
  State<SnurreChatScreen> createState() => _SnurreChatScreenState();
}

class _SnurreUiMessage {
  _SnurreUiMessage({
    required this.isUser,
    required this.text,
    required this.at,
    this.storeCards = const [],
    this.productCards = const [],
    this.priceCompareCards = const [],
    this.ingredientPlanCards = const [],
    this.cartCard,
    this.richContentReady = true,
  });

  final bool isUser;
  final String text;
  final DateTime at;
  final List<Map<String, dynamic>> storeCards;
  final List<Map<String, dynamic>> productCards;
  final List<Map<String, dynamic>> priceCompareCards;
  final List<Map<String, dynamic>> ingredientPlanCards;
  final Map<String, dynamic>? cartCard;
  final bool richContentReady;

  _SnurreUiMessage copyWith({String? text, bool? richContentReady}) {
    return _SnurreUiMessage(
      isUser: isUser,
      text: text ?? this.text,
      at: at,
      storeCards: storeCards,
      productCards: productCards,
      priceCompareCards: priceCompareCards,
      ingredientPlanCards: ingredientPlanCards,
      cartCard: cartCard,
      richContentReady: richContentReady ?? this.richContentReady,
    );
  }
}

final RouteObserver<PageRoute<dynamic>> snurreRouteObserver =
    RouteObserver<PageRoute<dynamic>>();

class SnurreChatSession {
  SnurreChatSession._();

  static final SnurreChatSession instance = SnurreChatSession._();
  final _messages = <_SnurreUiMessage>[];
  int? conversationId;

  void clear() {
    _messages.clear();
    conversationId = null;
  }
}

class _FadingDotsIndicator extends StatefulWidget {
  @override
  State<_FadingDotsIndicator> createState() => _FadingDotsIndicatorState();
}

class _FadingDotsIndicatorState extends State<_FadingDotsIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _dot(int index) {
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        index * 0.18,
        0.64 + index * 0.18,
        curve: Curves.easeInOut,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(opacity: 0.25 + (animation.value * 0.75), child: child);
      },
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: ScSaasThemeTokens.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dot(0),
        const SizedBox(width: 4),
        _dot(1),
        const SizedBox(width: 4),
        _dot(2),
      ],
    );
  }
}

class _SnurreChatScreenState extends State<SnurreChatScreen> with RouteAware {
  final SnurreRepo _repo = SnurreRepo();
  final SnurreChatSession _session = SnurreChatSession.instance;
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _inputFocus = FocusNode();

  bool _sending = false;
  bool _landingOffersLoading = false;
  List<SwipeCardModel> _landingOffers = [];
  int _typingGeneration = 0;
  PageRoute<dynamic>? _route;

  static List<String> get _suggestionPrompts => [
    languages.snurreSuggestion1,
    languages.snurreSuggestion2,
  ];

  @override
  void initState() {
    super.initState();
    snurreChatRouteOnTop.value = true;
    snurreLauncherVisible.value = false;
    if (widget.draftFromHomeSearch.isNotEmpty) {
      _input.text = widget.draftFromHomeSearch;
    }
    _inputFocus.addListener(_onInputFocusChanged);
    _bootstrapSession();
    _loadLandingOffers();
  }

  List<_SnurreUiMessage> get _messages => _session._messages;

  int? get _conversationId => _session.conversationId;

  set _conversationId(int? value) => _session.conversationId = value;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic> && _route != route) {
      if (_route != null) {
        snurreRouteObserver.unsubscribe(this);
      }
      _route = route;
      snurreRouteObserver.subscribe(this, route);
      snurreChatRouteOnTop.value = route.isCurrent;
      refreshSnurreLauncherVisibility(route);
    }
  }

  /// Register home-screen address + cart with Snurre before the first user message.
  Future<void> _bootstrapSession() async {
    if (prefGetString(prefAccessToken) == '' || prefGetInt(prefUserId) == 0) {
      return;
    }
    try {
      final raw = await _repo.postContext();
      if (!mounted || raw is! Map) return;
      if ((raw['status'] ?? 0) != 1) return;
    } catch (_) {
      // Chat still works; each message sends lat/long from prefs.
    }
  }

  Future<void> _loadLandingOffers() async {
    if (_landingOffersLoading) return;
    setState(() => _landingOffersLoading = true);
    try {
      final ll = prefGetLatLngForStoreSearch();
      final raw = await SwipeAerendRepo().callHareSwipeApi(
        ll.latitude,
        ll.longitude,
      );
      if (!mounted) return;
      final parsed = HareSwipeListPojo.fromJson(raw);
      setState(() {
        _landingOffers = parsed.status == 1
            ? parsed.swipeList.where((e) => e.productId > 0).take(4).toList()
            : [];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _landingOffers = []);
    } finally {
      if (mounted) {
        setState(() => _landingOffersLoading = false);
      }
    }
  }

  void _onInputFocusChanged() {
    if (_inputFocus.hasFocus) {
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _typingGeneration++;
    if (_route != null) {
      snurreRouteObserver.unsubscribe(this);
    }
    _inputFocus.removeListener(_onInputFocusChanged);
    _inputFocus.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didPush() {
    snurreChatRouteOnTop.value = true;
    refreshSnurreLauncherVisibility(_route);
  }

  @override
  void didPopNext() {
    snurreChatRouteOnTop.value = true;
    refreshSnurreLauncherVisibility(_route);
  }

  @override
  void didPushNext() {
    snurreChatRouteOnTop.value = false;
    refreshSnurreLauncherVisibility(snurreLauncherNavigatorObserver.topRoute);
  }

  @override
  void didPop() {
    snurreChatRouteOnTop.value = false;
    refreshSnurreLauncherVisibility(snurreLauncherNavigatorObserver.topRoute);
  }

  String get _screenTitle => '${languages.appName} AI';

  bool get _showLanding => _messages.isEmpty;

  Future<void> _sendMessage([String? override]) async {
    final text = (override ?? _input.text).trim();
    if (text.isEmpty || _sending) return;

    if (prefGetString(prefAccessToken) == '' || prefGetInt(prefUserId) == 0) {
      openSimpleSnackbar(languages.snurreLoginRequired);
      return;
    }

    setState(() {
      _messages.add(
        _SnurreUiMessage(isUser: true, text: text, at: DateTime.now()),
      );
      _input.clear();
      _sending = true;
    });
    _scrollToBottom();

    try {
      final raw = await _repo.postChat(
        message: text,
        conversationId: _conversationId,
      );
      if (!mounted) return;

      if (raw is! Map) {
        throw Exception('Invalid response');
      }
      final map = Map<String, dynamic>.from(raw);
      final status = map['status'];
      final ok = status == 1 || status == 1.0;
      if (!ok) {
        final msg = map['message']?.toString() ?? 'Request failed';
        throw Exception(msg);
      }

      final cid = map['conversation_id'];
      if (cid is int) {
        _conversationId = cid;
      } else if (cid != null) {
        _conversationId = int.tryParse(cid.toString());
      }

      final assistantRaw = _blocksToPlainText(map['blocks']);
      final assistantText = _stripLightMarkdown(assistantRaw);
      final storeCards = _extractStoreCardBlocks(map['blocks']);
      final productCards = _extractProductCardBlocks(map['blocks']);
      final priceCompareCards = _extractPriceCompareCardBlocks(map['blocks']);
      final ingredientPlanCards = _extractIngredientPlanCardBlocks(
        map['blocks'],
      );
      final cartCard = _extractCartCardBlock(map['blocks']);
      final hasRichContent =
          storeCards.isNotEmpty ||
          productCards.isNotEmpty ||
          priceCompareCards.isNotEmpty ||
          ingredientPlanCards.isNotEmpty ||
          cartCard != null;
      final displayText = assistantText.isEmpty
          ? (hasRichContent ? 'Here is what I found:' : '...')
          : assistantText;
      final messageIndex = _messages.length;
      final generation = ++_typingGeneration;
      setState(() {
        _sending = false;
        _messages.add(
          _SnurreUiMessage(
            isUser: false,
            text: '',
            at: DateTime.now(),
            storeCards: storeCards,
            productCards: productCards,
            priceCompareCards: priceCompareCards,
            ingredientPlanCards: ingredientPlanCards,
            cartCard: cartCard,
            richContentReady: false,
          ),
        );
      });
      _scrollToBottom();
      await _animateAssistantMessage(
        messageIndex: messageIndex,
        fullText: displayText,
        generation: generation,
      );
    } catch (e) {
      if (mounted) {
        openSimpleSnackbar(e.toString());
        setState(() {
          if (_messages.isNotEmpty && _messages.last.isUser) {
            _messages.removeLast();
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
      _scrollToBottom();
    }
  }

  Future<void> _animateAssistantMessage({
    required int messageIndex,
    required String fullText,
    required int generation,
  }) async {
    if (messageIndex < 0 || messageIndex >= _messages.length) return;

    final chunkSize = fullText.length > 220 ? 2 : 1;
    for (var i = chunkSize; i <= fullText.length; i += chunkSize) {
      await Future<void>.delayed(const Duration(milliseconds: 18));
      if (generation != _typingGeneration) return;
      final visible = fullText.substring(0, i.clamp(0, fullText.length));
      if (!mounted) {
        _messages[messageIndex] = _messages[messageIndex].copyWith(
          text: fullText,
          richContentReady: true,
        );
        return;
      }
      setState(() {
        _messages[messageIndex] = _messages[messageIndex].copyWith(
          text: visible,
          richContentReady: false,
        );
      });
      if (i % 12 == 0) _scrollToBottom();
    }

    if (generation != _typingGeneration) return;
    if (!mounted) {
      _messages[messageIndex] = _messages[messageIndex].copyWith(
        text: fullText,
        richContentReady: true,
      );
      return;
    }
    setState(() {
      _messages[messageIndex] = _messages[messageIndex].copyWith(
        text: fullText,
        richContentReady: true,
      );
    });
    _scrollToBottom();
  }

  void _finishChat() {
    _typingGeneration++;
    setState(() {
      _session.clear();
      _input.clear();
      _sending = false;
    });
    Navigator.of(context).maybePop();
  }

  String _blocksToPlainText(dynamic blocks) {
    if (blocks is! List) return '';
    final buf = StringBuffer();
    for (final b in blocks) {
      if (b is Map && b['type'] == 'text' && b['text'] != null) {
        if (buf.isNotEmpty) buf.writeln();
        buf.write(b['text']);
      }
    }
    return buf.toString().trim();
  }

  String _stripLightMarkdown(String s) {
    if (s.isEmpty) return s;
    var t = s;
    t = t.replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1');
    t = t.replaceAll(RegExp(r'\*([^*]+)\*'), r'$1');
    t = t.replaceAll(RegExp(r'__([^_]+)__'), r'$1');
    t = t.replaceAll(RegExp(r'`([^`]+)`'), r'$1');
    t = t.replaceAll(RegExp(r'^[ \t]{0,3}[-*+][ \t]+', multiLine: true), '• ');
    t = t.replaceAll(RegExp(r'^[ \t]*#{1,6}[ \t]*', multiLine: true), '');
    return t.trim();
  }

  List<Map<String, dynamic>> _extractStoreCardBlocks(dynamic blocks) {
    if (blocks is! List) return [];
    final out = <Map<String, dynamic>>[];
    for (final b in blocks) {
      if (b is Map && b['type'] == 'store_card') {
        out.add(Map<String, dynamic>.from(b));
      }
    }
    return out;
  }

  List<Map<String, dynamic>> _extractProductCardBlocks(dynamic blocks) {
    if (blocks is! List) return [];
    final out = <Map<String, dynamic>>[];
    for (final b in blocks) {
      if (b is Map && b['type'] == 'product_card') {
        out.add(Map<String, dynamic>.from(b));
      }
    }
    return out;
  }

  Map<String, dynamic>? _extractCartCardBlock(dynamic blocks) {
    if (blocks is! List) return null;
    for (final b in blocks) {
      if (b is Map && b['type'] == 'cart_card') {
        return Map<String, dynamic>.from(b);
      }
    }
    return null;
  }

  List<Map<String, dynamic>> _extractPriceCompareCardBlocks(dynamic blocks) {
    if (blocks is! List) return [];
    final out = <Map<String, dynamic>>[];
    for (final b in blocks) {
      if (b is Map && b['type'] == 'price_compare_card') {
        out.add(Map<String, dynamic>.from(b));
      }
    }
    return out;
  }

  List<Map<String, dynamic>> _extractIngredientPlanCardBlocks(dynamic blocks) {
    if (blocks is! List) return [];
    final out = <Map<String, dynamic>>[];
    for (final b in blocks) {
      if (b is Map && b['type'] == 'ingredient_plan_card') {
        out.add(Map<String, dynamic>.from(b));
      }
    }
    return out;
  }

  Future<void> _addProductToCart({
    required int storeId,
    required int productId,
    required int serviceCategoryId,
  }) async {
    if (storeId < 1 || productId < 1) {
      openSimpleSnackbar(languages.snurreProductUnavailable);
      return;
    }
    final svcId = serviceCategoryId > 0
        ? serviceCategoryId
        : prefGetInt(prefSelectedServiceCateId);
    try {
      final raw = await OrderCartRepo().callAddCartApi(
        storeId,
        svcId,
        productId,
        1,
      );
      if (!mounted) return;
      if (raw is! Map) {
        openSimpleSnackbar(languages.snurreCouldNotAddToCart);
        return;
      }
      final response = UserOrderCartPojo.fromJson(
        Map<String, dynamic>.from(raw),
      );
      if (response.messageCode == 1) {
        prefSetInt(prefCartCount, response.countOrder);
        final homeState = context.findAncestorStateOfType<HomeMainV1State>();
        homeState?.badgeCountNotifier.value = response.countOrder;
        openSimpleSnackbar(languages.snurreAddedToCart);
        return;
      }
      openSimpleSnackbar(
        response.message.isNotEmpty
            ? response.message
            : languages.snurreCouldNotAddToCart,
      );
    } catch (e) {
      if (mounted) openSimpleSnackbar(e.toString());
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final p = _scroll.position;
      p.jumpTo(p.minScrollExtent);
    });
  }

  /// First item sits nearest the composer ([ListView.reverse]).
  List<Widget> _chatScrollChildren() {
    final children = <Widget>[];

    if (_sending) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Row(
            children: [
              _FadingDotsIndicator(),
              const SizedBox(width: 10),
              Text(
                'Snurre is thinking...',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: ScSaasThemeTokens.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    for (var i = _messages.length - 1; i >= 0; i--) {
      children.add(_buildBubble(_messages[i]));
    }

    if (_showLanding) {
      children.add(const SizedBox(height: 16));
      for (var i = _suggestionPrompts.length - 1; i >= 0; i--) {
        children.add(_buildSuggestionTile(_suggestionPrompts[i]));
      }
      children.add(const SizedBox(height: 12));
      children.add(
        Row(
          children: [
            const Icon(
              Icons.auto_awesome,
              color: ScSaasThemeTokens.primary,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              'Ask With AI',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: ScSaasThemeTokens.text,
              ),
            ),
          ],
        ),
      );
      children.add(const SizedBox(height: 28));
      if (_landingOffersLoading || _landingOffers.isNotEmpty) {
        children.add(_buildLandingOfferGrid());
        children.add(const SizedBox(height: 16));
        children.add(
          Text(
            'Live exclusive offers near you',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: ScSaasThemeTokens.text,
              height: 1.25,
            ),
          ),
        );
        children.add(const SizedBox(height: 20));
      }
      children.add(_buildHeroLogo());
    }

    return children;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: ScSaasThemeTokens.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: ScSaasThemeTokens.background,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: ScSaasThemeTokens.shadowCard,
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: ScSaasThemeTokens.text, size: 20),
            ),
          ),
        ),
        centerTitle: true,
        title: Text(_screenTitle, style: aeH3()),
        actions: [
          TextButton(
            onPressed: _finishChat,
            child: Text(languages.snurreClose, style: aeLabel(color: ScSaasThemeTokens.primary)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scroll,
              reverse: true,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: _chatScrollChildren(),
            ),
          ),
          _buildComposer(bottomInset),
        ],
      ),
    );
  }

  Widget _buildHeroLogo() {
    return Center(
      child: Container(
        width: 112,
        height: 112,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: ScSaasThemeTokens.primary,
          boxShadow: [
            BoxShadow(
              color: Color(0x337F5FC4),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: ColorFiltered(
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            child: Image.asset(
              'assets/Logo/aerend_mark_coral.png',
              width: 52,
              height: 52,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLandingOfferGrid() {
    if (_landingOffersLoading && _landingOffers.isEmpty) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.05,
        children: List.generate(4, (_) => _buildOfferSkeletonCard()),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: _landingOffers.map(_buildLandingOfferCard).toList(),
    );
  }

  Widget _buildOfferSkeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color: ScSaasThemeTokens.card,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: ScSaasThemeTokens.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const Spacer(),
          Container(
            height: 12,
            width: double.infinity,
            decoration: BoxDecoration(
              color: ScSaasThemeTokens.muted.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 10,
            width: 90,
            decoration: BoxDecoration(
              color: ScSaasThemeTokens.muted.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandingOfferCard(SwipeCardModel offer) {
    final discount = offer.discountPercent > 0
        ? '-${offer.discountPercent}%'
        : '';
    final price = offer.amount > 0
        ? 'NOK ${offer.amount.toStringAsFixed(offer.amount == offer.amount.roundToDouble() ? 0 : 2)}'
        : '';

    void openStore() {
      if (offer.storeId < 1) {
        openSimpleSnackbar(languages.snurreStoreUnavailable);
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => StoreDetail(
            storeId: offer.storeId,
            storeName: offer.storeName.isEmpty ? 'Store' : offer.storeName,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: openStore,
      child: Container(
        decoration: AeSurface.card(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 38,
                      height: 38,
                      child: offer.productImage.isNotEmpty
                          ? LoadImageSimple(
                              image: offer.productImage,
                              imageFit: BoxFit.cover,
                              width: 38,
                              height: 38,
                            )
                          : Container(
                              color: ScSaasThemeTokens.primary.withValues(
                                alpha: 0.12,
                              ),
                              child: const Icon(
                                Icons.local_offer_rounded,
                                color: ScSaasThemeTokens.primary,
                                size: 22,
                              ),
                            ),
                    ),
                  ),
                  const Spacer(),
                  if (discount.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: ScSaasThemeTokens.primary.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(discount,
                          style: aeCaption(color: ScSaasThemeTokens.primary)
                              .copyWith(fontWeight: FontWeight.w800, fontSize: 11)),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                offer.productName.isEmpty
                    ? 'Eksklusivt tilbud'
                    : offer.productName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: aeTitle(),
              ),
              const SizedBox(height: 4),
              Text(
                offer.storeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: aeCaption(),
              ),
              if (price.isNotEmpty) const SizedBox(height: 4),
              Row(
                children: [
                  if (price.isNotEmpty)
                    Expanded(
                      child: Text(price,
                          overflow: TextOverflow.ellipsis,
                          style: aeLabel(color: ScSaasThemeTokens.primary)),
                    ),
                  const SizedBox(width: 6),
                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => _addProductToCart(
                      storeId: offer.storeId,
                      productId: offer.productId,
                      serviceCategoryId: offer.serviceCategoryId,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: ScSaasThemeTokens.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(languages.snurreBuy,
                          style: aeCaption(color: Colors.white)
                              .copyWith(fontWeight: FontWeight.w800, fontSize: 11)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  double? _parseSnurreNum(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim());
    }
    return null;
  }

  String _formatIngredientQuantity(dynamic value) {
    final n = _parseSnurreNum(value);
    if (n == null) return '1';
    if (n == n.roundToDouble()) return n.toStringAsFixed(0);
    if (n >= 10) return n.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
    return n
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0$'), '')
        .replaceFirst(RegExp(r'\.0$'), '');
  }

  Future<void> _openCart({bool checkout = false}) async {
    final screen = checkout ? const CheckOut() : const OrderCart();
    await openScreenWithResult(context, screen);
  }

  String _formatCount(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K';
    }
    return '$n';
  }

  Widget _buildSuggestionTile(String line) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _sendMessage(line),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: AeSurface.card(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(child: Text(line, style: aeLabel())),
              const Icon(Icons.chevron_right_rounded,
                  color: ScSaasThemeTokens.gray500, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBubble(_SnurreUiMessage m) {
    final time = TimeOfDay.fromDateTime(m.at).format(context);
    if (m.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.82,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: const BoxDecoration(
            color: ScSaasThemeTokens.primary,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(m.text, style: aeBody(color: Colors.white)),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: aeCaption(color: Colors.white70).copyWith(fontSize: 11),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.done_all_rounded,
                    size: 16,
                    color: Color(0xFF22C55E),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final cardWidth = MediaQuery.sizeOf(context).width * 0.88;
    final showTextBubble = m.text.trim().isNotEmpty;
    final hasRichCards =
        m.richContentReady &&
        (m.storeCards.isNotEmpty ||
            m.productCards.isNotEmpty ||
            m.priceCompareCards.isNotEmpty ||
            m.ingredientPlanCards.isNotEmpty ||
            m.cartCard != null);
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showTextBubble)
            Container(
              margin: EdgeInsets.only(bottom: hasRichCards ? 10 : 12),
              constraints: BoxConstraints(maxWidth: cardWidth),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: ScSaasThemeTokens.gray50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                ),
                boxShadow: ScSaasThemeTokens.shadowCard,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.text, style: aeBody()),
                  const SizedBox(height: 6),
                  Text(time, style: aeCaption().copyWith(fontSize: 11)),
                ],
              ),
            ),
          if (m.richContentReady && m.productCards.isEmpty)
            for (final block in m.storeCards)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: cardWidth,
                  child: _buildApiStoreCard(block),
                ),
              ),
          if (m.richContentReady)
            for (final block in m.productCards)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: cardWidth,
                  child: _buildApiProductCard(block),
                ),
              ),
          if (m.richContentReady)
            for (final block in m.priceCompareCards)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: cardWidth,
                  child: _buildPriceCompareCard(block),
                ),
              ),
          if (m.richContentReady)
            for (final block in m.ingredientPlanCards)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: cardWidth,
                  child: _buildIngredientPlanCard(block),
                ),
              ),
          if (m.richContentReady && m.cartCard != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: cardWidth,
                child: _buildCartSummaryCard(m.cartCard!),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCartSummaryCard(Map<String, dynamic> block) {
    final linesRaw = block['lines'];
    final lines = <Map<String, dynamic>>[];
    if (linesRaw is List) {
      for (final row in linesRaw) {
        if (row is Map) {
          lines.add(Map<String, dynamic>.from(row));
        }
      }
    }
    final total = _parseSnurreNum(block['total']);
    final currency = (block['currency_symbol'] ?? '').toString();
    final isEmpty = lines.isEmpty;

    String formatMoney(double? value) {
      if (value == null) return '';
      final decimals = value == value.roundToDouble() ? 0 : 2;
      final n = value.toStringAsFixed(decimals);
      return currency.isNotEmpty ? '$currency$n' : n;
    }

    return Material(
      color: ScSaasThemeTokens.card,
      elevation: 2,
      shadowColor: ScSaasThemeTokens.text.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Your cart',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: ScSaasThemeTokens.text,
              ),
            ),
            const SizedBox(height: 10),
            if (isEmpty)
              Text(
                'No items in your cart.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: ScSaasThemeTokens.muted,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              ...lines.map((line) {
                final name = (line['name'] ?? line['product_name'] ?? '')
                    .toString()
                    .trim();
                final qty = _parseSnurreNum(line['quantity'])?.round() ?? 0;
                final imageUrl = (line['image_url'] ?? '').toString().trim();
                final lineTotal = _parseSnurreNum(
                  line['line_total'] ?? line['line_amount'],
                );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: imageUrl.isNotEmpty
                              ? LoadImageSimple(
                                  image: imageUrl,
                                  imageFit: BoxFit.cover,
                                  width: 44,
                                  height: 44,
                                )
                              : Container(
                                  color: const Color(0xFFE8E4F2),
                                  child: const Icon(
                                    Icons.shopping_bag_outlined,
                                    color: Color(0xFF9B8FC4),
                                    size: 22,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.isEmpty ? 'Item' : name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: ScSaasThemeTokens.text,
                              ),
                            ),
                            if (qty > 0)
                              Text(
                                'Qty $qty',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: ScSaasThemeTokens.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (line['snurre_flag_review'] == true)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF1D6),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Review substitution',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: const Color(0xFF9A5B00),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (lineTotal != null)
                        Text(
                          formatMoney(lineTotal),
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: ScSaasThemeTokens.primary,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            if (!isEmpty) ...[
              Divider(
                height: 1,
                color: ScSaasThemeTokens.muted.withValues(alpha: 0.25),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                Text(
                  'Total',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: ScSaasThemeTokens.text,
                  ),
                ),
                const Spacer(),
                Text(
                  formatMoney(total ?? (isEmpty ? 0 : null)),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: ScSaasThemeTokens.primary,
                  ),
                ),
              ],
            ),
            if (!isEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _openCart(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ScSaasThemeTokens.primary,
                        side: const BorderSide(
                          color: ScSaasThemeTokens.primary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(languages.viewCart),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _openCart(checkout: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ScSaasThemeTokens.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(languages.checkOut),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCompareCard(Map<String, dynamic> block) {
    final product = (block['product_name'] ?? '').toString().trim();
    final store = (block['store_name'] ?? '').toString().trim();
    final source = (block['competitor_source'] ?? '').toString().trim();
    final competitorTitle = (block['competitor_title'] ?? '').toString().trim();
    final currency = (block['currency'] ?? 'NOK').toString();
    final reenPrice = _parseSnurreNum(block['reen_price']);
    final competitorPrice = _parseSnurreNum(block['competitor_price']);
    final delta = _parseSnurreNum(block['delta']);
    final productId = int.tryParse(block['product_id']?.toString() ?? '') ?? 0;
    final storeId = int.tryParse(block['store_id']?.toString() ?? '') ?? 0;
    final isStale = block['is_stale'] == true;

    String money(double? value) {
      if (value == null) return '—';
      final decimals = value == value.roundToDouble() ? 0 : 2;
      return '$currency ${value.toStringAsFixed(decimals)}';
    }

    void openStore() {
      if (storeId < 1) {
        openSimpleSnackbar(languages.snurreStoreUnavailable);
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => StoreDetail(
            storeId: storeId,
            storeName: store.isEmpty ? 'Store' : store,
          ),
        ),
      );
    }

    final sourceLabel = source.isEmpty
        ? 'External'
        : source[0].toUpperCase() + source.substring(1).toLowerCase();

    return Material(
      color: ScSaasThemeTokens.card,
      elevation: 2,
      shadowColor: ScSaasThemeTokens.text.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1EDF8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.shopping_basket_rounded,
                    color: ScSaasThemeTokens.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.isEmpty ? 'Price comparison' : product,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: ScSaasThemeTokens.text,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFB020),
                            size: 16,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              store.isEmpty ? 'Price comparison' : store,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: ScSaasThemeTokens.muted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(
              height: 1,
              color: ScSaasThemeTokens.muted.withValues(alpha: 0.18),
            ),
            _buildPriceCompareRow(
              sourceKey: 'aerend',
              label: 'Price Ærend',
              price: money(reenPrice),
            ),
            Divider(
              height: 1,
              color: ScSaasThemeTokens.muted.withValues(alpha: 0.18),
            ),
            _buildPriceCompareRow(
              sourceKey: source,
              label: 'Price $sourceLabel',
              price: money(competitorPrice),
              subtitle: competitorTitle,
            ),
            if (isStale) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'External price may be outdated - refresh failed',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
            ],
            if (delta != null) const SizedBox(height: 6),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: storeId > 0 && productId > 0
                        ? () => _addProductToCart(
                            storeId: storeId,
                            productId: productId,
                            serviceCategoryId: 0,
                          )
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ScSaasThemeTokens.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(languages.snurreBuyNow),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: storeId > 0 ? openStore : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ScSaasThemeTokens.primary,
                      side: const BorderSide(color: ScSaasThemeTokens.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(languages.snurreVisitStore),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientPlanCard(Map<String, dynamic> block) {
    final servings = _parseSnurreNum(block['servings'])?.round() ?? 2;
    final mealsRaw = block['meals'];
    final ingredientsRaw = block['ingredients'];
    final pantryRaw = block['pantry_skipped'];
    final meals = <Map<String, dynamic>>[];
    if (mealsRaw is List) {
      for (final row in mealsRaw) {
        if (row is Map) meals.add(Map<String, dynamic>.from(row));
      }
    }
    final ingredients = <Map<String, dynamic>>[];
    if (ingredientsRaw is List) {
      for (final row in ingredientsRaw) {
        if (row is Map) ingredients.add(Map<String, dynamic>.from(row));
      }
    }
    final pantry = <String>[];
    if (pantryRaw is List) {
      for (final item in pantryRaw) {
        final s = item?.toString().trim() ?? '';
        if (s.isNotEmpty) pantry.add(s);
      }
    }

    return Material(
      color: ScSaasThemeTokens.card,
      elevation: 2,
      shadowColor: ScSaasThemeTokens.text.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Shopping list',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: ScSaasThemeTokens.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${ingredients.length} items · $servings servings',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: ScSaasThemeTokens.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (meals.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Meals',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: ScSaasThemeTokens.text,
                ),
              ),
              const SizedBox(height: 6),
              ...meals.take(6).map((meal) {
                final name = (meal['name'] ?? '').toString().trim();
                final day = (meal['day'] ?? '').toString().trim();
                final label = day.isNotEmpty ? '$day — $name' : name;
                if (label.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ScSaasThemeTokens.muted,
                    ),
                  ),
                );
              }),
            ],
            const SizedBox(height: 10),
            Divider(
              height: 1,
              color: ScSaasThemeTokens.muted.withValues(alpha: 0.18),
            ),
            const SizedBox(height: 8),
            ...ingredients.take(14).map((row) {
              final label = (row['label'] ?? row['name'] ?? '')
                  .toString()
                  .trim();
              final qty = _formatIngredientQuantity(row['quantity']);
              final unit = (row['unit'] ?? 'pcs').toString().trim();
              if (label.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: ScSaasThemeTokens.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$qty $unit $label',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: ScSaasThemeTokens.text,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (ingredients.length > 14)
              Text(
                '+ ${ingredients.length - 14} more items',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: ScSaasThemeTokens.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (pantry.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Pantry (not added): ${pantry.take(4).join(', ')}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: ScSaasThemeTokens.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCompareRow({
    required String sourceKey,
    required String label,
    required String price,
    String subtitle = '',
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          _buildPriceSourceLogo(sourceKey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: ScSaasThemeTokens.text,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (subtitle.isNotEmpty) const SizedBox(width: 8),
          Text(
            price,
            textAlign: TextAlign.right,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: ScSaasThemeTokens.text,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSourceLogo(String sourceKey) {
    final key = sourceKey.toLowerCase();
    Color background;
    Color foreground;
    Widget child;

    if (key == 'wolt') {
      background = const Color(0xFF00C2E8);
      foreground = Colors.white;
      child = Text(
        'wolt',
        style: GoogleFonts.plusJakartaSans(
          color: foreground,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      );
    } else if (key == 'zalando') {
      background = const Color(0xFFFF6900);
      foreground = Colors.white;
      child = Icon(Icons.play_arrow_rounded, color: foreground, size: 17);
    } else {
      background = ScSaasThemeTokens.primary.withValues(alpha: 0.14);
      foreground = ScSaasThemeTokens.primary;
      child = Icon(Icons.storefront_rounded, color: foreground, size: 18);
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }

  Widget _buildApiStoreCard(Map<String, dynamic> block) {
    final storeId = int.tryParse(block['store_id']?.toString() ?? '') ?? 0;
    final name = (block['name'] ?? block['store_name'] ?? '').toString().trim();
    final subtitle = (block['subtitle'] ?? '').toString().trim();
    final snurreAction = (block['snurre_action'] ?? '').toString().trim();
    final selectionMessage = (block['selection_message'] ?? '')
        .toString()
        .trim();
    final buttonLabel = (block['button_label'] ?? '').toString().trim();
    final isMealPlanSelection =
        snurreAction == 'select_meal_plan_store' && selectionMessage.isNotEmpty;
    final imageUrl = (block['image_url'] ?? block['store_banner'] ?? '')
        .toString()
        .trim();
    final isOpen =
        block['is_open'] == true ||
        block['is_open'] == 1 ||
        block['is_open'] == 1.0 ||
        block['store_status'] == 1;

    void openStore() {
      if (storeId < 1) {
        openSimpleSnackbar(languages.snurreStoreUnavailable);
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => StoreDetail(
            storeId: storeId,
            storeName: name.isEmpty ? 'Store' : name,
          ),
        ),
      );
    }

    void selectStoreForMealPlan() {
      if (selectionMessage.isEmpty) {
        openSimpleSnackbar(languages.snurreStoreSelectionUnavailable);
        return;
      }
      _sendMessage(selectionMessage);
    }

    final primaryAction = isMealPlanSelection
        ? selectStoreForMealPlan
        : openStore;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: ScSaasThemeTokens.card,
          elevation: 0,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: primaryAction,
            child: SizedBox(
              height: 92,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 112,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (imageUrl.isNotEmpty)
                            LoadImageSimple(
                              image: imageUrl,
                              imageFit: BoxFit.cover,
                              width: 112,
                              height: 92,
                            )
                          else
                            Container(
                              color: const Color(0xFFE8E4F2),
                              child: const Icon(
                                Icons.storefront_rounded,
                                color: Color(0xFF9B8FC4),
                                size: 34,
                              ),
                            ),
                          Positioned(
                            left: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isOpen
                                    ? const Color(0xFF008E18)
                                    : const Color(0xFF94A3B8),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(6),
                                ),
                              ),
                              child: Text(
                                isOpen ? 'Open' : 'Closed',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name.isEmpty ? 'Store' : name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: ScSaasThemeTokens.text,
                              height: 1.2,
                            ),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: const Color(0xFFA9A6AE),
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: primaryAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: ScSaasThemeTokens.primary,
              foregroundColor: Colors.white,
              elevation: 3,
              shadowColor: ScSaasThemeTokens.primary.withValues(alpha: 0.25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              buttonLabel.isNotEmpty
                  ? buttonLabel
                  : (isMealPlanSelection ? 'Select Store' : languages.snurreVisitStore),
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApiProductCard(Map<String, dynamic> block) {
    final productId = int.tryParse(block['product_id']?.toString() ?? '') ?? 0;
    final storeId = int.tryParse(block['store_id']?.toString() ?? '') ?? 0;
    final serviceCategoryId =
        int.tryParse(block['service_category_id']?.toString() ?? '') ?? 0;
    final name = (block['name'] ?? block['product_name'] ?? '')
        .toString()
        .trim();
    final storeName = (block['store_name'] ?? '').toString().trim();
    final imageUrl = (block['image_url'] ?? block['product_image'] ?? '')
        .toString()
        .trim();
    final price = block['price'];
    final originalPrice = block['original_price'];
    final discountAmount = _parseSnurreNum(block['discount_amount']);
    final discountPercent = _parseSnurreNum(block['discount_percent']);
    final rating = _parseSnurreNum(block['rating']);
    final ratingsCount = _parseSnurreNum(block['ratings_count']);
    final currency = (block['currency_symbol'] ?? '').toString();

    void openStore() {
      if (storeId < 1) {
        openSimpleSnackbar(languages.snurreStoreUnavailable);
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => StoreDetail(
            storeId: storeId,
            storeName: storeName.isEmpty ? 'Store' : storeName,
          ),
        ),
      );
    }

    String priceLabel = '';
    if (price is num) {
      priceLabel = currency.isNotEmpty
          ? '$currency${price.toStringAsFixed(price == price.roundToDouble() ? 0 : 2)}'
          : price.toStringAsFixed(price == price.roundToDouble() ? 0 : 2);
    }
    String originalPriceLabel = '';
    if (originalPrice is num && originalPrice > 0 && originalPrice != price) {
      originalPriceLabel = currency.isNotEmpty
          ? '$currency${originalPrice.toStringAsFixed(originalPrice == originalPrice.roundToDouble() ? 0 : 2)}'
          : originalPrice.toStringAsFixed(
              originalPrice == originalPrice.roundToDouble() ? 0 : 2,
            );
    }
    String discountLabel = '';
    if (discountPercent != null && discountPercent > 0) {
      discountLabel = '-${discountPercent.round()}%';
    } else if (discountAmount != null && discountAmount > 0) {
      final decimals = discountAmount == discountAmount.roundToDouble() ? 0 : 2;
      discountLabel = '-$currency${discountAmount.toStringAsFixed(decimals)}';
    }

    String ratingLabel = '';
    if (rating != null && rating > 0) {
      final count = ratingsCount ?? 0;
      ratingLabel = count > 0
          ? '${rating.toStringAsFixed(1)} (${_formatCount(count.round())})'
          : rating.toStringAsFixed(1);
    }

    final pillShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(28),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: ScSaasThemeTokens.card,
          elevation: 2,
          shadowColor: ScSaasThemeTokens.text.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: imageUrl.isNotEmpty
                        ? LoadImageSimple(
                            image: imageUrl,
                            imageFit: BoxFit.cover,
                            width: 56,
                            height: 56,
                          )
                        : Container(
                            color: const Color(0xFFE8E4F2),
                            child: const Icon(
                              Icons.fastfood_rounded,
                              color: Color(0xFF9B8FC4),
                              size: 28,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? 'Product' : name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: ScSaasThemeTokens.text,
                        ),
                      ),
                      if (storeName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.storefront_rounded,
                              color: ScSaasThemeTokens.primary,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                storeName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: ScSaasThemeTokens.muted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (ratingLabel.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFBBF24),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              ratingLabel,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: ScSaasThemeTokens.muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (priceLabel.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (discountLabel.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            discountLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              color: const Color(0xFF15803D),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        priceLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: ScSaasThemeTokens.primary,
                        ),
                      ),
                      if (originalPriceLabel.isNotEmpty)
                        Text(
                          originalPriceLabel,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: ScSaasThemeTokens.muted,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: ScSaasThemeTokens.muted,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: productId < 1
                    ? null
                    : () => _addProductToCart(
                        storeId: storeId,
                        productId: productId,
                        serviceCategoryId: serviceCategoryId,
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ScSaasThemeTokens.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: pillShape,
                ),
                child: Text(
                  languages.snurreBuyNow,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: openStore,
                style: OutlinedButton.styleFrom(
                  foregroundColor: ScSaasThemeTokens.primary,
                  side: const BorderSide(
                    color: ScSaasThemeTokens.primary,
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: pillShape,
                ),
                child: Text(
                  languages.snurreVisitStore,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComposer(double bottomPad) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + bottomPad),
      decoration: BoxDecoration(
        color: ScSaasThemeTokens.background,
        border: Border(top: BorderSide(color: ScSaasThemeTokens.gray100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: AeSurface.card(
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: _input,
                focusNode: _inputFocus,
                scrollPadding: EdgeInsets.zero,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                style: aeBody(),
                decoration: InputDecoration(
                  hintText: languages.snurreWriteMessage,
                  hintStyle: aeCaption(color: ScSaasThemeTokens.gray500),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sending ? null : () => _sendMessage(),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _sending
                    ? ScSaasThemeTokens.primaryDisabled
                    : ScSaasThemeTokens.primary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: _sending ? null : ScSaasThemeTokens.shadowButton,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
