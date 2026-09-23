import 'package:flutter/material.dart';

import '../constant/constant.dart';
import '../theme/sc_saas_theme.dart';

class CustomFillButton extends StatelessWidget {
  final Widget? child;
  final Function? onPressed;
  final Color? color;
  final double? width, height, elevation;
  final BorderRadiusDirectional? borderRadius;
  final EdgeInsetsDirectional? margin, padding;
  final MaterialTapTargetSize? tapTargetSize;

  const CustomFillButton({
    super.key,
    required this.onPressed,
    required this.child,
    required this.width,
    required this.height,
    required this.margin,
    required this.padding,
    required this.color,
    this.elevation,
    this.borderRadius,
    this.tapTargetSize = MaterialTapTargetSize.padded,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null;
    final Color fillColor = isDisabled
        ? ScSaasThemeTokens.primaryDisabled
        : (color ?? ScSaasThemeTokens.primary);

    // Brand-tinted purple glow shadow for primary buttons.
    final List<BoxShadow> glowShadow =
        (!isDisabled && (color == null || color == ScSaasThemeTokens.primary))
            ? ScSaasThemeTokens.shadowButton
            : const [];

    final defaultRadius = BorderRadiusDirectional.all(
      Radius.circular(14), // --ae-r-md
    );

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? defaultRadius,
        boxShadow: glowShadow,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: padding,
          backgroundColor: fillColor,
          disabledBackgroundColor: ScSaasThemeTokens.primaryDisabled,
          foregroundColor: Colors.white,
          tapTargetSize: tapTargetSize,
          elevation: elevation ?? 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? defaultRadius,
          ),
          minimumSize: Size(width!, height!),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: -0.01 * 15,
          ),
        ),
        onPressed: onPressed != null
            ? () {
                FocusManager.instance.primaryFocus?.unfocus();
                onPressed!.call();
              }
            : null,
        child: child,
      ),
    );
  }
}
