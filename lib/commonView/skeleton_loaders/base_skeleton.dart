import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../constant/constant.dart';

/// Base skeleton component with subtle shimmer animation.
/// Provides a smooth, non-blinking loading placeholder.
class BaseSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final ShapeBorder? shape;

  const BaseSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: colorShimmerBg,
      highlightColor: Colors.grey[100]!,
      period: const Duration(milliseconds: 1500), // Smooth, subtle shimmer
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
        child: shape != null
            ? DecoratedBox(
                decoration: ShapeDecoration(
                  shape: shape!,
                  color: Colors.white,
                ),
              )
            : null,
      ),
    );
  }
}

/// Text skeleton that mimics a single line of text.
class TextSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const TextSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return BaseSkeleton(
      width: width,
      height: height,
      borderRadius: borderRadius ?? BorderRadius.circular(4),
    );
  }
}

/// Image skeleton with circular or rectangular shape.
class ImageSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final bool isCircular;

  const ImageSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.isCircular = false,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: colorShimmerBg,
      highlightColor: Colors.grey[100]!,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircular ? null : BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// Button skeleton.
class ButtonSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ButtonSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 48,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return BaseSkeleton(
      width: width,
      height: height,
      borderRadius: borderRadius ?? BorderRadius.circular(12),
    );
  }
}

/// Card skeleton with image and text lines.
class CardSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double imageHeight;
  final int textLines;

  const CardSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 220,
    this.imageHeight = 140,
    this.textLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: colorShimmerBg,
      highlightColor: Colors.grey[100]!,
      period: const Duration(milliseconds: 1500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: width,
            height: imageHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(
            textLines,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                width: index == textLines - 1 ? width * 0.7 : width,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// List item skeleton.
class ListItemSkeleton extends StatelessWidget {
  final double avatarSize;
  final int textLines;

  const ListItemSkeleton({
    super.key,
    this.avatarSize = 60,
    this.textLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: colorShimmerBg,
      highlightColor: Colors.grey[100]!,
      period: const Duration(milliseconds: 1500),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                textLines,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    width: index == textLines - 1 ? double.infinity * 0.7 : double.infinity,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
