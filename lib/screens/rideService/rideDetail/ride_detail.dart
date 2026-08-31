import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:focus_detector/focus_detector.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../commonView/common_view.dart';
import '../../../commonView/custom_text_field.dart';
import '../../../commonView/dash_line_view.dart';
import '../../../commonView/item_key_value.dart';
import '../../../commonView/no_record_found.dart';
import '../../../commonView/statusView/ride_status_view.dart';
import '../../../dialogs/ride_common_dialog.dart';
import '../../../networking/api_base_helper.dart';
import '../../../utils/child_size_notifier.dart';
import '../../../utils/utils.dart';
import '../../common/base_dl.dart';
import '../../common/chatting/chatting.dart';
import '../../common/homeMainV1/home_main_v1.dart';
import '../runningRide/running_ride.dart';
import 'item_courier_detail.dart';
import 'ride_detail_bloc.dart';
import 'ride_detail_dl.dart';
import 'ride_detail_shimmer.dart';

class RideDetail extends StatefulWidget {
  final int rideId;
  final String rideType;
  final bool isFromNotification, clearAllNotifications;

  const RideDetail({super.key, required this.rideId, required this.rideType, this.isFromNotification = false, this.clearAllNotifications = false});

  @override
  RideDetailState createState() => RideDetailState();
}

class RideDetailState extends State<RideDetail> {
  RideDetailBloc? _bloc;

  @override
  void initState() {
    if (widget.clearAllNotifications) {
      pushNotificationService.flutterLocalNotificationsPlugin.cancelAll();
    }
    super.initState();
  }

