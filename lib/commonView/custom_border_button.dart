import 'package:flutter/material.dart';

import '../constant/constant.dart';
import '../theme/sc_saas_theme.dart';

/// Button variant used for design-system styling.
enum AeBorderButtonVariant { outlined, ghost, dark }

class CustomBorderButton extends StatelessWidget {
  final Widget child;
  final Function onPressed;
  final double width, height;
  final BorderRadiusDirectional borderRadius;
  final BorderSide borderSide;
  final EdgeInsetsDirectional margin;
  final Color highlightedBorderColor;
  final MaterialTapTargetSize tapTargetSize;
  final EdgeInsetsDirectional? padding;
  final AeBorderButtonVariant variant;

  const CustomBorderButton({
    super.key,
    required this.onPressed,
    required this.child,
    required this.width,
    required this.height,
    required this.margin,
    required this.borderRadius,
    required this.highlightedBorderColor,
    required this.borderSide,
    this.tapTargetSize = MaterialTapTargetSize.padded,
    this.padding,
    this.variant = AeBorderButtonVariant.outlined,
  });

  @override
  Widget build(BuildContext context) {
    final defaultRadius = BorderRadiusDirectional.all(
      Radius.circular(14), // --ae-r-md
    );
    final resolvedRadius = borderRadius;

    switch (variant) {
      case AeBorderButtonVariant.ghost:
        return Container(
          margin: margin,
          child: TextButton(
            style: TextButton.styleFrom(
              tapTargetSize: tapTargetSize,
              minimumSize: Size(width, height),
              padding: padding ??
                  EdgeInsetsDirectional.only(
                    start: deviceWidth * 0.01,
                    end: deviceWidth * 0.01,
                  ),
              foregroundColor: ScSaasThemeTokens.primaryHover,
              shape: RoundedRectangleBorder(borderRadius: resolvedRadius),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            onPressed: () => onPressed(),
            child: child,
          ),
        );

      case AeBorderButtonVariant.dark:
        return Container(
          margin: margin,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              tapTargetSize: tapTargetSize,
              minimumSize: Size(width, height),
              padding: padding ??
                  EdgeInsetsDirectional.only(
                    start: deviceWidth * 0.01,
                    end: deviceWidth * 0.01,
                  ),
              backgroundColor: ScSaasThemeTokens.midnightButton,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: resolvedRadius),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: -0.01 * 15,
              ),
            ),
            onPressed: () => onPressed(),
            child: child,
          ),
        );

      case AeBorderButtonVariant.outlined:
        return Container(
          margin: margin,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              tapTargetSize: tapTargetSize,
              minimumSize: Size(width, height),
              padding: padding ??
                  EdgeInsetsDirectional.only(
                    start: deviceWidth * 0.01,
                    end: deviceWidth * 0.01,
                  ),
              foregroundColor: highlightedBorderColor,
              shape: RoundedRectangleBorder(borderRadius: resolvedRadius),
              side: borderSide,
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: -0.01 * 15,
              ),
            ),
            child: child,
            onPressed: () => onPressed(),
          ),
        );
    }
  }
}
