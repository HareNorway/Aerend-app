import 'dart:math';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../utils/utils.dart';
import 'account_dl.dart';

class ItemAccount extends StatelessWidget {
  final AccountItem accountItem;

  const ItemAccount({super.key, required this.accountItem});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: deviceWidth,
      color: Theme.of(context).colorScheme.surface,
      padding:
          EdgeInsetsDirectional.only(top: deviceHeight * 0.025, bottom: deviceHeight * 0.025, start: deviceWidth * 0.01, end: deviceWidth * 0.01),
      child: Row(
        children: [
          Expanded(
            flex: 0,
            child: SizedBox(
              width: deviceWidth * 0.2,
              child: Icon(
                accountItem.icon,
                size: deviceAverageSize * (accountItem.size ?? 0.035),
                color: colorPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              accountItem.name,
              textAlign: TextAlign.start,
              style: bodyText(fontSize: textSizeRegular, fontWeight: FontWeight.bold, textColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : colorTextCommon),
            ),
          ),
          Expanded(
            flex: 0,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(isRtl() ? pi : 0),
              child: FaIcon(
                FontAwesomeIcons.chevronRight,
                size: deviceAverageSize * 0.021,
                color: colorMainLightGray,
              ),
            ),
          ),
          SizedBox(
            width: deviceWidth * 0.03,
          ),
        ],
      ),
    );
  }
}
