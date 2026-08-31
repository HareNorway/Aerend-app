import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../commonView/modal_ui.dart';
import '../utils/utils.dart';

class WarningDialog extends StatelessWidget {
  const WarningDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAliasWithSaveLayer,
      insetPadding: EdgeInsets.only(
        left: deviceWidth * 0.035,
        right: deviceWidth * 0.035,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(deviceAverageSize * 0.01),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            margin: EdgeInsetsDirectional.only(
              bottom: deviceHeight * 0.025,
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.triangleExclamation,
                      color: colorRed,
                      size: deviceAverageSize * 0.035,
                    ),
                    SizedBox(width: deviceWidth * 0.03),
                    Text(
                      "Warning!".toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: headerText(
                        fontSize: 0.036,
                        textColor: colorRed,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: deviceWidth * 0.03),
                    FaIcon(
                      FontAwesomeIcons.triangleExclamation,
                      color: colorRed,
                      size: deviceAverageSize * 0.035,
                    ),
                  ],
                ),
                SizedBox(height: deviceHeight * 0.03),
                SvgPicture.asset(
                  "assets/svgs/warning.svg",
                  width: deviceAverageSize * 0.2,
                  height: deviceAverageSize * 0.2,
                ),
                SizedBox(height: deviceHeight * 0.03),
                RichText(
                  text: TextSpan(
                    text: "This system is Designed and Developed by ",
                    style: bodyText(
                      fontSize: textSizeBig,
                      fontWeight: FontWeight.w600,
                    ),
                    children: [
                      TextSpan(
                        text: "whitelabelfox.com",
                        style: bodyText(
                          fontSize: textSizeBig,
                          fontWeight: FontWeight.w600,
                          textColor: colorRed,
                        ),
                        recognizer: TapGestureRecognizer()..onTap = () {},
                      ),
                      TextSpan(
                        text:
                            " and holding 100% Selling rights for this system.",
                        style: bodyText(
                          fontSize: textSizeBig,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: deviceHeight * 0.015),
                Text(
                  "White Label Fox is located in the western part of India. We DO NOT have any representatives, Resellers, or Partner companies anywhere in the world. Please email at \"sales@whitelabelfox.com\" or WhatsApp on \"+91 79849 31943\". If someone claims this Ærend system to be his/her and is planning to sell it to you. He/She is probably a scammer.",
                  textAlign: TextAlign.start,
                  style: bodyText(
                    fontSize: textSizeSmallest,
                    textColor: colorTextCommonLight,
                  ),
                ),
                ModalUi.actionRow(
                  context,
                  primaryLabel: "I Agree, Let me Explore",
                  secondaryLabel: "Cancel",
                  onPrimaryPressed: () {
                    Navigator.pop(context, true);
                  },
                  onSecondaryPressed: () => Navigator.pop(context, false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
