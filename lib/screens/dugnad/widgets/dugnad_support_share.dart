import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/design_scale.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../club_crest.dart';
import '../dugnad_club_theme.dart';
import '../dugnad_club_branding.dart';
import '../dugnad_repo.dart';
import '../dugnad_share.dart';
import '../dugnad_sheet.dart';
import '../dugnad_state.dart';
import 'dugnad_confirm_sheet.dart';

/// Shared max width for cards on payment/donation success screens.
const double dugnadSuccessCardWidth = 320;

/// Centers content to the same width as [DugnadSupportShareCard].
class DugnadSuccessCardWidth extends StatelessWidget {
  const DugnadSuccessCardWidth({
    super.key,
    required this.child,
    this.maxWidth = dugnadSuccessCardWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

Future<String> fetchDugnadSupportShareLink({int? organizationId}) async {
  final share = await DugnadRepo().getShareSummary(
    organizationId: organizationId ?? DugnadState.instance.clubId,
  );
  return share?.shareLink?.trim() ?? '';
}

Future<void> copyDugnadSupportShareLink(BuildContext context) async {
  final link = await fetchDugnadSupportShareLink();
  if (!context.mounted) return;
  if (link.isEmpty) {
    openSimpleSnackbar(languages.dugnadShareLinkUnavailable);
    return;
  }
  await Clipboard.setData(ClipboardData(text: link));
  if (!context.mounted) return;
  openSimpleSnackbar(languages.referralCopied);
}

/// Success check burst (`.dg-placed .burst`) — primary shiny gradient + white tick.
class DugnadSuccessBurstCheck extends StatelessWidget {
  const DugnadSuccessBurstCheck({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final s = context.dp(size);
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: theme.shinyGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.4),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: theme.primary.withValues(alpha: 0.6),
            blurRadius: context.dp(30),
            offset: const Offset(0, 14),
            spreadRadius: -8,
          ),
        ],
      ),
      child: Icon(
        Icons.check_rounded,
        color: Colors.white,
        size: context.dp(size * 0.46),
      ),
    );
  }
}

/// Dark shareable support card (prototype `ShareCard` in gamify.jsx).
class DugnadSupportShareCard extends StatelessWidget {
  const DugnadSupportShareCard({
    super.key,
    required this.teamName,
    required this.message,
    this.logoUrl,
    this.eyebrow,
    this.maxWidth = dugnadSuccessCardWidth,
  });

