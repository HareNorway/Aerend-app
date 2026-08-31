import 'package:flutter/material.dart';

import '../../../utils/utils.dart';
import 'ride_book_dl.dart';

class ItemVehicleType extends StatelessWidget {
  final ServiceTypeItem? serviceTypeItem;
  final Function? onClick;

  const ItemVehicleType({super.key, @required this.serviceTypeItem, @required this.onClick});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        serviceTypeItem!.serviceStatus == 0 ? openSimpleSnackbar(languages.vehicleNotAvailable) : onClick!();
      },
      child: Opacity(
        opacity: serviceTypeItem!.serviceStatus == 0 ? 0.4 : 1,
        child: Container(
          margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.02, end: deviceWidth * 0.02),
          child: IntrinsicWidth(
            child: Column(
              children: [
                Container(
                  padding: EdgeInsetsDirectional.only(start: deviceWidth * 0.02, end: deviceWidth * 0.02),
                  child: LoadImageWithPlaceHolder(
                    width: deviceAverageSize * 0.08,
                    height: deviceAverageSize * 0.08,
                    image: serviceTypeItem?.image ?? "",
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                Text(
                  serviceTypeItem?.serviceName ?? "-",
                  textAlign: TextAlign.start,
                  style: bodyText(textColor: colorGray700, fontWeight: FontWeight.normal, fontSize: textSizeSmall),
                ),
                Container(
                  margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.01),
                  child: Divider(
                    color: serviceTypeItem!.isSelected ? colorPrimary : colorWhite,
                    height: 0,
                    thickness: deviceWidth * 0.006,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
