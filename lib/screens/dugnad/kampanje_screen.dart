import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/design_scale.dart';

import '../../commonView/skeleton_loaders/dugnad_subpage_skeletons.dart';
import '../../commonView/surface_decorations.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/guest_auth_helper.dart';
import '../../utils/utils.dart';
import '../common/signUp/sign_up.dart';
import '../common/homeMainV1/home_main_v1.dart';
import 'matkasse_campaign_screen.dart';
import 'club_sheet.dart';
import '../../services/dugnad_data_cache.dart';
import 'dugnad_club_branding.dart';
import 'dugnad_models.dart';
import 'dugnad_state.dart';
import '../../ui/kit/ae_theme.dart';
import 'widgets/dugnad_choose_club_widgets.dart';
import 'widgets/dugnad_locked_module.dart';
import '../../ui/kit/ae_subpage_shell.dart';
import 'widgets/mk_campaign_card.dart';
import '../../ui/kit/ae_rise_in.dart';
import 'widgets/lucide_box_icon.dart';

/// Club-scoped campaign tab for dugnad mode.
///
/// Lists the selected club's campaigns from getClubDetail().campaigns.
/// Tap opens existing CampaignDetailScreen by slug.
class KampanjeScreen extends StatefulWidget {
  const KampanjeScreen({super.key});

  @override
  State<KampanjeScreen> createState() => _KampanjeScreenState();
}

