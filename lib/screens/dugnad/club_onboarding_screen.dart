import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/design_scale.dart';
import '../../theme/reen_pre_club_theme.dart';
import '../../utils/global_loading_overlay.dart';
import '../../utils/utils.dart';
import '../common/homeMainV1/home_main_v1.dart';
import 'dugnad_celebration_orchestrator.dart';
import 'dugnad_welcome_screen.dart';
import 'club_crest.dart';
import 'club_sheet.dart';
import 'dugnad_models.dart';
import 'dugnad_state.dart';
import 'dugnad_club_theme.dart';
import 'widgets/dugnad_points_pop.dart';
// Mode select temporarily skipped — back goes to Login.
// import 'mode_select_screen.dart';
import '../common/login/login.dart';
import 'widgets/dugnad_rise_in.dart';
import 'widgets/dugnad_subpage_shell.dart';

/// Onboarding is always `.reen-pre` — do not use [BuildContext.dugnadTheme]
/// here; browse/no-club mode overrides that to the light feed palette.
final DugnadClubThemePalette _onbTheme = DugnadClubThemePalette.reenPreClub;

/// Club onboarding: pick a club, then continue.
///
/// Points team is chosen later (leaderboard / profile), not during onboarding.
/// The 30-pt welcome bonus is credited as soon as a club is chosen.
class ClubOnboardingScreen extends StatefulWidget {
  const ClubOnboardingScreen({super.key});

  @override
  State<ClubOnboardingScreen> createState() => _ClubOnboardingScreenState();
}

