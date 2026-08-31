import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../constant/constant.dart';

class AddFilterShimmer extends StatelessWidget {
  final bool enabled;

  const AddFilterShimmer({super.key, this.enabled = true});

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
            itemCount: 8,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (_, __) => Container(
              margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.005, bottom: deviceHeight * 0.005),
              child: CheckboxListTile(
                contentPadding: const EdgeInsets.all(0),
                tileColor: colorWhite,
                controlAffinity: ListTileControlAffinity.leading,
                selectedTileColor: colorPrimary,
                selected: false,
                activeColor: colorWhite,
                checkColor: colorPrimary,
                title: Container(
                  width: deviceWidth * 0.6,
                  color: Colors.black,
                  margin: EdgeInsetsDirectional.only(end: deviceWidth * 0.15),
                  height: deviceHeight * 0.025,
                ),
                value: false,
                onChanged: (bool? value) {},
              ),
            ),
          ),
        ),
      );
}
