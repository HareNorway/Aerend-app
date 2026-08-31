import 'package:flutter/material.dart';

import '../theme/sc_saas_theme.dart';
import '../utils/utils.dart';

BoxDecoration getBoxDecoration({Color? color, double radius = 0.0, BoxBorder? border}) {
  return BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(radius)), color: color ?? ScSaasThemeTokens.card, border: border);
}

InputDecoration getInputDecoration({String? hint, Color? color, String? prefix, String? error, double? radius, bool leftError = false}) {
  Tooltip? tooltip;
  if (leftError && (error ?? "").isNotEmpty) {
    GlobalKey tooltipKey = GlobalKey();
    tooltip = Tooltip(
      key: tooltipKey,
      message: error,
      child: IconButton(
        icon: const Icon(
          Icons.error,
            color: ScSaasThemeTokens.danger,
        ),
        onPressed: () async {
          final dynamic tooltip = tooltipKey.currentState;
          tooltip.ensureTooltipVisible();
          await Future.delayed(const Duration(seconds: 3));
          tooltip.deactivate();
        },
      ),
    );
  }

  Color cc = color ?? Colors.white;
  double bRadius = radius ?? deviceAverageSize * 0.01;
  return InputDecoration(
    prefix: prefix != null ? Container(margin: EdgeInsets.symmetric(horizontal: deviceWidth * 0.006), child: Text(prefix)) : null,
    fillColor: cc,
    filled: true,
    errorMaxLines: 2,
    errorStyle: const TextStyle(height: 0, fontSize: 0.0),
    errorText: error,
    suffix: tooltip,
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: cc, width: 0.0, style: BorderStyle.none),
      borderRadius: BorderRadius.circular(bRadius),
    ),
    enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: cc),
      borderRadius: BorderRadius.circular(bRadius),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: deviceWidth * 0.025),
    border: InputBorder.none,
    hintStyle: bodyText(textColor: ScSaasThemeTokens.muted, fontSize: textSizeSmall),
    hintText: hint ?? "",
    hintTextDirection: TextDirection.ltr,
  );
}

InputDecoration getInputDecorationCommon({String? hint, String? labelText}) {
  return InputDecoration(
    labelText: labelText,
    hintText: hint,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(deviceAverageSize * 0.01)),
      borderSide: BorderSide(color: colorMainView, width: deviceHeight * 0.001),
    ),
    contentPadding: EdgeInsetsDirectional.only(
      top: deviceHeight * 0.020,
      bottom: deviceHeight * 0.020,
      end: deviceWidth * 0.02,
      start: deviceWidth * 0.04,
    ),
    labelStyle: bodyText(
      textColor: colorMainLightGray,
      fontSize: textSizeMediumBig,
    ).copyWith(
      height: deviceHeight * 0.0008,
    ),
    hintStyle: bodyText(
      textColor: colorMainLightGray,
      fontSize: textSizeMediumBig,
    ).copyWith(
      height: deviceHeight * 0.0008,
    ),
  );
}