class _ClubOnboardingScreenState extends State<ClubOnboardingScreen> {
  ClubListItem? _selectedClub;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    DugnadCelebrationOrchestrator.instance.holdCriticalFlow();
  }

  @override
  void dispose() {
    DugnadCelebrationOrchestrator.instance.releaseCriticalFlow();
    super.dispose();
  }

  void _finish() {
    if (_finishing) return;
    HapticFeedback.lightImpact();
    unawaited(_finishAndNavigate());
  }

  Future<void> _finishAndNavigate() async {
    _finishing = true;
    final showWelcome = prefGetBool(prefShowDugnadWelcomeAfterOnboarding);
    var awardedPoints = 0;

    final clubId = _selectedClub?.id ??
        (DugnadState.instance.hasClub ? DugnadState.instance.clubId : 0);
    if (clubId > 0) {
      awardedPoints = await withGlobalLoadingOverlay(
        () => DugnadState.instance.claimOnboardingWelcomeBonus(clubId: clubId),
      );
    }

    final referralJoinPoints = prefGetInt(prefDugnadReferralJoinPoints);

    await prefSetBool(prefShowDugnadWelcomeAfterOnboarding, false);
    await prefSetInt(prefDugnadWelcomeBonusPoints, awardedPoints);
    if (showWelcome && referralJoinPoints > 0) {
      await prefSetInt(prefDugnadReferralJoinPoints, 0);
    }

    if (!mounted) return;

    if (showWelcome) {
      openScreenWithClearPrevious(
        context,
        DugnadWelcomeScreen(
          welcomeBonusPoints: awardedPoints > 0 ? awardedPoints : 30,
          bonusAwarded: awardedPoints > 0,
          referralJoinPoints: referralJoinPoints,
        ),
      );
      return;
    }

    openScreenWithClearPrevious(
      context,
      const HomeMainV1(isShowDialog: true),
    );
    if (referralJoinPoints > 0) {
      DugnadPointsPop.award(
        referralJoinPoints,
        reason: DugnadPointsPopReasons.referralJoin(context),
      );
      await prefSetInt(prefDugnadReferralJoinPoints, 0);
    }
  }

  void _goBack() {
    HapticFeedback.lightImpact();
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
    } else {
      // ModeSelectScreen skipped — return to Login.
      openScreenWithClearPrevious(context, const Login());
    }
  }

  Future<void> _openClubSheet() async {
    HapticFeedback.lightImpact();
    final club = await showClubSheet(
      context,
      currentClub: _selectedClub,
      useReenPreClubStyle: true,
    );
    if (club != null && mounted) {
      await DugnadState.instance.selectClub(club);
      setState(() => _selectedClub = club);
    }
  }

  String _clubMeta(ClubListItem club) {
    final parts = <String>[];
    if (club.area != null && club.area!.isNotEmpty) {
      parts.add(club.area!);
    }
    if (club.sponsorStoreCount > 0) {
      parts.add(languages.dugnadStoreCount(club.sponsorStoreCount));
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    // Keep Reen for the whole onboarding flow — even after [selectClub] so the
    // picker/confirmation stay coral-navy until the user lands on Home.
    // Colors use [_onbTheme] directly — not [context.dugnadTheme], which
    // resolves to the light browse palette when no club is selected yet.
    return DugnadClubThemeScope(
      palette: DugnadClubThemePalette.reenPreClub,
      child: Builder(builder: _buildPreClubScaffold),
    );
  }

  Widget _buildPreClubScaffold(BuildContext context) {
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goBack();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: _onbTheme.background,
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: ReenPreClubTokens.screenGradient,
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // `.dg-onb` fills the frame and `.dg-onb-body` is `flex: 1`, so
                  // the foot group's `margin-top: auto` can push it down. Use
                  // minHeight (never a fixed height) so short devices scroll
                  // instead of overflowing.
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Padding(
                            // .dg-onb { padding: 8px 20px 8px }
                            padding: EdgeInsets.fromLTRB(context.dp(20), context.dp(8), context.dp(20), context.dp(8)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              // The single `margin-top: auto` on the foot group.
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // .dg-onb-steps { margin: 10px 0 24px }
                                    SizedBox(height: context.dp(10)),
                                    const _OnbStepsIndicator(),
                                    SizedBox(height: context.dp(24)),
                                    // `.dg-onb-body > *` staggers each child
                                    // individually, not the block as a whole.
                                    _buildClubStep(),
                                  ],
                                ),
                                // inline: margin-top auto; padding-top 18; gap 12
                                Padding(
                                  padding: EdgeInsets.only(top: context.dp(18)),
                                  child: _onbRise(3, _buildClubFoot()),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // `.dg-onb-back { position: absolute; top: 6; left: 12 }`
                  Positioned(
                    top: 6,
                    left: 12,
                    child: DugnadLbBackButton(
                      onPressed: _goBack,
                      solidWhite: true,
                      forceDarkSurface: true,
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

  /// `@keyframes dg-onb-rise` — .5s cubic-bezier(.22,1,.36,1), starting at
  /// opacity .4 and 12px down (tighter than the login stagger's 0 / 16px).
  /// Delays run .04 / .10 / .16 / .22s across `.dg-onb-body`'s children.
  static const List<int> _onbDelaysMs = [40, 100, 160, 220];

  Widget _onbRise(int index, Widget child) {
    return DugnadRiseIn(
      // The prototype replays this on every step change via its `key="s1"`
      // remount. This screen implements a single step, so mounting the screen
      // is the step entry — a stable key per child is equivalent here.
      key: ValueKey('onb-rise-$index'),
      delay: Duration(milliseconds: _onbDelaysMs[index]),
      duration: const Duration(milliseconds: 500),
      offsetY: 12,
      beginOpacity: 0.4,
      child: child,
    );
  }

  /// `.dg-onb-body` above the foot group — head, club picker, `.dg-info`.
  Widget _buildClubStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _onbRise(
          0,
          _OnbHead(
            icon: const _OnbHeartIcon(),
            title: languages.dugnadChooseYourClub,
            subtitle: languages.dugnadChooseClubOnboardSubtitle,
          ),
        ),
        _onbRise(
          1,
          _selectedClub != null
              ? _OnbPickedClub(
                  club: _selectedClub!,
                  meta: _clubMeta(_selectedClub!),
                  onTap: _openClubSheet,
                )
              : _OnbChooseClub(onTap: _openClubSheet),
        ),
        // .dg-info { margin-top: 16 }
        SizedBox(height: context.dp(16)),
        _onbRise(2, _OnbInfoBox(text: languages.dugnadClubChangeAnytime)),
      ],
    );
  }

  /// The bottom-pinned group — `margin-top: auto; padding-top: 18; gap: 12`.
  Widget _buildClubFoot() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OnbPrimaryButton(
          label: languages.continueTxt,
          enabled: _selectedClub != null,
          onTap: _selectedClub != null ? _finish : null,
          trailingIcon: Icons.arrow_forward_rounded,
        ),
        SizedBox(height: context.dp(12)),
        _OnbSkipLink(
          label: languages.dugnadBrowseWithoutClub,
          onTap: _finish,
        ),
      ],
    );
  }
}

