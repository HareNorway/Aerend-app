import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../data/aegil/aegil_app_models.dart';
import '../../../data/aegil/aegil_app_repo.dart';
import '../../../data/aegil/suggestion_models.dart';
import '../../../data/points/points_app_repo.dart';
import '../meg/a3_scaffold.dart';
import '../meg/a3_services.dart';
import '../kit/bergen_kit.dart';
import 'poeng_copy.dart';

/// Fjordfiske (design `fiske` ≈L7166 + `fiskeFangst`): Ægil and the customer
/// fish in Vågen. Kast ut → the line is out → "Napp!" → DRA INN → a catch card
/// (a suggestion from `agent/suggestions?context=fiske`) with Slipp /
/// Legg i kurven / Lagre. Every `fiske_premie_hver_n`-th catch is a
/// Premiefangst from the shelf (`points/prizes/pick`). Each reeled catch earns
/// through `points/me/earn?rule=dagens_napp`, capped per day by the backend.
class FjordfiskeScreen extends StatefulWidget {
  const FjordfiskeScreen({super.key, this.points, this.aegil, this.random, this.prizeEvery = 4});

  final PointsAppApi? points;
  final AegilAppApi? aegil;
  final Random? random;
  final int prizeEvery;

  @override
  State<FjordfiskeScreen> createState() => _FjordfiskeScreenState();
}

enum _Phase { idle, out, bite, reveal, done }

class _FjordfiskeScreenState extends State<FjordfiskeScreen> {
  late final PointsAppApi _points = widget.points ?? A3Services.points();
  late final AegilAppApi _aegil = widget.aegil ?? A3Services.aegil();
  late final Random _rng = widget.random ?? Random();

