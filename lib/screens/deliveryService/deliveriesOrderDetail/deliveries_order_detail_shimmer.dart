import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../../../commonView/statusView/deliveries_status_view.dart';
import '../../../utils/utils.dart';

class DeliveriesOrderDetailShimmer extends StatelessWidget {
  final bool enabled;

  const DeliveriesOrderDetailShimmer({super.key, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    var padding = EdgeInsets.symmetric(
        horizontal: deviceWidth * 0.035, vertical: deviceWidth * 0.025);
    var titleTextStyle = bodyText(fontWeight: FontWeight.w600);
    return SizedBox(
      width: double.infinity,
      child: Shimmer.fromColors(
        baseColor: colorShimmerBg,
        highlightColor: Colors.grey.shade100,
        enabled: enabled,
        period: const Duration(milliseconds: 1500),
        child: SingleChildScrollView(
          padding: EdgeInsetsDirectional.only(bottom: deviceHeight * 0.1),
          child: SizedBox(
            width: deviceWidth,
            child: Column(children: [
              Container(
                padding: EdgeInsets.symmetric(vertical: deviceHeight * 0.005),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: deviceAverageSize * 0.055,
                            height: deviceAverageSize * 0.055,
                            margin: padding,
                            child: Container(
                              width: deviceAverageSize * 0.04,
                              height: deviceAverageSize * 0.04,
                              color: Colors.black,
                            ),
                          ),
                          Container(
                            width: deviceWidth * 0.4,
                            color: Colors.black,
                            height: deviceHeight * 0.025,
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      flex: 0,
                      child: DeliveriesStatusView(
                        isLeft: false,
                        orderStatus: 7,
                        padding: EdgeInsetsDirectional.only(
                            start: deviceWidth * 0.02,
                            end: deviceWidth * 0.025,
                            top: deviceHeight * 0.006,
                            bottom: deviceHeight * 0.006),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 0,
                child: Container(
                  color: Colors.black45,
                  padding: padding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsetsDirectional.only(
                            top: deviceHeight * 0.002,
                            bottom: deviceHeight * 0.005),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  deviceAverageSize * 0.008),
                              child: Container(
                                width: deviceAverageSize * 0.09,
                                height: deviceAverageSize * 0.09,
                                color: Colors.black,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Container(
                                margin: EdgeInsetsDirectional.only(
                                    start: deviceWidth * 0.015,
                                    end: deviceWidth * 0.015),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: deviceWidth * 0.4,
                                      color: Colors.black,
                                      height: deviceHeight * 0.022,
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.star,
                                          color: colorRatingStar,
                                          size: deviceAverageSize * 0.025,
                                        ),
                                        Container(
                                          margin: EdgeInsetsDirectional.only(
                                              start: deviceWidth * 0.008),
                                          width: deviceWidth * 0.1,
                                          color: Colors.black,
                                          height: deviceHeight * 0.022,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 0,
                              child: Container(
                                width: deviceAverageSize * 0.06,
                                height: deviceAverageSize * 0.06,
                                margin: EdgeInsetsDirectional.only(
                                    end: deviceWidth * 0.02),
                                child: CustomFillButton(
                                  onPressed: () {},
                                  width: deviceAverageSize * 0.06,
                                  height: deviceAverageSize * 0.06,
                                  margin: EdgeInsetsDirectional.zero,
                                  padding: EdgeInsetsDirectional.zero,
                                  borderRadius: BorderRadiusDirectional.all(
                                      Radius.circular(
                                          deviceAverageSize * 0.03)),
                                  color: colorPrimary,
                                  child: Center(
                                      child: FaIcon(
                                    FontAwesomeIcons.solidCommentDots,
                                    size: deviceAverageSize * 0.03,
                                    color: colorWhite,
                                  )),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 0,
                              child: SizedBox(
                                width: deviceAverageSize * 0.06,
                                height: deviceAverageSize * 0.06,
                                child: CustomFillButton(
                                  onPressed: () {},
                                  width: deviceAverageSize * 0.06,
                                  height: deviceAverageSize * 0.06,
                                  margin: EdgeInsetsDirectional.zero,
                                  padding: EdgeInsetsDirectional.zero,
                                  borderRadius: BorderRadiusDirectional.all(
                                      Radius.circular(
                                          deviceAverageSize * 0.03)),
                                  color: colorPrimary,
                                  child: Center(
                                    child: Icon(
                                      Icons.call_rounded,
                                      size: deviceAverageSize * 0.035,
                                      color: colorWhite,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: EdgeInsetsDirectional.only(
                                top: deviceHeight * 0.008,
                                bottom: deviceHeight * 0.005),
                            child: Text(
                              languages.deliveryAddress,
                              textAlign: TextAlign.start,
                              style: titleTextStyle,
                            ),
                          ),
                          Container(
                            width: deviceWidth,
                            color: Colors.black,
                            height: deviceHeight * 0.02,
                          ),
                          Container(
                            width: deviceWidth * 0.5,
                            color: Colors.black,
                            height: deviceHeight * 0.02,
                            margin: EdgeInsetsDirectional.only(
                                top: deviceHeight * 0.002),
                          ),
                        ],
                      ),
                      Container(
                        margin: EdgeInsetsDirectional.only(
                            top: deviceHeight * 0.008),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 0,
                              child: Container(
                                margin: EdgeInsetsDirectional.only(
                                    end: deviceWidth * 0.008),
                                child: Text(
                                  languages.landmark,
                                  textAlign: TextAlign.start,
                                  style: titleTextStyle,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Container(
                                width: deviceWidth * 0.3,
                                color: Colors.black,
                                height: deviceHeight * 0.02,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: EdgeInsetsDirectional.only(
                            top: deviceHeight * 0.008),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 0,
                              child: Container(
                                margin: EdgeInsetsDirectional.only(
                                    end: deviceWidth * 0.008),
                                child: Text(
                                  languages.flatNo,
                                  textAlign: TextAlign.start,
                                  style: titleTextStyle,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Container(
                                width: deviceWidth * 0.2,
                                color: Colors.black,
                                height: deviceHeight * 0.02,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(
                  color: colorMainBackground,
                  height: deviceHeight * 0.005,
                  thickness: deviceHeight * 0.005),
              Container(
                padding: padding,
                color: Colors.black45,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text(
                            languages.deliveryPerson,
                            textAlign: TextAlign.start,
                            style: titleTextStyle,
                          ),
                        ),
                        Expanded(
                          flex: 0,
                          child: RatingBar.builder(
                            initialRating: 4,
                            direction: Axis.horizontal,
                            allowHalfRating: true,
                            glow: false,
                            ignoreGestures: true,
                            itemCount: 5,
                            itemSize: deviceAverageSize * 0.022,
                            unratedColor: colorDisableCheckBox,
                            itemPadding: EdgeInsets.symmetric(
                                horizontal: deviceWidth * 0.001),
                            itemBuilder: (context, _) => const Icon(
                              Icons.star,
                              color: colorRatingStar,
                            ),
                            onRatingUpdate: (rating) {},
                          ),
                        ),
                      ],
                    ),
                    Container(
                      margin:
                          EdgeInsetsDirectional.only(top: deviceHeight * 0.01),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 0,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  deviceAverageSize * 0.045),
                              child: Container(
                                width: deviceAverageSize * 0.09,
                                height: deviceAverageSize * 0.09,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              margin: EdgeInsetsDirectional.only(
                                  start: deviceWidth * 0.015,
                                  end: deviceWidth * 0.015),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: deviceWidth * 0.4,
                                    color: Colors.black,
                                    height: deviceHeight * 0.022,
                                  ),
                                  Container(
                                    margin: EdgeInsetsDirectional.only(
                                        top: deviceHeight * 0.0035),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.call_rounded,
                                          size: deviceAverageSize * 0.03,
                                          color: colorMainGray,
                                        ),
                                        Expanded(
                                          child: Container(
                                            margin: EdgeInsetsDirectional.only(
                                                start: deviceWidth * 0.002),
                                            width: deviceWidth * 0.3,
                                            color: Colors.black,
                                            height: deviceHeight * 0.022,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 0,
                            child: Container(
                              width: deviceAverageSize * 0.054,
                              height: deviceAverageSize * 0.054,
                              margin: EdgeInsetsDirectional.only(
                                  end: deviceWidth * 0.02),
                              child: CustomFillButton(
                                onPressed: () {},
                                width: deviceAverageSize * 0.054,
                                height: deviceAverageSize * 0.054,
                                margin: EdgeInsetsDirectional.zero,
                                padding: EdgeInsetsDirectional.zero,
                                borderRadius: BorderRadiusDirectional.all(
                                    Radius.circular(deviceAverageSize * 0.027)),
                                color: colorPrimary,
                                child: Center(
                                    child: FaIcon(
                                  FontAwesomeIcons.solidCommentDots,
                                  size: deviceAverageSize * 0.027,
                                  color: colorWhite,
                                )),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 0,
                            child: SizedBox(
                              width: deviceAverageSize * 0.054,
                              height: deviceAverageSize * 0.054,
                              child: CustomFillButton(
                                onPressed: () {},
                                width: deviceAverageSize * 0.054,
                                height: deviceAverageSize * 0.054,
                                margin: EdgeInsetsDirectional.zero,
                                padding: EdgeInsetsDirectional.zero,
                                borderRadius: BorderRadiusDirectional.all(
                                    Radius.circular(deviceAverageSize * 0.027)),
                                color: colorPrimary,
                                child: Center(
                                    child: Icon(
                                  Icons.call_rounded,
                                  size: deviceAverageSize * 0.032,
                                  color: colorWhite,
                                )),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                  color: colorMainBackground,
                  height: deviceHeight * 0.005,
                  thickness: deviceHeight * 0.005),
              Container(
                color: Colors.black45,
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: deviceWidth * 0.4,
                      color: Colors.black,
                      height: deviceHeight * 0.025,
                    ),
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      padding:
                          EdgeInsetsDirectional.only(top: deviceHeight * 0.005),
                      itemCount: 2,
                      itemBuilder: (BuildContext context, position) {
                        return Container(
                          margin: EdgeInsetsDirectional.only(
                              top: deviceHeight * 0.01),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: deviceWidth * 0.4,
                                      color: Colors.black,
                                      height: deviceHeight * 0.022,
                                    ),
                                    Container(
                                      margin: EdgeInsetsDirectional.only(
                                          top: deviceHeight * 0.005),
                                      width: deviceWidth * 0.5,
                                      color: Colors.black,
                                      height: deviceHeight * 0.02,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 0,
                                child: Container(
                                  margin: EdgeInsetsDirectional.only(
                                      start: deviceWidth * 0.01,
                                      end: deviceWidth * 0.01),
                                  width: deviceWidth * 0.1,
                                  color: Colors.black,
                                  height: deviceHeight * 0.022,
                                ),
                              ),
                              Expanded(
                                flex: 0,
                                child: Container(
                                  width: deviceWidth * 0.2,
                                  color: Colors.black,
                                  height: deviceHeight * 0.022,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Container(
                      margin:
                          EdgeInsetsDirectional.only(top: deviceHeight * 0.015),
                      child: ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        padding: const EdgeInsetsDirectional.only(top: 0),
                        itemCount: 6,
                        itemBuilder: (BuildContext context, position) {
                          return Container(
                            margin: EdgeInsetsDirectional.only(
                                bottom: deviceHeight * 0.005),
                            child: Column(
                              children: [
                                (position == 0 ||
                                        position == 4 ||
                                        position == 5)
                                    ? Divider(
                                        color: colorDivider,
                                        height: deviceHeight * 0.006,
                                        thickness: deviceAverageSize * 0.002,
                                      )
                                    : Container(),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        margin: EdgeInsetsDirectional.only(
                                            end: (position % 2 == 0)
                                                ? deviceWidth * 0.2
                                                : deviceWidth * 0.1),
                                        width: deviceWidth * 0.6,
                                        color: Colors.black,
                                        height: deviceHeight * 0.022,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 0,
                                      child: Container(
                                        height: deviceHeight * 0.022,
                                        width: (position % 2 == 0)
                                            ? deviceWidth * 0.12
                                            : deviceWidth * 0.1,
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
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
