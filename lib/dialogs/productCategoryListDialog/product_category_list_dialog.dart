import 'package:flutter/material.dart';

import '../../commonView/modal_ui.dart';
import '../../screens/deliveryService/storeDetail/store_detail_dl.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/utils.dart';
import 'item_product_category_list_dialog.dart';

class ProductCategoryListDialog extends StatelessWidget {
  final List<CategoryWiseProductListItem> categoryWiseProductList;
  final void Function(int selected) onSelected;

  const ProductCategoryListDialog({super.key, required this.categoryWiseProductList, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: dialogPending,
      shape: RoundedRectangleBorder(borderRadius: dialogBorderRadius),
      backgroundColor: ScSaasThemeTokens.card,
      child: SizedBox(
        width: double.infinity,
        height: deviceHeight * 0.5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              padding: EdgeInsetsDirectional.only(
                top: deviceHeight * 0.015,
                start: deviceWidth * 0.038,
                end: deviceWidth * 0.01,
                bottom: deviceHeight * 0.01,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ModalUi.handle(),
                  const SizedBox(height: 12),
                  Text(
                    prefGetInt(prefSelectedServiceCateId) == 5 ? languages.cuisine : languages.productCategory,
                    textAlign: TextAlign.center,
                    style: bodyText(fontSize: textSizeBig, fontWeight: FontWeight.w600, textColor: ScSaasThemeTokens.text),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                shrinkWrap: true,
                separatorBuilder: (context, index) => Container(
                  margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.02, end: deviceWidth * 0.02),
                  child: Divider(
                    color: ScSaasThemeTokens.border,
                    thickness: deviceHeight * 0.002,
                    height: 0,
                  ),
                ),
                padding: EdgeInsetsDirectional.only(top: 0, bottom: deviceHeight * 0.02),
                itemCount: categoryWiseProductList.length,
                itemBuilder: (BuildContext context, position) {
                  return categoryWiseProductList.isNotEmpty
                      ? ItemProductCategoryListDialog(
                          onCuisineClick: () {
                            onSelected(position);
                            Navigator.pop(context, true);
                          },
                          categoryWiseProductListItem: categoryWiseProductList[position],
                        )
                      : Container();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
