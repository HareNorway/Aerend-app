import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../constant/constant.dart';

class SearchUserShimmer extends StatelessWidget {
  const SearchUserShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: colorShimmerBg,
      highlightColor: Colors.grey.shade100,
      period: const Duration(milliseconds: 1500),
      child: ListView.separated(
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.symmetric(horizontal: deviceWidth * 0.015, vertical: deviceHeight * 0.001),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(deviceAverageSize * 0.07),
                  child: Container(
                    width: deviceAverageSize * 0.09,
                    height: deviceAverageSize * 0.09,
                    color: Colors.black,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: deviceHeight * 0.015),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: deviceWidth * 0.5,
                          height: deviceHeight * 0.02,
                          color: Colors.black,
                        ),
                        Container(height: deviceHeight * 0.01),
                        Container(
                          width: deviceWidth * 0.3,
                          height: deviceHeight * 0.015,
                          color: Colors.black,
                        ),
                        Container(height: deviceHeight * 0.01),
                        Container(
                          width: deviceWidth * 0.4,
                          height: deviceHeight * 0.015,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        itemCount: 12,
        separatorBuilder: (BuildContext context, int index) {
          return Divider(
            indent: deviceAverageSize * 0.11,
            endIndent: deviceAverageSize * 0.015,
            thickness: 2,
          );
        },
      ),
    );
  }
}
