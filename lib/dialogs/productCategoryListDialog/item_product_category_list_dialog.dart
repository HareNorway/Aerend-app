import 'package:flutter/material.dart';

import '../../screens/deliveryService/storeDetail/store_detail_dl.dart';
import '../../utils/utils.dart';

class ItemProductCategoryListDialog extends StatelessWidget {
  final Function onCuisineClick;
  final bool selected;
  final CategoryWiseProductListItem categoryWiseProductListItem;

  const ItemProductCategoryListDialog(
      {super.key,
      required this.onCuisineClick,
      this.selected = false,
      required this.categoryWiseProductListItem});

  @override
  Widget build(BuildContext context) {
    var style = bodyText(
            textColor: selected ? colorPrimary : colorMainLightGray,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal)
        .copyWith(
      decoration: TextDecoration.none,
    );
    return GestureDetector(
      onTap: () {
        onCuisineClick.call();
      },
      child: Container(
        margin: EdgeInsetsDirectional.only(
            top: deviceHeight * 0.01, bottom: deviceHeight * 0.01),
        padding: EdgeInsetsDirectional.only(
            start: deviceWidth * 0.03,
            end: deviceWidth * 0.03,
            top: deviceHeight * 0.005,
            bottom: deviceHeight * 0.005),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              flex: 1,
              child: Container(
                constraints: BoxConstraints(minWidth: deviceWidth * 0.6),
                child: Text(
                  categoryWiseProductListItem.categoryName,
                  textAlign: TextAlign.start,
                  style: style,
                ),
              ),
            ),
            Text(
              categoryWiseProductListItem.subCategoryList.length.toString(),
              textAlign: TextAlign.end,
              style: style,
            ),
          ],
        ),
      ),
    );
  }
}
