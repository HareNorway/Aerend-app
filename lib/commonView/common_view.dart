import 'package:flutter/material.dart';
import 'package:aerend_customer/screens/common/homeMainV1/home_main_v1.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../dialogs/simple_dialog_util.dart';
import '../screens/common/editProfile/edit_profile.dart';
import '../theme/sc_saas_theme.dart';
import '../utils/utils.dart';

class CustomRoundedButton extends StatelessWidget {
  final BuildContext context;
  final String text;
  final GestureTapCallback? onPressed;
  final Color? bgColor;
  final Color? textColor;
  final Color? progressColor;
  final Color? borderColor;
  final Widget? icon;
  final Widget? widget;
  final double? textSize;
  final double? progressSize;
  final double? progressStrokeWidth;
  final double? elevation;
  final double? iconTextSpacing;
  final double? borderWidth;
  final bool setBorder;
  final bool setProgress;
  final int maxLine;
  final TextAlign textAlign;
  final FontWeight fontWeight;
  final RoundedRectangleBorder? roundedRectangleBorder;
  final EdgeInsetsDirectional margin;
  final EdgeInsetsDirectional padding;
  final MaterialTapTargetSize materialTapTargetSize;
  final double minHeight;
  final double minWidth;

  const CustomRoundedButton(
    this.context,
    this.text,
    this.onPressed, {
    this.bgColor,
    this.textColor,
    this.progressColor,
    this.borderColor,
    this.icon,
    this.widget,
    this.textSize,
    this.progressSize,
    this.progressStrokeWidth,
    this.elevation,
    this.iconTextSpacing,
    this.borderWidth,
    this.setBorder = false,
    this.setProgress = false,
    this.maxLine = 1,
    this.textAlign = TextAlign.start,
    this.fontWeight = FontWeight.normal,
    this.roundedRectangleBorder,
    this.margin = EdgeInsetsDirectional.zero,
    this.padding = EdgeInsetsDirectional.zero,
    this.materialTapTargetSize = MaterialTapTargetSize.shrinkWrap,
    this.minHeight = 0.0,
    this.minWidth = 0.0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Color mainBgColor = bgColor ?? colorPrimary;
    mainBgColor = onPressed == null ? lighten(mainBgColor) : mainBgColor;

    return Container(
      margin: margin,
      child: CustomBorderButton(
        onPressed: setProgress ? null : onPressed,
        border:
            roundedRectangleBorder ??
            RoundedRectangleBorder(
              borderRadius: BorderRadiusDirectional.only(
                topStart: topRightRadius,
                topEnd: topLeftRadius,
                bottomStart: bottomRightRadius,
                bottomEnd: bottomLeftRadius,
              ),
            ),
        borderColor: borderColor ?? mainBgColor,
        bgColor: setBorder ? null : mainBgColor,
        icon: icon,
        minHeight: minHeight,
        minWidth: minWidth,
        setBorder: setBorder,
        tapTargetSize: materialTapTargetSize,
        padding: padding,
        elevation: elevation,
        borderWidth: borderWidth,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            setProgress
                ? Flexible(
                    child: SizedBox(
                      width: deviceHeight * (progressSize ?? cpiSizeSmall),
                      height: deviceHeight * (progressSize ?? cpiSizeSmall),
                      child: CircularProgressIndicator(
                        strokeWidth:
                            deviceAverageSize *
                            (progressStrokeWidth ?? cpiStrokeWidthSmall),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progressColor ??
                              (setBorder
                                  ? bgColor ?? colorPrimary
                                  : colorWhite),
                        ),
                      ),
                    ),
                  )
                : Flexible(
                    child:
                        widget ??
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (icon != null)
                              Flexible(
                                child: Container(
                                  margin: EdgeInsetsDirectional.only(
                                    end: deviceWidth * 0.02,
                                  ),
                                  child: icon,
                                ),
                              ),
                            Flexible(
                              child: Text(
                                text,
                                overflow: TextOverflow.ellipsis,
                                maxLines: maxLine,
                                textAlign: textAlign,
                                style: bodyText(
                                  fontSize: textSize ?? textSizeRegular,
                                  fontWeight: fontWeight,
                                  textColor:
                                      textColor ??
                                      (setBorder
                                          ? bgColor ?? colorPrimary
                                          : colorWhite),
                                ),
                              ),
                            ),
                          ],
                        ),
                  ),
          ],
        ),
      ),
    );
  }
}

