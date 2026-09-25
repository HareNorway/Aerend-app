import 'package:flutter/material.dart';

import 'a3_services.dart';
import '../kit/bergen_kit.dart';

/// The page frame every agil-3 screen uses: teal (`onDark`) or paper, the
/// design's header row (back, title, optional trailing), the reduced-motion
/// preference applied, and the shell's bottom reserve.
class A3Scaffold extends StatelessWidget {
  const A3Scaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.onDark = true,
    this.trailing,
    this.kicker,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 24),
    this.showBack = true,
  });

  final String title;
  final String? subtitle;
  final String? kicker;
  final Widget child;
  final bool onDark;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final fg = onDark ? Colors.white : BergenTokens.ink;
    final sub = onDark ? const Color(0xFFDCE9EC) : BergenTokens.inkSecondary;

    return ValueListenableBuilder<bool>(
      valueListenable: A3Services.reducedMotion,
      builder: (context, reduced, _) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduced || MediaQuery.of(context).disableAnimations),
        child: Scaffold(
          backgroundColor: onDark ? BergenTokens.tealDeep : BergenTokens.body,
          body: DecoratedBox(
            decoration: BoxDecoration(gradient: onDark ? BergenTokens.screen : null),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 16, 8),
                    child: Row(
                      children: [
                        if (showBack && Navigator.of(context).canPop())
                          IconButton(
                            tooltip: 'Tilbake',
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: Icon(Icons.arrow_back_rounded, color: fg),
                          )
                        else
                          const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (kicker != null)
                                Text(
                                  kicker!,
                                  style: BergenTokens.text(BergenTokens.textMicro, weight: FontWeight.w800, color: BergenTokens.orangeLight),
                                ),
                              Text(title, style: BergenTokens.display(BergenTokens.textTitle, color: fg)),
                              if (subtitle != null)
                                Text(subtitle!, style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w500, color: sub)),
                            ],
                          ),
                        ),
                        if (trailing != null) trailing!,
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: padding,
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A section heading in the design's small-caps style.
class A3Kicker extends StatelessWidget {
  const A3Kicker(this.text, {super.key, this.onDark = true, this.trailing});

  final String text;
  final bool onDark;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: BergenTokens.text(BergenTokens.textMicro, weight: FontWeight.w800, color: onDark ? const Color(0xFF9FD3DE) : BergenTokens.inkMuted).copyWith(letterSpacing: 1.2),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// A design "row" (Meg-rader, Konto rows): icon, title, subtitle, trailing, chevron.
class A3Row extends StatelessWidget {
  const A3Row({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.onTap,
    this.onDark = true,
    this.badge,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool onDark;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final fg = onDark ? Colors.white : BergenTokens.ink;
    final sub = onDark ? const Color(0xFFDCE9EC) : BergenTokens.inkSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BergenCard(
        onDark: onDark,
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: onDark ? BergenTokens.mint : BergenTokens.teal),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: BergenTokens.text(BergenTokens.textBody, weight: FontWeight.w700, color: fg)),
                  if (subtitle != null) Text(subtitle!, style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w500, color: sub)),
                ],
              ),
            ),
            if (badge != null) ...[
              BergenChip(label: badge!, selected: true),
              const SizedBox(width: 8),
            ],
            if (trailing != null) trailing! else if (onTap != null) Icon(Icons.chevron_right_rounded, color: sub),
          ],
        ),
      ),
    );
  }
}

String a3Kr(int ore) => '${(ore / 100).toStringAsFixed(ore % 100 == 0 ? 0 : 2).replaceAll('.', ',')} kr';

/// Cream text tones on the teal screens (the design's `#DCE9EC/#BFD6DD/#9FB6C2`).
abstract final class A3Ink {
  static const Color sub = Color(0xFFDCE9EC);
  static const Color soft = Color(0xFFBFD6DD);
  static const Color muted = Color(0xFF9FB6C2);
}
