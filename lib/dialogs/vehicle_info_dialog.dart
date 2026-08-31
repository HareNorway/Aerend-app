import 'package:flutter/material.dart';

import '../commonView/modal_ui.dart';
import '../screens/common/base_dl.dart';
import '../theme/sc_saas_theme.dart';
import '../utils/utils.dart';

class VehicleInfoDialog extends StatelessWidget {
  final List<KeyValueModel> vehicleList;

  const VehicleInfoDialog({super.key, required this.vehicleList});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.only(
        left: deviceWidth * 0.035,
        right: deviceWidth * 0.035,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(deviceAverageSize * 0.02),
      ),
      backgroundColor: ScSaasThemeTokens.card,
      child: Container(
        width: double.infinity,
        padding: EdgeInsetsDirectional.only(
          top: deviceHeight * 0.015,
          start: deviceWidth * 0.035,
          end: deviceWidth * 0.035,
          bottom: deviceHeight * 0.015,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ModalUi.handle(),
            const SizedBox(height: 12),
            Text(
              languages.vehicleInformation,
              textAlign: TextAlign.start,
              style: bodyText(
                fontSize: 0.034,
                fontWeight: FontWeight.w700,
                textColor: ScSaasThemeTokens.text,
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: vehicleList.length,
              padding: EdgeInsets.zero,
              itemBuilder: (BuildContext context, position) {
                return ((vehicleList[position].value).isNotEmpty)
                    ? Container(
                        margin: EdgeInsetsDirectional.only(
                          top: deviceHeight * 0.012,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              vehicleList[position].key,
                              textAlign: TextAlign.start,
                              style: bodyText(
                                fontSize: textSizeRegular,
                                fontWeight: FontWeight.w600,
                                textColor: ScSaasThemeTokens.text,
                              ),
                            ),
                            Text(
                              vehicleList[position].value,
                              textAlign: TextAlign.start,
                              style: bodyText(
                                fontSize: textSizeLarge,
                                fontWeight: FontWeight.w700,
                                textColor: ScSaasThemeTokens.text,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container();
              },
            ),
            Align(
              alignment: AlignmentDirectional.center,
              child: CustomFillButton(
                margin: EdgeInsetsDirectional.only(
                  start: deviceWidth * 0.02,
                  top: deviceHeight * 0.02,
                  end: deviceWidth * 0.035,
                  bottom: deviceHeight * 0.01,
                ),
                color: ScSaasThemeTokens.primary,
                width: deviceWidth * 0.8,
                height: deviceHeight * 0.06,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsetsDirectional.only(
                  start: deviceWidth * 0.005,
                  end: deviceWidth * 0.005,
                ),
                borderRadius: BorderRadiusDirectional.only(
                  topStart: topLeftRadius,
                  topEnd: topRightRadius,
                  bottomStart: bottomLeftRadius,
                  bottomEnd: bottomRightRadius,
                ),
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: Text(
                  languages.ok.toUpperCase(),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: bodyText(
                    fontSize: textSizeMediumBig,
                    textColor: colorWhite,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