class CustomBorderButton extends StatelessWidget {
  final GestureTapCallback? onPressed;
  final Widget? child;
  final Widget? icon;
  final Color? bgColor;
  final Color? borderColor;
  final double? borderWidth;
  final double? minHeight;
  final double? minWidth;
  final double? elevation;
  final EdgeInsetsDirectional? padding;
  final bool? setBorder;
  final MaterialTapTargetSize? tapTargetSize;
  final RoundedRectangleBorder? border;

  const CustomBorderButton({
    super.key,
    this.onPressed,
    this.child,
    this.bgColor,
    this.borderColor,
    this.borderWidth,
    this.border,
    this.icon,
    this.minHeight = 0,
    this.setBorder = false,
    this.padding = EdgeInsetsDirectional.zero,
    this.minWidth = 0,
    this.tapTargetSize = MaterialTapTargetSize.shrinkWrap,
    this.elevation,
  });

  // Values < 1 are legacy screen-fractions; >= 1 are fixed px (Ærend spec).
  double _resolve(double value, double dimension) =>
      value < 1 ? dimension * value : value;

  @override
  Widget build(BuildContext context) {
    var borderRadiusDirectional = BorderRadiusDirectional.only(
      topStart: topRightRadius,
      topEnd: topLeftRadius,
      bottomStart: bottomRightRadius,
      bottomEnd: bottomLeftRadius,
    );
    return !setBorder!
        ? ElevatedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: bgColor ?? colorPrimary,
              tapTargetSize: tapTargetSize,
              elevation: elevation,
              padding: padding,
              minimumSize: Size(
                _resolve(minWidth!, deviceWidth),
                _resolve(minHeight!, deviceHeight),
              ),
              shape:
                  border ??
                  RoundedRectangleBorder(borderRadius: borderRadiusDirectional),
            ),
            onPressed: onPressed != null
                ? () {
                    FocusManager.instance.primaryFocus!.unfocus();
                    onPressed?.call();
                  }
                : null,
            child: child,
          )
        : OutlinedButton(
            style: OutlinedButton.styleFrom(
              tapTargetSize: tapTargetSize,
              minimumSize: Size(
                _resolve(minWidth!, deviceWidth),
                _resolve(minHeight!, deviceHeight),
              ),
              padding: padding,
              foregroundColor: bgColor ?? colorPrimary,
              shape:
                  border ??
                  RoundedRectangleBorder(borderRadius: borderRadiusDirectional),
              side: BorderSide(
                color: borderColor ?? colorPrimary,
                width: deviceAverageSize * (borderWidth ?? 0.002),
              ),
            ),
            onPressed: onPressed != null
                ? () {
                    FocusManager.instance.primaryFocus!.unfocus();
                    onPressed?.call();
                  }
                : null,
            child: child!,
          );
  }
}

class Error extends StatelessWidget {
  final String? errorMessage;

  final Function()? onRetryPressed;

  const Error({super.key, this.errorMessage, this.onRetryPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (errorMessage != null)
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: bodyText(
                textColor: ScSaasThemeTokens.danger,
                fontSize: 18,
              ),
            ),
          if (errorMessage != null) const SizedBox(height: 8),
          IconButton(
            onPressed: onRetryPressed,
            icon: const Icon(Icons.refresh, color: ScSaasThemeTokens.danger),
          ),
        ],
      ),
    );
  }
}

Widget indicator(bool isActive) {
  return AnimatedContainer(
    duration: const Duration(milliseconds: 150),
    margin: EdgeInsets.symmetric(horizontal: deviceWidth * 0.005),
    height: isActive ? deviceHeight * 0.008 : deviceHeight * 0.006,
    width: isActive ? deviceHeight * 0.008 : deviceHeight * 0.006,
    decoration: BoxDecoration(
      borderRadius: BorderRadiusDirectional.all(
        Radius.circular(999), // --ae-r-pill
      ),
      color: isActive
          ? ScSaasThemeTokens.primaryHover // Purple 700
          : ScSaasThemeTokens.primaryDisabled, // Purple 400
    ),
  );
}

