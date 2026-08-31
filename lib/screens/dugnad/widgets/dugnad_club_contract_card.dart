import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/design_scale.dart';
import '../../../utils/utils.dart';
import '../../../ui/kit/ae_club_crest.dart';
import '../../../ui/kit/ae_theme.dart';

/// Player contract card for T14 club welcome (`dgseq-contract-card`).
class DugnadClubContractCard extends StatefulWidget {
  const DugnadClubContractCard({
    super.key,
    required this.clubName,
    required this.playerName,
    required this.roleLabel,
    this.clubLogoUrl,
    this.seasonStamp = '25/26',
  });

  final String clubName;
  final String playerName;
  final String roleLabel;
  final String? clubLogoUrl;
  final String seasonStamp;

  @override
  State<DugnadClubContractCard> createState() => _DugnadClubContractCardState();
}

class _DugnadClubContractCardState extends State<DugnadClubContractCard>
    with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _signature;
  late final AnimationController _stamp;
  late final AnimationController _sweep;
  bool? _reduceMotion;

  static const _ink = Color(0xFF221A3D);

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 880),
    );
    _signature = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _stamp = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );
    _sweep = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion != null && reduce == _reduceMotion) return;
    _reduceMotion = reduce;
    if (reduce == true) {
      _enter.value = 1;
      _signature.value = 1;
      _stamp.value = 1;
      _sweep.value = 1;
    } else if (_enter.status == AnimationStatus.dismissed) {
      _enter.forward();
      Future<void>.delayed(const Duration(milliseconds: 620), () {
        if (mounted) _signature.forward();
      });
      Future<void>.delayed(const Duration(milliseconds: 1520), () {
        if (mounted) _stamp.forward();
      });
      Future<void>.delayed(const Duration(milliseconds: 1700), () {
        if (mounted) _sweep.forward();
      });
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    _signature.dispose();
    _stamp.dispose();
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final l10n = AppLocalizations.of(context)!;
    final stampColor = Color.lerp(theme.primary, Colors.black, 0.12)!;

    return AnimatedBuilder(
      animation: Listenable.merge([_enter, _signature, _stamp, _sweep]),
      builder: (context, _) {
        return SizedBox(
          width: context.dp(206),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned(
                top: context.dp(-50),
                child: IgnorePointer(
                  child: Container(
                    width: context.dp(260),
                    height: context.dp(280),
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.9),
                        radius: 0.72,
                        colors: [
                          Colors.white.withValues(alpha: 0.26),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              FadeTransition(
                opacity: _reduceMotion == true
                    ? const AlwaysStoppedAnimation(1)
                    : CurvedAnimation(parent: _enter, curve: Curves.easeOut),
                child: ScaleTransition(
                  scale: _reduceMotion == true
                      ? const AlwaysStoppedAnimation(1)
                      : Tween<double>(begin: 0.82, end: 1).animate(
                          CurvedAnimation(
                            parent: _enter,
                            curve: Curves.easeOutBack,
                          ),
                        ),
                  child: Transform.rotate(
                    angle: _reduceMotion == true ? 0 : (1 - _enter.value) * -0.07,
                    child: _ContractDocument(
                      theme: theme,
                      l10n: l10n,
                      clubName: widget.clubName,
                      playerName: widget.playerName,
                      roleLabel: widget.roleLabel,
                      clubLogoUrl: widget.clubLogoUrl,
                      seasonStamp: widget.seasonStamp,
                      signatureProgress:
                          _reduceMotion == true ? 1 : _signature.value,
                      sweepProgress: _reduceMotion == true ? 1 : _sweep.value,
                    ),
                  ),
                ),
              ),
              if (_reduceMotion == true || _stamp.value > 0)
                Positioned(
                  right: context.dp(-16),
                  bottom: context.dp(-14),
                  child: Transform.rotate(
                    angle: -0.21,
                    child: Transform.scale(
                      scale: _reduceMotion == true ? 1 : _stampScale(_stamp.value),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.dp(12),
                          vertical: context.dp(6),
                        ),
                        decoration: BoxDecoration(
                          color: stampColor,
                          borderRadius: BorderRadius.circular(context.dp(8)),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.92),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Text(
                          l10n.celebrationContractStamp,
                          style: aeLabel(color: Colors.white).copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 12.5,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  double _stampScale(double t) {
    if (t < 0.7) return 2.6 - (1.66 * (t / 0.7));
    return 0.94 + (0.06 * ((t - 0.7) / 0.3));
  }
}

class _ContractDocument extends StatelessWidget {
  const _ContractDocument({
    required this.theme,
    required this.l10n,
    required this.clubName,
    required this.playerName,
    required this.roleLabel,
    required this.clubLogoUrl,
    required this.seasonStamp,
    required this.signatureProgress,
    required this.sweepProgress,
  });

  final AeThemePalette theme;
  final AppLocalizations l10n;
  final String clubName;
  final String playerName;
  final String roleLabel;
  final String? clubLogoUrl;
  final String seasonStamp;
  final double signatureProgress;
  final double sweepProgress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.dp(206),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.dp(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 50,
            offset: const Offset(0, 26),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.dp(20)),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: context.dp(5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.ink, theme.primary, theme.ink],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.dp(13),
                    context.dp(10),
                    context.dp(13),
                    context.dp(9),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.celebrationContractTitle.toUpperCase(),
                          style: aeLabel(color: theme.ink).copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 8.5,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      Text(
                        seasonStamp,
                        style: aeLabel(
                          color: _DugnadClubContractCardState._ink.withValues(alpha: 0.4),
                        ).copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 8.5,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: _DugnadClubContractCardState._ink.withValues(alpha: 0.08),
                ),
                SizedBox(height: context.dp(13)),
                AeClubCrest(
                  name: clubName,
                  logoUrl: clubLogoUrl,
                  size: context.dp(52),
                  backgroundColor: Color.lerp(theme.primary, Colors.white, 0.9),
                ),
                SizedBox(height: context.dp(8)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.dp(12)),
                  child: Text(
                    clubName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: aeTitle(color: _DugnadClubContractCardState._ink).copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.dp(14),
                    context.dp(11),
                    context.dp(14),
                    context.dp(4),
                  ),
                  child: Column(
                    children: [
                      _ContractRow(
                        label: l10n.celebrationContractPlayerLabel,
                        value: playerName,
                      ),
                      SizedBox(height: context.dp(5)),
                      _ContractRow(
                        label: l10n.celebrationContractRoleLabel,
                        value: roleLabel,
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: context.dp(17),
                      top: context.dp(8),
                      bottom: context.dp(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: context.dp(132),
                          height: context.dp(30),
                          child: CustomPaint(
                            painter: _SignaturePainter(
                              progress: signatureProgress,
                              color: Color.lerp(
                                theme.primary,
                                const Color(0xFF101C2E),
                                0.16,
                              )!,
                            ),
                          ),
                        ),
                        Container(
                          width: context.dp(115),
                          height: 1.5,
                          color: _DugnadClubContractCardState._ink.withValues(alpha: 0.16),
                        ),
                        SizedBox(height: context.dp(4)),
                        Text(
                          l10n.celebrationContractSignedBy.toUpperCase(),
                          style: aeLabel(
                            color: _DugnadClubContractCardState._ink.withValues(alpha: 0.42),
                          ).copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 8.5,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: context.dp(14)),
              ],
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(context.dp(20)),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final dx = -width * 1.5 + (width * 2.6 * sweepProgress);
                      return Transform.translate(
                        offset: Offset(dx, 0),
                        child: Container(
                          width: width * 0.55,
                          decoration: BoxDecoration(
                            // Laminate sheen on white paper — cool grey band
                            // (pure white-on-white is invisible; never use
                            // `Colors.transparent` or mid-stops go muddy black).
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                const Color(0xFFD8DCE6).withValues(alpha: 0),
                                const Color(0xFFC8CEDA).withValues(alpha: 0.28),
                                const Color(0xFFE8ECF2).withValues(alpha: 0.55),
                                Colors.white.withValues(alpha: 0.78),
                                const Color(0xFFE8ECF2).withValues(alpha: 0.55),
                                const Color(0xFFC8CEDA).withValues(alpha: 0.28),
                                const Color(0xFFD8DCE6).withValues(alpha: 0),
                              ],
                              stops: const [
                                0.0,
                                0.18,
                                0.34,
                                0.5,
                                0.66,
                                0.82,
                                1.0,
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContractRow extends StatelessWidget {
  const _ContractRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          label.toUpperCase(),
          style: aeLabel(
            color: _DugnadClubContractCardState._ink.withValues(alpha: 0.4),
          ).copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 10,
            letterSpacing: 0.6,
          ),
        ),
        SizedBox(width: context.dp(6)),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return CustomPaint(
                size: Size(constraints.maxWidth, 1),
                painter: _DottedLinePainter(
                  color: _DugnadClubContractCardState._ink.withValues(alpha: 0.22),
                ),
              );
            },
          ),
        ),
        SizedBox(width: context.dp(6)),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: aeLabel(color: _DugnadClubContractCardState._ink).copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 10.5,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ],
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  _DottedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dash = 2.0;
    const gap = 2.5;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 124;
    final scaleY = size.height / 34;
    canvas.scale(scaleX, scaleY);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final main = Path()
      ..moveTo(3, 27)
      ..cubicTo(9, 11, 15, 5, 19, 12)
      ..cubicTo(23, 19, 17, 25, 21, 28)
      ..cubicTo(26, 31, 33, 19, 39, 10)
      ..cubicTo(43, 4, 47, 8, 45, 16)
      ..cubicTo(43, 23, 39, 27, 45, 27)
      ..cubicTo(53, 27, 62, 19, 75, 12)
      ..cubicTo(84, 7, 90, 10, 96, 17);

    _drawPath(canvas, main, paint, progress);

    final flick = Path()
      ..moveTo(92, 8)
      ..cubicTo(100, 5, 107, 7, 112, 12);
    _drawPath(canvas, flick, paint..strokeWidth = 2.2, (progress - 0.55).clamp(0.0, 1.0));
  }

  void _drawPath(Canvas canvas, Path path, Paint paint, double t) {
    if (t <= 0) return;
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final extract = metric.extractPath(0, metric.length * t);
    canvas.drawPath(extract, paint);
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
