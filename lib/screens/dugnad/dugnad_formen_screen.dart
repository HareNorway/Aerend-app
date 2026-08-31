import 'package:flutter/material.dart';

import '../../theme/design_scale.dart';
import 'package:flutter/services.dart';

import '../../commonView/skeleton_loaders/dugnad_subpage_skeletons.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/utils.dart';
import 'dugnad_club_branding.dart';
import '../../ui/kit/ae_theme.dart';
import 'dugnad_form_utils.dart';
import 'dugnad_missions_screen.dart';
import 'dugnad_repo.dart';
import 'dugnad_state.dart';
import 'gamification_models.dart';
import 'referral_share_screen.dart';
import 'supporter_card_screen.dart';
import '../../ui/kit/ae_subpage_shell.dart';
import '../../ui/kit/ae_rise_in.dart';

/// "Formen din" — season form tempo screen with an activity line graph,
/// preview toggles and the activities that build form (aerend-sto spec §3, form
/// is a cosmetic tempo indicator built purely on in-app activity).
class DugnadFormenScreen extends StatefulWidget {
  const DugnadFormenScreen({super.key});

  @override
  State<DugnadFormenScreen> createState() => _DugnadFormenScreenState();
}

class _DugnadFormenScreenState extends State<DugnadFormenScreen> {
  final DugnadRepo _repo = DugnadRepo();
  GamificationConfig? _config;
  GamificationProgress? _progress;
  bool _loading = true;
  bool _recording = false;

