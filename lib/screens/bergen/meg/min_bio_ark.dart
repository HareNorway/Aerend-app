import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../../data/aegil/aegil_models.dart';
import '../../../data/aegil/aegil_repo.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/auth/launch/lf_widgets.dart' show LfPress;
import '../aegil/aegil_bits.dart' show aePose;
import '../kit/bergen_kit.dart' show showBergenToast;
import '../kit/bergen_perf.dart';
import 'meg_ark.dart';
import 'min_bio.dart';
import 'min_bio_bits.dart';
import 'min_bio_kort.dart' show bioNivC;

/// Opens Min Bio (the dark Ark that glides, design L9693–9762) and saves it on
/// «Lagre i Ægils minne». Returns how many things Ægil now knows, or null
/// when the sheet was closed without saving. The toast is shown here.
Future<int?> visMinBio(BuildContext context, {required AegilRepo repo, required MinBio bio, required List<MemoryEntry> minne, Duration? autoLagre}) async {
  final k = MinBioKontroll(bio);
  final lagre = _LagreHandle();
  // Debug harness (`megArk: bioLagre`): press «Lagre» after [autoLagre].
  if (kDebugMode && autoLagre != null) Future<void>.delayed(autoLagre, () => lagre.trykk?.call());
  final n = await showMegArkGlid<int>(
    context,
    key: const Key('min-bio-ark'),
    title: BioCopy.tittel,
    subtitle: BioCopy.linje,
    body: (ctx, _) => MinBioKropp(k: k, repo: repo, minne: minne, lagre: lagre),
    primaryBuilder: (ctx) => MegArkButton(key: const Key('min-bio-lagre'), label: BioCopy.lagre, onTap: () => lagre.trykk?.call()),
  );
  // The route's exit animation still reads the controller for a moment.
  Future<void>.delayed(const Duration(milliseconds: 600), k.dispose);
  if (n != null && context.mounted) {
    showBergenToast(context, BioCopy.lagretToast(n), icon: Icons.check_rounded);
  }
  return n;
}

class _LagreHandle {
  VoidCallback? trykk;
}

/// The sheet's body. Public for the debug harness and tests.
class MinBioKropp extends StatefulWidget {
  const MinBioKropp({super.key, required this.k, required this.repo, required this.minne, required this.lagre});

  final MinBioKontroll k;
  final AegilRepo repo;
  final List<MemoryEntry> minne;
  final Object lagre;

  @override
  State<MinBioKropp> createState() => _MinBioKroppState();
}

class _Fly {
  _Fly(this.r, this.chip);

  final Rect r;
  final Widget chip;
}

class _MinBioKroppState extends State<MinBioKropp> with TickerProviderStateMixin {
  MinBioKontroll get k => widget.k;

  /// The glide's staggered entrance (`arkGlidInn`: the first eight rows).
  late final AnimationController _inn = AnimationController(vsync: this, duration: const Duration(milliseconds: 140 + 7 * 45 + 520));

  /// The save flight (`bioLagre`).
  late final AnimationController _fly = AnimationController(vsync: this);
  List<_Fly> _flyr = const [];
  Offset? _ringAt;
  double _ringStart = 0;
  bool _lagrer = false;

  final GlobalKey _stack = GlobalKey();
  final GlobalKey _aeg = GlobalKey();
  final Map<String, GlobalKey> _nokler = {};
  final Map<String, Widget> _paaKopi = {};
  final List<String> _paaRekke = [];

  final TextEditingController _tekst = TextEditingController();
  final FocusNode _tekstFokus = FocusNode();
  final Map<BioListe, TextEditingController> _ny = {for (final l in BioListe.values) l: TextEditingController()};
  final Map<BioListe, FocusNode> _nyFokus = {for (final l in BioListe.values) l: FocusNode()};

  @override
  void initState() {
    super.initState();
    _tekst.text = k.bio.tekst;
    _tekstFokus.addListener(() => setState(() {}));
    for (final f in _nyFokus.values) {
      f.addListener(() => setState(() {}));
    }
    final h = widget.lagre;
    if (h is _LagreHandle) h.trykk = _lagre;
    k.addListener(_endret);
  }

