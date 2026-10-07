part of 'hjelp_sheet.dart';

// ── Support-chat (`hjChat`, L8775–8812) ──────────────────────────────────────

/// One support conversation (`scVals`): the header (subject, assistant /
/// person / closed), the guest step (`scGjest`) when nobody is logged in,
/// the thread (system pills, the customer's orange bubbles, Ægil's glass
/// bubbles and a person's mint bubbles, each with its ORDRE / SAK / … card),
/// the typing dots, the chips, the composer and «Snakk med et menneske».
class _SupportChat extends StatefulWidget {
  const _SupportChat({super.key, required this.samtale, required this.gjest, required this.fornavn, required this.hentOrdre, required this.onTilbake, required this.onGjestBekreftet});

  final SupportSamtale? samtale;
  final bool gjest;
  final String fornavn;
  final Future<SupportOrdre?> Function() hentOrdre;
  final VoidCallback onTilbake;
  final VoidCallback onGjestBekreftet;

  @override
  State<_SupportChat> createState() => _SupportChatState();
}

class _SupportChatState extends State<_SupportChat> {
  final TextEditingController _tekst = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _skriver = false;

  // Guest.
  final TextEditingController _gjestOrdre = TextEditingController();
  final TextEditingController _gjestKode = TextEditingController();
  bool _kodeSendt = false;
  (String, String)? _feil;

  @override
  void initState() {
    super.initState();
    SupportStore.instance.endret.addListener(_endret);
    _tekst.addListener(() => setState(() {}));
    // A person's replies arrive by polling while the chat is on screen.
    if (widget.samtale case final s?) SupportStore.instance.startPolling(s);
  }

  @override
  void dispose() {
    SupportStore.instance.stoppPolling();
    SupportStore.instance.endret.removeListener(_endret);
    _tekst.dispose();
    _scroll.dispose();
    _gjestOrdre.dispose();
    _gjestKode.dispose();
    super.dispose();
  }

  void _endret() {
    if (!mounted) return;
    setState(() {});
    _nedover();
  }

