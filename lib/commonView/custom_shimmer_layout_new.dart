import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constant/constant.dart';

/// Updated CustomShimmerLayout with subtle shimmer and skeleton structure.
/// Used for general list loading states.
class CustomShimmerLayout extends StatefulWidget {
  final bool enabled;
  final int itemCount;

  const CustomShimmerLayout({
    super.key,
    this.enabled = true,
    this.itemCount = 8,
  });

  @override
  State createState() => _CustomShimmerLayoutState();
}

class _CustomShimmerLayoutState extends State<CustomShimmerLayout> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: deviceWidth * 0.03,
        vertical: deviceHeight * 0.005,
      ),
      child: Shimmer.fromColors(
        baseColor: colorShimmerBg,
        highlightColor: Colors.grey[100]!,
        enabled: widget.enabled,
        period: const Duration(milliseconds: 1500), // Subtle, smooth shimmer
        child: ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.itemCount,
          itemBuilder: (_, index) => Padding(
            padding: EdgeInsets.only(bottom: deviceHeight * 0.02),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar skeleton
                Container(
                  width: deviceAverageSize * 0.11,
                  height: deviceAverageSize * 0.11,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                SizedBox(width: deviceWidth * 0.03),
                // Text content skeleton
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Title line
                      Container(
                        width: double.infinity,
                        height: deviceHeight * 0.016,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      SizedBox(height: deviceHeight * 0.008),
                      // Subtitle line
                      Container(
                        width: double.infinity * 0.75,
                        height: deviceHeight * 0.014,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      SizedBox(height: deviceHeight * 0.008),
                      // Meta info line
                      Container(
                        width: double.infinity * 0.5,
                        height: deviceHeight * 0.012,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
