import 'package:flutter/material.dart';

import '../../../data/aegil/aegil_models.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../hurtig/hurtig_data.dart' show HbButikk;
import 'aegil_bits.dart';
import 'aegil_launch_copy.dart';

// ── Start (`agS0`, L4634–4690) ──────────────────────────────────────────────

/// «Ægil tipper»: the customer's last delivered order, ready again.
class AeTips {
  const AeTips({required this.butikk, required this.dag, required this.min, required this.adresse, required this.sumKr, required this.ico, required this.tint, required this.pleier});

  final String butikk;

  /// The order's weekday, lower case («torsdag»).
  final String dag;
  final int min;
  final String adresse;
  final int sumKr;
  final String ico;
  final List<Color> tint;

  /// Ordered on this weekday before: «Du pleier å bestille nå».
  final bool pleier;
}

/// The three tints of the prototype's art tiles (`radial-gradient(130% 110%
/// at 28% 0%, a, b 48%, c)`).
const List<Color> kAeTintFisk = [Color(0xFFEEF7F9), Color(0xFFC9E2E8), Color(0xFF93BFCB)];
const List<Color> kAeTintMat = [Color(0xFFFFF1E6), Color(0xFFF8D3B6), Color(0xFFE9AE86)];
const List<Color> kAeTintGave = [Color(0xFFFBEFEC), Color(0xFFEFCFC6), Color(0xFFD9A79A)];

class _ArtTile extends StatelessWidget {
  const _ArtTile({required this.size, required this.r, required this.tint, required this.ico});

  final double size;
  final double r;
  final List<Color> tint;
  final String ico;

  @override
  Widget build(BuildContext context) => CssBox(
    width: size,
    height: size,
    radius: BorderRadius.circular(r),
    bg: [
      CssRadial(tint, stops: const [0, .48, 1], rx: 1.3, ry: 1.1, cx: .28, cy: 0),
    ],
    shadows: const [
      CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .9)),
      CssShadow.inset(0, -5, 8, -5, Color.fromRGBO(60, 48, 30, .3)),
      CssShadow(0, 8, 12, -8, Color.fromRGBO(3, 16, 24, .8)),
    ],
    child: Center(child: AeIco(ico, w: 32, h: 28)),
  );
}

class AeStartView extends StatelessWidget {
  const AeStartView({
    super.key,
    required this.kicker,
    required this.hilsen,
    required this.husker,
    required this.tilbud,
    required this.tips,
    required this.onMinne,
    required this.onObStart,
    required this.onIkkeNaa,
    required this.onBestill,
    required this.onEndre,
    required this.onSi,
    required this.onSok,
  });

  final String kicker;
  final String hilsen;

  /// `mnTopp` — what Ægil remembers (empty: nothing).
  final List<String> husker;

  /// The memory offer (`mnTom`).
  final bool tilbud;
  final AeTips? tips;
  final VoidCallback onMinne;
  final VoidCallback onObStart;
  final VoidCallback onIkkeNaa;
  final VoidCallback onBestill;
  final VoidCallback onEndre;
  final ValueChanged<String> onSi;
  final VoidCallback onSok;

