import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class FeedImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? aspectRatio;
  final BorderRadius? borderRadius;

  const FeedImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.aspectRatio,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = Shimmer.fromColors(
      baseColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      highlightColor: scheme.surface,
      child: Container(color: scheme.surfaceContainerHighest),
    );
    final errorWidget = Container(
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(Icons.broken_image_outlined, color: scheme.outline),
    );

    Widget image = CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (_, __) => placeholder,
      errorWidget: (_, __, ___) => errorWidget,
      fadeInDuration: const Duration(milliseconds: 200),
    );

    if (aspectRatio != null) {
      image = AspectRatio(aspectRatio: aspectRatio!, child: image);
    }

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }
}
