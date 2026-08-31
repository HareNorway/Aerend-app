import 'package:flutter/material.dart';

class IconSurface extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double size;
  final EdgeInsets padding;
  final BorderRadius borderRadius;

  const IconSurface({
    super.key,
    required this.child,
    this.onTap,
    this.size = 44,
    this.padding = const EdgeInsets.all(10),
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.surface;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
                color: Color.fromRGBO(0, 0, 0, isDark ? 0.35 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
          ],
        ),
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: Padding(
            padding: padding,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class BackIconSurface extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget? icon;

  const BackIconSurface({super.key, this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    return IconSurface(
      onTap: onPressed ?? () => Navigator.maybePop(context),
      child: icon ?? Icon(Icons.arrow_back, size: 20, color: Theme.of(context).iconTheme.color),
    );
  }
}