// ── Shared onboarding widgets (dg-onb-* from dugnad.css) ───────────────

/// `.dg-onb-back` — 38px white circle, `:active { transform: scale(.94) }`
/// over `.12s ease`.
class _OnbStepsIndicator extends StatelessWidget {
  const _OnbStepsIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: context.dp(28),
          height: context.dp(5),
          decoration: BoxDecoration(
            color: ReenPreClubTokens.coral,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );
  }
}

class _OnbHead extends StatelessWidget {
  final Widget icon;
  final String title;
  final String subtitle;

  const _OnbHead({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.dp(22)),
      child: Column(
        children: [
          icon,
          SizedBox(height: context.dp(14)),
          // .dg-onb-head h1 { font-size: 23px } — not the 26px auth h1.
          Text(
            title,
            textAlign: TextAlign.center,
            // Prototype heading tracking is -0.02em (aeH2 base is -0.015em).
            style: aeH2(color: ReenPreClubTokens.ink).copyWith(
              fontSize: context.dp(23),
              letterSpacing: context.dp(23) * -0.02,
            ),
          ),
          SizedBox(height: context.dp(8)),
          // .dg-onb-head p { font-size: 14; line-height: 1.5; font-weight: 500;
          // max-width: 32ch }
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: context.dp(286)),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: aeBody(color: ReenPreClubTokens.textSubtitle).copyWith(
                  fontSize: context.dp(14),
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnbHeartIcon extends StatelessWidget {
  const _OnbHeartIcon();

  @override
  Widget build(BuildContext context) {
    // Design `.dg-onb-ic` under `.reen-pre` — coral shiny plate (not Ærend purple).
    return Container(
      width: context.dp(58),
      height: context.dp(58),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.dp(17)),
        gradient: ReenPreClubTokens.shinyCoral,
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A081424),
            blurRadius: context.dp(2),
            offset: Offset(0, context.dp(1)),
          ),
          BoxShadow(
            color: ReenPreClubTokens.coral.withValues(alpha: 0.55),
            blurRadius: context.dp(18),
            offset: Offset(0, context.dp(6)),
            spreadRadius: context.dp(-8),
          ),
        ],
      ),
      child: Icon(
        Icons.favorite_rounded,
        color: Colors.white,
        size: context.dp(26),
      ),
    );
  }
}

class _OnbChooseClub extends StatelessWidget {
  final VoidCallback onTap;

