import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../constant/constant.dart';

class WalletTransactionShimmer extends StatelessWidget {
  final bool enabled;

  const WalletTransactionShimmer({super.key, this.enabled = true});

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
            padding: EdgeInsetsDirectional.only(top: 0, bottom: deviceHeight * 0.02),
            itemCount: 8,
            itemBuilder: (BuildContext context, position) {
              return Container(
                color: Colors.black45,
                margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.012),
                padding: EdgeInsetsDirectional.only(
                    start: deviceWidth * 0.03, top: deviceHeight * 0.015, end: deviceWidth * 0.02, bottom: deviceHeight * 0.015),
                child: Row(
                  children: [
                    Expanded(
                      flex: 0,
                      child: Image.asset(
                        "assets/images/ic_add_money.png",
                        width: deviceAverageSize * 0.065,
                        height: deviceAverageSize * 0.065,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        alignment: AlignmentDirectional.centerStart,
                        margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.025),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: deviceWidth * 0.6,
                              color: Colors.black,
                              height: deviceHeight * 0.025,
                            ),
                            Container(
                              margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.01),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      margin: EdgeInsetsDirectional.only(end: deviceWidth * 0.2),
                                      width: deviceWidth * 0.4,
                                      color: Colors.black,
                                      height: deviceHeight * 0.025,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 0,
                                    child: Container(
                                      alignment: AlignmentDirectional.bottomEnd,
                                      margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.005),
                                      width: deviceWidth * 0.2,
                                      color: Colors.black,
                                      height: deviceHeight * 0.025,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
}
