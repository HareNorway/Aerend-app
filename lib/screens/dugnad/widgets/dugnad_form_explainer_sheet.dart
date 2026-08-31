import 'package:flutter/material.dart';

import '../../../theme/design_scale.dart';
import '../../../theme/ae_typography.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../../../ui/kit/ae_theme.dart';
import '../dugnad_form_utils.dart';
import '../../../ui/kit/ae_sheet.dart';
import '../gamification_models.dart';
import '../../../ui/kit/ae_subpage_shell.dart';

/// Form tempo explainer (prototype `PcFormSheet` in player-card.jsx).
class DugnadFormExplainerSheet extends StatelessWidget {
  const DugnadFormExplainerSheet({
    super.key,
    required this.status,
    this.history = const [],
    this.formValue = 70,
    this.floor = 40,
  });

  final DugnadFormStatus status;
  final List<GamificationFormPoint> history;
  final int formValue;
  final int floor;

  static Future<void> show(
    BuildContext context, {
    required DugnadFormStatus status,
    List<GamificationFormPoint> history = const [],
    int formValue = 70,
    int floor = 40,
  }) {
    return showAeSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.aeTheme.background,
      builder: (_) => DugnadFormExplainerSheet(
        status: status,
        history: history,
        formValue: formValue,
        floor: floor,
      ),
    );
  }

  String get _title {
    switch (status) {
      case DugnadFormStatus.up:
        return languages.dugnadFormWhyRisingTitle;
      case DugnadFormStatus.down:
        return languages.dugnadFormWhyFallingTitle;
      case DugnadFormStatus.flat:
        return languages.dugnadFormWhyFlatTitle;
    }
  }

  String get _statusLabel {
    switch (status) {
      case DugnadFormStatus.up:
        return languages.dugnadFormStatusUp;
      case DugnadFormStatus.flat:
        return languages.dugnadFormStatusFlat;
      case DugnadFormStatus.down:
        return languages.dugnadFormStatusDown;
    }
  }

  String get _statusDesc {
    switch (status) {
      case DugnadFormStatus.up:
        return languages.dugnadFormStateUpDesc;
      case DugnadFormStatus.flat:
        return languages.dugnadFormStateFlatDesc;
      case DugnadFormStatus.down:
        return languages.dugnadFormStateDownDesc;
    }
  }

  List<Color> get _gradient {
    switch (status) {
      case DugnadFormStatus.up:
        return const [Color(0xFF2BB673), Color(0xFF16794C)];
      case DugnadFormStatus.flat:
        return const [Color(0xFF7A7590), Color(0xFF565270)];
      case DugnadFormStatus.down:
        return const [Color(0xFFE6A93A), Color(0xFFC07F1C)];
    }
  }

  IconData get _statusIcon {
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
    final theme = context.aeTheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final sheetBg = theme.background;
    final radius = context.dp(kAeSheetRadius);
    final values = history.isNotEmpty
        ? history.map((p) => p.value.toDouble()).toList()
        : [formValue.toDouble()];

    return AeFixedTypography(
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
        child: ColoredBox(
          color: sheetBg,
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.88,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.dp(18),
                    context.dp(10),
                    context.dp(18),
                    0,
                  ),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          width: context.dp(42),
                          height: context.dp(4),
                          decoration: BoxDecoration(
                            color: theme.text.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      SizedBox(height: context.dp(14)),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _title,
                              style: aeH2().copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: theme.text,
                                letterSpacing: 20 * -0.02,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: context.dp(34),
                              height: context.dp(34),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: context.dp(18),
                                color: theme.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      context.dp(18),
                      context.dp(16),
                      context.dp(18),
                      context.dp(18) + bottomInset,
                    ),
                    children: [
                      _hero(context, values),
                      SizedBox(height: context.dp(14)),
                      _explainerBanner(context, theme),
                      SizedBox(height: context.dp(18)),
                      Text(
                        languages.dugnadFormLiftSection.toUpperCase(),
                        style: AeDugnadText.sectionLabel(),
                      ),
                      SizedBox(height: context.dp(10)),
                      _buildRow(
                        context,
                        icon: Icons.check_rounded,
                        title: languages.dugnadFormBuildLoginTitle,
                        subtitle: languages.dugnadFormBuildLoginSub,
                      ),
                      SizedBox(height: context.dp(8)),
                      _buildRow(
                        context,
                        icon: Icons.bolt_rounded,
                        title: languages.dugnadFormBuildMissionTitle,
                        subtitle: languages.dugnadFormBuildMissionSub,
                      ),
                      SizedBox(height: context.dp(8)),
                      _buildRow(
                        context,
                        icon: Icons.ios_share_rounded,
                        title: languages.dugnadFormBuildReferTitle,
                        subtitle: languages.dugnadFormBuildReferSub,
                      ),
                      SizedBox(height: context.dp(8)),
                      _buildRow(
                        context,
                        icon: Icons.local_fire_department_rounded,
                        title: languages.dugnadFormBuildStreakTitle,
                        subtitle: languages.dugnadFormBuildStreakSub,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero(BuildContext context, List<double> values) {
    return Container(
      padding: EdgeInsets.all(context.dp(18)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.dp(22)),
        gradient: LinearGradient(
          begin: const Alignment(-0.5, -0.85),
          end: const Alignment(0.5, 0.85),
          colors: _gradient,
          stops: const [0.0, 0.7],
        ),
        boxShadow: ScSaasThemeTokens.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: context.dp(52),
                height: context.dp(52),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(context.dp(16)),
                ),
                child: Icon(_statusIcon, color: Colors.white, size: context.dp(30)),
              ),
              SizedBox(width: context.dp(14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _statusLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                    SizedBox(height: context.dp(4)),
                    Text(
                      _statusDesc,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.dp(16)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              context.dp(14),
              context.dp(12),
              context.dp(14),
              context.dp(12),
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(context.dp(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  languages.dugnadFormSeasonGraphTitle.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                    letterSpacing: 10.5 * 0.08,
                  ),
                ),
                SizedBox(height: context.dp(12)),
                SizedBox(
                  height: context.dp(72),
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _FormSheetSparklinePainter(
                      values: values,
                      floor: floor.toDouble(),
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

  Widget _explainerBanner(BuildContext context, AeThemePalette theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.dp(13),
        context.dp(12),
        context.dp(13),
        context.dp(12),
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
          SizedBox(width: context.dp(9)),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                  color: theme.primaryHover,
                ),
                children: [
                  TextSpan(text: languages.dugnadFormArrowExplainerPrefix),
                  TextSpan(
                    text: languages.dugnadFormArrowExplainerBold,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: languages.dugnadFormArrowExplainerSuffix),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = context.aeTheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.dp(14),
        vertical: context.dp(13),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.dp(16)),
        boxShadow: [
          BoxShadow(
            color: theme.text.withValues(alpha: 0.05),
            blurRadius: context.dp(10),
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: context.dp(38),
            height: context.dp(38),
            decoration: BoxDecoration(
              color: theme.primaryTint,
              borderRadius: BorderRadius.circular(context.dp(12)),
            ),
            child: Icon(icon, size: context.dp(17), color: theme.primaryHover),
          ),
          SizedBox(width: context.dp(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: aeBody().copyWith(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: context.dp(2)),
                Text(subtitle, style: aeCaption()),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.dp(9),
              vertical: context.dp(4),
            ),
            decoration: BoxDecoration(
              color: const Color(0x2422A769),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star_rounded,
                  size: context.dp(11),
                  color: const Color(0xFF22A769),
                ),
                SizedBox(width: context.dp(3)),
                Text(
                  languages.dugnadFormBuildChip,
                  style: const TextStyle(
                    color: Color(0xFF22A769),
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
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

class _FormSheetSparklinePainter extends CustomPainter {
  _FormSheetSparklinePainter({
    required this.values,
    required this.floor,
  });

  final List<double> values;
  final double floor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final dataMin = values.reduce((a, b) => a < b ? a : b);
    final dataMax = values.reduce((a, b) => a > b ? a : b);
    var lo = (dataMin < floor ? dataMin : floor) - 4;
    var hi = dataMax + 4;
    if (hi - lo < 12) hi = lo + 12;
    lo = lo.clamp(0, 100).toDouble();
    hi = hi.clamp(lo + 12, 105).toDouble();

    final n = values.length;
    double dx(int i) => n == 1 ? size.width / 2 : size.width * (i / (n - 1));
    double dy(double v) =>
        size.height - ((v - lo) / (hi - lo)) * size.height;

    final path = Path();
    for (var i = 0; i < n; i++) {
      final p = Offset(dx(i), dy(values[i]));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FormSheetSparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.floor != floor;
}
