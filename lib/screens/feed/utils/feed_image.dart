import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class FeedImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? aspectRatio;
  final BorderRadius? borderRadius;

  /// Replaces the broken-image placeholder.
  ///
  /// A story whose media has expired mid-view is not a broken image — it is a
  /// story that ended, and a grey icon leaves the viewer wondering whether the
  /// app is broken. Callers that know what a missing image *means* pass their
  /// own explanation (handover T3).
  final WidgetBuilder? errorBuilder;

  const FeedImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.aspectRatio,
    this.borderRadius,
    this.errorBuilder,
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
      errorWidget: (BuildContext ctx, __, ___) =>
          errorBuilder?.call(ctx) ?? errorWidget,
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
