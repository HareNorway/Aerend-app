import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:focus_detector/focus_detector.dart';
import 'package:flutter/cupertino.dart';
import 'package:aerend_customer/theme/app_ui.dart';
import 'package:aerend_customer/dialogs/reviewDialog/review_dialog_repo.dart';
import 'package:aerend_customer/screens/common/home/home_repo.dart';
import 'package:aerend_customer/screens/common/swipeAerend/swipe_aerend_dl.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:aerend_customer/screens/deliveryService/storeDetail/store_detail.dart';
import 'package:aerend_customer/screens/deliveryService/home/ds_home.dart';
import 'package:aerend_customer/screens/common/manageAddress/manage_address_dl.dart';
import 'package:aerend_customer/screens/deliveryService/storeDetail/widget_topping_option.dart';
import 'package:aerend_customer/screens/deliveryService/storeDetail/widget_size_color.dart';
import 'package:aerend_customer/screens/deliveryService/trackOrder/track_order.dart';
import 'package:aerend_customer/screens/common/homeMainV1/home_main_v1.dart';
import 'package:aerend_customer/screens/deliveryService/searchStore/search_store.dart';
import 'package:aerend_customer/screens/snurre/snurre_chat_screen.dart';
import 'package:aerend_customer/screens/snurre/snurre_launcher_policy.dart';
import 'package:aerend_customer/utils/discount_star.dart';
import 'package:aerend_customer/theme/sc_saas_theme.dart';

import '../../../commonView/common_view.dart';
import '../../../commonView/no_record_found.dart';
import '../../../commonView/surface_decorations.dart';

import '../../common/swipeAerend/swipe_aerend.dart';
import '../../../networking/api_base_helper.dart';
import '../../../utils/guest_auth_helper.dart';
import '../../../utils/utils.dart';
import '../login/login.dart';
import '../location/add_location.dart';
import 'home_bloc.dart';
import 'home_dl.dart';
import 'home_v1_shimmer.dart';
import '../../deliveryService/storeDetail/add_on_repo.dart';
import '../../feed/feed_shell_screen.dart';

class HomeV1 extends StatefulWidget {
  final bool isShowDialog;
  final bool isHareExplore;
  final int orderId;

  const HomeV1({
    super.key,
    this.isShowDialog = false,
    this.isHareExplore = false,
    this.orderId = 0,
  });

  @override
  HomeV1State createState() => HomeV1State();
}

