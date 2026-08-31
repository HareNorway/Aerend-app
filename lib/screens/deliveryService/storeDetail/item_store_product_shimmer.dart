import 'package:flutter/material.dart';

import '../../../utils/utils.dart';

class ItemStoreProductShimmer extends StatelessWidget {
  const ItemStoreProductShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(height: deviceHeight * 0.025, color: colorShimmerBg),
              SizedBox(height: deviceHeight * 0.01),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      getAmountWithCurrency(0),
                      textAlign: TextAlign.start,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bodyText(),
                    ),
                  ),
                  SizedBox(width: deviceWidth * 0.01),
                ],
              ),
              SizedBox(height: deviceHeight * 0.005),
              Container(
                height: deviceHeight * 0.0125,
                color: colorShimmerBg,
                margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.0025),
              ),
              Container(
                height: deviceHeight * 0.0125,
                color: colorShimmerBg,
                margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.0025),
              ),
              Container(
                height: deviceHeight * 0.0125,
                color: colorShimmerBg,
                margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.0025),
              ),
            ],
          ),
        ),
        SizedBox(width: deviceWidth * 0.025),
        Expanded(
          flex: 0,
          child: Column(
            children: [
              Stack(
                fit: StackFit.loose,
                children: [
                  Container(
                    width: deviceWidth * 0.2826,
                    height: deviceWidth * 0.2826,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(deviceAverageSize * 0.015)),
                      color: colorShimmerBg,
                    ),
                  ),
                  Container(
                    width: deviceWidth * 0.2826,
                    margin: EdgeInsets.only(top: deviceWidth * 0.25),
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: deviceWidth * 0.01, vertical: deviceHeight * 0.004),
                        decoration: BoxDecoration(
                          color: colorShimmerBg,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.grey,
                              offset: Offset(1.0, 1.0), //(x,y)
                              blurRadius: 3.0,
                            ),
                          ],
                          borderRadius: BorderRadius.all(Radius.circular(deviceAverageSize * 0.01)),
                        ),
                        constraints: BoxConstraints(minWidth: deviceWidth * 0.225),
                        child: Text(
                          languages.add.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: bodyText(fontWeight: FontWeight.w600, textColor: colorBlack, fontSize: textSizeMediumBig),
                        ),
                      ),
                    ),
                  )
                ],
              ),
              SizedBox(height: deviceHeight * 0.002),
            ],
          ),
        ),
      ],
    );
  }
}
