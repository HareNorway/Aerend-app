import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/ae_typography.dart';
import '../../../theme/design_scale.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../../../ui/kit/ae_theme.dart';
import '../../../ui/kit/ae_hourglass.dart';

class CampaignCountdownState {
  const CampaignCountdownState({
    required this.expired,
    required this.urgent,
    required this.parts,
    required this.deadline,
  });

  final bool expired;
  final bool urgent;
  final CampaignCountdownParts parts;
  final DateTime deadline;
}

class CampaignCountdownParts {
  const CampaignCountdownParts({
    required this.d,
    required this.h,
    required this.m,
    required this.s,
  });

  final int d;
  final int h;
  final int m;
  final int s;
}

CampaignCountdownState? campaignCountdownState(String? salesWindowEnd) {
  if (salesWindowEnd == null || salesWindowEnd.isEmpty) return null;
  final deadline = DateTime.tryParse(salesWindowEnd);
  if (deadline == null) return null;

  final ms = deadline.difference(DateTime.now()).inMilliseconds;
  final expired = ms <= 0;
  final urgent = !expired && ms < 24 * 3600 * 1000;
  return CampaignCountdownState(
    expired: expired,
    urgent: urgent,
    parts: _countdownParts(ms),
    deadline: deadline,
  );
}

CampaignCountdownParts _countdownParts(int ms) {
  final s = math.max(0, ms ~/ 1000);
  return CampaignCountdownParts(
    d: s ~/ 86400,
    h: (s % 86400) ~/ 3600,
    m: (s % 3600) ~/ 60,
    s: s % 60,
  );
}

/// Chip variant — mirrors `CampaignCountdown` variant `chip`.
class CampaignCountdownChip extends StatefulWidget {
  const CampaignCountdownChip({super.key, required this.salesWindowEnd});

  final String salesWindowEnd;

  @override
  State<CampaignCountdownChip> createState() => _CampaignCountdownChipState();
}

class _CampaignCountdownChipState extends State<CampaignCountdownChip> {
  @override
  void initState() {
    super.initState();
    _scheduleTick();
  }

  void _scheduleTick() {
    Future<void>.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {});
        _scheduleTick();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = campaignCountdownState(widget.salesWindowEnd);
    if (state == null) return const SizedBox.shrink();

    final theme = context.aeTheme;

