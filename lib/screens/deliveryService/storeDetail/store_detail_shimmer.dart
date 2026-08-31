import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../utils/utils.dart';

class StoreDetailShimmer extends StatelessWidget {
  final bool enabled;

  const StoreDetailShimmer({super.key, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = Theme.of(context).colorScheme.surface;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade800 : colorShimmerBg,
      highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
      enabled: enabled,
      period: const Duration(milliseconds: 1500),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsetsDirectional.only(
            start: deviceWidth * 0.03,
            end: deviceWidth * 0.03,
            top: deviceHeight * 0.01,
            bottom: deviceHeight * 0.02,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _heroBannerSkeleton(),
              SizedBox(height: deviceHeight * 0.02),
              Center(
                child: _line(
                  width: deviceWidth * 0.55,
                  height: 28,
                  radius: 10,
                ),
              ),
              SizedBox(height: deviceHeight * 0.012),
              Center(
                child: _line(
                  width: deviceWidth * 0.66,
                  height: 16,
                ),
              ),
              SizedBox(height: deviceHeight * 0.012),
              Center(
                child: _line(
                  width: deviceWidth * 0.36,
                  height: 38,
                  radius: 19,
                ),
              ),
              SizedBox(height: deviceHeight * 0.02),
              _searchBarSkeleton(cardColor),
              SizedBox(height: deviceHeight * 0.02),
              _tabHeaderSkeleton(),
              SizedBox(height: deviceHeight * 0.018),
              _subCategorySkeleton(cardColor),
              SizedBox(height: deviceHeight * 0.012),
              ...List.generate(4, (_) => _productCardSkeleton(cardColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroBannerSkeleton() {
    return Container(
      height: deviceHeight * 0.28,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 18,
            right: 18,
            child: _line(width: 88, height: 34, radius: 12),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 68,
            child: Column(
              children: [
                _line(width: deviceWidth * 0.5, height: 22, radius: 8),
                const SizedBox(height: 10),
                _line(width: deviceWidth * 0.74, height: 15),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _line(width: 54, height: 18, radius: 10),
                    const SizedBox(width: 8),
                    _line(width: 10, height: 10, radius: 5),
                    const SizedBox(width: 8),
                    _line(width: 72, height: 18, radius: 10),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: -24,
            child: Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBarSkeleton(Color cardColor) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _line(width: 24, height: 24, radius: 12),
          const SizedBox(width: 12),
          Expanded(child: _line(width: double.infinity, height: 18)),
        ],
      ),
    );
  }

  Widget _tabHeaderSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _line(width: deviceWidth * 0.15, height: 22),
            SizedBox(width: deviceWidth * 0.06),
            _line(width: deviceWidth * 0.15, height: 22),
            SizedBox(width: deviceWidth * 0.06),
            _line(width: deviceWidth * 0.15, height: 22),
          ],
        ),
        const SizedBox(height: 10),
        Container(height: 1.2, color: Colors.grey.shade300),
      ],
    );
  }

  Widget _subCategorySkeleton(Color cardColor) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 110,
                height: 70,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 8),
              _line(width: 80, height: 12),
            ],
          );
        },
      ),
    );
  }

  Widget _productCardSkeleton(Color cardColor) {
    return Container(
      margin: EdgeInsets.only(bottom: deviceHeight * 0.015),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _line(width: deviceWidth * 0.42, height: 24)),
                    const SizedBox(width: 12),
                    _line(width: 86, height: 24),
                  ],
                ),
                const SizedBox(height: 10),
                _line(width: deviceWidth * 0.55, height: 16),
                const SizedBox(height: 8),
                _line(width: deviceWidth * 0.42, height: 16),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _line(width: deviceWidth * 0.26, height: 16),
                    const Spacer(),
                    _line(width: 72, height: 16),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _line({
    required double width,
    required double height,
    double radius = 6,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