  const _OnbChooseClub({required this.onTap});

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
            borderRadius: BorderRadius.circular(context.dp(16)),
            border: Border.all(color: ReenPreClubTokens.glassBorder, width: context.dp(1.5)),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x1AFFFFFF), Color(0x09FFFFFF)],
            ),
            boxShadow: [
              // CSS rest state: 0 2px 4px (dugnad.css .dg-onb-choose). Colour
              // unchanged; geometry only.
              BoxShadow(
                color: const Color(0x59081424),
                blurRadius: context.dp(4),
                offset: Offset(0, context.dp(2)),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: context.dp(44),
                height: context.dp(44),
                decoration: BoxDecoration(
                  color: const Color(0x26FFFFFF),
                  borderRadius: BorderRadius.circular(context.dp(12)),
                ),
                child: Icon(
                  Icons.search_rounded,
                  color: ReenPreClubTokens.textSoft,
                  size: context.dp(19),
                ),
              ),
              SizedBox(width: context.dp(12)),
              Expanded(
                child: Text(
                  '${languages.dugnadSearchForClub}…',
                  style: aeBody(color: ReenPreClubTokens.textSoft).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: ReenPreClubTokens.glassBorder,
                size: context.dp(18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnbPickedClub extends StatelessWidget {
  final ClubListItem club;
  final String meta;
  final VoidCallback onTap;

  const _OnbPickedClub({
    required this.club,
    required this.meta,
    required this.onTap,
  });

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
            borderRadius: BorderRadius.circular(context.dp(16)),
            // Design `.reen-pre .dg-onb-picked` — opaque navy glass so the
            // drop glow never bleeds through the face (CSS glass composited
            // on navy: white@.105 → white@.035).
            border: Border.all(
              color: ReenPreClubTokens.glassBorder,
              width: context.dp(1),
            ),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2E4661), Color(0xFF1E3755)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.16),
                blurRadius: 0,
                offset: Offset(0, context.dp(1)),
                blurStyle: BlurStyle.inner,
              ),
              BoxShadow(
                color: const Color(0x59081424),
                blurRadius: context.dp(3),
                offset: Offset(0, context.dp(2)),
              ),
              BoxShadow(
                color: const Color(0x99081424),
                blurRadius: context.dp(26),
                offset: Offset(0, context.dp(14)),
                spreadRadius: context.dp(-10),
              ),
            ],
          ),
          child: Row(
            children: [
              ClubCrest(name: club.name, logoUrl: club.logo, size: context.dp(46)),
              SizedBox(width: context.dp(13)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      club.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      // Prototype picked-name tracking is -0.01em (aeTitle base
                      // is -0.005em).
                      style: aeTitleMd(color: Colors.white).copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: context.dp(AeFontSize.titleMd) * -0.01,
                      ),
                    ),
                    if (meta.isNotEmpty) ...[
                      SizedBox(height: context.dp(2)),
                      Text(
                        meta,
                        style: aeCaptionSm(color: ReenPreClubTokens.textSoft)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: context.dp(13), vertical: context.dp(7)),
                decoration: BoxDecoration(
                  color: const Color(0x26FFFFFF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  languages.dugnadChangeClub,
                  style: aeCaption(color: ReenPreClubTokens.coralHover).copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnbInfoBox extends StatelessWidget {
  final String text;

  const _OnbInfoBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(context.dp(14), context.dp(13), context.dp(14), context.dp(13)),
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
              Icons.refresh_rounded,
              size: context.dp(17),
              color: ReenPreClubTokens.coral,
            ),
          ),
          SizedBox(width: context.dp(11)),
          Expanded(
            child: Text(
              text,
              style: aeCaption(color: ReenPreClubTokens.textSubtitle).copyWith(
                fontSize: context.dp(12.5),
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnbPrimaryButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback? onTap;
  final IconData? trailingIcon;

  const _OnbPrimaryButton({
    required this.label,
    this.enabled = true,
    this.onTap,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(context.dp(14)),
        child: Ink(
          height: context.dp(52),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.dp(14)),
            gradient: enabled ? _onbTheme.shinyGradient : null,
            color:
                enabled ? null : _onbTheme.primaryDisabled.withValues(alpha: 0.55),
            boxShadow: enabled ? _onbTheme.shadowButton : null,
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: aeLabel(color: Colors.white).copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (trailingIcon != null) ...[
                  SizedBox(width: context.dp(8)),
                  Icon(trailingIcon, color: Colors.white, size: context.dp(18)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnbSkipLink extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _OnbSkipLink({
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: ReenPreClubTokens.textSoft,
          padding: EdgeInsets.symmetric(horizontal: context.dp(8), vertical: context.dp(6)),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: context.dp(13.5),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

TextStyle aeCaptionSm({Color? color}) => aeCaption(color: color).copyWith(
      fontSize: AeFontSize.captionSm,
    );

TextStyle aeTitleMd({Color? color}) => aeTitle(color: color).copyWith(
      fontSize: AeFontSize.titleMd,
    );
