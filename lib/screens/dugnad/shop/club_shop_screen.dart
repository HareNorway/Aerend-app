import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../commonView/circle_nav_bar.dart';
import '../../../commonView/dugnad_club_loader.dart';
import '../../../services/dugnad_data_cache.dart';
import '../../../theme/design_scale.dart';
import '../../../theme/reen_pre_club_theme.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/guest_auth_helper.dart';
import '../../../utils/utils.dart';
import '../../common/homeMainV1/home_main_v1.dart';
import '../../common/signUp/sign_up.dart';
import '../club_sheet.dart';
import '../dugnad_club_branding.dart';
import '../dugnad_club_theme.dart';
import '../dugnad_repo.dart';
import '../dugnad_state.dart';
import '../gamification_models.dart';
import '../widgets/dugnad_locked_module.dart';
import '../widgets/dugnad_shiny_press.dart';
import '../widgets/dugnad_subpage_shell.dart';
import 'club_shop_home.dart';
import 'club_shop_models.dart';

/// Club shop — locked gate (`ShopLocked` in `dugnad/shop.jsx`).
class ClubShopScreen extends StatefulWidget {
  const ClubShopScreen({super.key});

  static const routeName = '/club-shop';

  @override
  State<ClubShopScreen> createState() => _ClubShopScreenState();
}

class _ClubShopScreenState extends State<ClubShopScreen> {
  final DugnadRepo _repo = DugnadRepo();
  final TextEditingController _number = TextEditingController();
  final FocusNode _focus = FocusNode();

  ClubShopMemberInfo? _member;
  String? _error;
  bool _busy = false;
  bool _checking = true;

  ClubShopConfig? get _shopConfig {
    final clubId = DugnadState.instance.clubId;
    return DugnadDataCache.instance
        .peek<GamificationConfig>(
          DugnadDataCache.gamificationConfigKey(clubId),
        )
        ?.clubShop;
  }

  String get _collectionLabel {
    final name = _shopConfig?.collectionName.trim() ?? '';
    if (name.isNotEmpty) return name;
    return languages.dugnadClubShopSubtitle(DugnadClubBranding.compactName());
  }

  String get _partnerName {
    final name = _shopConfig?.partnerName.trim() ?? '';
    return name;
  }

  @override
  void initState() {
    super.initState();
    DugnadState.instance.revision.addListener(_onClubChanged);
    if (DugnadState.instance.hasClub) {
      _loadAccess();
    } else {
      _checking = false;
    }
  }

