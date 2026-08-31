import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../commonView/skeleton_loaders/dugnad_subpage_skeletons.dart';
import '../../theme/design_scale.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/utils.dart';
import 'club_crest.dart';
import 'dugnad_club_branding.dart';
import 'dugnad_models.dart';
import 'dugnad_repo.dart';
import 'dugnad_state.dart';
import 'widgets/dugnad_subpage_shell.dart';
import 'dugnad_club_theme.dart';
import 'widgets/dugnad_rise_in.dart';

/// Profile privacy controls — matches prototype `visibility.jsx`.
class DugnadPrivacyScreen extends StatefulWidget {
  const DugnadPrivacyScreen({super.key});

  @override
  State<DugnadPrivacyScreen> createState() => _DugnadPrivacyScreenState();
}

class _DugnadPrivacyScreenState extends State<DugnadPrivacyScreen> {
  final DugnadRepo _repo = DugnadRepo();
  final TextEditingController _nicknameController = TextEditingController();

  DugnadPrivacySettings? _settings;
  PointsSummary? _summary;
  LeaderboardScorerRow? _viewerScorer;
  bool _loading = true;
  bool _saving = false;
  String _selectedPref = 'initial';
  bool _isVisible = true;
  bool _previewAsMinor = false;
  Timer? _saveDebounce;

  static const _cardShadow = BoxShadow(
    color: Color(0x0D2D1B5B),
    blurRadius: 3,
    offset: Offset(0, 1),
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final settings = await _repo.getPrivacySettings();
    final summary = await _repo.getPointsSummary();
    LeaderboardScorerRow? viewerScorer;
    if (DugnadState.instance.hasClub) {
      final scorers = await _repo.getLeaderboardScorers(
        DugnadState.instance.clubId,
        tab: 'toppscorer',
      );
      if (scorers != null) {
        for (final row in scorers.scorers) {
          if (row.isViewer) {
            viewerScorer = row;
            break;
          }
        }
      }
    }
    if (!mounted) return;
    if (settings != null) {
      _applySettings(settings);
    }
    setState(() {
      _summary = summary;
      _viewerScorer = viewerScorer;
      _loading = false;
    });
  }

  void _applySettings(DugnadPrivacySettings settings) {
    _settings = settings;
    _selectedPref = _uiPref(settings.displayNamePref);
    _isVisible = settings.isVisible;
    _previewAsMinor = settings.isMinor;
    _nicknameController.text = settings.nickname ?? '';
  }

  String _uiPref(String backendPref) {
    switch (backendPref) {
      case 'full':
        return 'full';
      case 'nickname':
        return 'nick';
      case 'anonymous':
        return 'anon';
      case 'first_initial':
      default:
        return 'initial';
    }
  }

  String _backendPref(String uiPref) {
    switch (uiPref) {
      case 'full':
        return 'full';
      case 'nick':
        return 'nickname';
      case 'anon':
        return 'anonymous';
      case 'initial':
      default:
        return 'first_initial';
    }
  }

  bool get _effectiveMinor => _previewAsMinor || (_settings?.isMinor ?? false);

  List<_NameOption> get _nameOptions {
    const all = [
      _NameOption(id: 'full'),
      _NameOption(id: 'initial'),
      _NameOption(id: 'nick'),
      _NameOption(id: 'anon'),
    ];
    if (_effectiveMinor) {
      return all.where((o) => o.id != 'full').toList();
    }
    return all;
  }

  String _legalName() {
    final legal = _settings?.legalFullName.trim() ?? '';
    if (legal.isNotEmpty) return legal;
    return prefGetString(prefUserName);
  }

