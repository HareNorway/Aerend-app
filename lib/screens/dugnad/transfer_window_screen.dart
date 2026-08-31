import 'package:flutter/material.dart';

import '../../theme/design_scale.dart';
import 'package:flutter/services.dart';

import '../../commonView/skeleton_loaders/dugnad_subpage_skeletons.dart';
import '../../services/dugnad_data_cache.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/utils.dart';
import 'club_sheet.dart';
import 'dugnad_models.dart';
import 'dugnad_repo.dart';
import 'dugnad_state.dart';
import 'career_screen.dart';
import 'gamification_models.dart';
import 'points_team_picker_screen.dart';
import 'transfer_window_models.dart';
import 'widgets/dugnad_hourglass.dart';
import 'widgets/dugnad_subpage_shell.dart';
import 'dugnad_club_theme.dart';
import 'widgets/dugnad_rise_in.dart';

enum _TransferStep { home, moveUp, stay, teamSwitch }

/// Transfer window — prototype: `TransferScreen` in gamify-cards.jsx + gamify-plus.css.
class TransferWindowScreen extends StatefulWidget {
  const TransferWindowScreen({super.key});

  @override
  State<TransferWindowScreen> createState() => _TransferWindowScreenState();
}

class _TransferWindowScreenState extends State<TransferWindowScreen> {
  final DugnadRepo _repo = DugnadRepo();
  final DugnadDataCache _cache = DugnadDataCache.instance;

  TransferWindowContext? _context;
  _TransferStep _step = _TransferStep.home;
  ClubTeamItem? _teamTarget;
  bool _loading = true;
  bool _committing = false;
  bool _animateIn = true;

  @override
  void initState() {
    super.initState();
    _seedFromCache();
    _load();
  }

  void _seedFromCache() {
    final clubId = DugnadState.instance.clubId;
    final cached = _cache.peek<TransferWindowContext>(
      DugnadDataCache.transferWindowKey(clubId),
    );
    final seeded = cached ?? _placeholderFromLocalState();
    if (seeded == null) return;
    _context = seeded;
    _loading = false;
    // Cached paint should not wait on rise-in delays.
    _animateIn = cached == null;
  }

  /// Instant first paint from config + selected team — the dedicated
  /// `/transfer/window` call only refines options and club teams.
  TransferWindowContext? _placeholderFromLocalState() {
    final ds = DugnadState.instance;
    if (!ds.hasClub) return null;
    final config = _cache.peek<GamificationConfig>(
      DugnadDataCache.gamificationConfigKey(ds.clubId),
    );
    if (config == null) return null;
    final tw = config.modules?.transferWindow;
    final featureOn = config.isEnabled('transfer_window_enabled');
    final enabled = featureOn && (tw?.enabled ?? false);
    final now = DateTime.now();
    final opens = _parseWindowDate(tw?.opensAt);
    final closes = _parseWindowDate(tw?.closesAt);
    var windowOpen = enabled;
    if (opens != null && now.isBefore(opens)) windowOpen = false;
    if (closes != null && now.isAfter(closes)) windowOpen = false;
    int? daysRemaining;
    if (closes != null) {
      daysRemaining = closes.difference(now).inDays.clamp(0, 3650);
    }
    return TransferWindowContext(
      enabled: enabled,
      windowOpen: windowOpen,
      daysRemaining: daysRemaining,
      autoPromoteEnabled: tw?.autoPromoteEnabled ?? false,
      club: TransferClubInfo(
        id: ds.clubId,
        name: ds.clubName,
        shortName: ds.clubShortName.isEmpty ? null : ds.clubShortName,
      ),
      currentTeam: ds.hasPointsTeam
          ? ClubTeamItem(
              id: ds.pointsTeamId,
              name: ds.pointsTeamName,
              ageGroup: ds.pointsTeamAgeGroup.isEmpty
                  ? null
                  : ds.pointsTeamAgeGroup,
            )
          : null,
      options: TransferOptions(
        moveUp: windowOpen && (tw?.autoPromoteEnabled ?? false) && ds.hasPointsTeam,
        stay: windowOpen && ds.hasPointsTeam,
        teamSwitch: windowOpen,
        clubChange: windowOpen,
      ),
    );
  }

