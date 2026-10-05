part of 'launch_onboarding.dart';

// ── Konto (`onbErKonto`, L2079–2124) ────────────────────────────────────────

const Color _kIdle = Color.fromRGBO(35, 32, 29, .12);
const Color _kOk = Color(0xFF2FB893);
const Color _kWarn = Color(0xFFF26D3D);

extension _Konto on LaunchOnboardingState {
  Widget _konto(BuildContext context, double inset) {
    final logg = _logg;
    final pass = _pass.text;
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(22, inset + 84, 22, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _kontoFaner(logg),
          const SizedBox(height: 18),
          Text(logg ? LfCopy.velkommenTilbake : LfCopy.opprettKonto, style: jakarta(24, em: -.03)),
          const SizedBox(height: 6),
          Text(logg ? LfCopy.loggUnder : LfCopy.regUnder,
              style: inter(12.5, height: 1.45, color: const Color(0xFFDCE9EC))),
          const SizedBox(height: 12),
          LfAegilPortrait(text: LfCopy.aegilKonto, image: 'assets/images/aegil/voucher.png'),
          const SizedBox(height: 18),
          if (!logg) ...[
            LfField(
              label: LfCopy.fulltNavn,
              controller: _navn,
              hint: LfCopy.navnHint,
              accent: _navnOk ? _kOk : _kIdle,
              icon: lfFieldIcon(LfIco.userExtra),
              autofill: const [AutofillHints.name],
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 13),
            LfField(
              label: LfCopy.epost,
              controller: _epost,
              hint: LfCopy.epostHint,
              accent: _epostOk ? _kOk : _kIdle,
              icon: lfFieldIcon(LfIco.mailExtra),
              keyboard: TextInputType.emailAddress,
              autofill: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 13),
            LfField(
              label: LfCopy.passord,
              controller: _pass,
              hint: LfCopy.passHint,
              obscure: true,
              accent: pass.length >= 6 ? _kOk : (pass.isNotEmpty ? _kWarn : _kIdle),
              icon: lfFieldIcon(LfIco.lockExtra),
              autofill: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 10),
            _styrke(pass),
            const SizedBox(height: 13),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color.fromRGBO(92, 224, 184, .12),
                border: Border.all(color: const Color.fromRGBO(92, 224, 184, .3)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset('assets/images/aegil/voucher.png', width: 38, height: 38, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      (_erVerv || _vervOk) ? LfCopy.bonusVerv : LfCopy.bonusOrg,
                      style: inter(11.5, weight: FontWeight.w700, height: 1.4, color: const Color(0xFFCFF3E6)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            LfCta(label: LfCopy.opprettKonto, ready: _regOk, onTap: _tilTelefon),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _set(() => _logg = true),
              child: Padding(
                padding: const EdgeInsets.only(top: 13),
                child: Text.rich(
                  TextSpan(
                    style: inter(12.5, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .6)),
                    children: [
                      TextSpan(text: LfCopy.harKonto),
                      TextSpan(
                        text: LfCopy.loggInn,
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFF9A273)),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ] else ...[
            LfField(
              label: LfCopy.epost,
              controller: _epost,
              hint: LfCopy.epostHintLogg,
              accent: _epostOk ? _kOk : _kIdle,
              icon: lfFieldIcon(LfIco.mailExtra),
              keyboard: TextInputType.emailAddress,
              autofill: const [AutofillHints.email, AutofillHints.username],
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 13),
            Builder(
              builder: (ctx) => LfField(
                label: LfCopy.passord,
                controller: _pass,
                hint: LfCopy.passHintLogg,
                obscure: true,
                accent: pass.length >= 6 ? _kOk : (pass.isNotEmpty ? _kWarn : _kIdle),
                icon: lfFieldIcon(LfIco.lockExtra),
                autofill: const [AutofillHints.password],
                textInputAction: TextInputAction.go,
                onSubmitted: (_) => _loggInn(_rectOf(ctx)),
              ),
            ),
            const SizedBox(height: 18),
            Builder(
              builder: (ctx) => LfCta(label: LfCopy.loggInn, ready: _loggOk, onTap: () => _loggInn(_rectOf(ctx))),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => lfForgotPassword(context),
              child: Padding(
                padding: const EdgeInsets.only(top: 13),
                child: Text(
                  LfCopy.glemtPassord,
                  textAlign: TextAlign.right,
                  style: inter(12, weight: FontWeight.w800, color: const Color(0xFFF9A273)),
                ),
              ),
            ),
          ],
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _gaa(LfSteg.landing),
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                LfCopy.tilbakeInnlogging,
                textAlign: TextAlign.center,
                style: inter(12, weight: FontWeight.w800, color: const Color.fromRGBO(255, 255, 255, .45)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kontoFaner(bool logg) {
    const c = Cubic(.34, 1.32, .5, 1);
    return CssBox(
      radius: BorderRadius.circular(17),
      bg: const [CssSolid(Color.fromRGBO(8, 26, 36, .34))],
      shadows: const [
        CssShadow.inset(0, 1, 3, 0, Color.fromRGBO(3, 16, 24, .5)),
        CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .1)),
      ],
      padding: const EdgeInsets.all(4),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 420),
              curve: c,
              alignment: logg ? Alignment.centerRight : Alignment.centerLeft,
              child: const FractionallySizedBox(
                widthFactor: .5,
                heightFactor: 1,
                child: CssBox(
                  radius: BorderRadius.all(Radius.circular(13)),
                  bg: [CssSolid(Colors.white)],
                  shadows: [
                    CssShadow(0, 2, 0, 0, Color.fromRGBO(180, 171, 160, .65)),
                    CssShadow(0, 10, 18, -10, Color.fromRGBO(3, 16, 24, .9)),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final l in [false, true])
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _set(() => _logg = l),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: inter(12.5,
                            weight: FontWeight.w800,
                            height: 1.2,
                            color: l == logg ? const Color(0xFF0F1F2B) : const Color.fromRGBO(255, 255, 255, .6)),
                        child: Text(l ? LfCopy.loggInn : LfCopy.opprettKonto, textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _styrke(String pass) {
    final n = pass.length;
    final on = n >= 10 ? const Color(0xFF5CE0B8) : (n >= 6 ? const Color(0xFFF2C14E) : const Color(0xFFE9573A));
    final tx = n == 0 ? '' : (n >= 10 ? LfCopy.sterkt : (n >= 6 ? LfCopy.greit : LfCopy.forKort));
    final tc = n >= 10 ? const Color(0xFF9FE0C8) : (n >= 6 ? const Color(0xFFF2C14E) : const Color(0xFFF09578));
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: n >= const [1, 6, 10][i] ? on : const Color.fromRGBO(255, 255, 255, .14),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 7),
        Text(tx, style: inter(10.5, weight: FontWeight.w800, height: 1.2, color: tc)),
      ],
    );
  }
}