  @override
  void didChangeDependencies() {
    _bloc = _bloc ?? RideDetailBloc(context, widget.rideId, this);

    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _bloc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusDetector(
      onForegroundGained: () {
        _bloc!.getRideDetail(isSetSubject: false, showDialog: true);
      },
      child: WillPopScope(
        onWillPop: () {
          if (widget.isFromNotification) {
            openScreenWithClearPrevious(context, const HomeMainV1());
          } else if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            openScreenWithClearPrevious(context, const HomeMainV1());
          }
          return Future.value(true);
        },
        child: Scaffold(
          backgroundColor: colorMainBackground,
          appBar: AppBar(
            automaticallyImplyLeading: true,
            centerTitle: false,
            leading: const BackButton(),
            titleSpacing: 0,
            title: Text(
              languages.courierDetail,
              textAlign: TextAlign.center,
              style: toolbarStyle(),
            ),
            actions: [
              StreamBuilder<ApiResponse<RideDetailPojo>>(
                stream: _bloc!.subject,
                builder: (context, snap) {
                  RideDetailPojo? data = snap.data?.data;
                  if (data != null && data.rideStatus < 6) {
                    List<PopupMenuEntry> popupMenuEntryList = [];
                    if (data.rideStatus < 4) {
                      popupMenuEntryList.add(
                        PopupMenuItem(
                          value: 1,
                          height: deviceHeight * 0.045,
                          child: Text(
                            languages.cancel,
                            textAlign: TextAlign.start,
                            style: bodyText(fontSize: textSizeMediumBig, textColor: colorBlack, fontWeight: FontWeight.w700),
                          ),
                        ),
                      );
                    }
                    if (data.rideStatus < 6 && data.rideStatus != 4) {
                      popupMenuEntryList.add(
                        PopupMenuItem(
                          value: 2,
                          height: deviceHeight * 0.045,
                          child: Text(
                            languages.share,
                            textAlign: TextAlign.start,
                            style: bodyText(fontSize: textSizeMediumBig, textColor: colorBlack, fontWeight: FontWeight.w700),
                          ),
                        ),
                      );
                    }
                    return popupMenuEntryList.isNotEmpty
                        ? PopupMenuButton(
                            child: Padding(
                              padding: EdgeInsetsDirectional.only(start: deviceWidth * 0.02, end: deviceWidth * 0.02),
                              child: const Icon(
                                Icons.more_vert_rounded,
                                color: colorBlack,
                              ),
                            ),
                            onSelected: (value) {
                              managePopupMenuClick(value, data);
                            },
                            itemBuilder: (context) => popupMenuEntryList,
                          )
                        : Container();
                  } else {
                    return Container();
                  }
                },
              ),
            ],
          ),
          body: _buildRideDetail(context),
        ),
      ),
    );
  }

  _buildRideDetail(BuildContext context) {
    return StreamBuilder<ApiResponse<RideDetailPojo>>(
        stream: _bloc!.subject,
        builder: (context, snap) {
          var isLoading = snap.hasData && snap.data?.status == Status.loading;
          var isError = snap.hasData && snap.data?.status == Status.error;
          Widget simmerView = RideDetailShimmer(
            enabled: isLoading,
          );
          RideDetailPojo? data = snap.data?.data;
          int paymentStatus = (data?.paymentStatus ?? 0);
          if (isLoading) {
            return simmerView;
          } else {
            return (!isError && data != null)
                ? Stack(
                    children: [
                      SingleChildScrollView(
                        padding: EdgeInsetsDirectional.only(bottom: deviceHeight * 0.085),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            addressDetail(data, context),
                            if (data.driverId > 0) driverDetail(data, context),
                            if (data.courierDetails != null) courierDetail(data.courierDetails!),
                            rideInvoice(data),
                            (paymentStatus == 1 && data.rideStatus > 5 && data.rideStatus <= 9 && data.userRatingStatus != 1)
                                ? Container(
                                    color: colorWhite,
                                    width: deviceWidth,
                                    margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.015),
                                    padding: EdgeInsetsDirectional.only(
                                        start: deviceWidth * 0.035, end: deviceWidth * 0.035, top: deviceHeight * 0.02, bottom: deviceHeight * 0.012),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          languages.shareExperience,
                                          maxLines: 1,
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                          style: bodyText(fontSize: textSizeBig, textColor: colorBlack, fontWeight: FontWeight.w700),
                                        ),
                                        Container(
                                          width: deviceWidth * 0.2,
                                          margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.02, bottom: deviceHeight * 0.02),
                                          child: Divider(
                                            color: colorMainEdtBottomLine,
                                            thickness: deviceHeight * 0.003,
                                            height: 0,
                                          ),
                                        ),
                                        Text(
                                          languages.rateDriverStar,
                                          maxLines: 1,
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                          style: bodyText(fontSize: textSizeSmall, textColor: colorGray700, fontWeight: FontWeight.w700),
                                        ),
                                        Container(
                                          margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.02),
                                          child: RatingBar.builder(
                                            initialRating: 0,
                                            direction: Axis.horizontal,
                                            allowHalfRating: true,
                                            glow: false,
                                            itemCount: 5,
                                            itemSize: deviceAverageSize * 0.05,
                                            unratedColor: colorDisableCheckBox,
                                            itemPadding: EdgeInsets.symmetric(horizontal: deviceWidth * 0.001),
                                            itemBuilder: (context, _) => const Icon(
                                              Icons.star,
                                              color: colorRatingStar,
                                            ),
                                            onRatingUpdate: (rating) {
                                              _bloc!.changeDriverRating(rating);
                                            },
                                          ),
                                        ),
                                        Container(
                                          margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.008, bottom: deviceHeight * 0.015),
                                          padding: EdgeInsetsDirectional.only(
                                              top: deviceHeight * 0.005, start: deviceWidth * 0.015, end: deviceWidth * 0.015, bottom: deviceHeight * 0.005),
                                          decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(deviceAverageSize * 0.003)), color: colorMainView),
                                          child: TextFormFieldCustom(
                                            backgroundColor: colorMainView,
                                            controller: _bloc!.driverCommentTEC,
                                            maxLine: 3,
                                            minLine: 3,
                                            textInputAction: TextInputAction.done,
                                            keyboardType: TextInputType.multiline,
                                            hint: languages.writeReviewHere,
                                            onChanged: _bloc!.changeDriverComment,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Container(),
                          ],
                        ),
                      ),
                      (data.rideStatus > 5 && data.rideStatus <= 9 && (paymentStatus != 1 || data.userRatingStatus != 1))
                          ? Align(
                              alignment: AlignmentDirectional.bottomCenter,
                              child: StreamBuilder<ApiResponse<BaseModel>>(
                                  stream: _bloc!.subjectRating,
                                  builder: (context, snapshot) {
                                    return CustomRoundedButton(
                                      context,
                                      (paymentStatus == 1) ? languages.submit : languages.proceedToPay,
                                      () {
                                        (paymentStatus == 1) ? _bloc!.rideRating(data.driverId) : _bloc!.openSelectPaymentMethod(getDoubleFromDynamic(data.totalPay));
                                      },
                                      minWidth: commonBtnWidthLargest,
                                      minHeight: commonBtnHeightMedium,
                                      margin: EdgeInsetsDirectional.only(bottom: deviceHeight * 0.02),
                                      padding: EdgeInsetsDirectional.zero,
                                      roundedRectangleBorder: RoundedRectangleBorder(
                                        borderRadius: BorderRadiusDirectional.only(
                                            topStart: topLeftRadius, topEnd: topRightRadius, bottomStart: bottomLeftRadius, bottomEnd: bottomRightRadius),
                                      ),
                                      bgColor: colorPrimary,
                                      textColor: colorWhite,
                                      fontWeight: FontWeight.w700,
                                      textSize: textSizeBig,
                                    );
                                  }),
                            )
                          : Container(),
                    ],
                  )
                : NoRecordFound(
                    message: snap.data?.message ?? "",
                  );
          }
        });
  }

  Container rideInvoice(RideDetailPojo data) {
    return Container(
      width: double.infinity,
      color: colorWhite,
      margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.01),
      padding: EdgeInsetsDirectional.only(start: deviceWidth * 0.035, end: deviceWidth * 0.035, top: deviceHeight * 0.01, bottom: deviceHeight * 0.01),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            languages.bookingId + (data.bookingNo ?? "-"),
            textAlign: TextAlign.start,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: bodyText(fontSize: textSizeMediumBig, textColor: colorBlack, fontWeight: FontWeight.w700),
          ),
          Container(
            margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.015),
            child: StreamBuilder<List<KeyValueModel>>(
              stream: _bloc!.keyValueList,
              builder: (context, keyValueSnap) {
                return ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  padding: const EdgeInsetsDirectional.only(top: 0),
                  itemCount: keyValueSnap.data?.length ?? 0,
                  itemBuilder: (BuildContext context, position) {
                    return ItemKeyValue(
                      keyValueModel: keyValueSnap.data![position],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Container addressDetail(RideDetailPojo data, BuildContext context) {
    return Container(
      padding: EdgeInsetsDirectional.only(top: deviceHeight * 0.01),
      color: colorWhite,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(deviceAverageSize * 0.004),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 0,
                  child: RideStatusView(
                    isRentalRide: false,
                    isLeft: true,
                    rideStatus: data.rideStatus,
                    padding: EdgeInsetsDirectional.only(start: deviceWidth * 0.02, end: deviceWidth * 0.02, top: deviceHeight * 0.005, bottom: deviceHeight * 0.005),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(),
                ),
                (data.rideStatus <= 3 || (data.courierDetails != null && data.rideStatus < 6 && data.rideStatus > 4))
                    ? Container(
                        height: deviceHeight * 0.036,
                        width: deviceWidth * 0.08,
                        margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.006, end: deviceWidth * 0.01),
                        child: FloatingActionButton(
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: colorPrimary,
                          heroTag: "chat",
                          elevation: 0,
                          onPressed: () {
                            openScreen(
                              context,
                              Chatting(
                                chatWithId: ChatConstant.providerIdCode + data.driverId.toString(),
                                chatWithName: data.driverName ?? "",
                                chatWithImage: data.driverImage ?? "",
                                chatWithServicesName: languages.driver,
                                chatWithUserType: chatWithTypeDriver,
                              ),
                            );
                          },
                          child: Icon(
                            CustomIcons.chat,
                            color: colorWhite,
                            size: deviceAverageSize * 0.03,
                          ),
                        ),
                      )
                    : Container(),
                (data.rideStatus <= 3 || (data.courierDetails != null && data.rideStatus < 6 && data.rideStatus > 4))
                    ? Container(
                        height: deviceHeight * 0.036,
                        width: deviceWidth * 0.08,
                        margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.006, end: deviceWidth * 0.02),
                        child: FloatingActionButton(
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: colorPrimary,
                          heroTag: "call",
                          elevation: 0,
                          onPressed: () {
                            openUrl("tel:${data.driverContactNumber}");
                          },
                          child: Icon(
                            CustomIcons.call,
                            color: colorWhite,
                            size: deviceAverageSize * 0.03,
                          ),
                        ),
                      )
                    : Container(),
              ],
            ),
            (data.cancelReason ?? "").trim().isNotEmpty
                ? Container(
                    alignment: AlignmentDirectional.centerStart,
                    margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.005, bottom: deviceHeight * 0.005, start: deviceWidth * 0.04, end: deviceWidth * 0.01),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${languages.cancelBy} ${data.cancelBy ?? "-"}",
                          textAlign: TextAlign.start,
                          style: bodyText(fontSize: textSizeRegular, textColor: colorBlack, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          data.cancelReason ?? "-",
                          textAlign: TextAlign.start,
                          style: bodyText(fontSize: textSizeRegular, textColor: colorTextCommon, fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                  )
                : Container(),
            ChildSizeNotifier(
              builder: (context, size, child) {
                return Container(
                  padding: EdgeInsetsDirectional.only(start: deviceWidth * 0.025, end: deviceWidth * 0.01, top: deviceHeight * 0.015, bottom: deviceHeight * 0.018),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        flex: 0,
                        child: Container(
                          margin: EdgeInsetsDirectional.only(
                            end: deviceWidth * 0.015,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: deviceAverageSize * 0.04,
                                height: deviceAverageSize * 0.04,
                                alignment: Alignment.center,
                                child: FaIcon(
                                  CustomIcons.startMapPin,
                                  size: deviceAverageSize * 0.03,
                                  color: colorPickUp,
                                ),
                              ),
                              Container(
                                alignment: AlignmentDirectional.center,
                                height: size.height / 2.8,
                                margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.002, bottom: deviceHeight * 0.002),
                                child: DashLineView(
                                  dashColor: colorMainTabDividerColor,
                                  totalHeight: (size.height > 0 ? size.height / 2.8 : 0),
                                  dashHeight: deviceHeight * 0.012,
                                  dashWidth: deviceWidth * 0.008,
                                  emptyHeight: deviceHeight * 0.005,
                                ),
                              ),
                              Container(
                                width: deviceAverageSize * 0.04,
                                height: deviceAverageSize * 0.04,
                                alignment: Alignment.center,
                                child: FaIcon(
                                  CustomIcons.destinationMapPin,
                                  size: deviceAverageSize * 0.03,
                                  color: colorRed,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: (data.addressList).mapWithIndex((e, i) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (i == 0)
                                  Container(
                                    alignment: AlignmentDirectional.topStart,
                                    child: Text(
                                      languages.pickUpLocation,
                                      style: bodyText(fontSize: textSizeSmallest, textColor: colorTextCommonLight, fontWeight: FontWeight.normal),
                                    ),
                                  ),
                                if (i == (data.addressList.length - 1))
                                  Container(
                                    alignment: AlignmentDirectional.topStart,
                                    margin: EdgeInsetsDirectional.only(
                                      top: deviceHeight * 0.005,
                                    ),
                                    child: Text(
                                      languages.dropLocation,
                                      style: bodyText(fontSize: textSizeSmallest, textColor: colorTextCommonLight, fontWeight: FontWeight.normal),
                                    ),
                                  ),
                                Container(
                                  margin: EdgeInsets.symmetric(vertical: deviceHeight * 0.005),
                                  child: Text(
                                    e.address ?? "-",
                                    textAlign: TextAlign.start,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: bodyText(fontSize: textSizeRegular, textColor: colorGray700, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: Container(),
            ),
            if ((data.otp ?? "").trim().isNotEmpty)
              Container(
                margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.035, bottom: deviceHeight * 0.005),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 0,
                      child: Container(
                        margin: EdgeInsetsDirectional.only(end: deviceWidth * 0.008),
                        child: Text(
                          languages.otp,
                          textAlign: TextAlign.start,
                          style: bodyText(fontSize: textSizeRegular, textColor: colorGray700, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        ": ${data.otp ?? "-"}",
                        textAlign: TextAlign.start,
                        style: bodyText(fontSize: textSizeRegular, textColor: colorGray700, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Container driverDetail(RideDetailPojo data, BuildContext context) {
    return Container(
      width: double.infinity,
      color: colorWhite,
      padding: EdgeInsetsDirectional.only(start: deviceWidth * 0.02, end: deviceWidth * 0.02, top: deviceHeight * 0.01, bottom: deviceHeight * 0.01),
      margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.01),
      child: Row(
        children: [
          Expanded(
            flex: 10,
            child: Container(
              margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.02),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    languages.driver,
                    textAlign: TextAlign.start,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bodyText(fontWeight: FontWeight.w700, textColor: colorBlack, fontSize: textSizeMediumBig),
                  ),
                  Row(
                    children: [
                      Container(
                        margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.01),
                        child: LoadImageWithPlaceHolder(
                          width: deviceAverageSize * 0.09,
                          height: deviceAverageSize * 0.09,
                          image: data.driverImage ?? "",
                          defaultAssetImage: "assets/images/avatar_driver.png",
                          borderRadius: BorderRadius.circular(deviceAverageSize * 0.05),
                        ),
                      ),
                      Container(
                        margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.02),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(data.driverName ?? "-",
                                textAlign: TextAlign.start,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: bodyText(textColor: colorGray700, fontWeight: FontWeight.w700, fontSize: textSizeRegular)),
                            RatingBar.builder(
                              initialRating: getDoubleFromDynamic(data.driverRating),
                              direction: Axis.horizontal,
                              allowHalfRating: true,
                              glow: false,
                              ignoreGestures: true,
                              itemCount: 5,
                              itemSize: deviceAverageSize * 0.025,
                              unratedColor: colorDisableCheckBox,
                              itemPadding: EdgeInsets.symmetric(horizontal: deviceWidth * 0.001),
                              itemBuilder: (context, _) => const Icon(
                                Icons.star,
                                color: colorRatingStar,
                              ),
                              onRatingUpdate: (rating) {},
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
          GestureDetector(
            onTap: () {
              _bloc!.openVehicleInfoDialog(data);
            },
            child: Container(
                width: deviceWidth * 0.04,
                alignment: AlignmentDirectional.centerEnd,
                child: Icon(
                  CustomIcons.info,
                  size: deviceAverageSize * 0.04,
                  color: colorMainLightGray,
                )),
          ),
          Expanded(
            flex: 5,
            child: Container(
              alignment: AlignmentDirectional.center,
              decoration: BoxDecoration(border: Border.all(color: colorGray, width: deviceWidth * 0.004)),
              margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.05, bottom: deviceHeight * 0.01),
              child: Column(
                children: [
                  LoadImageWithPlaceHolder(
                    width: deviceAverageSize * 0.09,
                    height: deviceAverageSize * 0.09,
                    image: data.serviceTypeIcon ?? "",
                    borderRadius: BorderRadius.zero,
                    imageFit: BoxFit.fill,
                  ),
                  Text(
                    data.serviceType ?? "-",
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: bodyText(fontSize: textSizeSmall, textColor: colorGray700, fontWeight: FontWeight.w600),
                  ),
                  if (data.rideStatus < 6 && data.rideStatus != 4)
                    GestureDetector(
                      onTap: () async {
                        openScreenWithResult(
                          context,
                          RunningRide(orderId: data.rideId, orderStatus: data.rideStatus),
                        ).then(
                          (value) {
                            _bloc!.getRideDetail();
                          },
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: deviceHeight * 0.001),
                        color: colorPrimary.withOpacity(0.15),
                        child: Text(
                          languages.trackRide,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: bodyText(fontSize: textSizeRegular, textColor: colorPrimaryDark, fontWeight: FontWeight.w700),
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

  Container courierDetail(CourierDetails courierDetails) {
    return Container(
      color: colorWhite,
      width: double.infinity,
      margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.01),
      padding: EdgeInsetsDirectional.only(start: deviceWidth * 0.035, end: deviceWidth * 0.035),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsetsDirectional.zero,
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          expandedAlignment: Alignment.topLeft,
          iconColor: colorMainGray,
          collapsedIconColor: colorMainGray,
          title: Text(
            languages.courierDetail,
            textAlign: TextAlign.start,
            style: bodyText(textColor: colorTextCommon, fontWeight: FontWeight.w700, fontSize: textSizeBig),
          ),
          children: [
            if (courierDetails.parcelName != null)
              ItemCourierDetail(
                label: languages.packageDetail,
                mainText: "${courierDetails.parcelName}",
              ),
            if (courierDetails.purchaseItemList.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsetsDirectional.only(top: deviceHeight * 0.01),
                    child: Text(
                      languages.itemToPurchase,
                      textAlign: TextAlign.start,
                      style: bodyText(textColor: colorMainGray, fontWeight: FontWeight.w600, fontSize: textSizeSmall),
                    ),
                  ),
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: courierDetails.purchaseItemList.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      return Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Text(
                              courierDetails.purchaseItemList[index].itemName ?? "",
                              style: bodyText(fontWeight: FontWeight.w600, fontSize: textSizeMediumBig, textColor: colorTextCommon),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              "X",
                              style: bodyText(fontWeight: FontWeight.w600, fontSize: textSizeMediumBig, textColor: colorTextCommon),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              courierDetails.purchaseItemList[index].itemValue ?? "",
                              style: bodyText(fontWeight: FontWeight.w600, fontSize: textSizeMediumBig, textColor: colorTextCommon),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            /*if (courierDetails.courierType == 1)
              Column(
                children: [
                  Padding(
                    padding: EdgeInsetsDirectional.only(top: deviceHeight * 0.007),
                    child: ItemCourierDetail(
                      label: languages.packageWeight,
                      mainText: "${courierDetails.goodsWeight} ${languages.kg}",
                    ),
                  ),
                  Padding(
                    padding: EdgeInsetsDirectional.only(top: deviceHeight * 0.007),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                languages.goodsHeight,
                                style: bodyText(fontWeight: FontWeight.w600, fontSize: textSizeSmall, textColor: colorMainGray),
                              ),
                              Text(
                                "${courierDetails.goodsHeight} cm",
                                style: bodyText(fontWeight: FontWeight.w600, fontSize: textSizeMediumBig, textColor: colorTextCommon),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                languages.goodsWidth,
                                style: bodyText(fontWeight: FontWeight.w600, fontSize: textSizeSmall, textColor: colorMainGray),
                              ),
                              Text(
                                "${courierDetails.goodsWidth} cm",
                                style: bodyText(fontWeight: FontWeight.w600, fontSize: textSizeMediumBig, textColor: colorTextCommon),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                languages.goodsLength,
                                style: bodyText(fontWeight: FontWeight.w600, fontSize: textSizeSmall, textColor: colorMainGray),
                              ),
                              Text(
                                "${courierDetails.goodsLength} cm",
                                style: bodyText(fontWeight: FontWeight.w600, fontSize: textSizeMediumBig, textColor: colorTextCommon),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),*/
            if (courierDetails.courierType == 2)
              Padding(
                padding: EdgeInsetsDirectional.only(top: deviceHeight * 0.007),
                child: ItemCourierDetail(
                  label: languages.estimatedValue,
                  mainText: getAmountWithCurrency(courierDetails.estimatePrice),
                ),
              ),
            if (courierDetails.deliveryInstruction != null)
              Container(
                margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.007),
                child: ItemCourierDetail(
                  label: languages.deliveryInstruction,
                  mainText: courierDetails.deliveryInstruction ?? "--",
                ),
              ),
            Container(
              margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.02),
              child: Row(
                children: [
                  Text(
                    languages.pickupDetail,
                    textAlign: TextAlign.start,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bodyText(fontSize: textSizeBig, textColor: colorBlack, fontWeight: FontWeight.w700),
                  ),
                  Expanded(
                    child: Divider(
                      color: colorDivider,
                      indent: deviceWidth * 0.02,
                      thickness: deviceHeight * 0.0015,
                    ),
                  )
                ],
              ),
            ),
            Container(
              padding: EdgeInsetsDirectional.only(start: deviceWidth * 0.02, end: deviceWidth * 0.02),
              margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.007, bottom: deviceHeight * 0.005),
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.005, bottom: deviceHeight * 0.005),
                    child: ItemCourierDetail(
                      icon: Icon(
                        CustomIcons.myAccountEditProfile,
                        color: colorMainLightGray,
                        size: deviceAverageSize * 0.03,
                      ),
                      mainText: courierDetails.senderName ?? "--",
                    ),
                  ),
                  Container(
                    margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.005, bottom: deviceHeight * 0.005),
                    child: ItemCourierDetail(
                      icon: Icon(
                        CustomIcons.call_1,
                        color: colorMainLightGray,
                        size: deviceAverageSize * 0.03,
                      ),
                      mainText: courierDetails.senderContactNumber ?? "--",
                    ),
                  ),
                  Container(
                    margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.005, bottom: deviceHeight * 0.005),
                    child: ItemCourierDetail(
                      label: languages.shopBuildingName,
                      mainText: courierDetails.shopName ?? "--",
                    ),
                  ),
                  Container(
                    margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.005, bottom: deviceHeight * 0.005),
                    child: ItemCourierDetail(
                      label: languages.houseNameLandmark,
                      mainText: courierDetails.shopLandmark ?? "--",
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.005),
              child: Row(
                children: [
                  Text(
                    languages.deliveryDetail,
                    textAlign: TextAlign.start,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bodyText(fontSize: textSizeBig, textColor: colorBlack, fontWeight: FontWeight.w700),
                  ),
                  Expanded(
                    child: Divider(
                      color: colorDivider,
                      indent: deviceWidth * 0.02,
                      thickness: deviceHeight * 0.0015,
                    ),
                  )
                ],
              ),
            ),
            Container(
              padding: EdgeInsetsDirectional.only(start: deviceWidth * 0.02, end: deviceWidth * 0.02),
              margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.007, bottom: deviceHeight * 0.005),
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.005, bottom: deviceHeight * 0.005),
                    child: ItemCourierDetail(
                      icon: Icon(
                        CustomIcons.myAccountEditProfile,
                        color: colorMainLightGray,
                        size: deviceAverageSize * 0.03,
                      ),
                      mainText: courierDetails.recipientName ?? "--",
                    ),
                  ),
                  Container(
                    margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.005, bottom: deviceHeight * 0.005),
                    child: ItemCourierDetail(
                      icon: Icon(
                        CustomIcons.call_1,
                        color: colorMainLightGray,
                        size: deviceAverageSize * 0.03,
                      ),
                      mainText: courierDetails.recipientContactNumber ?? "--",
                    ),
                  ),
                  Container(
                    margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.005, bottom: deviceHeight * 0.005),
                    child: ItemCourierDetail(
                      label: languages.houseName,
                      mainText: courierDetails.recipientHouseName ?? "--",
                    ),
                  ),
                  Container(
                    margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.005, bottom: deviceHeight * 0.005),
                    child: ItemCourierDetail(
                      label: languages.landmark,
                      mainText: courierDetails.recipientLandmark ?? "--",
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  managePopupMenuClick(dynamic value, RideDetailPojo data) {
    switch (value) {
      case 1:
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return StreamBuilder<ApiResponse<BaseModel>>(
                stream: _bloc!.subjectCancelOrder,
                builder: (context, snapLoading) {
                  var isLoading = snapLoading.hasData && snapLoading.data?.status == Status.loading;
                  return RideCommonDialog(
                    isLoading: isLoading,
                    dialogImg: "assets/images/dialog_cancel_img.png",
                    title: languages.cancelBooking,
                    msg: languages.enterReason,
                    positiveBtnTxt: languages.submit,
                    negativeBtnTxt: languages.cancel,
                    textFieldHint: languages.reason,
                    textFieldEmptyErrorMsg: languages.enterCancelReason,
                    positiveBtnOnClick: (spinnerPos, textFieldValue) {
                      if (textFieldValue.isNotEmpty) {
                        _bloc!.cancelOrderApi(textFieldValue);
                      }
                    },
                    negativeBtnOnClick: () {
                      Navigator.pop(context, true);
                    },
                  );
                },
              );
            });
        break;
      case 2:
        _bloc!.shareRide();
        break;
    }
  }
}
