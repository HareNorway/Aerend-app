import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../utils/utils.dart';

class DeliveriesStatusView extends StatelessWidget {
  final int? orderStatus;
  final bool? isLeft;
  final EdgeInsetsDirectional? padding;

  const DeliveriesStatusView({super.key, this.isLeft, required this.orderStatus, required this.padding});

  @override
  Widget build(BuildContext context) {
    Color? color;
    String? status;
    Widget? icon;

    setYellowLayout(String text) {
      color = colorYellow;
      status = text;
      icon = Container(
        width: deviceAverageSize * 0.03,
        height: deviceAverageSize * 0.03,
        alignment: Alignment.center,
        child: FaIcon(
          FontAwesomeIcons.hourglassHalf,
          size: deviceAverageSize * 0.025,
          color: colorWhite,
        ),
      );
    }

    setRedLayout(String text) {
      color = colorRed;
      status = text;
      icon = Container(
        width: deviceAverageSize * 0.03,
        height: deviceAverageSize * 0.03,
        alignment: Alignment.center,
        child: FaIcon(
          FontAwesomeIcons.circleXmark,
          size: deviceAverageSize * 0.025,
          color: colorWhite,
        ),
      );
    }

    setGreenLayout(String text) {
      color = colorGreen;
      status = text;
      icon = Container(
        width: deviceAverageSize * 0.03,
        height: deviceAverageSize * 0.03,
        alignment: Alignment.center,
        child: Icon(
          CupertinoIcons.checkmark_seal_fill,
          size: deviceAverageSize * 0.025,
          color: colorWhite,
        ),
      );
    }

    switch (orderStatus) {
      case 1:
        setYellowLayout(languages.pending);
        break;
      case 2:
        setYellowLayout(languages.accepted);
        break;
      case 3:
        setRedLayout(languages.rejected);
        break;
      case 4:
        setRedLayout(languages.cancelled);
        break;
      case 5:
        setYellowLayout(languages.processing);
        break;
      case 6:
        setYellowLayout(languages.processing);
        break;
      case 7:
      case 8:
        setYellowLayout(languages.onGoing);
        break;
      case 9:
        setGreenLayout(languages.completed);
        break;
      case 10:
        setRedLayout(languages.cancelled);
        break;
      default:
        setYellowLayout(languages.pending);
        break;
    }

    return Container(
      padding: padding,
      decoration: getStatusBorder(color!, isLeft: isLeft!),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon!,
          Container(
            margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.015),
            child: Text(
              status!,
              textAlign: TextAlign.start,
              style: bodyText(fontSize: textSizeSmall, textColor: colorWhite, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
