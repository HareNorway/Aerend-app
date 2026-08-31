import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../commonView/surface_decorations.dart';
import '../../theme/design_scale.dart';
import '../../theme/reen_pre_club_theme.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/utils.dart';
import 'club_crest.dart';
import 'dugnad_models.dart';
import 'dugnad_repo.dart';
import 'dugnad_sheet.dart';
import 'dugnad_club_theme.dart';
import 'dugnad_state.dart';

/// Searchable club picker bottom sheet.
///
/// Design spec: dugnad/club-select.jsx → ClubSheet + `.reen-pre` glass
/// overrides in Custom Dugnad.html when the sheet sits on navy.
/// Returns the chosen [ClubListItem] via Navigator.pop, or null if dismissed.
///
/// Usage:
/// ```dart
/// final club = await showClubSheet(context, title: 'Velg din klubb');
/// ```
Future<ClubListItem?> showClubSheet(
  BuildContext context, {
  String? title,
  ClubListItem? currentClub,
  String? membershipNumber,
  VoidCallback? onEditMembership,
  /// Force Reen coral-navy glass (club onboarding / pre-club). When null,
  /// Reen is used until onboarding is complete; after that the club theme wins.
  bool? useReenPreClubStyle,
}) {
  // club-select.jsx line 99: `{current ? "Bytt klubb" : "Velg din klubb"}`.
  title ??= currentClub != null
      ? languages.dugnadSwitchClub
      : languages.dugnadChooseYourClub;
  final theme = context.dugnadTheme;
  final dark = useReenPreClubStyle ??
      _isReenPreClubSheet(theme) ||
      !DugnadState.instance.onboardingComplete;
  final sheetTheme =
      dark ? DugnadClubThemePalette.reenPreClub : theme;
  return showDugnadSheet<ClubListItem>(
    context: context,
    isScrollControlled: true,
    // Prototype `.dg-csheet` height: 90%.
    // `.reen-pre .dg-csheet { background: #16304F }`
    backgroundColor: dark ? ReenPreClubTokens.navy : theme.background,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.90,
    ),
    builder: (_) => DugnadClubThemeScope(
      palette: sheetTheme,
      child: _ClubSheetBody(
        title: title!,
        currentClub: currentClub,
        membershipNumber: membershipNumber,
        onEditMembership: onEditMembership,
        dark: dark,
      ),
    ),
  );
}

bool _isReenPreClubSheet(DugnadClubThemePalette theme) {
  // Match Reen navy — luminance alone is wrong for a dark admin club color.
  return theme.background == ReenPreClubTokens.navy &&
      theme.primary == ReenPreClubTokens.coral;
}

class _ClubSheetBody extends StatefulWidget {
  final String title;
  final ClubListItem? currentClub;
  final String? membershipNumber;
  final VoidCallback? onEditMembership;
  final bool dark;

  const _ClubSheetBody({
    required this.title,
    this.currentClub,
    this.membershipNumber,
    this.onEditMembership,
    required this.dark,
  });

  @override
  State<_ClubSheetBody> createState() => _ClubSheetBodyState();
}

