part of 'launch_onboarding.dart';

// ── Ferdig (`onbErFerdig`, L2166–2212) ──────────────────────────────────────

extension _Ferdig on LaunchOnboardingState {
  Widget _ferdig(BuildContext context, double inset) {
    final maal = _maal;
    final poeng = _poeng;
    final pct = maal == 0 ? 0.0 : (poeng / maal).clamp(0.0, 1.0);
    final verv = (_erVerv || _vervOk) && (_regler?.referee ?? 0) > 0;
    final linje = poeng >= maal
        ? (verv ? LfCopy.poengVerv(maal, _regler!.referee, _vervNavn) : LfCopy.poengOrg(maal))
        : LfCopy.leggerPoeng;
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(22, inset + 84, 22, 22),
          child: Column(
            children: [
              const SizedBox(height: 14),
              const _FerdigMerke(),
              const SizedBox(height: 10),
              LfRise(
                delay: 500,
                child: Text(LfCopy.velkommen(_fornavn),
                    textAlign: TextAlign.center, style: jakarta(26, em: -.035, height: 1.15)),
              ),
              const SizedBox(height: 12),
              LfAegilPortrait(
                text: LfCopy.aegilFerdig,
                image: 'assets/images/aegil/aegil_done.png',
                size: 52,
                radius: 17,
                delay: 600,
              ),
              const SizedBox(height: 18),
              // No start points (sign-up bonus off, or no rules): no card.
              if (maal > 0)
                _KortInn(
                  delay: 600,
                  dur: 550,
                  curve: const Cubic(.3, 1.15, .5, 1),
                  child: _poengKort(poeng, pct, linje),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 9),
                    Expanded(
                      child: _KortInn(
                        delay: 850 + 100.0 * i,
                        dur: 500,
                        curve: const Cubic(.3, 1.2, .5, 1),
                        child: _oppdrag(i),
                      ),
                    ),
                  ],
                ],
              ),
              const Spacer(),
              const SizedBox(height: 14),
              Builder(
                builder: (ctx) => LfPillCta(
                  height: 56,
                  phaseMs: -1500,
                  pulse: true,
                  onTap: () => _tilHjem(_rectOf(ctx), toast: LfCopy.velkommenToast(_maal)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(LfCopy.komIGang, style: jakarta(16)),
                      const SizedBox(width: 9),
                      const LfStroke(LfIco.kickOff, size: 17, color: Colors.white, width: 2.8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // `konfettiI` 380ms after arriving.
        const Positioned.fill(child: IgnorePointer(child: _Konfetti3D())),
      ],
    );
  }

  Widget _poengKort(int poeng, double pct, String linje) {
    return CssBox(
      radius: BorderRadius.circular(24),
      bg: const [
        CssRadial(
          [Color.fromRGBO(242, 193, 78, .22), Color.fromRGBO(242, 193, 78, 0)],
          stops: [0, .6],
          rx: .8,
          ry: .9,
          cx: .9,
          cy: 0,
        ),
        CssLinear(165, [
          Color.fromRGBO(255, 255, 255, .2),
          Color.fromRGBO(255, 255, 255, .08),
          Color.fromRGBO(255, 255, 255, .04),
        ], [0, .45, 1]),
      ],
      border: Border.all(color: const Color.fromRGBO(255, 255, 255, .24)),
      shadows: const [
        CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .4)),
        CssShadow.inset(0, -1, 0, 0, Color.fromRGBO(255, 255, 255, .06)),
        CssShadow(0, 3, 0, 0, Color.fromRGBO(8, 30, 38, .55)),
        CssShadow(0, 24, 34, -18, Color.fromRGBO(2, 12, 18, .95)),
      ],
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
      child: Column(
        children: [
          Row(
            children: [
              const _Mynt(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(LfCopy.startpoeng, style: inter(10, weight: FontWeight.w800, em: .14, color: const Color(0xFF9FE0C8))),
                    const SizedBox(height: 2),
                    Text(linje, style: inter(11.5, height: 1.35, color: const Color.fromRGBO(255, 255, 255, .72))),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$poeng',
                style: jakarta(32, em: -.04, color: const Color(0xFFF7D57E), shadows: const [
                  Shadow(color: Color.fromRGBO(120, 70, 10, .35), offset: Offset(0, 2)),
                  Shadow(color: Color.fromRGBO(242, 193, 78, .35), blurRadius: 18),
                ]).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ],
          ),
          const SizedBox(height: 14),
          CssBox(
            height: 16,
            radius: BorderRadius.circular(99),
            bg: const [CssLinear(180, [Color.fromRGBO(0, 0, 0, .42), Color.fromRGBO(0, 0, 0, .22)])],
            shadows: const [
              CssShadow.inset(0, 2, 4, 0, Color.fromRGBO(0, 0, 0, .55)),
              CssShadow.inset(0, -1, 0, 0, Color.fromRGBO(255, 255, 255, .14)),
              CssShadow(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .1)),
            ],
            padding: const EdgeInsets.all(3),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: pct),
                duration: const Duration(milliseconds: 800),
                curve: const Cubic(.3, .9, .3, 1),
                builder: (context, w, _) => FractionallySizedBox(
                  widthFactor: w,
                  child: w <= 0 ? const SizedBox.shrink() : const _PoengFyll(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _oppdrag(int i) {
    // The real amounts from `points/rules`; blank until it answers.
    String pluss(int? n) => n == null || n <= 0 ? '' : '+$n';
    final r = _regler;
    final (tx, p, svg, delay) = [
      (LfCopy.oppdragForste, pluss(r?.firstOrderBonus), 'onb_pose3d', 0.0),
      (LfCopy.oppdragFisk, pluss(r?.fiskePerCatch), 'onb_orb_fisk', 600.0),
      (LfCopy.oppdragVerv, pluss(r?.referrer), 'onb_varde3d', 1200.0),
    ][i];
    return CssBox(
      radius: BorderRadius.circular(18),
      bg: const [
        CssLinear(165, [
          Color.fromRGBO(255, 255, 255, .18),
          Color.fromRGBO(255, 255, 255, .07),
          Color.fromRGBO(255, 255, 255, .04),
        ], [0, .45, 1]),
      ],
      border: Border.all(color: const Color.fromRGBO(255, 255, 255, .22)),
      shadows: const [
        CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .34)),
        CssShadow(0, 2, 0, 0, Color.fromRGBO(8, 30, 38, .5)),
        CssShadow(0, 16, 24, -16, Color.fromRGBO(2, 12, 18, .95)),
      ],
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 11),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          const Positioned(
            top: -2,
            width: 44,
            height: 44,
            child: CssBox(
              radius: BorderRadius.all(Radius.circular(22)),
              bg: [CssSolid(Color.fromRGBO(0, 0, 0, .25))],
              shadows: [
                CssShadow.inset(0, 2, 4, 0, Color.fromRGBO(0, 0, 0, .45)),
                CssShadow.inset(0, -1, 0, 0, Color.fromRGBO(255, 255, 255, .14)),
              ],
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 6),
              LfLoop(
                builder: (context, t, child) {
                  final q = kfLoop(t, delay, 5000);
                  final y = q == null ? 0.0 : kf(q, const [0, .5, 1], const [0, -3, 0], cssEaseInOut);
                  return Transform.translate(offset: Offset(0, y), child: child);
                },
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // filter: drop-shadow(0 4px 4px rgba(0,0,0,.4))
                      Positioned(
                        left: 0,
                        top: 4,
                        child: ImageFiltered(
                          imageFilter: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                          child: ColorFiltered(
                            colorFilter: const ColorFilter.mode(Color.fromRGBO(0, 0, 0, .4), BlendMode.srcIn),
                            child: LfSvgAsset(svg, w: 32, h: 32),
                          ),
                        ),
                      ),
                      LfSvgAsset(svg, w: 32, h: 32),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4 + 6),
              Text(tx, textAlign: TextAlign.center, style: inter(10.5, weight: FontWeight.w800, height: 1.25)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFE19A), Color(0xFFE0A32C)],
                  ),
                  boxShadow: const [BoxShadow(color: Color(0xFF9A6A14), offset: Offset(0, 2))],
                ),
                foregroundDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: const Border(top: BorderSide(color: Color.fromRGBO(255, 255, 255, .6), width: 1)),
                ),
                child: Text(p,
                    style: inter(10, weight: FontWeight.w800, height: 1.2, color: const Color(0xFF3A2508))
                        .copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// `kortInn` — translateY(140px) scale(.86) → none, with opacity.
class _KortInn extends StatelessWidget {
  const _KortInn({required this.child, required this.delay, required this.dur, required this.curve});

  final Widget child;
  final double delay;
  final double dur;
  final Curve curve;

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: delay + dur,
    child: child,
    builder: (context, t, child) {
      final p = curve.transform(kfP(t, delay, dur));
      return Opacity(
        opacity: kfP(t, delay, dur) == 0 ? 0 : p.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 140 * (1 - p)),
          child: Transform.scale(scale: .86 + .14 * p, child: child),
        ),
      );
    },
  );
}