  bool _startet = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_startet) return;
    _startet = true;
    if (BergenPerf.of(context) == BergenTier.still) {
      _inn.value = 1;
    } else {
      _inn.forward();
    }
  }

  void _endret() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    k.removeListener(_endret);
    final h = widget.lagre;
    if (h is _LagreHandle && h.trykk == _lagre) h.trykk = null;
    _inn.dispose();
    _fly.dispose();
    _tekst.dispose();
    _tekstFokus.dispose();
    for (final c in _ny.values) {
      c.dispose();
    }
    for (final f in _nyFokus.values) {
      f.dispose();
    }
    super.dispose();
  }

  // ── Save (`bioLagre`) ────────────────────────────────────────────────────

  Future<void> _lagre() async {
    if (_lagrer) return;
    _lagrer = true;
    FocusScope.of(context).unfocus();
    final lagring = minBioLagre(widget.repo, k.bio, widget.minne);
    int? svar;
    var ferdig = false;
    unawaited(lagring.then((n) {
      svar = n;
      ferdig = true;
    }));
    final still = BergenPerf.of(context) == BergenTier.still;
    if (!still) await _flyInn();
    if (!mounted) return;
    final n = ferdig ? svar : await lagring;
    if (!mounted) return;
    if (n == null) {
      setState(() {
        _flyr = const [];
        _ringAt = null;
      });
      _lagrer = false;
      k.si(BioCopy.ikkeLagret);
      showBergenToast(context, BioCopy.ikkeLagret, icon: Icons.error_outline_rounded);
      return;
    }
    Navigator.of(context).pop(n);
  }

  /// The chips that are on fly into Ægil (640 ms each, 70 ms apart), a mint
  /// ring rings out, and the sheet closes 950 ms after the last one lands.
  Future<void> _flyInn() async {
    final pos = Scrollable.maybeOf(_stack.currentContext ?? context)?.position;
    if (pos != null && pos.pixels > 0) {
      unawaited(pos.animateTo(0, duration: BergenPerf.oneShot(context, 380), curve: cssEaseInOut));
    }
    await Future<void>.delayed(const Duration(milliseconds: 380));
    if (!mounted) return;
    final stack = _stack.currentContext?.findRenderObject() as RenderBox?;
    final aeg = _aeg.currentContext?.findRenderObject() as RenderBox?;
    if (stack == null || aeg == null) return;
    final ra = aeg.localToGlobal(Offset.zero, ancestor: stack) & aeg.size;
    final m = Offset(ra.center.dx, ra.top + ra.height * .42);
    final vh = pos?.viewportDimension ?? double.infinity;
    final flyr = <_Fly>[];
    for (final key in _paaRekke) {
      final box = _nokler[key]?.currentContext?.findRenderObject() as RenderBox?;
      final kopi = _paaKopi[key];
      if (box == null || kopi == null || !box.attached) continue;
      final r = box.localToGlobal(Offset.zero, ancestor: stack) & box.size;
      if (r.width > 0 && r.bottom > -8 && r.top < vh - 8) flyr.add(_Fly(r, kopi));
      if (flyr.length == 10) break;
    }
    final tot = 640 + flyr.length * 70;
    k.si(BioCopy.lagrer);
    setState(() {
      _flyr = flyr;
      _ringAt = m;
      _ringStart = math.max(200, tot - 80).toDouble();
    });
    _fly.duration = Duration(milliseconds: tot + 950);
    unawaited(_fly.forward(from: 0));
    unawaited(Future<void>.delayed(Duration(milliseconds: _ringStart.round()), () {
      if (mounted) k.si(BioCopy.lagret);
    }));
    await Future<void>.delayed(Duration(milliseconds: tot + 950));
  }

  Widget _flyLag() => AnimatedBuilder(
        animation: _fly,
        builder: (context, _) {
          final t = _fly.value * (_fly.duration?.inMilliseconds ?? 0);
          final m = _ringAt;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              if (m != null)
                for (final (i, f) in _flyr.indexed)
                  if (t < i * 70 + 640)
                    () {
                      final e = const Cubic(.5, 0, .3, 1).transform(kfP(t, i * 70.0, 640));
                      final dx = m.dx - f.r.center.dx, dy = m.dy - f.r.center.dy;
                      final x = kf(e, const [0, .4, 1], [0, dx * .3, dx]);
                      final y = kf(e, const [0, .4, 1], [0, dy * .3 - 34, dy]);
                      final s = kf(e, const [0, .4, 1], const [1, .92, .12]);
                      final o = kf(e, const [0, .4, 1], const [1, 1, .15]);
                      return Positioned.fromRect(
                        rect: f.r,
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: o,
                            child: Transform.translate(offset: Offset(x, y), child: Transform.scale(scale: s, child: f.chip)),
                          ),
                        ),
                      );
                    }(),
              if (m != null && t >= _ringStart && t < _ringStart + 700)
                () {
                  final e = const Cubic(.2, .7, .3, 1).transform(kfP(t, _ringStart, 700));
                  return Positioned(
                    left: m.dx - 34,
                    top: m.dy - 34,
                    width: 68,
                    height: 68,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: (.9 * (1 - e)).clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: .4 + 1.2 * e,
                          child: Container(
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF7FF0CB), width: 2.5)),
                          ),
                        ),
                      ),
                    ),
                  );
                }(),
            ],
          );
        },
      );

  // ── Rows ─────────────────────────────────────────────────────────────────

  /// The first eight rows come in one after another as the sheet glides up.
  Widget _innRad(int i, Widget child) {
    if (i >= 8) return child;
    return AnimatedBuilder(
      animation: _inn,
      child: child,
      builder: (context, child) {
        final p = const Cubic(.22, 1, .36, 1).transform(kfP(_inn.value * _inn.duration!.inMilliseconds, 140 + i * 45.0, 520));
        return Opacity(opacity: p.clamp(0.0, 1.0), child: Transform.translate(offset: Offset(0, 22 * (1 - p)), child: child));
      },
    );
  }

  Widget _hode(String tittel, [String? sub]) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF5CE0B8), boxShadow: [BoxShadow(color: Color(0xFF5CE0B8), blurRadius: 4)]),
                ),
                const SizedBox(width: 7),
                Text(tittel, style: inter(11, weight: FontWeight.w800, em: .06, color: const Color(0xFF7FF0CB))),
              ],
            ),
            if (sub != null) ...[
              const SizedBox(height: 3),
              Text(sub, style: inter(11.5, weight: FontWeight.w600, height: 1.4, color: const Color.fromRGBO(255, 255, 255, .62))),
            ],
          ],
        ),
      );

  Widget _chip({
    required String key,
    required String tx,
    required bool paa,
    required BioStil stil,
    String? ik,
    bool fra = false,
    String? merke,
    Color? merkeBg,
    Color? merkeC,
    required VoidCallback onTap,
  }) {
    final nokkel = _nokler.putIfAbsent(key, GlobalKey.new);
    final kopi = _BioChipFlate(tx: tx, stil: stil, ik: ik, paa: paa, fra: fra, merke: merke, merkeBg: merkeBg, merkeC: merkeC);
    if (paa) {
      _paaKopi[key] = kopi;
      _paaRekke.add(key);
    }
    return _BioChip(
      key: ValueKey('bio-chip-$key'),
      nokkel: nokkel,
      stil: stil,
      pop: key == k.sist ? k.n : null,
      onTap: onTap,
      flate: kopi,
    );
  }

  List<Widget> _grupper(BioEff E) {
    final b = k.bio;
    final forslag = E.forslag;
    final kost = [
      for (final x in [...bioKostListe, ...b.egneI(BioListe.kost)])
        () {
          final on = E.kost.contains(x);
          return _chip(
            key: 'kost:$x',
            tx: x,
            paa: on,
            fra: forslag.contains('kost:$x'),
            ik: on ? BioIk.hake : null,
            stil: on ? BioStil.mint : BioStil.av,
            onTap: () => k.kost(x),
          );
        }(),
    ];
    final ingenPaa = k.ingenPaa;
    final all = [
      for (final x in [...bioAllListe, ...b.egneI(BioListe.all)])
        () {
          final v = E.all[x];
          final allergi = v == BioAll.allergi;
          return _chip(
            key: 'all:$x',
            tx: x,
            paa: v != null,
            fra: (v != null && !b.all.containsKey(x)) || forslag.contains('all:$x'),
            ik: v != null ? BioIk.varsel : null,
            stil: allergi ? BioStil.ora : (v == BioAll.unnga ? BioStil.gul : BioStil.av),
            merke: allergi ? BioCopy.merkeAllergi : (v == BioAll.unnga ? BioCopy.merkeUnngaar : null),
            merkeBg: allergi ? const Color(0xFFF26D3D) : const Color.fromRGBO(246, 210, 122, .92),
            merkeC: allergi ? Colors.white : const Color(0xFF4A300A),
            onTap: () => k.allTrykk(x),
          );
        }(),
      _chip(key: 'ingen', tx: BioCopy.ingenAllergier, paa: ingenPaa, ik: ingenPaa ? BioIk.hake : null, stil: ingenPaa ? BioStil.mint : BioStil.av, onTap: k.ingen),
    ];
    final lik = [
      for (final x in [...bioLikListe, ...b.egneI(BioListe.liker)])
        () {
          final on = E.liker.contains(x);
          return _chip(key: 'lik:$x', tx: x, paa: on, fra: on && !b.liker.contains(x), ik: on ? BioIk.hjerte : null, stil: on ? BioStil.mint : BioStil.av, onTap: () => k.lik(x, BioListe.liker));
        }(),
    ];
    final ikke = [
      for (final x in [...bioIkkeListe, ...b.egneI(BioListe.ikke)])
        () {
          final on = E.ikke.contains(x);
          return _chip(key: 'ikke:$x', tx: x, paa: on, fra: on && !b.ikke.contains(x), ik: on ? BioIk.nei : null, stil: on ? BioStil.nei : BioStil.av, onTap: () => k.lik(x, BioListe.ikke));
        }(),
    ];
    Widget wrap(List<Widget> c) => Wrap(spacing: 6, runSpacing: 6, children: c);
    return [
      _hode(BioCopy.k1, BioCopy.k1Sub),
      wrap(kost),
      _NyFelt(liste: BioListe.kost, c: _ny[BioListe.kost]!, f: _nyFokus[BioListe.kost]!, onLegg: _legg),
      _hode(BioCopy.k2, BioCopy.k2Sub),
      wrap(all),
      _NyFelt(liste: BioListe.all, c: _ny[BioListe.all]!, f: _nyFokus[BioListe.all]!, onLegg: _legg),
      _hode(BioCopy.k3, BioCopy.k3Sub),
      wrap(lik),
      _NyFelt(liste: BioListe.liker, c: _ny[BioListe.liker]!, f: _nyFokus[BioListe.liker]!, onLegg: _legg),
      _hode(BioCopy.k4, BioCopy.k4Sub),
      wrap(ikke),
      _NyFelt(liste: BioListe.ikke, c: _ny[BioListe.ikke]!, f: _nyFokus[BioListe.ikke]!, onLegg: _legg),
    ];
  }

  void _legg(BioListe l) {
    final tx = _ny[l]!.text;
    _ny[l]!.clear();
    k.nyLegg(l, tx);
  }

  @override
  Widget build(BuildContext context) {
    _paaKopi.clear();
    _paaRekke.clear();
    final b = k.bio;
    final E = k.eff;
    final score = bioScore(b, E);
    final gull = score == 5;
    final P = E.p;
    final fT = P.tagger;
    final rader = <Widget>[
      // Ægil and his bubble.
      Padding(
        padding: const EdgeInsets.fromLTRB(2, 2, 2, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(key: _aeg, width: 76, height: 86, child: _AegilHopp(n: k.n)),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 26),
                child: BioOmstart(
                  trigger: k.n,
                  ms: 420,
                  builder: (context, t, child) {
                    final p = kfP(t, 0, 420);
                    const c = Cubic(.3, 1.4, .5, 1);
                    final s = kf(p, const [0, 1], const [.9, 1], c);
                    final x = kf(p, const [0, 1], const [-6, 0], c);
                    final o = kf(p, const [0, 1], const [0, 1], c);
                    return Opacity(
                      opacity: o.clamp(0.0, 1.0),
                      child: Transform(
                        alignment: Alignment.bottomLeft,
                        transform: Matrix4.translationValues(x, -x, 0)..scaleByDouble(s, s, 1, 1),
                        child: child,
                      ),
                    );
                  },
                  child: _Boble(tekst: k.aeg ?? BioCopy.aegStart),
                ),
              ),
            ),
          ],
        ),
      ),
      // ÆGIL KJENNER DEG · the score.
      CssBox(
        radius: BorderRadius.circular(20),
        clip: true,
        bg: const [CssLinear(180, [Color.fromRGBO(255, 255, 255, .14), Color.fromRGBO(255, 255, 255, .05)])],
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, .16)),
        shadows: const [CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .22)), CssShadow(0, 12, 20, -14, Color.fromRGBO(0, 10, 16, .85))],
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -50,
              width: 160,
              height: 120,
              child: IgnorePointer(
                child: CssBox(
                  radius: const BorderRadius.all(Radius.elliptical(80, 60)),
                  bg: [CssRadial.closestSide([gull ? const Color.fromRGBO(242, 193, 78, .24) : const Color.fromRGBO(92, 224, 184, .2), const Color.fromRGBO(0, 0, 0, 0)])],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(BioCopy.kjennerDeg, style: inter(10.5, weight: FontWeight.w800, em: .08, color: const Color.fromRGBO(255, 255, 255, .6))),
                            const SizedBox(height: 2),
                            Text(bioNivaaNavn[score], style: jakarta(20, em: -.02)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        height: 28,
                        padding: const EdgeInsets.fromLTRB(9, 0, 11, 0),
                        decoration: BoxDecoration(
                          color: gull ? const Color.fromRGBO(242, 193, 78, .16) : const Color.fromRGBO(92, 224, 184, .14),
                          border: Border.all(color: gull ? const Color.fromRGBO(246, 210, 122, .55) : const Color.fromRGBO(92, 224, 184, .45)),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            BioIkon(BioIk.stjerne, color: bioNivC(score), size: 12, fill: true),
                            const SizedBox(width: 5),
                            Text(BioCopy.score(score), style: inter(12, weight: FontWeight.w800, color: bioNivC(score)).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  BioSegmenter(score: score, h: 9),
                  const SizedBox(height: 9),
                  Text(bioNeste(b, E), style: inter(11.5, weight: FontWeight.w700, height: 1.4, color: const Color.fromRGBO(255, 255, 255, .78))),
                ],
              ),
            ),
          ],
        ),
      ),
      ..._grupper(E),
      _hode(BioCopy.k5),
      _Tekstfelt(
        c: _tekst,
        f: _tekstFokus,
        skriver: k.skriver,
        onEndret: k.skriv,
      ),
      if (fT.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 2, 2, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const BioIkon(BioIk.stjerne, color: Color(0xFFFFDD86), size: 11, fill: true),
                  const SizedBox(width: 6),
                  Text(BioCopy.fanget, style: inter(10.5, weight: FontWeight.w800, em: .08, color: const Color(0xFFFFDD86))),
                ],
              ),
              const SizedBox(height: 7),
              Wrap(
                spacing: 5,
                runSpacing: 5,
                children: [
                  for (final key in fT)
                    () {
                      final t = key.substring(0, key.indexOf(':'));
                      final nm = key.substring(key.indexOf(':') + 1);
                      final stil = t == 'all' ? (P.all[nm] == BioAll.allergi ? BioStil.ora : BioStil.gul) : (t == 'ikke' ? BioStil.nei : BioStil.mint);
                      final ik = switch (t) { 'all' => BioIk.varsel, 'kost' => BioIk.blad, 'lik' => BioIk.hjerte, _ => BioIk.nei };
                      final chip = BioSmaaChip(tx: bioStor(bioEtikett(key, P)), stil: stil, ik: ik);
                      return BioOmstart(
                        key: ValueKey('bio-funn-$key'),
                        trigger: k.nye.contains(key) ? k.n : null,
                        ms: 450,
                        vedStart: false,
                        builder: (context, t, child) => bioPop(t, child!, ms: 450),
                        child: chip,
                      );
                    }(),
                ],
              ),
            ],
          ),
        ),
      // «6 · Slik bruker Ærend bioen» and «Skjul det jeg ikke tåler» are left
      // out: only Ægil's own suggestions read the bio today (needs sign-off).
    ];
    return Stack(
      key: _stack,
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, r) in rader.indexed) ...[
              if (i > 0) const SizedBox(height: 8),
              _innRad(i, r),
            ],
          ],
        ),
        Positioned.fill(child: IgnorePointer(child: _flyLag())),
      ],
    );
  }
}

