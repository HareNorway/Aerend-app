import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../theme/design_scale.dart';
import '../../../utils/utils.dart';
import '../../../ui/kit/ae_club_crest.dart';
import '../dugnad_club_branding.dart';
import '../../../ui/kit/ae_theme.dart';
import '../dugnad_state.dart';
import 'dugnad_shiny_press.dart';

/// Home Klubbshop card — prototype `.sh-entry` in `dugnad/shop.css`.
class DugnadClubShopEntry extends StatelessWidget {
  const DugnadClubShopEntry({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final club = DugnadClubBranding.compactName();
    final radius = context.dp(18);
    final logo = DugnadState.instance.clubLogo;

    return DugnadShinyPress(
      borderRadius: radius,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: context.dp(16),
          vertical: context.dp(15),
        ),
        decoration: BoxDecoration(
          gradient: theme.shinyGradient,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: const Color(0x47140C28),
              blurRadius: context.dp(2),
              offset: Offset(0, context.dp(1)),
            ),
            BoxShadow(
              color: theme.primary.withValues(alpha: 0.62),
              blurRadius: context.dp(24),
              offset: Offset(0, context.dp(10)),
              spreadRadius: context.dp(-8),
            ),
          ],
        ),
        child: Row(
          children: [
            _LogoTile(
              name: DugnadClubBranding.fullName(),
              logoUrl: logo.isEmpty ? null : logo,
              accent: theme.primaryHover,
            ),
            SizedBox(width: context.dp(13)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    languages.dugnadClubShopTitle,
                    style: aeBody(color: Colors.white)
                        .copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: 15 * -0.01,
                          height: 1.2,
                        )
                        .dp(context),
                  ),
                  SizedBox(height: context.dp(3)),
                  Text(
                    languages.dugnadClubShopSubtitle(club),
                    style: aeCaption(
                      color: Colors.white.withValues(alpha: 0.78),
                    )
                        .copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                          height: 1.4,
                        )
                        .dp(context),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: context.dp(18),
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoTile extends StatelessWidget {
  const _LogoTile({
    required this.name,
    required this.logoUrl,
    required this.accent,
  });

  final String name;
  final String? logoUrl;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final size = context.dp(44);
    final radius = context.dp(13);
    final url = AeClubCrest.resolveClubMediaUrl(logoUrl);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.5),
            blurRadius: 0,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: const Color(0x47080C1E),
            blurRadius: context.dp(5),
            offset: Offset(0, context.dp(2)),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? Center(
              child: Text(
                _initials(name),
                style: aeBody(color: accent)
                    .copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: 15 * -0.01,
                    )
                    .dp(context),
              ),
            )
          : Padding(
              padding: EdgeInsets.all(context.dp(5)),
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (_, __) => const SizedBox.shrink(),
                errorWidget: (_, __, ___) => Center(
                  child: Text(
                    _initials(name),
                    style: aeBody(color: accent)
                        .copyWith(fontWeight: FontWeight.w800, fontSize: 15)
                        .dp(context),
                  ),
                ),
              ),
            ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (name.length >= 2) return name.substring(0, 2).toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