class _KampanjeScreenState extends State<KampanjeScreen> {
  final DugnadDataCache _cache = DugnadDataCache.instance;
  final TextEditingController _searchController = TextEditingController();
  List<ClubCampaignSummary> _campaigns = [];
  String _searchQuery = '';
  String? _selectedTeam;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    DugnadState.instance.revision.addListener(_onClubChanged);
    final pending = DugnadState.instance.takePendingKampanjeTeamFilter();
    if (pending != null && pending.isNotEmpty) {
      _selectedTeam = pending;
    }
    _loadCampaigns();
  }

  @override
  void dispose() {
    _searchController.dispose();
    DugnadState.instance.revision.removeListener(_onClubChanged);
    super.dispose();
  }

  Future<void> _openCreateAccount() async {
    HapticFeedback.lightImpact();
    if (isGuestUser()) {
      await showGuestLoginSheet(context);
    } else {
      await openScreenWithResult(context, const SignUp(returnOnSuccess: true));
    }
    if (mounted) setState(() {});
  }

  Future<void> _pickClub() async {
    HapticFeedback.lightImpact();
    final club = await showClubSheet(context);
    if (club != null && mounted) {
      await DugnadState.instance.selectClub(club);
      _loadCampaigns();
    }
  }

  Widget _lockBrowse(Widget child) {
    final hasClub = DugnadState.instance.hasClub;
    final locked = !hasClub || !isLoggedIn();
    if (!locked) return child;
    return DugnadLockedModule(
      locked: true,
      label: hasClub
          ? languages.dugnadGateBuyAndEarn
          : languages.dugnadGateChooseClubBuyAndEarn,
      onUnlock: hasClub ? _openCreateAccount : _pickClub,
      hBleed: context.dp(18),
      child: child,
    );
  }

  void _onClubChanged() {
    final pending = DugnadState.instance.takePendingKampanjeTeamFilter();
    if (pending != null && pending.isNotEmpty) {
      _selectedTeam = pending;
    }
    if (mounted) _loadCampaigns();
  }

  Future<void> _loadCampaigns({bool forceRefresh = false}) async {
    if (!DugnadState.instance.hasClub) {
      setState(() => _loading = false);
      return;
    }
    final clubId = DugnadState.instance.clubId;
    final cached = _cache.peekClubDetail(clubId);
    if (cached != null && _campaigns.isEmpty) {
      _campaigns = cached.campaigns;
      _loading = false;
    }
    if (mounted && _campaigns.isEmpty) {
      setState(() => _loading = true);
    }
    try {
      final detail = await _cache.getClubDetail(
        clubId,
        forceRefresh: forceRefresh,
      );
      if (detail != null) {
        _campaigns = detail.campaigns;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  List<String> get _teamFilters {
    final teams = _campaigns
        .map((c) => (c.teamName ?? '').trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return teams;
  }

  List<ClubCampaignSummary> get _filteredCampaigns {
    final q = _searchQuery.trim().toLowerCase();
    return _campaigns.where((campaign) {
      final teamName = (campaign.teamName ?? '').trim();
      final matchesTeam = _selectedTeam == null || teamName == _selectedTeam;
      if (!matchesTeam) return false;

      if (q.isEmpty) return true;
      final title = campaign.displayTitle.toLowerCase();
      final name = campaign.name.toLowerCase();
      final slug = campaign.slug.toLowerCase();
      final team = teamName.toLowerCase();
      return title.contains(q) ||
          name.contains(q) ||
          slug.contains(q) ||
          team.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!DugnadState.instance.hasClub) {
      return AeThemeScope(
        palette: AeThemePalette.reenPreClub,
        child: Scaffold(
          backgroundColor: context.aeTheme.background,
          body: _buildBody(),
        ),
      );
    }
    return Scaffold(
      backgroundColor: context.aeTheme.background,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Browse without club — header + dummy cards under blur.
    if (!DugnadState.instance.hasClub) {
      return _buildBrowseNoClub();
    }
    // Loading
    if (_loading && _campaigns.isEmpty) {
      return ListView(
        padding: EdgeInsets.fromLTRB(
          context.dp(18),
          context.dp(8),
          context.dp(18),
          context.dp(100),
        ),
        children: [
          _buildHeaderArea(),
          SizedBox(height: context.dp(14)),
          const DugnadKampanjeListSkeleton(),
        ],
      );
    }
    // Empty — keep header + back so iOS users can leave the screen.
    if (_campaigns.isEmpty) {
      return _withPageChrome(_buildEmpty());
    }
    final visibleCampaigns = _filteredCampaigns;
    final hPad = context.dp(18);

    // Build the card list as a plain column (inside a scrollable).
    final cardList = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < visibleCampaigns.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: context.dp(14)),
            child: AeRiseIn(
              delay: Duration(milliseconds: 60 * i.clamp(0, 6)),
              child: buildCampaignSummaryCard(context, visibleCampaigns[i]),
            ),
          ),
        SizedBox(height: context.dp(60)),
      ],
    );

    return RefreshIndicator(
      color: context.aeTheme.primary,
      onRefresh: _loadCampaigns,
      child: ListView(
        padding: EdgeInsets.fromLTRB(hPad, context.dp(8), hPad, context.dp(100)),
        children: [
          _buildHeaderArea(),
          SizedBox(height: context.dp(14)),
          _buildSearchAndFilters(),
          SizedBox(height: context.dp(14)),
          Text(
            languages.dugnadDonationTeamInClub(
              DugnadClubBranding.compactName(),
            ).toUpperCase(),
            style: TextStyle(
              fontSize: context.dp(11),
              fontWeight: FontWeight.w800,
              letterSpacing: context.dp(11) * 0.08,
              color: ScSaasThemeTokens.gray500,
            ),
          ),
          SizedBox(height: context.dp(14)),
          // Single blur overlay covers the entire campaign list for guests.
          _lockBrowse(cardList),
        ],
      ),
    );
  }

  /// Header (with back) + centered empty / no-club content.
  Widget _withPageChrome(Widget child, {bool showBanner = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.dp(18),
            context.dp(8),
            context.dp(18),
            0,
          ),
          child: showBanner
              ? _buildHeaderArea()
              : SafeArea(bottom: false, child: _buildTitleBar()),
        ),
        Expanded(child: child),
      ],
    );
  }

  String _allTeamsLabel() => languages.dugnadAllTeams;

  String _searchHint() => languages.dugnadCampaignSearchHint;

  String _campaignPageTitle() => languages.dugnadCampaignPageTitle;

  String _supportTeamsTitle() {
    final club = DugnadClubBranding.fullName();
    if (club.isEmpty) return languages.dugnadCampaignPageTitle;
    return languages.dugnadSupportTeamsIn(club);
  }

  String _supportTeamsSubtitle() => languages.dugnadSupportTeamsSub;

  void _onBack() {
    final home = context.findAncestorStateOfType<HomeMainV1State>();
    if (home != null) {
      home.backOrHome();
      return;
    }
    Navigator.maybePop(context);
  }

  Widget _buildTitleBar() {
    final theme = context.aeTheme;
    return Row(
      children: [
        AeBackButton(
          onPressed: _onBack,
          solidWhite: !DugnadState.instance.hasClub,
        ),
        SizedBox(width: context.dp(12)),
        Expanded(
          child: Text(
            _campaignPageTitle(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: context.dp(20),
              fontWeight: FontWeight.w800,
              letterSpacing: context.dp(20) * -0.015,
              color: theme.text,
              height: 1.15,
            ),
          ),
        ),
        SizedBox(width: context.dp(38)),
      ],
    );
  }

  Widget _buildHeaderArea() {
    final theme = context.aeTheme;
    // Prototype: `.tk-head` + `.dg-green-banner` (matkasse.jsx MatkasseList).
    const success = ScSaasThemeTokens.success; // --ae-success #22A769
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleBar(),
          SizedBox(height: context.dp(14)),
          // `.dg-green-banner` — 38px icon, 13.5/800 title, 11.5/700 sub.
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: context.dp(15),
              vertical: context.dp(13),
            ),
            decoration: BoxDecoration(
              color: success.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(context.dp(16)),
              border: Border.all(color: success.withValues(alpha: 0.22)),
            ),
            child: Row(
              children: [
                Container(
                  width: context.dp(38),
                  height: context.dp(38),
                  decoration: BoxDecoration(
                    color: success.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(context.dp(11)),
                  ),
                  alignment: Alignment.center,
                  // Lucide `box` size 19 — `.dg-green-banner .ic`.
                  child: LucideBoxIcon(
                    size: context.dp(19),
                    color: success,
                  ),
                ),
                SizedBox(width: context.dp(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _supportTeamsTitle(),
                        style: TextStyle(
                          fontSize: context.dp(13.5),
                          fontWeight: FontWeight.w800,
                          letterSpacing: context.dp(13.5) * -0.01,
                          height: 1.25,
                          color: theme.text,
                        ),
                      ),
                      SizedBox(height: context.dp(2)),
                      Text(
                        _supportTeamsSubtitle(),
                        style: TextStyle(
                          fontSize: context.dp(11.5),
                          fontWeight: FontWeight.w700,
                          color: success,
                          height: 1.3,
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

  Widget _buildSearchAndFilters() {
    final chips = _teamFilters;
    final theme = context.aeTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.dp(16)),
            border: Border.all(color: ScSaasThemeTokens.gray100),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
            style: aeBody(color: theme.text),
            decoration: InputDecoration(
              hintText: _searchHint(),
              hintStyle: aeBody(color: ScSaasThemeTokens.gray500),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: ScSaasThemeTokens.gray500,
                size: context.dp(22),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 14,
              ),
            ),
          ),
        ),
        SizedBox(height: context.dp(12)),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildTeamChip(
                label: _allTeamsLabel(),
                active: _selectedTeam == null,
                showShield: false,
                onTap: () => setState(() => _selectedTeam = null),
              ),
              ...chips.map(
                (team) => Padding(
                  padding: EdgeInsets.only(left: context.dp(8)),
                  child: _buildTeamChip(
                    label: team,
                    active: _selectedTeam == team,
                    onTap: () => setState(() => _selectedTeam = team),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
    bool showShield = true,
  }) {
    final theme = context.aeTheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: context.dp(14),
          vertical: context.dp(9),
        ),
        decoration: BoxDecoration(
          color: active ? theme.primary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? theme.primary : ScSaasThemeTokens.gray100,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showShield) ...[
              Icon(
                Icons.shield_outlined,
                size: context.dp(15),
                color: active ? Colors.white : ScSaasThemeTokens.gray500,
              ),
              SizedBox(width: context.dp(6)),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: context.dp(13),
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : theme.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowseNoClub() {
    final dummy = dugnadDummyCampaigns();
    final hPad = context.dp(18);
    final cardList = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < dummy.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: context.dp(14)),
            child: AeRiseIn(
              delay: Duration(milliseconds: 60 * i.clamp(0, 6)),
              child: buildCampaignSummaryCard(context, dummy[i]),
            ),
          ),
        SizedBox(height: context.dp(60)),
      ],
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, context.dp(100)),
      children: [
        _buildHeaderArea(),
        SizedBox(height: context.dp(14)),
        _buildSearchAndFilters(),
        SizedBox(height: context.dp(14)),
        Text(
          languages.dugnadDonationTeamInClub(languages.dugnadChooseClub)
              .toUpperCase(),
          style: TextStyle(
            fontSize: context.dp(11),
            fontWeight: FontWeight.w800,
            letterSpacing: context.dp(11) * 0.08,
            color: ScSaasThemeTokens.gray500,
          ),
        ),
        SizedBox(height: context.dp(14)),
        _lockBrowse(cardList),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.dp(32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: context.dp(64),
              height: context.dp(64),
              decoration: AeSurface.shiny(isCircle: true),
              child: Icon(Icons.inventory_2_rounded,
                  color: context.aeTheme.primary, size: context.dp(28)),
            ),
            SizedBox(height: context.dp(20)),
            Text(languages.dugnadNoCampaignsNow,
                style: aeH3(), textAlign: TextAlign.center),
            SizedBox(height: context.dp(8)),
            Text(
              languages.dugnadCampaignsComingSoon(DugnadClubBranding.fullName()),
              style: aeBody(color: ScSaasThemeTokens.gray500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shared campaign summary card — used by KampanjeScreen + DGHome matkasse
// ═══════════════════════════════════════════════════════════════════════════

/// Builds an AeSurface campaign card from a [ClubCampaignSummary].
/// Taps navigate to [CampaignDetailScreen] by slug.
Widget buildCampaignSummaryCard(
    BuildContext context, ClubCampaignSummary campaign) {
  return MkCampaignCard(
    campaign: campaign,
    onTap: () {
      openScreen(
        context,
        MatkasseCampaignScreen(
          slug: campaign.slug,
          campaignName: campaign.name,
        ),
      );
    },
  );
}
