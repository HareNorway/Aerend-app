import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/lys/lys_palett.dart';
import '../../../theme/lys/modus_scope.dart';
import '../kasse/kasse_copy.dart' show KasseCopy;
import '../kasse/kurv_parts.dart' show KurvFlis;
import '../kit/ae_primitiver.dart' show AeKnappPille, aeMyk;
import '../../common/auth/launch/lf_css.dart';
import 'hurtig_bits.dart';
import 'hurtig_glass.dart';
import 'hurtig_copy.dart';

/// Design 21 Nov plan Step 4 (A1, design `Hurtig · ordreutkast` / `Hurtig · til kassen`): Ægil's draft card.
///
/// The 44 px store tile with its initials, «ÆGILS UTKAST», the store and the clock line; one row per line with a
/// 48 px tile (the product photo, else the kitchen's cloche), the name, «2 stk. · 49 kr per stk.», the line sum with
/// a small «kr» and the 32 px −/+ stepper under it; the «Passer til … Ægil foreslår» chips («+ Sitron 9 kr»); the sum
/// card («Varer» with the amount counting up, the free-delivery meter and its text, and «Levering, tid og betaling
/// velger du i kassen · ønsket tid 18:30»); the 56 px pill **«Gå til kassen · N kr»** and «Ingenting bestilles før du
/// bekrefter i kassen». Nothing here orders anything.
///
/// Motion (`hbAnim`, all off under reduced motion): on a new draft the rows enter one by one (440 ms, 180 + 120·i
/// delay, 14 px up and scale .97 → 1), the chips pop (380 ms, scale .6 → 1.06 → 1, 80 ms apart), then the sum card
/// (+120), the pill (+220) and the note (+300) follow; the amount counts up from 0 over 520 ms. On a change the
/// changed row pulses with a mint ring (700 ms), the amount dunks (scale 1.3, 360 ms) and counts from the old sum; a
/// row going to 0 slides out to the left (220 ms) before it leaves ([HbUtkastLinjeVis.ut]).
class HbUtkastKort extends StatefulWidget {
  const HbUtkastKort({
    super.key,
    required this.ini,
    required this.bg,
    this.fg = Colors.white,
    required this.butikk,
    required this.klar,
    required this.linjer,
    required this.forslag,
    required this.varer,
    required this.levGratis,
    required this.levPst,
    required this.levTekst,
    required this.kasseTekst,
    required this.cta,
    required this.onCta,
    required this.signatur,
  });

  final String ini;
  final Color bg;
  final Color fg;
  final String butikk;
  final String klar;
  final List<HbUtkastLinjeVis> linjer;
  final List<HbForslagVis> forslag;

  /// The goods' sum in kroner (the number that counts).
  final double varer;
  final bool levGratis;
  final double levPst;
  final String levTekst;
  final String kasseTekst;
  final String cta;
  final VoidCallback? onCta;

  /// The store and the line ids: a new value replays the entry (`hbAnim`'s `f.b !== sig.b`).
  final String signatur;

  @override
  State<HbUtkastKort> createState() => _HbUtkastKortState();
}

class _HbUtkastKortState extends State<HbUtkastKort> {
  /// The last quantities per line, to find the changed row.
  Map<int, int> _ant = {};
  int? _pulsId;
  int _pulsNonce = 0;
  int _dunkNonce = 0;
  double _fraVarer = 0;
  bool _ny = true;

  @override
  void initState() {
    super.initState();
    _ant = {for (final l in widget.linjer) l.id: l.ant};
  }