/// The Æ sticker slapped on (`klistre`), floating (`spSvev`), the mint
/// glow, the shadow, six confetti bits (`onbKonf`) and the check badge.
class _FerdigMerke extends StatelessWidget {
  const _FerdigMerke();

  static const Cubic _pop = Cubic(.34, 1.56, .64, 1);

  // (colour, kx, ky, kr, w, h, round)
  static const _konf = [
    (Color(0xFFF26D3D), -52.0, -104.0, 200.0, 9.0, 9.0, false),
    (Color(0xFF5CE0B8), 46.0, -96.0, -160.0, 8.0, 8.0, true),
    (Color(0xFFFFFFFF), -30.0, -118.0, 140.0, 7.0, 12.0, false),
    (Color(0xFFF2C14E), 58.0, -70.0, -220.0, 10.0, 10.0, true),
    (Color(0xFF9C7BE8), 10.0, -128.0, 180.0, 8.0, 8.0, false),
    (Color(0xFFFFFFFF), -66.0, -60.0, -140.0, 6.0, 6.0, true),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 150,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            left: 30 - 20,
            top: 30 - 20,
            width: 120 + 40,
            height: 90 + 40,
            child: CssBox(
              bg: [
                CssRadial(
                  [Color.fromRGBO(92, 224, 184, .36), Color.fromRGBO(92, 224, 184, .12), Color.fromRGBO(92, 224, 184, 0)],
                  stops: [0, .45, .85],
                  circle: true,
                  farthestCorner: true,
                ),
              ],
            ),
          ),
          const Positioned(
            left: 14,
            top: 118,
            width: 150,
            height: 22,
            child: CssBox(
              bg: [
                CssRadial(
                  [Color.fromRGBO(3, 16, 24, .7), Color.fromRGBO(3, 16, 24, .2), Color.fromRGBO(3, 16, 24, 0)],
                  stops: [0, .5, .9],
                ),
              ],
            ),
          ),
          for (var i = 0; i < _konf.length; i++)
            Positioned(
              left: 68 + (i % 3) * 8.0,
              top: 64,
              child: LfOnce(
                ms: 250 + i * 50 + 1000 + i * 80,
                builder: (context, t, child) {
                  final k = _konf[i];
                  final dur = 1000 + i * 80.0, delay = 250 + i * 50.0;
                  final p = kfP(t, delay, dur);
                  if (p <= 0) return const SizedBox.shrink();
                  final e = const Cubic(.2, .7, .4, 1).transform(p);
                  final o = p < .12 ? kf(p, const [0, .12], const [0, 1], const Cubic(.2, .7, .4, 1)) : 1 - kf(p, const [.12, 1], const [0, 1], const Cubic(.2, .7, .4, 1));
                  return Opacity(
                    opacity: o.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(k.$2 * e, k.$3 * e),
                      child: Transform.rotate(angle: rad(k.$4 * e), child: Transform.scale(scale: .4 + .6 * e, child: child)),
                    ),
                  );
                },
                child: Container(
                  width: _konf[i].$5,
                  height: _konf[i].$6,
                  decoration: BoxDecoration(
                    color: _konf[i].$1,
                    borderRadius: _konf[i].$7 ? BorderRadius.circular(99) : BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 15,
            top: 15,
            child: LfOnce(
              ms: 700,
              builder: (context, t, child) {
                final p = kfP(t, 100, 600);
                final s = kf(p, const [0, .55, .75, 1], const [1.5, .97, 1.03, 1], _pop);
                final r = kf(p, const [0, .55, .75, 1], const [-14, -4, -6, -5], _pop);
                final o = kf(p, const [0, .55, 1], const [0, 1, 1], _pop);
                return Opacity(
                  opacity: o.clamp(0.0, 1.0),
                  child: Transform.rotate(angle: rad(r), child: Transform.scale(scale: s, child: child)),
                );
              },
              child: LfLoop(
                builder: (context, t, child) {
                  final q = kfLoop(t, 1000, 4400);
                  final y = q == null ? 0.0 : kf(q, const [0, .5, 1], const [0, -4, 0], cssEaseInOut);
                  final rz = q == null ? 0.0 : kf(q, const [0, .5, 1], const [0, .6, 0], cssEaseInOut);
                  return Transform.translate(offset: Offset(0, y), child: Transform.rotate(angle: rad(rz), child: child));
                },
                child: const LfMerke(w: 150, h: 120),
              ),
            ),
          ),
          Positioned(
            right: 4,
            bottom: 16,
            child: LfOnce(
              ms: 1050,
              builder: (context, t, child) => lfHake(kfP(t, 550, 500), child!),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF5CE0B8), Color(0xFF2FB893)],
                  ),
                  boxShadow: [
                    const BoxShadow(color: Colors.white, spreadRadius: 3),
                    BoxShadow(
                      color: const Color.fromRGBO(47, 184, 147, .9),
                      offset: const Offset(0, 10),
                      blurRadius: cssSigma(18) / .57735,
                      spreadRadius: -8,
                    ),
                  ],
                ),
                child: const Center(child: LfStroke(LfIco.check, size: 22, color: Color(0xFF0F1F2B), width: 3.6)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The gold coin with the embossed Æ (`phMynt`: flips at 72–100% of 4s).
class _Mynt extends StatelessWidget {
  const _Mynt();

  @override
  Widget build(BuildContext context) {
    return LfLoop(
      builder: (context, t, child) {
        final q = kfLoop(t, 1400, 4000);
        final ry = q == null ? 0.0 : kf(q, const [0, .72, .86, 1], const [0, 0, 180, 0], cssEaseInOut);
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, .002)
            ..rotateY(rad(ry)),
          child: child,
        );
      },
      child: Stack(
        children: [
          const CssBox(
            width: 44,
            height: 44,
            radius: BorderRadius.all(Radius.circular(22)),
            bg: [
              CssRadial(
                [Color(0xFFFFF2C8), Color(0xFFF2C14E), Color(0xFFB77F1C)],
                stops: [0, .55, 1],
                cx: .34,
                cy: .28,
                circle: true,
                farthestCorner: true,
              ),
            ],
            shadows: [
              CssShadow.inset(0, 2, 0, 0, Color.fromRGBO(255, 255, 255, .8)),
              CssShadow.inset(0, -3, 6, 0, Color.fromRGBO(120, 70, 10, .45)),
              CssShadow(0, 3, 0, 0, Color(0xFF8E5E12)),
              CssShadow(0, 10, 16, -6, Color.fromRGBO(0, 0, 0, .55)),
              CssShadow(0, 0, 18, 0, Color.fromRGBO(242, 193, 78, .45)),
            ],
          ),
          Positioned(
            left: 5,
            top: 5,
            right: 5,
            bottom: 5,
            child: CustomPaint(painter: _DashedCircle()),
          ),
          Positioned.fill(
            child: Center(child: LfSvg(lfMerkeInk(const Color(0xFF6A4A10)), w: 22, h: 18)),
          ),
        ],
      ),
    );
  }
}

