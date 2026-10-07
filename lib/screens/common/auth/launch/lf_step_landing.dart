part of 'launch_onboarding.dart';

// ── Landing (`onbErLanding`, L1919–2028) ────────────────────────────────────

extension _Landing on LaunchOnboardingState {
  Widget _landing(BuildContext context, double inset) {
    final erVerv = _erVerv;
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: LfStepIn(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      if (erVerv) ...[
                        SizedBox(height: 16 + inset),
                        _header(),
                        const SizedBox(height: 2),
                        _vervKort(),
                      ] else
                        SizedBox(
                          height: 16 + 35 + 294,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Positioned(left: -22, top: -7, child: LfWelcomeScene()),
                              Positioned(left: 0, right: 0, top: 16 + inset, child: _header()),
                            ],
                          ),
                        ),
                      const SizedBox(height: 6),
                      LfRise(
                        delay: 100,
                        child: LfBalanced(
                          erVerv ? LfCopy.tittelVerv(_vervNavn) : LfCopy.tittel,
                          style: jakarta(28, em: -.035, height: 1.1),
                        ),
                      ),
                      const SizedBox(height: 8),
                      LfRise(
                        delay: 160,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 290),
                          child: Text(
                            LfCopy.under,
                            textAlign: TextAlign.center,
                            style: inter(13, height: 1.45, color: const Color(0xFFDCE9EC)),
                          ),
                        ),
                      ),
                      if (erVerv)
                        LfRise(
                          delay: 220,
                          child: GestureDetector(
                            onTap: () => _set(() => _fane = false),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
                              child: Text(LfCopy.annenKode,
                                  style: inter(12, weight: FontWeight.w800, color: const Color(0xFF9FE0C8))),
                            ),
                          ),
                        )
                      else ...[
                        const SizedBox(height: 16),
                        _chips(),
                        if (!_inv && !_kodeAapen)
                          LfRise(
                            delay: 220,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _set(() => _kodeAapen = true),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const LfStroke(LfIco.plus, size: 14, color: Color(0xFF9FE0C8), width: 2.6, join: false),
                                    const SizedBox(width: 7),
                                    Text(LfCopy.harVervekode,
                                        style: inter(12, weight: FontWeight.w800, color: const Color(0xFF9FE0C8))),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else ...[
                          const SizedBox(height: 14),
                          LfRise(dur: 350, child: _kodeFelt()),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  _vervSvar.isNotEmpty ? _vervSvar : (kDebugMode ? LfCopy.vervHint : ''),
                                  style: inter(11,
                                      weight: FontWeight.w700,
                                      color: _vervOk ? const Color(0xFF9FE0C8) : const Color.fromRGBO(255, 255, 255, .5)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              if (_inv)
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => _set(() => _fane = true),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Text(LfCopy.invitasjonen(_vervNavn),
                                        style: inter(12, weight: FontWeight.w800, color: const Color(0xFF9FE0C8))),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                      const SizedBox(height: 22),
                    ],
                  ),
                  Column(
                    children: [
                      LfRise(delay: 340, dur: 400, child: _vippsKnapp()),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: LfRise(
                              delay: 400,
                              dur: 400,
                              child: _hvitKnapp(
                                icon: const LfSvg(kLfGoogleSvg, w: 18, h: 18),
                                label: 'Google',
                                onTap: () => _velgMetode(LfMetode.google),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: LfRise(
                              delay: 460,
                              dur: 400,
                              child: _hvitKnapp(
                                icon: const LfSvg(kLfAppleSvg, w: 16, h: 18),
                                label: 'Apple',
                                onTap: () => _velgMetode(LfMetode.apple),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      LfRise(
                        delay: 520,
                        dur: 400,
                        // A Wrap so large text / English never overflows;
                        // one line at the design's sizes.
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _velgMetode(LfMetode.epost),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                                child: Text(LfCopy.brukEpost, style: inter(12.5, weight: FontWeight.w800)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(color: Color.fromRGBO(255, 255, 255, .35), shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 14),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _seRundt(LfCopy.seRundtToast),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const LfStroke('', extra: LfIco.searchExtra, size: 14, color: Color(0xFFF9A273), width: 2.4, join: false),
                                    const SizedBox(width: 6),
                                    Text(LfCopy.seRundt, style: inter(12.5, weight: FontWeight.w800, color: const Color(0xFFF9A273))),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Logo + NO/EN switch (`z-index:3`, above the scene).
  Widget _header() {
    const knobCurve = Cubic(.34, 1.56, .64, 1);
    return SizedBox(
      height: 35,
      child: Row(
        children: [
          const LfMerke(w: 44, h: 35),
          const Spacer(),
          CssBox(
            width: 88,
            height: 32,
            radius: BorderRadius.circular(999),
            bg: const [
              CssLinear(180, [Color.fromRGBO(4, 18, 26, .42), Color.fromRGBO(4, 18, 26, .24)]),
            ],
            border: Border.all(color: const Color.fromRGBO(255, 255, 255, .2)),
            shadows: const [
              CssShadow.inset(0, 2, 5, 0, Color.fromRGBO(0, 0, 0, .4)),
              CssShadow.inset(0, -1, 0, 0, Color.fromRGBO(255, 255, 255, .12)),
              CssShadow(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .14)),
            ],
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Stack(
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 460),
                    curve: knobCurve,
                    alignment: _en ? Alignment.centerRight : Alignment.centerLeft,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 460),
                      curve: knobCurve,
                      scale: _knottPop ? 1.05 : 1,
                      child: Transform.scale(
                        scaleX: _knottPop ? 1.1 / 1.05 : 1,
                        scaleY: _knottPop ? .92 / 1.05 : 1,
                        child: const CssBox(
                          width: 40,
                          height: 24,
                          radius: BorderRadius.all(Radius.circular(999)),
                          bg: [
                            CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFEEF3F4), Color(0xFFDCE6E8)], [0, .6, 1]),
                          ],
                          shadows: [
                            CssShadow.inset(0, 1.5, 0, 0, Color(0xFFFFFFFF)),
                            CssShadow.inset(0, -2, 3, 0, Color.fromRGBO(30, 79, 92, .18)),
                            CssShadow(0, 2, 0, 0, Color.fromRGBO(150, 175, 182, .9)),
                            CssShadow(0, 3, 0, 0, Color.fromRGBO(4, 18, 26, .3)),
                            CssShadow(0, 8, 14, -6, Color.fromRGBO(4, 18, 26, .7)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (final no in [true, false])
                        Expanded(
                          child: LfPress(
                            scale: .9,
                            ms: 180,
                            onTap: () => _sprak(no),
                            child: Center(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 300),
                                style: inter(11.5,
                                    weight: FontWeight.w800,
                                    em: .04,
                                    color: (no != _en) ? const Color(0xFF0F1F2B) : const Color.fromRGBO(255, 255, 255, .7)),
                                child: Text(no ? 'NO' : 'EN'),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chips() {
    Widget chip(Widget icon, String label, double delay) => LfRise(
      delay: delay,
      dur: 500,
      child: CssBox(
        radius: BorderRadius.circular(18),
        bg: const [
          CssLinear(180, [Color.fromRGBO(255, 255, 255, .14), Color.fromRGBO(255, 255, 255, .05)]),
        ],
        shadows: const [
          CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .28)),
          CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .1)),
          CssShadow(0, 3, 0, 0, Color.fromRGBO(8, 28, 36, .45)),
          CssShadow(0, 14, 20, -14, Color.fromRGBO(3, 14, 20, .8)),
        ],
        padding: const EdgeInsets.fromLTRB(6, 12, 6, 11),
        child: Column(
          children: [
            CssBox(
              width: 32,
              height: 32,
              radius: BorderRadius.circular(11),
              bg: const [
                CssLinear(160, [Color(0xFF3F8798), Color(0xFF27606F), Color(0xFF1A4654)], [0, .52, 1]),
              ],
              shadows: const [
                CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .32)),
                CssShadow.inset(0, -3, 5, 0, Color.fromRGBO(4, 20, 28, .42)),
                CssShadow(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .07)),
                CssShadow(0, 8, 10, -6, Color.fromRGBO(3, 16, 24, .8)),
              ],
              child: Center(child: icon),
            ),
            const SizedBox(height: 7),
            SizedBox(
              height: 2 * 10.5 * 1.25,
              child: Align(
                alignment: Alignment.topCenter,
                child: LfBalanced(label, style: inter(10.5, weight: FontWeight.w800, height: 1.25)),
              ),
            ),
          ],
        ),
      ),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: chip(const LfStroke(LfIco.store, size: 16, color: Colors.white, width: 2.4), LfCopy.chipButikker, 220)),
        const SizedBox(width: 8),
        Expanded(child: chip(const LfStroke('', extra: LfIco.bikeExtra, size: 16, color: Colors.white, width: 2.4), LfCopy.chipBud, 280)),
        const SizedBox(width: 8),
        Expanded(child: chip(const LfStroke(LfIco.star, size: 16, color: Colors.white, width: 2.4), LfCopy.chipPoeng, 340)),
      ],
    );
  }

  /// The glass referral field with the 3D "Bruk" button.
  Widget _kodeFelt() {
    final op = _verv.text.length > 3 ? 1.0 : .45;
    return SizedBox(
      height: 54,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          Positioned.fill(
            child: CssBox(
              radius: BorderRadius.circular(18),
              bg: const [
                CssLinear(180, [Color.fromRGBO(255, 255, 255, .16), Color.fromRGBO(255, 255, 255, .07)]),
              ],
              shadows: const [
                CssShadow.inset(0, 2, 4, 0, Color.fromRGBO(3, 16, 24, .35)),
                CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .18)),
                CssShadow(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .12)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 6, 6),
            child: Row(
              children: [
                const LfStroke('', extra: LfIco.ticketExtra, size: 16, color: Color(0xFF9FF0D4), width: 2.2),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _verv,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(14),
                      TextInputFormatter.withFunction((o, n) => n.copyWith(text: n.text.toUpperCase())),
                    ],
                    onChanged: (_) => _set(() {
                      _vervSvar = '';
                      _vervOk = false;
                    }),
                    onSubmitted: (_) => _brukVerv(),
                    autocorrect: false,
                    cursorColor: const Color(0xFFFF9466),
                    style: inter(14, weight: FontWeight.w800, em: .06),
                    decoration: InputDecoration(
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: LfCopy.vervekode,
                      hintStyle: inter(14, weight: FontWeight.w800, em: .06, color: const Color.fromRGBO(255, 255, 255, .4)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                LfPress(
                  dy: 2,
                  onTap: _brukVerv,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: SizedBox(
                      height: 40,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Positioned.fill(
                            child: CssBox(
                              radius: BorderRadius.all(Radius.circular(13)),
                              bg: [
                                CssLinear(180, [Color.fromRGBO(255, 255, 255, .18), Color.fromRGBO(255, 255, 255, .08)]),
                              ],
                              shadows: [
                                CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .3)),
                                CssShadow(0, 2.5, 0, 0, Color.fromRGBO(6, 22, 30, .55)),
                              ],
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            bottom: -2.5,
                            child: AnimatedOpacity(
                              opacity: op,
                              duration: const Duration(milliseconds: 200),
                              child: const CssBox(
                                radius: BorderRadius.all(Radius.circular(13)),
                                bg: [CssLinear(180, [Color(0xFFFF9466), Color(0xFFE95C2C)])],
                                shadows: [
                                  CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .45)),
                                  CssShadow.inset(0, -2.5, 0, 0, Color(0xFFA63A12)),
                                  CssShadow(0, 8, 12, -6, Color.fromRGBO(3, 16, 24, .7)),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Center(child: Text(LfCopy.bruk, style: inter(13, weight: FontWeight.w800))),
                          ),
                        ],
                      ),
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

  Widget _vippsKnapp() {
    return _Knapp3D(
      height: 54,
      radius: 18,
      bg: const [
        CssRadial(
          [Color.fromRGBO(255, 255, 255, .28), Color.fromRGBO(255, 255, 255, 0)],
          stops: [0, .7],
          rx: .8,
          ry: .6,
          cx: .5,
          cy: 0,
        ),
        CssLinear(180, [Color(0xFFFF9466), Color(0xFFE95C2C), Color(0xFFD9501F)], [0, .62, 1]),
      ],
      up: const [
        CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .5)),
        CssShadow.inset(0, -2, 0, 0, Color.fromRGBO(0, 0, 0, .08)),
        CssShadow(0, 4, 0, 0, Color(0xFFA63A12)),
        CssShadow(0, 18, 24, -10, Color.fromRGBO(3, 16, 24, .85)),
      ],
      down: const [
        CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .4)),
        CssShadow(0, 1, 0, 0, Color(0xFFA63A12)),
        CssShadow(0, 6, 10, -6, Color.fromRGBO(3, 16, 24, .7)),
      ],
      onTap: () => _velgMetode(LfMetode.vipps),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(LfCopy.fortsettMed, style: inter(13, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .92))),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Image.asset('assets/images/vipps_logo_hvit.png', height: 20, filterQuality: FilterQuality.medium),
          ),
        ],
      ),
    );
  }

  Widget _hvitKnapp({required Widget icon, required String label, required VoidCallback onTap}) {
    return _Knapp3D(
      height: 50,
      radius: 16,
      bg: const [
        CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFEEF2F2), Color(0xFFDFE6E7)], [0, .6, 1]),
      ],
      up: const [
        CssShadow.inset(0, 1.5, 0, 0, Color(0xFFFFFFFF)),
        CssShadow.inset(0, -2, 3, 0, Color.fromRGBO(30, 79, 92, .12)),
        CssShadow(0, 3.5, 0, 0, Color(0xFF9FB3B8)),
        CssShadow(0, 14, 20, -10, Color.fromRGBO(3, 16, 24, .8)),
      ],
      down: const [
        CssShadow.inset(0, 1.5, 0, 0, Color(0xFFFFFFFF)),
        CssShadow(0, 1, 0, 0, Color(0xFF9FB3B8)),
        CssShadow(0, 6, 10, -6, Color.fromRGBO(3, 16, 24, .7)),
      ],
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 9),
          Text(label, style: inter(13.5, weight: FontWeight.w800, color: const Color(0xFF23201D))),
        ],
      ),
    );
  }

  // ── Verv card (`onbErVerv`, L1930) ────────────────────────────────────────
  Widget _vervKort() {
    const brev = Cubic(.2, 1.1, .4, 1);
    final navn = _vervNavn;
    return SizedBox(
      height: 290,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          for (final (d, bw, a) in const [(0.0, 1.5, .22), (1800.0, 1.0, .16)])
            Positioned(
              top: 262,
              width: 190,
              height: 34,
              child: LfLoop(
                builder: (context, t, child) {
                  final p = kfLoop(t, d, 3600);
                  if (p == null) return const SizedBox.shrink();
                  final e = cssEaseOut.transform(p);
                  return Opacity(
                    opacity: (.7 * (1 - e)).clamp(0.0, 1.0),
                    child: Transform.scale(scale: .6 + e, child: child),
                  );
                },
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: OvalBorder(side: BorderSide(color: Color.fromRGBO(255, 255, 255, a / .7 * .7), width: bw)),
                  ),
                ),
              ),
            ),
          const Positioned(
            top: 266,
            width: 140,
            height: 20,
            child: CssBox(
              bg: [
                CssRadial.closestSide([Color.fromRGBO(3, 16, 24, .6), Color.fromRGBO(3, 16, 24, 0)], stops: [0, .72]),
              ],
            ),
          ),
          Positioned(
            top: 0,
            width: 244,
            child: LfLoop(
              builder: (context, t, child) {
                final p = kfP(t, 150, 750);
                final y = kf(p, const [0, 1], const [80, 0], brev);
                final r = kf(p, const [0, 1], const [0, -3], brev);
                final s = kf(p, const [0, 1], const [.92, 1], brev);
                final o = kf(p, const [0, .55, 1], const [0, 1, 1], brev);
                final f = kfLoop(t, 1000, 4400);
                final svev = f == null ? 0.0 : kf(f, const [0, .5, 1], const [0, -4, 0], cssEaseInOut);
                return Opacity(
                  opacity: o.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, y + svev),
                    child: Transform(
                      alignment: Alignment.bottomCenter,
                      transform: Matrix4.rotationZ(rad(r))..scaleByDouble(s, s, 1, 1),
                      child: child,
                    ),
                  ),
                );
              },
              child: CssBox(
                radius: BorderRadius.circular(20),
                bg: const [CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFF6F2EA)])],
                shadows: const [
                  CssShadow.inset(0, -2, 0, 0, Color.fromRGBO(180, 171, 160, .35)),
                  CssShadow(0, 22, 34, -20, Color.fromRGBO(3, 16, 24, .9)),
                ],
                padding: const EdgeInsets.fromLTRB(17, 15, 17, 15),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 205 - 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFFF68450), Color(0xFFE65A28)],
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(navn.characters.first.toUpperCase(), style: jakarta(12)),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              LfCopy.invitasjonFra(navn).toUpperCase(),
                              style: inter(10.5, weight: FontWeight.w800, em: .08, color: const Color(0xFF8C847C)),
                            ),
                          ),
                        ],
                      ),
                      // The referral's real amount (`points/rules` referral.referee).
                      if ((_regler?.referee ?? 0) > 0) ...[
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text('+${_regler!.referee}', style: jakarta(38, em: -.04, height: 1, color: const Color(0xFF1E4F5C))),
                            const SizedBox(width: 6),
                            Text(LfCopy.poeng, style: jakarta(15, color: const Color(0xFF1E4F5C))),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(LfCopy.tilDereBegge,
                            style: inter(12, weight: FontWeight.w700, height: 1.4, color: const Color(0xFF57534B))),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 118,
            width: 166,
            height: 166,
            child: IgnorePointer(
              child: LfLoop(
                builder: (context, t, child) =>
                    Transform(transform: aegStaa(t, 3600), alignment: Alignment.bottomCenter, child: child),
                child: Image.asset('assets/images/aegil/aegil_invite.png', fit: BoxFit.contain),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A 3D button whose drop shadow collapses as it presses 3px
/// (`style-active="transform:translateY(3px);box-shadow:…"`, .12s).
class _Knapp3D extends StatefulWidget {
  const _Knapp3D({
    required this.height,
    required this.radius,
    required this.bg,
    required this.up,
    required this.down,
    required this.onTap,
    required this.child,
  });

  final double height;
  final double radius;
  final List<CssBg> bg;
  final List<CssShadow> up;
  final List<CssShadow> down;
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_Knapp3D> createState() => _Knapp3DState();
}

class _Knapp3DState extends State<_Knapp3D> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: cssEase,
        transform: Matrix4.translationValues(0, _down ? 3 : 0, 0),
        child: CssBox(
          height: widget.height,
          radius: BorderRadius.circular(widget.radius),
          bg: widget.bg,
          shadows: _down ? widget.down : widget.up,
          child: widget.child,
        ),
      ),
    );
  }
}
