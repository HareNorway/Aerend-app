import 'package:flutter/material.dart';

import '../../../utils/utils.dart';

class ItemCourierDetail extends StatelessWidget {
  final Widget? icon;
  final String? label, mainText;

  const ItemCourierDetail({super.key, this.icon, this.label, this.mainText});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        icon != null
            ? Container(
                margin: EdgeInsetsDirectional.only(end: deviceWidth * 0.025),
                child: icon,
              )
            : Container(),
        Flexible(
          flex: 1,
          child: Container(
            margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.002),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (label != null && label!.isNotEmpty)
                  Text(
                    label!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bodyText(fontWeight: FontWeight.w600, fontSize: textSizeSmall, textColor: colorMainGray),
                  ),
                if (mainText != null && mainText!.isNotEmpty)
                  Text(
                    mainText!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: bodyText(fontWeight: FontWeight.w600, fontSize: textSizeMediumBig, textColor: colorTextCommon),
                  ),
              ],
            ),
          ),
        )
      ],
    );
  }
}