  final String teamName;
  final String message;
  final String? logoUrl;
  final String? eyebrow;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.dp(20)),
          gradient: theme.shinyGradient,
          boxShadow: [
            // `.dg-sharecard` inset highlight + drop.
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.35),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
            BoxShadow(
              color: theme.primary.withValues(alpha: 0.7),
              blurRadius: context.dp(40),
              offset: const Offset(0, 20),
              spreadRadius: -16,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.dp(20)),
          child: Stack(
            children: [
              // `.dg-sharecard .sc-bg` — soft radials, not hard circles.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.88, -1.2),
                      radius: 1.15,
                      colors: [
                        Colors.white.withValues(alpha: 0.3),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.7],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-1.0, 1.3),
                      radius: 1.05,
                      colors: [
                        Colors.white.withValues(alpha: 0.14),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.7],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(context.dp(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: context.dp(50),
                          height: context.dp(50),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(context.dp(14)),
                          ),
                          child: Center(
                            child: ClubCrest(
                              name: teamName,
                              logoUrl: logoUrl,
                              size: context.dp(40),
                            ),
                          ),
                        ),
                        SizedBox(width: context.dp(12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (eyebrow ?? languages.dugnadSupporter)
                                    .toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                  letterSpacing: 10 * 0.08,
                                ),
                              ),
                              Text(
                                teamName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                  letterSpacing: 17 * -0.02,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.dp(16)),
                    Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 19,
                        height: 1.2,
                        letterSpacing: 19 * -0.02,
                      ),
                    ),
                    SizedBox(height: context.dp(16)),
                    Divider(color: Colors.white.withValues(alpha: 0.22)),
                    SizedBox(height: context.dp(8)),
                    Row(
                      children: [
                        Text(
                          'Reen Dugnad',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.favorite_rounded,
                          size: context.dp(16),
                          color: theme.primaryTint,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// White share button with optional points reward pill (`.dg-sharebtn`).
class DugnadShareSupportButton extends StatelessWidget {
  const DugnadShareSupportButton({
    super.key,
    required this.onPressed,
    this.pointsReward = 20,
    /// Matkasse placed uses compact centered; donate uses the row lead icon.
    this.compact = false,
  });

  final VoidCallback onPressed;
  final int pointsReward;
  final bool compact;

  Widget _rewardPill(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.dp(11),
        vertical: context.dp(4),
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF7D979), Color(0xFFE7B542)],
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.6),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: const Color(0xFFD8A028).withValues(alpha: 0.65),
            blurRadius: context.dp(10),
            offset: const Offset(0, 4),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Text(
        languages.dugnadSharePointsReward(pointsReward),
        style: const TextStyle(
          color: Color(0xFF7A5410),
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    // `.ae-btn` uses `--ae-r-md` (14). Shadow lives on this outer decoration
    // so it is not clipped to a rectangle (which reads as sharp corners).
    final radius = BorderRadius.circular(context.dp(14));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.7),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: theme.primary.withValues(alpha: 0.5),
            blurRadius: context.dp(26),
            offset: const Offset(0, 12),
            spreadRadius: -14,
          ),
          BoxShadow(
            color: theme.text.withValues(alpha: 0.12),
            blurRadius: context.dp(6),
            offset: const Offset(0, 2),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: radius),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onPressed();
          },
          customBorder: RoundedRectangleBorder(borderRadius: radius),
          child: compact
              ? Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.dp(16),
                    vertical: context.dp(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.share_rounded,
                        size: context.dp(17),
                        color: theme.primaryHover,
                      ),
                      SizedBox(width: context.dp(8)),
                      Flexible(
                        child: Text(
                          languages.dugnadShareYourSupport,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.text,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      SizedBox(width: context.dp(10)),
                      _rewardPill(context),
                    ],
                  ),
                )
              : Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.dp(14),
                    vertical: context.dp(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: context.dp(42),
                        height: context.dp(42),
                        decoration: BoxDecoration(
                          color: theme.primaryTint,
                          borderRadius: BorderRadius.circular(context.dp(12)),
                        ),
                        child: Icon(
                          Icons.share_rounded,
                          color: theme.primaryHover,
                        ),
                      ),
                      SizedBox(width: context.dp(13)),
                      Expanded(
                        child: Text(
                          languages.dugnadShareYourSupport,
                          style: TextStyle(
                            color: theme.text,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: 15 * -0.01,
                          ),
                        ),
                      ),
                      _rewardPill(context),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

/// Primary CTA matching `.ae-btn--primary` (shiny gradient + white label).
class DugnadSuccessPrimaryButton extends StatelessWidget {
  const DugnadSuccessPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.home_outlined,
  });

  final String label;
  final VoidCallback onPressed;
  /// Pass null for a label-only CTA (level-up "Heia!").
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        borderRadius: BorderRadius.circular(context.dp(14)),
        child: Ink(
          height: context.dp(52),
          decoration: BoxDecoration(
            gradient: theme.shinyGradient,
            borderRadius: BorderRadius.circular(context.dp(14)),
            boxShadow: theme.shadowButton,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: context.dp(18), color: Colors.white),
                SizedBox(width: context.dp(8)),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: 16 * -0.01,
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

/// Opens the share sheet with the support card preview.
Future<void> showDugnadSupportShareSheet({
  required BuildContext context,
  required String teamName,
  required String message,
  String? logoUrl,
  int pointsReward = 20,
}) {
  return showDugnadSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _DugnadSupportShareSheet(
      teamName: teamName,
      message: message,
      logoUrl: logoUrl,
      pointsReward: pointsReward,
    ),
  );
}

class _DugnadSupportShareSheet extends StatefulWidget {
  const _DugnadSupportShareSheet({
    required this.teamName,
    required this.message,
    this.logoUrl,
    required this.pointsReward,
  });

  final String teamName;
  final String message;
  final String? logoUrl;
  final int pointsReward;

  @override
  State<_DugnadSupportShareSheet> createState() => _DugnadSupportShareSheetState();
}

class _DugnadSupportShareSheetState extends State<_DugnadSupportShareSheet> {
  bool _done = false;
  String _shareLink = '';

  @override
  void initState() {
    super.initState();
    _loadShareLink();
  }

  Future<void> _loadShareLink() async {
    final link = await fetchDugnadSupportShareLink();
    if (mounted) setState(() => _shareLink = link);
  }

  String get _shareText {
    if (_shareLink.isEmpty) return widget.message;
    final club = DugnadClubBranding.fullName();
    return languages.dugnadSupporterCardShareMessage(
      languages.dugnadSupporterCardTitle,
      club,
      _shareLink,
    );
  }

