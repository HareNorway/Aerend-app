import 'package:flutter/material.dart';

import '../../../utils/utils.dart';
import 'manage_card_dl.dart';

class ItemManageCard extends StatelessWidget {
  final CardListItem cardListItem;
  final Function() onClickRemove;

  const ItemManageCard({super.key, required this.cardListItem, required this.onClickRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsetsDirectional.only(
        start: deviceWidth * 0.01,
        end: deviceWidth * 0.025,
        top: deviceHeight * 0.002,
        bottom: deviceHeight * 0.002,
      ),
      width: double.infinity,
      color: colorWhite,
      child: Row(
        children: [
          Expanded(
            flex: 0,
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                top: deviceHeight * 0.02,
                bottom: deviceHeight * 0.02,
                start: deviceWidth * 0.03,
                end: deviceWidth * 0.03,
              ),
              child: Icon(CustomIcons.selectCardAddCard, size: deviceAverageSize * 0.09, color: colorPrimary),
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cardListItem.cardHolderName,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.start,
                  style: bodyText(fontWeight: FontWeight.w600),
                ),
                Container(
                  margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.006),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          cardListItem.cardNumber,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                          style: bodyText(fontSize: textSizeSmall, textColor: colorMainLightGray),
                        ),
                      ),
                      Expanded(
                        flex: 0,
                        child: GestureDetector(
                          onTap: onClickRemove,
                          child: Padding(
                            padding: EdgeInsetsDirectional.only(
                                start: deviceWidth * 0.005, top: deviceHeight * 0.002, bottom: deviceHeight * 0.002, end: deviceWidth * 0.005),
                            child: Text(
                              languages.remove,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.start,
                              style: bodyText(fontSize: textSizeSmall, textColor: colorRed, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