  void _nedover() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 240), curve: Curves.easeOut);
    });
  }

  void _skriverNaa(bool v) {
    if (mounted) setState(() => _skriver = v);
    _nedover();
  }

  Future<void> _send(String t) async {
    final s = widget.samtale;
    if (s == null || t.trim().isEmpty) return;
    _tekst.clear();
    await SupportAssistent.svar(s, t, hentOrdre: widget.hentOrdre, skriver: _skriverNaa);
  }

  Future<void> _menneske() async {
    final s = widget.samtale;
    if (s == null) return;
    if (s.erMenneske) {
      showBergenToast(context, SupportCopy.erISamtalen(s.menneske!));
      return;
    }
    if (s.iKo) {
      showBergenToast(context, SupportCopy.allerede);
      return;
    }
    await SupportAssistent.eskaler(s, skriver: _skriverNaa);
  }

  void _chip(String c) {
    if (RegExp('menneske', caseSensitive: false).hasMatch(c)) {
      _menneske();
      return;
    }
    _send(c);
  }

  /// «Finn bestillingen din» (backend plan Step 5): `support/guest/lookup`
  /// sends a one-time code to the phone on the order, `support/guest/verify`
  /// returns a guest token for that order; the conversation then runs on it.
  bool _gjestVenter = false;

  Future<void> _gjestNeste() async {
    if (_gjestVenter) return;
    final ordre = _gjestOrdre.text.trim().toUpperCase();
    final store = SupportStore.instance;
    setState(() => _gjestVenter = true);
    try {
      if (!_kodeSendt) {
        final (feil, til) = await store.gjestOppslag(ordre);
        if (!mounted) return;
        if (feil != null) {
          setState(() => _feil = (feil, feil == 'OFFLINE' ? SupportCopy.ingenForbindelse : SupportCopy.fantIkke));
          return;
        }
        setState(() {
          _kodeSendt = true;
          _feil = null;
        });
        showBergenToast(context, SupportCopy.kodeSendt(til ?? SupportCopy.gjestKontakt));
        return;
      }
      final feil = await store.gjestBekreft(ordre, _gjestKode.text.trim());
      if (!mounted) return;
      if (feil != null) {
        setState(() => _feil = (feil, feil == 'OFFLINE' ? SupportCopy.ingenForbindelse : SupportCopy.feilKode));
        return;
      }
      showBergenToast(context, SupportCopy.bekreftet);
      widget.onGjestBekreftet();
    } finally {
      if (mounted) setState(() => _gjestVenter = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.samtale;
    final aapen = SupportConfig.aapen();
    final human = s?.erMenneske ?? false;
    final lukket = s?.lukket ?? false;
    final dot = lukket ? rgba(255, 255, 255, .4) : (human || s == null ? kSpMint : (aapen ? const Color(0xFFF2C14E) : rgba(255, 255, 255, .4)));
    final under = s == null
        ? ''
        : lukket
        ? SupportCopy.avsluttetUnder
        : human
        ? SupportCopy.menneskeUnder(s.menneske!.split(' ').first)
        : (aapen ? SupportCopy.aiUnder : SupportCopy.stengtUnder(SupportConfig.aapnerKl));
    return Column(
      key: const Key('a1_hjelp_chat'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 14),
        Row(
          children: [
            _Tilbake(onTap: widget.onTilbake),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s?.emne ?? SupportCopy.emneSupport, key: const Key('a1_hjelp_chat_tittel'), maxLines: 1, overflow: TextOverflow.ellipsis, style: jakarta(18, em: -.02)),
                  if (under.isNotEmpty || widget.gjest) ...[
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: dot,
                            boxShadow: [BoxShadow(color: dot, blurRadius: 6)],
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            under,
                            key: const Key('a1_hjelp_chat_under'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: inter(11.5, color: rgba(255, 255, 255, .62)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (widget.gjest) _gjestKort(),
        if (!widget.gjest && s != null) ..._traad(s),
      ],
    );
  }

  List<Widget> _traad(SupportSamtale s) {
    final chips = s.chips;
    final human = s.erMenneske;
    final navn = human ? s.menneske!.split(' ').first : '';
    return [
      const SizedBox(height: 12),
      ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 340),
        // A short thread: one column, so the scroll always knows its end.
        child: SingleChildScrollView(
          key: const Key('a1_hjelp_chat_traad'),
          controller: _scroll,
          padding: const EdgeInsets.only(bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, m) in s.meldinger.indexed) ...[if (i > 0) const SizedBox(height: 8), _ChatMelding(key: ValueKey('m$i'), m: m)],
              if (_skriver) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: CssBox(
                    key: const Key('a1_hjelp_chat_skriver'),
                    radius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomRight: Radius.circular(18), bottomLeft: Radius.circular(5)),
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    border: Border.all(color: rgba(255, 255, 255, .2)),
                    bg: [CssSolid(rgba(255, 255, 255, .1))],
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [for (var k = 0; k < 3; k++) _Prikk(delay: k * 200.0)],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      if (chips.isNotEmpty) ...[
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final (i, c) in chips.indexed)
              LfPress(
                key: Key('a1_hjelp_chat_chip_$i'),
                onTap: () => _chip(c),
                scale: .96,
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  decoration: BoxDecoration(
                    color: rgba(255, 255, 255, .1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: rgba(255, 255, 255, .26)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [Text(c, style: inter(12.5, weight: FontWeight.w700))],
                  ),
                ),
              ),
          ],
        ),
      ],
      // Closed on the server (staff or the customer): no input, back to the
      // hub to start a new conversation (backend plan Step 5).
      if (s.lukket) ...[
        const SizedBox(height: 10),
        LfPress(
          key: const Key('a1_hjelp_chat_ny'),
          onTap: widget.onTilbake,
          scale: .985,
          child: Container(
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rgba(255, 255, 255, .08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: rgba(255, 255, 255, .24)),
            ),
            child: Text(SupportCopy.nySamtale, style: inter(13, weight: FontWeight.w800)),
          ),
        ),
      ] else ...[
        const SizedBox(height: 10),
        CssBox(
          height: 50,
          radius: BorderRadius.circular(999),
          padding: const EdgeInsets.fromLTRB(16, 0, 6, 0),
          border: Border.all(color: rgba(255, 255, 255, .22)),
          bg: [
            CssLinear(180, [rgba(255, 255, 255, .14), rgba(255, 255, 255, .07)]),
          ],
          shadows: [CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .28))],
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('a1_hjelp_chat_felt'),
                  controller: _tekst,
                  onSubmitted: _send,
                  textInputAction: TextInputAction.send,
                  cursorColor: kSpMint,
                  style: inter(13.5),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    hintText: human ? SupportCopy.skrivTil(navn) : SupportCopy.skrivAi,
                    hintStyle: inter(13.5, color: rgba(255, 255, 255, .45)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              LfPress(
                key: const Key('a1_hjelp_chat_send'),
                onTap: () => _send(_tekst.text),
                scale: .9,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _tekst.text.trim().isEmpty ? .45 : 1,
                  child: CssBox(
                    width: 38,
                    height: 38,
                    radius: BorderRadius.circular(19),
                    bg: const [
                      CssLinear(160, [Color(0xFFF2884E), Color(0xFFE0662C)]),
                    ],
                    shadows: [CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .35)), CssShadow(0, 3, 0, 0, rgba(150, 60, 15, .8)), CssShadow(0, 8, 14, -8, rgba(120, 50, 10, .9))],
                    child: Center(child: spIkon(kSpIkonOpp, size: 16, width: 2.6)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        LfPress(
          key: const Key('a1_hjelp_chat_menneske'),
          onTap: _menneske,
          scale: .985,
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: rgba(255, 255, 255, .08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: rgba(255, 255, 255, .24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                spIkon('M8 8a4 4 0 1 0 8 0a4 4 0 1 0 -8 0M4 21a8 8 0 0 1 16 0', size: 15, color: kSpMint, width: 2.2),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    human ? SupportCopy.iSamtalen(navn) : SupportCopy.menneske,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: inter(13, weight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ];
  }

  Widget _gjestKort() {
    final feil = _feil;
    InputDecoration dekor(String hint, {bool feilKant = false}) => InputDecoration(
      isDense: true,
      filled: true,
      fillColor: rgba(255, 255, 255, .1),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintText: hint,
      hintStyle: inter(14, weight: FontWeight.w700, color: rgba(255, 255, 255, .45)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: feilKant ? rgba(255, 140, 100, .7) : rgba(255, 255, 255, .28)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: feilKant ? rgba(255, 140, 100, .7) : rgba(255, 255, 255, .5)),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: CssBox(
        key: const Key('a1_hjelp_gjest'),
        radius: BorderRadius.circular(20),
        padding: const EdgeInsets.all(14),
        border: Border.all(color: rgba(255, 255, 255, .2)),
        bg: [
          CssLinear(180, [rgba(255, 255, 255, .14), rgba(255, 255, 255, .07)]),
        ],
        shadows: [CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .28))],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(SupportCopy.gjestTittel, style: inter(14, weight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text('${SupportCopy.gjestTekst}${SupportCopy.gjestKontakt}.', style: inter(12, height: 1.45, color: rgba(255, 255, 255, .65))),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: TextField(
                key: const Key('a1_hjelp_gjest_ordre'),
                controller: _gjestOrdre,
                onChanged: (_) => setState(() => _feil = null),
                textCapitalization: TextCapitalization.characters,
                cursorColor: kSpMint,
                style: inter(14, weight: FontWeight.w700),
                decoration: dekor(SupportCopy.gjestOrdre),
              ),
            ),
            if (_kodeSendt) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: TextField(
                  key: const Key('a1_hjelp_gjest_kode'),
                  controller: _gjestKode,
                  onChanged: (_) => setState(() => _feil = null),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  cursorColor: kSpMint,
                  style: inter(16, weight: FontWeight.w800, em: .2),
                  decoration: dekor(SupportCopy.gjestKode, feilKant: feil != null).copyWith(counterText: ''),
                ),
              ),
            ],
            if (feil != null) ...[
              const SizedBox(height: 8),
              Container(
                key: const Key('a1_hjelp_gjest_feil'),
                padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
                decoration: BoxDecoration(
                  color: rgba(185, 68, 26, .22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: rgba(255, 140, 100, .4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Opacity(
                      opacity: .8,
                      child: Text(
                        '422 · ${feil.$1}',
                        style: inter(10, weight: FontWeight.w700, em: .06, color: const Color(0xFFFFD5C6)),
                      ),
                    ),
                    Text(
                      feil.$2,
                      style: inter(12, weight: FontWeight.w700, height: 1.4, color: const Color(0xFFFFD5C6)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            _Oransje(
              key: const Key('a1_hjelp_gjest_neste'),
              height: 48,
              onTap: _gjestNeste,
              child: Center(child: Text(_kodeSendt ? SupportCopy.bekreftKode : SupportCopy.sendKode, style: jakarta(14))),
            ),
          ],
        ),
      ),
    );
  }
}

/// One message (`scMeld`): a system pill, or the label and the bubble with
/// its card, popping in (`popp .32s`).
class _ChatMelding extends StatelessWidget {
  const _ChatMelding({super.key, required this.m});
  final SupportMelding m;

  static const Map<SupportKortType, Color> _kortC = {
    SupportKortType.ordre: Color(0xFF1E4F5C),
    SupportKortType.sak: Color(0xFFE0913A),
    SupportKortType.refusjon: Color(0xFF2E7E4F),
    SupportKortType.aapningstid: Color(0xFF8C847C),
  };

  @override
  Widget build(BuildContext context) {
    if (m.fra == SupportAvsender.system) {
      return Center(
        child: FractionallySizedBox(
          widthFactor: .86,
          child: Center(
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 5, 12, 5),
              decoration: BoxDecoration(color: rgba(255, 255, 255, .08), borderRadius: BorderRadius.circular(999)),
              child: Text(
                m.tekst,
                textAlign: TextAlign.center,
                style: inter(10.5, weight: FontWeight.w700, color: rgba(255, 255, 255, .62)),
              ),
            ),
          ),
        ),
      );
    }
    final meg = m.fra == SupportAvsender.du;
    final ai = m.fra == SupportAvsender.assistent;
    final merke = meg ? SupportCopy.merkeDu(m.kl) : (ai ? SupportCopy.merkeAi(m.kl) : SupportCopy.merkeMenneske(m.navn ?? 'Ærend', m.kl));
    final merkeC = ai ? const Color(0xFFF2C14E) : (meg ? rgba(255, 255, 255, .5) : kSpMint);
    final k = m.kort;
    // `popp .32s cubic-bezier(.2,.9,.3,1)`: 1 → 1.16 → .96 → 1.
    return LfOnce(
      ms: 320,
      builder: (context, t, child) {
        final p = (t / 320).clamp(0.0, 1.0);
        final k = kf(p, const [0, .35, .7, 1], const [1, 1.16, .96, 1], const Cubic(.2, .9, .3, 1));
        return Transform.scale(scale: k, alignment: meg ? Alignment.bottomRight : Alignment.bottomLeft, child: child);
      },
      child: Column(
        crossAxisAlignment: meg ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 3),
            child: Text(
              merke,
              style: inter(10, weight: FontWeight.w800, em: .06, color: merkeC),
            ),
          ),
          FractionallySizedBox(
            widthFactor: .86,
            alignment: meg ? Alignment.centerRight : Alignment.centerLeft,
            child: Align(
              alignment: meg ? Alignment.centerRight : Alignment.centerLeft,
              child: CssBox(
                radius: meg
                    ? const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomLeft: Radius.circular(18), bottomRight: Radius.circular(5))
                    : const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomRight: Radius.circular(18), bottomLeft: Radius.circular(5)),
                padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
                border: Border.all(color: meg ? rgba(255, 255, 255, .2) : rgba(255, 255, 255, .24)),
                bg: meg
                    ? const [
                        CssLinear(160, [Color(0xFFF2884E), Color(0xFFE0662C)]),
                      ]
                    : ai
                    ? [
                        CssLinear(180, [rgba(255, 255, 255, .18), rgba(255, 255, 255, .09)]),
                      ]
                    : [
                        CssLinear(180, [rgba(92, 224, 184, .26), rgba(92, 224, 184, .12)]),
                      ],
                shadows: [CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .2))],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(m.tekst, style: inter(13.5, height: 1.45)),
                    if (k != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        key: Key('a1_hjelp_kort_${k.type.name}'),
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        decoration: BoxDecoration(
                          color: rgba(253, 252, 249, .96),
                          borderRadius: BorderRadius.circular(14),
                          border: Border(left: BorderSide(color: _kortC[k.type]!, width: 4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${SupportCopy.kortLabel[k.type]}${k.ref == null ? '' : ' · ${k.ref}'}',
                              style: inter(10, weight: FontWeight.w800, em: .06, color: const Color(0xFF8C847C)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              k.tittel,
                              style: inter(13.5, weight: FontWeight.w800, color: const Color(0xFF23201D)),
                            ),
                            if (k.under.isNotEmpty) ...[const SizedBox(height: 1), Text(k.under, style: inter(11.5, color: const Color(0xFF57534B)))],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A typing dot (`pulsPrikk 1s`).
class _Prikk extends StatelessWidget {
  const _Prikk({required this.delay});
  final double delay;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: LfLoop(
      builder: (context, tt, child) {
        final e = tt - delay;
        final p = e < 0 ? 0.0 : (e / 1000) % 1.0;
        // `pulsPrikk 1s`: opacity .35 → 1 and up 2 px at the middle.
        return Opacity(
          opacity: kf(p, const [0, .5, 1], const [.35, 1, .35]),
          child: Transform.translate(offset: Offset(0, kf(p, const [0, .5, 1], const [0, -2, 0])), child: child),
        );
      },
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(shape: BoxShape.circle, color: rgba(255, 255, 255, .7)),
      ),
    ),
  );
}

// ── Hjelp og kontakt (`hjIngenOrdre`, L8660–8685) ────────────────────────────

/// The help hub when no order is on its way: open or closed, «Fortsett
/// samtalen», «Chat med oss», the cases filed on this device, «Finn svar
/// selv» and the e-mail line.
class _Hub extends StatelessWidget {
  const _Hub({required this.onLukk, required this.onChat, required this.onFortsett, required this.onSpor});

  final VoidCallback onLukk;
  final VoidCallback onChat;
  final VoidCallback? onFortsett;
  final void Function(String) onSpor;

  @override
  Widget build(BuildContext context) {
    final aapen = SupportConfig.aapen();
    final dot = aapen ? kSpMint : const Color(0xFFF7D57E);
    final samtale = SupportStore.instance.aapen;
    final saker = SupportStore.instance.saker;
    return Column(
      key: const Key('a1_hjelp_hub'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Avatar(size: 56, radius: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(SupportCopy.hjelpOgKontakt, style: jakarta(18, em: -.02)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: dot,
                            boxShadow: [BoxShadow(color: dot, blurRadius: 8)],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            aapen ? SupportCopy.aapenNaa : SupportCopy.stengtNaa(SupportConfig.aapnerKl),
                            key: const Key('a1_hjelp_hub_aapen'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: inter(11.5, color: rgba(255, 255, 255, .7)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _Lukk(onTap: onLukk),
          ],
        ),
        if (samtale != null && onFortsett != null) ...[
          const SizedBox(height: 14),
          LfPress(
            key: const Key('a1_hjelp_hub_fortsett'),
            onTap: onFortsett!,
            scale: .985,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: rgba(92, 224, 184, .12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: rgba(92, 224, 184, .5), width: 1.5),
              ),
              child: Row(
                children: [
                  const _PulsDot(),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(SupportCopy.fortsett, style: inter(13, weight: FontWeight.w800)),
                        const SizedBox(height: 1),
                        Text(
                          samtale.emne,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: inter(11, color: rgba(255, 255, 255, .7)),
                        ),
                      ],
                    ),
                  ),
                  spIkon(kSpIkonPilLiten, size: 13, color: const Color(0xFF7FF0CB), width: 2.4),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        LfPress(
          key: const Key('a1_hjelp_hub_chat'),
          onTap: onChat,
          scale: 1,
          dy: 3,
          child: CssBox(
            radius: BorderRadius.circular(20),
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
            bg: const [
              CssLinear(180, [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], [0, .56, 1]),
            ],
            shadows: [CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .45)), const CssShadow(0, 3, 0, 0, Color(0xFFC4491A)), CssShadow(0, 14, 24, -10, rgba(233, 92, 44, .9))],
            child: Row(
              children: [
                CssBox(
                  width: 38,
                  height: 38,
                  radius: BorderRadius.circular(13),
                  bg: [CssSolid(rgba(255, 255, 255, .2))],
                  shadows: [CssShadow.inset(0, 1, 0, 0, rgba(255, 255, 255, .4))],
                  child: Center(child: spIkon('${kSpIkonChatEnkel}M8.5 10.5h.01M12 10.5h.01M15.5 10.5h.01', size: 18, width: 2.2)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(SupportCopy.chatMedOss, style: jakarta(14.5)),
                      const SizedBox(height: 1),
                      Text(
                        SupportCopy.chatMedOssUnder,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: inter(11, color: rgba(255, 255, 255, .88)),
                      ),
                    ],
                  ),
                ),
                spIkon(kSpIkonPilLiten, size: 13, width: 2.4),
              ],
            ),
          ),
        ),
        if (saker.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            SupportCopy.dineSaker,
            style: inter(10.5, weight: FontWeight.w800, em: .06, color: rgba(255, 255, 255, .6)),
          ),
          const SizedBox(height: 8),
          for (final (i, s) in saker.indexed) ...[
            if (i > 0) const SizedBox(height: 7),
            _Rad(
              key: Key('a1_hjelp_hub_sak_$i'),
              tile: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF7D57E),
                  boxShadow: [BoxShadow(color: Color(0xFFF7D57E), blurRadius: 8)],
                ),
              ),
              tittel: s.tittel,
              under: s.customerSees ?? SupportCopy.ack,
              pil: false,
              etter: Container(
                padding: const EdgeInsets.fromLTRB(8, 2.5, 8, 2.5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF7D57E), Color(0xFFE0A32C)]),
                ),
                child: Text(
                  SupportCopy.aapenChip,
                  style: inter(9.5, weight: FontWeight.w800, color: const Color(0xFF3A2A08)),
                ),
              ),
              onTap: () => onSpor(SupportCopy.statusSpor(s.kode)),
            ),
          ],
        ],
        const SizedBox(height: 18),
        Text(
          SupportCopy.finnSvar,
          style: inter(10.5, weight: FontWeight.w800, em: .06, color: rgba(255, 255, 255, .6)),
        ),
        const SizedBox(height: 8),
        CssBox(
          radius: BorderRadius.circular(18),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          border: Border.all(color: rgba(255, 255, 255, .2)),
          bg: [
            CssLinear(180, [rgba(255, 255, 255, .14), rgba(255, 255, 255, .07)]),
          ],
          shadows: [CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .28))],
          child: Column(
            children: [
              for (final (i, f) in SupportCopy.faq.indexed)
                GestureDetector(
                  key: Key('a1_hjelp_faq_$i'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSpor(f.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      border: i == SupportCopy.faq.length - 1 ? null : Border(bottom: BorderSide(color: rgba(255, 255, 255, .08))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(f.$1, style: inter(13, weight: FontWeight.w800)),
                              const SizedBox(height: 1),
                              Text(f.$2, style: inter(10.5, color: rgba(255, 255, 255, .62))),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        spIkon(kSpIkonPilLiten, size: 13, color: rgba(255, 255, 255, .6), width: 2.4),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          key: const Key('a1_hjelp_epost'),
          onTap: () => launchUrl(Uri.parse('mailto:${SupportConfig.epost}')),
          child: Text.rich(
            TextSpan(
              style: inter(11.5, height: 1.5, color: rgba(255, 255, 255, .62)),
              children: [
                TextSpan(text: SupportCopy.epostFor),
                TextSpan(
                  text: SupportConfig.epost,
                  style: inter(11.5, weight: FontWeight.w800, height: 1.5, color: const Color(0xFF7FF0CB)),
                ),
                const TextSpan(text: SupportCopy.epostEtter),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

/// The «Fortsett samtalen» dot (`pulsDot 1.6s`).
class _PulsDot extends StatelessWidget {
  const _PulsDot();

  @override
  Widget build(BuildContext context) => LfLoop(
    builder: (context, tt, child) {
      final p = (tt / 1600) % 1.0;
      return Opacity(
        opacity: kf(p, const [0, .5, 1], const [1, .7, 1], cssEaseInOut),
        child: Transform.scale(scale: kf(p, const [0, .5, 1], const [1, 1.35, 1], cssEaseInOut), child: child),
      );
    },
    child: Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: kSpMint,
        boxShadow: [BoxShadow(color: kSpMint, blurRadius: 8)],
      ),
    ),
  );
}
