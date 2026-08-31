import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../../../commonView/common_view.dart';
import '../../../networking/api_base_helper.dart';
import '../../../utils/utils.dart';
import '../../deliveryService/checkout/checkout_dl.dart';
import '../searched_location_dl.dart';
import 'item_vehicle_type.dart';
import 'ride_book_bloc.dart';
import 'ride_book_dl.dart';

class RideBook extends StatefulWidget {
  final List<SearchedLocation>? locationList;
  final Map<String, dynamic> courierData;

  const RideBook({super.key, required this.locationList, required this.courierData});

  @override
  RideBookState createState() => RideBookState();
}

class RideBookState extends State<RideBook> with WidgetsBindingObserver {
  RideBookBloc? _bloc;
  bool showRipple = false;
  Timer? timer;

  @override
  void didChangeDependencies() {
    _bloc = _bloc ?? RideBookBloc(context, widget.locationList ?? [], widget.courierData, this);
    super.didChangeDependencies();
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    _bloc?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          manageBackgroundRideRequestAccept(_bloc!.rideId);
        });
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorMainBackground,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        centerTitle: false,
        titleSpacing: 0,
        title: Text(
          languages.selectVehicle,
          textAlign: TextAlign.start,
          style: toolbarStyle(),
        ),
      ),
      body: _buildRideBook(context),
    );
  }

  _buildRideBook(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: googleMap(),
          flex: 1,
        ),
        Expanded(
          flex: 0,
          child: Container(
            color: colorWhite,
            width: deviceWidth,
            padding: EdgeInsetsDirectional.only(top: deviceHeight * 0.01, bottom: deviceHeight * 0.015),
            child: Column(
              children: [
                serviceData(),
                Container(
                  padding: EdgeInsetsDirectional.only(start: deviceWidth * 0.05, end: deviceWidth * 0.05),
                  child: Column(
                    children: [
                      Divider(
                        color: colorDivider,
                        thickness: deviceWidth * 0.0025,
                        height: 0,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Container(
                              padding: EdgeInsetsDirectional.only(top: deviceHeight * 0.018, bottom: deviceHeight * 0.018),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    flex: 0,
                                    child: Icon(
                                      CustomIcons.pay,
                                      color: colorBlack,
                                      size: deviceAverageSize * 0.03,
                                    ),
                                  ),
                                  Flexible(
                                    flex: 1,
                                    child: Container(
                                      margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.015),
                                      child: StreamBuilder<double>(
                                          stream: _bloc!.amount,
                                          builder: (context, snap) {
                                            return Text(
                                              snap.hasData ? getAmountWithCurrency(snap.data ?? 0) : "-",
                                              textAlign: TextAlign.start,
                                              style: bodyText(textColor: colorGray700, fontWeight: FontWeight.normal, fontSize: textSizeRegular),
                                            );
                                          }),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            color: colorDivider,
                            width: deviceWidth * 0.003,
                            height: deviceHeight * 0.035,
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              padding: EdgeInsetsDirectional.only(top: deviceHeight * 0.018, bottom: deviceHeight * 0.018),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    flex: 0,
                                    child: Icon(
                                      CustomIcons.time,
                                      color: colorBlack,
                                      size: deviceAverageSize * 0.03,
                                    ),
                                  ),
                                  Flexible(
                                    flex: 1,
                                    child: Container(
                                      margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.015),
                                      child: StreamBuilder<int>(
                                          stream: _bloc!.time,
                                          builder: (context, snap) {
                                            return Text(
                                              snap.hasData ? "${snap.data} ${languages.min}" : "-",
                                              textAlign: TextAlign.start,
                                              style: bodyText(textColor: colorGray700, fontWeight: FontWeight.normal, fontSize: textSizeRegular),
                                            );
                                          }),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            color: colorDivider,
                            width: deviceWidth * 0.003,
                            height: deviceHeight * 0.035,
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              padding: EdgeInsetsDirectional.only(top: deviceHeight * 0.018, bottom: deviceHeight * 0.018),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    flex: 0,
                                    child: Icon(
                                      CustomIcons.distance,
                                      color: colorBlack,
                                      size: deviceAverageSize * 0.03,
                                    ),
                                  ),
                                  Flexible(
                                    flex: 1,
                                    child: Container(
                                      margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.015),
                                      child: StreamBuilder<double>(
                                          stream: _bloc!.distance,
                                          builder: (context, snap) {
                                            return Text(
                                              snap.hasData ? "${snap.data} ${languages.km.toLowerCase()}" : "-",
                                              textAlign: TextAlign.start,
                                              style: bodyText(textColor: colorGray700, fontWeight: FontWeight.normal, fontSize: textSizeRegular),
                                            );
                                          }),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Divider(
                        color: colorDivider,
                        thickness: deviceWidth * 0.0025,
                        height: 0,
                      ),
                      /*Row(
                        children: [
                          Expanded(
                            child: selectPaymentBtn(context),
                            flex: 1,
                          ),
                          Expanded(
                            child: promoCodeBtn(),
                            flex: 1,
                          ),
                        ],
                      ),*/
                      promoCodeBtn(),
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: StreamBuilder<ApiResponse<SurgeChargePojo>>(
                              stream: _bloc!.subjectSurgeCharge,
                              builder: (context, snapSurgeCharge) {
                                var isSurgeChargeLoading =
                                    snapSurgeCharge.hasData && snapSurgeCharge.data?.status == Status.loading && _bloc!.isSchedule!;
                                return StreamBuilder<ApiResponse<RideBookPojo>>(
                                    stream: _bloc!.subjectScheduleRideBook,
                                    builder: (context, snapLoading) {
                                      var isLoading = snapLoading.hasData && snapLoading.data?.status == Status.loading;
                                      isLoading = (isSurgeChargeLoading || isLoading);
                                      return Container(
                                        margin: EdgeInsetsDirectional.only(end: deviceWidth * 0.02, top: deviceHeight * 0.01),
                                        child: CustomRoundedButton(
                                          context,
                                          languages.scheduleRide,
                                          isLoading
                                              ? null
                                              : () {
                                                  _bloc!.onClickBookRide(true);
                                                },
                                          fontWeight: FontWeight.w600,
                                          textColor: colorPrimary,
                                          textSize: textSizeBig,
                                          bgColor: colorPrimary,
                                          setBorder: true,
                                          padding: EdgeInsetsDirectional.only(
                                              top: deviceHeight * 0.006,
                                              end: deviceWidth * 0.006,
                                              start: deviceWidth * 0.006,
                                              bottom: deviceHeight * 0.006),
                                          elevation: 0,
                                          roundedRectangleBorder: RoundedRectangleBorder(
                                            borderRadius: BorderRadiusDirectional.only(
                                                topStart: topLeftRadius,
                                                topEnd: topRightRadius,
                                                bottomStart: bottomLeftRadius,
                                                bottomEnd: bottomRightRadius),
                                          ),
                                          textAlign: TextAlign.center,
                                          progressColor: colorPrimary,
                                          setProgress: isLoading,
                                          minHeight: commonBtnHeight,
                                          progressStrokeWidth: cpiStrokeWidthSmall,
                                          progressSize: cpiSizeSmall,
                                        ),
                                      );
                                    });
                              },
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: StreamBuilder<ApiResponse<SurgeChargePojo>>(
                                stream: _bloc!.subjectSurgeCharge,
                                builder: (context, snapSurgeCharge) {
                                  var isSurgeChargeLoading =
                                      snapSurgeCharge.hasData && snapSurgeCharge.data?.status == Status.loading && !_bloc!.isSchedule!;
                                  return StreamBuilder<ApiResponse<RideBookPojo>>(
                                      stream: _bloc!.subjectRideBook,
                                      builder: (context, snapLoading) {
                                        var isLoading = snapLoading.hasData && snapLoading.data?.status == Status.loading;
                                        isLoading = (isSurgeChargeLoading || isLoading);
                                        return Container(
                                          margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.02, top: deviceHeight * 0.01),
                                          child: CustomRoundedButton(
                                            context,
                                            prefGetInt(prefSelectedServiceCateId) == 4 ? languages.proceed : languages.rideNow,
                                            isLoading
                                                ? null
                                                : () {
                                                    _bloc!.onClickBookRide(false);
                                                  },
                                            minHeight: commonBtnHeight,
                                            padding: EdgeInsetsDirectional.only(
                                                top: deviceHeight * 0.006,
                                                end: deviceWidth * 0.006,
                                                start: deviceWidth * 0.006,
                                                bottom: deviceHeight * 0.006),
                                            elevation: 0,
                                            setBorder: false,
                                            bgColor: colorPrimary,
                                            fontWeight: FontWeight.w600,
                                            textColor: colorWhite,
                                            textSize: textSizeBig,
                                            maxLine: 1,
                                            setProgress: isLoading,
                                            textAlign: TextAlign.center,
                                            progressStrokeWidth: cpiStrokeWidthSmall,
                                            progressSize: cpiSizeSmall,
                                            progressColor: colorWhite,
                                          ),
                                        );
                                      });
                                }),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  serviceData() => StreamBuilder<ApiResponse<ServiceTypeModel>>(
      stream: _bloc!.subjectServiceData,
      builder: (context, snap) {
        var isLoading = snap.hasData && snap.data?.status == Status.loading;
        List<ServiceTypeItem> serviceTypeList = snap.data?.data?.serviceType ?? [];
        bool vehicleStatus = false;
        for (var item in serviceTypeList) {
          if (item.serviceStatus == 1) {
            vehicleStatus = true;
            break;
          }
        }

        return isLoading
            ? getServiceDataShimmer()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: deviceAverageSize * 0.14,
                    child: ListView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsetsDirectional.only(start: deviceWidth * 0.01, end: deviceWidth * 0.01),
                      itemCount: serviceTypeList.length,
                      itemBuilder: (BuildContext context, position) {
                        return ItemVehicleType(
                          serviceTypeItem: serviceTypeList[position],
                          onClick: () {
                            _bloc!.vehicleSelect(position, true);
                          },
                        );
                      },
                    ),
                  ),
                  if (vehicleStatus)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: deviceWidth * 0.05),
                      child: Divider(
                        color: colorDivider,
                        thickness: deviceWidth * 0.0025,
                        height: 0,
                      ),
                    ),
                  if (vehicleStatus)
                    Padding(
                      padding: EdgeInsetsDirectional.only(start: deviceWidth * 0.05, top: deviceHeight * 0.01, bottom: deviceHeight * 0.01),
                      child: Row(
                        children: [
                          const Icon(
                            CustomIcons.package,
                            // width: deviceAverageSize * 0.03,
                            // height: deviceAverageSize * 0.03,
                            color: colorPrimary,
                          ),
                          Flexible(
                            child: Padding(
                              padding: EdgeInsetsDirectional.only(start: deviceWidth * 0.02),
                              child: StreamBuilder<String?>(
                                stream: _bloc!.dimensionAndWeightLimitSubject,
                                builder: (context, snapshot) {
                                  String dimensionLimit = snapshot.data ?? "";
                                  return Text(
                                    dimensionLimit ,
                                    style: bodyText(fontSize: 0.024, textColor: colorPrimary),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },
                              ),
                            ),
                          ),
                          /*const Text(",", style: TextStyle(color: colorPrimary)),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsetsDirectional.only(start: deviceWidth * 0.02),
                              child: StreamBuilder<String?>(
                                stream: _bloc!.weightLimitSubject,
                                builder: (context, snapshot) {
                                  String weightLimit = snapshot.data ?? "";
                                  return Text(
                                    weightLimit,
                                    style: bodyText(fontSize: 0.024, textColor: colorPrimary),
                                    maxLines: 1,
                                  );
                                },
                              ),
                            ),
                          ),*/
                        ],
                      ),
                    ),
                ],
              );
      });

  googleMap() => StreamBuilder<List<Marker>>(
      stream: _bloc!.markersList,
      builder: (context, snap) {
        return StreamBuilder<Map<PolylineId, Polyline>>(
            stream: _bloc!.polyLines,
            builder: (context, polyLinesSnap) {
              return GoogleMap(
                zoomControlsEnabled: false,
                zoomGesturesEnabled: true,
                mapType: MapType.normal,
                markers: (snap.data != null && snap.data!.isNotEmpty) ? Set<Marker>.of(snap.data!) : <Marker>{},
                polylines:
                    (polyLinesSnap.data != null && polyLinesSnap.data!.isNotEmpty) ? Set<Polyline>.of(polyLinesSnap.data!.values) : <Polyline>{},
                initialCameraPosition: initCameraPosition,
                onMapCreated: (value) {
                  _bloc!.onMapCreated(value);
                },
                myLocationButtonEnabled: false,
              );
            });
      });

  selectPaymentBtn(BuildContext context) => StreamBuilder<int>(
        stream: _bloc!.selectedPaymentMethod,
        builder: (context, snap) {
          int type = snap.data ?? 1;
          IconData? icon;
          String? title;
          if (type == 1) {
            icon = CustomIcons.cash;
            title = languages.cash;
          } else if (type == 2) {
            icon = CustomIcons.card;
            title = languages.card;
          } else if (type == 3) {
            icon = CustomIcons.wallet;
            title = languages.wallet;
          }

          return Container(
            margin: EdgeInsetsDirectional.only(end: deviceWidth * 0.02, top: deviceHeight * 0.01),
            child: CustomRoundedButton(
              context,
              title!,
              () {
                _bloc!.selectPaymentMethodDialog();
              },
              maxLine: 1,
              setBorder: false,
              bgColor: colorMainBackground,
              elevation: 0,
              textSize: textSizeRegular,
              textColor: colorTextCommon,
              fontWeight: FontWeight.normal,
              icon: Icon(
                icon,
                size: deviceAverageSize * 0.045,
                color: colorTextCommon,
              ),
              minHeight: commonBtnHeight,
            ),
          );
        },
      );

  promoCodeBtn() => StreamBuilder<PromoCodeListItem?>(
      stream: _bloc!.selectedPromoCode,
      builder: (context, snap) {
        return Container(
          margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.02, top: deviceHeight * 0.01),
          child: CustomRoundedButton(
            context,
            !snap.hasData ? languages.promoCode : snap.data!.promocodeName,
            () {
              _bloc!.promoCodeDialog();
            },
            minHeight: commonBtnHeight,
            bgColor: colorMainBackground,
            elevation: 0,
            widget: !snap.hasData
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        flex: 0,
                        child: Icon(
                          CustomIcons.promoCode,
                          size: deviceAverageSize * 0.04,
                          color: colorTextCommon,
                        ),
                      ),
                      Flexible(
                        flex: 1,
                        child: Container(
                          margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.02),
                          child: Text(
                            languages.promoCode,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: bodyText(textColor: colorGray700, fontWeight: FontWeight.normal, fontSize: textSizeRegular),
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        flex: 1,
                        child: Container(
                          margin: EdgeInsetsDirectional.only(end: deviceWidth * 0.015),
                          child: Text(
                            snap.data?.promocodeName ?? "-",
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: bodyText(textColor: colorGray700, fontWeight: FontWeight.normal, fontSize: textSizeRegular),
                          ),
                        ),
                      ),
                      Flexible(
                        flex: 0,
                        child: GestureDetector(
                          onTap: () {
                            _bloc!.removeAppliedPromoCode(true);
                          },
                          child: Icon(
                            Icons.cancel_rounded,
                            size: deviceAverageSize * 0.04,
                            color: colorRed,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      });

  getServiceDataShimmer() => Shimmer.fromColors(
        baseColor: colorShimmerBg,
        highlightColor: Colors.grey[100]!,
        period: const Duration(milliseconds: 1500),
        child: SizedBox(
          height: deviceAverageSize * 0.165,
          child: ListView.builder(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsetsDirectional.only(start: deviceWidth * 0.01, end: deviceWidth * 0.01),
              itemCount: 4,
              itemBuilder: (BuildContext context, position) {
                return Container(
                  margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.025, end: deviceWidth * 0.025),
                  child: Column(
                    children: [
                      Container(
                        width: deviceAverageSize * 0.1,
                        height: deviceAverageSize * 0.1,
                        margin: EdgeInsetsDirectional.only(bottom: deviceHeight * 0.005),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(deviceAverageSize * 0.05)),
                          border: Border.all(color: colorMainView, width: deviceAverageSize * 0.0015),
                          color: colorWhite,
                        ),
                      ),
                      Flexible(
                        child: Container(
                          margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.005),
                          width: deviceAverageSize * 0.08,
                          height: textSizeSmallest,
                          color: colorWhite,
                        ),
                      ),
                    ],
                  ),
                );
              }),
        ),
      );
}
