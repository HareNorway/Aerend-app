import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/design_scale.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/utils.dart';
import '../../ui/kit/ae_club_crest.dart';
import 'dugnad_models.dart';
import 'dugnad_repo.dart';
import 'dugnad_state.dart';
import '../../ui/kit/ae_theme.dart';
import '../../ui/kit/ae_sheet.dart';

/// Bottom sheet to pick the user's single points-team for a club.
///
/// Returns the chosen [ClubTeamItem] after persisting to the backend,
/// or null if dismissed / skipped.
Future<ClubTeamItem?> showPointsTeamSheet(
  BuildContext context, {
  required int clubId,
  ClubTeamItem? currentTeam,
  bool requiredSelection = false,
}) {
  return showModalBottomSheet<ClubTeamItem>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    isDismissible: !requiredSelection,
    enableDrag: !requiredSelection,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(context.dp(24))),
    ),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.85,
    ),
    builder: (_) => _PointsTeamSheetBody(
      clubId: clubId,
      currentTeam: currentTeam,
      requiredSelection: requiredSelection,
    ),
  );
}

class _PointsTeamSheetBody extends StatefulWidget {
  final int clubId;
  final ClubTeamItem? currentTeam;
  final bool requiredSelection;

  const _PointsTeamSheetBody({
    required this.clubId,
    this.currentTeam,
    this.requiredSelection = false,
  });

  @override
  State<_PointsTeamSheetBody> createState() => _PointsTeamSheetBodyState();
}

class _PointsTeamSheetBodyState extends State<_PointsTeamSheetBody> {
  final DugnadRepo _repo = DugnadRepo();
  List<ClubTeamItem> _teams = [];
  ClubTeamItem? _selected;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    aeSheetOpenHaptic();
    _selected = widget.currentTeam;
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    try {
      _teams = await _repo.listTeams(widget.clubId);
    } catch (_) {}
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _confirmSelection() async {
    final team = _selected;
    if (team == null || _saving) return;
    aeSheetSaveHaptic();

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
        clubId: widget.clubId,
      );
      if (profile != null) {
        await DugnadState.instance.applyPointsTeamProfile(profile);
        if (mounted) Navigator.pop(context, team);
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: context.dp(40),
              height: context.dp(4),
              decoration: BoxDecoration(
                color: ScSaasThemeTokens.gray300,
                borderRadius: BorderRadius.circular(context.dp(2)),
              ),
            ),
          ),
          SizedBox(height: context.dp(16)),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(languages.dugnadPointsTeamTitle, style: aeH2()),
                    SizedBox(height: context.dp(4)),
                    Text(
                      languages.dugnadPointsTeamSubtitle,
                      style: aeCaption(color: ScSaasThemeTokens.gray500),
                    ),
                  ],
                ),
              ),
              if (!widget.requiredSelection)
                GestureDetector(
                  onTap: () {
                    aeSheetCloseHaptic();
                    Navigator.pop(context);
                  },
                  child: Icon(Icons.close_rounded,
                      color: ScSaasThemeTokens.gray500, size: context.dp(22)),
                ),
            ],
          ),
          SizedBox(height: context.dp(16)),
          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(
                      color: context.aeTheme.primary,
                    ),
                  )
                : _teams.isEmpty
                    ? Center(
                        child: Text(
                          languages.dugnadPointsTeamEmpty,
                          textAlign: TextAlign.center,
                          style: aeBody(color: ScSaasThemeTokens.gray500),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _teams.length,
                        separatorBuilder: (_, __) => Divider(
                          height: context.dp(1),
                          color: ScSaasThemeTokens.gray100,
                        ),
                        itemBuilder: (context, index) {
                          final team = _teams[index];
                          final isSelected = _selected?.id == team.id;
                          return InkWell(
                            onTap: _saving
                                ? null
                                : () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _selected = team);
                                  },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 4,
                              ),
                              child: Row(
                                children: [
                                  AeClubCrest(
                                    name: team.name,
                                    logoUrl: team.logoUrl,
                                    size: context.dp(44),
                                  ),
                                  SizedBox(width: context.dp(14)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(team.name, style: aeTitle()),
                                        if (team.displaySubtitle.isNotEmpty)
                                          Text(
                                            team.displaySubtitle,
                                            style: aeCaption(),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked_rounded
                                        : Icons.radio_button_off_rounded,
                                    color: isSelected
                                        ? context.aeTheme.primary
                                        : ScSaasThemeTokens.gray300,
                                    size: context.dp(22),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          if (_error != null) ...[
            SizedBox(height: context.dp(8)),
            Text(
              _error!,
              style: aeCaption(color: ScSaasThemeTokens.danger),
            ),
          ],
          SizedBox(height: context.dp(12)),
          GestureDetector(
            onTap: _selected != null && !_saving ? _confirmSelection : null,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: context.dp(16)),
              decoration: BoxDecoration(
                color: _selected != null && !_saving
                    ? context.aeTheme.primary
                    : context.aeTheme.primaryDisabled,
                borderRadius: BorderRadius.circular(context.dp(14)),
                boxShadow: _selected != null && !_saving
                    ? ScSaasThemeTokens.shadowButton
                    : null,
              ),
              child: Center(
                child: _saving
                    ? SizedBox(
                        width: context.dp(22),
                        height: context.dp(22),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        languages.dugnadPointsTeamConfirm,
                        style: aeLabel(color: Colors.white),
                      ),
              ),
            ),
          ),
          if (!widget.requiredSelection) ...[
            SizedBox(height: context.dp(8)),
            Center(
              child: GestureDetector(
                onTap: _saving
                    ? null
                    : () {
                        aeSheetCloseHaptic();
                        Navigator.pop(context);
                      },
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: context.dp(8)),
                  child: Text(
                    languages.dugnadPointsTeamSkip,
                    style: aeCaption(color: context.aeTheme.primary)
                        .copyWith(decoration: TextDecoration.underline),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
