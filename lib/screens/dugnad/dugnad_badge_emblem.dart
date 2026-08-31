import 'package:flutter/material.dart';

import '../../theme/sc_saas_theme.dart';
import 'dugnad_badges.dart';
import '../../ui/kit/ae_theme.dart';
class DugnadBadgeEmblem extends StatelessWidget {
  const DugnadBadgeEmblem({
    super.key,
    required this.iconName,
    required this.tone,
    required this.locked,
    this.size = 46,
  });

  final String iconName;
  final DugnadBadgeTone tone;
  final bool locked;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (locked) {
      return Opacity(
        opacity: 0.55,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ScSaasThemeTokens.gray100,
                ),
              ),
              Container(
                width: size * 0.72,
                height: size * 0.72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF1F1F4),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  _iconForName(iconName),
                  size: size * 0.38,
                  color: ScSaasThemeTokens.gray300,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final ringColors = _ringGradient(context, tone);
    final coreColors = _coreGradient(context, tone);
    final iconColor = _coreIconColor(context, tone);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: ringColors,
              ),
              boxShadow: [
                // `.ring` is `0 6px 14px -6px rgba(45,27,91,.4)` -- the
                // negative spread was dropped along with the alpha, so the
                // shadow read both wider and fainter than intended.
                BoxShadow(
                  color: context.aeTheme.text.withValues(alpha: 0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                  spreadRadius: -6,
                ),
              ],
            ),
            // `.ring`'s second layer: `0 1px 1px rgba(255,255,255,.7) inset`.
            // A ring with no top highlight reads flat however correct its
            // gradient is.
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.7),
                    Colors.white.withValues(alpha: 0),
                  ],
                  stops: const [0.0, 0.06],
                ),
              ),
            ),
          ),
          Container(
            width: size * 0.72,
            height: size * 0.72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: coreColors,
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.85),
                width: 2,
              ),
            ),
            // `.core`'s `0 1px 2px rgba(45,27,91,.18) inset` -- a shallow
            // top shading that sets the core into the ring. Also dropped.
            foregroundDecoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  context.aeTheme.text.withValues(alpha: 0.18),
                  context.aeTheme.text.withValues(alpha: 0),
                ],
                stops: const [0.0, 0.09],
              ),
            ),
            child: Icon(
              _iconForName(iconName),
              size: size * 0.38,
              color: iconColor,
            ),
          ),
          Positioned(
            top: size * 0.07,
            left: size * 0.14,
            right: size * 0.14,
            child: Container(
              height: size * 0.34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.55),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _ringGradient(BuildContext context, DugnadBadgeTone tone) {
    switch (tone) {
      case DugnadBadgeTone.gold:
        return const [Color(0xFFF7D979), Color(0xFFC2871C)];
      case DugnadBadgeTone.green:
        return const [Color(0xFF5FD39A), Color(0xFF22A769)];
      case DugnadBadgeTone.silver:
        return const [Color(0xFFE3E8EE), Color(0xFF9AA6B2)];
      case DugnadBadgeTone.purple:
        // `.tone-purple .ring` uses `--ae-shiny-purple` → club shiny fill.
        final theme = context.aeTheme;
        return theme.shinyGradient.colors.length >= 3
            ? [
                theme.shinyGradient.colors.first,
                theme.shinyGradient.colors[1],
                theme.shinyGradient.colors.last,
              ]
            : [theme.primary, theme.primaryHover];
    }
  }

  List<Color> _coreGradient(BuildContext context, DugnadBadgeTone tone) {
    switch (tone) {
      case DugnadBadgeTone.gold:
        return const [Color(0xFFFFF4D6), Color(0xFFF3CD72)];
      case DugnadBadgeTone.green:
        return const [Color(0xFFE3F7EC), Color(0xFFBFEAD2)];
      case DugnadBadgeTone.silver:
        return const [Color(0xFFFBFCFE), Color(0xFFDDE3EA)];
      case DugnadBadgeTone.purple:
        // `#efe9fb → #cdbef0` remapped from club primary.
        final primary = context.aeTheme.primary;
        return [
          Color.lerp(primary, Colors.white, 0.92) ?? context.aeTheme.primaryTint,
          Color.lerp(primary, Colors.white, 0.72) ?? context.aeTheme.primaryTint,
        ];
    }
  }

  Color _coreIconColor(BuildContext context, DugnadBadgeTone tone) {
    switch (tone) {
      case DugnadBadgeTone.gold:
        return const Color(0xFF9A6B12);
      case DugnadBadgeTone.green:
        return const Color(0xFF14794A);
      case DugnadBadgeTone.silver:
        return const Color(0xFF5B6470);
      case DugnadBadgeTone.purple:
        return context.aeTheme.primaryHover;
    }
  }

  IconData _iconForName(String name) => dugnadBadgeIconData(name);
}

/// Shared badge icon resolver used by emblems and the supporter card.
IconData dugnadBadgeIconData(String name) {
  switch (name) {
      case 'heart':
        return Icons.favorite_rounded;
      case 'share':
        return Icons.share_rounded;
      case 'shield':
        return Icons.shield_rounded;
      case 'flask':
        return Icons.science_rounded;
      case 'zap':
        return Icons.bolt_rounded;
      case 'flag':
        return Icons.flag_rounded;
      case 'award':
      case 'medal':
        return Icons.military_tech_rounded;
      case 'trophy':
        return Icons.emoji_events_rounded;
      case 'crown':
        return Icons.workspace_premium_rounded;
      case 'refresh':
        return Icons.autorenew_rounded;
      case 'boot':
        return Icons.sports_soccer_rounded;
      case 'activity':
      case 'flame':
        return Icons.local_fire_department_rounded;
      case 'box':
        return Icons.inventory_2_rounded;
      case 'sparkle':
      case 'sparkles':
        return Icons.auto_awesome_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'target':
      case 'goal':
        return Icons.track_changes_rounded;
      case 'users':
      case 'people':
      case 'group':
        return Icons.groups_rounded;
      case 'megaphone':
      case 'campaign':
        return Icons.campaign_rounded;
      case 'calendar':
        return Icons.event_available_rounded;
      case 'clock':
      case 'time':
        return Icons.schedule_rounded;
      case 'rocket':
        return Icons.rocket_launch_rounded;
      case 'pin':
      case 'location':
        return Icons.location_on_rounded;
      case 'handshake':
        return Icons.volunteer_activism_rounded;
      default:
        return Icons.star_rounded;
    }
}
