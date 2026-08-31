import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animarker/widgets/animarker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dashed_circular_progress_bar/dashed_circular_progress_bar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../commonView/modal_ui.dart';
import '../../../commonView/surface_decorations.dart';
import '../../../dialogs/orderCancelDialog/order_cancel_dialog.dart';
import '../../../networking/api_base_helper.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/shared_pref_utill.dart';
import '../../../utils/utils.dart';
import '../../common/chatting/chatting.dart';
import '../../common/homeMainV1/home_main_v1.dart';
import '../../dugnad/dugnad_sheet.dart';
import '../deliveriesOrderDetail/deliveries_order_detail.dart';
import 'track_order_bloc.dart';
import 'track_order_dl.dart';

class TrackOrder extends StatefulWidget {
  final int orderId;
  final bool isFromPlacedOrder, isFromNotification;

  const TrackOrder({
    super.key,
    required this.orderId,
    this.isFromPlacedOrder = false,
    this.isFromNotification = false,
  });

  @override
  TrackOrderState createState() => TrackOrderState();
}

class TrackOrderState extends State<TrackOrder> with WidgetsBindingObserver {
  TrackOrderBloc? _bloc;
  Timer? timer;
  final Completer<GoogleMapController> controller =
      Completer<GoogleMapController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bloc = TrackOrderBloc(
      context,
      widget.orderId,
      widget.isFromPlacedOrder,
      this,
    );
    _startTrackOrderPolling();
    if (prefGetInt('bookedOrderId') == widget.orderId) {
      prefSetInt('bookedOrderId', 0);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void _startTrackOrderPolling() {
    _bloc?.callTrackOrderApi(true);
    stopTimer();
    timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      _bloc?.callTrackOrderApi(false);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    stopTimer();
    _bloc?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _bloc?.callTrackOrderApi(false);
    }
  }

