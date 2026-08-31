import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../utils/utils.dart';

class SelectLanguageAndCurrencyShimmer extends StatelessWidget {
  final bool enabled;

  const SelectLanguageAndCurrencyShimmer({super.key, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Shimmer.fromColors(
        baseColor: colorShimmerBg,
        highlightColor: Colors.grey.shade100,
        enabled: enabled,
        period: const Duration(milliseconds: 1500),
        child: Wrap(
          spacing: deviceWidth * 0.035,
          children: [1, 2, 3, 4, 5]
              .map<Padding>((s) => Padding(
                    padding: EdgeInsetsDirectional.only(top: deviceHeight * 0.005, bottom: deviceHeight * 0.005),
                    child: ChoiceChip(
                      label: Container(
                        width: deviceWidth * ((s % 2 == 0) ? 0.25 : 0.15),
                        color: Colors.black,
                        height: deviceHeight * 0.025,
                      ),
                      labelPadding: EdgeInsetsDirectional.only(
                          top: deviceHeight * 0.008, bottom: deviceHeight * 0.008, start: deviceWidth * 0.025, end: deviceWidth * 0.025),
                      labelStyle: bodyText(textColor: colorWhite, fontSize: textSizeSmall, fontWeight: FontWeight.w500),
                      backgroundColor: colorPrimary,
                      selectedColor: colorPrimary,
                      pressElevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadiusDirectional.only(
                              topStart: Radius.circular(deviceAverageSize * 0.005),
                              topEnd: Radius.circular(deviceAverageSize * 0.005),
                              bottomStart: Radius.circular(deviceAverageSize * 0.005),
                              bottomEnd: Radius.circular(deviceAverageSize * 0.005)),
                          side: const BorderSide(color: colorPrimary)),
                      selected: false,
                      onSelected: (selected) {},
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
