import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/design_scale.dart';

import '../../theme/sc_saas_theme.dart';
import '../../utils/utils.dart';
import 'club_crest.dart';
import 'dugnad_club_theme.dart';

/// Profile head row (`.dg-prof-head`) — avatar · name/email · edit.
/// Bell lives in the screen `tk-head`; edit is right-aligned under it.
class DugnadProfileHead extends StatelessWidget {
  const DugnadProfileHead({
    super.key,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.onEdit,
  });

  final String name;
  final String email;
  final String avatarUrl;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.dp(2),
        context.dp(4),
        context.dp(2),
        context.dp(4),
      ),
      child: Row(
        children: [
          if (avatarUrl.trim().isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LoadImageWithPlaceHolder(
                image: avatarUrl,
                width: context.dp(62),
                height: context.dp(62),
                defaultAssetImage: 'assets/images/avatar_user.png',
                borderRadius: BorderRadius.circular(999),
              ),
            )
          else
            Container(
              width: context.dp(62),
              height: context.dp(62),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: theme.shinyGradient,
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryHover.withValues(alpha: 0.4),
                    blurRadius: context.dp(6),
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: context.dp(30),
              ),
            ),
          SizedBox(width: context.dp(15)),
          // `.tx { flex: 1 }` — fill so edit sits under the header bell.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: aeH2(color: theme.text).copyWith(fontSize: 20),
                ),
                SizedBox(height: context.dp(3)),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: aeCaption(),
                ),
              ],
            ),
          ),
          SizedBox(width: context.dp(10)),
          GestureDetector(
            onTap: onEdit,
            child: Container(
              width: context.dp(40),
              height: context.dp(40),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: ScSaasThemeTokens.shadowCard,
              ),
              child: Icon(
                Icons.edit_outlined,
                size: context.dp(17),
                color: theme.primaryHover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `.dg-prof-tour` — shiny club CTA that restarts the app walkthrough.
class DugnadProfileTourCard extends StatelessWidget {
  const DugnadProfileTourCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DugnadProfileShinyRow(
      icon: Icon(
        Icons.auto_awesome_rounded,
        size: context.dp(20),
        color: Colors.white,
      ),
      title: languages.dugnadTourRowTitle,
      subtitle: languages.dugnadTourRowSubtitle,
      onTap: onTap,
    );
  }
}

/// `.dg-prof-tour.dg-prof-purch` — opens Kampanjekjøp overview.
class DugnadProfilePurchasesCard extends StatelessWidget {
  const DugnadProfilePurchasesCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DugnadProfileShinyRow(
      icon: SvgPicture.asset(
        'assets/svgs/menu/box.svg',
        width: context.dp(20),
        height: context.dp(20),
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      ),
      title: languages.campaignPurchasesEntryTitle,
      subtitle: languages.campaignPurchasesEntrySubtitle,
      onTap: onTap,
    );
  }
}

/// Shared chrome for `.dg-prof-tour`: club shiny fill, 44px icon tile, press
/// `scale(.985)` over 120ms (prototype `transition: transform .12s ease`).
class DugnadProfileShinyRow extends StatefulWidget {
  const DugnadProfileShinyRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Widget icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  State<DugnadProfileShinyRow> createState() => _DugnadProfileShinyRowState();
}

