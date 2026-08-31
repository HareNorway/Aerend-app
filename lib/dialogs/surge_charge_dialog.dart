import 'package:flutter/material.dart';

import '../commonView/common_view.dart';
import '../commonView/modal_ui.dart';
import '../theme/sc_saas_theme.dart';
import '../utils/utils.dart';

class SurgeChargeDialog extends StatefulWidget {
  final double costPerKm, costPerMin, charge;
  final Function onPositiveBtnClick;

  const SurgeChargeDialog(
      {required this.onPositiveBtnClick,
      required this.costPerKm,
      required this.costPerMin,
      required this.charge,
      super.key});

  @override
  State<SurgeChargeDialog> createState() => _SurgeChargeDialogState();
}

class _SurgeChargeDialogState extends State<SurgeChargeDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAliasWithSaveLayer,
      insetPadding: EdgeInsets.only(
          left: deviceWidth * 0.035, right: deviceWidth * 0.035),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(deviceAverageSize * 0.02)),
      child: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: EdgeInsetsDirectional.only(
            bottom: deviceHeight * 0.01,
            top: deviceHeight * 0.025,
            start: deviceWidth * 0.05,
            end: deviceWidth * 0.05,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              ModalUi.handle(),
              const SizedBox(height: 12),
              Text(
                languages.surgePricing,
                textAlign: TextAlign.start,
                style: bodyText(
                    fontSize: textSizeLargest,
                    textColor: ScSaasThemeTokens.text,
                    fontWeight: FontWeight.w600),
              ),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(deviceAverageSize * 0.005),
                    border: Border.all(
                        color: ScSaasThemeTokens.border, width: deviceAverageSize * 0.002),
                    color: ScSaasThemeTokens.rowHover),
                padding: EdgeInsetsDirectional.only(
                    start: deviceWidth * 0.02,
                    end: deviceWidth * 0.02,
                    top: deviceHeight * 0.015,
                    bottom: deviceHeight * 0.015),
                margin: EdgeInsetsDirectional.only(
                    top: deviceHeight * 0.03,
                    start: deviceWidth * 0.02,
                    end: deviceWidth * 0.02),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "${widget.charge}X",
                      textAlign: TextAlign.start,
                      style: bodyText(
                          fontSize: 0.12,
                        textColor: ScSaasThemeTokens.primary,
                          fontWeight: FontWeight.w600),
                    ),
                    Text(
                      languages.ofTotalFare,
                      textAlign: TextAlign.start,
                      style: bodyText(
                        fontSize: textSizeLarge, textColor: ScSaasThemeTokens.text),
                    ),
                    if ((widget.costPerKm) > 0 || (widget.costPerMin) > 0)
                      Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                                deviceAverageSize * 0.005),
                            border: Border.all(
                              color: ScSaasThemeTokens.border,
                                width: deviceAverageSize * 0.002),
                            color: ScSaasThemeTokens.rowHover),
                        padding: EdgeInsetsDirectional.only(
                            start: deviceWidth * 0.06,
                            end: deviceWidth * 0.06,
                            top: deviceHeight * 0.001,
                            bottom: deviceHeight * 0.002),
                        margin: EdgeInsetsDirectional.only(
                            top: deviceHeight * 0.01,
                            bottom: deviceHeight * 0.01,
                            start: deviceWidth * 0.02,
                            end: deviceWidth * 0.02),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if ((widget.costPerKm) > 0)
                              Text(
                                "${getAmountWithCurrency(widget.costPerKm)}/${languages.km.toLowerCase()}",
                                textAlign: TextAlign.start,
                                style: bodyText(
                                    fontSize: textSizeMediumBig,
                                  textColor: ScSaasThemeTokens.muted),
                              ),
                            if ((widget.costPerMin) > 0)
                              Text(
                                ", ${getAmountWithCurrency(widget.costPerMin)}/${languages.min.toLowerCase()}",
                                textAlign: TextAlign.start,
                                style: bodyText(
                                    fontSize: textSizeMediumBig,
                                  textColor: ScSaasThemeTokens.muted),
                              ),
                          ],
                        ),
                      ),
                    Text(
                      languages.surgeChargeMsg,
                      textAlign: TextAlign.center,
                      style: bodyText(
                          fontSize: textSizeSmall,
                          textColor: ScSaasThemeTokens.muted),
                    ),
                  ],
                ),
              ),
              CustomRoundedButton(
                context,
                languages.iAcceptHigherFare,
                () {
                  widget.onPositiveBtnClick();
                },
                margin: EdgeInsetsDirectional.only(
                    top: deviceHeight * 0.03, bottom: deviceHeight * 0.01),
                fontWeight: FontWeight.bold,
                textSize: textSizeBig,
                minHeight: commonBtnHeight,
                minWidth: double.infinity,
                bgColor: ScSaasThemeTokens.primary,
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context, true);
                },
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                      start: deviceWidth * 0.06,
                      end: deviceWidth * 0.06,
                      top: deviceHeight * 0.02,
                      bottom: deviceHeight * 0.02),
                  child: Text(
                    languages.tryLater,
                    textAlign: TextAlign.center,
                    style: bodyText(
                            fontSize: textSizeRegular,
                          textColor: ScSaasThemeTokens.muted,
                            fontWeight: FontWeight.w600)
                        .copyWith(decoration: TextDecoration.underline),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
