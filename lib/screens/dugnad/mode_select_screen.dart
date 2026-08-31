import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/design_scale.dart';
import '../../theme/reen_pre_club_theme.dart';
import '../../utils/utils.dart';
import '../common/auth/auth_style.dart';
import '../snurre/snurre_launcher_policy.dart';
import 'club_onboarding_screen.dart';
import 'dugnad_flip_route.dart';
import 'dugnad_state.dart';
import 'dugnad_club_theme.dart';
import 'widgets/dugnad_rise_in.dart';
import '../common/login/login.dart';

/// "Velg modus" — mode gate shown after login when onboarding is incomplete.
///
/// Pre-club: Reen coral-navy (`.reen-pre`). Design: `ModeSelect` in dugnad/auth.jsx.
class ModeSelectScreen extends StatelessWidget {
  const ModeSelectScreen({super.key});

  // Fixed px on the 375×812 reference frame.
  static const double _backMarginTop = 6; // .ae-back inline margin-top
  static const double _headMarginTop = 10; // .dg-auth-head margin-top
  static const double _titleMarginBottom = 8; // .dg-auth-head h1 margin-bottom
  static const double _headMarginBottom = 26; // .dg-auth-head margin-bottom
  static const double _modeListMarginTop = 4; // .dg-mode-list margin-top
  static const double _modeListGap = 14; // .dg-mode-list gap
  static const double _infoMarginTop = 26; // .dg-info inline margin-top