  @override
  void dispose() {
    DugnadState.instance.revision.removeListener(_onClubChanged);
    _number.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onClubChanged() {
    if (!mounted) return;
    if (DugnadState.instance.hasClub && _member == null) {
      setState(() => _checking = true);
      _loadAccess();
    } else {
      setState(() {});
    }
  }

  Future<void> _pickClub() async {
    HapticFeedback.lightImpact();
    final club = await showClubSheet(context);
    if (club != null && mounted) {
      await DugnadState.instance.selectClub(club);
    }
  }

  Widget _lockGate(Widget child) {
    final hasClub = DugnadState.instance.hasClub;
    final locked = !hasClub || !isLoggedIn();
    if (!locked) return child;
    return DugnadLockedModule(
      locked: true,
      label: hasClub
          ? languages.dugnadGateBuyAndEarn
          : languages.dugnadGateChooseClubBuyAndEarn,
      onUnlock: hasClub ? _openCreateAccount : _pickClub,
      hBleed: context.dp(22),
      vBleed: 0,
      child: child,
    );
  }

  Future<void> _loadAccess() async {
    if (!DugnadState.instance.hasClub) {
      if (mounted) setState(() => _checking = false);
      return;
    }
    final clubId = DugnadState.instance.clubId;
    final access = await _repo.clubShopAccess(clubId: clubId);
    if (!mounted) return;
    setState(() {
      _checking = false;
      if (access?.unlocked == true) {
        _member = access!.member;
      }
    });
  }

  Future<void> _submit() async {
    final value = _number.text.trim();
    if (value.isEmpty) {
      setState(() => _error = languages.dugnadClubShopUnlockEmpty);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await _repo.clubShopUnlock(
      clubId: DugnadState.instance.clubId,
      membershipNumber: value,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!result.ok) {
      setState(() {
        _error = result.message.trim().isNotEmpty
            ? result.message
            : languages.dugnadClubShopUnlockGeneric;
      });
      return;
    }
    final member = result.member;
    setState(() => _member = member);
    final greet = member?.firstName ?? '';
    if (greet.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(languages.dugnadClubShopUnlockSuccess(greet))),
      );
    }
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

  void _onBack() {
    final home = context.findAncestorStateOfType<HomeMainV1State>();
    if (home != null) {
      home.backOrHome();
      return;
    }
    Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    return Scaffold(
      backgroundColor: theme.background,
      body: _checking
          ? const DugnadClubLoaderScreen()
          : _member != null
              ? ClubShopHome(member: _member!)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ShopHead(
                      title: languages.dugnadClubShopTitle,
                      onBack: _onBack,
                    ),
                    Expanded(
                      child: _lockGate(
                        _LockedGate(
                          collectionLabel: _collectionLabel,
                          partnerName: _partnerName,
                          controller: _number,
                          focus: _focus,
                          error: _error,
                          busy: _busy,
                          onChanged: (_) {
                            if (_error != null) setState(() => _error = null);
                          },
                          onSubmit: _busy ? null : _submit,
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _ShopHead extends StatelessWidget {
  const _ShopHead({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    return ColoredBox(
      color: theme.background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.dp(18),
            context.dp(6),
            context.dp(18),
            context.dp(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              DugnadLbBackButton(onPressed: onBack, solidWhite: true),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: aeH2(color: theme.text)
                      .copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 20 * -0.015,
                        height: 1.15,
                      )
                      .dp(context),
                ),
              ),
              SizedBox(width: context.dp(38)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockedGate extends StatelessWidget {
  const _LockedGate({
    required this.collectionLabel,
    required this.partnerName,
    required this.controller,
    required this.focus,
    required this.error,
    required this.busy,
    required this.onChanged,
    required this.onSubmit,
  });

  final String collectionLabel;
  final String partnerName;
  final TextEditingController controller;
  final FocusNode focus;
  final String? error;
  final bool busy;
  final ValueChanged<String> onChanged;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.dp(22),
        context.dp(20),
        context.dp(22),
        aePillNavReservedHeight(context) + context.dp(16),
      ),
      children: [
        Column(
          children: [
            _LockGlyph(),
            Text(
              languages.dugnadClubShopLockedTitle,
              textAlign: TextAlign.center,
              style: aeH2(color: theme.text)
                  .copyWith(
                    fontSize: 21,
                    letterSpacing: 21 * -0.02,
                    fontWeight: FontWeight.w800,
                  )
                  .dp(context),
            ),
            SizedBox(height: context.dp(9)),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: context.dp(280)),
              child: Text(
                languages.dugnadClubShopLockedBody(collectionLabel),
                textAlign: TextAlign.center,
                style: aeBody(color: ScSaasThemeTokens.gray500)
                    .copyWith(
                      fontSize: 14,
                      height: 1.55,
                      fontWeight: FontWeight.w600,
                    )
                    .dp(context),
              ),
            ),
          ],
        ),
        SizedBox(height: context.dp(24)),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            languages.dugnadClubShopMemberNumber.toUpperCase(),
            style: aeCaption(color: ScSaasThemeTokens.gray500)
                .copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 12 * 0.04,
                )
                .dp(context),
          ),
        ),
        SizedBox(height: context.dp(10)),
        TextField(
          controller: controller,
          focusNode: focus,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
          onChanged: onChanged,
          onSubmitted: (_) => onSubmit?.call(),
          style: aeBody(color: theme.ink)
              .copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 15 * 0.06,
              )
              .dp(context),
          inputFormatters: [
            TextInputFormatter.withFunction((old, incoming) {
              return incoming.copyWith(text: incoming.text.toUpperCase());
            }),
          ],
          decoration: InputDecoration(
            hintText: languages.dugnadClubShopMemberPlaceholder,
            hintStyle: aeBody(color: ScSaasThemeTokens.gray500)
                .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.9)
                .dp(context),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: context.dp(18),
              vertical: context.dp(16),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.dp(14)),
              borderSide: const BorderSide(color: Colors.transparent, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.dp(14)),
              borderSide: const BorderSide(color: Colors.transparent, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.dp(14)),
              borderSide: BorderSide(color: theme.primary, width: 1.5),
            ),
          ),
        ),
        if (error != null) ...[
          SizedBox(height: context.dp(10)),
          _ErrorBanner(message: error!),
        ],
        SizedBox(height: context.dp(14)),
        IgnorePointer(
          ignoring: busy || onSubmit == null,
          child: DugnadShinyPress(
            borderRadius: context.dp(14),
            onTap: onSubmit ?? () {},
            child: Opacity(
            opacity: busy ? 0.7 : 1,
            child: Container(
              height: context.dp(52),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: theme.shinyGradient,
                borderRadius: BorderRadius.circular(context.dp(14)),
                boxShadow: theme.shadowButton,
              ),
              child: busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      languages.dugnadClubShopUnlockCta,
                      style: aeLabel(color: Colors.white)
                          .copyWith(fontSize: 16, fontWeight: FontWeight.w800)
                          .dp(context),
                    ),
            ),
          ),
        ),
        ),
        SizedBox(height: context.dp(16)),
        _HintCard(
          icon: Icons.info_outline_rounded,
          child: Text(
            languages.dugnadClubShopHintCard,
            style: aeCaption(color: ScSaasThemeTokens.gray600)
                .copyWith(
                  fontSize: 12.5,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                )
                .dp(context),
          ),
        ),
        if (partnerName.isNotEmpty) ...[
          SizedBox(height: context.dp(10)),
          _HintCard(
            icon: Icons.storefront_outlined,
            child: Text.rich(
              TextSpan(
                style: aeCaption(color: ScSaasThemeTokens.gray600)
                    .copyWith(
                      fontSize: 12.5,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    )
                    .dp(context),
                children: _partnerSpans(
                  languages.dugnadClubShopHintPartner(partnerName),
                  partnerName,
                  theme.primaryHover,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<InlineSpan> _partnerSpans(String full, String partner, Color accent) {
    final i = full.indexOf(partner);
    if (i < 0) return [TextSpan(text: full)];
    return [
      TextSpan(text: full.substring(0, i)),
      TextSpan(
        text: partner,
        style: TextStyle(fontWeight: FontWeight.w800, color: accent),
      ),
      TextSpan(text: full.substring(i + partner.length)),
    ];
  }
}

class _LockGlyph extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = context.dp(74);
    return Container(
      width: size,
      height: size,
      margin: EdgeInsets.only(bottom: context.dp(18)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.dp(24)),
        border: Border.all(color: ReenPreClubTokens.coral.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.7),
            blurRadius: 0,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: const Color(0xFF140C28).withValues(alpha: 0.12),
            blurRadius: context.dp(4),
            offset: Offset(0, context.dp(2)),
          ),
          BoxShadow(
            color: const Color(0xFF140C28).withValues(alpha: 0.16),
            blurRadius: context.dp(28),
            offset: Offset(0, context.dp(14)),
            spreadRadius: context.dp(-12),
          ),
        ],
      ),
      child: Icon(
        Icons.lock_rounded,
        size: context.dp(30),
        color: ReenPreClubTokens.coralDeep,
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.dp(13),
        context.dp(11),
        context.dp(13),
        context.dp(11),
      ),
      decoration: BoxDecoration(
        color: const Color(0x17D63F4D),
        border: Border.all(color: const Color(0x33D63F4D)),
        borderRadius: BorderRadius.circular(context.dp(13)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: context.dp(16),
            color: const Color(0xFFB02A37),
          ),
          SizedBox(width: context.dp(9)),
          Expanded(
            child: Text(
              message,
              style: aeCaption(color: const Color(0xFFB02A37))
                  .copyWith(
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  )
                  .dp(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.icon, required this.child});

  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.dp(14),
        context.dp(13),
        context.dp(14),
        context.dp(13),
      ),
      decoration: BoxDecoration(
        color: theme.primaryTint,
        borderRadius: BorderRadius.circular(context.dp(15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: context.dp(1)),
            child: Icon(icon, size: context.dp(16), color: theme.primaryHover),
          ),
          SizedBox(width: context.dp(10)),
          Expanded(child: child),
        ],
      ),
    );
  }
}

