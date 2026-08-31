import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../constant/constant.dart';

class CustomShimmerLayout extends StatelessWidget {
  final bool enabled;

  const CustomShimmerLayout({super.key, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: deviceWidth * 0.03, vertical: deviceHeight * 0.005),
      child: Shimmer.fromColors(
        baseColor: colorShimmerBg,
        highlightColor: Colors.grey[100]!,
        enabled: enabled,
        period: const Duration(milliseconds: 1500),
        child: ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (_, __) => Padding(
            padding: EdgeInsets.only(bottom: deviceHeight * 0.02),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: deviceAverageSize * 0.11,
                  height: deviceAverageSize * 0.11,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                SizedBox(width: deviceWidth * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: double.infinity,
                        height: deviceHeight * 0.016,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      SizedBox(height: deviceHeight * 0.008),
                      Container(
                        width: double.infinity * 0.75,
                        height: deviceHeight * 0.014,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      SizedBox(height: deviceHeight * 0.008),
                      Container(
                        width: double.infinity * 0.5,
                        height: deviceHeight * 0.014,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          itemCount: 8,
        ),
      ),
    );
  }
}
