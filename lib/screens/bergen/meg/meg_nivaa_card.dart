import 'package:flutter/material.dart';

import '../../../data/points/points_models.dart';
import '../kit/bergen_kit.dart';
import 'meg_ark.dart';
import 'meg_copy_a4.dart';
import 'meg_mark.dart';
import 'meg_pill.dart';
import 'meg_shine.dart';

/// The Poeng card (design `Poeng` ≈L5978), built from the design's own
/// values: the medal (spinning highlight ring, dark bezel, metal coin with the
/// inset rim and the dashed inner ring, the Æ mark, the shine sweep), the gold
/// gradient tier name, the ladder with the metal rungs on the glowing track,
/// POENG Å BRUKE with the coin and "Opptjent i alt", the big number, the
/// pending line, the sunken goal box with its gold-to-orange bar, and
/// Premiehylla / "Slik får du poeng".
class MegNivaaCard extends StatelessWidget {
  const MegNivaaCard({
    super.key,
    required this.balance,
    this.goal,
    this.onOpenPremiehylla,
    this.onOpenNivaa,
    this.onOpenSlik,
    this.onHentPremie,
  });

  final PointsBalance balance;
  final PointGoal? goal;
  final VoidCallback? onOpenPremiehylla;
  final VoidCallback? onOpenNivaa;
  final VoidCallback? onOpenSlik;
  final VoidCallback? onHentPremie;

