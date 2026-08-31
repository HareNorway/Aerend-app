import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../../commonView/dash_line_view.dart';
import '../../../../commonView/statusView/ride_status_view.dart';
import '../../../../utils/child_size_notifier.dart';
import '../../../../utils/utils.dart';
import '../../../rideService/rideDetail/ride_detail.dart';
import 'rides_history_dl.dart';

class ItemRidesHistory extends StatelessWidget {
  final RidesItem ridesItem;
  final PagingController pagingController;

  const ItemRidesHistory({
    super.key,
    required this.ridesItem,
    required this.pagingController,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        openScreenWithResult(
          context,
          RideDetail(
            rideId: ridesItem.rideId,
            rideType: ridesItem.categoryName,
          ),
        ).then((value) {
          pagingController.refresh();
        });
      },
      child: Card(
        margin: EdgeInsetsDirectional.only(
          top: deviceHeight * 0.008,
          bottom: deviceHeight * 0.008,
        ),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(deviceAverageSize * 0.002),
        ),
        child: Container(
          padding: EdgeInsetsDirectional.only(
            start: deviceWidth * 0.02,
            top: deviceHeight * 0.01,
            bottom: deviceHeight * 0.01,
          ),
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
                      margin: EdgeInsetsDirectional.only(
                        top: deviceHeight * 0.012,
                        start: deviceWidth * 0.025,
                      ),
                      child: LoadImageWithPlaceHolder(
                        width: deviceAverageSize * 0.04,
                        height: deviceAverageSize * 0.04,
                        image: ridesItem.categoryIcon,
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      margin: EdgeInsetsDirectional.only(
                        start: deviceWidth * 0.03,
                        top: deviceHeight * 0.012,
                      ),
                      child: Text(
                        ridesItem.categoryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.start,
                        style: bodyText(
                          fontSize: textSizeMediumBig,
                          textColor: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 0,
                    child: RideStatusView(
                      isRentalRide:
                          ((ridesItem.serviceCategoryId) == 31 ||
                          (ridesItem.serviceCategoryId) == 32),
                      isLeft: false,
                      rideStatus: ridesItem.rideStatus,
                      padding: EdgeInsetsDirectional.only(
                        start: deviceWidth * 0.02,
                        end: deviceWidth * 0.01,
                        top: deviceHeight * 0.006,
                        bottom: deviceHeight * 0.006,
                      ),
                    ),
                  ),
                ],
              ),
              ChildSizeNotifier(
                builder: (context, size, child) {
                  return Container(
                    padding: EdgeInsetsDirectional.only(
                      start: deviceWidth * 0.025,
                      end: deviceWidth * 0.01,
                      top: deviceHeight * 0.01,
                      bottom: deviceHeight * 0.01,
                    ),
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
                                    margin: EdgeInsetsDirectional.only(
                                      top: deviceHeight * 0.002,
                                      bottom: deviceHeight * 0.002,
                                    ),
                                    child: DashLineView(
                                      dashColor: colorMainTabDividerColor,
                                      totalHeight: (size.height > 0
                                          ? size.height / 2.8
                                          : 0),
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
                                Text(
                                  ridesItem.pickupAddress,
                                  textAlign: TextAlign.start,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: bodyText(
                                    fontSize: textSizeSmallest,
                                    textColor: colorTextCommonDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsetsDirectional.only(
                                    top: deviceHeight * 0.02,
                                  ),
                                  child: Text(
                                    ridesItem.destinationAddress,
                                    textAlign: TextAlign.start,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: bodyText(
                                      fontSize: textSizeSmallest,
                                      textColor: colorTextCommonDark,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(),
              ),
              Container(
                margin: EdgeInsetsDirectional.only(
                  start: deviceWidth * 0.025,
                  end: deviceWidth * 0.05,
                ),
                child: const HorizontalDashLineView(
                  color: colorMainTabDividerColor,
                ),
              ),
              Container(
                margin: EdgeInsetsDirectional.only(
                  start: deviceWidth * 0.025,
                  top: deviceHeight * 0.008,
                  end: deviceWidth * 0.045,
                ),
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
                        margin: EdgeInsetsDirectional.only(
                          start: deviceWidth * 0.015,
                        ),
                        child: Text(
                          getDateTime(
                            ridesItem.serviceDateTime,
                            returnFormat: "dd MMM, yyyy",
                          ),
                          // ridesItem?.pickupDate ?? "-",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                          style: bodyText(
                            fontSize: textSizeSmallest,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 0,
                      child: Text(
                        getAmountWithCurrency(
                          getDoubleFromDynamic(ridesItem.totalPay),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.start,
                        style: bodyText(
                          textColor: Theme.of(context).colorScheme.primary,
                          fontSize: textSizeBig,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsetsDirectional.only(
                  start: deviceWidth * 0.025,
                  top: deviceHeight * 0.008,
                  end: deviceWidth * 0.01,
                ),
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
                    Expanded(
                      flex: 1,
                      child: Container(
                        margin: EdgeInsetsDirectional.only(
                          start: deviceWidth * 0.015,
                        ),
                        child: Text(
                          getDateTime(
                            ridesItem.serviceDateTime,
                            returnFormat: "hh:mm aa",
                          ),
                          // ridesItem?.pickupTime ?? "-",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                          style: bodyText(
                            fontSize: textSizeSmallest,
                            fontWeight: FontWeight.w600,
                          ),
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
    );
  }
}
