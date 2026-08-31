import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../utils/utils.dart';
import 'home_dl.dart';

class ItemFeaturedRestaurant extends StatelessWidget {
  final StoreLists storeLists;

  const ItemFeaturedRestaurant({super.key, required this.storeLists});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: deviceWidth * 0.44,
      margin: EdgeInsetsDirectional.only(end: deviceWidth * 0.045),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Stack(
            alignment: AlignmentDirectional.bottomCenter,
            clipBehavior: Clip.antiAlias,
            children: [
              LoadImageWithPlaceHolder(
                width: deviceWidth * 0.44,
                height: deviceHeight * 0.16,
                image: storeLists.storeImage,
                borderRadius: BorderRadius.all(Radius.circular(deviceAverageSize * 0.018)),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(deviceAverageSize * 0.018)),
                  gradient: LinearGradient(
                    end: const Alignment(0.0, -0.5),
                    begin: const Alignment(0.0, 1),
                    colors: <Color>[const Color(0x8A000000), Colors.black12.withOpacity(0.0)],
                  ),
                ),
                width: deviceWidth * 0.44,
                height: deviceHeight * 0.16,
                child: Container(),
              ),
              if ((storeLists.offer).trim().isNotEmpty)
                Container(
                  margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.015, bottom: deviceHeight * 0.008),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 0,
                        child: Icon(CustomIcons.offer, size: deviceAverageSize * 0.025, color: colorRed),
                      ),
                      SizedBox(width: deviceWidth * 0.015),
                      Expanded(
                        flex: 1,
                        child: Text(
                          storeLists.offer,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                          style: bodyText(fontSize: 0.021, textColor: colorWhite),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: deviceHeight * 0.005),
          Text(
            storeLists.storeName,
            textAlign: TextAlign.start,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: headerText(fontSize: textSizeMediumBig),
          ),
          SizedBox(height: deviceHeight * 0.005),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (storeLists.averageRatings != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FaIcon(FontAwesomeIcons.solidStar, size: deviceAverageSize * 0.02, color: colorRatingStar),
                    SizedBox(width: deviceWidth * 0.01),
                    Flexible(
                      child: Text(
                        "${storeLists.averageRatings}",
                        textAlign: TextAlign.start,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: bodyText(fontSize: textSizeSmallest),
                      ),
                    ),
                    Container(
                      height: deviceAverageSize * 0.006,
                      width: deviceAverageSize * 0.006,
                      margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.02, end: deviceWidth * 0.02),
                      decoration: const BoxDecoration(
                        color: colorTextCommonLight,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              if (storeLists.etaDeliveryTime != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FaIcon(FontAwesomeIcons.clock, size: deviceAverageSize * 0.02, color: colorTextCommonLight),
                    SizedBox(width: deviceWidth * 0.01),
                    Flexible(
                      child: Text(
                        "${storeLists.etaDeliveryTime} ${languages.min}",
                        textAlign: TextAlign.start,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: bodyText(fontSize: textSizeSmallest),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if ((storeLists.storeProducts).trim().isNotEmpty)
            Container(
              height: deviceHeight * 0.03,
              margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.008, top: deviceHeight * 0.005),
              child: ListView.builder(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsetsDirectional.zero,
                itemCount: storeLists.storeProducts.split(",").length,
                itemBuilder: (BuildContext context, position) {
                  return Container(
                    margin: EdgeInsetsDirectional.only(end: deviceWidth * 0.016),
                    padding: EdgeInsetsDirectional.only(
                        start: deviceWidth * 0.01, end: deviceWidth * 0.01, top: deviceHeight * 0.002, bottom: deviceHeight * 0.002),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(deviceAverageSize * 0.005),
                      color: colorGray,
                    ),
                    child: Text(
                      storeLists.storeProducts.split(",")[position],
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      style: bodyText(fontSize: textSizeSmallest, textColor: colorTextCommonLight),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
