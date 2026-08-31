import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../utils/utils.dart';

class SelectPaymentMethodShimmer extends StatelessWidget {
  final bool enabled;

  const SelectPaymentMethodShimmer({super.key, this.enabled = true});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: Shimmer.fromColors(
          baseColor: colorShimmerBg,
          highlightColor: Colors.grey.shade100,
          enabled: enabled,
          period: const Duration(milliseconds: 1500),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: 4,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (BuildContext context, position) => Column(
              children: [
                Container(
                  padding: EdgeInsetsDirectional.only(
                      top: deviceHeight * 0.015, bottom: deviceHeight * 0.015, start: deviceWidth * 0.02, end: deviceWidth * 0.02),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        margin: EdgeInsetsDirectional.only(end: deviceWidth * 0.1),
                        width: deviceWidth * 0.3,
                        color: Colors.black,
                        height: deviceHeight * 0.025,
                      ),
                      position == 1
                          ? Container(
                              margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.002),
                              child: Text(
                                languages.addCard,
                                textAlign: TextAlign.start,
                                style: bodyText(fontSize: textSizeMediumBig, textColor: colorPrimary, fontWeight: FontWeight.normal),
                              ),
                            )
                          : Container(),
                    ],
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: 3,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (BuildContext context, pos) => Container(
                    padding: EdgeInsetsDirectional.only(top: deviceHeight * 0.002, bottom: deviceHeight * 0.002, end: deviceWidth * 0.01),
                    color: Colors.black45,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 0,
                          child: Container(
                            margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.05),
                            width: deviceAverageSize * 0.045,
                            height: deviceAverageSize * 0.045,
                            color: Colors.black,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            margin:
                                EdgeInsetsDirectional.only(start: deviceWidth * 0.04, end: (pos % 2 == 0) ? deviceWidth * 0.2 : deviceWidth * 0.3),
                            width: deviceWidth * 0.6,
                            color: Colors.black,
                            height: deviceHeight * 0.025,
                          ),
                        ),
                        Expanded(
                          flex: 0,
                          child: Radio(
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            activeColor: colorPrimary,
                            groupValue: 1,
                            value: 0,
                            onChanged: (var index) {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