class _DashedCircle extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color.fromRGBO(120, 80, 10, .45);
    final r = size.width / 2 - .75;
    final c = size.center(Offset.zero);
    const n = 18;
    for (var i = 0; i < n; i++) {
      final a0 = i * 2 * math.pi / n;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), a0, math.pi / n, false, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Striped mint fill with the travelling stripes (`phStripe`) and the
/// sparkle on its tip (`phGnist`).
class _PoengFyll extends StatelessWidget {
  const _PoengFyll();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: CssBox(
            radius: BorderRadius.circular(99),
            clip: true,
            bg: const [CssLinear(180, [Color(0xFF9CF5D6), Color(0xFF3FD0A4), Color(0xFF23A07C)], [0, .55, 1])],
            shadows: const [
              CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .6)),
              CssShadow.inset(0, -1, 0, 0, Color.fromRGBO(0, 60, 40, .3)),
              CssShadow(0, 0, 12, 0, Color.fromRGBO(92, 224, 184, .55)),
            ],
            child: LfLoop(
              builder: (context, t, _) => CustomPaint(painter: _Stripes((t / 900) % 1.0 * 14)),
            ),
          ),
        ),
        Positioned(
          right: -7,
          top: 5 - 8,
          child: LfLoop(
            builder: (context, t, child) {
              final q = (t / 1800) % 1.0;
              final s = kf(q, const [0, .5, 1], const [.3, 1, .3], cssEaseInOut);
              final r = kf(q, const [0, .5, 1], const [0, 45, 0], cssEaseInOut);
              final o = kf(q, const [0, .5, 1], const [0, 1, 0], cssEaseInOut);
              return Opacity(opacity: o, child: Transform.rotate(angle: rad(r), child: Transform.scale(scale: s, child: child)));
            },
            child: const SizedBox(width: 16, height: 16, child: CustomPaint(painter: _Spark())),
          ),
        ),
      ],
    );
  }
}