/// Ægil at the top of the sheet: the breathing glow (`bioPuls`), his shadow,
/// and a hop each time he says something (`bioHopp`, .6 s, then `aegStaa`).
class _AegilHopp extends StatefulWidget {
  const _AegilHopp({required this.n});

  final int n;

  @override
  State<_AegilHopp> createState() => _AegilHoppState();
}

class _AegilHoppState extends State<_AegilHopp> with SingleTickerProviderStateMixin {
  late final Ticker _t = createTicker(_tikk);
  final ValueNotifier<double> _e = ValueNotifier(0);
  Duration _start = Duration.zero;
  Duration _naa = Duration.zero;
  bool _loop = true;

  void _tikk(Duration d) {
    _naa = d;
    final e = (d - _start).inMicroseconds / 1000.0;
    _e.value = e;
    // `lite`: the hop plays, the breathing rests.
    if (!_loop && (widget.n == 0 || e >= 600)) {
      _e.value = -1;
      _t.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tier = BergenPerf.of(context);
    _loop = tier == BergenTier.full;
    if (tier == BergenTier.still) {
      _t.stop();
      _e.value = -1;
    } else if (_loop && !_t.isActive) {
      _t.start();
    } else if (!_loop) {
      _e.value = -1;
    }
  }

  @override
  void didUpdateWidget(_AegilHopp old) {
    super.didUpdateWidget(old);
    if (old.n != widget.n && BergenPerf.of(context) != BergenTier.still) {
      if (_t.isActive) {
        _start = _naa;
      } else {
        _start = Duration.zero;
        _t.start();
      }
    }
  }

  @override
  void dispose() {
    _t.dispose();
    _e.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 3,
            top: 4,
            width: 70,
            height: 70,
            child: LfLoop(
              frozenMs: -1,
              builder: (context, t, child) {
                if (t < 0) return child!;
                final p = (t / 3000) % 1;
                final s = kf(p, const [0, .5, 1], const [.92, 1.08, .92], cssEaseInOut);
                final o = kf(p, const [0, .5, 1], const [.6, 1, .6], cssEaseInOut);
                return Opacity(opacity: o, child: Transform.scale(scale: s, child: child));
              },
              child: const CssBox(
                radius: BorderRadius.all(Radius.circular(999)),
                bg: [CssRadial.closestSide([Color.fromRGBO(127, 240, 203, .32), Color.fromRGBO(127, 240, 203, 0)])],
              ),
            ),
          ),
          const Positioned(
            left: 12,
            right: 12,
            bottom: 0,
            height: 9,
            child: CssBox(
              radius: BorderRadius.all(Radius.elliptical(26, 4.5)),
              bg: [CssRadial.closestSide([Color.fromRGBO(3, 14, 20, .55), Color.fromRGBO(3, 14, 20, 0)])],
            ),
          ),
          Positioned(
            left: 4,
            width: 68,
            bottom: 4,
            child: ValueListenableBuilder<double>(
              valueListenable: _e,
              child: Image.asset(aePose('front'), width: 68, fit: BoxFit.fitWidth),
              builder: (context, e, child) {
                Matrix4 m;
                if (e < 0) {
                  m = Matrix4.identity();
                } else if (widget.n > 0 && e < 600) {
                  final p = e / 600;
                  const c = Cubic(.3, 1.3, .5, 1);
                  final y = kf(p, const [0, .35, .7, 1], const [0, -10, 0, 0], c);
                  final r = kf(p, const [0, .35, .7, 1], [0, widget.n.isOdd ? -4 : 4, 0, 0], c);
                  final sx = kf(p, const [0, .35, .7, 1], const [1, 1, 1.04, 1], c);
                  final sy = kf(p, const [0, .35, .7, 1], const [1, 1, .95, 1], c);
                  m = Matrix4.translationValues(0, y, 0)
                    ..rotateZ(r * math.pi / 180)
                    ..scaleByDouble(sx, sy, 1, 1);
                } else {
                  m = aegStaa(widget.n > 0 ? e - 600 : e, 3400);
                }
                return Transform(alignment: Alignment.bottomCenter, transform: m, child: child);
              },
            ),
          ),
        ],
      );
}

