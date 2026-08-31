import 'package:flutter/material.dart';
import '../../../utils/utils.dart';
import 'package:shimmer/shimmer.dart';

class NotificationsShimmer extends StatelessWidget {
  final bool enabled;

  const NotificationsShimmer({required this.enabled, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Shimmer.fromColors(
        baseColor: colorShimmerBg,
        highlightColor: Colors.grey.shade100,
        enabled: enabled,
        period: const Duration(milliseconds: 1500),
        child: ListView.separated(
          separatorBuilder: (context, index) => Divider(
            color: colorMainView,
            thickness: deviceHeight * 0.001,
            height: 0,
          ),
          shrinkWrap: true,
          padding:
              EdgeInsetsDirectional.only(start: deviceWidth * 0.04, end: deviceWidth * 0.04, top: deviceHeight * 0.005, bottom: deviceHeight * 0.005),
          itemCount: 15,
          itemBuilder: (_, __) => Padding(
            padding: EdgeInsetsDirectional.only(top: deviceHeight * 0.01, bottom: deviceHeight * 0.01),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: deviceWidth * 0.5,
                  color: Colors.black,
                  height: deviceHeight * 0.025,
                ),
                SizedBox(height: deviceHeight * 0.005),
                Container(
                  width: deviceWidth * 0.8,
                  color: Colors.black,
                  height: deviceHeight * 0.022,
                ),
                SizedBox(height: deviceHeight * 0.005),
                Container(
                  width: deviceWidth * 0.4,
                  color: Colors.black,
                  height: deviceHeight * 0.02,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