  _Phase _phase = _Phase.idle;
  List<Suggestion> _pool = const [];
  Suggestion? _catch;
  AegilPick? _prize;
  EarnResult? _last;
  int _casts = 0;
  int _saved = 0;
  int _basket = 0;
  int _maxCasts = 5;
  bool _loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final pool = await a3Try(() => _aegil.suggestions(context: 'fiske')) ?? const <Suggestion>[];
    if (!mounted) return;
    setState(() {
      _pool = pool;
      _loading = false;
    });
  }

  Duration _d(Duration d) => BergenTokens.motion(context, d);

  void _cast() {
    if (_phase != _Phase.idle || _casts >= _maxCasts) return;
    setState(() {
      _phase = _Phase.out;
      _catch = null;
      _prize = null;
    });
    final wait = Duration(milliseconds: 900 + _rng.nextInt(1400));
    _timer = Timer(_d(wait), () {
      if (!mounted) return;
      setState(() => _phase = _Phase.bite);
      _timer = Timer(_d(const Duration(seconds: 4)), () {
        if (!mounted || _phase != _Phase.bite) return;
        showBergenToast(context, 'Den slapp unna. Kast ut igjen.');
        setState(() => _phase = _Phase.idle);
      });
    });
  }

  Future<void> _reel() async {
    if (_phase != _Phase.bite) return;
    _timer?.cancel();
    _casts += 1;
    final isPrize = widget.prizeEvery > 0 && _casts % widget.prizeEvery == 0;
    Suggestion? s;
    AegilPick? pick;
    if (isPrize) {
      pick = await _points.pick();
    }
    if (pick?.prize == null && _pool.isNotEmpty) {
      s = _pool[(_casts - 1) % _pool.length];
    }
    final earn = await _points.earn(catchNumber: _casts, suggestionId: s?.id);
    if (!mounted) return;
    setState(() {
      _catch = s;
      _prize = pick?.prize == null ? null : pick;
      _last = earn;
      if (earn != null && earn.max > 0) _maxCasts = earn.max;
      _phase = _Phase.reveal;
    });
    if (earn != null && earn.earned > 0) {
      showBergenToast(context, '${A3PoengCopy.a3_poeng_fiske_napp} +${earn.earned} poeng', icon: Icons.stars_rounded);
    }
  }

  void _next() {
    setState(() => _phase = _casts >= _maxCasts ? _Phase.done : _Phase.idle);
  }

  Future<void> _addToBasket() async {
    final s = _catch;
    if (s != null) {
      await _aegil.add(s.id);
      _basket += 1;
    }
    if (!mounted) return;
    showBergenToast(context, A3PoengCopy.a3_poeng_fiske_legg, icon: Icons.shopping_basket_rounded);
    _next();
  }

  Future<void> _save() async {
    final s = _catch;
    if (s != null) await _aegil.add(s.id);
    _saved += 1;
    if (!mounted) return;
    showBergenToast(context, 'Lagret', icon: Icons.bookmark_added_rounded);
    _next();
  }

  Future<void> _release() async {
    final s = _catch;
    if (s != null) await _aegil.dismiss(s.id);
    if (!mounted) return;
    _next();
  }

  Future<void> _claimPrize() async {
    final id = _prize?.prizeId;
    if (id == null) return;
    final r = await _points.claim(id);
    if (!mounted) return;
    showBergenToast(context, r.claim != null ? '${_prize?.prizeName} er din' : (r.error ?? 'Kunne ikke hente'), icon: Icons.redeem_rounded);
    _next();
  }

  @override
  Widget build(BuildContext context) {
    return A3Scaffold(
      title: A3PoengCopy.a3_poeng_fiske_title,
      subtitle: A3PoengCopy.a3_poeng_fiske_sub,
      trailing: Text(A3PoengCopy.a3_poeng_fiske_snakk(min(_casts + (_phase == _Phase.idle ? 1 : 0), _maxCasts), _maxCasts, _saved), style: BergenTokens.text(BergenTokens.textMicro, weight: FontWeight.w700, color: A3Ink.soft)),
      child: _loading
          ? const Padding(padding: EdgeInsets.only(top: 80), child: Center(child: CircularProgressIndicator(color: BergenTokens.mint)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Water(phase: _phase, onTapLine: _reel),
                const SizedBox(height: 14),
                switch (_phase) {
                  _Phase.idle => Column(
                      children: [
                        Text(A3PoengCopy.a3_poeng_fiske_hint, textAlign: TextAlign.center, style: BergenTokens.text(BergenTokens.textSmall, color: A3Ink.sub)),
                        const SizedBox(height: 10),
                        BergenCta3d(key: const Key('fiske-kast'), label: A3PoengCopy.a3_poeng_fiske_kast, icon: Icons.phishing_rounded, onPressed: _cast),
                      ],
                    ),
                  _Phase.out => Text(A3PoengCopy.a3_poeng_fiske_ute, key: const Key('fiske-ute'), textAlign: TextAlign.center, style: BergenTokens.text(BergenTokens.textBody, weight: FontWeight.w600, color: Colors.white)),
                  _Phase.bite => BergenCta3d(key: const Key('fiske-dra'), label: A3PoengCopy.a3_poeng_fiske_dra, icon: Icons.bolt_rounded, onPressed: _reel),
                  _Phase.reveal => _prize != null ? _prizeCard() : _catchCard(),
                  _Phase.done => Column(
                      children: [
                        Text(A3PoengCopy.a3_poeng_fiske_slutt(_saved, _basket), key: const Key('fiske-slutt'), textAlign: TextAlign.center, style: BergenTokens.text(BergenTokens.textBody, weight: FontWeight.w600, color: Colors.white)),
                        const SizedBox(height: 6),
                        Text(A3PoengCopy.a3_poeng_fiske_i_morgen, style: BergenTokens.text(BergenTokens.textSmall, color: A3Ink.sub)),
                        const SizedBox(height: 12),
                        BergenCta3d(label: A3PoengCopy.a3_poeng_fiske_se_lagret, icon: Icons.bookmarks_rounded, onPressed: () => Navigator.of(context).pushNamed('/bergen/meg/favoritter')),
                      ],
                    ),
                },
                if (_last != null && _last!.capped)
                  Padding(padding: const EdgeInsets.only(top: 10), child: Text('Dagens ${_last!.max} fiskepoeng er tatt — resten er bare for moro.', textAlign: TextAlign.center, style: BergenTokens.text(BergenTokens.textMicro, weight: FontWeight.w600, color: A3Ink.muted))),
              ],
            ),
    );
  }

  Widget _catchCard() {
    final s = _catch;
    return BergenCard(
      key: const Key('fiske-fangst'),
      onDark: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BergenChip(label: A3PoengCopy.a3_poeng_fiske_fangst, selected: true, icon: Icons.set_meal_rounded),
              const Spacer(),
              if (_last != null && _last!.earned > 0) Text('+${_last!.earned} poeng', style: BergenTokens.display(BergenTokens.textBody, color: BergenTokens.mint)),
            ],
          ),
          const SizedBox(height: 8),
          Text(s?.headline ?? s?.reason ?? 'Ingenting nytt i Vågen — men snøret var ute.', style: BergenTokens.display(BergenTokens.textSection, color: Colors.white)),
          if (s?.reason != null && s?.headline != null) Text(s!.reason, style: BergenTokens.text(BergenTokens.textSmall, color: A3Ink.sub)),
          const SizedBox(height: 12),
          if (s == null)
            BergenCta3d(label: 'Videre', onPressed: _next)
          else
            Row(
              children: [
                Expanded(child: OutlinedButton(key: const Key('fiske-slipp'), onPressed: _release, style: _ghost, child: const Text(A3PoengCopy.a3_poeng_fiske_slipp))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton(key: const Key('fiske-lagre'), onPressed: _save, style: _ghost, child: const Text(A3PoengCopy.a3_poeng_fiske_lagre))),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: BergenCta3d(key: const Key('fiske-legg'), label: A3PoengCopy.a3_poeng_fiske_legg, onPressed: _addToBasket)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _prizeCard() {
    final p = _prize!;
    return BergenCard(
      key: const Key('fiske-premiefangst'),
      onDark: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BergenChip(label: A3PoengCopy.a3_poeng_fiske_premiefangst, selected: true, icon: Icons.redeem_rounded),
          const SizedBox(height: 8),
          Text(A3PoengCopy.a3_poeng_fiske_fra_hylla, style: BergenTokens.text(BergenTokens.textMicro, weight: FontWeight.w800, color: A3Ink.soft)),
          Text(p.prizeName ?? '', style: BergenTokens.display(BergenTokens.textSection, color: Colors.white)),
          Text(p.reason, style: BergenTokens.text(BergenTokens.textSmall, color: A3Ink.sub)),
          if (p.pointPrice != null) Text('${p.pointPrice} ${A3PoengCopy.a3_poeng_poeng}', style: BergenTokens.display(BergenTokens.textBody, color: BergenTokens.lantern)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: _next, style: _ghost, child: const Text(A3PoengCopy.a3_poeng_fiske_slipp))),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: BergenCta3d(key: const Key('fiske-hent'), label: A3PoengCopy.a3_poeng_fiske_hent, onPressed: p.affordable ? _claimPrize : null)),
            ],
          ),
        ],
      ),
    );
  }

  ButtonStyle get _ghost => OutlinedButton.styleFrom(
    foregroundColor: Colors.white,
    side: const BorderSide(color: BergenTokens.glassBorder),
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BergenTokens.radiusButton)),
  );
}

