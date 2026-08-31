import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../commonView/skeleton_loaders/dugnad_subpage_skeletons.dart';
import '../../theme/design_scale.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/utils.dart';
import 'donation_fee_calculator.dart';
import 'donation_setup_screen.dart';
import 'dugnad_models.dart';
import 'dugnad_repo.dart';
import 'dugnad_state.dart';
import 'widgets/dugnad_subpage_shell.dart';
import 'widgets/dugnad_rise_in.dart';
import 'dugnad_club_theme.dart';

/// Manage active Fast støtte subscriptions (prototype: DonateStatusScreen).
class DonationManageScreen extends StatefulWidget {
  const DonationManageScreen({super.key});

  static const int maxTeams = 3;

  @override
  State<DonationManageScreen> createState() => _DonationManageScreenState();
}

class _DonationManageScreenState extends State<DonationManageScreen> {
  final DugnadRepo _repo = DugnadRepo();
  List<DonationSubscriptionRecord> _subscriptions = [];
  bool _loading = true;
  int? _cancellingId;
  int? _pausingId;
  int? _confirmCancelId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _repo.listDonationSubscriptions();
      if (mounted) setState(() => _subscriptions = list);
    } catch (_) {
      if (mounted) openSimpleSnackbar(languages.dugnadDonationLoadFailed);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<DonationSubscriptionRecord> get _active =>
      _subscriptions.where((s) => s.isManageable).toList();

  int get _activeTotalKr => _active
      .where((s) => !s.isPaused)
      .fold<int>(0, (sum, s) => sum + s.amountKr.round());

  bool get _canAdd => _active.length < DonationManageScreen.maxTeams;

  Future<void> _cancel(DonationSubscriptionRecord sub) async {
    HapticFeedback.mediumImpact();
    setState(() {
      _confirmCancelId = null;
      _cancellingId = sub.id;
    });
    try {
      final ok = await _repo.cancelDonationSubscription(sub.id);
      if (!mounted) return;
      if (ok) {
        openSimpleSnackbar(languages.dugnadDonationCancelSuccess);
        await _load();
      } else {
        openSimpleSnackbar(languages.dugnadDonationCancelFailed);
      }
    } catch (_) {
      if (mounted) openSimpleSnackbar(languages.dugnadDonationCancelFailed);
    } finally {
      if (mounted) setState(() => _cancellingId = null);
    }
  }

  String _formatNextCharge(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat.MMMMd(languages.localeName).format(parsed.toLocal());
  }

  Future<void> _togglePause(DonationSubscriptionRecord sub) async {
    HapticFeedback.mediumImpact();
    setState(() => _pausingId = sub.id);
    try {
      final ok = sub.isPaused
          ? await _repo.resumeDonationSubscription(sub.id)
          : await _repo.pauseDonationSubscription(sub.id);
      if (!mounted) return;
      if (ok) {
        openSimpleSnackbar(
          sub.isPaused
              ? languages.dugnadDonationResumeSuccess
              : languages.dugnadDonationPauseSuccess,
        );
        await _load();
      } else {
        openSimpleSnackbar(
          sub.isPaused
              ? languages.dugnadDonationResumeFailed
              : languages.dugnadDonationPauseFailed,
        );
      }
    } catch (_) {
      if (mounted) {
        openSimpleSnackbar(
          sub.isPaused
              ? languages.dugnadDonationResumeFailed
              : languages.dugnadDonationPauseFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _pausingId = null);
    }
  }

  String _subtitleFor(DonationSubscriptionRecord sub) {
    if (sub.isPaused) {
      return languages.dugnadDonationManageSubLinePaused(sub.amountKr.round());
    }
    return languages.dugnadDonationManageSubLine(
      sub.amountKr.round(),
      _formatNextCharge(sub.nextChargeAt),
    );
  }

  String _statusLabelFor(DonationSubscriptionRecord sub) {
    if (sub.isPaused) return languages.dugnadDonationStatusPaused;
    if (sub.isPending) return languages.dugnadDonationStatusPending;
    return languages.dugnadDonationStatusActive;
  }

  void _showCancelSheet(DonationSubscriptionRecord sub) {
    HapticFeedback.lightImpact();
    setState(() => _confirmCancelId = sub.id);
  }

  @override
  Widget build(BuildContext context) {
    final clubName = DugnadState.instance.clubName.isNotEmpty
        ? DugnadState.instance.clubName
        : languages.dugnadChooseClubFirst;
    final clubLogo = DugnadState.instance.clubLogo;
    final active = _active;
    DonationSubscriptionRecord? pendingCancel;
    if (_confirmCancelId != null) {
      for (final sub in active) {
        if (sub.id == _confirmCancelId) {
          pendingCancel = sub;
          break;
        }
      }
    }

    final feedChildren = _buildFeedChildren(active);

    return DugnadFixedTypography(
      child: Scaffold(
        backgroundColor: context.dugnadTheme.primary,
        body: Stack(
          children: [
            DugnadLbScrollBody(
              hero: DugnadLbHero(
                clubName: clubName,
                clubLogo: clubLogo,
                title: languages.dugnadDonationManageHeroTitle,
                onBack: () => Navigator.pop(context),
              ),
              bottomPadding: 100,
              itemGap: 14,
              topPadding: 18,
              feedRadius: 22,
              overlap: 12,
              children: _loading
                  ? const [DugnadDonationSkeleton()]
                  : feedChildren,
            ),
            if (pendingCancel != null)
              _DonationCancelSheet(
                onDismiss: () => setState(() => _confirmCancelId = null),
                onConfirm: () => _cancel(pendingCancel!),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFeedChildren(List<DonationSubscriptionRecord> active) {
    return [
      _riseIn(0,
        _DonationManageSummaryCard(
          teamCount: active.length,
          maxTeams: DonationManageScreen.maxTeams,
          totalKr: _activeTotalKr,
        ),
      ),
      for (var i = 0; i < active.length; i++)
        _riseIn(i + 1,
          _DonationSubCard(
            subscription: active[i],
            subtitle: _subtitleFor(active[i]),
            statusLabel: _statusLabelFor(active[i]),
            isPending: active[i].isPending,
            isPaused: active[i].isPaused,
            isCancelling: _cancellingId == active[i].id,
            isPausing: _pausingId == active[i].id,
            onChange: () async {
              final updated = await openScreenWithResult(
                context,
                DonationSetupScreen(editing: active[i]),
              );
              if (updated == true && mounted) {
                await _load();
              }
            },
            onPause: () => _togglePause(active[i]),
            onExit: () => _showCancelSheet(active[i]),
          ),
        ),
      _riseIn(active.length + 1,
        _canAdd
            ? _DonationAddTeamCard(
                onTap: () => openScreen(context, const DonationSetupScreen()),
              )
            : _DonationMaxTeamsNote(),
      ),
      _riseIn(active.length + 2,
        Text(
          languages.dugnadDonationManageChangesNote,
          style: AeDugnadText.bannerSubtitle(),
        ),
      ),
    ];
  }
}

class _DonationManageSummaryCard extends StatelessWidget {
  const _DonationManageSummaryCard({
    required this.teamCount,
    required this.maxTeams,
    required this.totalKr,
  });

  final int teamCount;
  final int maxTeams;
  final int totalKr;

  @override
  Widget build(BuildContext context) {
    final totalFormatted = NumberFormat.decimalPattern(languages.localeName)
        .format(totalKr);

    return Container(
      padding: EdgeInsets.fromLTRB(context.dp(16), context.dp(14), context.dp(16), context.dp(14)),
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
      child: Row(
        children: [
          Expanded(
            child: _SummaryBlock(
              label: languages.dugnadDonationManageYouSupport,
              value: '$teamCount',
              suffix: languages.dugnadDonationManageOfTeams(maxTeams),
            ),
          ),
          Expanded(
            child: _SummaryBlock(
              label: languages.dugnadDonationManageTotal,
              value: totalFormatted,
              suffix: languages.dugnadDonationManageKrPerMonthShort,
              alignRight: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryBlock extends StatelessWidget {
  const _SummaryBlock({
    required this.label,
    required this.value,
    required this.suffix,
    this.alignRight = false,
  });

  final String label;
  final String value;
  final String suffix;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AeDugnadText.sectionLabel(),
        ),
        SizedBox(height: context.dp(4)),
        RichText(
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
          text: TextSpan(
            style: const TextStyle(height: 1.1),
            children: [
              TextSpan(
                text: value,
                style: AeDugnadText.clubStatValue(),
              ),
              TextSpan(
                text: ' $suffix',
                style: AeDugnadText.clubStatKr(
                  // `.dn-sum .v span` is a neutral gray-500 suffix, not a
                  // themed accent — the tint belongs to the surface, not this
                  // secondary label.
                  color: ScSaasThemeTokens.gray500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DonationSubCard extends StatelessWidget {
  const _DonationSubCard({
    required this.subscription,
    required this.subtitle,
    required this.statusLabel,
    required this.isPending,
    required this.isPaused,
    required this.isCancelling,
    required this.isPausing,
    required this.onChange,
    required this.onPause,
    required this.onExit,
  });

  final DonationSubscriptionRecord subscription;
  final String subtitle;
  final String statusLabel;
  final bool isPending;
  final bool isPaused;
  final bool isCancelling;
  final bool isPausing;
  final VoidCallback onChange;
  final VoidCallback onPause;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final amountKr = subscription.amountKr.round();
    final points = DonationFeeCalculator.previewPointsForAmountKr(amountKr);
    final isOrg = subscription.beneficiaryType == 'organization';
    final theme = context.dugnadTheme;

    return Opacity(
      opacity: isPaused ? 0.82 : 1,
      child: Container(
      padding: EdgeInsets.fromLTRB(context.dp(14), context.dp(13), context.dp(14), context.dp(13)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.dp(16)),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0D2D1B5B),
            blurRadius: context.dp(4),
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Color(0x4D2D1B5B),
            blurRadius: context.dp(24),
            spreadRadius: -18,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: context.dp(40),
                height: context.dp(40),
                decoration: BoxDecoration(
                  color: theme.primaryTint,
                  borderRadius: BorderRadius.circular(context.dp(12)),
                ),
                child: Icon(
                  isOrg ? Icons.favorite_rounded : Icons.shield_outlined,
                  size: context.dp(18),
                  color: theme.primary,
                ),
              ),
              SizedBox(width: context.dp(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.targetLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AeDugnadText.leagueEntryTitle(),
                    ),
                    SizedBox(height: context.dp(2)),
                    Text(
                      subtitle,
                      style: AeDugnadText.bannerSubtitle(),
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.dp(8)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (points > 0)
                    _PointsPerMonthBadge(points: points),
                  SizedBox(height: context.dp(6)),
                  _StatusPill(
                    label: statusLabel,
                    pending: isPending,
                    paused: isPaused,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: context.dp(12)),
          Row(
            children: [
              Expanded(
                child: _SubActionButton(
                  icon: Icons.edit_outlined,
                  label: languages.dugnadDonationManageChange,
                  onTap: onChange,
                ),
              ),
              SizedBox(width: context.dp(8)),
              Expanded(
                child: _SubActionButton(
                  icon: isPaused
                      ? Icons.check_rounded
                      : Icons.schedule_rounded,
                  label: isPaused
                      ? languages.dugnadDonationManageResume
                      : languages.dugnadDonationManagePause,
                  loading: isPausing,
                  onTap: isPausing ? null : onPause,
                ),
              ),
              SizedBox(width: context.dp(8)),
              Expanded(
                child: _SubActionButton(
                  icon: Icons.close_rounded,
                  label: languages.dugnadDonationManageExit,
                  danger: true,
                  loading: isCancelling,
                  onTap: isCancelling ? null : onExit,
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

class _PointsPerMonthBadge extends StatelessWidget {
  const _PointsPerMonthBadge({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.dp(9), vertical: context.dp(4)),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4D6),
        borderRadius: BorderRadius.circular(context.dp(99)),
        border: Border.all(color: const Color(0x59D8A028)),
      ),
      child: Text(
        languages.dugnadDonationPointsValue(points),
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 10.5 * -0.1,
          color: Color(0xFF9A6B12),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.pending,
    this.paused = false,
  });

  final String label;
  final bool pending;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    if (paused) {
      bg = const Color(0xFFF3F4F6);
      fg = context.dugnadTheme.primaryHover;
    } else if (pending) {
      bg = const Color(0xFFF3F4F6);
      fg = context.dugnadTheme.primaryHover;
    } else {
      bg = ScSaasThemeTokens.success.withValues(alpha: 0.16);
      fg = ScSaasThemeTokens.success;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.dp(11), vertical: context.dp(5)),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(context.dp(99)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}

class _SubActionButton extends StatelessWidget {
  const _SubActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
    this.loading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool danger;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final bg = danger
        ? const Color(0x1ADC4040)
        : const Color(0xFFF3F4F6);
    final fg = danger ? Color(0xFFDC4040) : context.dugnadTheme.text;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(context.dp(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.dp(10)),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: context.dp(9), horizontal: context.dp(6)),
          child: loading
              ? Center(
                  child: SizedBox(
                    width: context.dp(16),
                    height: context.dp(16),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: fg,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: context.dp(14), color: fg),
                    SizedBox(width: context.dp(5)),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.01 * 12,
                          color: fg,
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

class _DonationAddTeamCard extends StatelessWidget {
  const _DonationAddTeamCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      // `.dn-addteam` carries the same soft `0 2px 4px rgba(45,27,91,.04)`
      // lift as its sibling white sub-cards; only this card had dropped it.
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.dp(16)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A2D1B5B),
            blurRadius: context.dp(4),
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: CustomPaint(
      painter: _DashedRoundedBorderPainter(
        color: const Color(0xFFD9CEF0),
        radius: 16,
        strokeWidth: 1.5,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.dp(16)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(context.dp(16)),
          child: Padding(
            padding: EdgeInsets.all(context.dp(14)),
            child: Row(
              children: [
                Container(
                  width: context.dp(42),
                  height: context.dp(42),
                  decoration: BoxDecoration(
                    color: context.dugnadTheme.primaryTint,
                    borderRadius: BorderRadius.circular(context.dp(12)),
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    size: context.dp(19),
                    color: context.dugnadTheme.primaryHover,
                  ),
                ),
                SizedBox(width: context.dp(13)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languages.dugnadDonationManageAddTeamTitle,
                        style: AeDugnadText.bannerTitle(),
                      ),
                      SizedBox(height: context.dp(2)),
                      Text(
                        languages.dugnadDonationManageAddTeamHint,
                        style: AeDugnadText.bannerSubtitle(),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: context.dp(18),
                  // `.dn-addteam .go` is a neutral gray-300 chevron, not a
                  // translucent theme purple.
                  color: ScSaasThemeTokens.gray300,
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
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
        final extractPath = metric.extractPath(
          distance,
          next.clamp(0, metric.length),
        );
        canvas.drawPath(extractPath, paint);
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

class _DonationMaxTeamsNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // `.dn-maxnote` is a flat neutral advisory pill — gray-50 fill, no border,
    // no shadow, a gray-400 icon. The card had been rebuilt as a white bordered
    // card with a themed purple icon (the fifth undeclared border); restore the
    // quiet neutral surface the design declares.
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.dp(15), vertical: context.dp(13)),
      decoration: BoxDecoration(
        color: ScSaasThemeTokens.gray50,
        borderRadius: BorderRadius.circular(context.dp(14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: context.dp(14),
            color: ScSaasThemeTokens.gray400,
          ),
          SizedBox(width: context.dp(9)),
          Expanded(
            child: Text(
              languages.dugnadDonationManageMaxNote,
              style: AeDugnadText.bannerSubtitle(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonationCancelSheet extends StatelessWidget {
  const _DonationCancelSheet({
    required this.onDismiss,
    required this.onConfirm,
  });

  final VoidCallback onDismiss;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ModalBarrier(
          color: Colors.black.withValues(alpha: 0.45),
          dismissible: true,
          onDismiss: onDismiss,
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.fromLTRB(context.dp(12), context.dp(0), context.dp(12), context.dp(12)),
                padding: EdgeInsets.fromLTRB(context.dp(20), context.dp(12), context.dp(20), context.dp(24)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(context.dp(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: context.dp(40),
                        height: context.dp(4),
                        margin: EdgeInsets.only(bottom: context.dp(18)),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(context.dp(99)),
                        ),
                      ),
                    ),
                    Text(
                      languages.dugnadDonationCancelSheetTitle,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: context.dugnadTheme.text,
                      ),
                    ),
                    SizedBox(height: context.dp(10)),
                    Text(
                      languages.dugnadDonationCancelSheetBody,
                      style: TextStyle(
                        color: context.dugnadTheme.primaryHover,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                    SizedBox(height: context.dp(16)),
                    ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC4040),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: context.dp(14)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(context.dp(14)),
                        ),
                      ),
                      child: Text(
                        languages.dugnadDonationCancelConfirm,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    SizedBox(height: context.dp(10)),
                    TextButton(
                      onPressed: onDismiss,
                      child: Text(
                        languages.dugnadDonationCancelSheetKeep,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: context.dugnadTheme.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
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
