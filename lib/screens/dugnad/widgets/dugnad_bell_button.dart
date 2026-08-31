import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../theme/design_scale.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../dugnad_club_theme.dart';
import '../dugnad_state.dart';
import '../dugnad_notification_unread.dart';
import '../dugnad_notifications_screen.dart';

/// Profile / hero bell (`.dg-prof-bell`) with optional red unread dot.
class DugnadBellButton extends StatefulWidget {
  const DugnadBellButton({
    super.key,
    this.onHero = false,
  });

  /// Club hero top bar (`.dg-prof-bell.on-hero`).
  final bool onHero;

  @override
  State<DugnadBellButton> createState() => _DugnadBellButtonState();
}

class _DugnadBellButtonState extends State<DugnadBellButton> {
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    DugnadNotificationUnread.refresh();
  }

  Future<void> _open() async {
    await Navigator.of(context).push(
      buildAppPageRoute(const DugnadNotificationsScreen()),
    );
    if (mounted) DugnadNotificationUnread.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final size = context.dp(40);
    if (!DugnadState.instance.hasClub) {
      return widget.onHero
          ? SizedBox(width: size, height: size)
          : const SizedBox.shrink();
    }
    final disc = widget.onHero ? theme.primaryTint : Colors.white;
    final iconColor = widget.onHero ? theme.text : theme.primaryHover;
    final heroShadow = [
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.85),
        blurRadius: 0,
        offset: const Offset(0, 1),
      ),
      BoxShadow(
        color: const Color(0xFF040C18).withValues(alpha: 0.40),
        blurRadius: 1,
        offset: const Offset(0, 1),
      ),
      BoxShadow(
        color: const Color(0xFF040C18).withValues(alpha: 0.40),
        blurRadius: 5,
        spreadRadius: -1,
        offset: const Offset(0, 3),
      ),
      BoxShadow(
        color: const Color(0xFF040C18).withValues(alpha: 0.55),
        blurRadius: 20,
        spreadRadius: -6,
        offset: const Offset(0, 10),
      ),
    ];

    return ValueListenableBuilder<int>(
      valueListenable: DugnadNotificationUnread.count,
      builder: (context, count, _) {
        final hasUnread = count > 0;
        return GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: _open,
          child: Semantics(
            button: true,
            label: hasUnread ? 'Varsler ($count uleste)' : 'Varsler',
            child: AnimatedScale(
              scale: _pressed ? (widget.onHero ? 0.94 : 0.92) : 1,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.onHero ? null : Colors.white,
                  gradient: widget.onHero
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white,
                            theme.primaryTint,
                            Color.lerp(theme.primaryTint, Colors.black, 0.12)!,
                          ],
                          stops: const [0.0, 0.62, 1.0],
                        )
                      : null,
                  boxShadow: widget.onHero
                      ? heroShadow
                      : ScSaasThemeTokens.shadowCard,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/svgs/menu/bell.svg',
                      width: context.dp(19),
                      height: context.dp(19),
                      colorFilter: ColorFilter.mode(
                        iconColor,
                        BlendMode.srcIn,
                      ),
                    ),
                    if (hasUnread)
                      Positioned(
                        top: context.dp(8),
                        right: context.dp(9),
                        child: Container(
                          width: context.dp(8),
                          height: context.dp(8),
                          decoration: BoxDecoration(
                            color: ScSaasThemeTokens.danger,
                            shape: BoxShape.circle,
                            border: Border.all(color: disc, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
