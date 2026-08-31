import 'package:flutter/material.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:aerend_customer/constant/colors.dart';

class SwipeButton extends StatelessWidget {
  final Function onTap;
  final Widget child;

  const SwipeButton({
    required this.onTap,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(),
      child: child,
    );
  }
}

//swipe card to the right side
Widget swipeRightButton(BuildContext context,
    AppinioSwiperController controller, AppinioSwiperDirection direction) {
  final bool isDark = Theme.of(context).brightness == Brightness.dark;
  final Color idleBg = Theme.of(context).colorScheme.surface;
  final Color idleIcon = isDark ? Colors.white : colorBlack;
  final Color dimBg =
      isDark ? const Color(0xFF2A2A2A) : colorWhiteGray;

  Color bgColor = idleBg;
  Color iconColor = idleIcon;
  switch (direction) {
    case AppinioSwiperDirection.right:
      bgColor = colorGreen;
      iconColor = colorWhite;
      break;
    case AppinioSwiperDirection.left:
      bgColor = dimBg;
      iconColor = colorMainLightGray;
      break;
    case AppinioSwiperDirection.none:
      bgColor = idleBg;
      iconColor = idleIcon;
      break;
    default:
  }
  return SwipeButton(
    onTap: () => controller.swipeRight(),
    child: Container(
      height: 60,
      width: 60,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.15),
            spreadRadius: 5,
            blurRadius: 15,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: SvgPicture.asset('assets/svgs/icons/bucket.svg',
          width: 26, color: iconColor),
    ),
  );
}

//swipe card to the left side
Widget swipeLeftButton(BuildContext context,
    AppinioSwiperController controller, AppinioSwiperDirection direction) {
  final bool isDark = Theme.of(context).brightness == Brightness.dark;
  final Color idleBg = Theme.of(context).colorScheme.surface;
  final Color idleIcon = isDark ? Colors.white : colorBlack;
  final Color dimBg =
      isDark ? const Color(0xFF2A2A2A) : colorWhiteGray;

  Color bgColor = idleBg;
  Color iconColor = idleIcon;
  switch (direction) {
    case AppinioSwiperDirection.left:
      bgColor = colorRed;
      iconColor = colorWhite;
      break;
    case AppinioSwiperDirection.right:
      bgColor = dimBg;
      iconColor = colorMainLightGray;
      break;
    case AppinioSwiperDirection.none:
      bgColor = idleBg;
      iconColor = idleIcon;
      break;
    default:
  }
  return SwipeButton(
    onTap: () => controller.swipeLeft(),
    child: Container(
      height: 60,
      width: 60,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.15),
            spreadRadius: 5,
            blurRadius: 15,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: SvgPicture.asset('assets/svgs/icons/close.svg',
          width: 26, color: iconColor),
    ),
  );
}
