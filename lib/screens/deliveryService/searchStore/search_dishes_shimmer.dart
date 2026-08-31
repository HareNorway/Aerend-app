import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../../../utils/utils.dart';

class SearchDishesShimmer extends StatelessWidget {
  final bool enabled;

  const SearchDishesShimmer({super.key, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Shimmer.fromColors(
        baseColor: colorShimmerBg,
        highlightColor: Colors.grey.shade100,
        enabled: enabled,
        period: const Duration(milliseconds: 1500),
        child: ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsetsDirectional.only(start: deviceWidth * 0.025, end: deviceWidth * 0.025),
          itemCount: 8,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (_, __) => Container(
            padding: EdgeInsets.symmetric(vertical: deviceWidth * 0.02),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: colorGray))),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  flex: 0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(deviceAverageSize * 0.012)),
                    child: Container(
                      width: deviceAverageSize * 0.13,
                      height: deviceAverageSize * 0.13,
                      color: Colors.black,
                    ),
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
                        color: Colors.black,
                        height: deviceHeight * 0.025,
                      ),
                      SizedBox(height: deviceHeight * 0.005),
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              width: deviceWidth * 0.15,
                              color: Colors.black,
                              height: deviceHeight * 0.023,
                            ),
                          ),
                          SizedBox(width: deviceWidth * 0.01),
                        ],
                      ),
                      SizedBox(height: deviceHeight * 0.005),
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            FaIcon(CustomIcons.store, size: deviceAverageSize * 0.022, color: colorTextCommonLight),
                            SizedBox(width: deviceWidth * 0.01),
                            Flexible(
                              child: Container(
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
