import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../../../commonView/statusView/ride_status_view.dart';
import '../../../utils/child_size_notifier.dart';
import '../../../utils/utils.dart';

class RideDetailShimmer extends StatelessWidget {
  final bool enabled;

  const RideDetailShimmer({super.key, this.enabled = true});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: Shimmer.fromColors(
          baseColor: colorShimmerBg,
          highlightColor: Colors.grey.shade100,
          enabled: enabled,
          period: const Duration(milliseconds: 1500),
          child: SingleChildScrollView(
            padding: EdgeInsetsDirectional.only(
                top: deviceHeight * 0.01, start: deviceWidth * 0.018, end: deviceWidth * 0.018, bottom: deviceHeight * 0.01),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(deviceAverageSize * 0.004),
                  ),
                  color: Colors.black45,
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
                              rideStatus: 9,
                              padding: EdgeInsetsDirectional.only(
                                  start: deviceWidth * 0.02, end: deviceWidth * 0.02, top: deviceHeight * 0.004, bottom: deviceHeight * 0.004),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(),
                          ),
                        ],
                      ),
                      ChildSizeNotifier(
                        builder: (context, size, child) {
                          return Container(
                            padding: EdgeInsetsDirectional.only(
                                start: deviceWidth * 0.025, end: deviceWidth * 0.01, top: deviceHeight * 0.015, bottom: deviceHeight * 0.018),
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
                                            child: FaIcon(
                                              CustomIcons.startMapPin,
                                              size: deviceAverageSize * 0.035,
                                              color: colorPickUp,
                                            ),
                                          ),
                                          Container(
                                            alignment: AlignmentDirectional.center,
                                            height: size.height / 2.8,
                                            margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.004, bottom: deviceHeight * 0.004),
                                            child: VerticalDivider(
                                              color: colorMainTabDividerColor,
                                              thickness: deviceWidth * 0.0025,
                                            ),
                                          ),
                                          Container(
                                            width: deviceAverageSize * 0.035,
                                            height: deviceAverageSize * 0.035,
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
                                      children: [
                                        Container(
                                          margin: EdgeInsetsDirectional.only(end: deviceWidth * 0.02),
                                          width: deviceWidth,
                                          color: Colors.black,
                                          height: deviceHeight * 0.025,
                                        ),
                                        Container(
                                          margin: EdgeInsetsDirectional.only(top: deviceWidth * 0.005),
                                          width: deviceWidth * 0.6,
                                          color: Colors.black,
                                          height: deviceHeight * 0.025,
                                        ),
                                        Container(
                                          margin: EdgeInsetsDirectional.only(top: deviceWidth * 0.04, end: deviceWidth * 0.02),
                                          width: deviceWidth,
                                          color: Colors.black,
                                          height: deviceHeight * 0.025,
                                        ),
                                        Container(
                                          margin: EdgeInsetsDirectional.only(top: deviceWidth * 0.005),
                                          width: deviceWidth * 0.4,
                                          color: Colors.black,
                                          height: deviceHeight * 0.025,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }, child: Container(),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.01, bottom: deviceHeight * 0.01),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(deviceAverageSize * 0.004),
                    ),
                    color: Colors.black45,
                    child: Container(
                      width: double.infinity,
                      margin: EdgeInsetsDirectional.only(
                          start: deviceWidth * 0.035, end: deviceWidth * 0.035, top: deviceHeight * 0.01, bottom: deviceHeight * 0.01),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            languages.driver,
                            textAlign: TextAlign.start,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: bodyText(fontSize: textSizeRegular, textColor: colorBlack, fontWeight: FontWeight.w700),
                          ),
                          IntrinsicHeight(
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 0,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(deviceAverageSize * 0.05),
                                    child: Container(
                                      width: deviceAverageSize * 0.1,
                                      height: deviceAverageSize * 0.1,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 5,
                                  child: Container(
                                    margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.02),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: deviceWidth * 0.25,
                                          color: Colors.black,
                                          height: deviceHeight * 0.025,
                                        ),
                                        RatingBar.builder(
                                          initialRating: 4,
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
                                ),
                                Container(
                                  width: deviceWidth * 0.04,
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: Icon(
                                    CustomIcons.info,
                                    size: deviceAverageSize * 0.04,
                                    color: colorMainLightGray,
                                  ),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: Container(
                                    width: double.infinity,
                                    color: Colors.black54,
                                    margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.05, bottom: deviceHeight * 0.01),
                                    child: Column(
                                      children: [
                                        Container(
                                          margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.015, bottom: deviceHeight * 0.01),
                                          width: deviceAverageSize * 0.05,
                                          height: deviceAverageSize * 0.05,
                                          color: Colors.black,
                                        ),
                                        Container(
                                          margin: EdgeInsetsDirectional.only(
                                            bottom: deviceHeight * 0.01,
                                            start: deviceWidth * 0.05,
                                            end: deviceWidth * 0.05,
                                          ),
                                          width: deviceWidth * 0.15,
                                          color: Colors.black,
                                          height: deviceHeight * 0.025,
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
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.005),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(deviceAverageSize * 0.004),
                    ),
                    color: Colors.black45,
                    child: Container(
                      width: double.infinity,
                      margin: EdgeInsetsDirectional.only(
                          start: deviceWidth * 0.035, end: deviceWidth * 0.035, top: deviceHeight * 0.01, bottom: deviceHeight * 0.01),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: deviceWidth * 0.4,
                            color: Colors.black,
                            height: deviceHeight * 0.025,
                          ),
                          Container(
                            margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.015),
                            child: ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              padding: const EdgeInsetsDirectional.only(top: 0),
                              itemCount: 11,
                              itemBuilder: (BuildContext context, position) {
                                return Container(
                                  margin: EdgeInsetsDirectional.only(bottom: deviceHeight * 0.005),
                                  child: Column(
                                    children: [
                                      (position == 8 || position == 9)
                                          ? Divider(
                                              color: colorDivider,
                                              height: deviceHeight * 0.006,
                                              thickness: deviceAverageSize * 0.002,
                                            )
                                          : Container(),
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: Container(
                                              margin: EdgeInsetsDirectional.only(end: (position % 2 == 0) ? deviceWidth * 0.2 : deviceWidth * 0.1),
                                              width: deviceWidth * 0.6,
                                              color: Colors.black,
                                              height: deviceHeight * 0.025,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 0,
                                            child: Container(
                                              height: deviceHeight * 0.025,
                                              width: (position % 2 == 0) ? deviceWidth * 0.12 : deviceWidth * 0.1,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