  Future<void> _share() async {
    HapticFeedback.mediumImpact();
    final text = _shareText;
    await shareDugnadText(context, text: text, subject: widget.teamName);
    if (!mounted) return;
    setState(() => _done = true);
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _copy() async {
    HapticFeedback.selectionClick();
    final link = _shareLink.isNotEmpty ? _shareLink : widget.message;
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    openSimpleSnackbar(languages.referralCopied);
    setState(() => _done = true);
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    return DugnadSheetBody(
      children: _done
          ? [_buildDone(theme)]
          : [
              DugnadSheetHead(
                icon: Icons.share_rounded,
                title: languages.dugnadShareSheetTitle,
                message: languages.dugnadShareSheetSubtitle,
              ),
              SizedBox(height: context.dp(14)),
              Center(
                child: DugnadSupportShareCard(
                  teamName: widget.teamName,
                  message: widget.message,
                  logoUrl: widget.logoUrl,
                ),
              ),
              SizedBox(height: context.dp(16)),
              _rewardBanner(theme),
              SizedBox(height: context.dp(16)),
              Row(
                children: [
                  Expanded(
                    child: _shareTarget(
                      icon: Icons.copy_rounded,
                      label: languages.dugnadReferralCopyLink,
                      onTap: _copy,
                    ),
                  ),
                  SizedBox(width: context.dp(10)),
                  Expanded(
                    child: _shareTarget(
                      icon: Icons.share_rounded,
                      label: languages.share,
                      onTap: _share,
                    ),
                  ),
                ],
              ),
            ],
    );
  }

  Widget _buildDone(DugnadClubThemePalette theme) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.dp(12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: context.dp(74),
            height: context.dp(74),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: theme.shinyGradient,
              boxShadow: theme.shadowButton,
            ),
            child: Icon(Icons.check_rounded, color: Colors.white, size: context.dp(34)),
          ),
          SizedBox(height: context.dp(16)),
          Text(
            languages.dugnadShareSheetDoneTitle(widget.pointsReward),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.text,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          SizedBox(height: context.dp(6)),
          Text(
            languages.dugnadShareSheetDoneSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              // `.dg-share-done p` is a neutral gray-500, not a themed purple.
              color: ScSaasThemeTokens.gray500,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rewardBanner(DugnadClubThemePalette theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.dp(14), vertical: context.dp(12)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF4D6), Color(0xFFF7E3A8)],
        ),
        borderRadius: BorderRadius.circular(context.dp(14)),
        border: Border.all(color: const Color(0x59D8A028)),
      ),
      child: Row(
        children: [
          Container(
            width: context.dp(38),
            height: context.dp(38),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(context.dp(11)),
              gradient: const LinearGradient(
                colors: [Color(0xFFF7D979), Color(0xFFE0A93A)],
              ),
            ),
            child: Icon(Icons.star_rounded, color: Colors.white, size: context.dp(18)),
          ),
          SizedBox(width: context.dp(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  languages.dugnadShareSheetEarnTitle(widget.pointsReward),
                  style: const TextStyle(
                    color: Color(0xFF7A5410),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                Text(
                  languages.dugnadShareSheetEarnSubtitle,
                  style: const TextStyle(
                    color: Color(0xFF9A6B12),
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Text(
            languages.dugnadSharePointsReward(widget.pointsReward),
            style: const TextStyle(
              color: Color(0xFF9A6B12),
              fontWeight: FontWeight.w900,
              fontSize: 19,
            ),
          ),
        ],
      ),
    );
  }

  Widget _shareTarget({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = context.dugnadTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.dp(18)),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: context.dp(8)),
          child: Column(
            children: [
              Container(
                width: context.dp(56),
                height: context.dp(56),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(context.dp(18)),
                  boxShadow: ScSaasThemeTokens.shadowCard,
                ),
                // `.dg-share-targets .ic` glyph is purple-700, not purple-600.
                child: Icon(icon, color: theme.primaryHover),
              ),
              SizedBox(height: context.dp(8)),
              Text(
                label,
                style: const TextStyle(
                  // `.dg-share-targets .nm` is a neutral gray-700, not a themed
                  // purple.
                  color: ScSaasThemeTokens.gray700,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Centered golden points badge for success screens (`.dg-ptsreward`).
/// Medal pops, star-coins burst, and the amount counts up from 0.
class DugnadSuccessPointsBadge extends StatefulWidget {
  const DugnadSuccessPointsBadge({
    super.key,
    required this.points,
    required this.label,
    this.animate = true,
  });

  final int points;
  final String label;
  final bool animate;

  @override
  State<DugnadSuccessPointsBadge> createState() =>
      _DugnadSuccessPointsBadgeState();
}

class _DugnadSuccessPointsBadgeState extends State<DugnadSuccessPointsBadge>
    with TickerProviderStateMixin {
  static const _goldLight = Color(0xFFF7D979);
  static const _goldMid = Color(0xFFE0A93A);
  static const _goldDark = Color(0xFFC2871C);
  static const _goldText = Color(0xFF9A6B12);
  static const _coinLight = Color(0xFFFFE9A8);
  static const _coinMid = Color(0xFFE7B542);

  static const _coinOffsets = <Offset>[
    Offset(-52, -18),
    Offset(-34, -44),
    Offset(4, -56),
    Offset(40, -40),
    Offset(54, -10),
    Offset(40, 22),
    Offset(-30, 24),
    Offset(-50, 14),
  ];

  static const _coinDelays = <double>[
    0.04,
    0.10,
    0.02,
    0.12,
    0.06,
    0.14,
    0.08,
    0.16,
  ];

  late final AnimationController _pop;
  late final AnimationController _coins;
  late final AnimationController _count;
  late final Animation<double> _popScale;
  bool _started = false;
  bool _coinsGone = false;

  @override
  void initState() {
    super.initState();
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _coins = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1110),
    );
    _count = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _popScale = CurvedAnimation(parent: _pop, curve: Curves.easeOutBack);
    _coins.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _coinsGone = true);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _started) return;
      _started = true;
      final reduce = MediaQuery.disableAnimationsOf(context) || !widget.animate;
      if (reduce) {
        _pop.value = 1;
        _count.value = 1;
        _coinsGone = true;
        return;
      }
      HapticFeedback.mediumImpact();
      _pop.forward();
      _coins.forward();
      _count.forward();
    });
  }

  @override
  void dispose() {
    _pop.dispose();
    _coins.dispose();
    _count.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final medal = context.dp(64);
    return Column(
      children: [
        SizedBox(
          width: context.dp(160),
          height: context.dp(110),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (!_coinsGone)
                for (var i = 0; i < _coinOffsets.length; i++)
                  AnimatedBuilder(
                    animation: _coins,
                    builder: (context, _) {
                      const burst = 0.95;
                      const total = 1.11;
                      final t = ((_coins.value * total) - _coinDelays[i]) /
                          burst;
                      if (t <= 0 || t >= 1) return const SizedBox.shrink();
                      final opacity = t < 0.22
                          ? t / 0.22
                          : math.max(0.0, 1 - ((t - 0.22) / 0.78));
                      final scale = 0.3 + math.min(0.55, t * 0.85);
                      final offset = Offset(
                        _coinOffsets[i].dx * t,
                        _coinOffsets[i].dy * t,
                      );
                    return Positioned.fill(
                      child: Center(
                        child: Transform.translate(
                          offset: offset,
                          child: Opacity(
                            opacity: opacity,
                            child: Transform.scale(
                              scale: scale,
                              child: Container(
                                width: context.dp(19),
                                height: context.dp(19),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [_coinLight, _coinMid],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _goldMid.withValues(alpha: 0.7),
                                      blurRadius: context.dp(5),
                                      offset: const Offset(0, 2),
                                      spreadRadius: -2,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.star_rounded,
                                  size: context.dp(10),
                                  color: _goldText.withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ScaleTransition(
                scale: _popScale,
                child: Container(
                  width: medal,
                  height: medal,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment(-0.5, -1),
                      end: Alignment(0.8, 1),
                      colors: [_goldLight, _goldMid, _goldDark],
                      stops: [0.0, 0.62, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.5),
                        blurRadius: 0,
                        offset: const Offset(0, 1),
                      ),
                      BoxShadow(
                        color: const Color(0xFFD8A028).withValues(alpha: 0.7),
                        blurRadius: context.dp(28),
                        offset: const Offset(0, 14),
                        spreadRadius: -10,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.star_rounded,
                    color: Colors.white.withValues(alpha: 0.96),
                    size: context.dp(30),
                  ),
                ),
              ),
            ],
          ),
        ),
        AnimatedBuilder(
          animation: _count,
          builder: (context, _) {
            final t = Curves.easeOutCubic.transform(_count.value);
            final n = (widget.points * t).round();
            return Text(
              '+$n',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _goldText,
                fontWeight: FontWeight.w900,
                fontSize: 34,
                letterSpacing: 34 * -0.03,
                height: 1,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            );
          },
        ),
        SizedBox(height: context.dp(5)),
        Text(
          widget.label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _goldText,
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
            height: 1.2,
            letterSpacing: 12.5 * 0.01,
          ),
        ),
      ],
    );
  }
}