/// Ægil's white speech bubble with its tail bottom-left.
class _Boble extends StatelessWidget {
  const _Boble({required this.tekst});

  final String tekst;

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -5,
            bottom: 9,
            width: 12,
            height: 12,
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(decoration: BoxDecoration(color: const Color(0xFFEAF5F1), borderRadius: BorderRadius.circular(2))),
            ),
          ),
          CssBox(
            key: const Key('min-bio-boble'),
            radius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomRight: Radius.circular(18), bottomLeft: Radius.circular(6)),
            bg: const [CssLinear(180, [Colors.white, Color(0xFFEAF5F1)])],
            shadows: const [CssShadow(0, 10, 18, -10, Color.fromRGBO(0, 10, 16, .8))],
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(tekst, style: inter(12.5, weight: FontWeight.w700, height: 1.42, color: const Color(0xFF173E48))),
          ),
        ],
      );
}

/// A 38 px chip's face (also the copy that flies on save).
class _BioChipFlate extends StatelessWidget {
  const _BioChipFlate({required this.tx, required this.stil, this.ik, required this.paa, this.fra = false, this.merke, this.merkeBg, this.merkeC});

  final String tx;
  final BioStil stil;
  final String? ik;
  final bool paa, fra;
  final String? merke;
  final Color? merkeBg, merkeC;

