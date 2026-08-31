import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../commonView/modal_ui.dart';
import '../utils/utils.dart';

// Please do not translate this popup for languages even if ask by testers!!
class DemoDialog extends StatelessWidget {
  const DemoDialog({super.key});

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
                Text(
                  "This is product Version",
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: headerText(
                    fontSize: 0.036,
                    textColor: colorPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: deviceHeight * 0.03),
                SvgPicture.asset(
                  "assets/svgs/demo_dialog.svg",
                  width: deviceAverageSize * 0.25,
                  height: deviceAverageSize * 0.25,
                ),
                SizedBox(height: deviceHeight * 0.03),
                // Please do not change for languages...
                Text(
                  "This is a Fox-Delivery-Anything Customer App of Fox-Delivery-Anything product. Explore the services and features of app",
                  textAlign: TextAlign.start,
                  style: bodyText(
                    fontSize: textSizeBig,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: deviceHeight * 0.015),
                Text(
                  "The purpose of this version app is that people can understand what they getting from this app, how our app works, what are features we provide, and many more.",
                  style: bodyText(
                    fontSize: textSizeSmallest,
                    textColor: colorTextCommonLight,
                  ),
                  textAlign: TextAlign.justify,
                ),
                ModalUi.actionRow(
                  context,
                  primaryLabel: "Proceed",
                  secondaryLabel: "Contact Sales Support",
                  onPrimaryPressed: () {
                    Navigator.pop(context, true);
                  },
                  onSecondaryPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