class _Stripes extends CustomPainter {
  const _Stripes(this.shift);

  final double shift;

  @override
  void paint(Canvas canvas, Size size) {
    // linear-gradient(135deg, .26 25%, 0 25–50%, .26 50–75%, 0 75%) on 14×14.
    final p = Paint()..color = const Color.fromRGBO(255, 255, 255, .26);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (double x = -28 + shift; x < size.width + 28; x += 14) {
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x + 7, 0)
        ..lineTo(x + 7 - size.height, size.height)
        ..lineTo(x - size.height, size.height)
        ..close();
      canvas.drawPath(path, p);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Stripes old) => old.shift != shift;
}

class _Spark extends CustomPainter {
  const _Spark();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(w * .5, 0)
      ..lineTo(w * .62, h * .38)
      ..lineTo(w, h * .5)
      ..lineTo(w * .62, h * .62)
      ..lineTo(w * .5, h)
      ..lineTo(w * .38, h * .62)
      ..lineTo(0, h * .5)
      ..lineTo(w * .38, h * .38)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color.fromRGBO(160, 255, 220, .9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── konfettiI: real 3D confetti ─────────────────────────────────────────────

class _Bit {
  _Bit(this.type, this.w, this.h, this.f0, this.f1, this.vx, this.vy, this.vz, this.rx, this.ry, this.rz, this.wx,
      this.wy, this.wz, this.luft, this.fl, this.flF, this.forsink);

  final int type; // 0 flak, 1 strimmel, 2 rund
  final double w, h;
  final Color f0, f1;
  double x = 0, y = 0, z = 0;
  double vx, vy, vz, rx, ry, rz;
  final double wx, wy, wz, luft, fl, flF, forsink;
}

/// Prototype `konfettiI` (L17344): 90 pieces shot towards the camera in a
/// 640px perspective, spinning on three axes, slowed by air and pulled by
/// gravity for 3.4s. Starts 380ms after Ferdig appears.
class _Konfetti3D extends StatefulWidget {
  const _Konfetti3D();

  @override
  State<_Konfetti3D> createState() => _Konfetti3DState();
}

class _Konfetti3DState extends State<_Konfetti3D> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final List<_Bit> _bits = [];
  double _el = 0;
  Duration _last = Duration.zero;
  bool _done = false;

  static const _farger = [
    (Color(0xFFFF8A4C), Color(0xFFC24A17)),
    (Color(0xFF5CE0B8), Color(0xFF23A07C)),
    (Color(0xFFF7D57E), Color(0xFFC99422)),
    (Color(0xFFFFFFFF), Color(0xFFC9D6DA)),
    (Color(0xFF9CF5D6), Color(0xFF3FB892)),
    (Color(0xFFF26D3D), Color(0xFFA83A10)),
    (Color(0xFF7FC8FF), Color(0xFF3A86C4)),
  ];

  @override
  void initState() {
    super.initState();
    final r = math.Random();
    double rnd() => r.nextDouble();
    for (var i = 0; i < 90; i++) {
      final type = i % 9 == 0 ? 1 : (i % 4 == 0 ? 2 : 0);
      final w = type == 1 ? 5.0 : (type == 2 ? 7 + rnd() * 3 : 8 + rnd() * 5);
      final h = type == 1 ? 26 + rnd() * 14 : (type == 2 ? w : w * (.5 + rnd() * .4));
      final f = _farger[i % _farger.length];
      final a = rnd() * math.pi * 2, spred = 220 + rnd() * 420;
      _bits.add(_Bit(
        type, w, h, f.$1, f.$2,
        math.cos(a) * spred,
        math.sin(a) * spred * .75 - (380 + rnd() * 420),
        260 + rnd() * 620,
        rnd() * 360, rnd() * 360, rnd() * 360,
        (rnd() - .5) * 900, (rnd() - .5) * 900, (rnd() - .5) * 500,
        type == 0 ? 2.4 : (type == 1 ? 2.8 : 1.4),
        rnd() * 6.28, 3 + rnd() * 4, rnd() * .12,
      ));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _done = true;
      return;
    }
    Future.delayed(const Duration(milliseconds: 380), () {
      if (mounted && !_ticker.isActive && !_done) _ticker.start();
    });
  }

  void _tick(Duration e) {
    final dt = math.min(.033, (e - _last).inMicroseconds / 1e6);
    _last = e;
    _el = e.inMicroseconds / 1000;
    if (_el >= 3400) {
      _ticker.stop();
      setState(() => _done = true);
      return;
    }
    for (final p in _bits) {
      if (_el / 1000 < p.forsink) continue;
      final drag = math.exp(-p.luft * dt);
      p.vx *= drag;
      p.vy = p.vy * drag + 980 * dt;
      p.vz = p.vz * math.exp(-3.2 * dt) - 60 * dt;
      p.x += p.vx * dt + math.sin(p.fl + _el / 1000 * p.flF) * 26 * dt * (p.luft > 2 ? 1 : .3);
      p.y += p.vy * dt;
      p.z = math.min(430, p.z + p.vz * dt);
      p.rx += p.wx * dt;
      p.ry += p.wy * dt;
      p.rz += p.wz * dt;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done || !_ticker.isActive) return const SizedBox.shrink();
    return RepaintBoundary(child: CustomPaint(painter: _KonfettiPainter(_bits, _el), size: Size.infinite));
  }
}

class _KonfettiPainter extends CustomPainter {
  _KonfettiPainter(this.bits, this.el);