class _ClubSheetBodyState extends State<_ClubSheetBody> {
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<ClubListItem> _allClubs = [];
  List<ClubListItem> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadClubs();
    _search.addListener(_onSearchChanged);
    _searchFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadClubs() async {
    try {
      final response = await DugnadRepo().listClubs();
      if (response is Map && response['status'] == 1) {
        final List raw = response['clubs'] ?? [];
        _allClubs = raw.map((e) => ClubListItem.fromJson(e)).toList();
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _filtered = List.of(_allClubs);
        _loading = false;
      });
    }
  }

  void _onSearchChanged() {
    final q = _search.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = List.of(_allClubs);
      } else {
        _filtered = _allClubs
            .where((c) =>
                c.name.toLowerCase().contains(q) ||
                (c.area?.toLowerCase().contains(q) ?? false))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // `.dg-csheet-top { flex-shrink: 0; padding: 10px 18px 14px }`
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.dp(18),
            context.dp(10),
            context.dp(18),
            context.dp(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // `.dg-msheet-grab { margin: 2px auto 12px }`
              Padding(
                padding: EdgeInsets.only(top: context.dp(2), bottom: context.dp(12)),
                child: Center(
                  child: Container(
                    width: context.dp(40),
                    height: context.dp(5),
                    decoration: BoxDecoration(
                      color: widget.dark
                          ? const Color(0x47FFFFFF)
                          : ScSaasThemeTokens.gray300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              _buildHeader(context),
              if (widget.currentClub != null) ...[
                SizedBox(height: context.dp(13)),
                _buildCurrentClub(context),
              ],
              SizedBox(height: context.dp(13)),
              _buildSearch(context),
            ],
          ),
        ),
        Expanded(child: _buildList(context)),
      ],
    );
  }

  /// `.dg-csheet-top .hd` — 20px/800 title, 34px close circle.
  Widget _buildHeader(BuildContext context) {
    final titleColor =
        widget.dark ? Colors.white : ScSaasThemeTokens.text;
    final closeBg =
        widget.dark ? const Color(0x1FFFFFFF) : Colors.white;
    final closeFg =
        widget.dark ? Colors.white : ScSaasThemeTokens.text;

    return Row(
      children: [
        Expanded(
          child: Text(
            widget.title,
            style: aeH2(color: titleColor).copyWith(fontSize: context.dp(20)),
          ),
        ),
        SizedBox(width: context.dp(10)),
        GestureDetector(
          onTap: () {
            dugnadSheetCloseHaptic();
            Navigator.pop(context);
          },
          child: Container(
            width: context.dp(34),
            height: context.dp(34),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: closeBg,
              shape: BoxShape.circle,
              border: widget.dark
                  ? Border.all(
                      color: const Color(0x38FFFFFF),
                      width: context.dp(1),
                    )
                  : null,
              boxShadow: widget.dark
                  ? [
                      BoxShadow(
                        color: const Color(0x80000000),
                        blurRadius: context.dp(16),
                        offset: Offset(0, context.dp(6)),
                        spreadRadius: context.dp(-6),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: const Color(0x1F2D1B5B),
                        blurRadius: context.dp(3),
                        offset: Offset(0, context.dp(1)),
                      ),
                    ],
            ),
            child: Icon(
              Icons.close_rounded,
              color: closeFg,
              size: context.dp(18),
            ),
          ),
        ),
      ],
    );
  }

  /// `.dg-csheet-current` — radius 15, padding 11px 13px, gap 12.
  Widget _buildCurrentClub(BuildContext context) {
    final club = widget.currentClub!;
    final bool hasMember = widget.membershipNumber != null &&
        widget.membershipNumber!.trim().isNotEmpty;
    final dark = widget.dark;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.dp(13),
        vertical: context.dp(11),
      ),
      decoration: dark
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(context.dp(15)),
              border: Border.all(
                color: ReenPreClubTokens.glassBorder,
                width: context.dp(1),
              ),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x1AFFFFFF), Color(0x09FFFFFF)],
              ),
            )
          : AeSurface.card(
              borderRadius: BorderRadius.circular(context.dp(15)),
            ),
      child: Row(
        children: [
          ClubCrest(
            name: club.name,
            logoUrl: club.logo,
            size: context.dp(38),
          ),
          SizedBox(width: context.dp(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  club.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.dp(14.5),
                    fontWeight: FontWeight.w800,
                    letterSpacing: context.dp(14.5) * -0.01,
                    color: dark ? Colors.white : ScSaasThemeTokens.text,
                  ),
                ),
                SizedBox(height: context.dp(2)),
                Text(
                  hasMember
                      ? languages.dugnadMemberNumber(widget.membershipNumber!)
                      : languages.dugnadSupporter,
                  style: TextStyle(
                    fontSize: context.dp(11.5),
                    fontWeight: FontWeight.w600,
                    color: dark
                        ? ReenPreClubTokens.textSoft
                        : ScSaasThemeTokens.gray500,
                  ),
                ),
              ],
            ),
          ),
          if (widget.onEditMembership != null) ...[
            SizedBox(width: context.dp(10)),
            // `.dg-csheet-current .mem` — 11px/800 pill, padding 7px 11px.
            GestureDetector(
              onTap: widget.onEditMembership,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.dp(11),
                  vertical: context.dp(7),
                ),
                decoration: BoxDecoration(
                  color: dark
                      ? const Color(0x26FFFFFF)
                      : context.dugnadTheme.primaryTint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.vpn_key_rounded,
                      size: context.dp(12),
                      color: dark
                          ? ReenPreClubTokens.coralHover
                          : context.dugnadTheme.primaryHover,
                    ),
                    SizedBox(width: context.dp(5)),
                    Text(
                      hasMember
                          ? languages.dugnadChangeClub
                          : languages.dugnadAddMembership,
                      style: TextStyle(
                        fontSize: context.dp(11),
                        fontWeight: FontWeight.w800,
                        letterSpacing: context.dp(11) * -0.01,
                        color: dark
                            ? ReenPreClubTokens.coralHover
                            : context.dugnadTheme.primaryHover,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// `.dg-csheet-search` — inset on navy, white plate on lavender.
  Widget _buildSearch(BuildContext context) {
    final dark = widget.dark;
    final focused = _searchFocus.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.ease,
      padding: EdgeInsets.symmetric(horizontal: context.dp(15)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.dp(14)),
        border: Border.all(
          width: context.dp(1),
          color: dark
              ? (focused
                  ? ReenPreClubTokens.coral
                  : const Color(0x24FFFFFF))
              : Colors.transparent,
        ),
        gradient: dark
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x57081424), Color(0x29081424)],
              )
            : null,
        color: dark ? null : Colors.white,
        boxShadow: dark
            ? [
                BoxShadow(
                  color: const Color(0x66081424),
                  blurRadius: context.dp(5),
                  offset: Offset(0, context.dp(2)),
                  spreadRadius: -1,
                ),
                if (focused)
                  BoxShadow(
                    color: ReenPreClubTokens.coral.withValues(alpha: 0.20),
                    spreadRadius: context.dp(4),
                  ),
              ]
            : ScSaasThemeTokens.shadowCard,
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: dark ? Colors.white : ScSaasThemeTokens.gray500,
            size: context.dp(17),
          ),
          SizedBox(width: context.dp(10)),
          Expanded(
            child: TextField(
              controller: _search,
              focusNode: _searchFocus,
              style: TextStyle(
                fontSize: context.dp(15),
                color: dark ? Colors.white : ScSaasThemeTokens.text,
              ),
              cursorColor: dark ? ReenPreClubTokens.coral : null,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Colors.transparent,
                hintText: languages.dugnadSearchClubHint,
                hintStyle: TextStyle(
                  fontSize: context.dp(15),
                  color: dark
                      ? const Color(0x80FFFFFF)
                      : ScSaasThemeTokens.gray500,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: context.dp(13),
                ),
              ),
            ),
          ),
          // `.clr` renders only while the query is non-empty.
          if (_search.text.isNotEmpty) ...[
            SizedBox(width: context.dp(10)),
            GestureDetector(
              onTap: () => _search.clear(),
              child: Container(
                width: context.dp(24),
                height: context.dp(24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: dark
                      ? const Color(0x26FFFFFF)
                      : ScSaasThemeTokens.gray100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: dark
                      ? ReenPreClubTokens.textMuted
                      : ScSaasThemeTokens.gray500,
                  size: context.dp(14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// `.dg-csheet-list` — gap 9, padding `4px 18px calc(safe-bottom + 22px)`.
  Widget _buildList(BuildContext context) {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(
          color: widget.dark
              ? ReenPreClubTokens.coral
              : context.dugnadTheme.primary,
        ),
      );
    }
    if (_filtered.isEmpty) {
      return _buildEmpty(context);
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        context.dp(18),
        context.dp(4),
        context.dp(18),
        MediaQuery.paddingOf(context).bottom + context.dp(22),
      ),
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => SizedBox(height: context.dp(9)),
      itemBuilder: (context, index) {
        final club = _filtered[index];
        return _ClubRow(
          club: club,
          selected: widget.currentClub?.id == club.id,
          dark: widget.dark,
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.pop(context, club);
          },
        );
      },
    );
  }

  /// `.dg-csheet-empty { padding: 38px 24px }`
  Widget _buildEmpty(BuildContext context) {
    final dark = widget.dark;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.dp(24),
          vertical: context.dp(38),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: context.dp(22),
              color: dark
                  ? ReenPreClubTokens.textSoft
                  : ScSaasThemeTokens.gray300,
            ),
            SizedBox(height: context.dp(10)),
            Text(
              languages.dugnadNoClubMatch(_search.text),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.dp(13),
                fontWeight: FontWeight.w600,
                color: dark
                    ? ReenPreClubTokens.textMuted
                    : ScSaasThemeTokens.gray500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.dg-clubrow` — white card on lavender; glass relief on Reen navy.
class _ClubRow extends StatefulWidget {
  final ClubListItem club;
  final bool selected;
  final bool dark;
  final VoidCallback onTap;

  const _ClubRow({
    required this.club,
    required this.selected,
    required this.dark,
    required this.onTap,
  });

  @override
  State<_ClubRow> createState() => _ClubRowState();
}

class _ClubRowState extends State<_ClubRow> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final club = widget.club;
    final dark = widget.dark;

    // `.dg-clubrow:hover { transform: translateY(-2px) }` on Reen; -1 on kit.
    final lift = (_pressed || widget.selected) && !reduceMotion
        ? (dark ? -2.0 : -1.0)
        : 0.0;

    final meta = <String>[
      if (club.area != null && club.area!.trim().isNotEmpty) club.area!.trim(),
      if (club.sponsorStoreCount > 0)
        languages.dugnadStoreCount(club.sponsorStoreCount),
    ].join(' · ');

    final accent = dark ? ReenPreClubTokens.coral : theme.primary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 150),
        curve: Curves.ease,
        transform: Matrix4.translationValues(0, context.dp(lift), 0),
        padding: EdgeInsets.symmetric(
          horizontal: context.dp(dark ? 14 : 13),
          vertical: context.dp(dark ? 12 : 11),
        ),
        decoration: dark
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(context.dp(16)),
                border: Border.all(
                  width: context.dp(1),
                  color: widget.selected || _pressed
                      ? const Color(0x80E86657)
                      : ReenPreClubTokens.glassBorder,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: widget.selected || _pressed
                      ? const [Color(0x26FFFFFF), Color(0x0FFFFFFF)]
                      : const [Color(0x1AFFFFFF), Color(0x09FFFFFF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x59081424),
                    blurRadius: context.dp(26),
                    offset: Offset(0, context.dp(14)),
                    spreadRadius: context.dp(-10),
                  ),
                  if (widget.selected || _pressed)
                    BoxShadow(
                      color: ReenPreClubTokens.coral.withValues(alpha: 0.35),
                      blurRadius: context.dp(30),
                      offset: Offset(0, context.dp(8)),
                      spreadRadius: context.dp(-6),
                    ),
                ],
              )
            : BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(context.dp(15)),
                border: Border.all(
                  width: context.dp(1.5),
                  color: widget.selected ? theme.primary : Colors.transparent,
                ),
                boxShadow: [
                  if (widget.selected)
                    BoxShadow(
                      color: theme.primary.withValues(alpha: 0.45),
                      blurRadius: context.dp(24),
                      offset: Offset(0, context.dp(10)),
                      spreadRadius: context.dp(-14),
                    )
                  else if (_pressed)
                    BoxShadow(
                      color: const Color(0x662D1B5B),
                      blurRadius: context.dp(22),
                      offset: Offset(0, context.dp(10)),
                      spreadRadius: context.dp(-14),
                    )
                  else
                    BoxShadow(
                      color: const Color(0x0D2D1B5B),
                      blurRadius: context.dp(2),
                      offset: Offset(0, context.dp(1)),
                    ),
                ],
              ),
        child: Row(
          children: [
            ClubCrest(
              name: club.name,
              logoUrl: club.logo,
              size: context.dp(44),
            ),
            SizedBox(width: context.dp(13)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    club.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.dp(15),
                      fontWeight: FontWeight.w800,
                      letterSpacing: context.dp(15) * -0.01,
                      color: dark ? Colors.white : ScSaasThemeTokens.text,
                    ),
                  ),
                  if (meta.isNotEmpty) ...[
                    SizedBox(height: context.dp(3)),
                    Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: context.dp(11),
                          color: dark
                              ? ReenPreClubTokens.textSoft
                              : ScSaasThemeTokens.gray500,
                        ),
                        SizedBox(width: context.dp(5)),
                        Expanded(
                          child: Text(
                            meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: context.dp(11.5),
                              fontWeight: FontWeight.w600,
                              color: dark
                                  ? ReenPreClubTokens.textSoft
                                  : ScSaasThemeTokens.gray500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: context.dp(13)),
            if (widget.selected)
              Container(
                width: context.dp(28),
                height: context.dp(28),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: dark
                      ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            ReenPreClubTokens.coralHover,
                            ReenPreClubTokens.coral,
                          ],
                        )
                      : null,
                  color: dark ? null : accent,
                  shape: BoxShape.circle,
                  boxShadow: dark
                      ? [
                          BoxShadow(
                            color: ReenPreClubTokens.coral
                                .withValues(alpha: 0.70),
                            blurRadius: context.dp(16),
                            offset: Offset(0, context.dp(4)),
                            spreadRadius: context.dp(-4),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: context.dp(15),
                  color: Colors.white,
                ),
              )
            else if (dark)
              Container(
                width: context.dp(34),
                height: context.dp(34),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: _pressed
                        ? const [
                            ReenPreClubTokens.coralHover,
                            ReenPreClubTokens.coral,
                          ]
                        : const [Color(0x2BFFFFFF), Color(0x0FFFFFFF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x8C081424),
                      blurRadius: context.dp(7),
                      offset: Offset(0, context.dp(3)),
                      spreadRadius: context.dp(-3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: context.dp(18),
                  color: Colors.white,
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
    );
  }
}
