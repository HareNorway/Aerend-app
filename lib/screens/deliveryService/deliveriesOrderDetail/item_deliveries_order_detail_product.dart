import 'package:flutter/material.dart';

import '../../../utils/utils.dart';
import 'deliveries_order_detail_dl.dart';

class ItemDeliveriesOrderDetailProduct extends StatelessWidget {
  final ProductListItem productListItem;

  const ItemDeliveriesOrderDetailProduct({super.key, required this.productListItem});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: deviceHeight * 0.002),
      alignment: Alignment.topLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: deviceHeight * 0.001),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (productListItem.productName.isNotEmpty)
                  Container(
                    margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.005, bottom: deviceHeight * 0.005),
                    child: Text(
                      productListItem.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bodyText(fontSize: textSizeMediumBig, textColor: colorTextCommon, fontWeight: FontWeight.w700),
                    ),
                  ),
                (productListItem.addOns).trim().isNotEmpty
                    ? Text(
                        productListItem.addOns,
                        textAlign: TextAlign.start,
                        style: bodyText(fontSize: textSizeSmallest),
                      )
                    : Container(),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: deviceAverageSize * 0.045,
                height: deviceAverageSize * 0.045,
                alignment: AlignmentDirectional.center,
                decoration: BoxDecoration(
                    color: colorPrimaryDark.withOpacity(0.15),
                    borderRadius: BorderRadius.all(Radius.circular(deviceAverageSize * 0.005)),
                    border: Border.all(color: colorPrimary, width: deviceWidth * 0.003)),
                child: Text(
                  "${productListItem.productQuantity}",
                  style: bodyText(fontSize: textSizeSmallest),
                ),
              ),
              Expanded(
                flex: 0,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(start: deviceWidth * 0.025, end: deviceWidth * 0.025),
                  child: Text("X",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bodyText(fontSize: textSizeSmallest, textColor: colorTextCommonLight, fontWeight: FontWeight.w600)),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(getAmountWithCurrency(productListItem.productPrice),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bodyText(fontSize: textSizeSmallest, textColor: colorTextCommonLight, fontWeight: FontWeight.w600)),
              ),
              Expanded(
                flex: 1,
                child: Text(getAmountWithCurrency(productListItem.productPriceForOne),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bodyText(textColor: colorTextCommon, fontSize: textSizeRegular, fontWeight: FontWeight.w700)),
              ),
            ],
          )
        ],
      ),
    );
  }

// @override
// Widget build(BuildContext context) => Container(
//       margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.01),
//       child: Row(
//         mainAxisSize: MainAxisSize.max,
//         mainAxisAlignment: MainAxisAlignment.start,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   productListItem?.productName ?? "-",
//                   textAlign: TextAlign.start,
//                   style: bodyText(textColor: colorBlack),
//                 ),
//                 (productListItem?.addOns ?? "").trim().isNotEmpty
//                     ? Text(
//                         productListItem?.addOns ?? "",
//                         textAlign: TextAlign.start,
//                         style: bodyText(fontSize: textSizeSmallest),
//                       )
//                     : Container(),
//               ],
//             ),
//             flex: 1,
//           ),
//           Expanded(
//             child: Container(
//               margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.01, end: deviceWidth * 0.01),
//               child: Text(
//                 "x${productListItem?.productQuantity ?? 0}",
//                 textAlign: TextAlign.start,
//                 style: bodyText(fontSize: textSizeSmall, textColor: colorBlack),
//               ),
//             ),
//             flex: 0,
//           ),
//           Expanded(
//             child: Text(
//               getAmountWithCurrency(getDoubleFromDynamic(productListItem?.productPriceForOne ?? "0")),
//               textAlign: TextAlign.start,
//               style: bodyText(fontSize: textSizeSmall, textColor: colorBlack),
//             ),
//             flex: 0,
//           ),
//         ],
//       ),
//     );
}
