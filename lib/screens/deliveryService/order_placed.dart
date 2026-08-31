import 'package:flutter/material.dart';

import '../../commonView/common_view.dart';
import '../../commonView/no_record_found.dart';
import '../../utils/utils.dart';
import '../common/homeMainV1/home_main_v1.dart';
import 'trackOrder/track_order.dart';

class OrderPlaced extends StatelessWidget {
  final int? orderId;
  final String? orderNo;

  const OrderPlaced({super.key, required this.orderId, required this.orderNo});

  @override
  Widget build(BuildContext context) => WillPopScope(
      child: Scaffold(
        backgroundColor: colorWhite,
        appBar: AppBar(
          automaticallyImplyLeading: true,
          centerTitle: false,
          titleSpacing: 0,
          title: Text(
            languages.orderPlaced,
            textAlign: TextAlign.start,
            style: toolbarStyle(),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: NoRecordFound(
                rippleIconData: CustomIcons.orderPlaced,
                withRipple: true,
                widget: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(vertical: deviceHeight * 0.015),
                      child: Text(
                        languages.thankYou,
                        style: bodyText(fontWeight: FontWeight.bold, fontSize: textSizeBig),
                      ),
                    ),
                    Text(
                      languages.orderPlacedMsg,
                      style: bodyText(textColor: colorMainGray, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            CustomRoundedButton(
              context,
              languages.trackOrder,
              () {
                openScreenWithClearPrevious(context, TrackOrder(orderId: orderId ?? 0, isFromPlacedOrder: true));
              },
              minHeight: commonBtnHeightMedium,
              minWidth: 0.93,
              margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.055, bottom: deviceHeight * 0.025),
              padding: EdgeInsetsDirectional.zero,
            ),
          ],
        ),
      ),
      onWillPop: () {
        openScreenWithClearPrevious(context, const HomeMainV1());
        return Future(() => true);
      });
}
