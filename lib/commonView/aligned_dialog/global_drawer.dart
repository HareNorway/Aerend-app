import 'package:flutter/material.dart';

import 'aligned_dialog.dart';

///show a dialog/drawer that is aligned to one of the edges of the screen, specified by the direction.

Future showGlobalDrawer<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color barrierColor = Colors.black54,
  String? barrierLabel,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  AxisDirection direction = AxisDirection.left,
  Duration? duration,
}) {
  Alignment followerAnchor;
  Offset beginOffset;
  switch (direction) {
    case AxisDirection.left:
      followerAnchor = Alignment.topLeft;
      beginOffset = const Offset(-1, 0);
      break;
    case AxisDirection.right:
      followerAnchor = Alignment.topRight;
      beginOffset = const Offset(1, 0);
      break;
    case AxisDirection.up:
      followerAnchor = Alignment.topLeft;
      beginOffset = const Offset(0, -1);
      break;
    case AxisDirection.down:
      followerAnchor = Alignment.bottomLeft;
      beginOffset = const Offset(0, 1);
      break;
  }
  return showAlignedDialog(
    context: context,
    builder: builder,
    followerAnchor: followerAnchor,
    isGlobal: true,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    barrierLabel: barrierLabel,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    duration: duration,
    transitionsBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
      return SlideTransition(
        position: Tween(begin: beginOffset, end: Offset.zero).animate(animation),
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: child,
        ),
      );
    },
  );
}
