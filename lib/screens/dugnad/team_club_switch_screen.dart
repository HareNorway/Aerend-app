import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/design_scale.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/utils.dart';
import 'club_crest.dart';
import 'dugnad_club_branding.dart';
import 'dugnad_club_theme.dart';
import 'dugnad_models.dart';
import 'dugnad_repo.dart';
import 'dugnad_state.dart';
import 'widgets/dugnad_subpage_shell.dart';

/// Prototype: `SwitchScreen` in dugnad/gamify-cards.jsx.
///
/// Steps: pickclub → pickteam → confirm.
enum _SwitchStep { pickclub, pickteam, confirm }

/// Full-screen "Bytt lag eller klubb" flow from profile.
class TeamClubSwitchScreen extends StatefulWidget {
  const TeamClubSwitchScreen({super.key});

  @override
  State<TeamClubSwitchScreen> createState() => _TeamClubSwitchScreenState();
}

class _TeamClubSwitchScreenState extends State<TeamClubSwitchScreen> {
  final DugnadRepo _repo = DugnadRepo();

  _SwitchStep _step = _SwitchStep.pickclub;
  List<ClubListItem> _clubs = [];
  List<ClubTeamItem> _teams = [];
  ClubListItem? _clubTarget;
  ClubTeamItem? _teamTarget;
  bool _loadingClubs = true;
  bool _loadingTeams = false;
  bool _saving = false;
  String? _error;

  ClubListItem? get _currentClub {
    final ds = DugnadState.instance;
    if (!ds.hasClub) return null;
    return ClubListItem(
      id: ds.clubId,
      name: ds.clubName,
      shortName: ds.clubShortName.isEmpty ? null : ds.clubShortName,
      logo: ds.clubLogo.isEmpty ? null : ds.clubLogo,
      area: ds.clubArea.isEmpty ? null : ds.clubArea,
      portalThemeColor: ds.clubPortalThemeColor.isEmpty
          ? null
          : ds.clubPortalThemeColor,
      portalBackgroundColor: ds.clubPortalBackgroundColor.isEmpty
          ? null
          : ds.clubPortalBackgroundColor,
    );
  }

  String get _currentTeamName {
    final name = DugnadState.instance.pointsTeamName.trim();
    return name.isEmpty ? languages.dugnadYourTeamFallback : name;
  }

  String get _targetShort {
    final c = _clubTarget;
    if (c == null) return DugnadClubBranding.compactName();
    final short = c.shortName?.trim();
    if (short != null && short.isNotEmpty) return short;
    return c.name;
  }

  bool get _crossClub {
    final cur = _currentClub;
    final tgt = _clubTarget;
    return cur != null && tgt != null && cur.id != tgt.id;
  }

  @override
  void initState() {
    super.initState();
    _clubTarget = _currentClub;
    _loadClubs();
  }

  Future<void> _loadClubs() async {
    setState(() {
      _loadingClubs = true;
      _error = null;
    });
    try {
      final response = await _repo.listClubs();
      final list = <ClubListItem>[];
      if (response is Map && response['status'] == 1) {
        final raw = response['clubs'];
        if (raw is List) {
          for (final e in raw) {
            if (e is Map) {
              list.add(ClubListItem.fromJson(Map<String, dynamic>.from(e)));
            }
          }
        }
      }
      final current = _currentClub;
      // Current club first, then the rest (design: clubList).
      final ordered = <ClubListItem>[];
      if (current != null) {
        ordered.add(current);
        for (final c in list) {
          if (c.id != current.id) ordered.add(c);
        }
      } else {
        ordered.addAll(list);
      }
      if (!mounted) return;
      setState(() {
        _clubs = ordered;
        _loadingClubs = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingClubs = false;
        _error = languages.dugnadPointsTeamSaveFailed;
      });
    }
  }

