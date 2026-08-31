import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../utils/utils.dart';

class NoRecordFound extends StatelessWidget {
  final String? image, message;
  final double? height, rippleHeight, rippleImgSize;
  final bool? withRipple;
  final IconData? rippleIconData;
  final Widget? widget;

  const NoRecordFound({
    super.key,
    this.image,
    this.message,
    this.rippleIconData,
    this.height,
    this.rippleHeight,
    this.widget,
    this.rippleImgSize,
    this.withRipple = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            withRipple!
                ? Stack(
                    alignment: AlignmentDirectional.center,
                    children: [
                      SvgPicture.asset(
                        "assets/svgs/no_record_circle_bg.svg",
                        fit: BoxFit.contain,
                        height: rippleHeight ?? deviceHeight * 0.3,
                        colorFilter: const ColorFilter.mode(
                            colorPrimary, BlendMode.srcIn),
                      ),
                      Icon(
                        rippleIconData,
                        size: rippleImgSize ?? deviceHeight * 0.12,
                        color: colorPrimary,
                      ),
                    ],
                  )
                : SvgPicture.asset(
                    image ?? "assets/svgs/no_data_found.svg",
                    fit: BoxFit.contain,
                    height: height ?? deviceHeight * 0.18,
                  ),
            if (widget != null) widget!,
            if (message != null)
              Container(
                margin: EdgeInsetsDirectional.only(
                  start: deviceWidth * 0.01,
                  end: deviceWidth * 0.01,
                  top: deviceHeight * 0.015,
                ),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  // Default `bodyText()` uses a dark color; in dark mode it becomes invisible.
                  style: bodyText(
                    textColor: isDark ? Colors.white : null,
                  ),
                ),
              )
            else
              Container(),
          ],
        ),
      ),
    );
  }
}