/// The water: the line hangs from Ægil's rod; the bobber jerks on a bite and
/// the customer taps it (or the CTA) to reel in.
class _Water extends StatelessWidget {
  const _Water({required this.phase, required this.onTapLine});

  final _Phase phase;
  final VoidCallback onTapLine;

  @override
  Widget build(BuildContext context) {
    final bite = phase == _Phase.bite;
    final out = phase == _Phase.out || bite;

    return GestureDetector(
      key: const Key('fiske-vann'),
      onTap: bite ? onTapLine : null,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(BergenTokens.radiusCard),
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [BergenTokens.tealLight, BergenTokens.tealNight]),
          border: Border.all(color: BergenTokens.glassBorder),
        ),
        child: Stack(
          children: [
            Positioned(top: 18, left: 24, child: Icon(Icons.sailing_rounded, size: 44, color: Colors.white.withValues(alpha: .85))),
            if (out)
              Positioned(
                top: 48,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Container(width: 2, height: bite ? 70 : 90, color: Colors.white54),
                    AnimatedScale(
                      scale: bite ? 1.35 : 1,
                      duration: BergenTokens.motion(context, BergenTokens.motionFast),
                      child: Icon(Icons.circle, size: 18, color: bite ? BergenTokens.orange : BergenTokens.lantern),
                    ),
                  ],
                ),
              ),
            if (bite)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Text(A3PoengCopy.a3_poeng_fiske_napp, key: const Key('fiske-napp'), textAlign: TextAlign.center, style: BergenTokens.display(BergenTokens.textTitle, color: BergenTokens.orangeLight)),
              ),
          ],
        ),
      ),
    );
  }
}
