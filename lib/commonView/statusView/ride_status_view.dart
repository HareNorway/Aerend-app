import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../utils/utils.dart';

class RideStatusView extends StatelessWidget {
  final int rideStatus;
  final bool isLeft, isRentalRide;
  final EdgeInsetsDirectional padding;

  const RideStatusView({super.key, this.isLeft = false, required this.rideStatus, required this.padding, this.isRentalRide = false});

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

    //rental ride status
    //0=pending,
    //1=approved,
    //2=cancelled,
    //3=vehicle taken,
    //4=running,
    //5=drop,
    //6=vehicle received,
    //7=payment,
    //8=rating,
    //9=completed,
    //10=failed
    switch (rideStatus) {
      case 0:
        setYellowLayout(languages.pending);
        break;
      case 1:
      case 2:
        setYellowLayout(languages.accepted);
        break;
      case 3:
        setYellowLayout(languages.running);
        break;
      case 4:
        setRedLayout(languages.cancelled);
        break;
      case 5:
      case 6:
      case 7:
      case 8:
        setYellowLayout(languages.running);
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
      margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.01, start: deviceWidth * 0.01),
      decoration: getStatusBorder(color!, isLeft: isLeft),
      child: Row(
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
