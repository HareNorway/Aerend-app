import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../utils/utils.dart';
import 'ds_home_dl.dart';

class ItemStoreList extends StatelessWidget {
  final StoreListItem storeListItem;

  const ItemStoreList({super.key, required this.storeListItem});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(deviceAverageSize * 0.018),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LoadImageWithPlaceHolder(
                width: deviceAverageSize * 0.12,
                height: deviceAverageSize * 0.12,
                image: storeListItem.storeBanner,
                borderRadius: BorderRadius.circular(deviceAverageSize * 0.01),
              ),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.02),
                      child: Text(
                        storeListItem.storeName,
                        textAlign: TextAlign.center,
                        style: bodyText(fontSize: textSizeRegular, textColor: colorBlack, fontWeight: FontWeight.normal),
                      ),
                    ),
                    Container(
                      height: deviceHeight * 0.03,
                      margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.016, top: deviceHeight * 0.008),
                      child: ListView.builder(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsetsDirectional.only(top: 0),
                        itemCount: storeListItem.storeProducts.split(',').length,
                        itemBuilder: (BuildContext context, position) {
                          return Container(
                            margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.008, end: deviceWidth * 0.008),
                            padding: EdgeInsetsDirectional.only(
                                start: deviceWidth * 0.01, end: deviceWidth * 0.01, top: deviceHeight * 0.002, bottom: deviceHeight * 0.002),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(deviceAverageSize * 0.005),
                              color: colorGray,
                            ),
                            child: Text(
                              storeListItem.storeProducts.split(',')[position],
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              style: bodyText(fontSize: textSizeSmallest, textColor: colorTextCommon, fontWeight: FontWeight.normal),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.02, top: deviceHeight * 0.008),
                      child: Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: colorRatingStar,
                            size: deviceAverageSize * 0.03,
                          ),
                          Container(
                            margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.006),
                            child: Text(
                              storeListItem.averageRatings.toString(),
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              textAlign: TextAlign.start,
                              style: bodyText(fontSize: textSizeSmallest, textColor: colorTextCommonLight, fontWeight: FontWeight.normal),
                            ),
                          ),
                          Container(
                            height: deviceAverageSize * 0.006,
                            width: deviceAverageSize * 0.006,
                            margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.01, end: deviceWidth * 0.014),
                            decoration: const BoxDecoration(
                              color: colorTextCommonLight,
                              shape: BoxShape.circle,
                            ),
                          ),
                          FaIcon(
                            FontAwesomeIcons.clock,
                            size: deviceAverageSize * 0.023,
                            color: colorMainGray,
                          ),
                          Container(
                            margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.006),
                            child: Text(
                              "${storeListItem.orderDeliveryTime} ${languages.min}",
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              textAlign: TextAlign.start,
                              style: bodyText(fontSize: textSizeSmallest, textColor: colorTextCommonLight, fontWeight: FontWeight.normal),
                            ),
                          ),
                          Container(
                            height: deviceAverageSize * 0.006,
                            width: deviceAverageSize * 0.006,
                            margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.012, end: deviceWidth * 0.012),
                            decoration: const BoxDecoration(
                              color: colorTextCommonLight,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Flexible(
                              child: Text(
                            "${getAmountWithCurrency(storeListItem.orderMinAmount.toDouble())} ${languages.minOrder}",
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            textAlign: TextAlign.start,
                            style: bodyText(fontSize: textSizeSmallest, textColor: colorTextCommonLight, fontWeight: FontWeight.normal),
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Container(
            margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.006),
            child: Row(
              children: [
                Flexible(
                  flex: 1,
                  child: Row(
                    children: [
                      Image.asset(
                        "assets/images/discount.png",
                        height: deviceAverageSize * 0.03,
                        width: deviceAverageSize * 0.03,
                        color: storeListItem.offer.isNotEmpty ? colorOfferDiscountRed : colorOfferDiscountGray,
                      ),
                      Flexible(
                        child: Container(
                          margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.01),
                          child: Text(
                            storeListItem.offer.isNotEmpty ? storeListItem.offer: languages.noOfferAvailable,
                            textAlign: TextAlign.start,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: bodyText(fontSize: textSizeSmall, textColor: colorBlack, fontWeight: FontWeight.normal),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  flex: 0,
                  child: Row(
                    children: [
                      Container(
                        height: deviceAverageSize * 0.008,
                        width: deviceAverageSize * 0.008,
                        margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.01, end: deviceWidth * 0.01),
                        decoration: BoxDecoration(
                          color: storeListItem.storeStatus == 1 ? colorGreenLight : colorRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        storeListItem.storeStatus == 1 ? languages.openNow.toUpperCase() : languages.closed.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: bodyText(
                            fontSize: textSizeSmall,
                            textColor: storeListItem.storeStatus == 1 ? colorGreenLight : colorRed,
                            fontWeight: FontWeight.normal),
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
