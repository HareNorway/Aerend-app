import 'package:flutter/material.dart';

import '../../../commonView/common_circular_progress_indicator.dart';
import '../../../utils/utils.dart';
import 'checkout_dl.dart';

class ItemCartProductList extends StatelessWidget {
  final ProductQuantityListItem productQuantityListItem;
  final String productName;
  final Function() onTapMinus, onTapPlush;

  const ItemCartProductList(
      {super.key, required this.productQuantityListItem,
      required this.productName,
      required this.onTapMinus,
      required this.onTapPlush});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.symmetric(vertical: deviceHeight * 0.010),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              productName,
              textAlign: TextAlign.start,
              style: bodyText(textColor: colorBlack, fontWeight: FontWeight.bold, fontSize: textSizeMediumBig),
            ),
            if ((productQuantityListItem.productAddOns).isNotEmpty)
              Container(
                margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.004),
                child: Text(
                  productQuantityListItem.productAddOns,
                  textAlign: TextAlign.start,
                  style: bodyText(fontSize: textSizeSmall, textColor: colorMainGray, fontWeight: FontWeight.normal),
                ),
              ),
            SizedBox(
              height: deviceHeight * 0.005,
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Flexible(
                  flex: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: deviceWidth * 0.005, vertical: deviceHeight * 0.002),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(deviceAverageSize * 0.01)),
                        border: Border.all(color: colorDivider, width: deviceAverageSize * 0.0025)),
                    constraints: BoxConstraints(minWidth: deviceWidth * 0.18),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        InkWell(onTap: onTapMinus, child: Icon(Icons.remove, size: deviceAverageSize * 0.035, color: colorBlack)),
                        productQuantityListItem.isLoading
                            ? CommonCircularProgressIndicator(
                                strokeWidth: deviceAverageSize * 0.0025,
                                size: deviceHeight * 0.018,
                                color: colorBlack,
                              )
                            : Text(
                                productQuantityListItem.productQuantity.toString(),
                                style: bodyText(fontWeight: FontWeight.w600, textColor: colorBlack),
                              ),
                        InkWell(onTap: onTapPlush, child: Icon(Icons.add, size: deviceAverageSize * 0.035, color: colorBlack)),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 0,
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(start: deviceWidth * 0.02, end: deviceWidth * 0.02),
                    child: Text("X",
                        textAlign: TextAlign.start,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: bodyText(fontSize: textSizeSmallest, textColor: colorTextCommonLight, fontWeight: FontWeight.w600)),
                  ),
                ),
                Flexible(
                  flex: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: deviceWidth * 0.02),
                    constraints: BoxConstraints(minWidth: deviceWidth * 0.18),
                    child: Text(getAmountWithCurrency(getDoubleFromDynamic(productQuantityListItem.priceForOne))),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    getAmountWithCurrency(getDoubleFromDynamic(productQuantityListItem.productAmount)),
                    textAlign: TextAlign.end,
                    style: bodyText(textColor: colorPrimary, fontWeight: FontWeight.w600, fontSize: textSizeMediumBig),
                  ),
                ),
              ],
            ),
          ],
        ));
  }
}
