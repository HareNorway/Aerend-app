import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animarker/widgets/animarker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../commonView/common_view.dart';
import '../../../commonView/dash_line_view.dart';
import '../../../networking/api_response.dart';
import '../../../utils/child_size_notifier.dart';
import '../../../utils/utils.dart';
import '../../common/chatting/chatting.dart';
import '../rideDetail/ride_detail_dl.dart';
import 'running_ride_bloc.dart';

class RunningRide extends StatefulWidget {
  final int orderId, orderStatus;
  final bool isOpenFromNotificationClick;

  const RunningRide({
    super.key,
    required this.orderId,
    required this.orderStatus,
    this.isOpenFromNotificationClick = false,
  });

  @override
  RunningRideState createState() => RunningRideState();
}

class RunningRideState extends State<RunningRide> {
  RunningRideBloc? _bloc;
  final controller = Completer<GoogleMapController>();
  bool isFirstClick = true;
  Timer? _timer;

  @override
  void dispose() {
    if (_timer != null && _timer!.isActive) {
      _timer?.cancel();
    }
    _bloc?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    _bloc = RunningRideBloc(context, widget.orderId, widget.orderStatus,
        widget.isOpenFromNotificationClick, this);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorMainBackground,
      appBar: AppBar(
        titleSpacing: 0,
        title: StreamBuilder<String>(
            stream: _bloc!.toolbarTitle,
            builder: (context, snapshot) {
              return Text(
                snapshot.hasData && snapshot.data != null
                    ? snapshot.data!.toUpperCase()
                    : languages.arriving.toUpperCase(),
                textAlign: TextAlign.start,
                style: toolbarStyle(),
              );
            }),
      ),
      body: _buildRunningRide(context),
    );
  }

  _buildRunningRide(BuildContext context) {
    return StreamBuilder<ApiResponse<RideDetailPojo>>(
        stream: _bloc!.subjectRideDetail,
        builder: (context, snap) {
          // var isLoading = snap.hasData && snap.data?.status == Status.loading;
          RideDetailPojo? data = snap.data?.data;
          int rideStatus = data?.rideStatus ?? 0;
          return WillPopScope(
            onWillPop: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
              return Future.value(false);
            },
            child: Stack(
              children: [
                googleMap(),
                Align(
                  alignment: AlignmentDirectional.bottomCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (data != null && (data.addressList).length > 1)
                        GestureDetector(
                          onTap: () {
                            _bloc?.navigateTo();
                          },
                          child: Container(
                            alignment: AlignmentDirectional.bottomEnd,
                            margin: EdgeInsetsDirectional.only(
                                end: deviceWidth * 0.02),
                            child: Card(
                              elevation: deviceAverageSize * 0.005,
                              margin: EdgeInsetsDirectional.only(
                                  bottom: deviceHeight * 0.015),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    deviceAverageSize * 0.04),
                              ),
                              color: colorWhite,
                              child: Container(
                                alignment: Alignment.center,
                                width: deviceAverageSize * 0.065,
                                height: deviceAverageSize * 0.065,
                                child: Icon(
                                  Icons.navigation,
                                  size: deviceAverageSize * 0.045,
                                  color: colorPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      GestureDetector(
                        onTap: () {
                          _bloc?.getCurrentLocation(
                              isFocus: true, forcefullyGetLocation: true);
                        },
                        child: Container(
                          alignment: AlignmentDirectional.bottomEnd,
                          margin: EdgeInsetsDirectional.only(
                              end: deviceWidth * 0.02),
                          child: Card(
                            elevation: deviceAverageSize * 0.005,
                            margin: EdgeInsetsDirectional.only(
                                bottom: deviceHeight * 0.015),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  deviceAverageSize * 0.04),
                            ),
                            color: colorWhite,
                            child: Container(
                              alignment: Alignment.center,
                              width: deviceAverageSize * 0.065,
                              height: deviceAverageSize * 0.065,
                              child: Icon(
                                CustomIcons.gps,
                                size: deviceAverageSize * 0.04,
                                color: colorBlack,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Card(
                        elevation: deviceAverageSize * 0.025,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(deviceAverageSize * 0.015),
                        ),
                        margin: EdgeInsetsDirectional.only(
                          top: deviceHeight * 0.02,
                          start: deviceWidth * 0.03,
                          end: deviceWidth * 0.03,
                          bottom: deviceHeight * 0.02,
                        ),
                        child: Container(
                          padding: EdgeInsetsDirectional.only(
                              bottom: deviceHeight * 0.01),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft:
                                  Radius.circular(deviceAverageSize * 0.015),
                              topRight:
                                  Radius.circular(deviceAverageSize * 0.015),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: colorMainBackground,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(
                                        deviceAverageSize * 0.015),
                                    topRight: Radius.circular(
                                        deviceAverageSize * 0.015),
                                  ),
                                ),
                                padding: EdgeInsetsDirectional.only(
                                  start: deviceWidth * 0.02,
                                  top: deviceHeight * 0.01,
                                  bottom: deviceHeight * 0.01,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 0,
                                      child: LoadImageWithPlaceHolder(
                                        width: deviceAverageSize * 0.085,
                                        height: deviceAverageSize * 0.085,
                                        image: data?.driverImage ?? "",
                                        defaultAssetImage:
                                            "assets/images/avatar_driver.png",
                                        borderRadius: BorderRadius.circular(
                                            deviceAverageSize * 0.05),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 5,
                                      child: Container(
                                        margin: EdgeInsetsDirectional.only(
                                            start: deviceWidth * 0.025),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              data?.driverName ?? "-",
                                              textAlign: TextAlign.start,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: bodyText(
                                                  fontSize: textSizeMediumBig,
                                                  textColor: colorGray700,
                                                  fontWeight: FontWeight.w700),
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  CustomIcons.star,
                                                  size:
                                                      deviceAverageSize * 0.03,
                                                  color: colorYellow,
                                                ),
                                                Container(
                                                  alignment:
                                                      AlignmentDirectional
                                                          .center,
                                                  margin: EdgeInsetsDirectional
                                                      .only(
                                                          start: deviceWidth *
                                                              0.01),
                                                  child: Text(
                                                    getDoubleFromDynamic(
                                                            data?.driverRating ??
                                                                "0")
                                                        .toStringAsFixed(2),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: bodyText(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      textColor:
                                                          colorTextCommonLight,
                                                      fontSize: textSizeSmall,
                                                    ),
                                                  ),
                                                )
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        if (data != null) {
                                          _bloc?.openVehicleInfoDialog(data);
                                        }
                                      },
                                      child: SizedBox(
                                        width: deviceWidth * 0.045,
                                        child: Icon(
                                          Icons.info_outline_rounded,
                                          size: deviceAverageSize * 0.045,
                                          color: colorMainGray,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        children: [
                                          LoadImageWithPlaceHolder(
                                            width: deviceAverageSize * 0.07,
                                            height: deviceAverageSize * 0.07,
                                            image: data?.serviceTypeIcon ?? "",
                                            borderRadius: BorderRadius.zero,
                                            imageFit: BoxFit.fill,
                                          ),
                                          Text(
                                            data?.serviceType ?? "-",
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: bodyText(
                                                fontSize: textSizeMediumBig,
                                                textColor: colorGray700,
                                                fontWeight: FontWeight.w700),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ChildSizeNotifier(
                                builder: (context, size, child) {
                                  return Container(
                                    padding: EdgeInsetsDirectional.only(
                                        start: deviceWidth * 0.01,
                                        end: deviceWidth * 0.01),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Expanded(
                                          flex: 0,
                                          child: Container(
                                            margin: EdgeInsetsDirectional.only(
                                                end: deviceWidth * 0.015,
                                                start: deviceWidth * 0.02),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.max,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width:
                                                      deviceAverageSize * 0.04,
                                                  height:
                                                      deviceAverageSize * 0.04,
                                                  alignment: Alignment.center,
                                                  child: Icon(
                                                    CustomIcons.startMapPin,
                                                    size: deviceAverageSize *
                                                        0.035,
                                                    color: colorPickUp,
                                                  ),
                                                ),
                                                if (data != null &&
                                                    (data.addressList).length >
                                                        1)
                                                  Container(
                                                    alignment:
                                                        AlignmentDirectional
                                                            .center,
                                                    height: size.height / 2.8,
                                                    margin: EdgeInsetsDirectional
                                                        .only(
                                                            top: deviceHeight *
                                                                0.002,
                                                            bottom:
                                                                deviceHeight *
                                                                    0.002),
                                                    child: DashLineView(
                                                      dashColor:
                                                          colorMainTabDividerColor,
                                                      totalHeight:
                                                          (size.height > 0
                                                              ? size.height /
                                                                  2.8
                                                              : 0),
                                                      dashHeight:
                                                          deviceHeight * 0.012,
                                                      dashWidth:
                                                          deviceWidth * 0.008,
                                                      emptyHeight:
                                                          deviceHeight * 0.005,
                                                    ),
                                                  ),
                                                if (data != null &&
                                                    (data.addressList).length >
                                                        1)
                                                  Container(
                                                    width: deviceAverageSize *
                                                        0.04,
                                                    height: deviceAverageSize *
                                                        0.04,
                                                    alignment: Alignment.center,
                                                    child: Icon(
                                                      CustomIcons
                                                          .destinationMapPin,
                                                      size: deviceAverageSize *
                                                          0.035,
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Container(
                                                width: deviceWidth,
                                                color: colorWhite,
                                                padding:
                                                    EdgeInsetsDirectional.only(
                                                  start: deviceWidth * 0.02,
                                                  top: deviceHeight * 0.02,
                                                  bottom: deviceHeight * 0.02,
                                                  end: deviceWidth * 0.028,
                                                ),
                                                child: SingleChildScrollView(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  child: Text(
                                                    data != null &&
                                                            (data.addressList)
                                                                .isNotEmpty
                                                        ? data.addressList[0]
                                                                .address ??
                                                            ""
                                                        : "-",
                                                    textAlign: TextAlign.start,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: bodyText(
                                                      fontSize: textSizeRegular,
                                                      textColor:
                                                          colorTextCommon,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              if (data != null &&
                                                  (data.addressList).length > 1)
                                                Divider(
                                                  indent: deviceWidth * 0.02,
                                                  height: deviceHeight * 0.01,
                                                  endIndent: deviceWidth * 0.02,
                                                  color: colorDivider,
                                                  thickness:
                                                      deviceHeight * 0.0015,
                                                ),
                                              if (data != null &&
                                                  (data.addressList).length > 1)
                                                Container(
                                                  width: deviceWidth,
                                                  color: colorWhite,
                                                  padding: EdgeInsetsDirectional
                                                      .only(
                                                    start: deviceWidth * 0.02,
                                                    top: deviceHeight * 0.02,
                                                    bottom: deviceHeight * 0.02,
                                                    end: deviceWidth * 0.028,
                                                  ),
                                                  child: SingleChildScrollView(
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    child: Text(
                                                      (data.addressList)
                                                              .isNotEmpty
                                                          ? data
                                                                  .addressList[data
                                                                          .addressList
                                                                          .length -
                                                                      1]
                                                                  .address ??
                                                              ""
                                                          : "-",
                                                      textAlign:
                                                          TextAlign.start,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: bodyText(
                                                        fontSize:
                                                            textSizeRegular,
                                                        textColor:
                                                            colorTextCommon,
                                                        fontWeight:
                                                            FontWeight.w600,
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
                                child: Container(),
                              ),
                              Divider(
                                height: deviceHeight * 0.01,
                                color: colorDivider,
                                thickness: deviceHeight * 0.001,
                              ),
                              Row(
                                children: [
                                  if (rideStatus <= 3 ||
                                      data?.rideServiceCategoryId == 4)
                                    Expanded(
                                      child: CustomRoundedButton(
                                        context,
                                        languages.chat,
                                        () {
                                          if (data != null) {
                                            openScreen(
                                              context,
                                              Chatting(
                                                chatWithId:
                                                    "${ChatConstant.providerIdCode}${data.driverId.toString()}",
                                                chatWithImage:
                                                    data.driverImage.toString(),
                                                chatWithName:
                                                    data.driverName.toString(),
                                                chatWithServicesName:
                                                    languages.driver,
                                                chatWithUserType:
                                                    chatWithTypeDriver,
                                              ),
                                            );
                                          }
                                        },
                                        maxLine: 1,
                                        minHeight: commonBtnHeightSmall,
                                        minWidth: commonBtnWidthSmall,
                                        bgColor: colorWhite,
                                        textAlign: TextAlign.center,
                                        elevation: 0,
                                        icon: Icon(
                                          CustomIcons.chat,
                                          color: colorRunningChat,
                                          size: deviceAverageSize * 0.035,
                                        ),
                                        textColor: colorTextCommon,
                                        fontWeight: FontWeight.w600,
                                        textSize: textSizeBig,
                                      ),
                                    )
                                  else
                                    Container(),
                                  (rideStatus <= 3 ||
                                          data?.rideServiceCategoryId == 4)
                                      ? Container(
                                          width: deviceWidth * 0.002,
                                          height: deviceHeight * 0.035,
                                          color: colorDivider,
                                        )
                                      : Container(),
                                  Expanded(
                                    child: CustomRoundedButton(
                                      context,
                                      languages.call,
                                      () {
                                        openUrl(
                                            "tel:${data?.driverContactNumber ?? ""}");
                                      },
                                      maxLine: 1,
                                      minHeight: commonBtnHeightSmall,
                                      minWidth: commonBtnWidthSmall,
                                      bgColor: colorWhite,
                                      textAlign: TextAlign.center,
                                      elevation: 0,
                                      icon: Icon(
                                        CustomIcons.call,
                                        color: colorPrimary,
                                        size: deviceAverageSize * 0.035,
                                      ),
                                      textColor: colorTextCommon,
                                      fontWeight: FontWeight.w600,
                                      textSize: textSizeBig,
                                    ),
                                  ),
                                  Container(
                                    width: deviceWidth * 0.002,
                                    height: deviceHeight * 0.035,
                                    color: colorDivider,
                                  ),
                                  Expanded(
                                    child: CustomRoundedButton(
                                      context,
                                      languages.share,
                                      () {
                                        if (isFirstClick) {
                                          setState(() {
                                            isFirstClick = false;
                                          });
                                          _bloc?.shareRide(data);
                                          _timer = Timer(
                                              const Duration(
                                                  milliseconds: 1500), () {
                                            setState(() {
                                              isFirstClick = true;
                                            });
                                          });
                                        }
                                      },
                                      maxLine: 1,
                                      minHeight: commonBtnHeightSmall,
                                      minWidth: commonBtnWidthSmall,
                                      bgColor: colorWhite,
                                      textAlign: TextAlign.center,
                                      elevation: 0,
                                      // icon: Icon(
                                      //   CustomIcons.share,
                                      //   color: colorYellow,
                                      //   size: deviceAverageSize * 0.035,
                                      // ),
                                      textColor: colorTextCommon,
                                      fontWeight: FontWeight.w600,
                                      textSize: textSizeBig,
                                    ),
                                  ),
                                ],
                              ),
                              (rideStatus >= 5)
                                  ? Container()
                                  : CustomRoundedButton(
                                      context,
                                      languages.cancelRequest,
                                      () {
                                        _bloc?.openCancelRideDialog();
                                      },
                                      fontWeight: FontWeight.w700,
                                      textColor: colorTextCommon,
                                      textSize: textSizeBig,
                                      elevation: deviceAverageSize * 0.01,
                                      roundedRectangleBorder:
                                          RoundedRectangleBorder(
                                              borderRadius: BorderRadius.only(
                                        topRight: topRightRadius,
                                        topLeft: topLeftRadius,
                                        bottomLeft: bottomLeftRadius,
                                        bottomRight: bottomRightRadius,
                                      )),
                                      textAlign: TextAlign.center,
                                      minHeight: commonBtnHeight,
                                      bgColor: colorWhite,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      minWidth: 0.8,
                                      maxLine: 1,
                                      margin: EdgeInsetsDirectional.only(
                                        top: deviceHeight * 0.01,
                                        bottom: deviceHeight * 0.005,
                                        start: deviceWidth * 0.02,
                                        end: deviceWidth * 0.02,
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
  }

  googleMap() => StreamBuilder<List<Marker>>(
      stream: _bloc!.markersList,
      builder: (context, markerSnap) {
        List<Marker>? markerData = markerSnap.data;
        return StreamBuilder<Map<PolylineId, Polyline>>(
            stream: _bloc!.polyLines,
            builder: (context, polyLinesSnap) {
              Map<PolylineId, Polyline>? polyLinesData = polyLinesSnap.data;
              return StreamBuilder<List<Marker>>(
                  stream: _bloc!.rotateMarkers,
                  builder: (context, rotateMarkerSnap) {
                    List<Marker>? routeMarkerData = rotateMarkerSnap.data;
                    return Animarker(
                      useRotation: true,
                      curve: Curves.linear,
                      mapId:
                          controller.future.then<int>((value) => value.mapId),
                      markers:
                          routeMarkerData != null && routeMarkerData.isNotEmpty
                              ? Set<Marker>.of(routeMarkerData)
                              : <Marker>{},
                      child: GoogleMap(
                        padding: EdgeInsets.only(bottom: deviceHeight * 0.3),
                        zoomControlsEnabled: false,
                        zoomGesturesEnabled: true,
                        mapType: MapType.normal,
                        markers: markerData != null && markerData.isNotEmpty
                            ? Set<Marker>.of(markerData)
                            : <Marker>{},
                        polylines:
                            polyLinesData != null && polyLinesData.isNotEmpty
                                ? Set<Polyline>.of(polyLinesData.values)
                                : <Polyline>{},
                        initialCameraPosition: initCameraPosition,
                        onMapCreated: (value) {
                          _bloc?.onMapCreated(value);
                          controller.complete(value);
                        },
                        myLocationButtonEnabled: false,
                      ),
                    );
                  });
            });
      });
}
