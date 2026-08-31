import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../utils/utils.dart';

class ItemDishes extends StatelessWidget {
  final String image;
  final String name;
  final String storeName;
  final String price;
  final String oldPrice;

  const ItemDishes({
    super.key,
    required this.image,
    required this.name,
    required this.storeName,
    required this.price,
    required this.oldPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: deviceWidth * 0.02),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: colorGray))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            flex: 0,
            child: LoadImageWithPlaceHolder(
              width: deviceAverageSize * 0.13,
              height: deviceAverageSize * 0.13,
              image: image,
              borderRadius: BorderRadius.all(Radius.circular(deviceAverageSize * 0.012)),
            ),
          ),
          SizedBox(width: deviceWidth * 0.025),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  name,
                  textAlign: TextAlign.start,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: headerText(fontSize: textSizeMediumBig),
                ),
                SizedBox(height: deviceHeight * 0.005),
                Row(
                  children: [
                    Flexible(
                      child: Text(price,
                          textAlign: TextAlign.start, maxLines: 1, overflow: TextOverflow.ellipsis, style: bodyText(fontSize: textSizeSmall)),
                    ),
                    SizedBox(width: deviceWidth * 0.01),
                    oldPrice.trim().isNotEmpty
                        ? Flexible(
                            child: Text(
                              oldPrice,
                              textAlign: TextAlign.start,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: bodyText(textColor: colorMainLightGray, fontSize: textSizeSmallest).copyWith(
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          )
                        : Container(),
                  ],
                ),
                SizedBox(height: deviceHeight * 0.005),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      FaIcon(CustomIcons.store, size: deviceAverageSize * 0.022, color: colorTextCommonLight),
                      SizedBox(width: deviceWidth * 0.01),
                      Flexible(
                        child: Text(
                          storeName,
                          textAlign: TextAlign.start,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: bodyText(fontSize: textSizeSmallest, textColor: colorTextCommonLight),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