  @override
  Widget build(BuildContext context) => CssBox(
        height: 38,
        radius: BorderRadius.circular(999),
        bg: stil.bg,
        border: Border.all(color: stil.bd),
        shadows: paa ? const [CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .25)), CssShadow(0, 6, 12, -8, Color.fromRGBO(0, 10, 16, .8))] : const [],
        padding: EdgeInsets.fromLTRB(ik != null ? 10 : 14, 0, 13, 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ik != null ? BioIkon(ik!, color: stil.c, size: 13) : const SizedBox(width: 0),
            const SizedBox(width: 6),
            Text(tx, style: inter(12.5, weight: FontWeight.w800, color: stil.c)),
            if (merke != null) ...[
              const SizedBox(width: 6),
              Container(
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: merkeBg, borderRadius: BorderRadius.circular(999)),
                child: Text(merke!, style: inter(9.5, weight: FontWeight.w800, em: .03, color: merkeC ?? Colors.white)),
              ),
            ],
            if (fra) ...[const SizedBox(width: 6), const BioIkon(BioIk.stjerne, color: Color(0xFFFFDD86), size: 10, fill: true)],
          ],
        ),
      );
}

/// A tappable 38 px chip: its colours ease over .25 s, it presses to .95 and
/// pops when it is the one just set.
class _BioChip extends StatefulWidget {
  const _BioChip({super.key, required this.nokkel, required this.stil, required this.pop, required this.onTap, required this.flate});

