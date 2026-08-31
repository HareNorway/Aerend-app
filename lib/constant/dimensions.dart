import 'package:flutter/material.dart';

import 'constant.dart';

// Fixed px values on the Ærend 375×812 reference frame. The design does NOT
// scale type/radii/control heights with screen size — a 14px label is 14px on
// every device. `commonTextStyle` and `CustomBorderButton` treat values < 1 as
// legacy screen-fractions for any stragglers.

//Common Text Size (Ærend type scale, colors_and_type.css)
double textSizeSmallest = 13;
double textSizeSmaller = 14; // --ae-label-size
double textSizeSmall = 14.5;
double textSizeRegular = 15; // --ae-body-size
double textSizeMediumBig = 16;
double textSizeBig = 17; // --ae-h3-size
double textSizeLarge = 18;
double textSizeLargest = 20;

//Common Button Height (.ae-btn: 56px)
double commonBtnHeightBig = 56;
double commonBtnHeight = 56;
double commonBtnHeightMedium = 44;
double commonBtnHeightSmall = 40;
double commonBtnHeightSmallest = 32;
double commonBtnHeightVerySmall = 8;

// Button widths stay fluid (fractions of screen width).
double commonBtnWidthSmallest = 0.25;
double commonBtnWidthSmall = 0.4;
double commonBtnWidth = 0.5;
double commonBtnWidthBig = 0.55;
double commonBtnWidthLargest = 0.6;

//Common CircularProgressIndicator (fractions — spinners may stay fluid)
double cpiStrokeWidthRegular = 0.004;
double cpiStrokeWidthSmall = 0.003;
double cpiStrokeWidthSmallest = 0.0022;

double cpiSizeSmallest = 0.022;
double cpiSizeSmall = 0.03;
double cpiSizeRegular = 0.035;
double cpiSizeMediumBig = 0.04;

//Common Shape Radius (--ae-r-sm)
Radius topLeftRadius = const Radius.circular(8);
Radius topRightRadius = const Radius.circular(8);
Radius bottomLeftRadius = const Radius.circular(8);
Radius bottomRightRadius = const Radius.circular(8);

//Common BottomSheet Radius (--ae-r-xl / --ae-r-lg)
Radius topLeftRadiusBs = const Radius.circular(24);
Radius topLeftRadiusMediumBs = const Radius.circular(18);
Radius topRightRadiusBs = const Radius.circular(24);
Radius topRightRadiusMediumBs = const Radius.circular(18);

//Common Status Radius (--ae-r-pill)
Radius topLeftRadiusStatus = const Radius.circular(999);
Radius bottomLeftRadiusStatus = const Radius.circular(999);
Radius topRightRadiusStatus = const Radius.circular(999);
Radius bottomRightRadiusStatus = const Radius.circular(999);

//Common Dialog (--ae-r-md)
BorderRadius dialogBorderRadius = BorderRadius.circular(14);
EdgeInsets dialogPending = const EdgeInsets.all(16);

Radius zeroRadius = Radius.zero;

double iconSize = 18;
