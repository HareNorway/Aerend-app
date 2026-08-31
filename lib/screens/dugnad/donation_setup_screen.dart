import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/design_scale.dart';
import '../common/vipps/donation_vipps_return.dart';
import '../../commonView/skeleton_loaders/dugnad_subpage_skeletons.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/utils.dart';
import 'donation_fee_calculator.dart';
import 'donation_manage_screen.dart';
import 'dugnad_club_branding.dart';
import 'dugnad_feature_flags.dart';
import 'dugnad_models.dart';
import 'dugnad_repo.dart';
import 'dugnad_state.dart';
import 'widgets/donation_why_fee_sheet.dart';
import 'widgets/dugnad_subpage_shell.dart';
import 'widgets/dugnad_rise_in.dart';
import 'dugnad_club_theme.dart';

enum _DonationBeneficiaryKind { organization, team }

const String _kVippsLogo = 'assets/images/Vipps_Logo_orange.png';

class _DonationRecipientOption {
  final _DonationBeneficiaryKind kind;
  final int? teamId;
  final String name;
  final String subtitle;
  final IconData icon;

  const _DonationRecipientOption({
    required this.kind,
    this.teamId,
    required this.name,
    required this.subtitle,
    required this.icon,
  });

  String get key =>
      kind == _DonationBeneficiaryKind.organization ? 'org' : 'team:$teamId';
}

class _DonationChipStyle {
  const _DonationChipStyle({
    this.background = Colors.white,
    required this.borderColor,
    required this.textColor,
    this.selected = false,
  });

  final Color background;
  final Color borderColor;
  final Color textColor;
  final bool selected;
}

/// Fast støtte setup screen (design: donate.jsx → DonateSetup).
class DonationSetupScreen extends StatefulWidget {
  const DonationSetupScreen({super.key, this.editing, this.initialTeamId});

  /// Pre-select this team as donation recipient (from Team screen CTA).
  final int? initialTeamId;

  /// When set, opens in edit mode for an existing active subscription.
  final DonationSubscriptionRecord? editing;

  @override
  State<DonationSetupScreen> createState() => _DonationSetupScreenState();
}

class _DonationSetupScreenState extends State<DonationSetupScreen> {
  final DugnadRepo _repo = DugnadRepo();
  final TextEditingController _customAmountController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  static const List<int> _amountChips = [50, 100, 200];

  List<_DonationRecipientOption> _recipients = [];
  List<String> _takenRecipientKeys = [];
  bool _loading = true;
  bool _proceeding = false;
  bool _apiDonationsEnabled = false;
  bool _recipientMenuOpen = false;
  bool _customAmount = false;
  int _selectedChipAmount = 100;
  String _selectedRecipientKey = '';
  String _searchQuery = '';

  /// Server-computed fee/points preview (falls back to local calculator).
  DonationFeePreview? _feePreview;
  int? _feePreviewAmount;
  Timer? _feeDebounce;

  @override
  void initState() {
    super.initState();
    DugnadState.instance.revision.addListener(_onClubChanged);
    _load();
  }

