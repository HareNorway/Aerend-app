import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../kit/bergen_kit.dart';
import 'meg_shine.dart';

/// The design's Ark (`kVisArk` ≈L7333): the cream frosted sheet the Meg rows
/// open — `rgba(245,243,239,.94)` + blur, 28px top corners, the title (19px),
/// the line under it, the 38×38 close square, a scrolling body with 8px gaps,
/// and the two 52px footer pills (white secondary, dark primary).
abstract final class MegArkInk {
  static const Color ink = Color(0xFF23201D);
  static const Color sub = Color(0xFF57534B);
  static const Color muted = Color(0xFF6E6862);
  static const Color faint = Color(0xFF8C847C);
  static const Color teal = Color(0xFF1E4F5C);
  static const Color green = Color(0xFF2E6B47);

  /// Default primary (`GT` in the design's Ark): the deep teal.
  static const LinearGradient tealCta = LinearGradient(
    begin: Alignment(-.34, -.94),
    end: Alignment(.34, .94),
    colors: [Color(0xFF2A6272), Color(0xFF1E4F5C), Color(0xFF173E48)],
    stops: [0, .6, 1],
  );

  /// The Gullbilletten primary: `linear-gradient(180deg,#6B5120,#463316 58%,#33240E)`.
  static const LinearGradient goldCta = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF6B5120), Color(0xFF463316), Color(0xFF33240E)],
    stops: [0, .58, 1],
  );
}

class MegArkButton {
  const MegArkButton({required this.label, required this.onTap, this.gradient, this.key});

  final String label;
  final VoidCallback onTap;
  final Gradient? gradient;
  final Key? key;
}

typedef MegArkBody = Widget Function(BuildContext context, StateSetter setState);

Future<T?> showMegArk<T>(
  BuildContext context, {
  required String title,
  String? subtitle,
  MegArkBody? body,
  MegArkButton? primary,
  MegArkButton? secondary,
  Key? key,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color.fromRGBO(15, 25, 30, .5),
    sheetAnimationStyle: AnimationStyle(
      curve: const Cubic(.2, .9, .3, 1),
      duration: BergenTokens.motion(context, const Duration(milliseconds: 300)),
      reverseDuration: BergenTokens.motion(context, BergenTokens.motionBase),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => MegArk(
        key: key,
        title: title,
        subtitle: subtitle,
        body: body == null ? null : body(ctx, setState),
        primary: primary,
        secondary: secondary,
      ),
    ),
  );
}

class MegArk extends StatelessWidget {
  const MegArk({super.key, required this.title, this.subtitle, this.body, this.primary, this.secondary});

  final String title;
  final String? subtitle;
  final Widget? body;
  final MegArkButton? primary;
  final MegArkButton? secondary;

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * .86;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3EF).withValues(alpha: .96),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: .95), width: 1.5)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: BergenTokens.display(19, weight: FontWeight.w800, color: MegArkInk.ink, letterSpacingEm: -0.02)),
                              if (subtitle != null && subtitle!.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(subtitle!, style: BergenTokens.text(12.5, weight: FontWeight.w600, color: MegArkInk.sub, height: 1.45)),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        _CloseSquare(onTap: () => Navigator.of(context).maybePop()),
                      ],
                    ),
                  ),
                  if (body != null)
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                        child: body,
                      ),
                    ),
                  if (primary != null || secondary != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                      child: Row(
                        children: [
                          if (secondary != null) Expanded(flex: 10, child: _ArkSecondary(button: secondary!)),
                          if (secondary != null && primary != null) const SizedBox(width: 8),
                          if (primary != null) Expanded(flex: 16, child: _ArkPrimary(button: primary!)),
                        ],
                      ),
                    )
                  else
                    const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseSquare extends StatelessWidget {
  const _CloseSquare({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('meg-ark-lukk'),
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: .9)),
        ),
        child: const Icon(Icons.close_rounded, size: 18, color: MegArkInk.ink),
      ),
    );
  }
}

class _ArkSecondary extends StatelessWidget {
  const _ArkSecondary({required this.button});

  final MegArkButton button;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: button.key,
      onTap: button.onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFEFF3F4)]),
          border: Border.all(color: Colors.white.withValues(alpha: .95)),
          boxShadow: const [
            BoxShadow(color: Color(0xFFD2DDE0), offset: Offset(0, 1.5)),
            BoxShadow(color: Color.fromRGBO(60, 90, 100, .3), offset: Offset(0, 3.5)),
          ],
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(button.label, textAlign: TextAlign.center, style: BergenTokens.display(14, weight: FontWeight.w800, color: const Color(0xFF1B4A57))),
        ),
      ),
    );
  }
}