  stopTimer() {
    if (timer != null && timer!.isActive) {
      timer?.cancel();
      timer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color pageBg = Theme.of(context).scaffoldBackgroundColor;
    final Color textPrimary = isDark
        ? ScSaasThemeTokens.card
        : ScSaasThemeTokens.text;
    final Color textSecondary = isDark
        ? Colors.white70
        : ScSaasThemeTokens.muted;
    final Color routeBoxBg = isDark
        ? const Color(0xFF2C2C2C)
        : ScSaasThemeTokens.rowHover;
    final Color closeBtnBg = isDark
        ? const Color(0xFF383838)
        : ScSaasThemeTokens.card;
    final Color closeIconColor = isDark
        ? ScSaasThemeTokens.card
        : ScSaasThemeTokens.text;
    final Color timeTextColor = isDark
        ? Colors.white60
        : ScSaasThemeTokens.muted;
    final Color timelinePendingColor = isDark
        ? Colors.white38
        : Colors.grey.shade400;
    const Color timelineActiveColor = colorGreen;

    return WillPopScope(
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: pageBg,
            body: Column(
              children: [
                Flexible(flex: 4, child: googleMap(_bloc!)),
                Flexible(
                  flex: 6,
                  child: StreamBuilder<ApiResponse<TrackOrderPojo>>(
                    stream: _bloc!.subject,
                    builder: (context, snapshot) {
                      final ApiResponse<TrackOrderPojo>? resp = snapshot.data;
                      final TrackOrderPojo? data = resp?.data;

                      if (resp?.status == Status.error) {
                        return _trackOrderPanelError(
                          pageBg: pageBg,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          message:
                              resp?.message ??
                              languages.apiErrorUnexpectedErrorMsg,
                        );
                      }

                      if (resp == null ||
                          resp.status == Status.loading ||
                          data == null) {
                        return _trackOrderPanelLoading(
                          pageBg: pageBg,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        );
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: pageBg,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                          boxShadow: ScSaasThemeTokens.shadowDeep,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final bool trackShowStoreChat =
                                  _canOpenStoreTrackChat(data);
                              final bool trackShowDriverChat =
                                  _canOpenDriverTrackChat(data);
                              final bool trackShowChat =
                                  trackShowStoreChat || trackShowDriverChat;
                              final bool trackShowReceipt =
                                  data.userTakenType == 2 &&
                                  data.orderCurrentStatus == 6;
                              final bool trackShowCallButton =
                                  _canShowTrackOrderCallButton(data);
                              final bool tripleAction =
                                  trackShowReceipt &&
                                  trackShowChat &&
                                  trackShowCallButton;
                              final bool pairReceiptChat =
                                  trackShowReceipt &&
                                  trackShowChat &&
                                  !trackShowCallButton;
                              final bool pairReceiptCall =
                                  trackShowReceipt &&
                                  !trackShowChat &&
                                  trackShowCallButton;
                              final bool pairChatCall =
                                  !trackShowReceipt &&
                                  trackShowChat &&
                                  trackShowCallButton;
                              final content = Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Sporing",
                                        style: aeH2(color: textPrimary),
                                      ),
                                      GestureDetector(
                                        onTap: () =>
                                            openScreenWithClearPrevious(
                                              context,
                                              const HomeMainV1(),
                                            ),
                                        child: Container(
                                          height: 36,
                                          width: 36,
                                          decoration: BoxDecoration(
                                            color: closeBtnBg,
                                            shape: BoxShape.circle,
                                            boxShadow: ScSaasThemeTokens.shadowCard,
                                          ),
                                          child: Icon(
                                            Icons.close_rounded,
                                            size: 20,
                                            color: closeIconColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Container(
                                        height: 56,
                                        width: 56,
                                        margin: const EdgeInsets.only(right: 14),
                                        decoration: BoxDecoration(
                                          color: ScSaasThemeTokens.primaryTint,
                                          shape: BoxShape.circle,
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: LoadImageWithPlaceHolder(
                                          borderRadius: BorderRadius.circular(28),
                                          width: 56,
                                          height: 56,
                                          image: data.storeImage,
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(data.storeName,
                                              style: aeTitle(color: textPrimary)),
                                          const SizedBox(height: 2),
                                          Text('#${data.orderNo}',
                                              style: aeCaption(color: textSecondary)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: routeBoxBg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Flexible(
                                          flex: 1,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Fra",
                                                style: aeCaption(color: textSecondary),
                                              ),
                                              Text(data.storeName,
                                                  style: aeTitle(color: textPrimary)),
                                            ],
                                          ),
                                        ),
                                        Flexible(
                                          flex: 1,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Til",
                                                style: aeCaption(color: textSecondary),
                                              ),
                                              Text(
                                                data.userTakenType == 1
                                                    ? data.destinationAddress
                                                          .split(',')[0]
                                                    : data.pickupAddress.split(
                                                        ',',
                                                      )[0],
                                                  style: aeTitle(color: textPrimary)),
                                            ],
                                          ),
                                        ),
                                        Flexible(
                                          flex: 1,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(languages.trackEstimatedTime,
                                                  style: aeCaption(color: textSecondary)),
                                              SingleChildScrollView(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                child: Text(
                                                  data.scheduleOrderDateTime,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: ScSaasThemeTokens
                                                        .accent,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (data.otp.trim().isNotEmpty &&
                                      (data.orderCurrentStatus == 7 ||
                                          data.orderCurrentStatus == 8) &&
                                      data.userTakenType != 2)
                                    Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(top: 10),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: ScSaasThemeTokens.primaryTint,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: ScSaasThemeTokens.primary
                                              .withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(languages.trackDeliveryOtp,
                                              style: aeLabel(color: textPrimary)),
                                          Text(
                                            data.otp,
                                            style: aeMono().copyWith(
                                              fontSize: 20,
                                              letterSpacing: 3,
                                              color: ScSaasThemeTokens.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  if (data.orderCurrentStatus == 3 ||
                                      data.orderCurrentStatus == 4)
                                    Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: ScSaasThemeTokens.danger
                                            .withOpacity(isDark ? 0.18 : 0.08),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: ScSaasThemeTokens.danger
                                              .withOpacity(0.3),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data.orderCancelRejectTitle
                                                    .trim()
                                                    .isNotEmpty
                                                ? data.orderCancelRejectTitle
                                                : 'Your order is rejected',
                                            style: aeTitle(color: ScSaasThemeTokens.danger),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            data.cancelReason.trim().isNotEmpty
                                                ? data.cancelReason
                                                : languages.cancelReason,
                                            style: TextStyle(
                                              color: textPrimary,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Column(
                                              children: [
                                                const SizedBox(height: 10),
                                                Container(
                                                  width: 20,
                                                  height: 20,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        !data
                                                            .timelineAcceptComplete
                                                        ? timelinePendingColor
                                                        : timelineActiveColor,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                !data.timelineAcceptComplete
                                                    ? Container(
                                                        width: 2,
                                                        height: 40,
                                                        color:
                                                            timelinePendingColor,
                                                      )
                                                    : !data
                                                          .timelinePrepareComplete
                                                    ? Container(
                                                        width: 2,
                                                        height: 40,
                                                        decoration: BoxDecoration(
                                                          gradient: LinearGradient(
                                                            colors: [
                                                              timelineActiveColor,
                                                              Color.lerp(
                                                                timelineActiveColor,
                                                                timelinePendingColor,
                                                                0.7,
                                                              )!,
                                                              // You can add more colors as needed
                                                            ],
                                                            begin: Alignment
                                                                .topCenter,
                                                            end: Alignment
                                                                .bottomCenter,
                                                          ),
                                                        ),
                                                      )
                                                    : Container(
                                                        width: 2,
                                                        height: 40,
                                                        color:
                                                            timelineActiveColor,
                                                      ),
                                              ],
                                            ),
                                            const SizedBox(width: 20),
                                            Expanded(
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        !data.timelineAcceptComplete
                                                            ? "Venter på godkjenning"
                                                            : "Bestillingen er godkjent",
                                                        style: TextStyle(
                                                          color: textPrimary,
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        data.storeName,
                                                        style: TextStyle(
                                                          color: textPrimary,
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.normal,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Text(
                                                    data.acceptOrderTime,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      color: timeTextColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Column(
                                              children: [
                                                !data.timelineAcceptComplete
                                                    ? Container(
                                                        width: 2,
                                                        height: 10,
                                                        color:
                                                            timelinePendingColor,
                                                      )
                                                    : !data
                                                          .timelinePrepareComplete
                                                    ? Container(
                                                        width: 2,
                                                        height: 10,
                                                        decoration: BoxDecoration(
                                                          gradient: LinearGradient(
                                                            colors: [
                                                              Color.lerp(
                                                                timelineActiveColor,
                                                                timelinePendingColor,
                                                                0.7,
                                                              )!,
                                                              timelinePendingColor,
                                                            ],
                                                            begin: Alignment
                                                                .topCenter,
                                                            end: Alignment
                                                                .bottomCenter,
                                                          ),
                                                        ),
                                                      )
                                                    : Container(
                                                        width: 2,
                                                        height: 10,
                                                        color:
                                                            timelineActiveColor,
                                                      ),
                                                Container(
                                                  width: 20,
                                                  height: 20,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        !data
                                                            .timelinePrepareComplete
                                                        ? timelinePendingColor
                                                        : timelineActiveColor,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                data.userTakenType == 2
                                                    ? Container()
                                                    : !data
                                                          .timelinePrepareComplete
                                                    ? Container(
                                                        width: 2,
                                                        height: 40,
                                                        color:
                                                            timelinePendingColor,
                                                      )
                                                    : !data.timelineSendComplete
                                                    ? Container(
                                                        width: 2,
                                                        height: 40,
                                                        decoration: BoxDecoration(
                                                          gradient: LinearGradient(
                                                            colors: [
                                                              timelineActiveColor,
                                                              Color.lerp(
                                                                timelineActiveColor,
                                                                timelinePendingColor,
                                                                0.7,
                                                              )!,
                                                              // You can add more colors as needed
                                                            ],
                                                            begin: Alignment
                                                                .topCenter,
                                                            end: Alignment
                                                                .bottomCenter,
                                                          ),
                                                        ),
                                                      )
                                                    : Container(
                                                        width: 2,
                                                        height: 40,
                                                        color:
                                                            timelineActiveColor,
                                                      ),
                                              ],
                                            ),
                                            const SizedBox(width: 20),
                                            Expanded(
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        !data.timelinePrepareComplete
                                                            ? "Bestillingen tilberedes"
                                                            : "Bestillingen er klar",
                                                        style: TextStyle(
                                                          color: textPrimary,
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        data.storeName,
                                                        style: TextStyle(
                                                          color: textPrimary,
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.normal,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Text(
                                                    data.prepareOrderTime,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      color: timeTextColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        StreamBuilder<int>(
                                          stream: _bloc!.userTakenType,
                                          builder: (context, snapshot) {
                                            if (snapshot.data == 2) {
                                              return Container();
                                            }
                                            return Column(
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Column(
                                                      children: [
                                                        !data.timelinePrepareComplete
                                                            ? Container(
                                                                width: 2,
                                                                height: 10,
                                                                color:
                                                                    timelinePendingColor,
                                                              )
                                                            : !data
                                                                  .timelineSendComplete
                                                            ? Container(
                                                                width: 2,
                                                                height: 10,
                                                                decoration: BoxDecoration(
                                                                  gradient: LinearGradient(
                                                                    colors: [
                                                                      Color.lerp(
                                                                        timelineActiveColor,
                                                                        timelinePendingColor,
                                                                        0.7,
                                                                      )!,
                                                                      timelinePendingColor,
                                                                    ],
                                                                    begin: Alignment
                                                                        .topCenter,
                                                                    end: Alignment
                                                                        .bottomCenter,
                                                                  ),
                                                                ),
                                                              )
                                                            : Container(
                                                                width: 2,
                                                                height: 10,
                                                                color:
                                                                    timelineActiveColor,
                                                              ),
                                                        Container(
                                                          width: 20,
                                                          height: 20,
                                                          decoration: BoxDecoration(
                                                            color:
                                                                !data
                                                                    .timelineSendComplete
                                                                ? timelinePendingColor
                                                                : timelineActiveColor,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                        ),
                                                        !data.timelineSendComplete
                                                            ? Container(
                                                                width: 2,
                                                                height: 40,
                                                                color:
                                                                    timelinePendingColor,
                                                              )
                                                            : !data
                                                                  .timelineArriveComplete
                                                            ? Container(
                                                                width: 2,
                                                                height: 40,
                                                                decoration: BoxDecoration(
                                                                  gradient: LinearGradient(
                                                                    colors: [
                                                                      timelineActiveColor,
                                                                      Color.lerp(
                                                                        timelineActiveColor,
                                                                        timelinePendingColor,
                                                                        0.7,
                                                                      )!,
                                                                    ],
                                                                    begin: Alignment
                                                                        .topCenter,
                                                                    end: Alignment
                                                                        .bottomCenter,
                                                                  ),
                                                                ),
                                                              )
                                                            : Container(
                                                                width: 2,
                                                                height: 40,
                                                                color:
                                                                    timelineActiveColor,
                                                              ),
                                                      ],
                                                    ),
                                                    const SizedBox(width: 20),
                                                    Expanded(
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                !data.timelineSendComplete
                                                                    ? "Venter på bud"
                                                                    : "Bestillingen er sendt",
                                                                style: TextStyle(
                                                                  color:
                                                                      textPrimary,
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                height: 2,
                                                              ),
                                                              Text(
                                                                "Budet",
                                                                style: TextStyle(
                                                                  color:
                                                                      textPrimary,
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .normal,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          Text(
                                                            data.sendOrderTime,
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .normal,
                                                              color:
                                                                  timeTextColor,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Column(
                                                      children: [
                                                        !data.timelineArriveComplete
                                                            ? Container(
                                                                width: 2,
                                                                height: 10,
                                                                decoration: BoxDecoration(
                                                                  gradient: LinearGradient(
                                                                    colors: [
                                                                      timelineActiveColor,
                                                                      Color.lerp(
                                                                        timelineActiveColor,
                                                                        timelinePendingColor,
                                                                        0.7,
                                                                      )!,
                                                                    ],
                                                                    begin: Alignment
                                                                        .topCenter,
                                                                    end: Alignment
                                                                        .bottomCenter,
                                                                  ),
                                                                ),
                                                              )
                                                            : Container(
                                                                width: 2,
                                                                height: 10,
                                                                color:
                                                                    timelineActiveColor,
                                                              ),
                                                        Container(
                                                          width: 20,
                                                          height: 20,
                                                          decoration: BoxDecoration(
                                                            color:
                                                                !data
                                                                    .timelineArriveComplete
                                                                ? timelinePendingColor
                                                                : timelineActiveColor,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(width: 20),
                                                    Expanded(
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                !data.timelineArriveComplete
                                                                    ? "Bestillingen er på vei"
                                                                    : "Bestillingen er levert",
                                                                style: TextStyle(
                                                                  color:
                                                                      textPrimary,
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                height: 2,
                                                              ),
                                                              Text(
                                                                data.destinationAddress
                                                                    .split(
                                                                      ',',
                                                                    )[0],
                                                                style: TextStyle(
                                                                  color:
                                                                      textPrimary,
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .normal,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          Text(
                                                            data.arriveOrderTime,
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .normal,
                                                              color:
                                                                  timeTextColor,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  const SizedBox(height: 16),
                                  if (_canCustomerCancelDelivery(data)) ...[
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: () =>
                                            managePopupMenuClick(1, data),
                                        icon: Icon(
                                          Icons.cancel_outlined,
                                          color: isDark
                                              ? Colors.redAccent.shade100
                                              : ScSaasThemeTokens.primary,
                                        ),
                                        label: Text(
                                          languages.cancelOrder,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.redAccent.shade100
                                                : ScSaasThemeTokens.primary,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: isDark
                                                ? Colors.redAccent.shade100
                                                : ScSaasThemeTokens.primary,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                            horizontal: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  data.orderCurrentStatus == 9
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              width: deviceWidth * 0.45,
                                              child: ElevatedButton(
                                                onPressed: () =>
                                                    openScreenWithResult(
                                                      context,
                                                      DeliveriesOrderDetail(
                                                        isFromTrackOrderActivity:
                                                            true,
                                                        orderId: data.orderId,
                                                      ),
                                                    ),
                                                style: ElevatedButton.styleFrom(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  backgroundColor: colorGreen,
                                                  foregroundColor: colorWhite,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 10,
                                                        horizontal: 20,
                                                      ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const SizedBox(width: 10),
                                                    Text(
                                                      languages.receipt,
                                                      style: const TextStyle(
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: deviceWidth * 0.45,
                                              child: ElevatedButton(
                                                onPressed: () => openScreen(
                                                  context,
                                                  const HomeMainV1(),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  backgroundColor:
                                                      ScSaasThemeTokens.primary,
                                                  foregroundColor:
                                                      ScSaasThemeTokens.card,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 10,
                                                        horizontal: 20,
                                                      ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const SizedBox(width: 10),
                                                    Text(
                                                      languages.home,
                                                      style: const TextStyle(
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (trackShowReceipt)
                                              SizedBox(
                                                width: tripleAction
                                                    ? deviceWidth * 0.29
                                                    : (pairReceiptChat ||
                                                              pairReceiptCall
                                                          ? deviceWidth * 0.45
                                                          : deviceWidth * 0.92),
                                                child: ElevatedButton(
                                                  onPressed: () =>
                                                      openScreenWithResult(
                                                        context,
                                                        DeliveriesOrderDetail(
                                                          isFromTrackOrderActivity:
                                                              true,
                                                          orderId: data.orderId,
                                                        ),
                                                      ),
                                                  style: ElevatedButton.styleFrom(
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                    backgroundColor: colorGreen,
                                                    foregroundColor: colorWhite,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 10,
                                                          horizontal: 20,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const SizedBox(width: 10),
                                                      Text(
                                                        languages.receipt,
                                                        style: const TextStyle(
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            if (trackShowChat) ...[
                                              if (trackShowReceipt)
                                                SizedBox(
                                                  width: deviceWidth * 0.02,
                                                ),
                                              SizedBox(
                                                width: tripleAction
                                                    ? deviceWidth * 0.29
                                                    : (pairReceiptChat
                                                          ? deviceWidth * 0.45
                                                          : (trackShowCallButton
                                                                ? deviceWidth *
                                                                      0.45
                                                                : deviceWidth *
                                                                      0.92)),
                                                child: ElevatedButton.icon(
                                                  onPressed: () =>
                                                      _openTrackOrderChat(data),
                                                  icon: Icon(
                                                    CustomIcons.chat,
                                                    size: 22,
                                                    color:
                                                        ScSaasThemeTokens.card,
                                                  ),
                                                  label: Text(
                                                    languages.chat,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: ScSaasThemeTokens
                                                          .card,
                                                    ),
                                                  ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        ScSaasThemeTokens
                                                            .primary,
                                                    foregroundColor:
                                                        ScSaasThemeTokens.card,
                                                    elevation: 0,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 10,
                                                          horizontal: 12,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                            if (trackShowChat &&
                                                trackShowCallButton)
                                              SizedBox(
                                                width: deviceWidth * 0.02,
                                              ),
                                            if (trackShowCallButton)
                                              SizedBox(
                                                width: tripleAction
                                                    ? deviceWidth * 0.29
                                                    : (pairReceiptCall ||
                                                              pairChatCall
                                                          ? deviceWidth * 0.45
                                                          : deviceWidth * 0.92),
                                                child: ElevatedButton(
                                                  onPressed: () => {
                                                    launchDialer(
                                                      _trackOrderCallNumber(
                                                        data,
                                                      ),
                                                    ),
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                    backgroundColor: colorGreen,
                                                    foregroundColor: colorWhite,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 10,
                                                          horizontal: 20,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.call,
                                                        size: 24,
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: Text(
                                                          _trackOrderCallButtonLabel(
                                                            data,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 20,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                ],
                              );

                              return SingleChildScrollView(
                                physics: const ClampingScrollPhysics(),
                                padding: EdgeInsets.only(
                                  bottom:
                                      MediaQuery.of(
                                        context,
                                      ).viewPadding.bottom +
                                      8,
                                ),
                                child: content,
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      onWillPop: () {
        if (!Navigator.canPop(context) ||
            widget.isFromPlacedOrder ||
            widget.isFromNotification) {
          openScreenWithClearPrevious(context, const HomeMainV1());
        }
        return Future.value(true);
      },
    );
  }

  void launchDialer(String phoneNumber) async {
    final String digits = phoneNumber.trim();
    if (digits.isEmpty) {
      openSimpleSnackbar(
        'Phone number is not available yet. Pull to refresh or wait a moment.',
      );
      return;
    }
    final Uri phoneUri = Uri(scheme: 'tel', path: digits);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      openSimpleSnackbar(languages.trackCouldNotOpenPhone);
    }
  }

  googleMap(TrackOrderBloc bloc) => _TrackOrderMapView(
    bloc: bloc,
    controller: controller,
    showExpandButton: true,
    onExpand: _openExpandedMap,
    onMapCreated: (value) {
      _bloc?.onMapCreated(value, Theme.of(context).brightness);
      // Force a refresh once map is ready so route/timeline stay in sync
      // even if initial map creation was delayed.
      _bloc?.callTrackOrderApi(false);
      if (!controller.isCompleted) {
        controller.complete(value);
      }
    },
  );

  void _openExpandedMap() {
    if (_bloc == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _TrackOrderExpandedMap(
          bloc: _bloc!,
          canShowCall: _canShowTrackOrderCallButton,
          callLabel: _trackOrderCallButtonLabel,
          canShowChat: (data) =>
              _canOpenStoreTrackChat(data) || _canOpenDriverTrackChat(data),
          onCall: (data) => launchDialer(_trackOrderCallNumber(data)),
          onChat: (routeContext, data) {
            Navigator.of(routeContext).pop();
            _openTrackOrderChat(data);
          },
        ),
      ),
    );
  }

  /// Customer can cancel only before the store accepts the order.
  ///
  /// Status mapping (see bloc):
  /// 1 = request pending, 2 = accepted by store, 3/4 = rejected/cancelled.
  /// Hide cancel action as soon as any acceptance signal appears.
  bool _canCustomerCancelDelivery(TrackOrderPojo data) {
    final int s = data.orderCurrentStatus;
    final bool acceptedInStatusHistory = data.orderStatusList.any(
      (item) => item.orderStatus == 2,
    );
    final bool hasAcceptanceSignal =
        data.timelineAcceptComplete || acceptedInStatusHistory;
    return s == 1 && !hasAcceptanceSignal;
  }

  /// Phone call to store (or driver when en route). Hidden until the same
  /// "store accepted" signals used for cancel/timeline (status history or
  /// accept timestamp / status >= 2 via [TrackOrderPojo.timelineAcceptComplete]).
  bool _canShowTrackOrderCallButton(TrackOrderPojo data) {
    final int s = data.orderCurrentStatus;
    if (s == 3 || s == 4 || s == 9 || s == 10) return false;
    final bool acceptedInStatusHistory = data.orderStatusList.any(
      (item) => item.orderStatus == 2,
    );
    final bool storeApproved =
        data.timelineAcceptComplete || acceptedInStatusHistory;
    return storeApproved || s >= 2;
  }

  String _trackOrderCallButtonLabel(TrackOrderPojo data) {
    if (data.orderCurrentStatus == 8 && data.userTakenType != 2) {
      return languages.callDriver;
    }
    return languages.callStore;
  }

  String _trackOrderCallNumber(TrackOrderPojo data) {
    if (data.orderCurrentStatus == 8 && data.userTakenType != 2) {
      final String driverNumber = data.driverContactNumber.trim();
      if (driverNumber.isNotEmpty) return driverNumber;
    } else {
      final String storeNumber = data.storeContactNumber.trim();
      if (storeNumber.isNotEmpty) return storeNumber;
    }
    final String statusAwareNumber = data.contactNumber.trim();
    if (statusAwareNumber.isNotEmpty) return statusAwareNumber;
    final String prefNumber = prefGetString("order_contact_number").trim();
    if (prefNumber.isNotEmpty) return prefNumber;
    return _storeContactFromCheckoutCache();
  }

  String _storeContactFromCheckoutCache() {
    final String pref = prefGetString(prefSelectedStoreFullResponse).trim();
    if (pref.isEmpty) return '';
    try {
      final dynamic decoded = jsonDecode(pref);
      if (decoded is! Map) return '';
      return (decoded['store_contact_number'] ?? '').toString().trim();
    } catch (_) {
      return '';
    }
  }

  bool _orderTrackChatTerminal(TrackOrderPojo data) {
    final int s = data.orderCurrentStatus;
    return s == 3 || s == 4 || s == 9 || s == 10;
  }

  /// Before driver pickup (status below 8 for delivery), customer matches driver
  /// app: message the store. Customer pickup (`userTakenType == 2`) stays on store through status 8.
  bool _canOpenStoreTrackChat(TrackOrderPojo data) {
    if (_orderTrackChatTerminal(data)) return false;
    if (data.storeId <= 0) return false;
    if (data.orderCurrentStatus < 2) return false;
    if (data.userTakenType == 2) {
      return data.orderCurrentStatus <= 8;
    }
    return data.orderCurrentStatus < 8;
  }

  /// After driver confirms pickup (status 8+), same thread as driver `ChattingScreen`.
  bool _canOpenDriverTrackChat(TrackOrderPojo data) {
    if (_orderTrackChatTerminal(data)) return false;
    if (data.userTakenType == 2) return false;
    return data.driverId > 0 && data.orderCurrentStatus >= 8;
  }

  void _openTrackOrderChat(TrackOrderPojo data) {
    if (_canOpenDriverTrackChat(data)) {
      openScreen(
        context,
        Chatting(
          chatWithId: ChatConstant.providerIdCode + data.driverId.toString(),
          chatWithName: data.deliveryPeopleName.trim().isNotEmpty
              ? data.deliveryPeopleName
              : languages.driver,
          chatWithImage: '',
          chatWithServicesName: languages.driver,
          chatWithUserType: chatWithTypeDriver,
        ),
      );
      return;
    }
    if (_canOpenStoreTrackChat(data)) {
      openScreen(
        context,
        Chatting(
          chatWithId: ChatConstant.providerIdCode + data.storeId.toString(),
          chatWithName: data.storeName,
          chatWithImage: data.storeBanner.isNotEmpty
              ? data.storeBanner
              : data.storeImage,
          chatWithServicesName: languages.store,
          chatWithUserType: chatWithTypeStore,
        ),
      );
    }
  }

  managePopupMenuClick(dynamic value, TrackOrderPojo data) {
    switch (value) {
      case 1:
        // `OrderCancelSheet` — a bottom sheet in the approved design.
        showDugnadSheet<bool>(
          context: context,
          isScrollControlled: true,
          builder: (BuildContext context) {
            return OrderCancelDialog(
              subjectCancel: _bloc!.subjectCancelOrder,
              title: data.cancelCharge > 0 /*&& data.paymentType != 1*/
                  ? languages.cancellationCharge
                  : languages.cancelReason,
              message: getDoubleFromDynamic(data.cancelCharge) > 0
                  ? "${languages.orderCancelMsg} ${getAmountWithCurrency(getDoubleFromDynamic(data.cancelCharge))}. ${languages.orderCancelMsg1}"
                  : "",
              onSubmit: (value, reason) {
                if (value) {
                  _bloc?.cancelOrderApi(reason);
                }
              },
            );
          },
        );
        break;
      case 2:
        if (widget.isFromPlacedOrder ||
            widget.isFromNotification ||
            !Navigator.canPop(context)) {
          openScreen(
            context,
            DeliveriesOrderDetail(
              isFromTrackOrderActivity: true,
              orderId: widget.orderId,
            ),
          );
        } else {
          Navigator.pop(context);
        }
        break;
    }
  }

  orderNo(TrackOrderBloc bloc) => StreamBuilder<String>(
    stream: bloc.orderNo,
    builder: (context, snap) {
      return Text(
        snap.data ?? "order########".toUpperCase(),
        textAlign: TextAlign.start,
        style: bodyText(fontWeight: FontWeight.w600),
      );
    },
  );

  orderDetail(TrackOrderBloc bloc) => StreamBuilder<String>(
    stream: bloc.orderDetail,
    builder: (context, snap) {
      return Text(
        snap.data ?? "TIME#########".toUpperCase(),
        textAlign: TextAlign.start,
        style: bodyText(fontSize: textSizeSmallest),
      );
    },
  );

  titleText(TrackOrderBloc bloc) => StreamBuilder<String>(
    stream: bloc.title,
    builder: (context, snap) {
      return StreamBuilder<Color>(
        stream: bloc.titleColor,
        builder: (context, snapColor) {
          return Text(
            snap.data ?? "",
            textAlign: TextAlign.start,
            style: bodyText(
              fontSize: textSizeRegular,
              textColor: snapColor.data ?? colorPrimary,
              fontWeight: FontWeight.w600,
            ),
          );
        },
      );
    },
  );

  msgText(TrackOrderBloc bloc) => StreamBuilder<String>(
    stream: bloc.msg,
    builder: (context, snap) {
      if ((snap.data ?? "").isNotEmpty) {
        return Text(
          snap.data ?? "",
          textAlign: TextAlign.start,
          style: bodyText(
            fontSize: textSizeSmall,
            textColor: colorTextCommon,
            fontWeight: FontWeight.normal,
          ),
        );
      }
      return Container(height: 0);
    },
  );

  img(TrackOrderBloc bloc) => StreamBuilder<String>(
    stream: bloc.img,
    builder: (context, snap) {
      return StreamBuilder<bool>(
        stream: bloc.subjectDriverImage,
        builder: (context, snapshot) {
          bool driverImage = snapshot.data ?? false;
          return LoadImageWithPlaceHolder(
            image: snap.data ?? "",
            width: deviceAverageSize * 0.1,
            height: deviceAverageSize * 0.1,
            defaultAssetImage: driverImage
                ? "assets/images/avatar_driver.png"
                : "assets/images/avatar_store.png",
            borderRadius: BorderRadius.circular(deviceAverageSize * 0.05),
          );
        },
      );
    },
  );

  nameText(TrackOrderBloc bloc) => StreamBuilder<String>(
    stream: bloc.name,
    builder: (context, snap) {
      return Text(
        snap.data ?? "",
        textAlign: TextAlign.start,
        style: bodyText(
          fontSize: textSizeRegular,
          textColor: colorBlack,
          fontWeight: FontWeight.normal,
        ),
      );
    },
  );

  rating(TrackOrderBloc bloc) => StreamBuilder<String>(
    stream: bloc.rating,
    builder: (context, snap) {
      return Text(
        snap.data ?? "0",
        maxLines: 1,
        overflow: TextOverflow.fade,
        textAlign: TextAlign.start,
        style: bodyText(
          fontSize: textSizeRegular,
          textColor: colorTextCommon,
          fontWeight: FontWeight.normal,
        ),
      );
    },
  );

  /// Single loading surface for the bottom sheet (no fullscreen overlay).
  Widget _trackOrderPanelLoading({
    required Color pageBg,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final Color chip = ScSaasThemeTokens.primary.withOpacity(0.12);
    final Color line = ScSaasThemeTokens.border.withOpacity(0.85);

    Widget lineBar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: line,
        borderRadius: BorderRadius.circular(6),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: pageBg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 52,
              height: 52,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: ScSaasThemeTokens.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              languages.processing,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              languages.orderProcessingMsg,
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                color: textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [lineBar(120, 14), const Spacer(), lineBar(56, 14)],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: chip,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      lineBar(double.infinity, 16),
                      const SizedBox(height: 10),
                      lineBar(deviceWidth * 0.35, 12),
                      const SizedBox(height: 8),
                      lineBar(deviceWidth * 0.45, 12),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            lineBar(double.infinity, 8),
            const SizedBox(height: 10),
            lineBar(double.infinity, 8),
            const SizedBox(height: 10),
            lineBar(deviceWidth * 0.55, 8),
          ],
        ),
      ),
    );
  }

  Widget _trackOrderPanelError({
    required Color pageBg,
    required Color textPrimary,
    required Color textSecondary,
    required String message,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: pageBg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 52,
                color: ScSaasThemeTokens.muted,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: () => _bloc?.callTrackOrderApi(true),
                style: FilledButton.styleFrom(
                  backgroundColor: ScSaasThemeTokens.primary,
                  foregroundColor: ScSaasThemeTokens.card,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 22),
                label: Text(
                  languages.retry,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
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

class _TrackOrderMapView extends StatelessWidget {
  final TrackOrderBloc bloc;
  final Completer<GoogleMapController> controller;
  final ValueChanged<GoogleMapController> onMapCreated;
  final bool showExpandButton;
  final VoidCallback? onExpand;

  const _TrackOrderMapView({
    required this.bloc,
    required this.controller,
    required this.onMapCreated,
    this.showExpandButton = false,
    this.onExpand,
  });

  @override
  Widget build(BuildContext context) => StreamBuilder<List<Marker>>(
    stream: bloc.markersList,
    builder: (context, snap) {
      final List<Marker>? markers = snap.data;
      return StreamBuilder<List<Marker>>(
        stream: bloc.rotateMarkers,
        builder: (context, rotateMarkerSnap) {
          final List<Marker>? rotateMarkers = rotateMarkerSnap.data;
          return StreamBuilder<Map<PolylineId, Polyline>>(
            stream: bloc.polylinesList,
            builder: (context, polylinesSnap) {
              final Map<PolylineId, Polyline>? polylines = polylinesSnap.data;
              return Stack(
                children: [
                  Positioned.fill(
                    child: Animarker(
                      useRotation: true,
                      curve: Curves.linear,
                      mapId: controller.future.then<int>(
                        (value) => value.mapId,
                      ),
                      markers:
                          (rotateMarkers != null && rotateMarkers.isNotEmpty)
                          ? Set<Marker>.of(rotateMarkers)
                          : <Marker>{},
                      child: GoogleMap(
                        zoomControlsEnabled: false,
                        zoomGesturesEnabled: true,
                        mapType: MapType.normal,
                        markers: (markers != null && markers.isNotEmpty)
                            ? Set<Marker>.of(markers)
                            : <Marker>{},
                        initialCameraPosition: initCameraPosition,
                        onMapCreated: onMapCreated,
                        myLocationButtonEnabled: false,
                        polylines: (polylines != null && polylines.isNotEmpty)
                            ? polylines.values.toSet()
                            : <Polyline>{},
                      ),
                    ),
                  ),
                  if (showExpandButton && onExpand != null)
                    PositionedDirectional(
                      bottom: 12,
                      end: 12,
                      child: _MapCircleButton(
                        icon: Icons.fullscreen_rounded,
                        tooltip: 'Expand map',
                        onTap: onExpand!,
                      ),
                    ),
                ],
              );
            },
          );
        },
      );
    },
  );
}

class _TrackOrderExpandedMap extends StatefulWidget {
  final TrackOrderBloc bloc;
  final bool Function(TrackOrderPojo data) canShowCall;
  final String Function(TrackOrderPojo data) callLabel;
  final bool Function(TrackOrderPojo data) canShowChat;
  final void Function(TrackOrderPojo data) onCall;
  final void Function(BuildContext context, TrackOrderPojo data) onChat;

  const _TrackOrderExpandedMap({
    required this.bloc,
    required this.canShowCall,
    required this.callLabel,
    required this.canShowChat,
    required this.onCall,
    required this.onChat,
  });

  @override
  State<_TrackOrderExpandedMap> createState() => _TrackOrderExpandedMapState();
}

class _TrackOrderExpandedMapState extends State<_TrackOrderExpandedMap> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  @override
  Widget build(BuildContext context) {
    final Color overlayColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xDD1F1F1F)
        : ScSaasThemeTokens.card.withOpacity(0.94);

    return Scaffold(
      body: Stack(
        children: [
          _TrackOrderMapView(
            bloc: widget.bloc,
            controller: _controller,
            onMapCreated: (value) {
              if (!_controller.isCompleted) {
                _controller.complete(value);
              }
              widget.bloc.configureExternalMap(
                value,
                Theme.of(context).brightness,
              );
            },
          ),
          PositionedDirectional(
            top: MediaQuery.of(context).viewPadding.top + 12,
            start: 12,
            child: _MapCircleButton(
              icon: Icons.close_rounded,
              tooltip: languages.close,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          PositionedDirectional(
            start: 16,
            end: 16,
            bottom: MediaQuery.of(context).viewPadding.bottom + 18,
            child: StreamBuilder<ApiResponse<TrackOrderPojo>>(
              stream: widget.bloc.subject,
              builder: (context, snapshot) {
                final TrackOrderPojo? data = snapshot.data?.data;
                if (data == null) return const SizedBox.shrink();
                final bool showChat = widget.canShowChat(data);
                final bool showCall = widget.canShowCall(data);
                if (!showChat && !showCall) return const SizedBox.shrink();

                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: overlayColor,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (showChat)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => widget.onChat(context, data),
                            icon: const Icon(CustomIcons.chat, size: 22),
                            label: Text(
                              languages.chat,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ScSaasThemeTokens.primary,
                              foregroundColor: ScSaasThemeTokens.card,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                vertical: 13,
                                horizontal: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      if (showChat && showCall) const SizedBox(width: 10),
                      if (showCall)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => widget.onCall(data),
                            icon: const Icon(Icons.call, size: 22),
                            label: Text(
                              widget.callLabel(data),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorGreen,
                              foregroundColor: colorWhite,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                vertical: 13,
                                horizontal: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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
    );
  }
}

class _MapCircleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _MapCircleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: ScSaasThemeTokens.card.withOpacity(0.94),
    shape: const CircleBorder(),
    elevation: 6,
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: ScSaasThemeTokens.text, size: 28),
        ),
      ),
    ),
  );
}

class DeliveryStatus extends StatefulWidget {
  final int orderId;
  final List degreeList;
  final TrackOrderBloc? bloc;
  final String duration;

  const DeliveryStatus({
    super.key,
    required this.orderId,
    required this.degreeList,
    this.bloc,
    required this.duration,
  });

  @override
  DeliveryStatusState createState() => DeliveryStatusState();
}

class DeliveryStatusState extends State<DeliveryStatus> {
  List<bool> isFirstBuild = [true, true];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1)).then((_) {
      if (mounted) {
        setState(() {
          isFirstBuild[0] = false;
        });
      }
    });
    Future.delayed(const Duration(seconds: 2)).then((_) {
      if (mounted) {
        setState(() {
          isFirstBuild[1] = false;
        });
      }
    });
  }

  void launchDialer(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      throw 'Could not launch $phoneNumber';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ModalUi.handle(),
          const SizedBox(height: 12),
          const Text(
            'Order Status',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
          Stack(
            children: [
              SizedBox(
                width: deviceWidth * 0.8,
                height: deviceWidth * 0.7,
                child: const DashedCircularProgressBar.aspectRatio(
                  aspectRatio: 1,
                  progress: 100,
                  startAngle: -75,
                  sweepAngle: 150,
                  corners: StrokeCap.round,
                  foregroundStrokeWidth: 25,
                  backgroundStrokeWidth: 25,
                  circleCenterAlignment: Alignment.center,
                  foregroundColor: ScSaasThemeTokens.primary,
                  backgroundColor: ScSaasThemeTokens.border,
                  animation: true,
                ),
              ),
              SizedBox(
                width: deviceWidth * 0.8,
                height: deviceWidth * 0.7,
                child: isFirstBuild[0]
                    ? const DashedCircularProgressBar.aspectRatio(
                        aspectRatio: 1,
                        progress: 0,
                        startAngle: 105,
                        sweepAngle: 60,
                        corners: StrokeCap.round,
                        foregroundStrokeWidth: 25,
                        backgroundStrokeWidth: 25,
                        circleCenterAlignment: Alignment.center,
                        foregroundColor: ScSaasThemeTokens.primary,
                        backgroundColor: ScSaasThemeTokens.border,
                        animation: true,
                      )
                    : DashedCircularProgressBar.aspectRatio(
                        aspectRatio: 1,
                        progress: widget.degreeList[1],
                        startAngle: 105,
                        sweepAngle: 60,
                        corners: StrokeCap.round,
                        foregroundStrokeWidth: 25,
                        backgroundStrokeWidth: 25,
                        circleCenterAlignment: Alignment.center,
                        foregroundColor: ScSaasThemeTokens.primary,
                        backgroundColor: ScSaasThemeTokens.border,
                        animation: true,
                      ),
              ),
              SizedBox(
                width: deviceWidth * 0.8,
                height: deviceWidth * 0.7,
                child: isFirstBuild[1]
                    ? const DashedCircularProgressBar.aspectRatio(
                        aspectRatio: 1,
                        progress: 0,
                        startAngle: 195,
                        sweepAngle: 60,
                        corners: StrokeCap.round,
                        foregroundStrokeWidth: 25,
                        backgroundStrokeWidth: 25,
                        circleCenterAlignment: Alignment.center,
                        foregroundColor: colorRed,
                        backgroundColor: colorWhiteGray,
                        animation: true,
                      )
                    : DashedCircularProgressBar.aspectRatio(
                        aspectRatio: 1,
                        progress: widget.degreeList[2],
                        startAngle: 195,
                        sweepAngle: 60,
                        corners: StrokeCap.round,
                        foregroundStrokeWidth: 25,
                        backgroundStrokeWidth: 25,
                        circleCenterAlignment: Alignment.center,
                        foregroundColor: colorRed,
                        backgroundColor: colorWhiteGray,
                        animation: true,
                      ),
              ),
              Positioned(
                top: deviceWidth * 0.3 + 5,
                left: 15,
                child: const LoadImageSimple(
                  image: 'assets/images/icons/lock-red.jpg',
                  width: 40,
                ),
              ),
              Positioned(
                left: deviceWidth * 0.35 + 5,
                top: deviceWidth * 0.6 + 15,
                child: LoadImageSimple(
                  image: widget.degreeList[2] > 0
                      ? 'assets/images/icons/lock-red.jpg'
                      : 'assets/images/icons/lock-gray.png',
                  width: 40,
                ),
              ),
              Positioned(
                top: deviceWidth * 0.3 + 5,
                right: 15,
                child: LoadImageSimple(
                  image: widget.degreeList[1] > 0
                      ? 'assets/images/icons/pick-red.png'
                      : 'assets/images/icons/pick-gray.png',
                  width: 40,
                ),
              ),
              SizedBox(
                width: deviceWidth * 0.8,
                height: deviceWidth * 0.75,
                child: Center(
                  child: Text(
                    '${widget.duration} \nremaining',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Text(
            'Restaurant is preparing your food now',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const Divider(height: 2),
          Row(
            children: [
              StreamBuilder<int>(
                stream: widget.bloc!.orderStatus,
                builder: (context, snapshot) {
                  String buttonName = "Back";
                  VoidCallback? processOrderStatus = () =>
                      openScreenWithClearPrevious(context, const HomeMainV1());

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  if (snapshot.hasError) {
                    openSimpleSnackbar('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData) {
                    openSimpleSnackbar(languages.trackNoDataAvailable);
                  } else if (snapshot.data == 7) {
                    processOrderStatus = () => openScreenWithResult(
                      context,
                      DeliveriesOrderDetail(
                        isFromTrackOrderActivity: true,
                        orderId: widget.orderId,
                      ),
                    );
                    buttonName = 'Receipt';
                  }
                  return SizedBox(
                    width: deviceWidth * 0.45,
                    child: ElevatedButton(
                      onPressed: processOrderStatus,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(15),
                        backgroundColor: Colors.red[50],
                        foregroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        buttonName,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                },
              ),
              const Spacer(),
              SizedBox(
                width: deviceWidth * 0.45,
                child: ElevatedButton(
                  // onPressed: () => openScreenWithResult(context,
                  //     const ChatProvider(providerName: 'Le St Andre Cafe')),
                  onPressed: () {
                    launchDialer(prefGetString("order_contact_number"));
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(15),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Call Restaurant',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
        ],
      ),
    );
  }
}

/// Live tracking timeline uses API timestamps. If those are empty (e.g. older
/// rows), fall back to [orderCurrentStatus] so the line still reflects progress.
extension TrackOrderTimelineX on TrackOrderPojo {
  bool get _isRejectedOrCancelled =>
      orderCurrentStatus == 3 || orderCurrentStatus == 4;

  bool get timelineAcceptComplete =>
      !_isRejectedOrCancelled &&
      (acceptOrderTime.isNotEmpty || orderCurrentStatus >= 2);
  bool get timelinePrepareComplete =>
      !_isRejectedOrCancelled &&
      (prepareOrderTime.isNotEmpty || orderCurrentStatus >= 5);
  bool get timelineSendComplete =>
      !_isRejectedOrCancelled &&
      (sendOrderTime.isNotEmpty || orderCurrentStatus >= 8);
  bool get timelineArriveComplete =>
      !_isRejectedOrCancelled &&
      (arriveOrderTime.isNotEmpty || orderCurrentStatus >= 9);
}