  @override
  void didUpdateWidget(HbUtkastKort old) {
    super.didUpdateWidget(old);
    final naa = {for (final l in widget.linjer) if (!l.ut) l.id: l.ant};
    if (old.signatur != widget.signatur && old.signatur.split('|').first != widget.signatur.split('|').first) {
      // Another store: a new draft — everything enters again, the amount counts from 0.
      _ny = true;
      _fraVarer = 0;
      _pulsId = null;
    } else {
      _ny = false;
      _fraVarer = old.varer;
      int? endret;
      for (final e in naa.entries) {
        if (_ant[e.key] != null && _ant[e.key] != e.value) endret = e.key;
      }
      if (endret != null) {
        _pulsId = endret;
        _pulsNonce++;
      }
      if (old.varer != widget.varer) _dunkNonce++;
    }
    _ant = naa;
  }

  @override
  Widget build(BuildContext context) {
    final rolig = MediaQuery.disableAnimationsOf(context);
    final svak = context.aeM(const Color.fromRGBO(255, 255, 255, .66), LysPalett.sekundar);
    final hvit = context.aeM(Colors.white, LysPalett.brod);
    final mintTx = context.aeM(kHbMintPale, LysPalett.mintTekst);
    final ik = context.aeM(kHbMintPale, kHbLysIkon);
    final kant = Border.all(color: context.aeM(const Color.fromRGBO(255, 255, 255, .08), LysPalett.kantFarge));
    final n = widget.linjer.length;
    final etter = 180 + n * 120;
    Widget inn(int delayMs, Widget child, {Key? key}) => _Inn(key: key, delayMs: _ny ? delayMs : 0, rolig: rolig || !_ny, child: child);

    return CssBox(
      key: ValueKey('utkast-${widget.signatur.split('|').first}'),
      radius: BorderRadius.circular(26),
      bg: context.aeM(
        const [CssLinear(180, [Color.fromRGBO(255, 255, 255, .09), Color.fromRGBO(255, 255, 255, .04)])],
        const [CssSolid(LysPalett.hvit)],
      ),
      border: Border.all(color: context.aeM(const Color.fromRGBO(255, 255, 255, .1), LysPalett.kantFarge)),
      shadows: context.aeM(const [CssShadow(0, 22, 34, -20, Color.fromRGBO(0, 10, 16, .9))], LysPalett.kortskygge),
      padding: const EdgeInsets.fromLTRB(13, 14, 13, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The head.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              children: [
                HbFlis(ini: widget.ini, bg: widget.bg, fg: widget.fg, size: 44, radius: 14, fontSize: 13.5),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          HbIkon(HbIkoner.lyn, size: 10, fill: context.aeM(const Color(0xFFFF9466), const Color(0xFFA63A12))),
                          const SizedBox(width: 5),
                          Text(HurtigCopy.aegilsUtkast, style: hbI(10, weight: FontWeight.w800, em: .12, color: context.aeM(kHbFersken, LysPalett.glodTekst))),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(widget.butikk, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, style: hbJ(16, em: -.015, color: hvit)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          HbIkon(HbIkoner.klokke, size: 11, stroke: ik, width: 2.6),
                          const SizedBox(width: 5),
                          Text(widget.klar, style: hbI(11, weight: FontWeight.w700, color: svak, tabular: true)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // The lines.
          CssBox(
            radius: BorderRadius.circular(20),
            bg: [CssSolid(context.aeM(const Color.fromRGBO(255, 255, 255, .04), LysPalett.dis))],
            border: kant,
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < n; i++)
                  _Ut(
                    key: ValueKey('rad-${widget.linjer[i].id}'),
                    ut: widget.linjer[i].ut,
                    rolig: rolig,
                    child: inn(
                      180 + i * 120,
                      _Puls(
                        aktiv: _pulsId == widget.linjer[i].id,
                        nonce: _pulsNonce,
                        rolig: rolig,
                        child: _linje(context, widget.linjer[i], first: i == 0),
                      ),
                    ),
                  ),
                if (widget.forslag.isNotEmpty) ...[
                  Container(height: 1, margin: const EdgeInsets.only(top: 2), color: context.aeM(const Color.fromRGBO(255, 255, 255, .08), LysPalett.kantFarge)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      HbIkon(HbIkoner.pluss, size: 11, stroke: ik, width: 3),
                      const SizedBox(width: 8),
                      Text(HurtigCopy.passerTil, style: hbI(12, weight: FontWeight.w800, color: mintTx)),
                      const Spacer(),
                      Text(HurtigCopy.aegilForeslaar, style: hbI(10.5, weight: FontWeight.w700, color: svak)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (var j = 0; j < widget.forslag.length; j++)
                        _Pop(key: ValueKey('forslag-${widget.forslag[j].navn}'), delayMs: _ny ? etter + 40 + j * 80 : 0, rolig: rolig || !_ny, child: _forslag(context, widget.forslag[j])),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          // The sum card.
          inn(
            etter + 120,
            CssBox(
              key: const Key('a1_hurtig_sum'),
              radius: BorderRadius.circular(20),
              bg: [CssSolid(context.aeM(const Color.fromRGBO(0, 0, 0, .14), LysPalett.dis))],
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(HurtigCopy.varer, style: hbI(13, weight: FontWeight.w800, color: hvit)),
                      const Spacer(),
                      _Dunk(
                        nonce: _dunkNonce,
                        rolig: rolig,
                        child: TweenAnimationBuilder<double>(
                          key: ValueKey('varer-${widget.signatur.split('|').first}'),
                          tween: Tween<double>(begin: _ny ? 0 : _fraVarer, end: widget.varer),
                          duration: rolig ? Duration.zero : const Duration(milliseconds: 520),
                          curve: Curves.easeOutCubic,
                          builder: (context, v, _) => Text.rich(
                            TextSpan(children: [
                              TextSpan(text: KasseCopy.tall(v.round()), style: hbJ(20, em: -.02, color: hvit, tabular: true)),
                              TextSpan(text: ' ${KasseCopy.a1_kasse_kr}', style: hbI(11, weight: FontWeight.w800, color: svak)),
                            ]),
                            key: const Key('a1_hurtig_varer'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: context.aeM(const Color.fromRGBO(255, 255, 255, .1), LysPalett.hvit)),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: widget.levPst.clamp(0, 1)),
                              duration: rolig ? Duration.zero : const Duration(milliseconds: 600),
                              curve: const Cubic(.3, 1.2, .4, 1),
                              builder: (context, v, _) => FractionallySizedBox(
                                widthFactor: v.clamp(0.0, 1.0),
                                child: CssBox(
                                  height: 6,
                                  radius: BorderRadius.circular(4),
                                  clip: true,
                                  bg: [widget.levGratis ? const CssLinear(90, [Color(0xFF8CF0D2), Color(0xFF2FB893)]) : const CssLinear(90, [Color(0xFFFF9466), Color(0xFFE95C2C)])],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.levTekst,
                        key: const Key('a1_hurtig_lev'),
                        style: hbI(10.5, weight: FontWeight.w800, color: widget.levGratis ? context.aeM(kHbMintLys, LysPalett.mintTekst) : context.aeM(kHbFersken, LysPalett.glodTekst)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(height: 1, color: context.aeM(const Color.fromRGBO(255, 255, 255, .08), LysPalett.hvit)),
                  const SizedBox(height: 9),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(padding: const EdgeInsets.only(top: 1), child: HbIkon(HbIkoner.kurv, size: 13, stroke: ik, width: 2.4)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(widget.kasseTekst, key: const Key('a1_hurtig_kasse_tekst'), style: hbI(11.5, weight: FontWeight.w700, height: 1.35, color: svak))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          inn(etter + 220, AeKnappPille(key: const Key('a1_hurtig_til_kassen'), label: widget.cta, onPressed: widget.onCta)),
          const SizedBox(height: 10),
          inn(
            etter + 300,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HbIkon(HbIkoner.hake, size: 11, stroke: ik, width: 2.8),
                const SizedBox(width: 6),
                Text(HurtigCopy.ingentingBestilles, key: const Key('a1_hurtig_note'), style: hbI(11.5, weight: FontWeight.w700, color: svak)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _linje(BuildContext context, HbUtkastLinjeVis l, {required bool first}) {
    final svak = context.aeM(const Color.fromRGBO(255, 255, 255, .66), LysPalett.sekundar);
    final hvit = context.aeM(Colors.white, LysPalett.brod);
    final ik = context.aeM(kHbMintPale, kHbLysIkon);
    final knappFarge = context.aeM(const Color.fromRGBO(255, 255, 255, .1), LysPalett.hvit);
    return Container(
      key: Key('a1_hurtig_rad_${l.id}'),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: first ? null : Border(top: BorderSide(color: context.aeM(const Color.fromRGBO(255, 255, 255, .08), LysPalett.kantFarge)))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KurvFlis(imageUrl: l.bilde, size: 48, radius: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(l.navn, maxLines: 2, overflow: TextOverflow.ellipsis, style: hbJ(13.5, em: -.01, height: 1.2, color: hvit))),
                    const SizedBox(width: 10),
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(text: l.sum, style: hbJ(14.5, color: hvit, tabular: true)),
                        TextSpan(text: ' ${KasseCopy.a1_kasse_kr}', style: hbI(10, weight: FontWeight.w800, color: svak)),
                      ]),
                      key: Key('a1_hurtig_radsum_${l.id}'),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(KasseCopy.a1_kasse_stk_pris(l.ant, l.enhet), style: hbI(11, weight: FontWeight.w700, color: svak, tabular: true)),
                const SizedBox(height: 8),
                CssBox(
                  height: 36,
                  radius: BorderRadius.circular(999),
                  bg: [CssSolid(context.aeM(const Color.fromRGBO(0, 0, 0, .18), LysPalett.dis))],
                  padding: const EdgeInsets.all(2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        button: true,
                        label: KasseCopy.a1_kasse_en_mindre,
                        child: HbPress(
                          dy: 2,
                          onTap: l.onMinus,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: knappFarge),
                            child: Center(child: HbIkon(HbIkoner.minus, size: 11, stroke: ik, width: 3.2)),
                          ),
                        ),
                      ),
                      SizedBox(width: 30, child: Text('${l.ant}', key: Key('a1_hurtig_ant_${l.id}'), textAlign: TextAlign.center, style: hbJ(12.5, color: hvit, tabular: true))),
                      Semantics(
                        button: true,
                        label: KasseCopy.a1_kasse_en_mer,
                        child: HbPress(
                          dy: 2,
                          onTap: l.onPluss,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: knappFarge),
                            child: Center(child: HbIkon(HbIkoner.pluss, size: 11, stroke: ik, width: 3.2)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _forslag(BuildContext context, HbForslagVis f) => HbPress(
    dy: 2.5,
    onTap: f.onTap,
    child: CssBox(
      height: 34,
      radius: BorderRadius.circular(999),
      bg: [CssSolid(context.aeM(const Color.fromRGBO(92, 224, 184, .1), LysPalett.mintDis))],
      border: Border.all(color: context.aeM(const Color.fromRGBO(92, 224, 184, .45), const Color.fromRGBO(11, 107, 87, .25))),
      padding: const EdgeInsets.fromLTRB(12, 0, 13, 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HbIkon(HbIkoner.pluss, size: 10, stroke: context.aeM(kHbMintPale, kHbLysIkon), width: 3.2),
          const SizedBox(width: 6),
          Text(f.navn, style: hbI(11.5, weight: FontWeight.w800, color: context.aeM(kHbMintPale, LysPalett.mintTekst), tabular: true)),
          const SizedBox(width: 6),
          Text(f.pris, style: hbI(11.5, weight: FontWeight.w800, color: context.aeM(kHbMintPale, LysPalett.mintTekst), tabular: true)),
        ],
      ),
    ),
  );
}

class HbUtkastLinjeVis {
  const HbUtkastLinjeVis({required this.id, required this.navn, this.bilde, required this.enhet, required this.ant, required this.sum, required this.onMinus, required this.onPluss, this.ut = false});
  final int id;
  final String navn;
  final String? bilde;

  /// The unit price as a number («49»).
  final String enhet;
  final int ant;

  /// The line sum as a number («298»).
  final String sum;
  final VoidCallback onMinus;
  final VoidCallback onPluss;

  /// The row is on its way out (quantity 0): it slides left for 220 ms before the screen drops it.
  final bool ut;
}

class HbForslagVis {
  const HbForslagVis({required this.navn, required this.pris, required this.onTap});
  final String navn;
  final String pris;
  final VoidCallback onTap;
}

// ── motion ──────────────────────────────────────────────────────────────────

/// `inn`: opacity 0 → 1, `translate3d(0,14px,0) scale(.97)` → none, 440 ms after [delayMs].
class _Inn extends StatelessWidget {
  const _Inn({super.key, required this.delayMs, required this.rolig, required this.child});
  final int delayMs;
  final bool rolig;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (rolig) return child;
    final total = delayMs + 440;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delayMs / total, 1, curve: aeMyk),
      child: child,
      builder: (context, p, child) => Opacity(
        opacity: p,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.translationValues(0, 14 * (1 - p), 0)..scaleByDouble(.97 + .03 * p, .97 + .03 * p, 1, 1),
          child: child,
        ),
      ),
    );
  }
}

/// The chips' pop: scale .6 → 1.06 (70 %) → 1 over 380 ms after [delayMs].
class _Pop extends StatelessWidget {
  const _Pop({super.key, required this.delayMs, required this.rolig, required this.child});
  final int delayMs;
  final bool rolig;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (rolig) return child;
    final total = delayMs + 380;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delayMs / total, 1),
      child: child,
      builder: (context, t, child) {
        final s = t < .7 ? .6 + .46 * Curves.easeOut.transform(t / .7) : 1.06 - .06 * ((t - .7) / .3);
        return Opacity(opacity: t.clamp(0, 1), child: Transform.scale(scale: s, child: child));
      },
    );
  }
}

/// The changed row's mint ring, 700 ms, once per [nonce] while [aktiv].
class _Puls extends StatelessWidget {
  const _Puls({required this.aktiv, required this.nonce, required this.rolig, required this.child});
  final bool aktiv;
  final int nonce;
  final bool rolig;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (rolig || !aktiv) return child;
    return TweenAnimationBuilder<double>(
      key: ValueKey(nonce),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      child: child,
      builder: (context, t, child) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Color.fromRGBO(92, 224, 184, (1 - t) * .6), spreadRadius: 1 + 3 * math.sin(math.pi * t), blurRadius: 10 * math.sin(math.pi * t))],
        ),
        child: child,
      ),
    );
  }
}

/// `dunk`: scale 1 → 1.3 (40 %) → 1 in 360 ms, once per [nonce].
class _Dunk extends StatelessWidget {
  const _Dunk({required this.nonce, required this.rolig, required this.child});
  final int nonce;
  final bool rolig;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (rolig || nonce == 0) return child;
    return TweenAnimationBuilder<double>(
      key: ValueKey(nonce),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOut,
      child: child,
      builder: (context, t, child) {
        final s = t < .4 ? 1 + .3 * (t / .4) : 1.3 - .3 * ((t - .4) / .6);
        return Transform.scale(scale: s, alignment: Alignment.centerRight, child: child);
      },
    );
  }
}

/// A row on its way out: opacity 1 → 0, 24 px to the left, 220 ms.
class _Ut extends StatelessWidget {
  const _Ut({super.key, required this.ut, required this.rolig, required this.child});
  final bool ut;
  final bool rolig;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!ut) return child;
    if (rolig) return const SizedBox.shrink();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeIn,
      child: IgnorePointer(child: child),
      builder: (context, t, child) => Opacity(opacity: 1 - t, child: Transform.translate(offset: Offset(-24 * t, 0), child: child)),
    );
  }
}