  @override
  void dispose() {
    DugnadState.instance.revision.removeListener(_onClubChanged);
    _feeDebounce?.cancel();
    _customAmountController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onClubChanged() {
    if (mounted) _load();
  }

  bool get _isEditing => widget.editing != null;

  Future<void> _load() async {
    if (!DugnadState.instance.hasClub) {
      setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);
    try {
      _apiDonationsEnabled = await _repo.donationsEnabled();
    } catch (_) {
      _apiDonationsEnabled = false;
    }

    try {
      final teams = await _repo.listTeams(DugnadState.instance.clubId);
      _recipients = _buildRecipients(teams);
      if (_isEditing) {
        final subs = await _repo.listDonationSubscriptions();
        _takenRecipientKeys = subs
            .where((s) => s.isManageable && s.id != widget.editing!.id)
            .map(_recipientKeyForSubscription)
            .where((k) => k.isNotEmpty)
            .toList();
        _recipients = _recipients
            .where((r) =>
                !_takenRecipientKeys.contains(r.key) ||
                r.key == _recipientKeyForSubscription(widget.editing!))
            .toList();
        _applyEditingDefaults(widget.editing!);
      } else {
        final initialTeamId = widget.initialTeamId;
        if (initialTeamId != null &&
            initialTeamId > 0 &&
            teams.any((t) => t.id == initialTeamId)) {
          _selectedRecipientKey = 'team:$initialTeamId';
        } else {
          _selectedRecipientKey = _defaultRecipientKey(teams);
        }
      }
    } catch (_) {
      _recipients = const [];
      if (!_isEditing) _selectedRecipientKey = '';
    }

    if (mounted) setState(() => _loading = false);
    _loadFeePreview();
  }

  /// Debounced fee-preview fetch — used while the custom amount is typed.
  void _scheduleFeePreview() {
    _feeDebounce?.cancel();
    _feeDebounce = Timer(
      const Duration(milliseconds: 350),
      _loadFeePreview,
    );
  }

  /// Fetch the server-side fee/points preview for the current amount.
  Future<void> _loadFeePreview() async {
    final amount = _amountKr;
    if (amount < 10) {
      if (mounted && _feePreview != null) {
        setState(() {
          _feePreview = null;
          _feePreviewAmount = null;
        });
      }
      return;
    }
    if (_feePreviewAmount == amount && _feePreview != null) return;
    try {
      final preview = await _repo.donationFeePreview(amount);
      if (!mounted || preview == null) return;
      if (preview.amountKr == _amountKr) {
        setState(() {
          _feePreview = preview;
          _feePreviewAmount = preview.amountKr;
        });
      }
    } catch (_) {
      // Keep the local fallback breakdown on any failure.
    }
  }

  /// Fee breakdown from the backend preview when available, else local calc.
  DonationFeeBreakdown get _feeBreakdown {
    final amount = _amountKr;
    final preview = _feePreview;
    if (preview != null && preview.amountKr == amount && amount > 0) {
      final feeKr = preview.totalFeeKr.round();
      final netKr = preview.netToBeneficiaryKr.round();
      final tx = (feeKr / 2).round();
      return DonationFeeBreakdown(
        grossKr: amount,
        feeKr: feeKr,
        netKr: netKr,
        transactionFeeKr: tx,
        platformFeeKr: feeKr - tx,
      );
    }
    return DonationFeeCalculator.forAmountKr(amount);
  }

  /// Monthly points from the backend preview when available, else local calc.
  int get _previewPoints {
    final preview = _feePreview;
    if (preview != null &&
        preview.amountKr == _amountKr &&
        preview.estimatedPoints > 0) {
      return preview.estimatedPoints;
    }
    return DonationFeeCalculator.previewPointsForAmountKr(_amountKr);
  }

  String _recipientKeyForSubscription(DonationSubscriptionRecord sub) {
    if (sub.beneficiaryType == 'organization') return 'org';
    if (sub.teamId != null) return 'team:${sub.teamId}';
    return '';
  }

  void _applyEditingDefaults(DonationSubscriptionRecord sub) {
    _selectedRecipientKey = _recipientKeyForSubscription(sub);
    final amount = sub.amountKr.round();
    if (_amountChips.contains(amount)) {
      _customAmount = false;
      _selectedChipAmount = amount;
    } else {
      _customAmount = true;
      _customAmountController.text = amount.toString();
    }
  }

  bool get _donationsLive =>
      DugnadFeatureFlags.donationsEnabled && _apiDonationsEnabled;

  String _donationErrorMessage(Map<String, dynamic>? response) {
    final code = response?['code']?.toString() ?? '';
    switch (code) {
      case 'subscription_cap':
        return languages.dugnadDonationErrorSubscriptionCap;
      case 'duplicate_target':
        return languages.dugnadDonationErrorDuplicateTarget;
      case 'vipps_error':
        final debug = response?['debug_detail']?.toString();
        if (debug != null && debug.isNotEmpty) {
          return debug;
        }
        return languages.dugnadDonationVippsError;
      case 'vipps_not_confirmed':
        return languages.dugnadDonationUpdateNotConfirmed;
      default:
        return response?['message']?.toString() ??
            (_isEditing
                ? languages.dugnadDonationUpdateFailed
                : languages.dugnadDonationCreateFailed);
    }
  }

  Future<void> _onProceed() async {
    if (!_donationsLive || _proceeding) return;
    final recipient = _selectedRecipient;
    if (recipient == null || _amountKr < 10) return;
    final isOrg = recipient.kind == _DonationBeneficiaryKind.organization;
    final teamId = recipient.teamId;
    if (!isOrg && teamId == null) return;
    HapticFeedback.mediumImpact();

    setState(() => _proceeding = true);
    try {
      if (_isEditing) {
        final response = await _repo.updateDonationSubscription(
          id: widget.editing!.id,
          amountKr: _amountKr,
          beneficiaryType: isOrg ? 'organization' : 'team',
          organizationId: DugnadState.instance.clubId,
          teamId: isOrg ? null : teamId,
        );

        if (!mounted) return;

        if (response == null || response['status'] != 1) {
          openSimpleSnackbar(_donationErrorMessage(response));
          return;
        }

        openSimpleSnackbar(languages.dugnadDonationUpdateSuccess);
        Navigator.pop(context, true);
        return;
      }

      final response = await _repo.createDonationSubscription(
        beneficiaryType: isOrg ? 'organization' : 'team',
        organizationId: DugnadState.instance.clubId,
        teamId: isOrg ? null : teamId,
        amountKr: _amountKr,
      );

      if (!mounted) return;

      if (response == null || response['status'] != 1) {
        openSimpleSnackbar(_donationErrorMessage(response));
        return;
      }

      final result = DonationCreateResult.fromJson(response);
      final url = result.confirmationUrl;
      if (url == null || url.isEmpty) {
        openSimpleSnackbar(languages.dugnadDonationCreateFailed);
        return;
      }

      final uri = Uri.tryParse(url);
      if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        openSimpleSnackbar(languages.dugnadDonationVippsLaunchFailed);
        return;
      }

      if (result.subscription != null) {
        await prefSetInt(
          prefDonationPendingSubscriptionId,
          result.subscription!.id,
        );
      }
    } catch (_) {
      if (mounted) openSimpleSnackbar(languages.dugnadDonationCreateFailed);
    } finally {
      if (mounted) setState(() => _proceeding = false);
    }
  }

