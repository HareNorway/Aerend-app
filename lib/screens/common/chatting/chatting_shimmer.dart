import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../constant/constant.dart';

class ChattingShimmer extends StatelessWidget {
  final bool enabled;

  const ChattingShimmer({super.key, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Shimmer.fromColors(
        baseColor: colorShimmerBg,
        highlightColor: Colors.grey.shade100,
        enabled: enabled,
        period: const Duration(milliseconds: 1500),
        child: ListView(
            children: List.generate(20, (index) => index)
                .map((e) => (e % 2 == 0)
                    ? Container(
                        alignment: AlignmentDirectional.centerEnd,
                        margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.02, end: deviceWidth * 0.02),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: EdgeInsetsDirectional.only(
                                  start: deviceWidth * 0.025, end: deviceWidth * 0.025, top: deviceHeight * 0.01, bottom: deviceHeight * 0.008),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadiusDirectional.only(
                                    topStart: Radius.circular(deviceAverageSize * 0.01),
                                    topEnd: Radius.circular(deviceAverageSize * 0.01),
                                    bottomStart: Radius.circular(deviceAverageSize * 0.01),
                                    bottomEnd: Radius.zero),
                                color: const Color(0xffFDEDED),
                              ),
                              child: SizedBox(
                                width: deviceWidth * 0.6,
                                height: deviceHeight * 0.03,
                              ),
                            ),
                            Container(
                              margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.008),
                              width: deviceWidth * 0.35,
                              color: Colors.black,
                              height: deviceHeight * 0.015,
                            ),
                          ],
                        ),
                      )
                    : Container(
                        alignment: AlignmentDirectional.centerStart,
                        margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.02, start: deviceWidth * 0.02),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsetsDirectional.only(
                                  start: deviceWidth * 0.025, end: deviceWidth * 0.025, top: deviceHeight * 0.01, bottom: deviceHeight * 0.008),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadiusDirectional.only(
                                    topStart: Radius.circular(deviceAverageSize * 0.01),
                                    topEnd: Radius.circular(deviceAverageSize * 0.01),
                                    bottomStart: Radius.zero,
                                    bottomEnd: Radius.circular(deviceAverageSize * 0.01)),
                                color: const Color(0xffF5F5F5),
                              ),
                              child: SizedBox(
                                width: deviceWidth * 0.6,
                                height: deviceHeight * 0.03,
                              ),
                            ),
                            Container(
                              margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.008),
                              width: deviceWidth * 0.35,
                              color: Colors.black,
                              height: deviceHeight * 0.015,
                            ),
                          ],
                        ),
                      ))
                .toList()),
      ),
    );
  }
}
