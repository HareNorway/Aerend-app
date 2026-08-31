import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../../../utils/utils.dart';

class HomeV1Shimmer extends StatelessWidget {
  final bool enabled;

  const HomeV1Shimmer({super.key, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      enabled: enabled,
      highlightColor: Colors.grey[100]!,
      period: const Duration(milliseconds: 1500),
      child: ListView.builder(
        itemCount: 6,
        shrinkWrap: true,
        padding: EdgeInsetsDirectional.only(top: deviceHeight * 0.02),
        itemBuilder: (context, index) {
          return SizedBox(
            height: deviceHeight * 0.15,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.only(start: deviceWidth * 0.04),
                  child: Container(
                    color: colorWhite,
                    width: deviceWidth * 0.4,
                    height: deviceHeight * 0.02,
                  ),
                ),
                Container(
                  color: colorWhite,
                  margin: EdgeInsetsDirectional.only(end: deviceWidth * 0.03),
                  width: deviceAverageSize * 0.15,
                  height: deviceAverageSize * 0.15,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class HomeBannerShimmer extends StatelessWidget {
  final bool enabled;

  const HomeBannerShimmer({super.key, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: colorShimmerBg,
      enabled: enabled,
      highlightColor: Colors.grey[100]!,
      period: const Duration(milliseconds: 1500),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsetsDirectional.only(top: deviceHeight * 0.01),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        itemBuilder: (BuildContext context, position) {
          return Container(
            margin: EdgeInsetsDirectional.only(bottom: deviceHeight * 0.025),
            child: Card(
              semanticContainer: true,
              clipBehavior: Clip.antiAliasWithSaveLayer,
              color: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(deviceAverageSize * 0.02),
              ),
              margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.045, end: deviceWidth * 0.045),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    width: deviceWidth,
                    height: deviceHeight * 0.2,
                    color: colorBlack,
                  ),
                  Container(
                    padding: EdgeInsetsDirectional.only(
                        start: deviceWidth * 0.035, end: deviceWidth * 0.035, top: deviceHeight * 0.02, bottom: deviceHeight * 0.02),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          width: deviceWidth * 0.4,
                          height: deviceHeight * 0.025,
                          color: Colors.black,
                        ),
                        SizedBox(height: deviceHeight * 0.005),
                        Container(
                          width: deviceWidth,
                          height: deviceHeight * 0.022,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class FeatureStoreShimmer extends StatelessWidget {
  final bool enabled;

  const FeatureStoreShimmer({super.key, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: colorShimmerBg,
      highlightColor: Colors.grey[100]!,
      period: const Duration(milliseconds: 1500),
      enabled: enabled,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.045, end: deviceWidth * 0.045, bottom: deviceHeight * 0.005),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  flex: 1,
                  child: Container(
                    width: deviceWidth * 0.4,
                    height: deviceHeight * 0.025,
                    color: colorBlack,
                  ),
                ),
                Flexible(
                  flex: 0,
                  child: Container(
                    width: deviceWidth * 0.15,
                    height: deviceHeight * 0.022,
                    color: colorBlack,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
              height: deviceHeight * 0.29,
              child: ListView.builder(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsetsDirectional.only(top: deviceHeight * 0.02, start: deviceWidth * 0.045),
                itemCount: 6,
                itemBuilder: (BuildContext context, position) {
                  return Container(
                    width: deviceWidth * 0.44,
                    margin: EdgeInsetsDirectional.only(end: deviceWidth * 0.045),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Stack(
                          alignment: AlignmentDirectional.bottomCenter,
                          clipBehavior: Clip.antiAlias,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.all(Radius.circular(deviceAverageSize * 0.018)),
                              child: Container(
                                width: deviceWidth * 0.44,
                                height: deviceHeight * 0.16,
                                color: Colors.black,
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(deviceAverageSize * 0.018)),
                                gradient: LinearGradient(
                                  end: const Alignment(0.0, -0.5),
                                  begin: const Alignment(0.0, 1),
                                  colors: <Color>[const Color(0x8A000000), Colors.black12.withOpacity(0.0)],
                                ),
                              ),
                              width: deviceWidth * 0.43,
                              height: deviceHeight * 0.16,
                              child: Container(),
                            ),
                            Container(
                              margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.015, bottom: deviceHeight * 0.008),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 0,
                                    child: Icon(CustomIcons.offer, size: deviceAverageSize * 0.025, color: colorRed),
                                  ),
                                  SizedBox(width: deviceWidth * 0.015),
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      width: deviceWidth * 0.5,
                                      height: deviceHeight * 0.02,
                                      color: colorBlack,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: deviceHeight * 0.005),
                        Container(
                          width: deviceWidth * 0.3,
                          height: deviceHeight * 0.025,
                          color: colorBlack,
                        ),
                        SizedBox(height: deviceHeight * 0.005),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            FaIcon(FontAwesomeIcons.solidStar, size: deviceAverageSize * 0.02, color: colorRatingStar),
                            SizedBox(width: deviceWidth * 0.01),
                            Flexible(
                              child: Container(
                                width: deviceWidth * 0.1,
                                height: deviceHeight * 0.02,
                                color: colorBlack,
                              ),
                            ),
                            Container(
                              height: deviceAverageSize * 0.006,
                              width: deviceAverageSize * 0.006,
                              margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.02, end: deviceWidth * 0.02),
                              decoration: const BoxDecoration(
                                color: colorTextCommonLight,
                                shape: BoxShape.circle,
                              ),
                            ),
                            FaIcon(FontAwesomeIcons.clock, size: deviceAverageSize * 0.02, color: colorTextCommonLight),
                            SizedBox(width: deviceWidth * 0.01),
                            Flexible(
                              child: Container(
                                width: deviceWidth * 0.2,
                                height: deviceHeight * 0.02,
                                color: colorBlack,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          height: deviceHeight * 0.03,
                          margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.008, top: deviceHeight * 0.005),
                          child: ListView.builder(
                            shrinkWrap: true,
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsetsDirectional.zero,
                            itemCount: 2,
                            itemBuilder: (BuildContext context, position) {
                              return Container(
                                margin: EdgeInsetsDirectional.only(end: deviceWidth * 0.016),
                                padding: EdgeInsetsDirectional.only(
                                    start: deviceWidth * 0.01, end: deviceWidth * 0.01, top: deviceHeight * 0.002, bottom: deviceHeight * 0.002),
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(deviceAverageSize * 0.005), color: Colors.black),
                                child: Container(width: deviceWidth * 0.2),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )),
        ],
      ),
    );
  }
}

class InSpotLightShimmer extends StatelessWidget {
  final bool enabled;

  const InSpotLightShimmer({super.key, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: colorShimmerBg,
      highlightColor: Colors.grey[100]!,
      period: const Duration(milliseconds: 1500),
      enabled: enabled,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.045, end: deviceWidth * 0.045, top: deviceHeight * 0.005),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  flex: 1,
                  child: Container(
                    width: deviceWidth * 0.4,
                    height: deviceHeight * 0.025,
                    color: colorBlack,
                  ),
                ),
                Flexible(
                  flex: 0,
                  child: Container(
                    width: deviceWidth * 0.15,
                    height: deviceHeight * 0.022,
                    color: colorBlack,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: deviceHeight * 0.235,
            margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.02),
            child: GridView.builder(
                shrinkWrap: true,
                padding: EdgeInsetsDirectional.only(start: deviceWidth * 0.045, end: deviceHeight * 0.025),
                itemCount: 10,
                scrollDirection: Axis.horizontal,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisExtent: deviceHeight * 0.35),
                itemBuilder: (BuildContext context, int position) {
                  return Container(
                    margin: EdgeInsetsDirectional.only(end: deviceWidth * 0.02),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 0,
                          child: ClipRRect(
                            borderRadius: BorderRadius.all(Radius.circular(deviceAverageSize * 0.012)),
                            child: Container(
                              width: deviceAverageSize * 0.13,
                              height: deviceAverageSize * 0.13,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        SizedBox(width: deviceWidth * 0.025),
                        Expanded(
                          flex: 1,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                width: deviceWidth * 0.3,
                                height: deviceHeight * 0.025,
                                color: Colors.black,
                              ),
                              SizedBox(height: deviceHeight * 0.005),
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    FaIcon(FontAwesomeIcons.solidStar, size: deviceAverageSize * 0.02, color: colorRatingStar),
                                    SizedBox(width: deviceWidth * 0.01),
                                    Flexible(
                                      child: Container(
                                        width: deviceWidth * 0.1,
                                        height: deviceHeight * 0.022,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Container(
                                      height: deviceAverageSize * 0.006,
                                      width: deviceAverageSize * 0.006,
                                      margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.02, end: deviceWidth * 0.02),
                                      decoration: const BoxDecoration(
                                        color: colorTextCommonLight,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    FaIcon(FontAwesomeIcons.clock, size: deviceAverageSize * 0.02, color: colorTextCommonLight),
                                    SizedBox(width: deviceWidth * 0.01),
                                    Flexible(
                                      child: Container(
                                        width: deviceWidth * 0.15,
                                        height: deviceHeight * 0.022,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                height: deviceHeight * 0.03,
                                margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.008, top: deviceHeight * 0.008),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  scrollDirection: Axis.horizontal,
                                  padding: EdgeInsetsDirectional.zero,
                                  itemCount: 2,
                                  itemBuilder: (BuildContext context, position) {
                                    return Container(
                                      margin: EdgeInsetsDirectional.only(end: deviceWidth * 0.016),
                                      padding: EdgeInsetsDirectional.only(
                                          start: deviceWidth * 0.01,
                                          end: deviceWidth * 0.01,
                                          top: deviceHeight * 0.002,
                                          bottom: deviceHeight * 0.002),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(deviceAverageSize * 0.005),
                                        color: colorGray,
                                      ),
                                      child: Container(
                                        width: deviceWidth * 0.15,
                                        color: Colors.black,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
          ),
        ],
      ),
    );
  }
}
