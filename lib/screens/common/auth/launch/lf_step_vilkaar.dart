part of 'launch_onboarding.dart';

// ── Vilkår (`onbErVilkaar`, L2030) and the text pages (`onbErTekst`, L2059) ─

extension _Vilkaar on LaunchOnboardingState {
  Widget _vilkaar(BuildContext context, double inset) {
    final ok = _godtatt;
    return Padding(
      padding: EdgeInsets.fromLTRB(22, inset + 84, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LfRise(delay: 50, child: Text(LfCopy.vilkaarTittel, style: jakarta(26, em: -.035, height: 1.1))),
          const SizedBox(height: 12),
          LfAegilStanding(text: _vipps ? LfCopy.aegilVilkaarVipps : LfCopy.aegilVilkaar),
          const SizedBox(height: 18),
          LfRise(
            delay: 260,
            child: _docTile(
              tile: const CssBox(
                width: 50,
                height: 50,
                radius: BorderRadius.all(Radius.circular(16)),
                bg: [CssLinear(180, [Color(0xFFFFA77C), Color(0xFFF26D3D), Color(0xFFE95C2C)], [0, .55, 1])],
                shadows: [
                  CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .5)),
                  CssShadow(0, 3, 0, 0, Color(0xFFA63A12)),
                  CssShadow(0, 8, 12, -6, Color.fromRGBO(120, 40, 10, .5)),
                ],
                child: Center(child: LfSvg(kLfDocSvg, w: 30, h: 30)),
              ),
              title: LfCopy.vilkaarDoc,
              sub: LfCopy.vilkaarDocSub,
              tid: LfCopy.vilkaarDocTid,
              lest: _lestV,
              onTap: () {
                _set(() => _lestV = true);
                _gaa(LfSteg.vilkaarTekst);
              },
            ),
          ),
          const SizedBox(height: 10),
          LfRise(
            delay: 340,
            child: _docTile(
              tile: const CssBox(
                width: 50,
                height: 50,
                radius: BorderRadius.all(Radius.circular(16)),
                bg: [CssLinear(180, [Color(0xFFA6F8DD), Color(0xFF5CE0B8), Color(0xFF3CC79F)], [0, .55, 1])],
                shadows: [
                  CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .6)),
                  CssShadow(0, 3, 0, 0, Color(0xFF23946F)),
                  CssShadow(0, 8, 12, -6, Color.fromRGBO(20, 110, 80, .5)),
                ],
                child: Center(child: LfSvg(kLfShieldSvg, w: 30, h: 30)),
              ),
              title: LfCopy.personvernDoc,
              sub: LfCopy.personvernDocSub,
              tid: LfCopy.personvernDocTid,
              lest: _lestP,
              onTap: () {
                _set(() => _lestP = true);
                _gaa(LfSteg.personvern);
              },
            ),
          ),
          const SizedBox(height: 16),
          LfShake(
            trigger: _rist,
            child: LfPress(
              dy: 2,
              onTap: () => _set(() {
                _godtatt = !_godtatt;
                _feil = false;
              }),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: CssBox(
                  key: ValueKey('huk-$ok-$_feil'),
                  radius: BorderRadius.circular(18),
                  bg: [
                    ok
                        ? const CssLinear(180, [Color.fromRGBO(92, 224, 184, .24), Color.fromRGBO(92, 224, 184, .1)])
                        : const CssLinear(180, [Color.fromRGBO(255, 255, 255, .14), Color.fromRGBO(255, 255, 255, .05)]),
                  ],
                  shadows: ok
                      ? const [
                          CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .3)),
                          CssShadow.inset(0, 0, 0, 1.5, Color.fromRGBO(92, 224, 184, .7)),
                          CssShadow(0, 3, 0, 0, Color.fromRGBO(4, 20, 28, .45)),
                        ]
                      : _feil
                      ? const [
                          CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .25)),
                          CssShadow.inset(0, 0, 0, 1.5, Color.fromRGBO(255, 148, 102, .8)),
                          CssShadow(0, 3, 0, 0, Color.fromRGBO(4, 20, 28, .45)),
                        ]
                      : const [
                          CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .25)),
                          CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .16)),
                          CssShadow(0, 3, 0, 0, Color.fromRGBO(4, 20, 28, .45)),
                        ],
                  padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: CssBox(
                                radius: BorderRadius.circular(10),
                                bg: [
                                  ok
                                      ? const CssLinear(180, [Color(0xFFA6F8DD), Color(0xFF3CC79F)])
                                      : const CssSolid(Color.fromRGBO(0, 0, 0, .25)),
                                ],
                                shadows: ok
                                    ? const [
                                        CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .6)),
                                        CssShadow(0, 2.5, 0, 0, Color(0xFF23946F)),
                                      ]
                                    : const [
                                        CssShadow.inset(0, 2, 3, 0, Color.fromRGBO(0, 0, 0, .35)),
                                        CssShadow.inset(0, 0, 0, 1.5, Color.fromRGBO(255, 255, 255, .35)),
                                      ],
                              ),
                            ),
                            if (ok) ...[
                              Positioned(
                                left: -6,
                                top: -6,
                                right: -6,
                                bottom: -6,
                                child: LfOnce(
                                  ms: 700,
                                  builder: (context, t, child) {
                                    final p = cssEaseOut.transform(kfP(t, 0, 700));
                                    return Opacity(
                                      opacity: (.9 * (1 - p)).clamp(0.0, 1.0),
                                      child: Transform.scale(scale: .6 + 1.3 * p, child: child),
                                    );
                                  },
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: const Color.fromRGBO(127, 240, 203, .8), width: 2),
                                    ),
                                  ),
                                ),
                              ),
                              Center(
                                child: LfOnce(
                                  ms: 380,
                                  builder: (context, t, child) => lfHake(t / 380, child!),
                                  child: const LfStroke(LfIco.check, size: 16, color: Color(0xFF0F3A40), width: 3.6),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: inter(12.5, weight: FontWeight.w700, height: 1.45, color: const Color(0xFFF2F8F9)),
                            children: [
                              TextSpan(text: LfCopy.godtarA),
                              TextSpan(
                                text: LfCopy.godtarB,
                                style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFFFB089)),
                              ),
                              TextSpan(text: LfCopy.godtarC),
                              TextSpan(
                                text: LfCopy.godtarD,
                                style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFFFB089)),
                              ),
                              const TextSpan(text: '.'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          const SizedBox(height: 12),
          Builder(
            builder: (ctx) => LfCta(
              label: LfCopy.godtaFortsett,
              ready: ok,
              onTap: () => _godtaFortsett(_rectOf(ctx)),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _seRundt(LfCopy.avvisToast),
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                LfCopy.avvis,
                textAlign: TextAlign.center,
                style: inter(12.5, weight: FontWeight.w800, color: const Color.fromRGBO(255, 255, 255, .5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _docTile({
    required Widget tile,
    required String title,
    required String sub,
    required String tid,
    required bool lest,
    required VoidCallback onTap,
  }) {
    return LfPress(
      dy: 2,
      ms: 140,
      onTap: onTap,
      child: CssBox(
        radius: BorderRadius.circular(20),
        bg: const [CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFF3F6F5)])],
        shadows: const [
          CssShadow.inset(0, 1.5, 0, 0, Color(0xFFFFFFFF)),
          CssShadow(0, 4, 0, 0, Color(0xFFA9BBBF)),
          CssShadow(0, 16, 24, -14, Color.fromRGBO(3, 16, 24, .9)),
        ],
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            tile,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(title,
                            softWrap: false,
                            overflow: TextOverflow.fade,
                            style: jakarta(14.5, em: -.01, color: const Color(0xFF173E48))),
                      ),
                      if (lest) ...[
                        const SizedBox(width: 7),
                        LfOnce(
                          ms: 350,
                          builder: (context, t, child) {
                            final p = const Cubic(.2, 1.3, .3, 1).transform(kfP(t, 0, 350));
                            return Opacity(
                              opacity: p.clamp(0.0, 1.0),
                              child: Transform.translate(
                                offset: Offset(0, 8 * (1 - p)),
                                child: Transform.scale(scale: .85 + .15 * p, child: child),
                              ),
                            );
                          },
                          child: CssBox(
                            height: 22,
                            radius: BorderRadius.circular(999),
                            bg: const [CssSolid(Color(0xFFE0F8EF))],
                            shadows: const [CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(47, 184, 147, .45))],
                            padding: const EdgeInsets.fromLTRB(6, 0, 8, 0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const LfStroke(LfIco.checkLest, size: 10, color: Color(0xFF1F8A66), width: 3.6),
                                const SizedBox(width: 4),
                                Text(LfCopy.lest, style: inter(10, weight: FontWeight.w800, color: const Color(0xFF1F8A66))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(sub, style: inter(11.5, height: 1.35, color: const Color(0xFF6B655D))),
                  const SizedBox(height: 2),
                  Text(tid, style: inter(10.5, weight: FontWeight.w700, color: const Color(0xFF8C847C))),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const CssBox(
              width: 32,
              height: 32,
              radius: BorderRadius.all(Radius.circular(16)),
              bg: [CssSolid(Color(0xFFEEF4F5))],
              shadows: [CssShadow.inset(0, -1.5, 0, 0, Color.fromRGBO(30, 79, 92, .14))],
              child: Center(child: LfStroke(LfIco.chevronRight, size: 12, color: Color(0xFF1E4F5C), width: 3)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tekst(BuildContext context, double inset) {
    final erV = _steg == LfSteg.vilkaarTekst;
    final bolker = erV ? LfCopy.vilkaarBolker : LfCopy.personvernBolker;
    final body = inter(12.5, weight: FontWeight.w500, height: 1.55, color: const Color(0xFF4A4741));
    return Padding(
      padding: EdgeInsets.fromLTRB(16, inset + 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                LfPress(
                  scale: .92,
                  onTap: () => _gaa(LfSteg.vilkaar),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromRGBO(3, 16, 24, .8),
                          offset: const Offset(0, 8),
                          blurRadius: cssSigma(16) / .57735,
                          spreadRadius: -8,
                        ),
                      ],
                    ),
                    child: const Center(child: LfStroke(LfIco.chevronLeft, size: 16, color: Color(0xFF0F1F2B), width: 2.6)),
                  ),
                ),
                const SizedBox(width: 12),
                Text(erV ? LfCopy.vilkaarDoc : LfCopy.personvern, style: jakarta(18, em: -.02)),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(3, 16, 24, .9),
                    offset: const Offset(0, 24),
                    blurRadius: cssSigma(40) / .57735,
                    spreadRadius: -22,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(LfCopy.oppdatert, style: inter(10, weight: FontWeight.w800, em: .1, color: const Color(0xFF8C847C))),
                      for (final (h, tx, punkter) in bolker) ...[
                        const SizedBox(height: 16),
                        Text(h, style: jakarta(14.5, em: -.015, color: const Color(0xFF173E48))),
                        if (tx.isNotEmpty) ...[const SizedBox(height: 5), Text(tx, style: body)],
                        for (final p in punkter)
                          Padding(
                            padding: const EdgeInsets.only(top: 7),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.only(top: 6),
                                  decoration: const BoxDecoration(color: Color(0xFFF26D3D), shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 9),
                                Expanded(child: Text(p, style: body.copyWith(height: 1.5))),
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          LfPillCta(
            onTap: () => _gaa(LfSteg.vilkaar),
            child: Text(LfCopy.tilbakeVilkaar, style: jakarta(15)),
          ),
        ],
      ),
    );
  }
}

/// Global rect of the widget at [ctx] (the ring transition's origin).
Rect? _rectOf(BuildContext ctx) {
  final b = ctx.findRenderObject() as RenderBox?;
  if (b == null || !b.hasSize) return null;
  return b.localToGlobal(Offset.zero) & b.size;
}
