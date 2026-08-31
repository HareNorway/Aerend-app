import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../utils/utils.dart';
import '../storeDetail/item_store_product_shimmer.dart';

class ProductListShimmer extends StatelessWidget {
  final bool enabled;
  final bool isGrid;

  const ProductListShimmer({super.key, required this.enabled, this.isGrid = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Shimmer.fromColors(
        baseColor: colorShimmerBg,
        highlightColor: Colors.grey.shade100,
        enabled: enabled,
        period: const Duration(milliseconds: 1500),
        child: isGrid
            ? const GridTypePage()
            : ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsetsDirectional.only(start: deviceWidth * 0.025, end: deviceWidth * 0.035, top: deviceHeight * 0.015),
                itemCount: 8,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (_, __) => Padding(
                  padding: EdgeInsetsDirectional.only(bottom: deviceHeight * 0.02),
                  child: const ItemStoreProductShimmer(),
                ),
              ),
      ),
    );
  }
}

class GridTypePage extends StatelessWidget {
  const GridTypePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemBuilder: (context, index) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(deviceAverageSize * 0.012)),
                  color: colorWhite,
                ),
              ),
            ),
            SizedBox(height: deviceHeight * 0.005),
            Text(
              languages.productName,
              textAlign: TextAlign.start,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: bodyText(fontWeight: FontWeight.w600),
            ),
            Text(
              getAmountWithCurrency(0),
              textAlign: TextAlign.start,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: bodyText(fontSize: textSizeSmall),
            ),
            Container(
              width: deviceWidth * 0.25,
              height: deviceHeight * 0.03,
              margin: EdgeInsets.only(top: deviceWidth * 0.025),
              decoration: BoxDecoration(
                color: colorWhite,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.grey,
                    offset: Offset(1.0, 1.0), //(x,y)
                    blurRadius: 3.0,
                  ),
                ],
                borderRadius: BorderRadius.all(Radius.circular(deviceAverageSize * 0.01)),
              ),
              constraints: BoxConstraints(minWidth: deviceWidth * 0.225),
            ),
          ],
        );
      },
      itemCount: 6,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.91,
        crossAxisSpacing: deviceWidth * 0.03,
        mainAxisSpacing: deviceHeight * 0.015,
      ),
      padding: EdgeInsetsDirectional.only(start: deviceWidth * 0.03, end: deviceWidth * 0.03, bottom: deviceWidth * 0.03),
    );
  }
}