  List<_DonationRecipientOption> _buildRecipients(List<ClubTeamItem> teams) {
    final clubName = DugnadClubBranding.fullName();
    final clubShort = DugnadClubBranding.compactName();
    return [
      _DonationRecipientOption(
        kind: _DonationBeneficiaryKind.organization,
        name: clubName,
        subtitle: languages.dugnadDonationWholeClub,
        icon: Icons.favorite_rounded,
      ),
      ...teams.map(
        (team) => _DonationRecipientOption(
          kind: _DonationBeneficiaryKind.team,
          teamId: team.id,
          name: team.name,
          subtitle: languages.dugnadDonationTeamInClub(clubShort),
          icon: Icons.shield_outlined,
        ),
      ),
    ];
  }

  String _defaultRecipientKey(List<ClubTeamItem> teams) {
    final pointsTeamId = DugnadState.instance.pointsTeamId;
    if (pointsTeamId > 0 && teams.any((t) => t.id == pointsTeamId)) {
      return 'team:$pointsTeamId';
    }
    final firstTeam = teams.isNotEmpty ? teams.first : null;
    if (firstTeam != null) return 'team:${firstTeam.id}';
    return '';
  }

  int get _amountKr {
    if (_customAmount) {
      return int.tryParse(_customAmountController.text.trim()) ?? 0;
    }
    return _selectedChipAmount;
  }

  _DonationRecipientOption? get _selectedRecipient {
    for (final option in _recipients) {
      if (option.key == _selectedRecipientKey) return option;
    }
    return _recipients.isNotEmpty ? _recipients.first : null;
  }

  List<_DonationRecipientOption> get _filteredRecipients {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _recipients;
    return _recipients
        .where((r) => r.name.toLowerCase().contains(q))
        .toList();
  }