class _DugnadProfileShinyRowState extends State<DugnadProfileShinyRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return AnimatedScale(
      scale: _pressed && !reduce ? 0.985 : 1,
      duration: reduce ? Duration.zero : const Duration(milliseconds: 120),
      curve: Curves.ease,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (v) {
            if (_pressed == v) return;
            setState(() => _pressed = v);
          },
          borderRadius: BorderRadius.circular(context.dp(18)),
          child: Ink(
            padding: EdgeInsets.symmetric(
              horizontal: context.dp(15),
              vertical: context.dp(14),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(context.dp(18)),
              gradient: theme.shinyGradient,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.35),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                  blurStyle: BlurStyle.inner,
                ),
                BoxShadow(
                  color: theme.primary.withValues(alpha: 0.75),
                  blurRadius: context.dp(30),
                  offset: Offset(0, context.dp(14)),
                  spreadRadius: context.dp(-16),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: context.dp(44),
                  height: context.dp(44),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(context.dp(13)),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.30),
                    ),
                  ),
                  child: widget.icon,
                ),
                SizedBox(width: context.dp(13)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.dp(15.5),
                          fontWeight: FontWeight.w900,
                          letterSpacing: context.dp(15.5) * -0.01,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: context.dp(2)),
                      Text(
                        widget.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.dp(12.5),
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: context.dp(18),
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// White grouped list (`.dg-prof-list`).
class DugnadProfileListCard extends StatelessWidget {
  const DugnadProfileListCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.dp(16)),
        boxShadow: [
          BoxShadow(
            color: context.dugnadTheme.text.withValues(alpha: 0.05),
            blurRadius: context.dp(4),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class DugnadProfileListRow extends StatelessWidget {
  const DugnadProfileListRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.icon,
    this.iconWidget,
    this.iconBackground,
    this.iconColor,
    this.amberIcon = false,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final IconData? icon;
  final Widget? iconWidget;
  final Color? iconBackground;
  final Color? iconColor;
  final bool amberIcon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.dp(14), vertical: context.dp(13)),
        child: Row(
          children: [
            _buildIcon(context),
            SizedBox(width: context.dp(13)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: aeBody().copyWith(fontWeight: FontWeight.w800),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    SizedBox(height: context.dp(2)),
                    Text(
                      subtitle!,
                      style: aeCaption(color: ScSaasThemeTokens.gray500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: context.dp(20),
              color: ScSaasThemeTokens.gray300,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    BoxDecoration decoration;
    if (amberIcon) {
      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(context.dp(11)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE0A93A), Color(0xFFC2871C)],
        ),
      );
    } else {
      decoration = BoxDecoration(
        color: iconBackground ?? context.dugnadTheme.primaryTint,
        borderRadius: BorderRadius.circular(context.dp(11)),
      );
    }
    final glyph = iconWidget ??
        Icon(
          icon ?? Icons.circle_outlined,
          size: context.dp(18),
          color: amberIcon
              ? Colors.white
              : (iconColor ?? context.dugnadTheme.primary),
        );
    return Container(
      width: context.dp(40),
      height: context.dp(40),
      decoration: decoration,
      alignment: Alignment.center,
      child: glyph,
    );
  }
}

class DugnadProfileListDivider extends StatelessWidget {
  const DugnadProfileListDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: context.dp(1),
      thickness: 1,
      color: ScSaasThemeTokens.gray100,
    );
  }
}

/// Min klubb card (`.dg-prof-club`).
class DugnadProfileClubCard extends StatelessWidget {
  const DugnadProfileClubCard({
    super.key,
    required this.clubName,
    required this.clubArea,
    required this.clubLogo,
    required this.onSwitch,
  });

  final String clubName;
  final String clubArea;
  final String? clubLogo;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSwitch,
      child: Container(
        padding: EdgeInsets.all(context.dp(14)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.dp(16)),
          border: Border.all(
            color: context.dugnadTheme.primary.withValues(alpha: 0.18),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: context.dugnadTheme.text.withValues(alpha: 0.05),
              blurRadius: context.dp(4),
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClubCrest(
              name: clubName,
              logoUrl: clubLogo?.isEmpty ?? true ? null : clubLogo,
              size: context.dp(46),
            ),
            SizedBox(width: context.dp(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clubName,
                    style: aeBody().copyWith(fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (clubArea.isNotEmpty) ...[
                    SizedBox(height: context.dp(2)),
                    Text(clubArea, style: aeCaption()),
                  ],
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: context.dp(14), vertical: context.dp(8)),
              decoration: BoxDecoration(
                color: context.dugnadTheme.primaryTint,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                languages.dugnadSwitch,
                style: aeLabel(color: context.dugnadTheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Combined "change team or club" shortcut (design: club → team chained flow).
class DugnadProfileChangeClubTeamCard extends StatelessWidget {
  const DugnadProfileChangeClubTeamCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(context.dp(14)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.dp(16)),
          border: Border.all(color: ScSaasThemeTokens.gray100, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: context.dugnadTheme.text.withValues(alpha: 0.05),
              blurRadius: context.dp(4),
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: context.dp(46),
              height: context.dp(46),
              decoration: BoxDecoration(
                color: context.dugnadTheme.primary,
                borderRadius: BorderRadius.circular(context.dp(14)),
                boxShadow: [
                  BoxShadow(
                    color: context.dugnadTheme.primary.withValues(alpha: 0.28),
                    blurRadius: context.dp(12),
                    offset: const Offset(0, 5),
                    spreadRadius: -6,
                  ),
                ],
              ),
              child: Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: context.dp(22),
              ),
            ),
            SizedBox(width: context.dp(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    languages.dugnadChangeTeamOrClub,
                    style: aeBody().copyWith(fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: context.dp(2)),
                  Text(
                    languages.dugnadChangeTeamOrClubSub,
                    style: aeCaption(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: context.dp(8)),
            const Icon(
              Icons.chevron_right_rounded,
              color: ScSaasThemeTokens.gray500,
            ),
          ],
        ),
      ),
    );
  }
}

/// `.dg-prof-logout` — white card, soft red icon tile, error label + chevron.
class DugnadProfileLogoutButton extends StatelessWidget {
  const DugnadProfileLogoutButton({super.key, required this.onTap});

  final VoidCallback onTap;

  static const Color _error = ScSaasThemeTokens.danger; // #DC4040

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.dp(16)),
        child: Ink(
          padding: EdgeInsets.all(context.dp(14)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.dp(16)),
            boxShadow: [
              BoxShadow(
                color: context.dugnadTheme.text.withValues(alpha: 0.05),
                blurRadius: context.dp(4),
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: context.dp(40),
                height: context.dp(40),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _error.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(context.dp(11)),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  size: context.dp(19),
                  color: _error,
                ),
              ),
              SizedBox(width: context.dp(12)),
              Expanded(
                child: Text(
                  languages.logout,
                  style: TextStyle(
                    fontSize: context.dp(14),
                    fontWeight: FontWeight.w800,
                    letterSpacing: context.dp(14) * -0.01,
                    color: _error,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: context.dp(18),
                color: _error.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