  @override
  Widget build(BuildContext context) {
    final ord = hilsen.split(' ');
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AePulsDot(),
                    const SizedBox(width: 7),
                    Text(
                      kicker,
                      style: aeTab(inter(10.5, weight: FontWeight.w800, em: .08, color: kAeMintLys)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // The greeting, word by word (`ordInn .32s`, .15 s + .045 s).
                LfOnce(
                  ms: 150 + ord.length * 45.0 + 320,
                  builder: (context, t, _) => Wrap(
                    children: [for (final (i, w) in ord.indexed) aeInn(AeInn.ord, kfP(t, 150 + i * 45.0, 320), cssEaseOut, Alignment.center, Text('$w ', style: jakarta(26, em: -.035, height: 1.12)))],
                  ),
                ),
                if (husker.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    key: const Key('a1_aegil_husker'),
                    behavior: HitTestBehavior.opaque,
                    onTap: onMinne,
                    child: Row(
                      children: [
                        const AeIkon('M12 3a6 6 0 0 0-4 10.5V17h8v-3.5A6 6 0 0 0 12 3zM9 21h6', size: 12, color: kAeMintLys),
                        const SizedBox(width: 6),
                        Text(
                          AeCopy.husker,
                          style: inter(11.5, weight: FontWeight.w700, color: kAeSub),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: ClipRect(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const NeverScrollableScrollPhysics(),
                              child: Row(
                                children: [
                                  for (final (i, c) in husker.indexed) ...[
                                    if (i > 0) const SizedBox(width: 4),
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(text: c),
                                          TextSpan(
                                            text: ' · ',
                                            style: inter(11.5, weight: FontWeight.w700, color: const Color(0xFF7FA8B3)),
                                          ),
                                        ],
                                      ),
                                      style: inter(11.5, weight: FontWeight.w800),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const AeIkon('M9 6l6 6-6 6', size: 9, stroke: 3.2, color: kAeMintLys),
                      ],
                    ),
                  ),
                ],
                if (tilbud) ...[
                  const SizedBox(height: 12),
                  CssBox(
                    key: const Key('a1_aegil_minne_tilbud'),
                    radius: BorderRadius.circular(18),
                    bg: kAeGlass,
                    shadows: const [CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .3)), CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .12))],
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(AeCopy.minneTilbud, style: inter(12.5, weight: FontWeight.w700, height: 1.4)),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          children: [
                            AePress(
                              key: const Key('a1_aegil_ob_start'),
                              onTap: onObStart,
                              dy: 1.5,
                              child: CssBox(
                                radius: BorderRadius.circular(999),
                                bg: kAeOransje,
                                shadows: const [CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .45)), CssShadow(0, 2, 0, 0, Color(0xFFA63A12))],
                                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                                child: Text(AeCopy.jaLaOss, style: inter(11, weight: FontWeight.w800)),
                              ),
                            ),
                            const SizedBox(height: 5),
                            GestureDetector(
                              key: const Key('a1_aegil_ikke_naa'),
                              onTap: onIkkeNaa,
                              child: Text(
                                AeCopy.ikkeNaa,
                                style: inter(11, weight: FontWeight.w800, color: kAeSub),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (tips case final tp?) ...[
            const SizedBox(height: 18),
            AeOnce(
              kind: AeInn.vcKort,
              ms: 550,
              delay: 200,
              curve: const Cubic(.2, 1.15, .3, 1),
              child: _Tipper(t: tp, onBestill: onBestill, onEndre: onEndre),
            ),
          ],
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(child: Text(AeCopy.beOm, style: jakarta(15))),
                Text(
                  AeCopy.ordner,
                  style: inter(10.5, weight: FontWeight.w700, color: kAeSub),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, (tittel, sub, ico, tint, si)) in [
                  (AeCopy.taco, AeCopy.tacoSub, 'ico_mat', kAeTintMat, AeCopy.tacoSi),
                  (AeCopy.reker, AeCopy.rekerSubTom, 'ico_fisk', kAeTintFisk, AeCopy.rekerSi),
                  (AeCopy.gave, AeCopy.gaveSub, 'ico_gaver', kAeTintGave, AeCopy.gaveSi),
                ].indexed) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: AeOnce(
                      kind: AeInn.vcKort,
                      ms: 500,
                      delay: 320 + i * 60.0,
                      curve: const Cubic(.2, 1.15, .3, 1),
                      child: AePress(
                        key: Key('a1_aegil_be_$i'),
                        onTap: () => onSi(si),
                        dy: 0,
                        scale: .97,
                        child: CssBox(
                          radius: BorderRadius.circular(20),
                          bg: kAeGlass,
                          shadows: const [
                            CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .3)),
                            CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .12)),
                            CssShadow(0, 3, 0, 0, Color.fromRGBO(8, 28, 36, .45)),
                            CssShadow(0, 18, 26, -18, Color.fromRGBO(3, 14, 20, .85)),
                          ],
                          padding: const EdgeInsets.fromLTRB(10, 11, 10, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ArtTile(size: 42, r: 14, tint: tint, ico: ico),
                              const SizedBox(height: 9),
                              Text(tittel, style: jakarta(12.5, em: -.02, height: 1.2)),
                              const SizedBox(height: 2),
                              Text(
                                sub,
                                style: inter(10, weight: FontWeight.w700, height: 1.25, color: kAeSub),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          AePress(
            key: const Key('a1_aegil_sok'),
            onTap: onSok,
            dy: 0,
            scale: .985,
            child: CssBox(
              height: 46,
              radius: BorderRadius.circular(16),
              bg: const [CssSolid(Color.fromRGBO(6, 22, 30, .26))],
              shadows: const [CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .12))],
              padding: const EdgeInsets.fromLTRB(14, 0, 6, 0),
              child: Row(
                children: [
                  AeIkon('${AeIkon.sirkel(11, 11, 7)}M20.5 20.5l-4.3-4.3', size: 15, color: const Color(0xFFF26D3D)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AeCopy.sokSelv,
                      style: inter(13, weight: FontWeight.w700, color: const Color(0xFFDCE9EC)),
                    ),
                  ),
                  CssBox(
                    width: 32,
                    height: 32,
                    radius: BorderRadius.circular(11),
                    bg: const [
                      CssLinear(180, [Color.fromRGBO(130, 242, 210, .3), Color.fromRGBO(92, 224, 184, .1)]),
                    ],
                    shadows: const [CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .32)), CssShadow(0, 0, 0, 1, Color.fromRGBO(92, 224, 184, .38))],
                    child: const Center(child: AeIkon('M9 6l6 6-6 6', size: 11, stroke: 3)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// «Ægil tipper» (L4641): the warm-and-mint glass card with the passing
/// sheen (`sveipLys 7s`).
class _Tipper extends StatelessWidget {
  const _Tipper({required this.t, required this.onBestill, required this.onEndre});

  final AeTips t;
  final VoidCallback onBestill;
  final VoidCallback onEndre;

  @override
  Widget build(BuildContext context) {
    Widget chip(String d, String tekst) => CssBox(
      radius: BorderRadius.circular(999),
      bg: const [CssSolid(Color.fromRGBO(255, 255, 255, .08))],
      shadows: const [CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .12))],
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AeIkon(d, size: 10, stroke: 2.8, color: kAeMintLys),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              tekst,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: aeTab(inter(10.5, weight: FontWeight.w800, color: const Color(0xFFDCE9EC))),
            ),
          ),
        ],
      ),
    );
    return CssBox(
      key: const Key('a1_aegil_tipper'),
      radius: BorderRadius.circular(26),
      clip: true,
      bg: const [
        CssRadial([Color.fromRGBO(255, 148, 102, .24), Color.fromRGBO(255, 148, 102, 0)], stops: [0, .6], rx: .9, ry: .9, cx: 1, cy: 0),
        CssRadial([Color.fromRGBO(92, 224, 184, .18), Color.fromRGBO(92, 224, 184, 0)], stops: [0, .6], rx: .8, ry: .8, cx: 0, cy: 1),
        CssLinear(180, [Color.fromRGBO(255, 255, 255, .17), Color.fromRGBO(255, 255, 255, .06)]),
      ],
      shadows: const [
        CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .35)),
        CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .14)),
        CssShadow(0, 3, 0, 0, Color.fromRGBO(8, 28, 36, .5)),
        CssShadow(0, 22, 30, -18, Color.fromRGBO(3, 14, 20, .9)),
      ],
      child: Stack(
        children: [
          const Positioned.fill(child: IgnorePointer(child: _Sveip())),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CssBox(
                      radius: BorderRadius.circular(999),
                      bg: const [CssSolid(Color.fromRGBO(6, 22, 30, .4))],
                      shadows: const [CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .14))],
                      padding: const EdgeInsets.fromLTRB(7, 4, 9, 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AeIkon('M12 2l2.2 6.8L21 11l-6.8 2.2L12 20l-2.2-6.8L3 11l6.8-2.2z', size: 11, stroke: 0, fill: Color(0xFFFFD27A)),
                          const SizedBox(width: 6),
                          Text(AeCopy.tipper, style: inter(10, weight: FontWeight.w800, em: .06)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      t.pleier ? AeCopy.pleier : AeCopy.forrige,
                      style: inter(10.5, weight: FontWeight.w700, color: kAeSub),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _ArtTile(size: 52, r: 17, tint: t.tint, ico: t.ico),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AeCopy.sammeSomSist, style: jakarta(17, em: -.025, height: 1.15)),
                          const SizedBox(height: 2),
                          Text(
                            '${t.butikk} · ${AeCopy.bestillingen(t.dag)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: inter(11.5, weight: FontWeight.w700, color: const Color(0xFFDCE9EC)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    chip('${AeIkon.sirkel(12, 12, 9)}M12 7v5l3 2', AeCopy.levertOm(t.min)),
                    if (t.adresse.isNotEmpty) ...[const SizedBox(width: 6), Flexible(child: chip('M12 21s-7-6.5-7-12a7 7 0 0 1 14 0c0 5.5-7 12-7 12z', t.adresse))],
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AePress(
                        key: const Key('a1_aegil_bestill_igjen'),
                        onTap: onBestill,
                        child: CssBox(
                          height: 46,
                          radius: BorderRadius.circular(15),
                          bg: kAeOransje,
                          shadows: const [
                            CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .45)),
                            CssShadow.inset(0, -2, 0, 0, Color.fromRGBO(0, 0, 0, .08)),
                            CssShadow(0, 3, 0, 0, Color(0xFFA63A12)),
                            CssShadow(0, 10, 14, -8, Color.fromRGBO(3, 16, 24, .75)),
                          ],
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(AeCopy.bestillIgjen, maxLines: 1, overflow: TextOverflow.ellipsis, style: jakarta(13.5)),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: const Color.fromRGBO(255, 255, 255, .22)),
                                child: Text('${t.sumKr} kr', style: aeTab(inter(12, weight: FontWeight.w800))),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AePress(
                      key: const Key('a1_aegil_endre_sist'),
                      onTap: onEndre,
                      child: CssBox(
                        height: 46,
                        radius: BorderRadius.circular(15),
                        bg: kAeSek,
                        shadows: kAeSekSh,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Center(
                          child: Text(AeCopy.endre, style: inter(12.5, weight: FontWeight.w800)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `sveipLys 7s 1.4s` — a light band crossing the card (−120 % → 120 % in
/// the first 45 %), on a box 220 % wide.
class _Sveip extends StatelessWidget {
  const _Sveip();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => RepaintBoundary(
      child: LfLoop(
        frozenMs: 0,
        builder: (context, t, _) {
          final p = kfLoop(t, 1400, 7000);
          if (p == null) return const SizedBox.shrink();
          final x = kf(p, const [0, .45, 1], const [-1.2, 1.2, 1.2], cssEaseInOut);
          final w = box.maxWidth * 2.2;
          return OverflowBox(
            maxWidth: w,
            maxHeight: box.maxHeight * 1.8,
            child: Transform.translate(
              offset: Offset(x * w, 0),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-.98, -.17),
                    end: Alignment(.98, .17),
                    colors: [Color.fromRGBO(255, 255, 255, 0), Color.fromRGBO(255, 255, 255, .1), Color.fromRGBO(255, 255, 255, 0)],
                    stops: [.46, .5, .54],
                  ),
                ),
                child: SizedBox.expand(),
              ),
            ),
          );
        },
      ),
    ),
  );
}

// ── Det Ægil vet om deg (`agMinne`, L4734–4790) ─────────────────────────────

/// The memory grouped as the prototype groups it.
class AeMinneData {
  AeMinneData(List<MemoryEntry> alle) {
    for (final m in alle) {
      switch (m.kind) {
        case 'like' || 'likes' || 'product':
          liker.add(m);
        case 'store' || 'stores':
          butikker.add(m);
        case 'household':
          husstand.add(m);
        case 'allergen' || 'diet' || 'exclusion_product' || 'dislike':
          kosthold.add(m);
        case 'dinner' || 'rhythm':
          rytme.add(m);
        default:
          laert.add(m);
      }
    }
  }

  final List<MemoryEntry> liker = [], butikker = [], husstand = [], kosthold = [], rytme = [], laert = [];

  bool get tom => liker.isEmpty && butikker.isEmpty && husstand.isEmpty && kosthold.isEmpty && rytme.isEmpty && laert.isEmpty;

  static String tekst(MemoryEntry m) => (m.label ?? m.value).trim();

  /// `mnTopp`: the first two likes joined, the first store, the household.
  List<String> get topp => [
    if (liker.isNotEmpty) liker.length == 1 ? tekst(liker[0]) : AeCopy.og(tekst(liker[0]), tekst(liker[1])),
    if (butikker.isNotEmpty) tekst(butikker[0]),
    if (husstand.isNotEmpty) tekst(husstand[0]),
  ];
}

class AeMinneView extends StatelessWidget {
  const AeMinneView({
    super.key,
    required this.data,
    required this.varsler,
    required this.nivaaNavn,
    required this.onFjern,
    required this.onStemmer,
    required this.onLeggTil,
    required this.onNivaa,
    required this.onGlem,
  });

  final AeMinneData data;
  final String varsler;
  final String nivaaNavn;
  final ValueChanged<MemoryEntry> onFjern;
  final ValueChanged<MemoryEntry> onStemmer;
  final VoidCallback onLeggTil;
  final VoidCallback onNivaa;
  final VoidCallback onGlem;

  static const Color _kicker = Color.fromRGBO(255, 255, 255, .6);

  Widget _hode(String t, {bool leggTil = true}) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            t,
            style: inter(11, weight: FontWeight.w800, em: .05, color: _kicker),
          ),
        ),
        if (leggTil)
          GestureDetector(
            onTap: onLeggTil,
            child: Text(
              AeCopy.leggTil,
              style: inter(11, weight: FontWeight.w800, color: kAeMint),
            ),
          ),
      ],
    ),
  );

  Widget _boks(List<Widget> rader) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: CssBox(
      radius: BorderRadius.circular(20),
      bg: kAeRadGlass,
      shadows: kAeRadGlassSh,
      border: Border.all(color: const Color.fromRGBO(255, 255, 255, .18)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rader),
    ),
  );

  Widget _rad(MemoryEntry m, {bool sist = false}) => Container(
    key: Key('a1_aegil_minne_${m.id}'),
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      border: sist ? null : const Border(bottom: BorderSide(color: Color.fromRGBO(255, 255, 255, .1))),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(AeMinneData.tekst(m), style: inter(12.5, weight: FontWeight.w700)),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => onFjern(m),
          child: Text(
            AeCopy.fjern,
            style: inter(11, weight: FontWeight.w800, color: const Color(0xFFFFB08A)),
          ),
        ),
      ],
    ),
  );

  List<Widget> _rader(List<MemoryEntry> l) => [for (final (i, m) in l.indexed) _rad(m, sist: i == l.length - 1)];

  @override
  Widget build(BuildContext context) {
    final d = data;
    return AeOnce(
      kind: AeInn.stigOpp,
      ms: 500,
      curve: const Cubic(.3, 1.2, .5, 1),
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AeCopy.minneTittel, style: jakarta(18, em: -.02)),
            const SizedBox(height: 4),
            Text(AeCopy.minneSub, style: inter(11.5, height: 1.45, color: const Color.fromRGBO(255, 255, 255, .65))),
            if (d.tom)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: CssBox(
                  radius: BorderRadius.circular(18),
                  bg: const [CssSolid(Colors.white)],
                  shadows: const [CssShadow(0, 2, 3, -1, Color.fromRGBO(120, 80, 40, .1)), CssShadow(0, 16, 28, -22, Color.fromRGBO(30, 79, 92, .45))],
                  border: Border.all(color: const Color.fromRGBO(35, 32, 29, .08)),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 44,
                          height: 44,
                          color: const Color(0xFFEAF2F4),
                          child: Image.asset(aePose('front'), fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AeCopy.minneTom,
                          style: inter(12.5, weight: FontWeight.w700, height: 1.4, color: kAeInk),
                        ),
                      ),
                      const SizedBox(width: 12),
                      AePress(
                        key: const Key('a1_aegil_minne_ja'),
                        onTap: onLeggTil,
                        dy: 1.5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: kAeTeal),
                          child: Text(AeCopy.jaLaOss, style: inter(11.5, weight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              _hode(AeCopy.duLiker),
              if (d.liker.isNotEmpty) _boks(_rader(d.liker)),
              _hode(AeCopy.butikker),
              if (d.butikker.isNotEmpty) _boks(_rader(d.butikker)),
              _hode(AeCopy.husstand),
              if (d.husstand.isNotEmpty) _boks(_rader(d.husstand)),
              _hode(AeCopy.kosthold),
              _boks([
                Container(
                  padding: const EdgeInsets.fromLTRB(0, 9, 0, 7),
                  decoration: d.kosthold.isEmpty
                      ? null
                      : const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Color.fromRGBO(255, 255, 255, .1))),
                        ),
                  child: Text(
                    AeCopy.brukesAlltid,
                    style: inter(11, weight: FontWeight.w700, color: const Color(0xFF7FF0CB)),
                  ),
                ),
                ..._rader(d.kosthold),
              ]),
              _hode(AeCopy.middagsrytme),
              if (d.rytme.isNotEmpty) _boks(_rader(d.rytme)),
              if (d.laert.isNotEmpty) ...[
                _hode(AeCopy.lagtMerkeTil, leggTil: false),
                _boks([
                  for (final (i, m) in d.laert.indexed)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: i == d.laert.length - 1 ? null : const Border(bottom: BorderSide(color: Color.fromRGBO(255, 255, 255, .1))),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AeMinneData.tekst(m), style: inter(12.5, weight: FontWeight.w600, height: 1.35)),
                                const SizedBox(height: 2),
                                Text(
                                  _bekreftet(m) ? AeCopy.bekreftet : '${AeCopy.fraChat} · ${AeCopy.kunForslag}',
                                  style: inter(10, weight: FontWeight.w700, color: _bekreftet(m) ? const Color(0xFF7FF0CB) : const Color.fromRGBO(255, 255, 255, .55)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (!_bekreftet(m)) ...[
                            GestureDetector(
                              onTap: () => onStemmer(m),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: kAeTeal),
                                child: Text(AeCopy.stemmer, style: inter(10.5, weight: FontWeight.w800)),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          GestureDetector(
                            onTap: () => onFjern(m),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
                              child: Text(
                                AeCopy.fjern,
                                style: inter(11, weight: FontWeight.w800, color: const Color(0xFFFFB08A)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ]),
              ],
              _hode(AeCopy.varsler, leggTil: false),
              _boks([
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(varsler, style: inter(12.5, weight: FontWeight.w600)),
                      ),
                      GestureDetector(
                        onTap: onNivaa,
                        child: Text(
                          AeCopy.endre,
                          style: inter(11, weight: FontWeight.w800, color: kAeMint),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              AePress(
                key: const Key('a1_aegil_til_nivaa'),
                onTap: onNivaa,
                dy: 0,
                scale: .98,
                child: CssBox(
                  radius: BorderRadius.circular(18),
                  bg: const [CssSolid(Colors.white)],
                  shadows: const [CssShadow(0, 2, 3, -1, Color.fromRGBO(120, 80, 40, .1)), CssShadow(0, 16, 28, -22, Color.fromRGBO(30, 79, 92, .45))],
                  border: Border.all(color: const Color.fromRGBO(35, 32, 29, .08)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: AeCopy.saaMyeRad,
                                style: inter(12.5, weight: FontWeight.w800, color: kAeInk),
                              ),
                              TextSpan(
                                text: ' · $nivaaNavn',
                                style: inter(12.5, weight: FontWeight.w600, color: const Color(0xFF57534B)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        AeCopy.se,
                        style: inter(11, weight: FontWeight.w800, color: kAeTeal),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              AePress(
                key: const Key('a1_aegil_glem'),
                onTap: onGlem,
                dy: 0,
                scale: .98,
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFFF9A6B), width: 1.5),
                  ),
                  child: Text(
                    AeCopy.glemAlt,
                    style: inter(13, weight: FontWeight.w800, color: const Color(0xFFFF9A6B)),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AeCopy.glemAltSub,
                textAlign: TextAlign.center,
                style: inter(10.5, color: const Color.fromRGBO(255, 255, 255, .55)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static bool _bekreftet(MemoryEntry m) => m.source == 'stated' || m.source == 'onboarding' || m.source == 'settings';
}

// ── Så mye kan Ægil gjøre (`agNivaaSkjerm`, L4834–4858) ─────────────────────

/// One RAMMER row: what, the current value, and its key.
class AeRamme {
  const AeRamme(this.t, this.v, this.k, this.fg, this.onTap);
  final String t;
  final String v;
  final String k;
  final Color fg;
  final VoidCallback onTap;
}

class AeNivaaView extends StatelessWidget {
  const AeNivaaView({
    super.key,
    required this.nivaaer,
    required this.valgt,
    required this.rammer,
    required this.pauset,
    required this.onVelg,
    required this.onPause,
    required this.onGlem,
    required this.onTilbake,
  });

  final List<AegilLevel> nivaaer;
  final int valgt;
  final List<AeRamme> rammer;
  final bool pauset;
  final ValueChanged<int> onVelg;
  final VoidCallback onPause;
  final VoidCallback onGlem;
  final VoidCallback onTilbake;

  @override
  Widget build(BuildContext context) => AeOnce(
    kind: AeInn.stigOpp,
    ms: 500,
    curve: const Cubic(.3, 1.2, .5, 1),
    child: Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AeCopy.nivaaTittel, style: jakarta(20, em: -.02, height: 1.2)),
          const SizedBox(height: 5),
          Text(AeCopy.nivaaSub, style: inter(12, height: 1.45, color: const Color.fromRGBO(255, 255, 255, .72))),
          const SizedBox(height: 14),
          for (final (i, n) in nivaaer.indexed) ...[if (i > 0) const SizedBox(height: 8), _Nivaa(n: n, paa: n.level == valgt, onTap: () => onVelg(n.level))],
          const SizedBox(height: 20),
          Text(
            AeCopy.rammer,
            style: inter(10.5, weight: FontWeight.w800, em: .08, color: const Color.fromRGBO(255, 255, 255, .6)),
          ),
          const SizedBox(height: 8),
          CssBox(
            radius: BorderRadius.circular(20),
            bg: const [
              CssLinear(165, [Color.fromRGBO(255, 255, 255, .13), Color.fromRGBO(255, 255, 255, .05)]),
            ],
            shadows: const [
              CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .24)),
              CssShadow(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .14)),
              CssShadow(0, 14, 24, -16, Color.fromRGBO(2, 12, 18, .9)),
            ],
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                for (final (i, r) in rammer.indexed)
                  GestureDetector(
                    key: Key('a1_aegil_ramme_$i'),
                    behavior: HitTestBehavior.opaque,
                    onTap: r.onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        border: i == rammer.length - 1 ? null : const Border(bottom: BorderSide(color: Color.fromRGBO(255, 255, 255, .08))),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.t, style: inter(12.5, weight: FontWeight.w800)),
                                const SizedBox(height: 2),
                                Text(r.v, style: aeTab(inter(11.5, color: const Color.fromRGBO(255, 255, 255, .65)))),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          CssBox(
                            radius: BorderRadius.circular(999),
                            bg: const [CssSolid(Color.fromRGBO(255, 255, 255, .08))],
                            shadows: const [CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .14))],
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            child: Text(
                              r.k,
                              style: inter(11, weight: FontWeight.w800, color: r.fg),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AePress(
                  key: const Key('a1_aegil_pause'),
                  onTap: onPause,
                  dy: 2,
                  child: CssBox(
                    height: 46,
                    radius: BorderRadius.circular(999),
                    bg: const [
                      CssLinear(180, [Color.fromRGBO(255, 255, 255, .16), Color.fromRGBO(255, 255, 255, .06)]),
                    ],
                    shadows: const [
                      CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .3)),
                      CssShadow(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .22)),
                      CssShadow(0, 10, 16, -10, Color.fromRGBO(2, 12, 18, .9)),
                    ],
                    child: Center(
                      child: Text(pauset ? AeCopy.startIgjen : AeCopy.pause, style: inter(12.5, weight: FontWeight.w800)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AePress(
                  key: const Key('a1_aegil_nivaa_glem'),
                  onTap: onGlem,
                  dy: 2,
                  child: CssBox(
                    height: 46,
                    radius: BorderRadius.circular(999),
                    bg: const [CssSolid(Color.fromRGBO(242, 109, 61, .1))],
                    shadows: const [CssShadow.inset(0, 0, 0, 1.5, Color.fromRGBO(255, 154, 107, .7))],
                    child: Center(
                      child: Text(
                        AeCopy.glemAlt,
                        style: inter(12.5, weight: FontWeight.w800, color: const Color(0xFFFF9A6B)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            key: const Key('a1_aegil_tilbake'),
            behavior: HitTestBehavior.opaque,
            onTap: onTilbake,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                AeCopy.tilbake,
                textAlign: TextAlign.center,
                style: inter(12, weight: FontWeight.w800, color: const Color(0xFF7FF0CB)),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Nivaa extends StatelessWidget {
  const _Nivaa({required this.n, required this.paa, required this.onTap});

  final AegilLevel n;
  final bool paa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AePress(
    key: Key('a1_aegil_nivaa_${n.level}'),
    onTap: onTap,
    dy: 0,
    scale: .985,
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: CssBox(
        key: ValueKey(paa),
        radius: BorderRadius.circular(18),
        bg: paa
            ? const [
                CssLinear(165, [Color.fromRGBO(127, 240, 203, .2), Color.fromRGBO(127, 240, 203, .07)]),
              ]
            : const [
                CssLinear(165, [Color.fromRGBO(255, 255, 255, .13), Color.fromRGBO(255, 255, 255, .05)]),
              ],
        shadows: paa
            ? const [
                CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .3)),
                CssShadow(0, 0, 0, 1.5, Color.fromRGBO(127, 240, 203, .75)),
                CssShadow(0, 14, 24, -14, Color.fromRGBO(2, 12, 18, .9)),
              ]
            : const [
                CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .22)),
                CssShadow(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .14)),
                CssShadow(0, 12, 20, -16, Color.fromRGBO(2, 12, 18, .9)),
              ],
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: paa ? const Color(0xFF7FF0CB) : const Color.fromRGBO(255, 255, 255, .45), width: 2),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: paa ? const Color(0xFF7FF0CB) : Colors.transparent,
                    boxShadow: [BoxShadow(color: paa ? const Color(0xFF7FF0CB) : Colors.transparent, blurRadius: 4)],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('${n.level} · ${n.name}', style: inter(13, weight: FontWeight.w800)),
                      if (n.isDefault) _merke(AeCopy.standard, const Color(0xFF7FF0CB), const Color.fromRGBO(127, 240, 203, .16), const Color.fromRGBO(127, 240, 203, .4)),
                      if (n.requiresRecurring) _merke(AeCopy.bareDagligvarer, const Color(0xFFF7D57E), const Color.fromRGBO(242, 193, 78, .16), const Color.fromRGBO(242, 193, 78, .45)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    n.body,
                    style: inter(11.5, weight: FontWeight.w500, height: 1.45, color: const Color.fromRGBO(255, 255, 255, .72)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _merke(String t, Color fg, Color bg, Color ring) => CssBox(
    radius: BorderRadius.circular(999),
    bg: [CssSolid(bg)],
    shadows: [CssShadow.inset(0, 0, 0, 1, ring)],
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    child: Text(
      t,
      style: inter(9, weight: FontWeight.w800, color: fg),
    ),
  );
}

// ── Tillatelse (`agTillatelse`, L4720–4732) ─────────────────────────────────

class AeTillatelseView extends StatelessWidget {
  const AeTillatelseView({super.key, required this.handler, required this.onVelg, required this.onAlle, required this.onKomIGang});

  final bool handler;
  final ValueChanged<bool> onVelg;
  final VoidCallback onAlle;
  final VoidCallback onKomIGang;

  Widget _valg(String t, String sub, bool paa, bool std, VoidCallback onTap, Key key) => GestureDetector(
    key: key,
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: paa ? const Color.fromRGBO(220, 233, 236, .75) : const Color.fromRGBO(255, 255, 255, .7),
        border: Border.all(color: paa ? kAeTeal : const Color.fromRGBO(255, 255, 255, .95), width: paa ? 1.5 : 1),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: kAeTeal, width: 2),
            ),
            alignment: Alignment.center,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(shape: BoxShape.circle, color: paa ? kAeTeal : Colors.transparent),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t,
                  style: inter(13, weight: FontWeight.w800, color: kAeInk),
                ),
                Text(
                  sub,
                  style: inter(11, weight: FontWeight.w400, color: const Color(0xFF57534B)),
                ),
              ],
            ),
          ),
          if (std) ...[
            const SizedBox(width: 10),
            Text(
              AeCopy.standard,
              style: inter(9.5, weight: FontWeight.w800, color: kAeTeal),
            ),
          ],
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 26),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AeOnce(
          kind: AeInn.stigOpp,
          ms: 500,
          curve: const Cubic(.3, 1.2, .5, 1),
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(AeCopy.tlTittel, style: jakarta(20, em: -.02, height: 1.2)),
                const SizedBox(height: 8),
                Text(
                  AeCopy.tlTekst,
                  style: inter(13.5, weight: FontWeight.w500, height: 1.5, color: const Color.fromRGBO(255, 255, 255, .78)),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        AeCopy.tlHva,
                        style: inter(11, weight: FontWeight.w800, color: const Color.fromRGBO(255, 255, 255, .6)),
                      ),
                    ),
                    GestureDetector(
                      onTap: onAlle,
                      child: Text(
                        AeCopy.tlAlle,
                        style: inter(11, weight: FontWeight.w800, color: kAeMint),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _valg(AeCopy.foreslaa, AeCopy.tlForeslaaSub, !handler, true, () => onVelg(false), const Key('a1_aegil_tl_foreslaa')),
                const SizedBox(height: 6),
                _valg(AeCopy.handle, AeCopy.tlHandleSub, handler, false, () => onVelg(true), const Key('a1_aegil_tl_handle')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          children: [AeChip(tekst: AeCopy.komIGang, i: 0, onTap: onKomIGang, key: const Key('a1_aegil_kom_i_gang'))],
        ),
      ],
    ),
  );
}

/// `agChips` — glass pills springing in (`chipInn .45s`, .12 s + .09 s).
class AeChip extends StatelessWidget {
  const AeChip({super.key, required this.tekst, required this.i, required this.onTap});

  final String tekst;
  final int i;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AeOnce(
    kind: AeInn.chip,
    ms: 450,
    delay: 120 + i * 90.0,
    curve: const Cubic(.3, 1.3, .5, 1),
    child: AePress(
      onTap: onTap,
      dy: 0,
      scale: .96,
      child: CssBox(
        radius: BorderRadius.circular(999),
        bg: const [
          CssLinear(180, [Color.fromRGBO(255, 255, 255, .14), Color.fromRGBO(255, 255, 255, .07)]),
        ],
        shadows: const [CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .3)), CssShadow(0, 12, 20, -14, Color.fromRGBO(4, 18, 26, .8))],
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, .24)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Text(tekst, style: inter(12.5, weight: FontWeight.w700)),
      ),
    ),
  );
}

// ── Onboarding (`agOb1`–`agOb5`, `agObSum`, L4792–4832) ─────────────────────

/// A store to pick (ob3 and «Alle butikker»).
class AeObButikk {
  const AeObButikk({required this.id, required this.navn, required this.kat, required this.km, required this.min});
  final int id;
  final String navn;
  final String kat;
  final double? km;
  final int? min;
}

/// The answers so far (`st.ob`).
class AeOb {
  final Set<String> kat = {}, mat = {}, kost = {}, dager = {};
  final Set<int> but = {};
  String hus = '';
  String varsel = '';

  void veksle<T>(Set<T> s, T v) => s.contains(v) ? s.remove(v) : s.add(v);

  int get kostEkte => kost.where((k) => k != AeCopy.kost.last).length;

  /// `obLinjer` — the lines that will be stored.
  int get linjer => kat.length + mat.length + but.length + (hus.isEmpty ? 0 : 1) + kostEkte + dager.length;

  /// `obTotalPoeng` — five per answer.
  int get poeng => (kat.length + mat.length + but.length + (hus.isEmpty ? 0 : 1) + kost.length + dager.length + (varsel.isEmpty ? 0 : 1)) * 5;
}

/// The step frame: progress, Ægil asking in a white bubble, the white card
/// with the chips and «Hopp over» / «+N Ægil-poeng» / «Neste».
class AeObSteg extends StatelessWidget {
  const AeObSteg({
    super.key,
    required this.steg,
    required this.sporsmaal,
    required this.hint,
    required this.innhold,
    required this.harValg,
    required this.poeng,
    required this.siste,
    required this.onNeste,
    required this.onHopp,
    required this.onAvbryt,
  });

  final int steg;
  final String sporsmaal;
  final String hint;
  final Widget innhold;
  final bool harValg;
  final int poeng;
  final bool siste;
  final VoidCallback onNeste;
  final VoidCallback onHopp;
  final VoidCallback onAvbryt;

  @override
  Widget build(BuildContext context) => AeOnce(
    key: ValueKey('ob$steg'),
    kind: AeInn.stigOpp,
    ms: 500,
    curve: const Cubic(.3, 1.2, .5, 1),
    child: Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), color: const Color.fromRGBO(255, 255, 255, .14)),
                  clipBehavior: Clip.antiAlias,
                  child: AeTw(
                    v: steg / 5,
                    ms: 550,
                    curve: const Cubic(.2, .9, .3, 1),
                    builder: (f) => Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: f.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            gradient: const LinearGradient(colors: [kAeMint, kAeTeal]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$steg/5',
                style: aeTab(inter(10, weight: FontWeight.w800, color: kAeMintLys)),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                key: const Key('a1_aegil_ob_avbryt'),
                onTap: onAvbryt,
                child: Text(
                  AeCopy.hoppOverAlt,
                  style: inter(10.5, weight: FontWeight.w800, color: kAeSub),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AeObSporsmaal(steg: steg, tittel: sporsmaal, hint: hint),
          const SizedBox(height: 12),
          _ObKort(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                innhold,
                const SizedBox(height: 14),
                Row(
                  children: [
                    GestureDetector(
                      key: const Key('a1_aegil_ob_hopp'),
                      behavior: HitTestBehavior.opaque,
                      onTap: onHopp,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                        child: Text(
                          AeCopy.hoppOver,
                          maxLines: 1,
                          style: inter(12, weight: FontWeight.w800, color: const Color(0xFF6E6862)),
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (harValg) ...[
                      // UI-TEMP: Placeholder data because reference UI currently has no backend/API support.
                      Flexible(
                        flex: 3,
                        child: AeOnce(
                          key: ValueKey('p$poeng'),
                          kind: AeInn.klask,
                          ms: 400,
                          curve: const Cubic(.3, 1.4, .5, 1),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF3F8F5F)),
                                alignment: Alignment.center,
                                child: const AeIkon('M4.5 12.5l5 5 10-11', size: 8, stroke: 4),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  AeCopy.poeng(poeng),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: inter(10.5, weight: FontWeight.w800, color: const Color(0xFF2E6B47)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                    ],
                    AePress(
                      key: const Key('a1_aegil_ob_neste'),
                      onTap: onNeste,
                      dy: 0,
                      scale: .95,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 11),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: harValg ? kAeTeal : const Color.fromRGBO(35, 32, 29, .08),
                          boxShadow: [BoxShadow(color: harValg ? const Color.fromRGBO(30, 79, 92, .7) : Colors.transparent, offset: const Offset(0, 10), blurRadius: 9, spreadRadius: -8)],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              siste ? AeCopy.ferdig : AeCopy.neste,
                              style: inter(12.5, weight: FontWeight.w800, color: harValg ? Colors.white : const Color(0xFF6E6862)),
                            ),
                            const SizedBox(width: 6),
                            AeIkon('M9 5l7 7-7 7', size: 12, stroke: 3.2, color: harValg ? Colors.white : const Color(0xFF6E6862)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ObKort extends StatelessWidget {
  const _ObKort({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => CssBox(
    radius: BorderRadius.circular(22),
    bg: const [CssSolid(Colors.white)],
    shadows: const [CssShadow(0, 1, 2, 0, Color.fromRGBO(35, 32, 29, .07)), CssShadow(0, 20, 34, -22, Color.fromRGBO(30, 79, 92, .55))],
    padding: const EdgeInsets.all(14),
    child: child,
  );
}

/// Ægil asking: the 56 px portrait with its pulse and the step badge, and
/// the white bubble (`bobleFraAegil .5s`).
class AeObSporsmaal extends StatelessWidget {
  const AeObSporsmaal({super.key, required this.steg, required this.tittel, this.hint, this.tekst});

  final int steg;
  final String tittel;
  final String? hint;
  final String? tekst;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -4,
              top: -4,
              right: -4,
              bottom: -4,
              child: RepaintBoundary(
                child: LfLoop(
                  builder: (context, t, _) {
                    final (s, o) = aegPuls(t, 2800);
                    return Opacity(
                      opacity: o,
                      child: Transform.scale(
                        scale: s,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(colors: [Color.fromRGBO(92, 224, 184, .35), Color.fromRGBO(92, 224, 184, 0)], stops: [0, .7]),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(begin: Alignment(-.34, -.94), end: Alignment(.34, .94), colors: [Color(0xFFDCE9EC), Color(0xFF9FB6C2)]),
                  boxShadow: [BoxShadow(color: Color.fromRGBO(30, 79, 92, .6), offset: Offset(0, 6), blurRadius: 6, spreadRadius: -6)],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned(
                      left: -10,
                      top: 2,
                      width: 74,
                      child: AeLoop(m: (t) => aegVink(t, 2600), child: Image.asset(aePose('popup'), width: 74)),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: -3,
              bottom: -3,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: kAeTeal,
                  boxShadow: [BoxShadow(color: Colors.white, spreadRadius: 2)],
                ),
                alignment: Alignment.center,
                child: Text('$steg', style: aeTab(inter(9.5, weight: FontWeight.w800))),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: AeOnce(
          key: ValueKey(tittel),
          kind: AeInn.bobleFraAegil,
          ms: 500,
          curve: const Cubic(.3, 1.3, .5, 1),
          alignment: Alignment.bottomLeft,
          child: CssBox(
            radius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16), bottomLeft: Radius.circular(5), bottomRight: Radius.circular(16)),
            bg: const [CssSolid(Colors.white)],
            shadows: const [CssShadow(0, 1, 2, 0, Color.fromRGBO(35, 32, 29, .07)), CssShadow(0, 12, 22, -16, Color.fromRGBO(30, 79, 92, .5))],
            padding: EdgeInsets.symmetric(horizontal: 13, vertical: tekst != null ? 11 : 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tittel,
                  style: jakarta(15, em: -.015, height: tekst != null ? 1.3 : 1.25, color: kAeInk),
                ),
                if (hint != null) ...[const SizedBox(height: 3), Text(hint!, style: inter(11, color: const Color(0xFF57534B)))],
                if (tekst != null) ...[const SizedBox(height: 4), Text(tekst!, style: inter(12.5, height: 1.45, color: const Color(0xFF3E372F)))],
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

/// One answer chip (`obKat` …): cream, or teal with a tick and lifted.
class AeObChip extends StatelessWidget {
  const AeObChip({super.key, required this.t, required this.paa, required this.onTap});

  final String t;
  final bool paa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AePress(
    onTap: onTap,
    dy: 0,
    scale: .93,
    child: AeTw(
      v: paa ? 1 : 0,
      ms: 300,
      curve: const Cubic(.3, 1.5, .5, 1),
      builder: (s) => Transform.scale(
        scale: 1 + .06 * s,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: EdgeInsets.fromLTRB(paa ? 11 : 15, 9, 15, 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: paa ? null : const Color(0xFFF5F2EC),
            gradient: paa ? const LinearGradient(begin: Alignment(-.34, -.94), end: Alignment(.34, .94), colors: [Color(0xFF2A6272), kAeTeal]) : null,
            border: Border.all(color: paa ? Colors.white : const Color.fromRGBO(35, 32, 29, .08), width: paa ? 2 : 1),
            boxShadow: [BoxShadow(color: paa ? const Color.fromRGBO(30, 79, 92, .65) : Colors.transparent, offset: const Offset(0, 8), blurRadius: 7, spreadRadius: -6)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (paa) ...[const AeOnce(kind: AeInn.klask, ms: 350, curve: Cubic(.3, 1.4, .5, 1), child: AeIkon('M4.5 12.5l5 5 10-11', size: 11, stroke: 3.4)), const SizedBox(width: 6)],
              Text(
                t,
                style: inter(12.5, weight: FontWeight.w800, em: -.01, color: paa ? Colors.white : kAeInk),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// `agObSum` — «Nå kjenner jeg deg litt!» and «Minnet er startet».
class AeObSum extends StatelessWidget {
  const AeObSum({super.key, required this.oppsummering, required this.poeng, required this.linjer, required this.lagrer, required this.onStemmer, required this.onEndre});

  final String oppsummering;
  final int poeng;
  final int linjer;
  final bool lagrer;
  final VoidCallback onStemmer;
  final VoidCallback onEndre;

  @override
  Widget build(BuildContext context) => AeOnce(
    kind: AeInn.stigOpp,
    ms: 500,
    curve: const Cubic(.3, 1.2, .5, 1),
    child: Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AeObSporsmaal(steg: 5, tittel: AeCopy.sumTittel, tekst: oppsummering),
          const SizedBox(height: 12),
          _ObKort(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    AeOnce(
                      kind: AeInn.klask,
                      ms: 500,
                      curve: const Cubic(.3, 1.4, .5, 1),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(begin: Alignment(-.34, -.94), end: Alignment(.34, .94), colors: [kAeMint, Color(0xFF2E9B7C)]),
                          boxShadow: [BoxShadow(color: Color.fromRGBO(46, 155, 124, .7), offset: Offset(0, 6), blurRadius: 6, spreadRadius: -6)],
                        ),
                        alignment: Alignment.center,
                        child: const AeIkon('M4.5 12.5l5 5 10-11', size: 18, stroke: 3.2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AeCopy.minnetStartet,
                            style: inter(13, weight: FontWeight.w800, color: kAeInk),
                          ),
                          // UI-TEMP: Placeholder data because reference UI currently has no backend/API support.
                          Text(
                            AeCopy.minnetLinje(poeng, linjer),
                            style: inter(11, weight: FontWeight.w700, color: const Color(0xFF2E6B47)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: AePress(
                        key: const Key('a1_aegil_ob_stemmer'),
                        onTap: lagrer ? null : onStemmer,
                        dy: 0,
                        scale: .96,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: kAeTeal,
                            boxShadow: const [BoxShadow(color: Color.fromRGBO(30, 79, 92, .7), offset: Offset(0, 10), blurRadius: 9, spreadRadius: -8)],
                          ),
                          child: Text(AeCopy.stemmer, style: inter(13, weight: FontWeight.w800)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AePress(
                      key: const Key('a1_aegil_ob_endre'),
                      onTap: onEndre,
                      dy: 0,
                      scale: .96,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color.fromRGBO(35, 32, 29, .06)),
                        child: Text(
                          AeCopy.endre,
                          style: inter(13, weight: FontWeight.w800, color: kAeInk),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Alle butikker (`butArk`, L5085–5118) ────────────────────────────────────

class AeButArk extends StatefulWidget {
  const AeButArk({super.key, required this.butikker, required this.valgt, required this.onVelg, required this.onLukk});

  final List<AeObButikk> butikker;
  final Set<int> valgt;
  final ValueChanged<int> onVelg;
  final VoidCallback onLukk;

  @override
  State<AeButArk> createState() => _AeButArkState();
}

class _AeButArkState extends State<AeButArk> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final filtre = [
      '',
      ...{for (final b in widget.butikker) b.kat}.where((k) => k.isNotEmpty),
    ];
    final liste = widget.butikker.where((b) => _filter.isEmpty || b.kat == _filter).toList();
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onLukk,
            child: const AeOnce(
              kind: AeInn.skjermInn,
              ms: 280,
              child: ColoredBox(color: Color.fromRGBO(15, 31, 43, .45)),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 620,
          child: AeOnce(
            kind: AeInn.arkOpp,
            ms: 420,
            curve: const Cubic(.2, .9, .3, 1),
            child: Container(
              key: const Key('a1_aegil_but_ark'),
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                color: Color(0xFFF5F3EF),
                boxShadow: [BoxShadow(color: Color.fromRGBO(15, 31, 43, .7), offset: Offset(0, -24), blurRadius: 22, spreadRadius: -22)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 2),
                    child: Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), color: const Color.fromRGBO(35, 32, 29, .22)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                    child: Row(
                      children: [
                        AePress(
                          onTap: widget.onLukk,
                          dy: 0,
                          scale: .94,
                          child: CssBox(
                            width: 38,
                            height: 38,
                            radius: BorderRadius.circular(14),
                            bg: const [CssSolid(Colors.white)],
                            shadows: const [CssShadow(0, 1, 2, 0, Color.fromRGBO(35, 32, 29, .1)), CssShadow(0, 8, 16, -10, Color.fromRGBO(35, 32, 29, .5))],
                            child: const Center(child: AeIkon('M15 6l-6 6 6 6', size: 16, stroke: 2.2, color: kAeInk)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AeCopy.alleButikker, style: jakarta(18, em: -.02, height: 1.1, color: kAeInk)),
                              Text(
                                AeCopy.butArkSub(widget.valgt.length, widget.butikker.length),
                                style: inter(11, weight: FontWeight.w700, color: const Color(0xFF57534B)),
                              ),
                            ],
                          ),
                        ),
                        AePress(
                          key: const Key('a1_aegil_but_ferdig'),
                          onTap: widget.onLukk,
                          dy: 0,
                          scale: .95,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: kAeTeal,
                              boxShadow: const [BoxShadow(color: Color.fromRGBO(30, 79, 92, .7), offset: Offset(0, 8), blurRadius: 8, spreadRadius: -8)],
                            ),
                            child: Text(AeCopy.ferdig, style: inter(12.5, weight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      children: [
                        for (final (i, f) in filtre.indexed) ...[
                          if (i > 0) const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => setState(() => _filter = f),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: f == _filter ? kAeTeal : Colors.white,
                                boxShadow: [
                                  f == _filter
                                      ? const BoxShadow(color: Color.fromRGBO(30, 79, 92, .8), offset: Offset(0, 6), blurRadius: 6, spreadRadius: -7)
                                      : const BoxShadow(color: Color.fromRGBO(35, 32, 29, .08), offset: Offset(0, 1), blurRadius: 1),
                                ],
                              ),
                              child: Text(
                                f.isEmpty ? AeCopy.alle : f,
                                style: inter(11.5, weight: FontWeight.w800, color: f == _filter ? Colors.white : const Color(0xFF57534B)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 28),
                      children: [
                        for (final b in liste)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 9),
                            child: _ButRad(b: b, paa: widget.valgt.contains(b.id), onTap: () => setState(() => widget.onVelg(b.id))),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ButRad extends StatelessWidget {
  const _ButRad({required this.b, required this.paa, required this.onTap});

  final AeObButikk b;
  final bool paa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sub = paa ? const Color.fromRGBO(255, 255, 255, .75) : const Color(0xFF6E6862);
    final deler = [b.kat, if (b.km != null) AeCopy.km(b.km!), if (b.min != null) AeCopy.min(b.min!)].where((x) => x.isNotEmpty).toList();
    return AePress(
      onTap: onTap,
      dy: 0,
      scale: .99,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: paa ? null : Colors.white,
          gradient: paa ? const LinearGradient(begin: Alignment(-.34, -.94), end: Alignment(.34, .94), colors: [Color(0xFF2A6272), kAeTeal]) : null,
          border: Border.all(color: paa ? Colors.white : Colors.transparent, width: 2),
          boxShadow: [
            paa
                ? const BoxShadow(color: Color.fromRGBO(30, 79, 92, .7), offset: Offset(0, 10), blurRadius: 9, spreadRadius: -10)
                : const BoxShadow(color: Color.fromRGBO(35, 32, 29, .5), offset: Offset(0, 10), blurRadius: 9, spreadRadius: -16),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(shape: BoxShape.circle, color: HbButikk.farge(b.id)),
              alignment: Alignment.center,
              child: Text(HbButikk.initialer(b.navn), style: jakarta(13, em: -.04)),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.navn,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: inter(13.5, weight: FontWeight.w800, em: -.01, color: paa ? Colors.white : kAeInk),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      for (final (i, d) in deler.indexed) ...[
                        if (i > 0) ...[
                          const SizedBox(width: 5),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: sub.withValues(alpha: sub.a * .5),
                            ),
                          ),
                          const SizedBox(width: 5),
                        ],
                        Flexible(
                          child: Text(
                            d,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: aeTab(inter(10.5, weight: FontWeight.w700, color: sub)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 11),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: paa ? const Color.fromRGBO(255, 255, 255, .22) : const Color.fromRGBO(35, 32, 29, .06),
                border: paa ? Border.all(color: const Color.fromRGBO(255, 255, 255, .6), width: 1.5) : null,
              ),
              alignment: Alignment.center,
              child: paa
                  ? const AeOnce(kind: AeInn.klask, ms: 350, curve: Cubic(.3, 1.4, .5, 1), child: AeIkon('M4.5 12.5l5 5 10-11', size: 13, stroke: 3.2))
                  : const AeIkon('M12 5v14M5 12h14', size: 12, stroke: 2.8, color: Color(0xFF8C847C)),
            ),
          ],
        ),
      ),
    );
  }
}