/// Ærend badge/pill — brand-tinted by default with semantic variants.
enum AeBadgeVariant { info, success, warning, error, primary, dark }

Widget aeBadge(
  String label, {
  AeBadgeVariant variant = AeBadgeVariant.info,
  double fontSize = 11,
}) {
  Color bg;
  Color fg;
  switch (variant) {
    case AeBadgeVariant.info:
      bg = ScSaasThemeTokens.primaryTint; // Purple 100
      fg = ScSaasThemeTokens.primaryHover; // Purple 700
    case AeBadgeVariant.success:
      bg = const Color(0x1F22A769); // success @ 12%
      fg = ScSaasThemeTokens.success;
    case AeBadgeVariant.warning:
      bg = const Color(0x1FC98A1A); // warning @ 12%
      fg = ScSaasThemeTokens.warning;
    case AeBadgeVariant.error:
      bg = const Color(0x1ADC4040); // error @ 10%
      fg = ScSaasThemeTokens.danger;
    case AeBadgeVariant.primary:
      bg = ScSaasThemeTokens.primary;
      fg = Colors.white;
    case AeBadgeVariant.dark:
      bg = ScSaasThemeTokens.midnightButton;
      fg = Colors.white;
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(999), // pill
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.02 * fontSize,
        color: fg,
      ),
    ),
  );
}

openRequiredInfoDialog(BuildContext context, Function onPositivePress) {
  if (isEmailOrNumNull()) {
    String mess = "";
    if (prefGetString(prefEmail).trim().isEmpty) {
      mess = "- ${languages.emailAddress}\n";
    }
    if (prefGetString(prefContactNumber).trim().isEmpty) {
      mess = "$mess- ${languages.mobileNumber}";
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialogUtil(
          title: languages.requiredMess,
          message: mess,
          positiveButtonTxt: languages.ok,
          negativeButtonTxt: languages.cancel,
          onNegativePress: () {
            Navigator.pop(context, true);
          },
          onPositivePress: () {
            Navigator.pop(context, true);
            openScreenWithResult(context, const EditProfile()).then((value) {
              if (value != null && value) {
                onPositivePress();
              }
            });
          },
        );
      },
    );
  } else {
    onPositivePress();
  }
}

Widget appVersionName({Color? textColor}) {
  return FutureBuilder(
    future: PackageInfo.fromPlatform(),
    builder: (BuildContext context, AsyncSnapshot<PackageInfo> snapshot) {
      return Text(
        (snapshot.data != null && snapshot.data?.version != null)
            ? "V${snapshot.data?.version}"
            : "",
        textAlign: TextAlign.center,
        maxLines: 1,
        style: bodyText(
          textColor: textColor ?? colorWhite,
          fontSize: textSizeSmall,
          fontWeight: FontWeight.w600,
        ),
      );
    },
  );
}

Widget ExploreAerend(BuildContext context) {
  return Container(
    decoration: const BoxDecoration(
      color: ScSaasThemeTokens.dangerSoft,
      borderRadius: BorderRadius.all(Radius.circular(10)),
      boxShadow: [
        BoxShadow(
          color: ScSaasThemeTokens.dangerSoft,
          spreadRadius: 2,
          blurRadius: 3,
          offset: Offset(0, 3), // changes position of shadow
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 15, left: 15, bottom: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Explore Reen Dugnad offer that suits you right now!',
                  style: TextStyle(
                    color: Color(0xFF7F5FC4),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: colorWhite,
                    backgroundColor: colorPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => openScreenWithResult(
                    context,
                    const HomeMainV1(homeIndex: 0),
                  ),
                  child: const Text('Explore Now'),
                ),
              ],
            ),
          ),
        ),
        const LoadImageSimple(
          image: 'assets/images/explore.png',
          width: 150,
          imageFit: BoxFit.fitHeight,
        ),
        const SizedBox(width: 15),
      ],
    ),
  );
}