  DateTime? _parseWindowDate(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  Future<void> _load() async {
    final wasEmpty = _context == null;
    final ctx = await _cache.getTransferWindow();
    if (!mounted) return;
    setState(() {
      if (ctx != null) _context = ctx;
      _loading = false;
      if (!wasEmpty) _animateIn = false;
    });
  }

  void _goBack() {
    if (_step == _TransferStep.home) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _step = _TransferStep.home;
      _teamTarget = null;
    });
  }

  String _deadlineTitle() {
    final days = _context?.daysRemaining;
    if (days != null && days > 0) {
      return languages.dugnadTransferWindowClosesTitle(days);
    }
    return languages.dugnadTransferWindowClosesSoon;
  }

  Future<void> _commit(String action, {int? teamId}) async {
    if (_committing) return;
    HapticFeedback.mediumImpact();
    setState(() => _committing = true);
    final result = await _repo.commitTransfer(action: action, teamId: teamId);
    if (!mounted) return;
    setState(() => _committing = false);

    if (result == null) {
      openSimpleSnackbar(languages.dugnadTransferCommitFailed);
      return;
    }

    if (result.points != null) {
      await DugnadState.instance.applyPointsTeamProfile(result.points!);
    }
    _cache.invalidate(
      DugnadDataCache.transferWindowKey(DugnadState.instance.clubId),
    );

    final teamName = result.teamName ?? _context?.currentTeamName ?? '';
    final message = switch (action) {
      'move_up' => languages.dugnadTransferSuccessMoveUp(teamName),
      'stay' => languages.dugnadTransferSuccessStay(teamName),
      'team_switch' => languages.dugnadTransferSuccessTeamSwitch(teamName),
      _ => languages.dugnadTransferCommitSuccess,
    };

    openSimpleSnackbar(message);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _changeClub() async {
    final ds = DugnadState.instance;
    final club = await showClubSheet(
      context,
      title: languages.dugnadTransferPickClubLabel,
      currentClub: ds.hasClub
          ? ClubListItem(
              id: ds.clubId,
              name: ds.clubName,
              shortName: ds.clubShortName.isEmpty ? null : ds.clubShortName,
              logo: ds.clubLogo.isEmpty ? null : ds.clubLogo,
              area: ds.clubArea.isEmpty ? null : ds.clubArea,
              portalThemeColor:
                  ds.clubPortalThemeColor.isEmpty ? null : ds.clubPortalThemeColor,
              portalBackgroundColor: ds.clubPortalBackgroundColor.isEmpty
                  ? null
                  : ds.clubPortalBackgroundColor,
            )
          : null,
    );
    if (club == null || !mounted) return;
    await DugnadState.instance.selectClub(club);
    if (!mounted) return;
    await openPointsTeamPicker(context);
    if (!mounted) return;
    openSimpleSnackbar(languages.dugnadTransferClubChanged(club.name));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;

    // Same shell as Lagkonkurranse / sesong-recap / karriere.
    return DugnadFixedTypography(
      child: Scaffold(
        backgroundColor: theme.primary,
        body: DugnadLbScrollBody(
          hero: _TransferHero(
            title: languages.dugnadTransitionWindowTitle,
            deadlineTitle: _deadlineTitle(),
            deadlineSub: languages.dugnadTransferWindowDeadlineSub,
            onBack: _goBack,
          ),
          bottomPadding: 40,
          itemGap: 0,
          topPadding: 18,
          feedRadius: 22,
          overlap: 12,
          children: [
            if (_loading)
              const DugnadTransferWindowSkeleton()
            else
              _buildStepContent(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(DugnadClubThemePalette theme) {
    final ctx = _context;
    if (ctx == null) {
      return _enter(
        0,
        Text(
          languages.dugnadTransferLoadFailed,
          style: aeBody(color: ScSaasThemeTokens.gray500),
        ),
      );
    }

    if (!ctx.enabled) {
      return _enter(
        0,
        Text(
          languages.dugnadTransferWindowDisabled,
          style: aeBody(color: ScSaasThemeTokens.gray500),
        ),
      );
    }

    if (!ctx.windowOpen) {
      return _enter(
        0,
        Text(
          languages.dugnadTransferWindowClosed,
          style: aeBody(color: ScSaasThemeTokens.gray500),
        ),
      );
    }

    return switch (_step) {
      _TransferStep.home => _buildHome(ctx, theme),
      _TransferStep.moveUp => _buildMoveUpConfirm(ctx, theme),
      _TransferStep.stay => _buildStayConfirm(ctx, theme),
      _TransferStep.teamSwitch => _buildTeamSwitch(ctx, theme),
    };
  }

  Widget _buildHome(TransferWindowContext ctx, DugnadClubThemePalette theme) {
    final current = ctx.currentTeamName;
    final next = _nextTeamLabel(ctx);

    // Option order + icons match TransferScreen (gamify-cards.jsx).
    // Icon fills use club theme (primary / soft / text) — not hard-coded brand purple.
    const gap = 14.0;
    var i = 0;
    final children = <Widget>[
      _enter(
        i++,
        _TransferSectionLabel(languages.dugnadTransferNextSeasonLabel),
      ),
    ];

    void addOption(Widget card) {
      if (children.length > 1) {
        children.add(SizedBox(height: context.dp(gap)));
      }
      children.add(_enter(i++, card));
    }

    // Always show Rykk opp. Grey it out when API has no next promotion team.
    final moveUpReady = ctx.options.moveUp || ctx.promotion.nextTeam != null;
    final moveUpSub = current.isEmpty
        ? languages.dugnadTransferMoveUpUnavailable
        : (moveUpReady
            ? languages.dugnadTransferMoveUpSub(current, next)
            : languages.dugnadTransferMoveUpUnavailable);
    addOption(
      _TransferOptionCard(
        icon: Icons.north_east_rounded,
        iconBackground: moveUpReady
            ? ScSaasThemeTokens.success
            : ScSaasThemeTokens.gray300,
        title: languages.dugnadTransferMoveUpTitle,
        subtitle: moveUpSub,
        recommended: moveUpReady,
        enabled: moveUpReady,
        onTap: moveUpReady
            ? () => setState(() => _step = _TransferStep.moveUp)
            : () => openSimpleSnackbar(languages.dugnadTransferMoveUpUnavailable),
      ),
    );
    if (ctx.options.stay) {
      addOption(
        _TransferOptionCard(
          // Lucide `shield`
          icon: Icons.shield_outlined,
          // `.stay .ic` → purple-400 role → club primaryDisabled
          iconBackground: theme.primaryDisabled,
          title: languages.dugnadTransferStayTitle,
          subtitle: languages.dugnadTransferStaySub(current),
          onTap: () => setState(() => _step = _TransferStep.stay),
        ),
      );
    }
    if (ctx.options.teamSwitch) {
      addOption(
        _TransferOptionCard(
          // Lucide `refresh` (open arc) — not autorenew’s full loop
          icon: Icons.refresh_rounded,
          // `.teamswitch .ic` → midnight → club text
          iconBackground: theme.text,
          title: languages.dugnadTransferTeamSwitchTitle,
          subtitle: languages.dugnadTransferTeamSwitchSub(ctx.clubShortName),
          onTap: () => setState(() => _step = _TransferStep.teamSwitch),
        ),
      );
    }
    if (ctx.options.clubChange) {
      addOption(
        _TransferOptionCard(
          // Proper flask (Material science) — mockup boot glyph was unusable.
          icon: Icons.science_outlined,
          // `.switch .ic` → purple-600 → club primary
          iconBackground: theme.primary,
          title: languages.dugnadTransferClubChangeTitle,
          subtitle: languages.dugnadTransferClubChangeSub,
          onTap: _changeClub,
        ),
      );
    }
    addOption(
      _TransferOptionCard(
        // Lucide `clock`
        icon: Icons.access_time_rounded,
        iconBackground: ScSaasThemeTokens.gray400,
        title: languages.dugnadTransferNotNowTitle,
        subtitle: languages.dugnadTransferNotNowSub,
        onTap: _chooseLater,
      ),
    );

    children.add(SizedBox(height: context.dp(gap)));
    children.add(
      _enter(i++, _TransferInfoBox(text: languages.dugnadTransferInfo, theme: theme)),
    );
    children.add(SizedBox(height: context.dp(gap)));
    children.add(
      _TransferExtraNote(text: languages.dugnadTransferExtra, theme: theme),
    );
    children.add(SizedBox(height: context.dp(gap)));
    children.add(
      _TransferCareerEntry(
        title: languages.dugnadCareerTitle,
        subtitle: languages.dugnadCareerSub,
        onTap: _openCareer,
        theme: theme,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  void _chooseLater() {
    openSimpleSnackbar(languages.dugnadTransferChooseLater);
    Navigator.of(context).pop();
  }

  void _openCareer() {
    openScreen(context, const CareerScreen());
  }

  Widget _buildMoveUpConfirm(TransferWindowContext ctx, DugnadClubThemePalette theme) {
    final current = ctx.currentTeamName;
    final next = _nextTeamLabel(ctx);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MoveUpCard(
          current: current,
          next: next,
          question: languages.dugnadTransferMoveUpConfirmTitle(current, next),
          body: languages.dugnadTransferMoveUpConfirmBody,
          theme: theme,
        ),
        SizedBox(height: context.dp(14)),
        _TransferInfoBox(
          text: languages.dugnadTransferInfo,
          theme: theme,
        ),
        SizedBox(height: context.dp(14)),
        _TransferPrimaryButton(
          label: languages.dugnadTransferMoveUpConfirmBtn(next),
          leading: Icons.check_rounded,
          loading: _committing,
          onPressed: () {
            if (!ctx.options.moveUp) {
              openSimpleSnackbar(languages.dugnadTransferMoveUpUnavailable);
              return;
            }
            _commit('move_up');
          },
          theme: theme,
        ),
        SizedBox(height: context.dp(10)),
        // Mockup secondary on move-up is "Ikke nå" (back to home), not "Tilbake".
        _TransferSecondaryButton(
          label: languages.dugnadTransferNotNowTitle,
          onPressed: _goBack,
          ink: theme.text,
        ),
      ],
    );
  }

  Widget _buildStayConfirm(TransferWindowContext ctx, DugnadClubThemePalette theme) {
    final current = ctx.currentTeamName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MoveUpCard(
          current: current,
          next: current,
          question: languages.dugnadTransferStayConfirmTitle(current),
          body: languages.dugnadTransferStayConfirmBody(current),
          theme: theme,
          stayMode: true,
        ),
        SizedBox(height: context.dp(14)),
        _TransferInfoBox(text: languages.dugnadTransferInfo, theme: theme),
        SizedBox(height: context.dp(14)),
        _TransferPrimaryButton(
          label: languages.dugnadTransferStayConfirmBtn(current),
          leading: Icons.check_rounded,
          loading: _committing,
          onPressed: () => _commit('stay'),
          theme: theme,
        ),
        SizedBox(height: context.dp(10)),
        _TransferSecondaryButton(
          label: languages.dugnadTransferBack,
          onPressed: _goBack,
        ),
      ],
    );
  }

  Widget _buildTeamSwitch(TransferWindowContext ctx, DugnadClubThemePalette theme) {
    if (ctx.clubTeams.isEmpty) {
      return const DugnadTransferWindowSkeleton();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TransferSectionLabel(
          languages.dugnadTransferPickTeamLabel(ctx.clubShortName),
        ),
        ...ctx.clubTeams.map((team) {
          final selected = _teamTarget?.id == team.id;
          return Padding(
            padding: EdgeInsets.only(bottom: context.dp(10)),
            child: _TeamPickRow(
              team: team,
              clubName: ctx.clubShortName,
              selected: selected,
              onTap: () => setState(() => _teamTarget = team),
              theme: theme,
            ),
          );
        }),
        SizedBox(height: context.dp(4)),
        _TransferInfoBox(text: languages.dugnadTransferInfo, theme: theme),
        SizedBox(height: context.dp(14)),
        _TransferPrimaryButton(
          label: languages.dugnadTransferFollowTeamBtn(
            _teamTarget?.name ?? languages.dugnadTransferNewTeam,
          ),
          leading: Icons.check_rounded,
          loading: _committing,
          onPressed: _teamTarget == null
              ? null
              : () => _commit('team_switch', teamId: _teamTarget!.id),
          theme: theme,
        ),
        SizedBox(height: context.dp(10)),
        _TransferSecondaryButton(
          label: languages.dugnadTransferBack,
          onPressed: _goBack,
        ),
      ],
    );
  }

  String _incrementTeamName(String name) {
    final match = RegExp(r'(\d+)').firstMatch(name);
    if (match == null) return name;
    final n = int.tryParse(match.group(1) ?? '') ?? 0;
    return name.replaceFirst(match.group(0)!, '${n + 1}');
  }

  /// Prefer API next team → promotion to_label → bumped name → bumped age.
  String _nextTeamLabel(TransferWindowContext ctx) {
    if (ctx.nextTeamName.isNotEmpty) return ctx.nextTeamName;
    final to = ctx.promotion.toLabel?.trim() ?? '';
    if (to.isNotEmpty) return to;
    final name = ctx.currentTeamName;
    final bumpedName = _incrementTeamName(name);
    if (bumpedName != name) return bumpedName;
    final age = ctx.currentTeam?.ageGroup?.trim() ?? '';
    if (age.isNotEmpty) {
      final bumpedAge = _incrementTeamName(age);
      if (bumpedAge != age) return bumpedAge;
    }
    return name;
  }

  Widget _enter(int index, Widget child) =>
      _riseIn(index, child, animate: _animateIn);
}

class _TransferHero extends StatelessWidget {
  const _TransferHero({
    required this.title,
    required this.deadlineTitle,
    required this.deadlineSub,
    required this.onBack,
  });

  final String title;
  final String deadlineTitle;
  final String deadlineSub;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;

    return Container(
      width: double.infinity,
      color: theme.primary,
      padding: EdgeInsets.fromLTRB(
        context.dp(18),
        MediaQuery.paddingOf(context).top + context.dp(6),
        context.dp(18),
        context.dp(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              DugnadLbBackButton(onPressed: onBack),
              Expanded(
                child: Text(
                  title,
                  style: AeDugnadText.pageHeroOrg(color: Colors.white).dp(context),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: context.dp(38)),
            ],
          ),
          SizedBox(height: context.dp(12)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: context.dp(14), vertical: context.dp(12)),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(context.dp(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: context.dp(42),
                  height: context.dp(42),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(context.dp(12)),
                  ),
                  alignment: Alignment.center,
                  child: DugnadHourglass(size: context.dp(22), color: Colors.white),
                ),
                SizedBox(width: context.dp(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deadlineTitle,
                        style: aeLabel(color: Colors.white).copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 14.5,
                          letterSpacing: 14.5 * -0.01,
                        ),
                      ),
                      SizedBox(height: context.dp(2)),
                      Text(
                        deadlineSub,
                        style: aeCaption(color: Colors.white.withValues(alpha: 0.9))
                            .copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransferSectionLabel extends StatelessWidget {
  const _TransferSectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(context.dp(2), context.dp(0), context.dp(2), context.dp(10)),
      child: Text(
        text.toUpperCase(),
        style: aeCaption(color: ScSaasThemeTokens.gray500).copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 0.08 * 11,
        ),
      ),
    );
  }
}

class _TransferOptionCard extends StatelessWidget {
  const _TransferOptionCard({
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.recommended = false,
    this.enabled = true,
  });

  final IconData icon;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool recommended;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final titleColor = enabled ? theme.text : ScSaasThemeTokens.gray500;
    final subColor = enabled
        ? ScSaasThemeTokens.gray500
        : ScSaasThemeTokens.gray400;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(context.dp(18)),
          child: Ink(
            decoration: BoxDecoration(
              color: enabled ? Colors.white : const Color(0xFFF7F6FB),
              borderRadius: BorderRadius.circular(context.dp(18)),
              border: Border.all(
                color: ScSaasThemeTokens.gray100,
                width: 1.5,
              ),
              boxShadow: enabled ? ScSaasThemeTokens.shadowCard : null,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: context.dp(16),
              vertical: context.dp(15),
            ),
            child: Row(
              children: [
                Container(
                  width: context.dp(44),
                  height: context.dp(44),
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(context.dp(13)),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: Colors.white, size: context.dp(20)),
                ),
                SizedBox(width: context.dp(13)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: aeLabel(color: titleColor).copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 15.5,
                                letterSpacing: 15.5 * -0.01,
                              ),
                            ),
                          ),
                          if (recommended) ...[
                            SizedBox(width: context.dp(7)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: ScSaasThemeTokens.success
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                languages.dugnadTransferRecommended,
                                style: aeCaption(
                                  color: const Color(0xFF1F8A5B),
                                ).copyWith(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 9.5,
                                  letterSpacing: 9.5 * 0.04,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: context.dp(2)),
                      Text(
                        subtitle,
                        style: aeCaption(color: subColor).copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: context.dp(30),
                  height: context.dp(30),
                  decoration: BoxDecoration(
                    color: enabled
                        ? const Color(0xFFF7F6FB)
                        : ScSaasThemeTokens.gray100,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: context.dp(18),
                    color: ScSaasThemeTokens.gray500,
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

class _MoveUpCard extends StatelessWidget {
  const _MoveUpCard({
    required this.current,
    required this.next,
    required this.question,
    required this.body,
    required this.theme,
    this.stayMode = false,
  });

  final String current;
  final String next;
  final String question;
  final String body;
  final DugnadClubThemePalette theme;
  final bool stayMode;

  @override
  Widget build(BuildContext context) {
    // `.dg-moveup-card` — soft lilac ramp + purple-100 border (not club tint wash).
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.dp(18),
        context.dp(20),
        context.dp(18),
        context.dp(20),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: const Alignment(0.35, 1.1),
          colors: [
            Colors.white,
            theme.primaryTint.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(context.dp(20)),
        border: Border.all(
          color: theme.primaryTint,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TeamBubble(label: current, highlight: stayMode, theme: theme),
              if (!stayMode) ...[
                SizedBox(width: context.dp(12)),
                Icon(
                  Icons.north_east_rounded,
                  color: theme.primarySoft,
                  size: context.dp(22),
                ),
                SizedBox(width: context.dp(12)),
                _TeamBubble(label: next, highlight: true, theme: theme),
              ],
            ],
          ),
          SizedBox(height: context.dp(16)),
          Text(
            question,
            textAlign: TextAlign.center,
            style: aeLabel(color: theme.text).copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 18 * -0.02,
              height: 1.25,
            ),
          ),
          SizedBox(height: context.dp(6)),
          Text(
            body,
            textAlign: TextAlign.center,
            style: aeCaption(color: ScSaasThemeTokens.gray500).copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamBubble extends StatelessWidget {
  const _TeamBubble({
    required this.label,
    required this.highlight,
    required this.theme,
  });

  final String label;
  final bool highlight;
  final DugnadClubThemePalette theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: context.dp(46),
          height: context.dp(46),
          decoration: BoxDecoration(
            color: highlight ? theme.primary : Colors.white,
            borderRadius: BorderRadius.circular(context.dp(14)),
            boxShadow: ScSaasThemeTokens.shadowCard,
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.shield_outlined,
            size: context.dp(20),
            color: highlight ? Colors.white : theme.primary,
          ),
        ),
        SizedBox(height: context.dp(7)),
        SizedBox(
          width: context.dp(88),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: aeCaption(
              color: highlight ? theme.text : ScSaasThemeTokens.gray500,
            ).copyWith(fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _TransferInfoBox extends StatelessWidget {
  const _TransferInfoBox({required this.text, required this.theme});

  final String text;
  final DugnadClubThemePalette theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.dp(14), vertical: context.dp(12)),
      decoration: BoxDecoration(
        color: theme.primaryTint.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(context.dp(14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: context.dp(15), color: theme.primary),
          SizedBox(width: context.dp(10)),
          Expanded(
            child: Text(
              text,
              style: aeCaption(color: theme.primary).copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamPickRow extends StatelessWidget {
  const _TeamPickRow({
    required this.team,
    required this.clubName,
    required this.selected,
    required this.onTap,
    required this.theme,
  });

  final ClubTeamItem team;
  final String clubName;
  final bool selected;
  final VoidCallback onTap;
  final DugnadClubThemePalette theme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.dp(16)),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.dp(16)),
            border: Border.all(
              color: selected ? theme.primary : ScSaasThemeTokens.gray100,
              width: selected ? 2 : 1.5,
            ),
            boxShadow: ScSaasThemeTokens.shadowCard,
          ),
          padding: EdgeInsets.symmetric(horizontal: context.dp(14), vertical: context.dp(12)),
          child: Row(
            children: [
              Container(
                width: context.dp(40),
                height: context.dp(40),
                decoration: BoxDecoration(
                  color: theme.primaryTint.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(context.dp(12)),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.shield_outlined, color: theme.primary, size: context.dp(20)),
              ),
              SizedBox(width: context.dp(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      style: aeLabel(color: theme.text).copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      clubName,
                      style: aeCaption(color: ScSaasThemeTokens.gray500).copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Container(
                  width: context.dp(28),
                  height: context.dp(28),
                  decoration: BoxDecoration(
                    color: theme.primary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.check_rounded, color: Colors.white, size: context.dp(15)),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  size: context.dp(18),
                  color: ScSaasThemeTokens.gray500,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransferPrimaryButton extends StatelessWidget {
  const _TransferPrimaryButton({
    required this.label,
    required this.onPressed,
    required this.theme,
    this.leading,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final DugnadClubThemePalette theme;
  final IconData? leading;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(context.dp(16)),
        child: Ink(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: context.dp(14)),
          decoration: BoxDecoration(
            color: enabled
                ? theme.primary
                : theme.primary.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(context.dp(16)),
            boxShadow: enabled ? theme.shadowButton : null,
          ),
          child: loading
              ? SizedBox(
                  height: context.dp(20),
                  child: Center(
                    child: SizedBox(
                      width: context.dp(20),
                      height: context.dp(20),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (leading != null) ...[
                      Icon(leading, color: Colors.white, size: context.dp(18)),
                      SizedBox(width: context.dp(8)),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: aeLabel(color: Colors.white).copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
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

class _TransferSecondaryButton extends StatelessWidget {
  const _TransferSecondaryButton({
    required this.label,
    required this.onPressed,
    this.ink,
  });

  final String label;
  final VoidCallback onPressed;
  final Color? ink;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(context.dp(16)),
        child: Ink(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: context.dp(14)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.dp(16)),
            border: Border.all(color: ScSaasThemeTokens.gray100, width: 1.5),
            boxShadow: ScSaasThemeTokens.shadowCard,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: aeLabel(color: ink ?? ScSaasThemeTokens.gray500).copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

/// `.dg-transfer-extra` — star note below info box.
class _TransferExtraNote extends StatelessWidget {
  const _TransferExtraNote({required this.text, required this.theme});

  final String text;
  final DugnadClubThemePalette theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.dp(4)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.star_rounded, size: context.dp(14), color: theme.primary),
          SizedBox(width: context.dp(8)),
          Expanded(
            child: Text(
              text,
              style: aeCaption(color: ScSaasThemeTokens.gray500).copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `.dg-career-entry` — lighter card linking to career timeline.
class _TransferCareerEntry extends StatelessWidget {
  const _TransferCareerEntry({
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.theme,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final DugnadClubThemePalette theme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.dp(16)),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.dp(16)),
            border: Border.all(color: ScSaasThemeTokens.gray100, width: 1.5),
            boxShadow: ScSaasThemeTokens.shadowCard,
          ),
          padding: EdgeInsets.symmetric(horizontal: context.dp(14), vertical: context.dp(13)),
          child: Row(
            children: [
              Container(
                width: context.dp(40),
                height: context.dp(40),
                decoration: BoxDecoration(
                  color: theme.primaryTint,
                  borderRadius: BorderRadius.circular(context.dp(12)),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.flag_outlined,
                  size: context.dp(19),
                  color: theme.primaryHover,
                ),
              ),
              SizedBox(width: context.dp(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: aeLabel(color: theme.text).copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),
                    SizedBox(height: context.dp(1)),
                    Text(
                      subtitle,
                      style: aeCaption(color: ScSaasThemeTokens.gray500).copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: context.dp(18),
                color: ScSaasThemeTokens.gray300,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Canonical `au-rise` entrance cadence (dugnad.css / splash.css): the first
/// block rises at 120ms, then roughly 70ms apart; trailing blocks use the
/// 550ms duration and ~50ms spacing of the `.auth-bottom` group. Blocks past
/// the first screenful render immediately rather than animating out of view.
Widget _riseIn(int index, Widget child, {required bool animate}) {
  if (!animate || index > 6) return child;
  return DugnadRiseIn(
    delay: Duration(
      milliseconds: index < 4 ? 120 + index * 70 : 400 + (index - 4) * 50,
    ),
    duration: Duration(milliseconds: index < 4 ? 600 : 550),
    child: child,
  );
}
