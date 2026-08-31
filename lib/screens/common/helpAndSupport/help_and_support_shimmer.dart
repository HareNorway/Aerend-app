import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../constant/constant.dart';

class HelpAndSupportShimmer extends StatelessWidget {
  final bool enabled;

  const HelpAndSupportShimmer({super.key, this.enabled = true});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: Shimmer.fromColors(
          baseColor: colorShimmerBg,
          highlightColor: Colors.grey.shade100,
          enabled: enabled,
          period: const Duration(milliseconds: 1500),
          child: ListView.separated(
            separatorBuilder: (context, index) => Divider(
              color: colorMainView,
              thickness: deviceHeight * 0.002,
              height: 0,
            ),
            shrinkWrap: true,
            padding: EdgeInsetsDirectional.only(top: 0, bottom: deviceHeight * 0.02),
            itemCount: 5,
            itemBuilder: (BuildContext context, position) {
              return ListTile(
                onTap: () {},
                horizontalTitleGap: 0,
                title: Container(
                  margin: EdgeInsetsDirectional.only(end: (position % 2 == 0) ? deviceWidth * 0.3 : deviceWidth * 0.1),
                  height: deviceHeight * 0.025,
                  width: double.infinity,
                  color: Colors.black,
                ),
              );
            },
          ),
        ),
      );
}