    final chip = Container(
      padding: EdgeInsets.fromLTRB(context.dp(9), context.dp(5), context.dp(12), context.dp(5)),
      decoration: BoxDecoration(
        color: state.expired
            ? ScSaasThemeTokens.gray100
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(999),
        boxShadow: state.expired
            ? null
            : [
                BoxShadow(
                  color: theme.text.withValues(alpha: 0.25),
                  blurRadius: context.dp(6),
                  offset: const Offset(0, 2),
                  spreadRadius: -2,
                ),
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.expired)
            Icon(Icons.close_rounded, size: context.dp(13), color: ScSaasThemeTokens.gray500)
          else
            AeHourglass(
              size: context.dp(15),
              color: state.urgent ? theme.primaryHover : theme.primary,
              fast: state.urgent,
            ),
          SizedBox(width: context.dp(7)),
          CampaignCountdownTimeRow(
            parts: state.parts,
            expired: state.expired,
            urgent: state.urgent,
            textColor: theme.text,
            accentColor: theme.primary,
          ),
          if (!state.expired) ...[
            SizedBox(width: context.dp(4)),
            Text(
              languages.campaignCountdownLeft,
              style: aeCaption(
                // `.urgent .lbl` is --ae-error, not the brand purple. The
                // urgency state existed and its one colour override did not:
                // under 24h the chip looked exactly like every other chip.
                color: state.urgent
                    ? ScSaasThemeTokens.danger
                    : ScSaasThemeTokens.gray500,
              ).copyWith(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );

    if (state.urgent && !state.expired) {
      return AeCountdownPulse(color: theme.primary, child: chip);
    }
    return chip;
  }
}

/// Panel variant — mirrors `CampaignCountdown` variant `panel` / `.dg-cd-panel`.
class CampaignCountdownPanel extends StatefulWidget {
  const CampaignCountdownPanel({super.key, required this.salesWindowEnd});

  final String salesWindowEnd;

  @override
  State<CampaignCountdownPanel> createState() => _CampaignCountdownPanelState();
}

class _CampaignCountdownPanelState extends State<CampaignCountdownPanel> {
  @override
  void initState() {
    super.initState();
    _scheduleTick();
  }

  void _scheduleTick() {
    Future<void>.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {});
        _scheduleTick();
      }
    });
  }

  String _formatDeadline(DateTime deadline, bool isNo) {
    try {
      return DateFormat(isNo ? 'd. MMMM' : 'd MMMM', isNo ? 'nb_NO' : 'en_US')
          .format(deadline);
    } catch (_) {
      return deadline.toIso8601String();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = campaignCountdownState(widget.salesWindowEnd);
    if (state == null) return const SizedBox.shrink();

    final theme = context.aeTheme;
    final isNo = Localizations.localeOf(context).languageCode == 'no';
    final borderColor = state.expired
        ? ScSaasThemeTokens.gray100
        : state.urgent
            ? ScSaasThemeTokens.danger.withValues(alpha: 0.35)
            : theme.primaryTint;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.dp(16), vertical: context.dp(14)),
      decoration: BoxDecoration(
        color: state.expired
            ? ScSaasThemeTokens.gray50
            : Colors.white,
        borderRadius: BorderRadius.circular(context.dp(16)),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: state.expired
            ? [
                BoxShadow(
                  color: theme.text.withValues(alpha: 0.05),
                  blurRadius: context.dp(3),
                  offset: const Offset(0, 1),
                ),
              ]
            : [
                BoxShadow(
                  color: theme.primary.withValues(alpha: 0.5),
                  blurRadius: context.dp(26),
                  offset: const Offset(0, 10),
                  spreadRadius: -16,
                ),
                BoxShadow(
                  color: theme.text.withValues(alpha: 0.05),
                  blurRadius: context.dp(3),
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Row(
        children: [
          _PanelHourglass(
            expired: state.expired,
            urgent: state.urgent,
            gradient: theme.shinyGradient,
          ),
          SizedBox(width: context.dp(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _panelLabel(state),
                  style: aeOverline(
                    color: state.expired
                        ? ScSaasThemeTokens.gray700
                        : state.urgent
                            ? ScSaasThemeTokens.danger
                            : theme.primaryHover,
                  ).copyWith(
                    fontSize: context.dp(12),
                    letterSpacing: context.dp(12) * 0.04,
                  ),
                ),
                SizedBox(height: context.dp(3)),
                _PanelBigTime(
                  parts: state.parts,
                  expired: state.expired,
                  textColor: theme.text,
                ),
                SizedBox(height: context.dp(4)),
                Text(
                  state.expired
                      ? '${languages.campaignCountdownClosed} ${_formatDeadline(state.deadline, isNo)}'
                      : '${campaignStringsOrderBy()} ${_formatDeadline(state.deadline, isNo)}',
                  style: aeCaption(color: ScSaasThemeTokens.gray700).copyWith(
                    fontSize: context.dp(13),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _panelLabel(CampaignCountdownState state) {
    if (state.expired) {
      return languages.campaignCountdownDeadlinePassed;
    }
    if (state.urgent) {
      return languages.campaignCountdownLastDay;
    }
    return languages.campaignCountdownTimeLeft;
  }
}

String campaignStringsOrderBy() => languages.campaignOrderBy;

class _PanelHourglass extends StatelessWidget {
  const _PanelHourglass({
    required this.expired,
    required this.urgent,
    required this.gradient,
  });

  final bool expired;
  final bool urgent;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final badge = Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: context.dp(46),
          height: context.dp(46),
          decoration: BoxDecoration(
            gradient: expired ? null : gradient,
            color: expired ? ScSaasThemeTokens.gray100 : null,
            borderRadius: BorderRadius.circular(context.dp(13)),
            boxShadow: expired
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFF7F5FC4).withValues(alpha: 0.35),
                      blurRadius: context.dp(8),
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: expired
              ? Icon(
                  Icons.schedule_outlined,
                  color: ScSaasThemeTokens.gray500,
                  size: context.dp(22),
                )
              : Center(
                  child: AeHourglass(
                    size: context.dp(26),
                    color: Colors.white,
                    fast: urgent,
                  ),
                ),
        ),
        if (urgent && !expired)
          const Positioned(
            top: -3,
            right: -3,
            child: _UrgentPulseDot(),
          ),
      ],
    );

    return badge;
  }
}

class _UrgentPulseDot extends StatefulWidget {
  const _UrgentPulseDot();

  @override
  State<_UrgentPulseDot> createState() => _UrgentPulseDotState();
}

class _UrgentPulseDotState extends State<_UrgentPulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _ring;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _ring = Tween<double>(begin: 0, end: 7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  /// The controller used to start in initState and be hidden in build,
  /// which leaves it running under reduced motion with a frame
  /// permanently scheduled. Gating in build is not gating (rule 16).
  bool _motionStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      if (_controller.isAnimating) _controller.stop();
      _controller.value = 0;
      _motionStarted = false;
      return;
    }
    if (_motionStarted) return;
    _motionStarted = true;
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Container(
        width: context.dp(11),
        height: context.dp(11),
        decoration: BoxDecoration(
          color: ScSaasThemeTokens.danger,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _ring,
      builder: (context, child) {
        final t = _controller.value;
        final ringOpacity = t < 0.7 ? (1 - t / 0.7) * 0.55 : 0.0;
        return Stack(
          alignment: Alignment.center,
          children: [
            if (ringOpacity > 0)
              Container(
                width: context.dp(11) + _ring.value * 2,
                height: context.dp(11) + _ring.value * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ScSaasThemeTokens.danger.withValues(alpha: ringOpacity),
                    width: 2,
                  ),
                ),
              ),
            child!,
          ],
        );
      },
      child: Container(
        width: context.dp(11),
        height: context.dp(11),
        decoration: BoxDecoration(
          color: ScSaasThemeTokens.danger,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }
}

class _PanelBigTime extends StatelessWidget {
  const _PanelBigTime({
    required this.parts,
    required this.expired,
    required this.textColor,
  });

  final CampaignCountdownParts parts;
  final bool expired;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    if (expired) {
      return Text(
        languages.campaignCountdownClosed,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: ScSaasThemeTokens.gray500,
          letterSpacing: 22 * -0.02,
        ),
      );
    }

    final segments = <Widget>[];
    if (parts.d >= 1) {
      segments.addAll([
        _bigSeg(context, parts.d, 'd'),
        _bigSeg(context, parts.h, 't'),
        _bigSeg(context, parts.m, 'm'),
      ]);
    } else if (parts.h >= 1) {
      segments.addAll([
        _bigSeg(context, parts.h, 't'),
        _bigSeg(context, parts.m, 'm'),
        _bigSeg(context, parts.s, 's'),
      ]);
    } else {
      segments.addAll([
        _bigSeg(context, parts.m, 'm'),
        _bigSeg(context, parts.s, 's', pad: true),
      ]);
    }

    return Row(children: segments);
  }

  Widget _bigSeg(BuildContext context, int value, String unit, {bool pad = false}) {
    final text = pad ? value.toString().padLeft(2, '0') : '$value';
    final numSize = context.dp(24);
    final unitSize = context.dp(15);
    return Padding(
      padding: EdgeInsets.only(right: context.dp(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: numSize,
              fontWeight: FontWeight.w900,
              color: textColor,
              letterSpacing: numSize * -0.02,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: unitSize,
              fontWeight: FontWeight.w800,
              color: ScSaasThemeTokens.gray700,
            ),
          ),
        ],
      ),
    );
  }
}