class HomeV1State extends State<HomeV1>
    with AutomaticKeepAliveClientMixin<HomeV1> {
  late HomeBloc _bloc;
  Timer? timer;

  bool isExpanded = false;

  List checkedToppingList = [];
  List checkedOptionsList = [];
  int prodQuantity = 1;
  bool inStock = true;
  String addOnsMessage = '';
  final TextEditingController _homeSearchController = TextEditingController();

  void _openSearchScreen([String? rawQuery]) {
    final String keyword = (rawQuery ?? _homeSearchController.text).trim();
    final homeState = context.findAncestorStateOfType<HomeMainV1State>();
    if (homeState != null) {
      homeState.openSearchTab(keyword: keyword);
      return;
    }
    openScreen(context, SearchStore(latLng: prefGetLatLng(), keyword: keyword));
  }

  void _openSnurreScreen() {
    openScreen(
      context,
      SnurreChatScreen(draftFromHomeSearch: _homeSearchController.text.trim()),
    );
  }

  void _openFeedScreen() {
    openScreen(context, const FeedShellScreen());
  }

  openFeedbackModal() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        int amount = 3;
        bool submitting = false;
        final ThemeData theme = Theme.of(dialogContext);
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              backgroundColor:
                  theme.dialogTheme.backgroundColor ??
                  theme.colorScheme.surfaceContainerHigh,
              surfaceTintColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      languages.homeFeedbackTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    onPressed: submitting
                        ? null
                        : () => Navigator.pop(dialogContext),
                    icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
                  ),
                ],
              ),
              content: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  AbsorbPointer(
                    absorbing: submitting,
                    child: Opacity(
                      opacity: submitting ? 0.45 : 1,
                      child: Builder(
                        builder: (context) {
                          final double panelW =
                              (MediaQuery.sizeOf(context).width - 40).clamp(
                                260.0,
                                520.0,
                              );
                          final double starSize = ((panelW - 32) / 5).clamp(
                            24.0,
                            40.0,
                          );
                          return SingleChildScrollView(
                            child: SizedBox(
                              width: panelW,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    languages.homeFeedbackBody,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.75),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: List.generate(
                                      5,
                                      (index) => Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () async {
                                            setState(() {
                                              amount = index + 1;
                                              submitting = true;
                                            });
                                            try {
                                              await ReviewDialogRepo()
                                                  .callOrderRatingApi(
                                                    widget.orderId,
                                                    amount.toDouble(),
                                                    null,
                                                    null,
                                                    null,
                                                  );
                                              final response = await HomeRepo()
                                                  .addProductRateApi(
                                                    widget.orderId,
                                                    index + 1,
                                                  );
                                              if (response['status'] == 1 &&
                                                  dialogContext.mounted) {
                                                Navigator.pop(dialogContext);
                                              }
                                            } catch (e) {
                                              debugPrint(
                                                "openFeedbackModal: $e",
                                              );
                                            } finally {
                                              if (dialogContext.mounted) {
                                                setState(
                                                  () => submitting = false,
                                                );
                                              }
                                            }
                                          },
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(4),
                                            child: LoadImageSimple(
                                              image: index < amount
                                                  ? 'assets/images/active_star.png'
                                                  : 'assets/images/inactive_star.png',
                                              width: starSize,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  if (submitting)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ColoredBox(
                          color: theme.colorScheme.surface.withOpacity(0.88),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: ScSaasThemeTokens.primary,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    languages.processing,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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

  openFeedbackModal1() {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        List<String> stateList = ['none', 'none'];
        return AlertDialog(
          content: Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: deviceWidth * 0.4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "We need your opinion!",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const Text(
                      "Help others decide what the best to order in the restaurant",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorMainGray, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    StatefulBuilder(
                      builder: (context, setVote) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const LoadImageSimple(
                              image: 'assets/images/products/cruch.png',
                              width: 32,
                              height: 32,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Cruch Rush Pizza',
                              style: TextStyle(fontSize: 16),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => setVote(() => stateList[0] = 'down'),
                              child: LoadImageSimple(
                                image: stateList[0] == 'down'
                                    ? 'assets/images/icons/downvote_red.png'
                                    : 'assets/images/icons/downvote_gray.png',
                                width: 32,
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () => setVote(() => stateList[0] = 'up'),
                              child: LoadImageSimple(
                                image: stateList[0] == 'up'
                                    ? 'assets/images/icons/upvote_red.png'
                                    : 'assets/images/icons/upvote_gray.png',
                                width: 32,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    StatefulBuilder(
                      builder: (context, setVote) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const LoadImageSimple(
                              image: 'assets/images/products/cruch.png',
                              width: 32,
                              height: 32,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Cruch Rush Pizza',
                              style: TextStyle(fontSize: 16),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => setVote(() => stateList[1] = 'down'),
                              child: LoadImageSimple(
                                image: stateList[1] == 'down'
                                    ? 'assets/images/icons/downvote_red.png'
                                    : 'assets/images/icons/downvote_gray.png',
                                width: 32,
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () => setVote(() => stateList[1] = 'up'),
                              child: LoadImageSimple(
                                image: stateList[1] == 'up'
                                    ? 'assets/images/icons/upvote_red.png'
                                    : 'assets/images/icons/upvote_gray.png',
                                width: 32,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  openFeedbackModal2() {
    const List<String> feedbackOptions = <String>[
      'Very Professional',
      'Arrive on Time',
      'Safety and Hygiene',
      'Handed Gently',
    ];

    return showDialog<List<dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        int amount = 3;
        String comment = "";
        final ThemeData theme = Theme.of(dialogContext);

        Widget starRow(StateSetter setState, double maxWidth) {
          final double safeW = maxWidth.isFinite && maxWidth > 0
              ? maxWidth
              : 280.0;
          final double starSize = ((safeW - 32) / 5).clamp(22.0, 40.0);
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              5,
              (index) => Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => amount = index + 1),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: LoadImageSimple(
                      image: index < amount
                          ? 'assets/images/active_star.png'
                          : 'assets/images/inactive_star.png',
                      width: starSize,
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        Widget optionChip(
          String label,
          double chipWidth,
          StateSetter setState,
        ) {
          final bool selected = comment == label;
          return SizedBox(
            width: chipWidth,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => comment = label),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? colorPrimary.withOpacity(0.12)
                        : colorMainBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? colorPrimary : Colors.transparent,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? colorPrimary : colorMainGray,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return AlertDialog(
          backgroundColor:
              theme.dialogTheme.backgroundColor ??
              theme.colorScheme.surfaceContainerHigh,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  "Rate a courrier",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                onPressed: () =>
                    Navigator.pop(dialogContext, <dynamic>[amount, comment]),
                icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
              ),
            ],
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              final double panelW = (MediaQuery.sizeOf(context).width - 40)
                  .clamp(260.0, 520.0);
              const double gap = 8;
              final double chipW = panelW > 280 ? (panelW - gap) / 2 : panelW;
              return SingleChildScrollView(
                child: SizedBox(
                  width: panelW,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Our courier will appreciate your ratings!",
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.75),
                        ),
                      ),
                      const SizedBox(height: 12),
                      starRow(setState, panelW),
                      const SizedBox(height: 16),
                      Text(
                        "Leave a feedback",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        alignment: WrapAlignment.center,
                        children: feedbackOptions
                            .map((label) => optionChip(label, chipW, setState))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, <dynamic>[amount, comment]),
              child: Text(languages.skip),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, <dynamic>[amount, comment]),
              child: Text(languages.submit),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _bloc = HomeBloc(context, this, widget.isHareExplore);
    timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _bloc.callHomeTrackOrderApi();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.orderId != 0) {
        openFeedbackModal().then((_) {
          openFeedbackModal2().then((Object? result) {
            if (result is! List || result.length < 2) return;
            final num? stars = result[0] as num?;
            final String driverComment = result[1]?.toString() ?? '';
            if (stars == null) return;
            ReviewDialogRepo().callOrderRatingApi(
              widget.orderId,
              null,
              stars.toDouble(),
              null,
              driverComment.isEmpty ? null : driverComment,
            );
          });
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    _bloc = HomeBloc(context, this, widget.isHareExplore);
    timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _bloc.callHomeTrackOrderApi();
    });
    if (isDemoApp) {
      if (widget.isShowDialog) _bloc.openDemoDialog();
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    stopTimer();
    _homeSearchController.dispose();
    _bloc.dispose();
    super.dispose();
  }

  stopTimer() {
    if (timer != null && timer!.isActive) {
      timer?.cancel();
      timer = null;
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final r = context.responsive;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color heroBackgroundColor = isDark
        ? ScSaasThemeTokens.primaryDarkMode
        : ScSaasThemeTokens.primary;
    final double headerActionSize = r.sizeValue(72, min: 64, max: 82);
    final double headerSideInset =
        headerActionSize + r.sizeValue(UiSpacing.md, min: 10, max: 16);
    return FocusDetector(
      onFocusLost: () {
        scContext = null;
      },
      child: Scaffold(
        backgroundColor: ScSaasThemeTokens.backgroundLavender,
        appBar: AppBar(
          elevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          toolbarHeight: r.h(0.1, min: 80, max: 94),
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: isDark ? null : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF6B4FA8), Color(0xFF7F5FC4), Color(0xFF9B7FD4)],
              ),
              color: isDark ? heroBackgroundColor : null,
            ),
          ),
          title: Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: r.h(0.085, min: 62, max: 76),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Levering til',
                      style: aeCaption(color: Colors.white70).copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20.0),
                              topRight: Radius.circular(20.0),
                            ),
                          ),
                          builder: (BuildContext context) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20.0),
                                  topRight: Radius.circular(20.0),
                                ),
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Center(
                                    child: Container(
                                      width: 44,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: ScSaasThemeTokens.border,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Center(
                                    child: Text(languages.homeLocation, style: aeH2()),
                                  ),
                                  const SizedBox(height: 35),
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          _bloc.getCurrentLocation();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                            horizontal: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? ScSaasThemeTokens.accent
                                                      .withOpacity(0.2)
                                                : ScSaasThemeTokens.accentSoft,
                                            border: Border.all(
                                              width: 1,
                                              color: ScSaasThemeTokens.accent,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                CustomIcons.gps,
                                                color: ScSaasThemeTokens.primary,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(languages.homeCurrent,
                                                  style: aeLabel(
                                                      color: ScSaasThemeTokens
                                                          .primary)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: () async {
                                          if (isGuestUser()) {
                                            final authed =
                                                await showGuestLoginSheet(
                                                  context,
                                                  prompt:
                                                      GuestLoginPrompt.address,
                                                );
                                            if (!context.mounted || !authed) {
                                              return;
                                            }
                                          }
                                          openScreenWithResult(
                                            context,
                                            const AddLocation(),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                            horizontal: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.surface,
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: ScSaasThemeTokens.border
                                                    .withOpacity(0.85),
                                                spreadRadius: 0,
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.add,
                                                color:
                                                    Theme.of(
                                                          context,
                                                        ).brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : colorBlack,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                'New Location',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      Theme.of(
                                                            context,
                                                          ).brightness ==
                                                          Brightness.dark
                                                      ? Colors.white
                                                      : colorBlack,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  // const Divider(),
                                  // GestureDetector(
                                  //   onTap: () => openScreenWithResult(
                                  //       context, const ExploreCity()),
                                  //   child: Row(
                                  //     children: const [
                                  //       Icon(Icons.menu),
                                  //       SizedBox(width: 15),
                                  //       Text(
                                  //         'Browse All Ærend City',
                                  //         style: TextStyle(
                                  //             fontWeight: FontWeight.bold),
                                  //       )
                                  //     ],
                                  //   ),
                                  // ),
                                  const Divider(),
                                  const SizedBox(height: 5),
                                  StreamBuilder(
                                    stream: _bloc.addressList,
                                    builder: (context, snapshot) {
                                      List<AddressListItem> addressList =
                                          snapshot.data ?? [];
                                      return addressList.isEmpty
                                          ? const Expanded(
                                              child: NoRecordFound(
                                                message: "No address saved",
                                              ),
                                            )
                                          : Expanded(
                                              child: ListView(
                                                children: List.generate(
                                                  addressList.length,
                                                  (index) => _savedAddressItem(
                                                    addressList[index],
                                                  ),
                                                ),
                                              ),
                                            );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: headerSideInset,
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: r.sizeValue(
                              UiSpacing.md,
                              min: 10,
                              max: 14,
                            ),
                            vertical: r.sizeValue(
                              UiSpacing.xxs,
                              min: 2,
                              max: 4,
                            ),
                          ),
                          decoration: BoxDecoration(
                            color: ScSaasThemeTokens.card.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(
                              r.sizeValue(UiRadius.pill, min: 20, max: 28),
                            ),
                            border: Border.all(
                              color: ScSaasThemeTokens.card.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: ScSaasThemeTokens.card,
                                size: 20.0,
                              ),
                              SizedBox(
                                width: r.sizeValue(
                                  UiSpacing.sm,
                                  min: 6,
                                  max: 10,
                                ),
                              ),
                              StreamBuilder(
                                stream: _bloc.deliveryAddress,
                                builder: (context, snapshot) {
                                  AddressListItem defaultAddress =
                                      AddressListItem(address: 'Velg Adresse');
                                  String addressString = prefGetString(
                                    prefNewDeliveryAddress,
                                  );

                                  if (addressString.isNotEmpty) {
                                    defaultAddress = AddressListItem.fromJson(
                                      jsonDecode(addressString),
                                    );
                                  }
                                  AddressListItem deliveryAddress =
                                      snapshot.data ?? defaultAddress;

                                  return ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: r.w(0.34, min: 120, max: 220),
                                    ),
                                    child: Text(
                                      deliveryAddress.address.split(',')[0],
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: r.text(
                                          UiTypography.bodyLarge - 1,
                                          min: 13,
                                          max: 16,
                                        ),
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
                                        color: ScSaasThemeTokens.card,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 16,
                child: GestureDetector(
                  onTap: () {
                    openScreenWithReplacePrevious(context, const SwipeReen());
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/svgs/cursor_hand.svg',
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                          height: 18,
                        ),
                        const SizedBox(height: 2),
                        Text(languages.homeSwipe,
                            style: aeCaption(color: Colors.white).copyWith(
                                fontSize: 9, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
              if (isGuestUser())
                Positioned(
                  right: r.w(0.04, min: 12, max: 20),
                  top: r.h(0.012, min: 6, max: 12),
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          settings: RouteSettings(
                            name: snurreLauncherRouteNameFor(const Login()),
                          ),
                          builder: (_) => const Login(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: ScSaasThemeTokens.card,
                      backgroundColor: ScSaasThemeTokens.card.withValues(
                        alpha: 0.14,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      languages.signIn,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: r.text(13, min: 12, max: 14),
                        color: ScSaasThemeTokens.card,
                      ),
                    ),
                  ),
                ),
              StreamBuilder<ApiResponse<HomeTrackOrderPojo>>(
                stream: _bloc.subjectTrackOrder,
                builder: (context, snapshot) {
                  var data = snapshot.data;
                  int? orderId = snapshot.data?.data?.orderId;
                  if (data != null && orderId != null) {
                    int remainingTime = snapshot.data!.data!.remainingTime;
                    return Positioned(
                      right: 15,
                      child: GestureDetector(
                        onTap: () {
                          openScreen(context, TrackOrder(orderId: orderId));
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50.0),
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              Container(
                                decoration: const BoxDecoration(
                                  color: colorWhite,
                                  shape: BoxShape.circle,
                                ),
                                width: 70,
                                height: 70,
                                child: Image.asset(
                                  'assets/images/tracking.png',
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              Positioned(
                                bottom: -45,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: const BoxDecoration(
                                    color: ScSaasThemeTokens.primaryHover,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 5,
                                child: Text(
                                  '${remainingTime}min',
                                  style: const TextStyle(
                                    color: colorWhite,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return Container();
                },
              ),
            ],
          ),
        ),
        body: Container(
          color: ScSaasThemeTokens.backgroundLavender,
          child: _buildHome(context),
        ),
      ),
    );
  }

  Widget _savedAddressItem(AddressListItem address) {
    bool selected = address.addressId == prefGetInt(prefNewDeliveryAddressId);
    return GestureDetector(
      onTap: () {
        _bloc.updateDeliveryAddress(addressId: address.addressId);
        Navigator.pop(context);
      },
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? ScSaasThemeTokens.primary : colorMainGray,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${prefGetString(prefUserName)} | ${prefGetString(prefCountryCode)} ${prefGetString(prefContactNumber)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      address.address,
                      softWrap: true,
                      style: const TextStyle(
                        fontSize: 15,
                        color: colorMainGray,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 15,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? (Theme.of(context).brightness == Brightness.dark
                                  ? ScSaasThemeTokens.primary.withOpacity(0.2)
                                  : ScSaasThemeTokens.rowHover)
                            : Theme.of(context).colorScheme.surface,
                        border: Border.all(
                          width: 1,
                          color: selected
                              ? ScSaasThemeTokens.primary
                              : colorMainGray,
                        ),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Text(
                        capitalize(address.type),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: selected
                              ? ScSaasThemeTokens.primaryHover
                              : colorMainGray,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  _bloc.deleteAddress(address.addressId);
                },
                child: Icon(
                  Icons.delete_outlined,
                  color: selected
                      ? ScSaasThemeTokens.primaryHover
                      : colorMainGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildHome(BuildContext context) {
    final r = context.responsive;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color heroBackgroundColor = isDark
        ? ScSaasThemeTokens.primaryDarkMode
        : ScSaasThemeTokens.primary;
    bool isNormalDelivery = false;
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: ScSaasThemeTokens.backgroundLavender,
          ),
          child: Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(),
            child: ListView(
              children: [
                if (widget.isHareExplore == false)
                  Container(
                    width: double.infinity,
                    color: heroBackgroundColor,
                    child: Column(
                      children: [
                        SizedBox(
                          height: r.sizeValue(UiSpacing.xl, min: 16, max: 24),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            decoration: AeSurface.shiny(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: TextField(
                              controller: _homeSearchController,
                              textInputAction: TextInputAction.search,
                              onSubmitted: _openSearchScreen,
                              style: const TextStyle(
                                color: ScSaasThemeTokens.text,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                filled: true,
                                fillColor: Colors.transparent,
                                hintText: languages.heroSearchStoresProducts,
                                hintStyle: aeCaption(color: ScSaasThemeTokens.gray500),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: ScSaasThemeTokens.muted,
                                ),
                                suffixIcon: IconButton(
                                  tooltip: 'Ask Snurre',
                                  onPressed: _openSnurreScreen,
                                  icon: Container(
                                    width: r.sizeValue(34, min: 30, max: 38),
                                    height: r.sizeValue(34, min: 30, max: 38),
                                    decoration: BoxDecoration(
                                      color: ScSaasThemeTokens.primary,
                                      borderRadius: BorderRadius.circular(
                                        r.sizeValue(
                                          UiRadius.md,
                                          min: 10,
                                          max: 14,
                                        ),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.auto_awesome,
                                      color: ScSaasThemeTokens.card,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: r.sizeValue(8, min: 6, max: 12),
                                  vertical: r.sizeValue(14, min: 12, max: 16),
                                ),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                  borderRadius: BorderRadius.circular(
                                    r.sizeValue(
                                      UiRadius.pill,
                                      min: 16,
                                      max: 22,
                                    ),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                  borderRadius: BorderRadius.circular(
                                    r.sizeValue(
                                      UiRadius.pill,
                                      min: 16,
                                      max: 22,
                                    ),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: ScSaasThemeTokens.primary,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    r.sizeValue(
                                      UiRadius.pill,
                                      min: 16,
                                      max: 22,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: r.sizeValue(UiSpacing.lg, min: 10, max: 16),
                        ),
                        SizedBox(
                          height: r.sizeValue(330, min: 280, max: 360),
                          width: r.sizeValue(330, min: 280, max: 360),
                          child: StreamBuilder<ApiResponse<HomeCatePojo>>(
                            stream: _bloc.subjectHomeCat,
                            builder: (context, snap) {
                              Widget shimmer = Center(
                                child: Container(
                                  width: r.sizeValue(85, min: 72, max: 95),
                                  height: r.sizeValue(85, min: 72, max: 95),
                                  decoration: BoxDecoration(
                                    color: colorWhite.withOpacity(0.22),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: LoadImageSimple(
                                      width: r.sizeValue(40, min: 34, max: 46),
                                      height: r.sizeValue(40, min: 34, max: 46),
                                      image: 'assets/Logo/reen/mark-coral-navy.png',
                                    ),
                                  ),
                                ),
                              );

                              List<ServicesItem> serviceList =
                                  snap.data?.data?.services ?? [];

                              switch (snap.data?.status) {
                                case Status.loading:
                                  return shimmer;
                                case Status.completed:
                                  if (serviceList.isNotEmpty) {
                                    return _categoryList(serviceList);
                                  } else {
                                    return SizedBox(
                                      height: deviceHeight * 0.9,
                                      width: deviceWidth * 0.9,
                                      child: NoRecordFound(
                                        message: languages.noRecordFound,
                                      ),
                                    );
                                  }
                                case Status.error:
                                default:
                                  return SizedBox(
                                    height: deviceWidth * 0.6,
                                    child: Error(
                                      onRetryPressed: () {
                                        _bloc.onRefresh();
                                      },
                                    ),
                                  );
                              }
                            },
                          ),
                        ),
                        SizedBox(
                          height: r.sizeValue(UiSpacing.xl, min: 16, max: 24),
                        ),
                      ],
                    ),
                  ),
                Container(
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(
                        r.sizeValue(UiRadius.md, min: 12, max: 18),
                      ),
                    ),
                  ),
                  child: RefreshIndicator(
                    onRefresh: () {
                      return _bloc.onRefresh();
                    },
                    child: Column(
                      children: [
                        SizedBox(
                          height: r.sizeValue(UiSpacing.sm, min: 6, max: 12),
                        ),
                        StatefulBuilder(
                          builder: (context, setState) {
                            final toggleWidth = r.w(0.42, min: 145, max: 210);
                            final toggleRadius = r.sizeValue(
                              UiRadius.pill,
                              min: 24,
                              max: 34,
                            );
                            final iconWrapSize = r.sizeValue(
                              37,
                              min: 34,
                              max: 42,
                            );
                            final iconSize = r.sizeValue(30, min: 24, max: 32);
                            return ResponsiveCard(
                              color: Theme.of(context).colorScheme.surface,
                              radius: UiRadius.pill,
                              minRadius: 24,
                              maxRadius: 34,
                              padding: UiSpacing.sm,
                              minPadding: 6,
                              maxPadding: 10,
                              border: Border.all(
                                color: ScSaasThemeTokens.border,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: ScSaasThemeTokens.primary.withOpacity(
                                    0.08,
                                  ),
                                  blurRadius: r.sizeValue(
                                    UiSpacing.xl,
                                    min: 12,
                                    max: 20,
                                  ),
                                  offset: Offset(
                                    0,
                                    r.sizeValue(UiSpacing.sm, min: 4, max: 8),
                                  ),
                                ),
                              ],
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        isNormalDelivery = false;
                                      });
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(
                                        r.sizeValue(
                                          UiSpacing.xxs,
                                          min: 2,
                                          max: 4,
                                        ),
                                      ),
                                      width: toggleWidth,
                                      decoration: BoxDecoration(
                                        color: isNormalDelivery
                                            ? ScSaasThemeTokens.rowHover
                                            : ScSaasThemeTokens.primary,
                                        borderRadius: BorderRadius.circular(
                                          toggleRadius,
                                        ),
                                        border: Border.all(
                                          color: isNormalDelivery
                                              ? ScSaasThemeTokens.border
                                              : ScSaasThemeTokens.primary,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(
                                              r.sizeValue(
                                                UiSpacing.xxs,
                                                min: 2,
                                                max: 3,
                                              ),
                                            ),
                                            width: iconWrapSize,
                                            height: iconWrapSize,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color:
                                                  Theme.of(
                                                        context,
                                                      ).brightness ==
                                                      Brightness.dark
                                                  ? Colors.grey[800]
                                                  : ScSaasThemeTokens.card,
                                            ),
                                            child: SvgPicture.asset(
                                              'assets/svgs/delivery/local.svg',
                                              height: iconSize,
                                            ),
                                          ),
                                          const ResponsiveGap(
                                            UiSpacing.xs,
                                            axis: Axis.horizontal,
                                            min: 4,
                                            max: 8,
                                          ),
                                          Text(
                                            'Lokal levering',
                                            style: TextStyle(
                                              color: isNormalDelivery
                                                  ? (Theme.of(
                                                              context,
                                                            ).brightness ==
                                                            Brightness.dark
                                                        ? Colors.white
                                                        : colorBlack)
                                                  : ScSaasThemeTokens.card,
                                              fontSize: r.text(
                                                UiTypography.bodyLarge - 1,
                                                min: 13,
                                                max: 16,
                                              ),
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        // isNormalDelivery = true;
                                      });
                                    },
                                    child: Stack(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(
                                            r.sizeValue(
                                              UiSpacing.xxs,
                                              min: 2,
                                              max: 4,
                                            ),
                                          ),
                                          width: toggleWidth,
                                          decoration: BoxDecoration(
                                            color: isNormalDelivery
                                                ? ScSaasThemeTokens.primary
                                                : Theme.of(
                                                    context,
                                                  ).scaffoldBackgroundColor,
                                            borderRadius: BorderRadius.circular(
                                              toggleRadius,
                                            ),
                                            border: Border.all(
                                              color: isNormalDelivery
                                                  ? ScSaasThemeTokens.primary
                                                  : ScSaasThemeTokens.border,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(
                                                  r.sizeValue(
                                                    UiSpacing.xs,
                                                    min: 4,
                                                    max: 6,
                                                  ),
                                                ),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color:
                                                      Theme.of(
                                                            context,
                                                          ).brightness ==
                                                          Brightness.dark
                                                      ? Colors.grey[800]
                                                      : ScSaasThemeTokens.card,
                                                ),
                                                child: SvgPicture.asset(
                                                  'assets/svgs/delivery/normal.svg',
                                                  height: iconSize,
                                                ),
                                              ),
                                              const ResponsiveGap(
                                                UiSpacing.xs,
                                                axis: Axis.horizontal,
                                                min: 4,
                                                max: 8,
                                              ),
                                              Text(
                                                'Vanlig levering',
                                                style: TextStyle(
                                                  color: isNormalDelivery
                                                      ? ScSaasThemeTokens.card
                                                      : (Theme.of(
                                                                  context,
                                                                ).brightness ==
                                                                Brightness.dark
                                                            ? Colors.white
                                                            : colorBlack),
                                                  fontSize: r.text(
                                                    UiTypography.bodyLarge - 1,
                                                    min: 13,
                                                    max: 16,
                                                  ),
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Positioned(
                                          top: r.sizeValue(
                                            UiSpacing.md - UiSpacing.xxs,
                                            min: 8,
                                            max: 12,
                                          ),
                                          right: 0,
                                          child: Transform.rotate(
                                            angle: 10 * 3.141592653589793 / 180,
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: r.sizeValue(
                                                  UiSpacing.xs + UiSpacing.xxs,
                                                  min: 5,
                                                  max: 8,
                                                ),
                                                vertical: r.sizeValue(
                                                  UiSpacing.xxs,
                                                  min: 2,
                                                  max: 4,
                                                ),
                                              ),
                                              decoration: BoxDecoration(
                                                color: ScSaasThemeTokens
                                                    .primaryDarkMode,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      r.sizeValue(
                                                        UiRadius.md,
                                                        min: 10,
                                                        max: 14,
                                                      ),
                                                    ),
                                              ),
                                              child: Text(
                                                'Coming Soon',
                                                style: TextStyle(
                                                  color: ScSaasThemeTokens.card,
                                                  fontSize: r.text(
                                                    UiTypography.caption,
                                                    min: 11,
                                                    max: 13,
                                                  ),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const ResponsiveGap(UiSpacing.sm, min: 8, max: 14),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: r.w(0.05, min: 14, max: 26),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _categoryHeader(context, 'Eksklusive tilbud'),
                              const ResponsiveGap(
                                UiSpacing.sm,
                                min: 8,
                                max: 14,
                              ),
                              StreamBuilder<ApiResponse<HareSwipeListPojo>>(
                                stream: _bloc.subjectHareSwipe,
                                builder: (context, snap) {
                                  var isLoading =
                                      snap.hasData &&
                                      snap.data?.status == Status.loading;

                                  List<SwipeCardModel> swipeList =
                                      snap.data?.data?.swipeList ?? [];

                                  switch (snap.data?.status) {
                                    case Status.loading:
                                      return HomeBannerShimmer(
                                        enabled: isLoading,
                                      );
                                    case Status.completed:
                                      if (swipeList.isNotEmpty) {
                                        return RepaintBoundary(
                                          child: _ExclusiveOfferPagedCarousel(
                                            key: ValueKey(
                                              swipeList
                                                  .map((e) => e.productId)
                                                  .join(','),
                                            ),
                                            items: swipeList,
                                            itemBuilder: (ctx, item) =>
                                                _exclusiveOfferSlide(ctx, item),
                                          ),
                                        );
                                      } else {
                                        return SizedBox(
                                          height: deviceHeight * 0.2,
                                          child: NoRecordFound(
                                            message: "No Exclusive Offer found",
                                            height: deviceHeight * 0.1,
                                          ),
                                        );
                                      }
                                    case Status.error:
                                    default:
                                      return SizedBox(
                                        height: deviceHeight * 0.2,
                                        child: NoRecordFound(
                                          message: "No Exclusive Offer found",
                                          height: deviceHeight * 0.1,
                                        ),
                                      );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        StreamBuilder<ApiResponse<HareExplorePojo>>(
                          stream: _bloc.subjectHareExplore,
                          builder: (context, snap) {
                            var isLoading =
                                snap.hasData &&
                                snap.data?.status == Status.loading;

                            List<HareStoreListItems> lunchList =
                                snap.data?.data?.lunchList ?? [];
                            List<HareStoreListItems> fastList =
                                snap.data?.data?.fastList ?? [];

                            final double exploreSidePad = r.w(
                              0.05,
                              min: 14,
                              max: 26,
                            );

                            switch (snap.data?.status) {
                              case Status.loading:
                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: exploreSidePad,
                                  ),
                                  child: HomeBannerShimmer(enabled: isLoading),
                                );
                              case Status.completed:
                                return Column(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: exploreSidePad,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          _categoryHeader(
                                            context,
                                            'Lunsj i nærheten',
                                            expandPossible: true,
                                          ),
                                          if (lunchList.isNotEmpty)
                                            RepaintBoundary(
                                              child: CarouselSlider(
                                                options: CarouselOptions(
                                                  autoPlay: true,
                                                  aspectRatio: 1.3,
                                                  enlargeCenterPage: true,
                                                ),
                                                items: lunchList
                                                    .map(
                                                      (
                                                        store,
                                                      ) => GestureDetector(
                                                        onTap: () => openScreen(
                                                          context,
                                                          StoreDetail(
                                                            storeId:
                                                                store.storeId,
                                                            storeName:
                                                                store.storeName,
                                                          ),
                                                        ),
                                                        child: _restaurantCard(
                                                          store,
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                              ),
                                            )
                                          else
                                            const SizedBox(
                                              height: 150,
                                              child: NoRecordFound(
                                                message: "No Store Found",
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.symmetric(vertical: 12),
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),
                                        color: ScSaasThemeTokens.primaryTint,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              'Nyt 14 dager uten leveringsgebyr!',
                                              style: aeTitle(color: ScSaasThemeTokens.primaryHover),
                                            ),
                                          ),
                                          const LoadImageSimple(
                                            image: 'assets/images/no_delivery_fee.svg',
                                            width: 100,
                                            imageFit: BoxFit.contain,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: exploreSidePad,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          _categoryHeader(
                                            context,
                                            'Raskest levering',
                                            expandPossible: true,
                                          ),
                                          if (fastList.isNotEmpty)
                                            CarouselSlider(
                                              options: CarouselOptions(
                                                autoPlay: true,
                                                aspectRatio: 1.3,
                                                enlargeCenterPage: true,
                                              ),
                                              items: fastList
                                                  .map(
                                                    (store) => GestureDetector(
                                                      onTap: () => openScreen(
                                                        context,
                                                        StoreDetail(
                                                          storeId:
                                                              store.storeId,
                                                          storeName:
                                                              store.storeName,
                                                        ),
                                                      ),
                                                      child: _restaurantCard(
                                                        store,
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                            )
                                          else
                                            const SizedBox(
                                              height: 150,
                                              child: NoRecordFound(
                                                message: "No Store Found",
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              case Status.error:
                              default:
                                return Container();
                            }
                          },
                        ),
                        // _categoryHeader('Retail & grocery',
                        //     expandPossible: true),
                        // SingleChildScrollView(
                        //   scrollDirection: Axis.horizontal,
                        //   child: Row(
                        //     children: [
                        //       _groceryCard('assets/images/home/fresh_mart.png',
                        //           'Happy Fresh Mart'),
                        //       _groceryCard(
                        //           'assets/images/home/smart_market.png',
                        //           'Doma Smart Market '),
                        //       _groceryCard('assets/images/home/grocery.png',
                        //           'Joyland Candy Bar'),
                        //     ],
                        //   ),
                        // ),
                        // _categoryHeader('Get to Know Us!',
                        //     expandPossible: true),
                        // SingleChildScrollView(
                        //   scrollDirection: Axis.horizontal,
                        //   child: Row(
                        //     children: [
                        //       Container(
                        //         height: deviceWidth * 0.5,
                        //         width: deviceWidth * 0.8,
                        //         margin: const EdgeInsets.all(8),
                        //         decoration: BoxDecoration(
                        //           color: colorWhite,
                        //           borderRadius:
                        //               BorderRadius.circular(deviceWidth * 0.05),
                        //         ),
                        //         child: ClipRRect(
                        //           borderRadius: const BorderRadius.all(
                        //               Radius.circular(10.0)),
                        //           child: LoadImageSimple(
                        //             width: deviceWidth * 0.8,
                        //             height: deviceWidth * 0.5,
                        //             image: 'assets/images/home/card.png',
                        //             imageFit: BoxFit.cover,
                        //           ),
                        //         ),
                        //       ),
                        //       Container(
                        //         height: deviceWidth * 0.5,
                        //         width: deviceWidth * 0.8,
                        //         margin: const EdgeInsets.all(8),
                        //         decoration: BoxDecoration(
                        //           color: colorWhite,
                        //           borderRadius:
                        //               BorderRadius.circular(deviceWidth * 0.05),
                        //         ),
                        //         child: ClipRRect(
                        //           borderRadius: const BorderRadius.only(
                        //             topLeft: Radius.circular(10.0),
                        //             topRight: Radius.circular(10.0),
                        //             bottomLeft: Radius.zero,
                        //             bottomRight: Radius.zero,
                        //           ),
                        //           child: LoadImageSimple(
                        //             width: deviceWidth * 0.8,
                        //             height: deviceWidth * 0.25,
                        //             image: 'assets/images/home/card1.png',
                        //             imageFit: BoxFit.cover,
                        //           ),
                        //         ),
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        // _categoryHeader('Good Deal Campaign',
                        //     expandPossible: true),
                        // SingleChildScrollView(
                        //   scrollDirection: Axis.horizontal,
                        //   child: Row(
                        //     children: [
                        //       _dessertCard('assets/images/home/deal.png',
                        //           'Discount For All Dessert'),
                        //       _dessertCard('assets/images/home/deal1.png',
                        //           'Get Juiced Up with All Deals!'),
                        //       _dessertCard('assets/images/home/deal2.png',
                        //           'Joyland Candy Bar'),
                        //     ],
                        //   ),
                        // ),
                        // _categoryHeader('Quick links'),
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        //   children: const [
                        //     Text('Send a gift'),
                        //     Icon(Icons.arrow_forward_ios)
                        //   ],
                        // ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // if (isDemoApp)
        //   Align(
        //     alignment: AlignmentDirectional.bottomEnd,
        //     child: GestureDetector(
        //       onTap: () {
        //         _bloc.openSupportWhatsapp();
        //       },
        //       child: Container(
        //         margin: EdgeInsetsDirectional.only(
        //             bottom: deviceHeight * 0.03, end: deviceWidth * 0.05),
        //         decoration: BoxDecoration(
        //           borderRadius:
        //               BorderRadiusDirectional.circular(deviceAverageSize * 0.1),
        //           color: const Color(0xff3DD848),
        //           boxShadow: const [
        //             BoxShadow(
        //               color: Colors.grey,
        //               offset: Offset(0.0, 1.0), //(x,y)
        //               blurRadius: 6.0,
        //             ),
        //           ],
        //         ),
        //         child: Showcase(
        //           title: languages.contactSalesPerson,
        //           description: languages.contactSalesPersonMsg,
        //           disableScaleAnimation: false,
        //           disableMovingAnimation: false,
        //           disposeOnTap: true,
        //           targetShapeBorder: const CircleBorder(),
        //           targetBorderRadius: BorderRadius.all(
        //               Radius.circular(deviceAverageSize * 0.1)),
        //           showArrow: false,
        //           onTargetClick: () {
        //             _bloc.openSupportWhatsapp();
        //           },
        //           titleTextStyle: headerText(fontWeight: FontWeight.bold),
        //           descTextStyle: bodyText(
        //               fontSize: textSizeSmallest, fontWeight: FontWeight.bold),
        //           targetPadding: EdgeInsets.all(deviceAverageSize * 0.008),
        //           key: _bloc.one,
        //           child: Padding(
        //             padding: EdgeInsets.all(deviceAverageSize * 0.02),
        //             child: Icon(
        //               CustomIcons.whatsappIcon,
        //               size: deviceAverageSize * 0.055,
        //               color: colorWhite,
        //             ),
        //           ),
        //         ),
        //       ),
        //     ),
        //   ),
      ],
    );
  }

  /// Single card per page (not peeking like Lunch carousel); dots match Figma pager.
  Widget _exclusiveOfferSlide(BuildContext context, SwipeCardModel item) {
    final r = context.responsive;
    return LayoutBuilder(
      builder: (context, constraints) {
        final double slideW = constraints.maxWidth;
        final double slideH = slideW / 2;
        final double corner = r.sizeValue(UiRadius.md, min: 12, max: 18);
        final double innerPad = r.sizeValue(UiSpacing.lg, min: 12, max: 22);
        final double logoSize = r.sizeValue(36, min: 30, max: 40);
        final double priceSize = r.text(
          UiTypography.bodyLarge,
          min: 14,
          max: 18,
        );

        return GestureDetector(
          onTap: () async {
            var response = await AddOnRepo().getToppingsAndOptions(
              item.productId,
            );
            if (!mounted) return;
            if (response['status'] == 1) {
              prefSetInt(
                prefSelectedServiceCateId,
                response['service_category_id'],
              );
              _openFoodSheet(
                context,
                item,
                response['size_list'],
                response['color_list'],
                response['options_list'],
              );
            }
          },
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(corner),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    LoadImageSimple(
                      width: slideW,
                      height: slideH,
                      image: item.productImage,
                      imageFit: BoxFit.cover,
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0x00F4F0FB),
                              Color(0x80F4F0FB),
                              Color(0xCCF4F0FB),
                              Color(0xB3F4F0FB),
                              Color(0x80F4F0FB),
                            ],
                            stops: [0.0, 0.4, 0.6, 0.8, 1.0],
                            begin: Alignment.center,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(innerPad),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(
                          r.sizeValue(UiRadius.md, min: 10, max: 16),
                        ),
                      ),
                      padding: EdgeInsets.all(
                        r.sizeValue(UiSpacing.xs, min: 4, max: 6),
                      ),
                      child: LoadImageSimple(
                        image: item.storeLogo,
                        height: logoSize,
                        width: logoSize,
                      ),
                    ),
                    const Spacer(),
                    Column(
                      children: [
                        DiscountStar(discount: item.discountPercent),
                        const Spacer(),
                        if (item.discountAmount > 0)
                          Text(
                            formatNok(item.originalAmount.toDouble()),
                            style: aeCaption(
                              color: ScSaasThemeTokens.primaryHover,
                            ).copyWith(
                              decoration: TextDecoration.lineThrough,
                              decorationColor: ScSaasThemeTokens.primaryHover,
                            ),
                          ),
                        Text(
                          formatNok(item.amount.toDouble()),
                          style: aeTitle(),
                        ),
                      ],
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

  void _openFoodSheet(
    BuildContext context,
    SwipeCardModel item,
    List sizeList,
    List colorList,
    List optionList,
  ) {
    List productImageList = item.productImageList;

    List<Widget> sliderList = productImageList
        .map(
          (item) => ClipRRect(
            borderRadius: BorderRadius.circular(20.0),
            child: LoadImageSimple(
              width: deviceWidth,
              height: deviceHeight * 0.33,
              image: '$item',
              imageFit: BoxFit.cover,
            ),
          ),
        )
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      constraints: const BoxConstraints(minWidth: double.infinity),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, setState) {
            return SizedBox(
              height: deviceHeight * 0.83,
              child: Stack(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: sliderList),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    top: deviceHeight * 0.35,
                    bottom: 80,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  item.productName,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 120,
                                child: Row(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          if (prodQuantity > 1) prodQuantity--;
                                        });
                                      },
                                      icon: Icon(
                                        Icons.remove_circle,
                                        color: prodQuantity > 1
                                            ? colorGreen
                                            : colorGreen.withOpacity(0.3),
                                        size: 27,
                                      ),
                                    ),
                                    Text(
                                      '$prodQuantity',
                                      style: const TextStyle(
                                        color: colorGreen,
                                        fontSize: 22,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          prodQuantity++;
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.add_circle,
                                        color: colorGreen,
                                        size: 27,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final textPainter = TextPainter(
                                text: TextSpan(
                                  text: item.description,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                maxLines: 2,
                                textDirection: TextDirection.ltr,
                              )..layout(maxWidth: constraints.maxWidth);
                              final isOverflowing =
                                  textPainter.didExceedMaxLines;
                              return RichText(
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: isOverflowing
                                          ? item.description.substring(
                                              0,
                                              textPainter
                                                  .getPositionForOffset(
                                                    Offset(
                                                      constraints.maxWidth -
                                                          100,
                                                      textPainter.height,
                                                    ),
                                                  )
                                                  .offset,
                                            )
                                          : item.description,
                                      style: const TextStyle(
                                        color: colorMainLightGray,
                                      ),
                                    ),
                                    if (isOverflowing)
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.middle,
                                        child: GestureDetector(
                                          onTap: () => _showDescriptionModal(
                                            context,
                                            item,
                                          ),
                                          child: const Text(
                                            "   Read More",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          const Divider(),
                          if (addOnsMessage != '')
                            Text(
                              addOnsMessage,
                              style: const TextStyle(color: colorRed),
                            ),
                          const SizedBox(height: 8),
                          if (getAddOnsType() == typeSizeColor)
                            SizeColorWidget(
                              sizeOptional: item.sizeOptional,
                              colorOptional: item.colorOptional,
                              sizeList: sizeList,
                              colorList: colorList,
                              validate: (value) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  setState(() {
                                    inStock = value;
                                  });
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
                                  print(value);
                                  setState(() {
                                    addOnsMessage = value;
                                  });
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 30,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.close,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : colorBlack,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            if (item.discountAmount > 0)
                              Text(
                                'NOK ${item.originalAmount}',
                                style: const TextStyle(
                                  color: colorPrimary,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: colorPrimary,
                                  decorationThickness: 2,
                                ),
                              ),
                            Text(
                              'NOK ${item.amount}  ',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 20),
                          height: 50,
                          width: deviceWidth * 0.6,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorGreen,
                              foregroundColor: colorWhite,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              textStyle: const TextStyle(fontSize: 20),
                            ),
                            onPressed: !inStock || addOnsMessage != ''
                                ? null
                                : () {
                                    _bloc.addOrderCart(
                                      item.storeId,
                                      item.productId,
                                      prodQuantity,
                                    );
                                    Navigator.pop(context);
                                  },
                            child: const Text(
                              'Order Now',
                              style: TextStyle(fontSize: 20),
                            ),
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
      },
    );
  }

  void _showDescriptionModal(BuildContext context, SwipeCardModel item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          content: SizedBox(
            width: deviceWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    const SizedBox(
                      height: 50,
                      child: Center(
                        child: Text(
                          "Product Details",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -10,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface,
                          elevation: 1,
                          padding: const EdgeInsets.all(10),
                          shape: const CircleBorder(),
                        ),
                        child: SvgPicture.asset(
                          'assets/svgs/icons/back.svg',
                          height: 18,
                          width: 18,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          item.storeName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: colorMainGray,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${item.amount}kr',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.description,
                  style: const TextStyle(fontSize: 14, color: colorMainGray),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget toppingCheckBoxGroup(int serviceCategoryId, List list) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: list.map((item) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (checkedToppingList.contains(item['id'])) {
                    checkedToppingList.remove(item['id']);
                  } else {
                    checkedToppingList.add(item['id']);
                  }
                });
              },
              child: Row(
                children: [
                  Icon(
                    checkedToppingList.contains(item['id'])
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    color: colorPrimary,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    item['name'],
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: checkedToppingList.contains(item['id'])
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: checkedToppingList.contains(item['id'])
                          ? null
                          : colorMainLightGray,
                    ),
                  ),
                  const Spacer(),
                  if (serviceCategoryId == 5)
                    Text(
                      "NOK ${item['amount']}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: checkedToppingList.contains(item['id'])
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: checkedToppingList.contains(item['id'])
                            ? null
                            : colorMainLightGray,
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget optionCheckBoxGroup(int serviceCategoryId, List list) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: list.map((item) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (checkedOptionsList.contains(item['id'])) {
                    checkedOptionsList.remove(item['id']);
                  } else {
                    checkedOptionsList.add(item['id']);
                  }
                });
              },
              child: Row(
                children: [
                  Icon(
                    checkedOptionsList.contains(item['id'])
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    color: colorPrimary,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    item['name'],
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: checkedOptionsList.contains(item['id'])
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: checkedOptionsList.contains(item['id'])
                          ? null
                          : colorMainLightGray,
                    ),
                  ),
                  const Spacer(),
                  if (serviceCategoryId == 5)
                    Text(
                      "NOK ${item['amount']}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: checkedOptionsList.contains(item['id'])
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: checkedOptionsList.contains(item['id'])
                            ? null
                            : colorMainLightGray,
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _categoryList(List<ServicesItem> serviceList) {
    return _ServiceWheel(
      services: serviceList,
      onServiceTap: (service) {
        setSelectedServiceInPref(
          service.serviceCategoryId,
          service.serviceCategoryName,
          service.serviceCategoryIcon,
        );
        openScreen(context, const DSHome());
      },
      onCenterTap: _openFeedScreen,
    );
  }

}

Widget _restaurantCard(HareStoreListItems storeInfo) {
  return Builder(
    builder: (context) {
      final r = context.responsive;
      return Container(
        width: r.w(0.8, min: 280, max: 420),
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: AeSurface.card(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: LoadImageSimple(
                  width: double.infinity,
                  height: double.infinity,
                  image: storeInfo.storeImage,
                  imageFit: BoxFit.cover,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(storeInfo.storeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: aeTitle()),
                    Text(storeInfo.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: aeCaption()),
                    Row(
                      children: [
                        Icon(Icons.star_rounded,
                            color: Colors.amber.shade600, size: 14),
                        const SizedBox(width: 3),
                        Text("${storeInfo.storeRating}", style: aeLabel()),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'NOK ${storeInfo.productMinAmount} – ${storeInfo.productMaxAmount}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: aeCaption(),
                          ),
                        ),
                        Icon(Icons.schedule_rounded,
                            color: ScSaasThemeTokens.gray500, size: 14),
                        const SizedBox(width: 3),
                        Text('${storeInfo.deliveryTime} min', style: aeCaption()),
                      ],
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
}

/// One offer per view with snap paging; bottom-left pill + dot indicators (Figma).
class _ExclusiveOfferPagedCarousel extends StatefulWidget {
  const _ExclusiveOfferPagedCarousel({
    super.key,
    required this.items,
    required this.itemBuilder,
  });

  final List<SwipeCardModel> items;
  final Widget Function(BuildContext context, SwipeCardModel item) itemBuilder;

  @override
  State<_ExclusiveOfferPagedCarousel> createState() =>
      _ExclusiveOfferPagedCarouselState();
}

class _ExclusiveOfferPagedCarouselState
    extends State<_ExclusiveOfferPagedCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _restartAutoPlay();
  }

  void _restartAutoPlay() {
    _autoPlayTimer?.cancel();
    if (widget.items.length <= 1) return;
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || widget.items.isEmpty) return;
      final int next = (_currentPage + 1) % widget.items.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void didUpdateWidget(covariant _ExclusiveOfferPagedCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.length != oldWidget.items.length) {
      final int last = widget.items.length - 1;
      if (_currentPage > last) {
        _currentPage = last < 0 ? 0 : last;
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_currentPage);
        }
      }
      _restartAutoPlay();
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }
    final r = context.responsive;
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final double h = w / 2;
        final double radius = r.sizeValue(UiRadius.md, min: 12, max: 18);
        final double dotLeft = r.sizeValue(UiSpacing.md, min: 12, max: 18);
        final double dotBottom = r.sizeValue(
          UiSpacing.sm + UiSpacing.xs,
          min: 10,
          max: 16,
        );
        final double dotH = r.sizeValue(
          UiSpacing.xs + UiSpacing.xxs,
          min: 5,
          max: 7,
        );
        final double dotGap = r.sizeValue(UiSpacing.xs, min: 4, max: 8);
        final double activeW = r.sizeValue(18, min: 16, max: 22);
        final double inactiveW = dotH;

        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: SizedBox(
            height: h,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: widget.items.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, index) =>
                      widget.itemBuilder(context, widget.items[index]),
                ),
                if (widget.items.length > 1)
                  Positioned(
                    left: dotLeft,
                    bottom: dotBottom,
                    child: Row(
                      children: List.generate(widget.items.length, (i) {
                        final bool active = i == _currentPage;
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _pageController.animateToPage(
                            i,
                            duration: const Duration(milliseconds: 320),
                            curve: Curves.easeOutCubic,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                            margin: EdgeInsets.only(right: dotGap),
                            height: dotH,
                            width: active ? activeW : inactiveW,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(dotH / 2),
                              color: active
                                  ? const Color(0xFF2C2C2C)
                                  : colorMainGray.withOpacity(0.45),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Widget _categoryHeader(
  BuildContext context,
  String categoryName, {
  bool expandPossible = false,
  Key? key,
}) {
  return Container(
    key: key,
    padding: const EdgeInsets.fromLTRB(0, 16, 0, 4),
    child: Text(categoryName, style: aeH2()),
  );
}

/// Shiny radial service wheel matching the design's category wheel.
class _ServiceWheel extends StatefulWidget {
  final List<ServicesItem> services;
  final void Function(ServicesItem service) onServiceTap;
  final VoidCallback onCenterTap;

  const _ServiceWheel({
    required this.services,
    required this.onServiceTap,
    required this.onCenterTap,
  });

  @override
  State<_ServiceWheel> createState() => _ServiceWheelState();
}

class _ServiceWheelState extends State<_ServiceWheel>
    with SingleTickerProviderStateMixin {
  double _rotationAngle = 0;
  late AnimationController _breatheController;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breatheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int count = widget.services.length;
    if (count == 0) return const SizedBox.shrink();

    const double outerRadius = 115;
    const double chipSize = 72;
    const double widgetSize = (outerRadius + chipSize / 2) * 2 + 8;

    return SizedBox(
      width: widgetSize,
      height: widgetSize,
      child: GestureDetector(
        onPanUpdate: (d) => setState(() => _rotationAngle += d.delta.dx * 0.005),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center orb — opens Feed
            AnimatedBuilder(
              animation: _breatheController,
              builder: (_, __) {
                final scale = 1.0 + _breatheController.value * 0.06;
                return Transform.scale(
                  scale: scale,
                  child: GestureDetector(
                    onTap: widget.onCenterTap,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: AeSurface.shinyPurple(isCircle: true),
                      child: Center(
                        child: Image.asset(
                          'assets/Logo/home-center-a-camera.png',
                          width: 32,
                          height: 24,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            // Service chips
            ...List.generate(count, (i) {
              final angle =
                  (2 * math.pi * i / count) + _rotationAngle - math.pi / 2;
              final dx = math.cos(angle) * outerRadius;
              final dy = math.sin(angle) * outerRadius;
              final service = widget.services[i];

              return Transform.translate(
                offset: Offset(dx, dy),
                child: GestureDetector(
                  onTap: () => widget.onServiceTap(service),
                  child: SizedBox(
                    width: chipSize,
                    height: chipSize + 16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: chipSize,
                          height: chipSize,
                          decoration: AeSurface.shiny(isCircle: true),
                          child: Center(
                            child: SvgPicture.network(
                              service.serviceCategoryIcon,
                              width: 26,
                              height: 26,
                              colorFilter: const ColorFilter.mode(
                                ScSaasThemeTokens.primaryHover,
                                BlendMode.srcIn,
                              ),
                              placeholderBuilder: (_) => const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          service.serviceCategoryName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: aeCaption(color: ScSaasThemeTokens.text).copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

