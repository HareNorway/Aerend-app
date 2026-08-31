import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../commonView/common_view.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';

class ManageAddressShimmer extends StatelessWidget {
  final bool enabled;

  const ManageAddressShimmer({super.key, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Shimmer.fromColors(
        baseColor: colorShimmerBg,
        highlightColor: ScSaasThemeTokens.rowHover,
        enabled: enabled,
        period: const Duration(milliseconds: 1500),
        child: Stack(
          children: [
            Container(
              margin: const EdgeInsetsDirectional.only(top: 5),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsetsDirectional.only(top: 0, bottom: 80),
                itemCount: 8,
                itemBuilder: (BuildContext context, position) {
                  return Card(
                    margin: EdgeInsets.symmetric(
                      vertical: deviceHeight * 0.01,
                      horizontal: deviceWidth * 0.035,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        deviceAverageSize * 0.005,
                      ),
                    ),
                    elevation: 0,
                    color: ScSaasThemeTokens.card,
                    child: Container(
                      padding: EdgeInsetsDirectional.only(
                        start: deviceWidth * 0.032,
                        end: deviceWidth * 0.032,
                        top: deviceHeight * 0.015,
                        bottom: deviceHeight * 0.015,
                      ),
                      width: double.infinity,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 0,
                                child: Icon(
                                  CustomIcons.homeAddress,
                                  size: deviceAverageSize * 0.035,
                                  color: colorTextCommon,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(
                                  margin: EdgeInsetsDirectional.only(
                                    start: deviceWidth * 0.025,
                                    end: deviceWidth * 0.05,
                                  ),
                                  width: deviceWidth * 0.3,
                                  height: deviceHeight * 0.025,
                                  color: colorBlack,
                                ),
                              ),
                              Expanded(
                                flex: 0,
                                child: Padding(
                                  padding: EdgeInsetsDirectional.all(
                                    deviceAverageSize * 0.01,
                                  ),
                                  child: Icon(
                                    CustomIcons.edit,
                                    size: deviceAverageSize * 0.025,
                                    color: ScSaasThemeTokens.muted,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 0,
                                child: Padding(
                                  padding: EdgeInsetsDirectional.all(
                                    deviceAverageSize * 0.01,
                                  ),
                                  child: Icon(
                                    CustomIcons.deleteBin,
                                    size: deviceAverageSize * 0.025,
                                    color: ScSaasThemeTokens.muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            margin: EdgeInsetsDirectional.only(
                              top: deviceHeight * 0.01,
                            ),
                            width: deviceWidth,
                            height: deviceHeight * 0.023,
                            color: colorBlack,
                          ),
                          Container(
                            margin: EdgeInsetsDirectional.only(
                              top: deviceHeight * 0.002,
                            ),
                            width: deviceWidth * 0.5,
                            height: deviceHeight * 0.023,
                            color: colorBlack,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              alignment: Alignment.bottomCenter,
              child: CustomRoundedButton(
                context,
                languages.addNewAddress,
                () {},
                fontWeight: FontWeight.bold,
                textSize: textSizeBig,
                minWidth: deviceWidth,
                bgColor: ScSaasThemeTokens.primary,
                textColor: ScSaasThemeTokens.card,
                minHeight: commonBtnHeight,
                padding: EdgeInsetsDirectional.only(
                  start: deviceWidth * 0.18,
                  end: deviceWidth * 0.18,
                ),
                margin: EdgeInsetsDirectional.only(
                  start: deviceWidth * 0.05,
                  end: deviceWidth * 0.05,
                  top: deviceHeight * 0.05,
                  bottom: deviceHeight * 0.035,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