class CampaignCountdownTimeRow extends StatelessWidget {
  const CampaignCountdownTimeRow({
    super.key,
    required this.parts,
    required this.expired,
    required this.urgent,
    required this.textColor,
    required this.accentColor,
  });

  final CampaignCountdownParts parts;
  final bool expired;
  final bool urgent;
  final Color textColor;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    if (expired) {
      return Text(
        languages.campaignCountdownClosed,
        style: aeOverline(color: ScSaasThemeTokens.gray500).copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 12 * 0.02,
        ),
      );
    }

    final segments = <Widget>[];
    if (parts.d >= 1) {
      segments.addAll([
        _seg(parts.d, 'd', urgent),
        _seg(parts.h, 't', urgent),
        _seg(parts.m, 'm', urgent),
      ]);
    } else if (parts.h >= 1) {
      segments.addAll([
        _seg(parts.h, 't', urgent),
        _seg(parts.m, 'm', urgent),
        _seg(parts.s, 's', urgent, highlight: urgent),
      ]);
    } else {
      segments.addAll([
        _seg(parts.m, 'm', urgent),
        _seg(parts.s, 's', urgent, highlight: urgent),
      ]);
    }

    return Row(mainAxisSize: MainAxisSize.min, children: segments);
  }

  Widget _seg(int value, String unit, bool urgent, {bool highlight = false}) {
    return Padding(
      padding: EdgeInsets.only(right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 13 * -0.01,
              color: highlight ? accentColor : textColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: (highlight ? accentColor : textColor).withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