  final GlobalKey nokkel;
  final BioStil stil;
  final Object? pop;
  final VoidCallback onTap;
  final _BioChipFlate flate;

  @override
  State<_BioChip> createState() => _BioChipState();
}

class _BioChipState extends State<_BioChip> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, value: 1);
  late BioStil _fra = widget.stil;

  @override
  void didUpdateWidget(_BioChip old) {
    super.didUpdateWidget(old);
    if (old.stil != widget.stil) {
      _fra = BioStil.lerp(_fra, old.stil, cssEase.transform(_c.value));
      _c.duration = BergenPerf.oneShot(context, 250);
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LfPress(
        onTap: widget.onTap,
        scale: .95,
        ms: 140,
        child: BioOmstart(
          trigger: widget.pop,
          ms: 420,
          vedStart: false,
          builder: (context, t, child) => bioPop(t, child!),
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final f = widget.flate;
              final stil = BioStil.lerp(_fra, widget.stil, cssEase.transform(_c.value));
              return KeyedSubtree(
                key: widget.nokkel,
                child: _BioChipFlate(tx: f.tx, stil: stil, ik: f.ik, paa: f.paa, fra: f.fra, merke: f.merke, merkeBg: f.merkeBg, merkeC: f.merkeC),
              );
            },
          ),
        ),
      );
}

