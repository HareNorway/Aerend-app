import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../commonView/common_view.dart';
import '../../../constant/constant.dart';
import 'item_store_list_shimmer.dart';

class DsHomeShimmer extends StatelessWidget {
  final bool enabled;

  const DsHomeShimmer({super.key, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Shimmer.fromColors(
        baseColor: colorShimmerBg,
        highlightColor: Colors.grey.shade100,
        enabled: enabled,
        period: const Duration(milliseconds: 1500),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: 8,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (_, __) => const ItemStoreListShimmer(),
        ),
      ),
    );
  }
}

class DsHomeSliderShimmer extends StatelessWidget {
  final bool enabled;

  const DsHomeSliderShimmer({super.key, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: colorShimmerBg,
      enabled: enabled,
      highlightColor: Colors.grey[100]!,
      period: const Duration(milliseconds: 1500),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          CarouselSlider.builder(
            itemCount: 5,
            itemBuilder:
                (BuildContext context, int itemIndex, int pageViewIndex) =>
                    Card(
              semanticContainer: true,
              elevation: 0,
              clipBehavior: Clip.antiAliasWithSaveLayer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(deviceAverageSize * 0.02),
              ),
              margin: EdgeInsetsDirectional.only(
                  start: deviceWidth * 0.02, end: deviceWidth * 0.02),
              child: AspectRatio(
                aspectRatio: 2.1,
                child: Container(color: Colors.black),
              ),
            ),
            options: CarouselOptions(
              aspectRatio: 2.1,
              viewportFraction: 0.9,
              initialPage: 0,
              disableCenter: true,
              enableInfiniteScroll: true,
              reverse: false,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 3),
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              autoPlayCurve: Curves.fastOutSlowIn,
              enlargeCenterPage: false,
              onPageChanged: (index, reason) {},
              scrollDirection: Axis.horizontal,
            ),
          ),
          SizedBox(height: deviceHeight * 0.012),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [1, 2, 3, 4, 5]
                .asMap()
                .map((i, element) {
                  return MapEntry(i, indicator(true));
                })
                .values
                .toList(),
          ),
        ],
      ),
    );
  }
}

class DsCategoryShimmer extends StatelessWidget {
  final bool enabled;

  const DsCategoryShimmer({super.key, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: colorShimmerBg,
      enabled: enabled,
      highlightColor: Colors.grey[100]!,
      period: const Duration(milliseconds: 1500),
      child: SizedBox(
        height: deviceAverageSize * 0.22,
        child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: deviceWidth * 0.015),
            itemBuilder: (context, index) {
              var imgSize = deviceAverageSize * 0.13;
              return Container(
                margin: EdgeInsets.symmetric(horizontal: deviceWidth * 0.015),
                constraints: BoxConstraints(maxWidth: imgSize),
                child: Column(
                  children: [
                    Container(
                      width: imgSize,
                      height: imgSize,
                      padding: EdgeInsets.zero,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(
                            Radius.circular(deviceAverageSize * 0.02)),
                        color: Colors.black,
                      ),
                      clipBehavior: Clip.antiAlias,
                    ),
                    Flexible(
                      child: Container(
                        margin: EdgeInsetsDirectional.only(
                            top: deviceHeight * 0.005),
                        width: deviceWidth * 0.25,
                        height: deviceHeight * 0.022,
                        color: Colors.black,
                      ),
                    )
                  ],
                ),
              );
            },
            itemCount: 10),
      ),
    );
  }
}