  /// Preview override (null = show the real state).
  DugnadFormStatus? _preview;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final clubId = DugnadState.instance.clubId;
      final teamId = DugnadState.instance.pointsTeamId;
      final config = await _repo.getGamificationConfig(
        organizationId: clubId > 0 ? clubId : null,
        teamId: teamId > 0 ? teamId : null,
      );
      final progress = await _repo.getGamificationProgress(
        organizationId: clubId > 0 ? clubId : null,
        teamId: teamId > 0 ? teamId : null,
      );
      if (!mounted) return;
      setState(() {
        _config = config;
        _progress = progress;
        _loading = false;
        if (progress != null &&
            _actualStatusFrom(progress) == DugnadFormStatus.up) {
          _preview = null;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  DugnadFormStatus _actualStatusFrom(GamificationProgress progress) {
    switch (progress.formState) {
      case 'up':
        return DugnadFormStatus.up;
      case 'down':
        return DugnadFormStatus.down;
      case 'flat':
        return DugnadFormStatus.flat;
      default:
        return dugnadFormStatusFromProgress(
          progress,
          warningThreshold: progress.formWarningThreshold,
        );
    }
  }

  DugnadFormStatus get _actualStatus {
    final progress = _progress;
    if (progress == null) return DugnadFormStatus.flat;
    return _actualStatusFrom(progress);
  }

  bool get _previewLocked => _actualStatus == DugnadFormStatus.up;

  DugnadFormStatus get _displayStatus => _preview ?? _actualStatus;

  Future<void> _recordLogin() async {
    if (_recording) return;
    setState(() => _recording = true);
    try {
      await _repo.recordGamificationActivity('login');
    } catch (_) {}
    if (!mounted) return;
    setState(() => _recording = false);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final clubName = DugnadClubBranding.fullName();
    final clubLogo = DugnadState.instance.clubLogo.isEmpty
        ? null
        : DugnadState.instance.clubLogo;

    return AeFixedTypography(
      child: Scaffold(
        backgroundColor: context.aeTheme.primary,
        body: AeScrollBody(
          hero: AeHero(
            clubName: clubName,
            clubLogo: clubLogo,
            title: languages.dugnadFormPageTitle,
            subtitle: languages.dugnadFormPageSubtitle,
            subtitleWithClock: true,
            onBack: () => Navigator.of(context).pop(),
          ),
          bottomPadding: 40,
          itemGap: 14,
          topPadding: 18,
          feedRadius: 22,
          overlap: 12,
          children: _loading
              ? const [DugnadFormenSkeleton()]
              : _buildFeed(),
        ),
      ),
    );
  }

  List<Widget> _buildFeed() {
    final progress = _progress;
    if (progress == null || progress.teamRequired) {
      return [
        AeRiseIn(
          key: const ValueKey('formenTeamRequired'),
          delay: const Duration(milliseconds: 120),
          child: _plainCard(
            child: Text(
              languages.dugnadFormTeamRequired,
              style: aeBody(color: ScSaasThemeTokens.gray700),
            ),
          ),
        ),
      ];
    }

    final status = _displayStatus;
    // Entrance stagger (`au-rise`): 120ms then ~70ms apart, trailing block at
    // 550ms. Keys keep the animation state stable when the preview chips
    // toggle `status` and the warning banner appears/disappears.
    return [
      AeRiseIn(
        key: const ValueKey('formenStateCard'),
        delay: const Duration(milliseconds: 120),
        child: _FormStateCard(
          status: status,
          history: progress.formHistory,
          formValue: progress.formValue,
          floor: progress.formFloor,
        ),
      ),
      AeRiseIn(
        key: const ValueKey('formenPreviewChips'),
        delay: const Duration(milliseconds: 190),
        child: _previewChips(),
      ),
      if (status != DugnadFormStatus.up)
        AeRiseIn(
          key: const ValueKey('formenWarning'),
          delay: const Duration(milliseconds: 260),
          child: _warningBanner(),
        ),
      AeRiseIn(
        key: const ValueKey('formenBuildSection'),
        delay: const Duration(milliseconds: 330),
        child: AeSectionBlock(
          label: languages.dugnadFormBuildSection,
          children: _buildRows(),
        ),
      ),
      AeRiseIn(
        key: const ValueKey('formenInfo'),
        delay: const Duration(milliseconds: 400),
        duration: const Duration(milliseconds: 550),
        child: _infoBanner(),
      ),
    ];
  }

  Widget _previewChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _previewChip(DugnadFormStatus.up)),
            SizedBox(width: context.dp(8)),
            Expanded(child: _previewChip(DugnadFormStatus.flat)),
            SizedBox(width: context.dp(8)),
            Expanded(child: _previewChip(DugnadFormStatus.down)),
          ],
        ),
        if (!_previewLocked) ...[
          SizedBox(height: context.dp(8)),
          Center(
            child: Text(
              languages.dugnadFormPreviewHint,
              style: aeCaption(color: ScSaasThemeTokens.gray500)
                  .copyWith(fontSize: 11.5),
            ),
          ),
        ],
      ],
    );
  }

  Widget _previewChip(DugnadFormStatus status) {
    final selected = _displayStatus == status;
    final palette = _statePalette(status);
    final disabled =
        _previewLocked && status != DugnadFormStatus.up;
    return GestureDetector(
      onTap: disabled
          ? null
          : () => setState(() {
                HapticFeedback.lightImpact();
                _preview = status == _actualStatus ? null : status;
              }),
      child: Opacity(
        opacity: disabled ? 0.42 : 1,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        // `.pv { padding: 10px 6px; border-radius: 13px;
        //   border: 1.5px solid var(--ae-gray-100) }`
        padding: EdgeInsets.symmetric(
          horizontal: context.dp(6),
          vertical: context.dp(10),
        ),
        decoration: BoxDecoration(
          color: selected ? palette.tint : Colors.white,
          borderRadius: BorderRadius.circular(context.dp(13)),
          border: Border.all(
            color: selected ? palette.accent : ScSaasThemeTokens.border,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _stateIcon(status),
              size: context.dp(17),
              color: selected ? palette.accent : ScSaasThemeTokens.gray500,
            ),
            SizedBox(width: context.dp(5)),
            Flexible(
              child: Text(
                _stateLabel(status),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: aeCaption(
                  color: selected ? palette.text : ScSaasThemeTokens.gray500,
                ).copyWith(fontWeight: FontWeight.w800, fontSize: 12.5),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _warningBanner() {
    return GestureDetector(
      onTap: () => openScreen(context, const DugnadMissionsScreen()),
      child: Container(
        // `.dg-form-warn { border: 1.5px solid rgba(224,169,58,.4);
        //   background: rgba(224,169,58,.1); border-radius: 16px;
        //   padding: 13px 14px }` -- both colours translucent, so they tint
        // whatever sits behind them rather than sitting on it.
        padding: EdgeInsets.symmetric(
          horizontal: context.dp(14),
          vertical: context.dp(13),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFE0A93A).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(context.dp(16)),
          border: Border.all(
            color: const Color(0xFFE0A93A).withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              // `.ic` is 38x38, radius 11, on --ae-warning.
              width: context.dp(38),
              height: context.dp(38),
              decoration: BoxDecoration(
                color: ScSaasThemeTokens.warning,
                borderRadius: BorderRadius.circular(context.dp(11)),
              ),
              child: Icon(Icons.bolt_rounded,
                  color: Colors.white, size: context.dp(22)),
            ),
            SizedBox(width: context.dp(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    languages.dugnadFormWarningTitle,
                    // `.dg-form-warn .tx .t` is 14 / 800 / --ae-midnight --
                    // the card is tinted amber, the heading is not.
                    style: aeBody(color: ScSaasThemeTokens.text)
                        .copyWith(fontWeight: FontWeight.w800, fontSize: 14)
                        .dp(context),
                  ),
                  SizedBox(height: context.dp(2)),
                  Text(
                    languages.dugnadFormWarningSub,
                    style: aeCaption(color: const Color(0xFFAE8434))
                        .copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFC79A45)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRows() {
    final form = _config?.modules?.form;
    return [
      _FormBuildRow(
        icon: Icons.check_rounded,
        title: languages.dugnadFormBuildLoginTitle,
        subtitle: languages.dugnadFormBuildLoginSub,
        formPoints: form?.ruleFor('login')?.formPoints ?? 0,
        onTap: _recording ? null : _recordLogin,
      ),
      _FormBuildRow(
        icon: Icons.bolt_rounded,
        title: languages.dugnadFormBuildMissionTitle,
        subtitle: languages.dugnadFormBuildMissionSub,
        formPoints: 0,
        onTap: () => openScreen(context, const DugnadMissionsScreen()),
      ),
      _FormBuildRow(
        icon: Icons.share_outlined,
        title: languages.dugnadFormBuildReferTitle,
        subtitle: languages.dugnadFormBuildReferSub,
        formPoints: form?.ruleFor('referral')?.formPoints ?? 0,
        onTap: () => openScreen(context, const ReferralShareScreen()),
      ),
      _FormBuildRow(
        icon: Icons.science_outlined,
        title: languages.dugnadFormBuildShareTitle,
        subtitle: languages.dugnadFormBuildShareSub,
        formPoints: form?.ruleFor('card_shared')?.formPoints ?? 0,
        onTap: () => openScreen(context, const SupporterCardScreen()),
      ),
      _FormBuildRow(
        icon: Icons.local_fire_department_rounded,
        title: languages.dugnadFormBuildStreakTitle,
        subtitle: languages.dugnadFormBuildStreakSub,
        formPoints: 0,
        onTap: () => openScreen(context, const DugnadMissionsScreen()),
      ),
    ];
  }

  Widget _infoBanner() {
    return Container(
      padding: EdgeInsets.fromLTRB(context.dp(12), context.dp(12), context.dp(12), context.dp(12)),
      decoration: BoxDecoration(
        color: context.aeTheme.primaryTint,
        borderRadius: BorderRadius.circular(context.dp(14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: context.dp(17), color: context.aeTheme.primary),
          SizedBox(width: context.dp(9)),
          Expanded(
            child: Text(
              languages.dugnadFormInfoBanner,
              style: aeCaption(color: ScSaasThemeTokens.gray700)
                  .copyWith(fontSize: 12, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _plainCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.dp(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.dp(18)),
      ),
      child: child,
    );
  }

  String _stateLabel(DugnadFormStatus status) {
    switch (status) {
      case DugnadFormStatus.up:
        return languages.dugnadFormStatusUp;
      case DugnadFormStatus.flat:
        return languages.dugnadFormStatusFlat;
      case DugnadFormStatus.down:
        return languages.dugnadFormStatusDown;
    }
  }

  IconData _stateIcon(DugnadFormStatus status) {
    switch (status) {
      case DugnadFormStatus.up:
        return Icons.keyboard_arrow_up_rounded;
      case DugnadFormStatus.flat:
        return Icons.trending_flat_rounded;
      case DugnadFormStatus.down:
        return Icons.keyboard_arrow_down_rounded;
    }
  }
}

class _StatePalette {
  const _StatePalette({
    required this.accent,
    required this.text,
    required this.tint,
    required this.gradient,
  });

  /// `.pv.on.tone-*`'s `border-color` -- also the icon.
  final Color accent;

  /// `.pv.on.tone-*`'s `color`. A **third** role: the design uses a darker,
  /// more readable value for text than for the border, and the app was
  /// reusing `accent` for both. Three roles per tone, not two.
  final Color text;

  /// `.pv.on.tone-*`'s `background`. Note the alphas differ per tone --
  /// .08 on green, .10 on the other two -- so a single constant is wrong.
  final Color tint;

  final List<Color> gradient;
}

_StatePalette _statePalette(DugnadFormStatus status) {
  switch (status) {
    case DugnadFormStatus.up:
      return const _StatePalette(
        accent: Color(0xFF2BB673),
        text: Color(0xFF12724A),
        tint: Color(0x1422A769), // rgba(34,167,105,.08)
        // `.dg-form-hero.tone-green .fh-bg`
        gradient: [Color(0xFF2BB673), Color(0xFF16794C)],
      );
    case DugnadFormStatus.flat:
      return const _StatePalette(
        accent: Color(0xFF8A86A0),
        text: Color(0xFF4A4560),
        tint: Color(0x1A8A86A0), // rgba(138,134,160,.1)
        gradient: [Color(0xFF7A7590), Color(0xFF565270)],
      );
    case DugnadFormStatus.down:
      return const _StatePalette(
        accent: Color(0xFFE0A93A),
        text: Color(0xFF8A5A12),
        tint: Color(0x1AE0A93A), // rgba(224,169,58,.1)
        gradient: [Color(0xFFE6A93A), Color(0xFFC07F1C)],
      );
  }
}

/// Big colored form-state card with the season activity line graph.
class _FormStateCard extends StatelessWidget {
  const _FormStateCard({
    required this.status,
    required this.history,
    required this.formValue,
    required this.floor,
  });

  final DugnadFormStatus status;
  final List<GamificationFormPoint> history;
  final int formValue;
  final int floor;

  String _title() {
    switch (status) {
      case DugnadFormStatus.up:
        return languages.dugnadFormStatusUp;
      case DugnadFormStatus.flat:
        return languages.dugnadFormStatusFlat;
      case DugnadFormStatus.down:
        return languages.dugnadFormStatusDown;
    }
  }

  String _desc() {
    switch (status) {
      case DugnadFormStatus.up:
        return languages.dugnadFormStateUpDesc;
      case DugnadFormStatus.flat:
        return languages.dugnadFormStateFlatDesc;
      case DugnadFormStatus.down:
        return languages.dugnadFormStateDownDesc;
    }
  }

  IconData _icon() {
    switch (status) {
      case DugnadFormStatus.up:
        return Icons.keyboard_arrow_up_rounded;
      case DugnadFormStatus.flat:
        return Icons.trending_flat_rounded;
      case DugnadFormStatus.down:
        return Icons.keyboard_arrow_down_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = _statePalette(status);
    // Always plot backend season history; fall back to the current form value.
    final values = history.isNotEmpty
        ? history.map((p) => p.value.toDouble()).toList()
        : [formValue.toDouble()];

    return Container(
      width: double.infinity,
      // `.dg-form-hero { border-radius: 22px; padding: 18px;
      //   box-shadow: var(--ae-shadow-card) }`, with the tone gradient at
      //   150deg and its second stop at 70%.
      padding: EdgeInsets.all(context.dp(18)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.dp(22)),
        gradient: LinearGradient(
          begin: const Alignment(-0.5, -0.85),
          end: const Alignment(0.5, 0.85),
          colors: palette.gradient,
          stops: const [0.0, 0.7],
        ),
        // --ae-shadow-card is three layers, and the first is a hairline ring.
        // A single tinted drop reads floaty where the ring makes it crisp
        // (rule 4).
        boxShadow: ScSaasThemeTokens.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // `.dg-form-hero .dg-formarrow` is 52x52, radius 16,
              // rgba(255,255,255,.2), with an inset highlight.
              Container(
                width: context.dp(52),
                height: context.dp(52),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(context.dp(16)),
                ),
                child: Stack(
                  children: [
                    // `0 1px 1px rgba(255,255,255,.4) inset`
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(context.dp(16)),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0.4),
                                Colors.white.withValues(alpha: 0),
                              ],
                              stops: const [0.0, 0.04],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Icon(_icon(),
                          color: Colors.white, size: context.dp(28)),
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.dp(14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title(),
                      style: aeBody(color: Colors.white).copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        height: context.dp(1.1),
                      ),
                    ),
                    SizedBox(height: context.dp(4)),
                    Text(
                      _desc(),
                      style: aeCaption(
                        color: Colors.white.withValues(alpha: 0.95),
                      ).copyWith(fontWeight: FontWeight.w600, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.dp(16)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(context.dp(14), context.dp(12), context.dp(14), context.dp(12)),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(context.dp(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  languages.dugnadFormSeasonGraphTitle.toUpperCase(),
                  style: aeCaption(
                    color: Colors.white.withValues(alpha: 0.8),
                  ).copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                    letterSpacing: 10.5 * 0.08,
                  ),
                ),
                SizedBox(height: context.dp(12)),
                SizedBox(
                  height: context.dp(92),
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _FormSeasonLinePainter(
                      values: values,
                      floor: floor.toDouble(),
                      lineColor: Colors.white,
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

class _FormSeasonLinePainter extends CustomPainter {
  _FormSeasonLinePainter({
    required this.values,
    required this.floor,
    required this.lineColor,
  });

  final List<double> values;
  final double floor;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    // Domain: a little below the floor up to the max (100 ceiling).
    final dataMin = values.reduce((a, b) => a < b ? a : b);
    final dataMax = values.reduce((a, b) => a > b ? a : b);
    var lo = (dataMin < floor ? dataMin : floor) - 4;
    var hi = dataMax + 4;
    if (hi - lo < 12) hi = lo + 12;
    lo = lo.clamp(0, 100).toDouble();
    hi = hi.clamp(lo + 12, 105).toDouble();

    final n = values.length;
    double dx(int i) =>
        n == 1 ? size.width / 2 : size.width * (i / (n - 1));
    double dy(double v) =>
        size.height - ((v - lo) / (hi - lo)) * size.height;

    final points = <Offset>[
      for (var i = 0; i < n; i++) Offset(dx(i), dy(values[i])),
    ];

    // Smooth line path (midpoint quadratic smoothing).
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    if (points.length == 1) {
      linePath.lineTo(points.first.dx, points.first.dy);
    } else {
      for (var i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
        linePath.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
      }
      linePath.lineTo(points.last.dx, points.last.dy);
    }

    // Gradient fill under the curve.
    final fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.28),
          lineColor.withValues(alpha: 0.0),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = lineColor.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    // End dot.
    final last = points.last;
    canvas.drawCircle(
      last,
      6,
      Paint()..color = lineColor.withValues(alpha: 0.25),
    );
    canvas.drawCircle(last, 3.4, Paint()..color = lineColor);
  }

  @override
  bool shouldRepaint(covariant _FormSeasonLinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.floor != floor ||
        oldDelegate.lineColor != lineColor;
  }
}

/// White row in the "Slik bygger du form" list.
class _FormBuildRow extends StatelessWidget {
  const _FormBuildRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.formPoints,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int formPoints;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    // `.lb-ways .ic` → club tint + hover (same treatment for every builder row).

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: context.dp(8)),
        padding: EdgeInsets.symmetric(horizontal: context.dp(13), vertical: context.dp(12)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.dp(16)),
          boxShadow: [
            BoxShadow(
              color: theme.text.withValues(alpha: 0.05),
              blurRadius: context.dp(4),
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: context.dp(42),
              height: context.dp(42),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(context.dp(12)),
                color: theme.primaryTint,
              ),
              child: Icon(icon, size: context.dp(21), color: theme.primaryHover),
            ),
            SizedBox(width: context.dp(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: aeBody().copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                    ),
                  ),
                  SizedBox(height: context.dp(1)),
                  Text(
                    subtitle,
                    style: aeCaption(color: ScSaasThemeTokens.gray500)
                        .copyWith(fontSize: 12.5),
                  ),
                ],
              ),
            ),
            SizedBox(width: context.dp(8)),
            Container(
              padding: EdgeInsets.symmetric(horizontal: context.dp(10), vertical: context.dp(5)),
              decoration: BoxDecoration(
                color: const Color(0xFFE5F4EC),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                formPoints > 0
                    ? languages.dugnadFormBuildChipPoints(formPoints)
                    : languages.dugnadFormBuildChip,
                style: aeCaption(color: const Color(0xFF1D8D5F))
                    .copyWith(fontWeight: FontWeight.w900, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
