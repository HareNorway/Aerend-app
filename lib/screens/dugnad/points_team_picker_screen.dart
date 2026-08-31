import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/design_scale.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/utils.dart';
import 'dugnad_club_branding.dart';
import '../../ui/kit/ae_theme.dart';
import 'dugnad_models.dart';
import 'dugnad_repo.dart';
import 'dugnad_state.dart';
import '../../ui/kit/ae_rise_in.dart';
import '../../ui/kit/ae_subpage_shell.dart';

/// How the picker presents itself.
///
/// * [select] — TeamPickerScreen (`Velg ditt lag`) from leaderboard / first connect.
/// * [switchTeam] — SwitchScreen pickteam (`Change team in Club`) from profile.
enum PointsTeamPickerMode { select, switchTeam }

/// Full-screen team picker.
///
/// Design: `TeamPickerScreen` / `SwitchScreen` pickteam in dugnad prototypes.
class PointsTeamPickerScreen extends StatefulWidget {
  const PointsTeamPickerScreen({
    super.key,
    this.mode,
  });

  /// Nullable so hot reload of an in-memory route never crashes when the field
  /// was added after the widget was first constructed.
  final PointsTeamPickerMode? mode;

  PointsTeamPickerMode get resolvedMode =>
      mode ?? PointsTeamPickerMode.select;

  @override
  State<PointsTeamPickerScreen> createState() => _PointsTeamPickerScreenState();
}

class _TeamPickerRow {
  const _TeamPickerRow({
    required this.team,
    required this.rank,
    required this.activeFamilies,
  });

  final ClubTeamItem team;
  final int rank;
  final int activeFamilies;
}

class _PointsTeamPickerScreenState extends State<PointsTeamPickerScreen> {
  final DugnadRepo _repo = DugnadRepo();
  final TextEditingController _search = TextEditingController();
  List<_TeamPickerRow> _rows = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  /// First paint of the loaded team list. Rows only stagger in inside this
  /// window so that typing in the search box never replays the entrance.
  DateTime? _contentShownAt;

  /// Rows that fit the first screenful — never stagger past this.
  static const int _staggerCount = 6;

  bool get _isSwitch =>
      widget.resolvedMode == PointsTeamPickerMode.switchTeam;

