import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../utils/utils.dart';

class ItemStoreListShimmer extends StatelessWidget {
  const ItemStoreListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: deviceWidth * 0.02),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            flex: 0,
            child: Stack(
              fit: StackFit.loose,
              // alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(deviceAverageSize * 0.012)),
                  child: Container(
                    width: deviceAverageSize * 0.13,
                    height: deviceAverageSize * 0.13,
                    color: Colors.black,
                  ),
                ),
                Container(
                  width: deviceAverageSize * 0.13,
                  margin: EdgeInsetsDirectional.only(top: deviceAverageSize * 0.11),
                  child: Center(
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(deviceAverageSize * 0.005)),
                      elevation: deviceAverageSize * 0.009,
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: deviceAverageSize * 0.008),
                        width: deviceAverageSize * 0.06,
                        color: Colors.black,
                        height: deviceHeight * 0.02,
                      ),
                    ),
                  ),
                )
              ],
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
                Container(
                  width: deviceWidth * 0.4,
                  height: deviceHeight * 0.022,
                  color: Colors.black,
                ),
                Container(
                  constraints: BoxConstraints(maxHeight: deviceHeight * 0.066),
                  child: Wrap(
                    clipBehavior: Clip.antiAlias,
                    children: "Fast Food, Combo"
                        .split(",")
                        .map<Widget>((s) => Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(deviceAverageSize * 0.006),
                              color: colorGray,
                            ),
                            padding: EdgeInsets.symmetric(horizontal: deviceWidth * 0.01),
                            margin: EdgeInsetsDirectional.only(end: deviceWidth * 0.01, top: deviceHeight * 0.004, bottom: deviceHeight * 0.004),
                            child: Text(s, style: bodyText(fontSize: textSizeSmallest, textColor: colorTextCommonLight))))
                        .toList(),
                  ),
                ),
                // SizedBox(height: deviceHeight * 0.005),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      FaIcon(FontAwesomeIcons.clock, size: deviceAverageSize * 0.02, color: colorTextCommonLight),
                      SizedBox(width: deviceWidth * 0.01),
                      Flexible(
                        child: Container(
                          width: deviceWidth * 0.2,
                          height: deviceHeight * 0.02,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsetsDirectional.only(top: deviceWidth * 0.005, bottom: deviceHeight * 0.005),
                  child: Row(
                    children: [
                      FaIcon(
                        CustomIcons.offer,
                        size: deviceAverageSize * 0.021,
                        color: colorOfferDiscountGray,
                      ),
                      SizedBox(width: deviceWidth * 0.005),
                      Expanded(
                        flex: 1,
                        child: Container(
                          width: deviceWidth * 0.3,
                          height: deviceHeight * 0.02,
                          color: Colors.black,
                        ),
                      ),
                      Container(
                        height: deviceAverageSize * 0.012,
                        width: deviceAverageSize * 0.012,
                        margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.02, end: deviceWidth * 0.02),
                        decoration: const BoxDecoration(
                          color: colorRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: deviceWidth * 0.2,
                        height: deviceHeight * 0.02,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
                Divider(
                  color: colorGray,
                  thickness: deviceHeight * 0.0015,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