  BoxDecoration get _glassCard => BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ReenPreClubTokens.glassBorder),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x1AFFFFFF), Color(0x09FFFFFF)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x59081424),
            blurRadius: 26,
            offset: Offset(0, 14),
            spreadRadius: -10,
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return DugnadClubThemeScope(
      palette: DugnadClubThemePalette.reenPreClub,
      child: Builder(builder: _buildPreClub),
    );
  }

  Widget _buildPreClub(BuildContext context) {
    final theme = context.dugnadTheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: theme.background,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: ReenPreClubTokens.screenGradient,
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: AuthScaffold.dgAuthPadding(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: context.dp(_backMarginTop)),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: AuthBackButton(onTap: () => _onBack(context)),
                        ),
                        SizedBox(height: context.dp(_headMarginTop)),
                        Text(
                          languages.dugnadSelectModeTitle,
                          textAlign: TextAlign.center,
                          style: aeH1(color: Colors.white)
                              .copyWith(fontSize: context.dp(26)),
                        ),
                        SizedBox(height: context.dp(_titleMarginBottom)),
                        Center(
                          child: ConstrainedBox(
                            constraints:
                                BoxConstraints(maxWidth: context.dp(268)),
                            child: Text(
                              languages.dugnadSelectModeSubtitle,
                              textAlign: TextAlign.center,
                              style: aeBody(color: ReenPreClubTokens.textSubtitle)
                                  .copyWith(
                                    fontSize: context.dp(14),
                                    height: 1.45,
                                  ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: context.dp(
                            _headMarginBottom + _modeListMarginTop,
                          ),
                        ),
                        DugnadRiseIn(child: _buildDugnadCard(context, theme)),
                        SizedBox(height: context.dp(_modeListGap)),
                        DugnadRiseIn(
                          delay: const Duration(milliseconds: 80),
                          child: _buildCommercialCard(context),
                        ),
                        SizedBox(height: context.dp(_infoMarginTop)),
                        _buildInfoBanner(context, theme),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onBack(BuildContext context) {
    HapticFeedback.lightImpact();
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
    } else {
      openScreenWithClearPrevious(context, const Login());
    }
  }

  /// `.dg-modecard.dugnad` — grid `54px 1fr auto`, gap 15, radius 20, pad 18.
  Widget _buildDugnadCard(BuildContext context, DugnadClubThemePalette theme) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        await DugnadState.instance.setDugnadMode(true);
        if (!context.mounted) return;
        // `[data-trans="flip"]` on `.dg-viewport` — the 3D depth push.
        Navigator.of(context).push(
          DugnadFlipRoute<void>(
            settings: RouteSettings(
              name: snurreLauncherRouteNameFor(const ClubOnboardingScreen()),
            ),
            builder: (_) => const ClubOnboardingScreen(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(context.dp(18)),
        decoration: _glassCard.copyWith(
          borderRadius: BorderRadius.circular(context.dp(20)),
        ),
        child: Row(
          children: [
            // .dg-modecard .mi { width: 54; height: 54; border-radius: 16 }
            Container(
              width: context.dp(54),
              height: context.dp(54),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: theme.shinyGradient,
                borderRadius: BorderRadius.circular(context.dp(16)),
                boxShadow: theme.shadowButton,
              ),
              child: Icon(
                Icons.favorite_rounded,
                color: Colors.white,
                size: context.dp(24),
              ),
            ),
            SizedBox(width: context.dp(15)),
            Expanded(
              child: _buildCardText(
                context: context,
                title: languages.dugnadModeDugnad,
                titleColor: Colors.white,
                description: languages.dugnadModeDugnadDesc,
                badge: _buildBadge(
                  context: context,
                  icon: Icons.check_rounded,
                  label: languages.dugnadModeActive,
                  foreground: Colors.white,
                  background: theme.primary,
                  horizontalPadding: 8,
                ),
              ),
            ),
            SizedBox(width: context.dp(15)),
            Icon(
              Icons.chevron_right_rounded,
              color: ReenPreClubTokens.textSoft,
              size: context.dp(20),
            ),
          ],
        ),
      ),
    );
  }

  /// `.dg-modecard.soon` — same box metrics, no trailing chevron.
  Widget _buildCommercialCard(BuildContext context) {
    return Opacity(
      opacity: 0.55,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(context.dp(18)),
        decoration: _glassCard.copyWith(
          borderRadius: BorderRadius.circular(context.dp(20)),
        ),
        child: Row(
          children: [
            Container(
              width: context.dp(54),
              height: context.dp(54),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0x24FFFFFF),
                borderRadius: BorderRadius.circular(context.dp(16)),
              ),
              child: Icon(
                Icons.storefront_rounded,
                color: ReenPreClubTokens.textSoft,
                size: context.dp(24),
              ),
            ),
            SizedBox(width: context.dp(15)),
            Expanded(
              child: _buildCardText(
                context: context,
                title: languages.dugnadModeCommercial,
                titleColor: ReenPreClubTokens.textSoft,
                description: languages.dugnadModeCommercialDesc,
                badge: _buildBadge(
                  context: context,
                  icon: Icons.schedule_rounded,
                  label: languages.dugnadModeComingSoon,
                  foreground: ReenPreClubTokens.textSoft,
                  background: const Color(0x33FFFFFF),
                  horizontalPadding: 9,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// `.mt` (17/800/-0.01em, gap 9, wraps) over `.ms` (12.5/600, lh 1.4, mt 4).
  Widget _buildCardText({
    required BuildContext context,
    required String title,
    required Color? titleColor,
    required String description,
    required Widget badge,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: context.dp(9),
          runSpacing: context.dp(4),
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              title,
              style:
                  aeH3(color: titleColor).copyWith(fontSize: context.dp(17)),
            ),
            badge,
          ],
        ),
        SizedBox(height: context.dp(4)),
        Text(
          description,
          style: TextStyle(
            fontSize: context.dp(12.5),
            fontWeight: FontWeight.w600,
            height: 1.4,
            color: ReenPreClubTokens.textSoft,
          ),
        ),
      ],
    );
  }

  /// `.recommend` / `.soon-badge` — 10px/800/.02em, 3px vertical, gap 4.
  Widget _buildBadge({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color foreground,
    required Color background,
    required double horizontalPadding,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.dp(horizontalPadding),
        vertical: context.dp(3),
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: context.dp(10), color: foreground),
          SizedBox(width: context.dp(4)),
          Text(
            label,
            style: TextStyle(
              fontSize: context.dp(10),
              fontWeight: FontWeight.w800,
              letterSpacing: context.dp(10) * 0.02,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }

  /// `.dg-info` — gap 11, radius 14, padding 13px 14px, copy 12.5/600/lh 1.45.
  Widget _buildInfoBanner(BuildContext context, DugnadClubThemePalette theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.dp(14),
        vertical: context.dp(13),
      ),
      decoration: BoxDecoration(
        color: const Color(0x1AE86657),
        borderRadius: BorderRadius.circular(context.dp(14)),
        border: Border.all(color: const Color(0x57E86657)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: context.dp(1)),
            child: Icon(
              Icons.info_outline_rounded,
              color: theme.primary,
              size: context.dp(18),
            ),
          ),
          SizedBox(width: context.dp(11)),
          Expanded(
            child: Text(
              languages.dugnadModeSwitchHint,
              style: TextStyle(
                fontSize: context.dp(12.5),
                fontWeight: FontWeight.w600,
                height: 1.45,
                color: ReenPreClubTokens.textSubtitle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
