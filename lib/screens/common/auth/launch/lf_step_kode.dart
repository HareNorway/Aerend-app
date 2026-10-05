part of 'launch_onboarding.dart';

// ── Telefon (`onbErTelefon`, L2126) and Kode (`onbErKode`, L2143) ───────────

extension _Kode on LaunchOnboardingState {
  /// The framed Ægil with the keel shadow (`onbKjol`) under it.
  Widget _kjolAegil(String image, double size, double radius, double shadowW, double shadowLeft) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: shadowLeft,
            bottom: -6,
            width: shadowW,
            height: 14,
            child: LfLoop(
              builder: (context, t, child) {
                final p = (t / 3400) % 1.0;
                final s = kf(p, const [0, .5, 1], const [1, 1.3, 1], cssEaseInOut);
                final o = kf(p, const [0, .5, 1], const [.5, .2, .5], cssEaseInOut);
                return Opacity(opacity: o, child: Transform.scale(scaleX: s, child: child));
              },
              child: const CssBox(
                bg: [
                  CssRadial([Color.fromRGBO(3, 16, 24, .75), Color.fromRGBO(3, 16, 24, .25), Color.fromRGBO(3, 16, 24, 0)],
                      stops: [0, .45, .9]),
                ],
              ),
            ),
          ),
          LfLoop(
            builder: (context, t, child) => Transform(transform: onbBaat(t), alignment: Alignment.center, child: child),
            child: LfPortrait(image: image, size: size, radius: radius),
          ),
        ],
      ),
    );
  }

  Widget _telefon(BuildContext context, double inset) {
    final ok = _tlfOk;
    final tlf = _tlf.text;
    return Padding(
      padding: EdgeInsets.fromLTRB(22, inset + 84, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              _kjolAegil('assets/images/aegil/aegil_phone.png', 96, 28, 72, 12),
              const SizedBox(height: 14),
              Text(LfCopy.tlfTittel, style: jakarta(24, em: -.03)),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 250),
                child: Text(LfCopy.tlfUnder,
                    textAlign: TextAlign.center, style: inter(12.5, color: const Color(0xFFDCE9EC))),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              CssBox(
                height: 58,
                radius: BorderRadius.circular(17),
                bg: const [CssSolid(Colors.white)],
                shadows: const [
                  CssShadow(0, 2, 0, 0, Color.fromRGBO(180, 171, 160, .8)),
                  CssShadow(0, 14, 24, -16, Color.fromRGBO(3, 16, 24, .9)),
                ],
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Center(
                  child: Text('🇳🇴 +47', style: inter(14, weight: FontWeight.w800, color: const Color(0xFF23201D))),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: LfField(
                  label: LfCopy.tlfLabel,
                  controller: _tlf,
                  hint: LfCopy.tlfHint,
                  accent: ok ? _kOk : (tlf.isNotEmpty ? _kWarn : _kIdle),
                  keyboard: TextInputType.phone,
                  autofill: const [AutofillHints.telephoneNumberNational],
                  formatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d ]')),
                    LengthLimitingTextInputFormatter(12),
                  ],
                  inputStyle: inter(16, weight: FontWeight.w800, em: .04, color: const Color(0xFF23201D)),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendKode(),
                ),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(height: 12),
          LfCta(label: LfCopy.sendKode, ready: ok, onTap: _sendKode),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _onBack(),
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(LfCopy.tilbake,
                  textAlign: TextAlign.center,
                  style: inter(12.5, weight: FontWeight.w800, color: const Color.fromRGBO(255, 255, 255, .5))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kodeSteg(BuildContext context, double inset) {
    final kode = _kodeV;
    final tlf = _tlf.text.trim().isEmpty ? LfCopy.tlfHint : _tlf.text.trim();
    return Padding(
      padding: EdgeInsets.fromLTRB(22, inset + 84, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              _kjolAegil('assets/images/aegil/find.png', 84, 26, 64, 10),
              const SizedBox(height: 12),
              Text(LfCopy.kodeTittel, style: jakarta(25, em: -.03)),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  style: inter(12.5, color: const Color(0xFFDCE9EC)),
                  children: [
                    TextSpan(text: LfCopy.kodeSendt),
                    TextSpan(text: '+47 $tlf', style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              // The prototype's demo hint; the local backend runs in OTP test
              // mode with the same code. Debug builds only.
              if (kDebugMode) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color.fromRGBO(0, 0, 0, .3),
                    border: Border.all(color: const Color.fromRGBO(255, 255, 255, .14)),
                  ),
                  child: Text.rich(
                    TextSpan(
                      style: inter(11.5, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .72)),
                      children: [
                        TextSpan(text: LfCopy.demoBruk),
                        const TextSpan(
                          text: '1234',
                          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFF9A273), letterSpacing: 1.15),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          LfShake(
            trigger: _rist,
            child: Stack(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 4; i++) ...[
                      if (i > 0) const SizedBox(width: 11),
                      _kodeCelle(i, kode),
                    ],
                  ],
                ),
                Positioned.fill(
                  child: Opacity(
                    opacity: 0,
                    child: TextField(
                      controller: _kode,
                      focusNode: _kodeFokus,
                      keyboardType: TextInputType.number,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                      onChanged: _skrivKode,
                      showCursor: false,
                      enableInteractiveSelection: false,
                      style: const TextStyle(fontSize: 16, color: Colors.transparent),
                      decoration: const InputDecoration(
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        counterText: '',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          LfCta(label: LfCopy.bekreft, ready: kode.length == 4, onTap: _bekreft),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _resend,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                _sek > 0 ? LfCopy.sendPaaNyttOm(_sek) : LfCopy.sendPaaNytt,
                textAlign: TextAlign.center,
                style: inter(12,
                    weight: FontWeight.w800,
                    color: _sek > 0 ? const Color.fromRGBO(255, 255, 255, .45) : const Color(0xFFF9A273)),
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _onBack(),
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const LfStroke(LfIco.pencil, size: 14, color: Color(0xFFF9A273), width: 2.2),
                  const SizedBox(width: 7),
                  Text(LfCopy.endreTlf, style: inter(12.5, weight: FontWeight.w800, color: const Color(0xFFF9A273))),
                ],
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _kodeCelle(int i, String kode) {
    final has = i < kode.length;
    final active = i == kode.length;
    final kant = _feil
        ? const Color(0xFFE9573A)
        : has
        ? const Color(0xFFF26D3D)
        : active
        ? const Color.fromRGBO(242, 109, 61, .55)
        : const Color.fromRGBO(255, 255, 255, .18);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      // `width:62px;height:70px` content-box + the 1.5px border.
      width: 65,
      height: 73,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: has ? const Color.fromRGBO(242, 109, 61, .16) : const Color.fromRGBO(0, 0, 0, .28),
        border: Border.all(color: kant, width: 1.5),
        boxShadow: active && !has ? const [BoxShadow(color: Color.fromRGBO(242, 109, 61, .14), spreadRadius: 4)] : null,
      ),
      alignment: Alignment.center,
      child: has
          ? LfOnce(
              key: ValueKey('k$i-${kode[i]}'),
              ms: 340,
              builder: (context, t, child) {
                final s = kf(t / 340, const [0, .35, .7, 1], const [1, 1.16, .96, 1], const Cubic(.34, 1.56, .64, 1));
                return Transform.scale(scale: s, child: child);
              },
              child: Text(kode[i], style: jakarta(28)),
            )
          : null,
    );
  }
}
