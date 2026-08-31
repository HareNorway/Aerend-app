import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../utils/utils.dart';

class DsSubCategoryShimmer extends StatefulWidget {
  const DsSubCategoryShimmer({super.key});

  @override
  State createState() => _DsSubCategoryShimmeryState();
}

class _DsSubCategoryShimmeryState extends State<DsSubCategoryShimmer> {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: colorShimmerBg,
      highlightColor: Colors.grey[100]!,
      period: const Duration(milliseconds: 1500),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: deviceHeight * 0.05,
                  margin: EdgeInsets.all(deviceAverageSize * 0.006),
                  color: Colors.black,
                ),
              ),
              Expanded(
                child: Container(
                  height: deviceHeight * 0.05,
                  margin: EdgeInsets.all(deviceAverageSize * 0.006),
                  color: Colors.black,
                ),
              ),
              Expanded(
                child: Container(
                  height: deviceHeight * 0.05,
                  margin: EdgeInsets.all(deviceAverageSize * 0.006),
                  color: Colors.black,
                ),
              ),
              Expanded(
                child: Container(
                  height: deviceHeight * 0.05,
                  margin: EdgeInsets.all(deviceAverageSize * 0.006),
                  color: Colors.black,
                ),
              ),
            ],
          ),
          Container(
            height: deviceHeight * 0.05,
            decoration: getBoxDecoration(
                radius: deviceAverageSize * 0.015,
                color: Colors.black,
                border: Border.all(
                  width: deviceAverageSize * 0.003,
                  color: colorMainTabDividerColor,
                )),
            padding: EdgeInsetsDirectional.only(start: deviceWidth * 0.015, end: deviceWidth * 0.01),
            margin: EdgeInsets.symmetric(horizontal: deviceWidth * 0.03, vertical: deviceHeight * 0.012),
            child: Row(children: [
              Icon(
                Icons.search_sharp,
                color: colorMainLightGray,
                size: deviceAverageSize * 0.035,
              ),
            ]),
          ),
          Expanded(
            child: ListView.separated(
              itemBuilder: (context, index) {
                return Container(
                  color: Colors.black,
                  height: deviceHeight * 0.1,
                );
                // return SubCatItemProduct(productListItem: item, storeDetailsPojo: widget.storeDetailsPojo);
              },
              padding: EdgeInsetsDirectional.only(start: deviceWidth * 0.03, end: deviceWidth * 0.03, bottom: deviceWidth * 0.03),
              separatorBuilder: (BuildContext context, int index) {
                return const Divider(
                  color: colorDivider,
                );
              },
              itemCount: 10,
            ),
          ),
        ],
      ),
    );
  }
}
