import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../commonView/dash_line_view.dart';
import '../../../../commonView/statusView/ride_status_view.dart';
import '../../../../utils/child_size_notifier.dart';
import '../../../../utils/utils.dart';

class RideHistoryShimmer extends StatelessWidget {
  final bool enabled;

  const RideHistoryShimmer({super.key, this.enabled = true});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: Shimmer.fromColors(
          baseColor: colorShimmerBg,
          highlightColor: Colors.grey.shade100,
          enabled: enabled,
          period: const Duration(milliseconds: 1500),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: 4,
            padding: EdgeInsets.zero,
            itemBuilder: (BuildContext context, position) => Card(
              margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.008, bottom: deviceHeight * 0.008),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(deviceAverageSize * 0.002),
              ),
              color: Colors.black45,
              child: Container(
                padding: EdgeInsetsDirectional.only(start: deviceWidth * 0.02, top: deviceHeight * 0.01, bottom: deviceHeight * 0.01),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 0,
                          child: Container(
                            margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.012, start: deviceWidth * 0.025),
                            width: deviceAverageSize * 0.035,
                            height: deviceAverageSize * 0.035,
                            color: Colors.black,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.015, top: deviceHeight * 0.012, end: deviceWidth * 0.15),
                            width: deviceWidth * 0.6,
                            color: Colors.black,
                            height: deviceHeight * 0.025,
                          ),
                        ),
                        Expanded(
                          flex: 0,
                          child: RideStatusView(
                            isRentalRide: position % 2 == 0,
                            isLeft: false,
                            rideStatus: 9,
                            padding: EdgeInsetsDirectional.only(
                                start: deviceWidth * 0.02, end: deviceWidth * 0.01, top: deviceHeight * 0.005, bottom: deviceHeight * 0.005),
                          ),
                        ),
                      ],
                    ),
                    ChildSizeNotifier(
                      builder: (context, size, child) {
                        return Container(
                          padding: EdgeInsetsDirectional.only(
                              start: deviceWidth * 0.025, end: deviceWidth * 0.01, top: deviceHeight * 0.01, bottom: deviceHeight * 0.01),
                          child: IntrinsicHeight(
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
                                      mainAxisSize: MainAxisSize.max,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: deviceAverageSize * 0.035,
                                          height: deviceAverageSize * 0.035,
                                          alignment: Alignment.center,
                                          child: Icon(
                                            CustomIcons.startMapPin,
                                            size: deviceAverageSize * 0.025,
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
                                            emptyHeight: deviceHeight * 0.008,
                                          ),
                                        ),
                                        Container(
                                          width: deviceAverageSize * 0.035,
                                          height: deviceAverageSize * 0.035,
                                          alignment: Alignment.center,
                                          child: Icon(
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
                                    children: [
                                      Container(
                                        margin: EdgeInsetsDirectional.only(end: deviceWidth * 0.02),
                                        width: deviceWidth,
                                        color: Colors.black,
                                        height: deviceHeight * 0.025,
                                      ),
                                      (position % 2 == 0)
                                          ? Container(
                                              margin: EdgeInsetsDirectional.only(top: deviceWidth * 0.005),
                                              width: deviceWidth * 0.6,
                                              color: Colors.black,
                                              height: deviceHeight * 0.025,
                                            )
                                          : Container(),
                                      Container(
                                        margin: EdgeInsetsDirectional.only(top: deviceWidth * 0.04, end: deviceWidth * 0.02),
                                        width: deviceWidth,
                                        color: Colors.black,
                                        height: deviceHeight * 0.025,
                                      ),
                                      (position % 2 != 0)
                                          ? Container(
                                              margin: EdgeInsetsDirectional.only(top: deviceWidth * 0.005),
                                              width: deviceWidth * 0.4,
                                              color: Colors.black,
                                              height: deviceHeight * 0.025,
                                            )
                                          : Container(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }, child: Container(),
                    ),
                    Container(
                      margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.025, end: deviceWidth * 0.05),
                      child: const HorizontalDashLineView(color: colorMainTabDividerColor),
                    ),
                    Container(
                      margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.025, top: deviceHeight * 0.008, end: deviceWidth * 0.045),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 0,
                            child: Container(
                              width: deviceAverageSize * 0.035,
                              height: deviceAverageSize * 0.035,
                              alignment: Alignment.center,
                              child: Icon(
                                CustomIcons.dateOrderHistoryScreen,
                                size: deviceAverageSize * 0.025,
                                color: colorTextCommon,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.015, end: deviceWidth * 0.3),
                              width: deviceWidth * 0.6,
                              color: Colors.black,
                              height: deviceHeight * 0.025,
                            ),
                          ),
                          Expanded(
                            flex: 0,
                            child: Container(
                              width: deviceWidth * 0.2,
                              color: Colors.black,
                              height: deviceHeight * 0.025,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.025, top: deviceHeight * 0.008, end: deviceWidth * 0.01),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 0,
                            child: Container(
                              width: deviceAverageSize * 0.035,
                              height: deviceAverageSize * 0.035,
                              alignment: Alignment.center,
                              child: Icon(
                                CustomIcons.timeOrderHistoryScreen,
                                size: deviceAverageSize * 0.025,
                                color: colorTextCommon,
                              ),
                            ),
                          ),
                          Container(
                            margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.015),
                            width: deviceWidth * 0.2,
                            color: Colors.black,
                            height: deviceHeight * 0.025,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