  bool get _inEntranceWindow {
    final shown = _contentShownAt;
    if (shown == null) return false;
    return DateTime.now().difference(shown) <
        const Duration(milliseconds: 1200);
  }

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final clubId = DugnadState.instance.clubId;
    final teams = await _repo.listTeams(clubId);
    final board = await _repo.getLeaderboard(clubId);
    final rankById = <int, LeaderboardTeamRow>{};
    if (board != null) {
      for (final row in board.teams) {
        rankById[row.teamId] = row;
      }
    }
    if (!mounted) return;
    setState(() {
      _rows = teams
          .map(
            (t) => _TeamPickerRow(
              team: t,
              rank: rankById[t.id]?.rank ?? 0,
              activeFamilies: rankById[t.id]?.activeFamilies ?? 0,
            ),
          )
          .toList();
      _loading = false;
      _contentShownAt ??= DateTime.now();
    });
  }

  List<_TeamPickerRow> get _filtered {
    if (_isSwitch) return _rows;
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _rows;
    return _rows
        .where((r) => r.team.name.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _pickTeam(ClubTeamItem team) async {
    if (_saving) return;
    HapticFeedback.lightImpact();
    if (!isLoggedIn()) {
      setState(() => _error = languages.dugnadPointsTeamLoginRequired);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final profile = await _repo.setPointsTeam(
        teamId: team.id,
        clubId: DugnadState.instance.clubId,
      );
      if (profile != null) {
        await DugnadState.instance.applyPointsTeamProfile(profile);
        if (mounted) Navigator.pop(context, true);
        return;
      }
      if (mounted) {
        setState(() {
          _error = languages.dugnadPointsTeamSaveFailed;
          _saving = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = languages.dugnadPointsTeamSaveFailed;
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clubName = DugnadClubBranding.fullName();
    final clubShort = DugnadClubBranding.compactName();
    final clubLogo = DugnadState.instance.clubLogo.isEmpty
        ? null
        : DugnadState.instance.clubLogo;
    final selectedId = DugnadState.instance.pointsTeamId;
    final theme = context.aeTheme;

    final title = _isSwitch
        ? languages.dugnadChangeTeamOrClub
        : languages.dugnadPickTeamTitle;
    final subtitle = _isSwitch
        ? languages.dugnadSwitchAnytimeSubtitle
        : languages.dugnadPickTeamSubtitle(clubName);

    return AeFixedTypography(
      child: Scaffold(
        backgroundColor: theme.primary,
        body: Stack(
          children: [
            AeScrollBody(
              // `.lb-feed { gap: 14 }` — list itself owns the 10px row gap.
              itemGap: context.dp(14),
              hero: AeHero(
                clubName: clubName,
                clubLogo: clubLogo,
                title: title,
                subtitle: subtitle,
                subtitleWithClock: _isSwitch,
                onBack: () => Navigator.pop(context),
              ),
              bottomPadding: context.dp(_isSwitch ? 120 : 24),
              children: [
                if (!_isSwitch) ...[
                  AeRiseIn(
                    key: const ValueKey('teamPickerSearch'),
                    delay: const Duration(milliseconds: 120),
                    child: _buildSearch(),
                  ),
                ] else
                  Text(
                    languages.dugnadTransferPickTeamLabel(clubShort),
                    style: TextStyle(
                      // `.dg-label`
                      fontSize: context.dp(11),
                      fontWeight: FontWeight.w800,
                      letterSpacing: context.dp(11) * 0.08,
                      color: ScSaasThemeTokens.gray500,
                    ),
                  ),
                if (_loading)
                  Padding(
                    padding: EdgeInsets.all(context.dp(32)),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: theme.primary,
                      ),
                    ),
                  )
                else if (_filtered.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: context.dp(24)),
                    child: Text(
                      languages.dugnadPickTeamEmpty(_search.text.trim()),
                      textAlign: TextAlign.center,
                      style: aeBody(color: ScSaasThemeTokens.gray500),
                    ),
                  )
                else
                  _buildTeamList(selectedId, clubShort, theme),
                if (_error != null)
                  Text(
                    _error!,
                    style: aeCaption(color: ScSaasThemeTokens.danger),
                  ),
                if (_isSwitch)
                  _SwitchInfoBanner(theme: theme)
                else
                  AeRiseIn(
                    key: const ValueKey('teamPickerNote'),
                    delay: const Duration(milliseconds: 610),
                    duration: const Duration(milliseconds: 550),
                    child: Text(
                      languages.dugnadPickTeamNote,
                      style: aeCaption(color: ScSaasThemeTokens.gray500)
                          .copyWith(height: 1.45),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
            if (_saving)
              Align(
                alignment: Alignment.bottomCenter,
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: theme.primary,
                  backgroundColor: theme.primaryTint,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// `.lb-list { gap: 10 }` — one column, no extra feed gap between rows.
  Widget _buildTeamList(
    int selectedId,
    String clubShort,
    AeThemePalette theme,
  ) {
    final rows = _filtered;
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) SizedBox(height: context.dp(10)),
          Builder(
            builder: (context) {
              final row = _buildTeamRow(rows[i], selectedId, clubShort, theme);
              if (i >= _staggerCount || !_inEntranceWindow) return row;
              return AeRiseIn(
                key: ValueKey('teamPickerRow-${rows[i].team.id}'),
                delay: Duration(milliseconds: 190 + i * 70),
                child: row,
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSearch() {
    // `.lb-search { padding: 13px 15px; border-radius: 14px }`
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.dp(15),
        vertical: context.dp(13),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.dp(14)),
        boxShadow: [
          BoxShadow(
            color: context.aeTheme.text.withValues(alpha: 0.05),
            blurRadius: context.dp(2),
            offset: Offset(0, context.dp(1)),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: context.dp(18),
            color: ScSaasThemeTokens.gray500,
          ),
          SizedBox(width: context.dp(10)),
          Expanded(
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: languages.dugnadPickTeamSearch,
                hintStyle: aeBody(color: ScSaasThemeTokens.gray500).copyWith(
                  fontSize: context.dp(14),
                  height: 1.2,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: aeBody().copyWith(fontSize: context.dp(14), height: 1.2),
            ),
          ),
          if (_search.text.isNotEmpty)
            GestureDetector(
              onTap: () => _search.clear(),
              child: Icon(
                Icons.close_rounded,
                size: context.dp(18),
                color: ScSaasThemeTokens.gray500,
              ),
            ),
        ],
      ),
    );
  }

  /// `.lb-pickrow` — 46×46 shield tile, 15.5/800 name, 11.5/600 meta.
  Widget _buildTeamRow(
    _TeamPickerRow row,
    int selectedId,
    String clubShort,
    AeThemePalette theme,
  ) {
    final isSelected = row.team.id == selectedId;
    final meta = _isSwitch
        ? (isSelected ? languages.dugnadYourTeamNow : clubShort)
        : (row.rank > 0
            ? languages.dugnadPickTeamMeta(row.activeFamilies, row.rank)
            : languages.dugnadLeaderboardActiveFamilies(row.activeFamilies));

    return Material(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: BorderRadius.circular(context.dp(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(context.dp(15)),
        onTap: _saving ? null : () => _pickTeam(row.team),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.dp(14),
            vertical: context.dp(12),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.dp(15)),
            border: Border.all(
              color: isSelected && !_isSwitch
                  ? theme.primary
                  : Colors.transparent,
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
                child: Icon(
                  Icons.shield_outlined,
                  color: theme.primaryHover,
                  size: context.dp(20),
                ),
              ),
              SizedBox(width: context.dp(13)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.team.name,
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
              SizedBox(width: context.dp(8)),
              if (isSelected && !_isSwitch)
                Container(
                  width: context.dp(28),
                  height: context.dp(28),
                  decoration: BoxDecoration(
                    color: theme.primary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: context.dp(15),
                  ),
                )
              else
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

/// `.dg-transfer-info` — STØ follow-you note under the team list.
class _SwitchInfoBanner extends StatelessWidget {
  const _SwitchInfoBanner({required this.theme});

  final AeThemePalette theme;

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

Future<bool?> openPointsTeamPicker(
  BuildContext context, {
  PointsTeamPickerMode mode = PointsTeamPickerMode.select,
}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => PointsTeamPickerScreen(mode: mode),
    ),
  );
}