class _ArkPrimary extends StatelessWidget {
  const _ArkPrimary({required this.button});

  final MegArkButton button;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: button.key,
      onTap: button.onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: button.gradient ?? MegArkInk.tealCta,
          border: Border.all(color: Colors.white.withValues(alpha: .28)),
          boxShadow: const [
            BoxShadow(color: Color.fromRGBO(8, 30, 38, .75), offset: Offset(0, 1.5)),
            BoxShadow(color: Color.fromRGBO(8, 30, 38, .5), offset: Offset(0, 3.5)),
          ],
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(button.label, textAlign: TextAlign.center, style: BergenTokens.display(14.5, weight: FontWeight.w800, color: Colors.white)),
        ),
      ),
    );
  }
}

/// A row in the Ark (design `rad`): white .62 card, 16px radius, the title,
/// the line under it, the teal value on the right; selected rows turn teal.
class MegArkRow extends StatelessWidget {
  const MegArkRow({super.key, required this.title, this.sub, this.value, this.onTap, this.selected = false, this.leading, this.trailing});

  final String title;
  final String? sub;
  final String? value;
  final VoidCallback? onTap;
  final bool selected;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? MegArkInk.teal.withValues(alpha: .12) : Colors.white.withValues(alpha: .62),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? MegArkInk.teal : Colors.white.withValues(alpha: .9), width: 1.5),
          ),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 10)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: BergenTokens.text(14, weight: FontWeight.w700, color: MegArkInk.ink)),
                    if (sub != null && sub!.isNotEmpty) Text(sub!, style: BergenTokens.text(12, weight: FontWeight.w600, color: MegArkInk.muted, height: 1.4)),
                  ],
                ),
              ),
              if (value != null && value!.isNotEmpty) ...[
                const SizedBox(width: 10),
                Text(value!, style: BergenTokens.text(13, weight: FontWeight.w800, color: MegArkInk.teal)),
              ],
              if (trailing != null) ...[const SizedBox(width: 10), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

/// The white paper card inside an Ark (`linear-gradient(168deg,#FFFFFF,#F4F0E6)`).
class MegArkCard extends StatelessWidget {
  const MegArkCard({super.key, required this.child, this.padding = const EdgeInsets.all(14)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(begin: Alignment(-.2, -1), end: Alignment(.2, 1), colors: [Colors.white, Color(0xFFF4F0E6)]),
        border: Border.all(color: MegArkInk.ink.withValues(alpha: .07)),
      ),
      child: child,
    );
  }
}

/// The gold code card (`kVisArkTekst`): label, the code in wide caps, the
/// dark Kopier pill, and the slow shine.
class MegArkCodeCard extends StatelessWidget {
  const MegArkCodeCard({super.key, required this.label, required this.code, required this.onCopy});

  final String label;
  final String code;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        key: const Key('meg-ark-kode'),
        onTap: onCopy,
        child: MegShine(
          borderRadius: BorderRadius.circular(18),
          period: const Duration(seconds: 5),
          delay: const Duration(seconds: 1),
          bandFraction: .3,
          opacity: .5,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(begin: Alignment(-.6, -1), end: Alignment(.6, 1), colors: [Color(0xFFFFF6DC), Color(0xFFF2DDA8), Color(0xFFE3C377)], stops: [0, .55, 1]),
              border: Border.all(color: Colors.white.withValues(alpha: .8)),
              boxShadow: const [
                BoxShadow(color: Color(0xFFC9A85E), offset: Offset(0, 1.5)),
                BoxShadow(color: Color.fromRGBO(120, 80, 10, .32), offset: Offset(0, 3.5)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 1.3, color: Color(0xFF3F2C06))),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(code, style: BergenTokens.display(22, weight: FontWeight.w800, color: const Color(0xFF3A2708), letterSpacingEm: .08, height: 1.2)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: MegArkInk.goldCta,
                    border: Border.all(color: const Color.fromRGBO(255, 240, 200, .3)),
                    boxShadow: const [
                      BoxShadow(color: Color(0xFF241A08), offset: Offset(0, 1.5)),
                      BoxShadow(color: Color.fromRGBO(20, 14, 4, .5), offset: Offset(0, 3)),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy_rounded, size: 13, color: Color(0xFFFBE8B4)),
                      SizedBox(width: 5),
                      Text('Kopier', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFFFBE8B4))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