  Future<void> _loadTeamsFor(ClubListItem club) async {
    setState(() {
      _loadingTeams = true;
      _teams = [];
      _error = null;
    });
    try {
      final teams = await _repo.listTeams(club.id);
      if (!mounted) return;
      setState(() {
        _teams = teams;
        _loadingTeams = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingTeams = false;
        _error = languages.dugnadPointsTeamSaveFailed;
      });
    }
  }

  void _pickClub(ClubListItem club) {
    HapticFeedback.lightImpact();
    setState(() {
      _clubTarget = club;
      _teamTarget = null;
      _step = _SwitchStep.pickteam;
    });
    _loadTeamsFor(club);
  }

  void _pickTeam(ClubTeamItem team) {
    HapticFeedback.lightImpact();
    setState(() {
      _teamTarget = team;
      _step = _SwitchStep.confirm;
    });
  }

  void _onBack() {
    switch (_step) {
      case _SwitchStep.pickclub:
        Navigator.pop(context);
      case _SwitchStep.pickteam:
        setState(() => _step = _SwitchStep.pickclub);
      case _SwitchStep.confirm:
        setState(() => _step = _SwitchStep.pickteam);
    }
  }

  Future<void> _confirmSwitch() async {
    final team = _teamTarget;
    final club = _clubTarget;
    if (team == null || club == null || _saving) return;
    if (!isLoggedIn()) {
      setState(() => _error = languages.dugnadPointsTeamLoginRequired);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_crossClub) {
        await DugnadState.instance.selectClub(club);
      }
      final profile = await _repo.setPointsTeam(
        teamId: team.id,
        clubId: club.id,
      );
      if (profile != null) {
        await DugnadState.instance.applyPointsTeamProfile(profile);
        if (mounted) {
          openSimpleSnackbar(languages.dugnadSwitchConfirmedToast);
          Navigator.pop(context, true);
        }
        return;
      }
      if (mounted) {
        setState(() {
          _saving = false;
          _error = languages.dugnadPointsTeamSaveFailed;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = languages.dugnadPointsTeamSaveFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final clubName = DugnadClubBranding.fullName();
    final clubLogo = DugnadState.instance.clubLogo.isEmpty
        ? null
        : DugnadState.instance.clubLogo;

    return DugnadFixedTypography(
      child: Scaffold(
        backgroundColor: theme.primary,
        body: Stack(
          children: [
            DugnadLbScrollBody(
              itemGap: context.dp(14),
              bottomPadding: context.dp(120),
              hero: DugnadLbHero(
                clubName: clubName,
                clubLogo: clubLogo,
                title: languages.dugnadChangeTeamOrClub,
                subtitle: languages.dugnadSwitchAnytimeSubtitle,
                subtitleWithClock: true,
                onBack: _onBack,
              ),
              children: [
                ..._buildStepBody(theme),
                if (_error != null)
                  Text(
                    _error!,
                    style: aeCaption(color: ScSaasThemeTokens.danger),
                  ),
              ],
            ),
            if (_saving)
              const Align(
                alignment: Alignment.bottomCenter,
                child: LinearProgressIndicator(minHeight: 2),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStepBody(DugnadClubThemePalette theme) {
    switch (_step) {
      case _SwitchStep.pickclub:
        return [
          _SectionLabel(languages.dugnadChooseClub),
          if (_loadingClubs)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            _buildClubList(theme),
          _SwitchInfoBanner(theme: theme),
        ];
      case _SwitchStep.pickteam:
        return [
          _SectionLabel(
            languages.dugnadTransferPickTeamLabel(_targetShort),
          ),
          if (_loadingTeams)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            _buildTeamList(theme),
          _SwitchInfoBanner(theme: theme),
        ];
      case _SwitchStep.confirm:
        return [
          _ConfirmCard(
            fromName: _currentTeamName,
            toName: _teamTarget?.name ?? languages.dugnadTransferNewTeam,
            question: languages.dugnadSwitchConfirmTitle(
              _teamTarget?.name ?? languages.dugnadTransferNewTeam,
              _crossClub ? ' i $_targetShort' : '',
            ),
            body: languages.dugnadSwitchConfirmBody,
            theme: theme,
          ),
          _SwitchInfoBanner(theme: theme),
          _PrimaryButton(
            label: languages.dugnadSwitchConfirmBtn,
            onTap: _saving ? null : _confirmSwitch,
            theme: theme,
          ),
          _SecondaryButton(
            label: languages.dugnadTransferBack,
            onTap: () => setState(() => _step = _SwitchStep.pickteam),
          ),
        ];
    }
  }

  Widget _buildClubList(DugnadClubThemePalette theme) {
    final currentId = _currentClub?.id;
    return Column(
      children: [
        for (var i = 0; i < _clubs.length; i++) ...[
          if (i > 0) SizedBox(height: context.dp(10)),
          _PickRow(
            leading: ClubCrest(
              name: _clubs[i].name,
              logoUrl: _clubs[i].logo,
              size: context.dp(26),
            ),
            title: _clubs[i].name,
            meta: currentId != null && _clubs[i].id == currentId
                ? languages.dugnadCareerRoleCurrent
                : (_clubs[i].area?.trim().isNotEmpty == true
                    ? _clubs[i].area!
                    : 'Bergen'),
            selected: _clubTarget?.id == _clubs[i].id,
            onTap: () => _pickClub(_clubs[i]),
            theme: theme,
          ),
        ],
      ],
    );
  }

  Widget _buildTeamList(DugnadClubThemePalette theme) {
    final myTeamId = DugnadState.instance.pointsTeamId;
    return Column(
      children: [
        for (var i = 0; i < _teams.length; i++) ...[
          if (i > 0) SizedBox(height: context.dp(10)),
          _PickRow(
            leading: Icon(
              Icons.shield_outlined,
              color: theme.primaryHover,
              size: context.dp(20),
            ),
            title: _teams[i].name,
            meta: (!_crossClub && _teams[i].id == myTeamId)
                ? languages.dugnadYourTeamNow
                : _targetShort,
            selected: _teamTarget?.id == _teams[i].id,
            onTap: () => _pickTeam(_teams[i]),
            theme: theme,
          ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: context.dp(11),
        fontWeight: FontWeight.w800,
        letterSpacing: context.dp(11) * 0.08,
        color: ScSaasThemeTokens.gray500,
      ),
    );
  }
}

/// `.lb-pickrow` — club crest or shield + name/meta + chevron.
class _PickRow extends StatelessWidget {
  const _PickRow({
    required this.leading,
    required this.title,
    required this.meta,
    required this.selected,
    required this.onTap,
    required this.theme,
  });

  final Widget leading;
  final String title;
  final String meta;
  final bool selected;
  final VoidCallback onTap;
  final DugnadClubThemePalette theme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: BorderRadius.circular(context.dp(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(context.dp(15)),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.dp(14),
            vertical: context.dp(12),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.dp(15)),
            border: Border.all(
              color: selected ? theme.primary : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.text.withValues(alpha: 0.05),
                blurRadius: context.dp(3),
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: context.dp(46),
                height: context.dp(46),
                decoration: BoxDecoration(
                  color: theme.primaryTint,
                  borderRadius: BorderRadius.circular(context.dp(13)),
                ),
                alignment: Alignment.center,
                clipBehavior: Clip.antiAlias,
                child: leading,
              ),
              SizedBox(width: context.dp(13)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: context.dp(15.5),
                        fontWeight: FontWeight.w800,
                        letterSpacing: context.dp(15.5) * -0.01,
                        color: theme.text,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: context.dp(3)),
                    Text(
                      meta,
                      style: TextStyle(
                        fontSize: context.dp(11.5),
                        fontWeight: FontWeight.w600,
                        color: ScSaasThemeTokens.gray500,
                        height: 1.25,
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

/// `.dg-moveup-card` — from → to confirm visual.
class _ConfirmCard extends StatelessWidget {
  const _ConfirmCard({
    required this.fromName,
    required this.toName,
    required this.question,
    required this.body,
    required this.theme,
  });

  final String fromName;
  final String toName;
  final String question;
  final String body;
  final DugnadClubThemePalette theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.dp(18),
        vertical: context.dp(20),
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFBFAFF), Color(0xFFF0ECFB)],
        ),
        borderRadius: BorderRadius.circular(context.dp(20)),
        border: Border.all(color: theme.primaryTint, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TeamCrestLabel(
                name: fromName,
                filled: false,
                theme: theme,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.dp(12)),
                child: Icon(
                  Icons.north_east_rounded,
                  size: context.dp(22),
                  color: theme.primary.withValues(alpha: 0.75),
                ),
              ),
              _TeamCrestLabel(
                name: toName,
                filled: true,
                theme: theme,
              ),
            ],
          ),
          SizedBox(height: context.dp(16)),
          Text(
            question,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.dp(18),
              fontWeight: FontWeight.w900,
              letterSpacing: context.dp(18) * -0.02,
              color: theme.text,
              height: 1.25,
            ),
          ),
          SizedBox(height: context.dp(6)),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.dp(13),
              fontWeight: FontWeight.w600,
              color: ScSaasThemeTokens.gray500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamCrestLabel extends StatelessWidget {
  const _TeamCrestLabel({
    required this.name,
    required this.filled,
    required this.theme,
  });

  final String name;
  final bool filled;
  final DugnadClubThemePalette theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: context.dp(46),
          height: context.dp(46),
          decoration: BoxDecoration(
            color: filled ? theme.primary : Colors.white,
            borderRadius: BorderRadius.circular(context.dp(14)),
            boxShadow: [
              BoxShadow(
                color: theme.text.withValues(alpha: 0.08),
                blurRadius: context.dp(8),
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.shield_outlined,
            size: context.dp(20),
            color: filled ? Colors.white : theme.primary,
          ),
        ),
        SizedBox(height: context.dp(7)),
        Text(
          name,
          style: TextStyle(
            fontSize: context.dp(13),
            fontWeight: FontWeight.w800,
            color: filled ? theme.text : ScSaasThemeTokens.gray500,
          ),
        ),
      ],
    );
  }
}

class _SwitchInfoBanner extends StatelessWidget {
  const _SwitchInfoBanner({required this.theme});

  final DugnadClubThemePalette theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.dp(14),
        vertical: context.dp(12),
      ),
      decoration: BoxDecoration(
        color: theme.primaryTint,
        borderRadius: BorderRadius.circular(context.dp(14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: context.dp(1)),
            child: Icon(
              Icons.shield_outlined,
              size: context.dp(15),
              color: theme.primaryHover,
            ),
          ),
          SizedBox(width: context.dp(10)),
          Expanded(
            child: Text(
              languages.dugnadSwitchTeamInfo,
              style: TextStyle(
                fontSize: context.dp(12.5),
                fontWeight: FontWeight.w700,
                height: 1.45,
                color: theme.primaryHover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onTap,
    required this.theme,
  });

  final String label;
  final VoidCallback? onTap;
  final DugnadClubThemePalette theme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.primary,
      borderRadius: BorderRadius.circular(context.dp(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.dp(14)),
        child: SizedBox(
          height: context.dp(52),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_rounded, color: Colors.white, size: context.dp(18)),
              SizedBox(width: context.dp(8)),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.dp(15),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(context.dp(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.dp(14)),
        child: Container(
          height: context.dp(52),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.dp(14)),
            border: Border.all(color: ScSaasThemeTokens.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: context.dugnadTheme.text,
              fontSize: context.dp(15),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool?> openTeamClubSwitch(BuildContext context) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => const TeamClubSwitchScreen()),
  );
}
