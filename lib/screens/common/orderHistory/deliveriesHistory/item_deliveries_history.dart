import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../../commonView/dash_line_view.dart';
import '../../../../commonView/statusView/deliveries_status_view.dart';
import '../../../../utils/utils.dart';
import '../../../deliveryService/deliveriesOrderDetail/deliveries_order_detail.dart';
import '../../repeat_order/reorder.dart';
import 'deliveries_history_dl.dart';

class ItemDeliveriesHistory extends StatelessWidget {
  final DeliveriesHistoryItem deliveriesHistoryItem;
  final PagingController pagingController;

  const ItemDeliveriesHistory({
    super.key,
    required this.deliveriesHistoryItem,
    required this.pagingController,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        openScreenWithResult(
          context,
          DeliveriesOrderDetail(
            isFromTrackOrderActivity: false,
            orderId: deliveriesHistoryItem.orderId,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(deviceAverageSize * 0.002),
        ),
        elevation: 0,
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
                        image: deliveriesHistoryItem.categoryIcon,
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
                        deliveriesHistoryItem.categoryName,
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
                    child: DeliveriesStatusView(
                      isLeft: false,
                      orderStatus: deliveriesHistoryItem.orderStatus,
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
              Container(
                margin: EdgeInsetsDirectional.only(
                  start: deviceWidth * 0.025,
                  top: deviceHeight * 0.008,
                  end: deviceWidth * 0.01,
                  bottom: deviceHeight * 0.008,
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
                          CustomIcons.destinationMapPin,
                          size: deviceAverageSize * 0.03,
                          color: colorRed,
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
                          (deliveriesHistoryItem.userTakenType) == 2
                              ? languages.pickup
                              : (deliveriesHistoryItem.deliveryAddress),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                          style: bodyText(
                            fontSize: textSizeSmallest,
                            textColor: colorTextCommonDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
                            deliveriesHistoryItem.serviceDateTime,
                            returnFormat: "dd MMM, yyyy",
                          ),
                          // deliveriesHistoryItem?.serviceDate ?? "-",
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
                          getDoubleFromDynamic(deliveriesHistoryItem.totalPay),
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
                            deliveriesHistoryItem.serviceDateTime,
                            returnFormat: "hh:mm a",
                          ),
                          // deliveriesHistoryItem?.serviceTime ?? "-",
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
              if (deliveriesHistoryItem.storeName.trim().isNotEmpty)
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
                            CustomIcons.store,
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
                            deliveriesHistoryItem.storeName,
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
              if (deliveriesHistoryItem.allowReorder == 1)
                Container(
                  margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.008),
                  child: Reorder(orderId: deliveriesHistoryItem.orderId),
                ),
              // Container(
              //     margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.01),
              //     child: CustomRoundedButton(context, "Repeat", () {},
              //         margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.02, end: deviceWidth * 0.02),
              //         setBorder: true,
              //         textSize: textSizeSmall,
              //         padding: EdgeInsetsDirectional.only(start: deviceWidth * 0.02, end: deviceWidth * 0.02),
              //         minHeight: 0.035,
              //         minWidth: 1))
            ],
          ),
        ),
      ),
    );
  }
}