  String _formatKr(int value) =>
      NumberFormat.decimalPattern('nb').format(value);

  String _monthlySupportPointsLine(int points) {
    if (points > 0) {
      return 'Du tjener $points poeng i måneden som fast støttespiller';
    }
    return 'Du tjener medlemspoeng hver måned som fast støttespiller';
  }

  @override
  Widget build(BuildContext context) {
    final clubName = DugnadClubBranding.fullName();
    final clubShort = DugnadClubBranding.compactName();
    final clubLogo = DugnadState.instance.clubLogo;
    final amount = _amountKr;
    final fee = _feeBreakdown;
    final points = _previewPoints;
    final recipient = _selectedRecipient;
    final targetName = recipient?.name ?? clubName;
    final valid = amount >= 10 && recipient != null;
    final enabled = _donationsLive;

    return DugnadFixedTypography(
      child: Scaffold(
        backgroundColor: context.dugnadTheme.primary,
        body: Stack(
          children: [
            DugnadLbScrollBody(
              hero: DugnadLbHero(
                clubName: clubName,
                clubLogo: clubLogo,
                title: _isEditing
                    ? languages.dugnadDonationEditTitle
                    : languages.dugnadFastSupportTitle,
                subtitle: languages.dugnadDonationHeroSubtitle,
                subtitleWithHeart: true,
                titleTrailing: GestureDetector(
                  onTap: () =>
                      openScreen(context, const DonationManageScreen()),
                  child: Container(
                    height: context.dp(34),
                    padding: EdgeInsets.fromLTRB(
                      context.dp(12),
                      0,
                      context.dp(8),
                      0,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(context.dp(999)),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          languages.dugnadDonationManageLink,
                          style: AeDugnadText.pageHeroSub(color: Colors.white)
                              .copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: context.dp(13),
                          ),
                        ),
                        SizedBox(width: context.dp(2)),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: context.dp(18),
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
                onBack: () => Navigator.pop(context),
              ),
              bottomPadding: 120,
              itemGap: 14,
              topPadding: 18,
              feedRadius: 22,
              overlap: 12,
              children: _loading
                  ? const [DugnadDonationSkeleton()]
                  : _buildFeedChildren(
                      fee: fee,
                      targetName: targetName,
                      clubName: clubName,
                      clubShort: clubShort,
                      points: points,
                      recipient: recipient,
                    ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: MediaQuery.paddingOf(context).bottom + 16,
              child: _buildProceedButton(valid: valid, enabled: enabled),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFeedChildren({
    required DonationFeeBreakdown fee,
    required String targetName,
    required String clubName,
    required String clubShort,
    required int points,
    required _DonationRecipientOption? recipient,
  }) {
    return [
      _riseIn(
        0,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DugnadSectionLabel(languages.dugnadDonationWhoSupport),
            _buildRecipientPicker(recipient),
          ],
        ),
      ),
      _riseIn(
        1,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DugnadSectionLabel(languages.dugnadDonationMonthlyAmount),
            SizedBox(height: context.dp(10)),
            _buildAmountChips(),
            if (_customAmount) ...[
              SizedBox(height: context.dp(10)),
              _buildCustomAmountField(),
            ],
            if (points > 0) ...[
              SizedBox(height: context.dp(12)),
              Container(
                padding: EdgeInsets.fromLTRB(
                  context.dp(14),
                  context.dp(12),
                  context.dp(14),
                  context.dp(12),
                ),
                decoration: BoxDecoration(
                  color: context.dugnadTheme.primaryTint,
                  borderRadius: BorderRadius.circular(context.dp(12)),
                  border: Border.all(
                    color: context.dugnadTheme.primary.withValues(alpha: 0.16),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: context.dp(1)),
                      child: Icon(
                        Icons.star_rounded,
                        size: context.dp(14),
                        color: context.dugnadTheme.primaryHover,
                      ),
                    ),
                    SizedBox(width: context.dp(8)),
                    Expanded(
                      child: Text(
                        _monthlySupportPointsLine(points),
                        style: aeBody(
                          color: context.dugnadTheme.primaryHover,
                        ).copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      _riseIn(2, _buildFeeCard(fee, targetName)),
      _riseIn(3, _buildHowPaidCard(clubName, clubShort, targetName)),
      _riseIn(
        4,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DugnadSectionLabel(languages.dugnadDonationPaymentHeading),
            _buildVippsCard(),
            SizedBox(height: context.dp(12)),
            Text(
              languages.dugnadDonationTerms,
              style: AeDugnadText.bannerSubtitle(),
            ),
          ],
        ),
      ),
      _riseIn(5, _buildPointsCard(points)),
    ];
  }

  _DonationChipStyle _chipStyle(bool selected) {
    final theme = context.dugnadTheme;

    return _DonationChipStyle(
      background: Colors.white,
      borderColor: selected ? theme.primary : Colors.transparent,
      textColor: selected ? theme.primaryHover : const Color(0xFF2D1B5B),
      selected: selected,
    );
  }

  Widget _buildRecipientPicker(_DonationRecipientOption? recipient) {
    final theme = context.dugnadTheme;

    if (_recipients.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(context.dp(14)),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E6),
          borderRadius: BorderRadius.circular(context.dp(14)),
          border: Border.all(color: const Color(0xFFF2DFA6)),
        ),
        child: Text(
          languages.dugnadDonationNoTeams,
          style: TextStyle(
            color: context.dugnadTheme.primaryHover,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _recipientMenuOpen = !_recipientMenuOpen);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.symmetric(
              horizontal: context.dp(14),
              vertical: context.dp(12),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(context.dp(14)),
              border: Border.all(
                color:
                    _recipientMenuOpen ? theme.primary : const Color(0xFFE6E2EE),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.text.withValues(alpha: 0.06),
                  blurRadius: context.dp(3),
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: context.dp(34),
                  height: context.dp(34),
                  decoration: BoxDecoration(
                    color: theme.primaryTint,
                    borderRadius: BorderRadius.circular(context.dp(10)),
                  ),
                  child: Icon(
                    recipient?.icon ?? Icons.shield_outlined,
                    color: theme.primaryHover,
                    size: context.dp(16),
                  ),
                ),
                SizedBox(width: context.dp(11)),
                Expanded(
                  child: Text(
                    recipient?.name ?? languages.dugnadDonationSelectTeam,
                    style: aeTitle().copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: AeFontSize.titleMd,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  recipient?.kind == _DonationBeneficiaryKind.organization
                      ? languages.dugnadDonationWholeClubShort
                      : languages.dugnadDonationTeamLabel.toUpperCase(),
                  style: AeDugnadText.clubStatLabel(
                    color: const Color(0xFFA39FB0),
                  ),
                ),
                SizedBox(width: context.dp(6)),
                AnimatedRotation(
                  turns: _recipientMenuOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  curve: const Cubic(0.2, 0.9, 0.3, 1.2),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _recipientMenuOpen
                        ? theme.primary
                        : ScSaasThemeTokens.gray500,
                    size: context.dp(19),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_recipientMenuOpen) ...[
          SizedBox(height: context.dp(10)),
          _buildRecipientMenuCard(),
        ],
      ],
    );
  }

  Widget _buildRecipientMenuCard() {
    final theme = context.dugnadTheme;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.dp(16)),
        boxShadow: ScSaasThemeTokens.shadowCard,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.42,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.dp(12),
                context.dp(12),
                context.dp(12),
                context.dp(8),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: languages.dugnadDonationSearchTeams,
                  prefixIcon: Icon(Icons.search_rounded, size: context.dp(20)),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(context.dp(12)),
                    borderSide: const BorderSide(color: Color(0xFFE6E2EE)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(context.dp(12)),
                    borderSide: BorderSide(color: theme.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.fromLTRB(
                  context.dp(8),
                  0,
                  context.dp(8),
                  context.dp(8),
                ),
                itemCount: _filteredRecipients.length,
                itemBuilder: (context, index) {
                  final option = _filteredRecipients[index];
                  final selected = option.key == _selectedRecipientKey;
                  return Container(
                    margin: EdgeInsets.only(top: context.dp(4)),
                    decoration: BoxDecoration(
                      color: selected ? theme.primaryTint : Colors.transparent,
                      borderRadius: BorderRadius.circular(context.dp(12)),
                    ),
                    child: ListTile(
                      leading: Container(
                        width: context.dp(32),
                        height: context.dp(32),
                        decoration: BoxDecoration(
                          gradient: selected ? theme.shinyGradient : null,
                          color: selected ? null : ScSaasThemeTokens.gray100,
                          borderRadius: BorderRadius.circular(context.dp(9)),
                          boxShadow: selected ? theme.shadowButton : null,
                        ),
                        child: Icon(
                          option.icon,
                          size: context.dp(16),
                          color: selected
                              ? Colors.white
                              : ScSaasThemeTokens.gray500,
                        ),
                      ),
                      title: Text(
                        option.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        option.subtitle,
                        style: TextStyle(
                          color: selected
                              ? theme.primaryHover
                              : ScSaasThemeTokens.gray500,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      trailing: selected
                          ? Container(
                              width: context.dp(24),
                              height: context.dp(24),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: theme.shinyGradient,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_rounded,
                                size: context.dp(14),
                                color: Colors.white,
                              ),
                            )
                          : null,
                      onTap: () => setState(() {
                        _selectedRecipientKey = option.key;
                        _recipientMenuOpen = false;
                        _searchQuery = '';
                        _searchController.clear();
                      }),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountChips() {
    return Row(
      children: [
        ..._amountChips.map((chip) {
          final selected = !_customAmount && _selectedChipAmount == chip;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: context.dp(8)),
              child: _amountChipButton(
                label: languages.dugnadDonationAmountKr(chip),
                selected: selected,
                onTap: () {
                  setState(() {
                    _customAmount = false;
                    _selectedChipAmount = chip;
                  });
                  _loadFeePreview();
                },
              ),
            ),
          );
        }),
        Expanded(
          child: _amountChipButton(
            label: languages.dugnadDonationOtherAmount,
            selected: _customAmount,
            onTap: () => setState(() => _customAmount = true),
          ),
        ),
      ],
    );
  }

  Widget _amountChipButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final style = _chipStyle(selected);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(context.dp(13)),
          border: Border.all(
            color: style.selected ? style.borderColor : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: style.selected
              ? [
                  BoxShadow(
                    // `.dn-chips button.on` lift is rgba(127,95,196,.5), not .35.
                    color: style.borderColor.withValues(alpha: 0.5),
                    blurRadius: context.dp(22),
                    offset: const Offset(0, 10),
                    spreadRadius: -14,
                  ),
                ]
              : [
                  BoxShadow(
                    color: context.dugnadTheme.text.withValues(alpha: 0.06),
                    blurRadius: context.dp(3),
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: context.dp(13), horizontal: context.dp(10)),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AeDugnadText.amountChip(color: style.textColor),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAmountField() {
    return TextField(
      controller: _customAmountController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) {
        setState(() {});
        _scheduleFeePreview();
      },
      decoration: InputDecoration(
        hintText: languages.dugnadDonationCustomHint,
        filled: true,
        fillColor: const Color(0xFFE8F0FE),
        suffixText: languages.dugnadDonationCurrencyPerMonth,
        suffixStyle: TextStyle(
          color: context.dugnadTheme.primaryHover,
          fontWeight: FontWeight.w700,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(context.dp(12)),
          borderSide: const BorderSide(color: Color(0xFFD8CBEF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(context.dp(12)),
          borderSide: const BorderSide(color: Color(0xFFD8CBEF)),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: context.dp(14), vertical: context.dp(14)),
      ),
    );
  }

  Widget _buildFeeCard(DonationFeeBreakdown fee, String targetName) {
    final netPct = fee.grossKr > 0 ? fee.netKr / fee.grossKr : 0.94;

    return Container(
      padding: EdgeInsets.all(context.dp(15)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.dp(16)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D2D1B5B),
            blurRadius: context.dp(4),
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FeeProgressBar(netPercent: netPct),
          SizedBox(height: context.dp(12)),
          RichText(
            text: TextSpan(
              style: AeDugnadText.feeBreakdown(),
              children: [
                TextSpan(
                  text: languages.dugnadDonationFeeBreakdownPrefix(
                    _formatKr(fee.grossKr),
                  ),
                ),
                TextSpan(
                  text: ' ${_formatKr(fee.netKr)} kr ',
                  style: const TextStyle(
                    color: Color(0xFF22A769),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(text: languages.dugnadDonationFeeBreakdownMiddle(targetName)),
                TextSpan(
                  text: ' ${_formatKr(fee.feeKr)} kr ',
                  style: TextStyle(
                    color: context.dugnadTheme.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(text: languages.dugnadDonationFeeBreakdownSuffix),
              ],
            ),
          ),
          SizedBox(height: context.dp(12)),
          Material(
            color: context.dugnadTheme.primaryTint,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                DonationWhyFeeSheet.show(context);
              },
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: context.dp(13), vertical: context.dp(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: context.dp(14),
                      color: context.dugnadTheme.primary,
                    ),
                    SizedBox(width: context.dp(6)),
                    Text(
                      languages.dugnadDonationWhyFee,
                      style: aeLabel().copyWith(
                        color: context.dugnadTheme.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowPaidCard(
    String clubName,
    String clubShort,
    String teamName,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(context.dp(15), context.dp(14), context.dp(15), context.dp(14)),
      decoration: BoxDecoration(
        color: const Color(0x1A22A769),
        borderRadius: BorderRadius.circular(context.dp(16)),
        border: Border.all(color: const Color(0x3822A769)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: context.dp(38),
            height: context.dp(38),
            decoration: BoxDecoration(
              color: const Color(0x2922A769),
              borderRadius: BorderRadius.circular(context.dp(11)),
            ),
            child: Icon(
              Icons.shield_outlined,
              color: Color(0xFF22A769),
              size: context.dp(18),
            ),
          ),
          SizedBox(width: context.dp(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  languages.dugnadDonationNudgeTitle,
                  style: AeDugnadText.nudgeTitle(
                    color: ScSaasThemeTokens.text,
                  ),
                ),
                SizedBox(height: context.dp(3)),
                Text(
                  languages.dugnadDonationHowPaidBody(
                    clubName,
                    clubShort,
                    teamName,
                  ),
                  style: AeDugnadText.nudgeBody(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVippsCard() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.dp(14), vertical: context.dp(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.dp(14)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F2D1B5B),
            blurRadius: context.dp(3),
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: context.dp(44),
            height: context.dp(44),
            decoration: BoxDecoration(
              // `.dn-pay .vipps { background: #ff5b24 }` -- Vipps orange behind
              // the mark, so a transparent-edged asset still reads as the brand.
              color: const Color(0xFFFF5B24),
              borderRadius: BorderRadius.circular(context.dp(11)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              _kVippsLogo,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
          SizedBox(width: context.dp(13)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  languages.dugnadDonationVippsLabel,
                  style: aeTitle().copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: AeFontSize.titleMd,
                  ),
                ),
                Text(
                  languages.dugnadDonationVippsSubtitle,
                  style: AeDugnadText.bannerSubtitle(),
                ),
              ],
            ),
          ),
          Container(
            width: context.dp(26),
            height: context.dp(26),
            decoration: BoxDecoration(
              color: context.dugnadTheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, color: Colors.white, size: context.dp(14)),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsCard(int points) {
    const titleColor = Color(0xFF7A5410);
    const bodyColor = Color(0xFF9A6B12);

    return Container(
      padding: EdgeInsets.all(context.dp(14)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF6DB), Color(0xFFFDEDBF)],
        ),
        borderRadius: BorderRadius.circular(context.dp(14)),
        border: Border.all(color: Color(0x57D8A028)),
      ),
      child: Row(
        children: [
          Container(
            width: context.dp(38),
            height: context.dp(38),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(context.dp(11)),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF7D979), Color(0xFFE0A93A)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD8A028).withValues(alpha: 0.7),
                  blurRadius: context.dp(14),
                  offset: const Offset(0, 6),
                  spreadRadius: -6,
                ),
              ],
            ),
            child: Icon(Icons.star_rounded, color: Colors.white, size: context.dp(19)),
          ),
          SizedBox(width: context.dp(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  languages.dugnadDonationPointsTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                    color: titleColor,
                    letterSpacing: 13.5 * -0.01,
                  ),
                ),
                Text(
                  languages.dugnadDonationPointsSubtitle,
                  style: TextStyle(
                    color: bodyColor.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '+$points',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: bodyColor,
                  letterSpacing: 22 * -0.02,
                  height: context.dp(1),
                ),
              ),
              Text(
                languages.dugnadDonationPointsPerMonth,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                  color: bodyColor.withValues(alpha: 0.8),
                  letterSpacing: 9 * 0.04,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProceedButton({required bool valid, required bool enabled}) {
    final canPress = valid && enabled && !_proceeding;
    final primary = context.dugnadTheme.primary;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: canPress ? _onProceed : null,
            icon: _proceeding
                ? SizedBox(
                    width: context.dp(18),
                    height: context.dp(18),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(Icons.favorite_rounded, size: context.dp(18)),
            label: Text(
              _isEditing
                  ? languages.dugnadDonationEditButton
                  : languages.dugnadDonationSetupButton,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: primary.withValues(alpha: 0.55),
              disabledForegroundColor: Colors.white.withValues(alpha: 0.9),
              padding: EdgeInsets.symmetric(vertical: context.dp(16)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.dp(14)),
              ),
            ),
          ),
        ),
        if (!enabled)
          Positioned(
            top: -8,
            right: 8,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: context.dp(10), vertical: context.dp(5)),
              decoration: BoxDecoration(
                color: const Color(0xFF2E1F58),
                borderRadius: BorderRadius.circular(context.dp(99)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: context.dp(6),
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                languages.dugnadDonationComingSoon,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Two-segment donation split bar: green (earmarked net) + orange (fee),
/// with rounded caps and a subtle gap (design: donate.jsx split bar).
class _FeeProgressBar extends StatelessWidget {
  const _FeeProgressBar({required this.netPercent});

  final double netPercent;

  @override
  Widget build(BuildContext context) {
    final net = (netPercent * 100).round().clamp(1, 99);
    final fee = (100 - net).clamp(1, 99);
    // `.dn-fee-bar` is ONE rounded track (gray-100, overflow hidden) holding
    // two edge-to-edge fills -- not two separately-rounded pills with a gap.
    // The app's two floating pills, its 3px gap, and the green glow it added
    // to `.net` are all absent from the design.
    return SizedBox(
      height: context.dp(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.dp(999)),
        child: ColoredBox(
          color: ScSaasThemeTokens.border, // --ae-gray-100 track
          child: Row(
            children: [
              Expanded(
                flex: net,
                // `.net` -- 90deg green, no shadow. 90deg is Flutter's default
                // centerLeft->centerRight, so begin/end are omitted correctly.
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF22A769), Color(0xFF2BBD7A)],
                    ),
                  ),
                  child: SizedBox.expand(),
                ),
              ),
              Expanded(
                flex: fee,
                // `.fee` -- **solid** --ae-warning, with a 1px white separator
                // on its left edge (`box-shadow: -1px 0 0 rgba(255,255,255,.7)`).
                // The app had an orange gradient and no divider.
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: ScSaasThemeTokens.warning,
                    border: Border(
                      left: BorderSide(
                        color: Colors.white.withValues(alpha: 0.7),
                        width: context.dp(1),
                      ),
                    ),
                  ),
                  child: const SizedBox.expand(),
                ),
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
Widget _riseIn(int index, Widget child) {
  if (index > 6) return child;
  return DugnadRiseIn(
    delay: Duration(
      milliseconds: index < 4 ? 120 + index * 70 : 400 + (index - 4) * 50,
    ),
    duration: Duration(milliseconds: index < 4 ? 600 : 550),
    child: child,
  );
}