  String _initialName([String? full]) {
    final name = (full ?? _legalName()).trim();
    if (name.isEmpty) return '—';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts.first} ${parts.last[0]}.';
    }
    return name;
  }

  String _exampleFor(String prefId) {
    switch (prefId) {
      case 'full':
        return _legalName();
      case 'initial':
        return _initialName();
      case 'nick':
        final nick = _nicknameController.text.trim();
        return nick.isNotEmpty ? nick : '—';
      case 'anon':
        return languages.dugnadPrivacyPrefAnonymousEx;
      default:
        return '—';
    }
  }

  bool get _previewAnon =>
      !_isVisible || _selectedPref == 'anon';

  String _previewDisplayName() {
    if (_previewAnon) {
      return _settings?.anonymousLabel ?? languages.dugnadPrivacyPrefAnonymousEx;
    }
    if (_selectedPref == 'full') return _legalName();
    if (_selectedPref == 'nick') {
      final nick = _nicknameController.text.trim();
      return nick.isNotEmpty ? nick : _initialName();
    }
    return _initialName();
  }

  void _setPreviewMinor(bool minor) {
    HapticFeedback.lightImpact();
    final prev = _selectedPref;
    setState(() {
      _previewAsMinor = minor;
      if (minor && _selectedPref == 'full') {
        _selectedPref = 'anon';
      }
    });
    if (minor && prev == 'full') {
      _scheduleSave(immediate: true);
    }
  }

  void _selectPref(String prefId) {
    HapticFeedback.lightImpact();
    setState(() => _selectedPref = prefId);
    _scheduleSave(immediate: true);
  }

  void _setVisible(bool value) {
    HapticFeedback.mediumImpact();
    setState(() => _isVisible = value);
    _scheduleSave(immediate: true);
  }

  void _scheduleSave({bool immediate = false}) {
    _saveDebounce?.cancel();
    if (immediate) {
      _persist();
      return;
    }
    _saveDebounce = Timer(const Duration(milliseconds: 450), _persist);
  }

  Future<void> _persist() async {
    if (_saving || _settings == null) return;
    setState(() => _saving = true);
    try {
      final updated = await _repo.updatePrivacySettings(
        displayNamePref: _backendPref(_selectedPref),
        nickname: _nicknameController.text.trim(),
        isVisible: _isVisible,
      );
      if (!mounted) return;
      if (updated != null) {
        setState(() {
          _settings = updated;
          _selectedPref = _uiPref(updated.displayNamePref);
          _isVisible = updated.isVisible;
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DugnadFixedTypography(
      child: Scaffold(
        backgroundColor: context.dugnadTheme.background,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            Expanded(
              child: _loading
                  ? Padding(
                      padding: EdgeInsets.all(context.dp(18)),
                      child: DugnadPrivacySkeleton(),
                    )
                  : SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        18,
                        0,
                        18,
                        MediaQuery.paddingOf(context).bottom + 120,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DugnadRiseIn(
                            delay: const Duration(milliseconds: 120),
                            child: _buildIntro(),
                          ),
                          SizedBox(height: context.dp(14)),
                          DugnadRiseIn(
                            delay: const Duration(milliseconds: 190),
                            child: _buildPreviewAsToggle(),
                          ),
                          SizedBox(height: context.dp(14)),
                          DugnadRiseIn(
                            delay: const Duration(milliseconds: 260),
                            child: _buildDisplayNameSection(),
                          ),
                          SizedBox(height: context.dp(14)),
                          DugnadRiseIn(
                            delay: const Duration(milliseconds: 330),
                            child: _buildVisibilitySection(),
                          ),
                          SizedBox(height: context.dp(14)),
                          DugnadRiseIn(
                            delay: const Duration(milliseconds: 400),
                            duration: const Duration(milliseconds: 550),
                            child: _buildLeaderboardPreview(),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        18,
        MediaQuery.paddingOf(context).top + 8,
        18,
        6,
      ),
      child: Row(
        children: [
          DugnadLbBackButton(onPressed: () => Navigator.of(context).pop()),
          Expanded(
            child: Text(
              languages.dugnadVisibilityTitle,
              style: aeH2().copyWith(fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: context.dp(38)),
        ],
      ),
    );
  }

  Widget _buildIntro() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: context.dp(1)),
          child: Icon(
            Icons.shield_outlined,
            size: context.dp(17),
            color: context.dugnadTheme.primary,
          ),
        ),
        SizedBox(width: context.dp(10)),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: aeCaption(color: const Color(0xFF6B6478)).copyWith(
                fontWeight: FontWeight.w600,
                height: 1.45,
                fontSize: 12,
              ),
              children: [
                TextSpan(text: languages.dugnadPrivacyIntroPrefix),
                TextSpan(
                  text: languages.dugnadPrivacyIntroBold,
                  style: TextStyle(
                    color: context.dugnadTheme.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(text: languages.dugnadPrivacyIntroSuffix),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewAsToggle() {
    return CustomPaint(
      painter: _DashedRoundedBorderPainter(
        color: ScSaasThemeTokens.gray300,
        radius: 12,
        strokeWidth: 1.5,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: context.dp(12), vertical: context.dp(9)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.dp(12)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                languages.dugnadPrivacyPreviewAsLabel.toUpperCase(),
                style: aeCaption(color: const Color(0xFF9890A8)).copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.03 * 11,
                  fontSize: 11,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(context.dp(3)),
              decoration: BoxDecoration(
                color: ScSaasThemeTokens.gray100,
                borderRadius: BorderRadius.circular(context.dp(10)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PreviewSegButton(
                    label: languages.dugnadPrivacyPreviewAdult,
                    selected: !_previewAsMinor,
                    onTap: () => _setPreviewMinor(false),
                  ),
                  _PreviewSegButton(
                    label: languages.dugnadPrivacyPreviewMinor,
                    selected: _previewAsMinor,
                    onTap: () => _setPreviewMinor(true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplayNameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(context.dp(2), context.dp(2), context.dp(2), context.dp(10)),
          child: Text(
            languages.dugnadPrivacyDisplayTitle.toUpperCase(),
            style: _sectionLabelStyle(),
          ),
        ),
        if (_effectiveMinor) ...[
          _MinorBanner(
            onConsent: () =>
                openSimpleSnackbar(languages.dugnadPrivacyMinorConsentSoon),
          ),
          SizedBox(height: context.dp(11)),
        ],
        ..._nameOptions.expand((option) sync* {
          yield _NameOptionCard(
            option: option,
            title: _optionTitle(option.id),
            subtitle: _optionSubtitle(option.id),
            example: _exampleFor(option.id),
            selected: _selectedPref == option.id,
            onTap: () => _selectPref(option.id),
          );
          if (option.id == 'nick' && _selectedPref == 'nick') {
            yield Padding(
              padding: EdgeInsets.only(top: context.dp(9), bottom: context.dp(2)),
              child: TextField(
                controller: _nicknameController,
                maxLength: 40,
                onChanged: (_) {
                  setState(() {});
                  _scheduleSave();
                },
                style: aeBody().copyWith(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: languages.dugnadPrivacyNicknameHint,
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: context.dp(14), vertical: context.dp(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(context.dp(12)),
                    borderSide: const BorderSide(
                      color: Color(0xFFE4DFF0),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(context.dp(12)),
                    borderSide: BorderSide(
                      color: context.dugnadTheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            );
          }
          yield SizedBox(height: context.dp(9));
        }),
      ],
    );
  }

  String _optionTitle(String id) {
    switch (id) {
      case 'full':
        return languages.dugnadPrivacyPrefFull;
      case 'initial':
        return languages.dugnadPrivacyPrefInitial;
      case 'nick':
        return languages.dugnadPrivacyPrefNickname;
      case 'anon':
        return languages.dugnadPrivacyPrefAnonymous;
      default:
        return '';
    }
  }

  String _optionSubtitle(String id) {
    switch (id) {
      case 'full':
        return languages.dugnadPrivacyPrefFullSub;
      case 'initial':
        return languages.dugnadPrivacyPrefInitialSub;
      case 'nick':
        return languages.dugnadPrivacyPrefNicknameSub;
      case 'anon':
        return languages.dugnadPrivacyPrefAnonymousSub;
      default:
        return '';
    }
  }

  Widget _buildVisibilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(context.dp(2), context.dp(2), context.dp(2), context.dp(10)),
          child: Text(
            languages.dugnadPrivacyVisibleSection.toUpperCase(),
            style: _sectionLabelStyle(),
          ),
        ),
        Container(
          padding: EdgeInsets.all(context.dp(14)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.dp(14)),
            boxShadow: const [_cardShadow],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isVisible
                          ? languages.dugnadPrivacyVisibleOnTitle
                          : languages.dugnadPrivacyVisibleOffTitle,
                      style: aeBody().copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 11.5 * -0.01,
                      ),
                    ),
                    SizedBox(height: context.dp(2)),
                    Text(
                      languages.dugnadPrivacyVisibleNote,
                      style: aeCaption(color: ScSaasThemeTokens.gray500)
                          .copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.dp(13)),
              _DgSwitch(value: _isVisible, onChanged: _setVisible),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardPreview() {
    final scorer = _viewerScorer;
    final rank = scorer?.rank ?? 4;
    final goals = scorer?.goals ?? _summary?.actionCounts.campaignPurchases ?? 14;
    final tierKey = scorer?.tierKey ?? _summary?.currentTier?.key ?? 'helt';
    final teamName = scorer?.teamName.isNotEmpty == true
        ? scorer!.teamName
        : DugnadState.instance.pointsTeamName;
    final tierLabel = scorer?.tierTitle.isNotEmpty == true
        ? scorer!.tierTitle
        : DugnadClubBranding.tierTitle(tierKey);

    return Container(
      padding: EdgeInsets.all(context.dp(13)),
      decoration: BoxDecoration(
        color: context.dugnadTheme.background,
        borderRadius: BorderRadius.circular(context.dp(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(context.dp(2), context.dp(0), context.dp(2), context.dp(9)),
            child: Text(
              languages.dugnadPrivacyLeaderboardPreviewTitle.toUpperCase(),
              style: _sectionLabelStyle().copyWith(fontSize: 10, letterSpacing: 0.06 * 10),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(context.dp(13), context.dp(11), context.dp(13), context.dp(11)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(context.dp(15)),
              border: Border.all(color: context.dugnadTheme.primary, width: 1.5),
              boxShadow: [
                // `.scl-row.me` — rgba(127,95,196,.55); the app had .35.
                BoxShadow(
                  color: Color(0x8C7F5FC4),
                  blurRadius: context.dp(24),
                  offset: Offset(0, 10),
                  spreadRadius: -16,
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: context.dp(26),
                  child: Text(
                    '$rank',
                    textAlign: TextAlign.center,
                    style: aeTitle(color: ScSaasThemeTokens.gray500),
                  ),
                ),
                SizedBox(width: context.dp(11)),
                _PreviewScorerAvatar(
                  anon: _previewAnon,
                  clubName: DugnadClubBranding.compactName(),
                  clubLogo: DugnadState.instance.clubLogo,
                ),
                SizedBox(width: context.dp(11)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 7,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            _previewDisplayName(),
                            style: aeTitle().copyWith(fontSize: 14.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                          _YouTag(label: languages.dugnadLeaderboardYouTag),
                        ],
                      ),
                      SizedBox(height: context.dp(3)),
                      Row(
                        children: [
                          Container(
                            width: context.dp(7),
                            height: context.dp(7),
                            decoration: BoxDecoration(
                              color: _previewAnon
                                  ? ScSaasThemeTokens.gray300
                                  : _tierDotColor(tierKey),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: context.dp(6)),
                          Expanded(
                            child: Text(
                              _previewAnon
                                  ? languages.dugnadPrivacyHiddenMeta(teamName)
                                  : '$tierLabel · $teamName',
                              style: aeCaption(color: ScSaasThemeTokens.gray500)
                                  .copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$goals',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: context.dugnadTheme.primaryHover,
                        letterSpacing: -0.02 * 17,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      languages.dugnadPrivacyGoalUnit.toUpperCase(),
                      style: aeCaption(color: const Color(0xFF9890A8)).copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 8.5,
                        letterSpacing: 0.04 * 8.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _sectionLabelStyle() {
    return aeCaption(color: ScSaasThemeTokens.gray500).copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: 0.08 * 11,
      fontSize: 11,
    );
  }
}

class _NameOption {
  const _NameOption({required this.id});

  final String id;
}

class _PreviewSegButton extends StatelessWidget {
  const _PreviewSegButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: context.dp(12), vertical: context.dp(6)),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(context.dp(8)),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0x2E2D1B5B),
                    blurRadius: context.dp(3),
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: aeCaption(
            color: selected ? context.dugnadTheme.text : ScSaasThemeTokens.gray500,
          ).copyWith(fontWeight: FontWeight.w800, fontSize: 12),
        ),
      ),
    );
  }
}

class _NameOptionCard extends StatelessWidget {
  const _NameOptionCard({
    required this.option,
    required this.title,
    required this.subtitle,
    required this.example,
    required this.selected,
    required this.onTap,
  });

  final _NameOption option;
  final String title;
  final String subtitle;
  final String example;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.dp(14)),
        child: Ink(
          padding: EdgeInsets.fromLTRB(context.dp(14), context.dp(13), context.dp(14), context.dp(13)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.dp(14)),
            border: Border.all(
              color: selected ? context.dugnadTheme.primary : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              // `.vis-opt.on` lifts to `0 8px 20px -14px rgba(127,95,196,.5)`;
              // the base keeps `0 1px 3px rgba(45,27,91,.05)`. The app had held
              // the selected offset at 1 instead of 8.
              BoxShadow(
                color: selected
                    ? const Color(0x807F5FC4)
                    : const Color(0x0D2D1B5B),
                blurRadius: selected ? 20 : 3,
                offset: Offset(0, selected ? 8 : 1),
                spreadRadius: selected ? -14 : 0,
              ),
            ],
          ),
          child: Row(
            children: [
              _VisRadio(selected: selected),
              SizedBox(width: context.dp(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: aeBody().copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 11.5 * -0.01,
                      ),
                    ),
                    SizedBox(height: context.dp(2)),
                    Text(
                      subtitle,
                      style: aeCaption(color: ScSaasThemeTokens.gray500)
                          .copyWith(fontWeight: FontWeight.w600, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.dp(8)),
              Container(
                constraints: const BoxConstraints(maxWidth: 120),
                padding: EdgeInsets.symmetric(horizontal: context.dp(10), vertical: context.dp(4)),
                decoration: BoxDecoration(
                  color: selected
                      ? context.dugnadTheme.primaryTint
                      : ScSaasThemeTokens.gray50,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  example,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: aeCaption(
                    color: selected
                        ? context.dugnadTheme.primaryHover
                        : ScSaasThemeTokens.gray500,
                  ).copyWith(fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisRadio extends StatelessWidget {
  const _VisRadio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.dp(22),
      height: context.dp(22),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? context.dugnadTheme.primary : ScSaasThemeTokens.gray300,
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: context.dp(11),
                height: context.dp(11),
                decoration: BoxDecoration(
                  color: context.dugnadTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}

class _DgSwitch extends StatelessWidget {
  const _DgSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: context.dp(48),
        height: context.dp(28),
        decoration: BoxDecoration(
          color: value ? context.dugnadTheme.primary : ScSaasThemeTokens.gray300,
          borderRadius: BorderRadius.circular(999),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: context.dp(22),
            height: context.dp(22),
            margin: EdgeInsets.symmetric(horizontal: context.dp(3)),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x4D2D1B5B),
                  blurRadius: context.dp(3),
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MinorBanner extends StatelessWidget {
  const _MinorBanner({required this.onConsent});

  final VoidCallback onConsent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(context.dp(14), context.dp(13), context.dp(14), context.dp(13)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF7E6), Color(0xFFFFF2D6)],
        ),
        borderRadius: BorderRadius.circular(context.dp(14)),
        border: Border.all(color: const Color(0x66D8A028), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: context.dp(34),
            height: context.dp(34),
            decoration: BoxDecoration(
              color: const Color(0x29D8A028),
              borderRadius: BorderRadius.circular(context.dp(10)),
            ),
            child: Icon(
              Icons.shield_outlined,
              size: context.dp(17),
              color: Color(0xFFB5851A),
            ),
          ),
          SizedBox(width: context.dp(11)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  languages.dugnadPrivacyMinorBannerTitle,
                  style: aeBody().copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF8A6410),
                    fontSize: 13,
                    letterSpacing: 13 * -0.01,
                  ),
                ),
                SizedBox(height: context.dp(3)),
                Text(
                  languages.dugnadPrivacyMinorBannerSub,
                  style: aeCaption(color: const Color(0xFF9A6B12)).copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: context.dp(10)),
                GestureDetector(
                  onTap: onConsent,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: context.dp(14), vertical: context.dp(9)),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC2871C),
                      borderRadius: BorderRadius.circular(context.dp(10)),
                    ),
                    child: Text(
                      languages.dugnadPrivacyMinorConsent,
                      style: aeCaption(color: Colors.white).copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
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

class _PreviewScorerAvatar extends StatelessWidget {
  const _PreviewScorerAvatar({
    required this.anon,
    required this.clubName,
    this.clubLogo,
  });

  final bool anon;
  final String clubName;
  final String? clubLogo;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: context.dp(42),
      height: context.dp(42),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: context.dp(42),
            height: context.dp(42),
            decoration: BoxDecoration(
              color: anon ? ScSaasThemeTokens.gray100 : context.dugnadTheme.primaryTint,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_rounded,
              size: context.dp(20),
              color: anon ? Color(0xFF9890A8) : context.dugnadTheme.primaryHover,
            ),
          ),
          if (!anon)
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                width: context.dp(21),
                height: context.dp(21),
                padding: EdgeInsets.all(context.dp(2)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(context.dp(7)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x472D1B5B),
                      blurRadius: context.dp(3),
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: ClubCrest(
                  name: clubName,
                  logoUrl: clubLogo?.isEmpty ?? true ? null : clubLogo,
                  size: context.dp(17),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _YouTag extends StatelessWidget {
  const _YouTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.dp(7),
        vertical: context.dp(2),
      ),
      decoration: BoxDecoration(
        // Club shiny (same as leaderboard `.mine-tag`) — not fixed purple.
        gradient: theme.shinyGradient,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: context.dp(9),
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: context.dp(9) * 0.03,
        ),
      ),
    );
  }
}

Color _tierDotColor(String tierKey) {
  switch (tierKey) {
    case 'helt':
      return const Color(0xFF707C8E);
    case 'legende':
      return const Color(0xFFC8942E);
    case 'ikon':
      return const Color(0xFF8D9CC7);
    case 'supporter':
    default:
      return const Color(0xFFA46321);
  }
}

class _DashedRoundedBorderPainter extends CustomPainter {
  const _DashedRoundedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  final Color color;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + 6;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + 4;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