  final List<_Bit> bits;
  final double el;

  @override
  void paint(Canvas canvas, Size size) {
    const persp = 640.0;
    final cx = size.width / 2, cy = size.height * .26;
    final ox = size.width * .5, oy = size.height * .4; // perspective-origin
    final ut = ((el - (3400 - 700)) / 700).clamp(0.0, 1.0);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (final p in bits) {
      final ax = rad(p.rx), ay = rad(p.ry), az = rad(p.rz);
      final lys = (math.cos(ax) * math.cos(ay)).abs();
      final color = (lys > .45 ? p.f0 : p.f1).withValues(alpha: 1 - ut);
      // Corners in the piece's frame → rotateX·rotateY·rotateZ → translate.
      final hw = p.w / 2, hh = p.h / 2;
      final pts = <Offset>[];
      for (final (u, v) in [(-hw, -hh), (hw, -hh), (hw, hh), (-hw, hh)]) {
        // rotateZ
        var x = u * math.cos(az) - v * math.sin(az);
        var y = u * math.sin(az) + v * math.cos(az);
        var z = 0.0;
        // rotateY
        final x1 = x * math.cos(ay) + z * math.sin(ay);
        final z1 = -x * math.sin(ay) + z * math.cos(ay);
        x = x1;
        z = z1;
        // rotateX
        final y2 = y * math.cos(ax) - z * math.sin(ax);
        final z2 = y * math.sin(ax) + z * math.cos(ax);
        y = y2;
        z = z2;
        final wx = cx + p.x + x, wy = cy + p.y + y, wz = p.z + z;
        final k = persp / math.max(1, persp - wz);
        pts.add(Offset(ox + (wx - ox) * k, oy + (wy - oy) * k));
      }
      final paint = Paint()..color = color;
      if (p.type == 2) {
        final c = (pts[0] + pts[2]) / 2;
        final rx = (pts[1] - pts[0]).distance / 2, ry = (pts[3] - pts[0]).distance / 2;
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.rotate(math.atan2(pts[1].dy - pts[0].dy, pts[1].dx - pts[0].dx));
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2), paint);
        canvas.restore();
      } else {
        canvas.drawPath(Path()..addPolygon(pts, true), paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_KonfettiPainter old) => true;
}
