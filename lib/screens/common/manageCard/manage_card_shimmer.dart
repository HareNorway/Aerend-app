import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../utils/utils.dart';

class ManageCardShimmer extends StatelessWidget {
  final bool enabled;

  const ManageCardShimmer({super.key, this.enabled = true});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: Shimmer.fromColors(
          baseColor: colorShimmerBg,
          highlightColor: Colors.grey.shade100,
          enabled: enabled,
          period: const Duration(milliseconds: 1500),
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsetsDirectional.only(top: 0, bottom: deviceHeight * 0.12),
            itemCount: 8,
            itemBuilder: (BuildContext context, position) {
              return Card(
                margin: EdgeInsetsDirectional.only(
                    start: deviceWidth * 0.03, end: deviceWidth * 0.03, top: deviceHeight * 0.007, bottom: deviceHeight * 0.007),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(deviceAverageSize * 0.005),
                ),
                color: Colors.black45,
                child: Container(
                  padding: EdgeInsetsDirectional.only(
                      start: deviceWidth * 0.01, end: deviceWidth * 0.015, top: deviceHeight * 0.002, bottom: deviceHeight * 0.002),
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 0,
                        child: Padding(
                          padding: EdgeInsetsDirectional.only(
                              top: deviceHeight * 0.02, bottom: deviceHeight * 0.02, start: deviceWidth * 0.03, end: deviceWidth * 0.03),
                          child: Icon(CustomIcons.selectCardAddCard, size: deviceAverageSize * 0.06, color: colorPrimary),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: deviceWidth * 0.6,
                              color: Colors.black,
                              height: deviceHeight * 0.025,
                            ),
                            Container(
                              margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.006),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      margin: EdgeInsetsDirectional.only(end: deviceWidth * 0.1),
                                      width: deviceWidth,
                                      color: Colors.black,
                                      height: deviceHeight * 0.025,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 0,
                                    child: GestureDetector(
                                      onTap: () {},
                                      child: Padding(
                                        padding: EdgeInsetsDirectional.only(
                                            start: deviceWidth * 0.005,
                                            top: deviceHeight * 0.002,
                                            bottom: deviceHeight * 0.002,
                                            end: deviceWidth * 0.005),
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
                ),
              );
            },
          ),
        ),
      );
}
