import 'package:flutter/material.dart';

import '../screens/common/base_dl.dart';
import '../utils/utils.dart';

class ItemKeyValue extends StatelessWidget {
  final KeyValueModel? keyValueModel;

  const ItemKeyValue({super.key, required this.keyValueModel});

  @override
  Widget build(BuildContext context) => Container(
        margin: EdgeInsetsDirectional.only(
            bottom: deviceHeight * 0.005, top: deviceHeight * 0.003),
        child: Column(
          children: [
            keyValueModel!.setDivider
                ? Divider(
                    color: colorMainBackground,
                    height: deviceHeight * 0.01,
                    thickness: deviceAverageSize * 0.003,
                  )
                : Container(),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    keyValueModel!.key,
                    textAlign: TextAlign.start,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bodyText(
                        fontSize: keyValueModel!.setBold? textSizeBig
                            : textSizeRegular,
                        textColor: /*keyValueModel.setBold ? colorBlack : */ colorBlack,
                        fontWeight: keyValueModel!.setBold? FontWeight.w600
                            : FontWeight.normal),
                  ),
                ),
                Expanded(
                  flex: 0,
                  child: GestureDetector(
                    onTap: keyValueModel!.setButton,
                    child: Container(
                      padding: keyValueModel!.setButton != null
                          ? EdgeInsets.symmetric(
                              vertical: deviceHeight * 0.005,
                              horizontal: deviceWidth * 0.02)
                          : null,
                      decoration: keyValueModel!.setButton != null
                          ? getBoxDecoration(
                              color: colorPrimary,
                              radius: deviceAverageSize * 0.008)
                          : null,
                      child: Text(
                        keyValueModel!.value,
                        textAlign: TextAlign.start,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: bodyText(
                            fontSize: keyValueModel!.setBold
                                ? textSizeBig
                                : textSizeRegular,
                            textColor: keyValueModel!.setButton != null
                                ? colorWhite
                                : /*keyValueModel.setBold
                                    ? colorBlack
                                    : */
                                colorBlack,
                            fontWeight: keyValueModel!.setBold
                                ? FontWeight.w600
                                : FontWeight.normal),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}