  static const LinearGradient _goldText = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF6D8), Color(0xFFF2C14E), Color(0xFFD9A93A)],
    stops: [0, .55, 1],
  );

  @override
  Widget build(BuildContext context) {
    final b = balance;
    final g = goal;

    return Container(
      key: const Key('meg-nivaa-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: .14),
            Colors.white.withValues(alpha: .06),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: .2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            key: const Key('meg-nivaa-open'),
            behavior: HitTestBehavior.opaque,
            onTap: onOpenNivaa,
            child: Row(
              children: [
                MegMedal(name: b.tierName, size: 64),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        A4MegCopy.a4_meg_ditt_nivaa,
                        style: megInter(10, FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Colors.white.withValues(alpha: .55),
                        ),
                      ),
                      const SizedBox(height: 2),
                      ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (r) => _goldText.createShader(r),
                        child: Text(
                          b.tierName.toUpperCase(),
                          key: const Key('meg-tier-name'),
                          style: BergenTokens.display(
                            30,
                            weight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacingEm: -0.035,
                            height: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      if (b.nextTierName == null || b.pointsToNextTier == null)
                        Text(
                          A4MegCopy.a4_meg_hoyeste,
                          key: const Key('meg-tier-progress-line'),
                          style: BergenTokens.text(
                            11.5,
                            weight: FontWeight.w800,
                            color: Colors.white.withValues(alpha: .7),
                          ),
                        )
                      else
                        Text.rich(
                          key: const Key('meg-tier-progress-line'),
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${A4MegCopy.nf(b.pointsToNextTier!)} ',
                                style: BergenTokens.display(
                                  15,
                                  weight: FontWeight.w800,
                                  color: BergenTokens.mint,
                                  letterSpacingEm: -0.02,
                                ),
                              ),
                              TextSpan(
                                text: 'poeng til ',
                                style: BergenTokens.text(
                                  11.5,
                                  weight: FontWeight.w800,
                                  color: Colors.white.withValues(alpha: .7),
                                ),
                              ),
                              TextSpan(
                                text: b.nextTierName,
                                style: BergenTokens.text(
                                  11.5,
                                  weight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Colors.white.withValues(alpha: .45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          MegLadder(balance: b),
          const SizedBox(height: 26),
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: Alignment(-.32, -.44),
                    colors: [
                      Color(0xFFFBE8B4),
                      Color(0xFFE0A32C),
                      Color(0xFFB77F1C),
                    ],
                    stops: [0, .62, 1],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(120, 80, 10, .65),
                      offset: Offset(0, 2),
                      blurRadius: 4,
                      spreadRadius: -1,
                    ),
                  ],
                ),
                child: const Center(
                  child: MegMark(color: Color(0xFF7C5A18), size: 16),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  A4MegCopy.a4_meg_poeng_bruke,
                  style: megInter(11, FontWeight.w800,
                    letterSpacing: .9,
                    color: Colors.white.withValues(alpha: .55),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: _MintChip(
                    A4MegCopy.a4_meg_opptjent(
                      b.lifetime > 0 ? b.lifetime : b.earned12m,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    A4MegCopy.nf(b.available),
                    key: const Key('meg-available-points'),
                    style: BergenTokens.display(
                      42,
                      weight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacingEm: -0.04,
                      height: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                A4MegCopy.a4_meg_poeng,
                style: BergenTokens.display(
                  16,
                  weight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: .55),
                  letterSpacingEm: -0.02,
                ),
              ),
            ],
          ),
          if (b.pending > 0) ...[
            const SizedBox(height: 6),
            Text(
              A4MegCopy.a4_meg_kommer(b.pending),
              key: const Key('meg-pending-line'),
              style: BergenTokens.text(
                11.5,
                weight: FontWeight.w600,
                color: Colors.white.withValues(alpha: .55),
              ),
            ),
          ],
          if (g != null) ...[
            const SizedBox(height: 13),
            Container(
              key: const Key('meg-goal'),
              padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .22),
                borderRadius: BorderRadius.circular(18),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: .14),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          g.reached
                              ? A4MegCopy.a4_meg_maal_klar(g.label)
                              : A4MegCopy.a4_meg_maal(g.label, g.remaining),
                          key: const Key('meg-goal-label'),
                          style: BergenTokens.text(
                            11.5,
                            weight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${g.percent}%',
                        style: megInter(10.5, FontWeight.w800,
                          color: BergenTokens.mint,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Container(
                    height: 9,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .3),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (g.percent / 100).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF2C14E), Color(0xFFF26D3D)],
                          ),
                          border: Border(
                            top: BorderSide(
                              color: Colors.white.withValues(alpha: .6),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (g.reached) ...[
                    const SizedBox(height: 12),
                    MegPill(
                      key: const Key('meg-hent-premien'),
                      label: A4MegCopy.a4_meg_hent_premien,
                      height: 46,
                      fontSize: 13.5,
                      onPressed: onHentPremie ?? onOpenPremiehylla,
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: MegPill(
                  key: const Key('meg-open-premiehylla'),
                  label: A4MegCopy.a4_meg_premiehylla,
                  icon: Icons.chevron_right_rounded,
                  height: 48,
                  fontSize: 13.5,
                  style: MegPillStyle.nav,
                  onPressed: onOpenPremiehylla,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                key: const Key('meg-open-slik'),
                behavior: HitTestBehavior.opaque,
                onTap: onOpenSlik,
                child: Text(
                  A4MegCopy.a4_meg_slik,
                  textAlign: TextAlign.center,
                  style: BergenTokens.text(
                    12.5,
                    weight: FontWeight.w800,
                    color: BergenTokens.mint,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MintChip extends StatelessWidget {
  const _MintChip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF5CE0B8).withValues(alpha: .14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFF5CE0B8).withValues(alpha: .35),
        ),
      ),
      child: Text(
        text,
        style: megInter(9.5, FontWeight.w800,
          color: BergenTokens.mint,
        ),
      ),
    );
  }
}

/// The four rungs on the glowing track (design `nivMedaljer`): finished rungs
/// in their metal with a check, the current one raised at 28px with the white
/// ring and the gold glow, locked ones as glass with a lock.
class MegLadder extends StatelessWidget {
  const MegLadder({super.key, required this.balance});

  final PointsBalance balance;

  @override
  Widget build(BuildContext context) {
    final steps = balance.tiers.isNotEmpty
        ? balance.tiers
        : [
            TierStep(index: balance.tier, name: balance.tierName, threshold: 0),
            if (balance.nextTierName != null)
              TierStep(
                index: balance.tier + 1,
                name: balance.nextTierName!,
                threshold: 0,
              ),
          ];
    final current = balance.tier;
    final rungs = steps.length;
    final pct = balance.tierProgress;
    final progress = rungs <= 1
        ? 1.0
        : ((current + pct) / (rungs - 1)).clamp(0.0, 1.0);

    return SizedBox(
      key: const Key('meg-ladder'),
      height: 46,
      child: LayoutBuilder(
        builder: (context, c) => Stack(
          children: [
            Positioned(
              left: 14,
              right: 14,
              top: 14,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .32),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Positioned(
              left: 14,
              top: 14,
              child: Container(
                height: 6,
                width: (c.maxWidth - 28) * progress,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFC98A62),
                      Color(0xFFC7CDD1),
                      Color(0xFFF2C14E),
                      Color(0xFFDDE5EA),
                    ],
                    stops: [0, .38, .74, 1],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(242, 193, 78, .6),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final s in steps)
                    _Rung(
                      name: s.name,
                      done: s.index < current,
                      current: s.index == current,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Rung extends StatelessWidget {
  const _Rung({required this.name, required this.done, required this.current});

  final String name;
  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final m = medalFor(name);
    final locked = !done && !current;
    final size = current ? 28.0 : 20.0;
    final ink = locked ? Colors.white.withValues(alpha: .55) : m.ink;

    return SizedBox(
      width: 28,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: current ? 3 : 7),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: locked ? Colors.white.withValues(alpha: .14) : null,
              gradient: locked
                  ? null
                  : RadialGradient(
                      center: const Alignment(-.32, -.48),
                      colors: m.gradient,
                      stops: m.stops,
                    ),
              border: Border.all(
                color: current
                    ? Colors.white
                    : (locked ? Colors.white.withValues(alpha: .2) : m.ring),
                width: current ? 2 : 1.5,
              ),
              boxShadow: current
                  ? const [
                      BoxShadow(
                        color: Color.fromRGBO(242, 193, 78, .8),
                        blurRadius: 14,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: current
                  ? MegMark(color: m.ink, size: 15)
                  : Icon(
                      done ? Icons.check_rounded : Icons.lock_rounded,
                      size: done ? 11 : 9,
                      color: ink,
                    ),
            ),
          ),
          const SizedBox(height: 3),
          // The label is wider than its rung (design: absolute, nowrap).
          SizedBox(
            height: 11,
            child: OverflowBox(
              minWidth: 64,
              maxWidth: 64,
              child: Text(
                name,
                textAlign: TextAlign.center,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: megInter(8.5, FontWeight.w800,
                  letterSpacing: .3,
                  height: 1.1,
                  color: current
                      ? Colors.white
                      : Colors.white.withValues(alpha: done ? .7 : .4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The medal (design `nivMetall` + the Poeng card's medal block).
class MegMedal extends StatelessWidget {
  const MegMedal({
    super.key,
    required this.name,
    this.size = 64,
    this.animate = true,
  });

  final String name;
  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final m = medalFor(name);
    final coin = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-.32, -.48),
          colors: m.gradient,
          stops: m.stops,
        ),
        border: Border.all(color: m.ring, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(3, 16, 24, .8),
            offset: Offset(0, 6),
            blurRadius: 12,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: .55),
                    Colors.white.withValues(alpha: 0),
                    Colors.transparent,
                    const Color(0xFF5A3C0A).withValues(alpha: .28),
                  ],
                  stops: const [0, .08, .7, 1],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(size * .094),
              child: CustomPaint(
                painter: _DashedRing(
                  color: const Color(0xFF5A3C0A).withValues(alpha: .35),
                ),
              ),
            ),
          ),
          MegMark(color: m.ink, size: size * .69),
        ],
      ),
    );

    final medal = SizedBox(
      width: size + 12,
      height: size + 12,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (animate) MegSpinRing(size: size + 12),
          Container(
            width: size + 8,
            height: size + 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF1E4F5C),
            ),
          ),
          coin,
        ],
      ),
    );
    if (!animate) return medal;
    return MegShine(
      borderRadius: BorderRadius.circular(size + 12),
      period: const Duration(milliseconds: 3400),
      delay: const Duration(milliseconds: 600),
      bandFraction: .36,
      opacity: .5,
      child: medal,
    );
  }
}

class _DashedRing extends CustomPainter {
  const _DashedRing({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final r = size.shortestSide / 2;
    final c = Offset(size.width / 2, size.height / 2);
    const dashes = 28;
    const pi = 3.141592653589793;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        i * 2 * pi / dashes,
        pi / dashes,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedRing old) => old.color != color;
}

class MedalStyle {
  const MedalStyle({
    required this.gradient,
    required this.stops,
    required this.ink,
    required this.ring,
    required this.accent,
  });

  final List<Color> gradient;
  final List<double> stops;
  final Color ink;
  final Color ring;
  final Color accent;
}

/// `nivMetall` in the design: Platina, Gull, Sølv, Bronse.
MedalStyle medalFor(String name) {
  switch (name.toLowerCase()) {
    case 'platina':
    case 'ulriken':
      return const MedalStyle(
        gradient: [
          Color(0xFFFFFFFF),
          Color(0xFFE8EDF0),
          Color(0xFFAEB9C2),
          Color(0xFF8C98A3),
        ],
        stops: [0, .48, .76, 1],
        ink: Color(0xFF263038),
        ring: Color(0x998C98A3),
        accent: Color(0xFFDCE3E6),
      );
    case 'gull':
    case 'rundemanen':
      return const MedalStyle(
        gradient: [Color(0xFFFFFCF0), Color(0xFFF2D591), Color(0xFFC99B2A)],
        stops: [0, .55, 1],
        ink: Color(0xFF5A4010),
        ring: Color(0x99C99B2A),
        accent: Color(0xFFF2C14E),
      );
    case 'sølv':
    case 'solv':
    case 'løvstakken':
      return const MedalStyle(
        gradient: [Color(0xFFFFFFFF), Color(0xFFDCE3E6), Color(0xFF9AA8AE)],
        stops: [0, .55, 1],
        ink: Color(0xFF2A3538),
        ring: Color(0x999AA8AE),
        accent: Color(0xFFCBD6DA),
      );
    default:
      return const MedalStyle(
        gradient: [Color(0xFFF6DCC8), Color(0xFFC98A62), Color(0xFF8E5B38)],
        stops: [0, .58, 1],
        ink: Color(0xFF4A2A16),
        ring: Color(0x998E5B38),
        accent: Color(0xFFE0A47E),
      );
  }
}
