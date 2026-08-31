import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../utils/utils.dart';
import 'item_tip.dart';

class CheckOutShimmer extends StatelessWidget {
  final bool enabled;

  const CheckOutShimmer({super.key, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Shimmer.fromColors(
        baseColor: colorShimmerBg,
        highlightColor: Colors.grey.shade100,
        enabled: enabled,
        period: const Duration(milliseconds: 1500),
        child: SingleChildScrollView(
          padding: EdgeInsetsDirectional.only(top: deviceHeight * 0.015, start: deviceWidth * 0.015, end: deviceWidth * 0.015),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.005),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: deviceAverageSize * 0.15,
                      height: deviceAverageSize * 0.15,
                      margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.02),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(deviceAverageSize * 0.016), color: colorWhite),
                    ),
                    Expanded(
                      child: Container(
                        margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.03),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(height: deviceHeight * 0.015, width: deviceWidth * 0.3, color: colorWhite),
                            Container(
                              margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.005),
                              color: colorWhite,
                              child: Container(margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.005), height: deviceHeight * 0.0125, width: deviceWidth * 0.6),
                            ),
                            Container(
                              margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.002),
                              color: colorWhite,
                              child: Container(margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.005), height: deviceHeight * 0.0125, width: deviceWidth * 0.6),
                            ),
                            Container(
                              margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.002),
                              color: colorWhite,
                              child: Container(margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.005), height: deviceHeight * 0.0125, width: deviceWidth * 0.6),
                            ),
                            Container(
                              margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.002),
                              color: colorWhite,
                              child: Container(margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.005), height: deviceHeight * 0.0125, width: deviceWidth * 0.6),
                            ),
                            Container(
                              margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.002),
                              color: colorWhite,
                              child: Container(margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.005), height: deviceHeight * 0.0125, width: deviceWidth * 0.3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.025, top: deviceHeight * 0.01),
                child: Text(
                  languages.cartDetail,
                  textAlign: TextAlign.start,
                  style: bodyText(fontSize: textSizeRegular, textColor: colorBlack, fontWeight: FontWeight.normal),
                ),
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsetsDirectional.only(
                  start: deviceWidth * 0.025,
                  end: deviceWidth * 0.025,
                  bottom: deviceHeight * 0.005,
                ),
                child: ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  padding: const EdgeInsetsDirectional.only(top: 0),
                  itemCount: 3,
                  itemBuilder: (BuildContext context, position) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: deviceHeight * 0.015,
                          width: deviceWidth * 0.25,
                          color: colorWhite,
                          margin: EdgeInsetsDirectional.only(bottom: deviceHeight * 0.01, top: deviceHeight * 0.01),
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
                                  border: Border.all(color: colorWhite, width: deviceAverageSize * 0.0025),
                                ),
                                constraints: BoxConstraints(minWidth: deviceWidth * 0.18),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Icon(Icons.remove, size: deviceAverageSize * 0.035, color: colorBlack),
                                    Text(
                                      "1",
                                      style: bodyText(fontWeight: FontWeight.w600, textColor: colorBlack),
                                    ),
                                    Icon(Icons.add, size: deviceAverageSize * 0.035, color: colorBlack),
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
                                child: Text(getAmountWithCurrency(0)),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                getAmountWithCurrency(0),
                                textAlign: TextAlign.end,
                                style: bodyText(textColor: colorPrimary, fontWeight: FontWeight.w600, fontSize: textSizeMediumBig),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              Container(
                width: double.infinity,
                color: colorWhite,
                height: deviceHeight * 0.035,
                margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.02, end: deviceWidth * 0.02, top: deviceHeight * 0.015, bottom: deviceHeight * 0.01),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    height: deviceHeight * 0.005,
                  ),
                  Padding(
                    padding: EdgeInsetsDirectional.only(start: deviceWidth * 0.03, end: deviceWidth * 0.03, top: deviceHeight * 0.018, bottom: deviceHeight * 0.01),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          CustomIcons.tipToDriver,
                          color: colorTextCommonLight,
                          size: deviceAverageSize * 0.035,
                        ),
                        SizedBox(
                          width: deviceWidth * 0.02,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                languages.addTipToDriver,
                                textAlign: TextAlign.start,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: bodyText(fontSize: textSizeSmall, fontWeight: FontWeight.bold),
                              ),
                              ItemTip(tipList: const [1, 2, 3, 0], defaultSelected: 0, onSelectionChanged: (tip) {}),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: deviceWidth * 0.025, vertical: deviceHeight * 0.02),
                child: Row(
                  children: [
                    Image.asset(
                      "assets/images/discount.png",
                      height: deviceAverageSize * 0.036,
                      width: deviceAverageSize * 0.036,
                      color: colorOfferDiscountRed,
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.015),
                        child: Text(
                          languages.applyPromoCode,
                          textAlign: TextAlign.start,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: bodyText(),
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, color: colorTextCommon, size: deviceAverageSize * 0.035),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsetsDirectional.only(
                  bottom: deviceHeight * 0.01,
                  top: deviceHeight * 0.005,
                  start: deviceWidth * 0.02,
                  end: deviceWidth * 0.02,
                ),
                child: Divider(color: colorMainView, thickness: deviceHeight * 0.0012, height: 0),
              ),
              Container(
                padding: EdgeInsetsDirectional.only(start: deviceWidth * 0.025, end: deviceWidth * 0.025, top: deviceHeight * 0.012, bottom: deviceHeight * 0.008),
                child: ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  padding: const EdgeInsetsDirectional.only(top: 0),
                  itemCount: 6,
                  itemBuilder: (BuildContext context, position) {
                    return Container(
                      margin: EdgeInsetsDirectional.only(bottom: deviceHeight * 0.01),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Container(
                                  margin: EdgeInsetsDirectional.only(end: (position % 2 == 0) ? deviceWidth * 0.2 : deviceWidth * 0.1),
                                  width: deviceWidth * 0.6,
                                  color: Colors.black,
                                  height: deviceHeight * 0.02,
                                ),
                              ),
                              Expanded(
                                flex: 0,
                                child: Container(
                                  height: deviceHeight * 0.02,
                                  width: (position % 2 == 0) ? deviceWidth * 0.12 : deviceWidth * 0.1,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: CustomFillButton(
                      onPressed: () {},
                      width: deviceWidth * 0.2,
                      height: commonBtnHeightMedium,
                      margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.025, end: deviceWidth * 0.015, top: deviceHeight * 0.025, bottom: deviceHeight * 0.015),
                      padding: EdgeInsetsDirectional.zero,
                      borderRadius:
                          BorderRadiusDirectional.only(topStart: topLeftRadius, topEnd: topRightRadius, bottomStart: bottomLeftRadius, bottomEnd: bottomRightRadius),
                      color: colorPrimary,
                      child: Text(
                        languages.scheduleOrder,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: bodyText(fontSize: textSizeRegular, textColor: colorWhite, fontWeight: FontWeight.normal),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: CustomFillButton(
                      onPressed: () {},
                      width: deviceWidth * 0.2,
                      height: commonBtnHeightMedium,
                      margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.025, end: deviceWidth * 0.025, top: deviceHeight * 0.025, bottom: deviceHeight * 0.015),
                      padding: EdgeInsetsDirectional.zero,
                      borderRadius: BorderRadiusDirectional.only(
                        topStart: topLeftRadius,
                        topEnd: topRightRadius,
                        bottomStart: bottomLeftRadius,
                        bottomEnd: bottomRightRadius,
                      ),
                      color: colorPrimary,
                      child: Text(
                        languages.orderNow,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: bodyText(fontSize: textSizeRegular, textColor: colorWhite, fontWeight: FontWeight.normal),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