/// «Mangler noe? …» — a dashed pill to add a chip of one's own.
class _NyFelt extends StatelessWidget {
  const _NyFelt({required this.liste, required this.c, required this.f, required this.onLegg});

  final BioListe liste;
  final TextEditingController c;
  final FocusNode f;
  final ValueChanged<BioListe> onLegg;

  @override
  Widget build(BuildContext context) {
    final fok = f.hasFocus;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: c,
      builder: (context, v, _) {
        final kan = v.text.trim().isNotEmpty;
        final ms = BergenPerf.oneShot(context, 250);
        return TextFieldTapRegion(
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: fok ? 1 : 0),
            duration: ms,
            curve: cssEase,
            builder: (context, a, child) => CustomPaint(
              painter: _Strek(Color.lerp(const Color.fromRGBO(255, 255, 255, .24), const Color.fromRGBO(127, 240, 203, .85), a)!),
              child: Container(
                height: 44,
                padding: const EdgeInsets.fromLTRB(12, 0, 5, 0),
                decoration: BoxDecoration(
                  color: Color.lerp(const Color.fromRGBO(255, 255, 255, .05), const Color.fromRGBO(255, 255, 255, .1), a),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [BoxShadow(color: Color.fromRGBO(92, 224, 184, .16 * a), spreadRadius: 3)],
                ),
                child: child,
              ),
            ),
            child: Row(
              children: [
                AnimatedRotation(
                  turns: fok || kan ? .25 : 0,
                  duration: BergenPerf.oneShot(context, 350),
                  curve: const Cubic(.3, 1.4, .5, 1),
                  child: const BioIkon(BioIk.pluss, color: Color(0xFF7FF0CB), size: 15),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    key: Key('min-bio-ny-${liste.name}'),
                    controller: c,
                    focusNode: f,
                    maxLength: 28,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => onLegg(liste),
                    cursorColor: const Color(0xFF5CE0B8),
                    style: inter(13, weight: FontWeight.w700),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      counterText: '',
                      hintText: BioCopy.nyHint[liste],
                      hintStyle: inter(13, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .5)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                LfPress(
                  onTap: () => onLegg(liste),
                  scale: .95,
                  ms: 140,
                  child: AnimatedContainer(
                    duration: ms,
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: kan ? null : const Color.fromRGBO(255, 255, 255, .08),
                      gradient: kan
                          ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], stops: [0, .56, 1])
                          : null,
                      boxShadow: kan
                          ? const [
                              BoxShadow(color: Color.fromRGBO(255, 255, 255, .4), spreadRadius: 1),
                              BoxShadow(color: Color(0xFFC4491A), offset: Offset(0, 1.5)),
                              BoxShadow(color: Color.fromRGBO(200, 70, 25, .8), offset: Offset(0, 6), blurRadius: 5, spreadRadius: -6),
                            ]
                          : null,
                    ),
                    child: Text(BioCopy.leggTil, style: inter(12, weight: FontWeight.w800, color: kan ? Colors.white : const Color.fromRGBO(255, 255, 255, .5))),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A 1 px dashed pill outline (CSS `border-style: dashed`).
class _Strek extends CustomPainter {
  const _Strek(this.c);

  final Color c;

  @override
  void paint(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius((Offset.zero & size).deflate(.5), Radius.circular(size.height / 2));
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = c;
    for (final PathMetric m in (Path()..addRRect(rr)).computeMetrics()) {
      for (double d = 0; d < m.length; d += 6) {
        canvas.drawPath(m.extractPath(d, math.min(d + 3, m.length)), p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _Strek old) => old.c != c;
}

/// «5 · Med egne ord»: the text, read as it is typed.
class _Tekstfelt extends StatelessWidget {
  const _Tekstfelt({required this.c, required this.f, required this.skriver, required this.onEndret});

  final TextEditingController c;
  final FocusNode f;
  final bool skriver;
  final ValueChanged<String> onEndret;

  @override
  Widget build(BuildContext context) {
    final fok = f.hasFocus;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: fok ? 1 : 0),
      duration: BergenPerf.oneShot(context, 250),
      curve: cssEase,
      builder: (context, a, child) => CssBox(
        radius: BorderRadius.circular(20),
        clip: true,
        bg: const [CssLinear(180, [Color.fromRGBO(255, 255, 255, .14), Color.fromRGBO(255, 255, 255, .05)])],
        border: Border.all(color: Color.lerp(const Color.fromRGBO(255, 255, 255, .16), const Color.fromRGBO(127, 240, 203, .85), a)!),
        shadows: [
          const CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .22)),
          CssShadow(0, 0, 0, 3, Color.fromRGBO(92, 224, 184, .18 * a)),
          const CssShadow(0, 12, 20, -14, Color.fromRGBO(0, 10, 16, .85)),
        ],
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: child,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 16),
            child: Row(
              children: [
                Text(BioCopy.skrivSom, style: inter(10.5, weight: FontWeight.w800, em: .08, color: const Color.fromRGBO(255, 255, 255, .6))),
                const Spacer(),
                if (skriver)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const BioDot(ms: 1000, glow: 0),
                      const SizedBox(width: 5),
                      Text(BioCopy.aegilLeser, style: inter(11, weight: FontWeight.w800, color: const Color(0xFF7FF0CB))),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 96,
            child: TextField(
              key: const Key('min-bio-tekst'),
              controller: c,
              focusNode: f,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              keyboardType: TextInputType.multiline,
              inputFormatters: [LengthLimitingTextInputFormatter(400)],
              onChanged: onEndret,
              cursorColor: const Color(0xFF5CE0B8),
              style: inter(14, weight: FontWeight.w600, height: 1.5),
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: BioCopy.tekstHint,
                hintMaxLines: 4,
                hintStyle: inter(14, weight: FontWeight.w600, height: 1.5, color: const Color.fromRGBO(255, 255, 255, .5)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 3,
              child: ColoredBox(
                color: const Color.fromRGBO(255, 255, 255, .1),
                child: skriver
                    ? LayoutBuilder(
                        builder: (context, box) => LfLoop(
                          essential: true,
                          builder: (context, t, _) {
                            final w = box.maxWidth * .3;
                            final x = (-1 + 4.4 * ((t / 1400) % 1)) * w;
                            return Stack(
                              children: [
                                Positioned(
                                  left: x,
                                  top: 0,
                                  bottom: 0,
                                  width: w,
                                  child: const DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [Color.fromRGBO(127, 240, 203, 0), Color(0xFF7FF0CB), Color.fromRGBO(127, 240, 203, 0)]),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 6),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: c,
            builder: (context, v, _) => Row(
              children: [
                Expanded(child: Text(BioCopy.plukker, style: inter(10.5, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .55)))),
                const SizedBox(width: 8),
                Text('${v.text.length}/400', style: inter(10.5, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .55)).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
