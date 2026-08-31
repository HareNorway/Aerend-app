import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../constant/constant.dart';

class ProductGridShimmer extends StatelessWidget {
  final bool enabled;

  const ProductGridShimmer({super.key, this.enabled = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Shimmer.fromColors(
        baseColor: colorShimmerBg,
        highlightColor: Colors.grey.shade100,
        enabled: enabled,
        period: const Duration(milliseconds: 1500),
        child: GridView.builder(
          shrinkWrap: true,
          itemCount: 8,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.99,
            crossAxisSpacing: deviceWidth * 0.03,
            mainAxisSpacing: deviceHeight * 0.015,
          ),
          padding: EdgeInsetsDirectional.only(start: deviceWidth * 0.03, end: deviceWidth * 0.03, bottom: deviceWidth * 0.03),
          itemBuilder: (_, __) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(color: colorWhite, borderRadius: BorderRadius.all(Radius.circular(deviceAverageSize * 0.012))),
                  ),
                ),
                Container(
                  height: deviceHeight * 0.01,
                  width: deviceWidth * 0.4,
                  color: colorWhite,
                  margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.01),
                ),
                Container(
                  height: deviceHeight * 0.01,
                  width: deviceWidth * 0.1,
                  color: colorWhite,
                  margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.01),
                ),
                Container(
                  height: deviceHeight * 0.035,
                  width: deviceWidth * 0.2,
                  decoration: BoxDecoration(color: colorWhite, borderRadius: BorderRadius.all(Radius.circular(deviceAverageSize * 0.012))),
                  margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.01),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
