import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../data/points/points_app_repo.dart';
import '../../../data/points/points_models.dart';
import '../../common/home/bergen/bergen_kit.dart' show bergenSvg;
import '../kit/bergen_kit.dart';
import '../meg/a3_services.dart';
import '../meg/meg_ark.dart';
import '../meg/meg_copy_a4.dart';
import '../meg/meg_mark.dart';
import '../meg/meg_nivaa_card.dart' show MegMedal, medalFor;
import '../meg/meg_sheets.dart';
import '../meg/meg_shine.dart';
import 'aegil_velger_screen.dart';
import 'prize_art.dart';

/// Premiehylla (design `Premiehylla` ≈L6177), 1:1 with the design: the
/// Torgallmenningen header with the back square, the points pill and Ægil
/// holding a voucher; the rounded teal sheet with the title, the Nivå row, the
/// goal card, "Mine premier" as perforated tickets, "Åpent på {nivå}" as a
/// two-column shelf of prize cards standing on wooden lips, "Låst til {neste}",
/// and the 60-day note. Data: `points/me`, `points/prizes`, `points/claims`.
class PremiehyllaScreen extends StatefulWidget {
  const PremiehyllaScreen({super.key, this.api});

  final PointsAppApi? api;

  @override
  State<PremiehyllaScreen> createState() => _PremiehyllaScreenState();
}

class _PremiehyllaScreenState extends State<PremiehyllaScreen> {
  late final PointsAppApi _api = widget.api ?? A3Services.points();
  PointsBalance? _balance;
  Premiehylla? _shelf;
  List<PrizeClaim> _claims = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await Future.wait<Object?>([a3Try(_api.balance), a3Try(_api.shelf), a3Try(_api.claims)]);
    if (!mounted) return;
    setState(() {
      _balance = r[0] as PointsBalance?;
      _shelf = r[1] as Premiehylla?;
      _claims = (r[2] as List<PrizeClaim>?) ?? const [];
      _loading = false;
    });
  }

  int get _points => _balance?.available ?? 0;

  Future<void> _setGoal(Prize p) async {
    if (_shelf?.goal?.prizeId == p.id) {
      showBergenToast(context, A4MegCopy.a4_hylla_er_maal);
      return;
    }
    final g = await _api.setGoal(prizeId: p.id);
    if (!mounted) return;
    if (g != null) {
      showBergenToast(context, A4MegCopy.a4_hylla_satt_maal(p.pointPrice - _points), icon: Icons.flag_rounded);
      _load();
    }
  }

  Future<void> _hent(Prize p) async {
    if (!p.inStock) {
      showBergenToast(context, A4MegCopy.a4_hylla_utsolgt_toast(p.name));
      return;
    }
    if (!p.affordable) {
      await _setGoal(p);
      return;
    }
    final claimed = await _krevArk(p);
    if (claimed == true && mounted) _load();
  }

  /// `krev`: what happens, how long it lasts, points after — and the boat asks
  /// for its name first (identity prize).
  Future<bool?> _krevArk(Prize p) {
    final after = (_points - p.pointPrice).clamp(0, 1 << 30);
    final identity = p.type == 'identity';
    final name = TextEditingController();
    var busy = false;
    String? error;
    StateSetter? sheetSet;

    return showMegArk<bool>(
      context,
      key: const Key('hylla-krev-sheet'),
      title: p.name,
      subtitle: identity ? A4MegCopy.a4_hylla_baat_linje : '${A4MegCopy.nf(p.pointPrice)} poeng${p.partnerName == null ? '' : ' · ${p.partnerName}'}',
      body: (ctx, setState) {
        sheetSet = setState;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (identity)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  key: const Key('hylla-baat-navn'),
                  controller: name,
                  maxLength: 20,
                  onChanged: (_) => setState(() {}),
                  style: BergenTokens.text(15, weight: FontWeight.w800, color: MegArkInk.ink),
                  decoration: InputDecoration(
                    hintText: A4MegCopy.a4_hylla_baat_hint,
                    counterText: '${name.text.length} av 20 tegn',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: .7),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: .9), width: 1.5)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: .9), width: 1.5)),
                  ),
                ),
              ),
            MegArkRow(title: A4MegCopy.a4_hylla_dette_skjer, sub: identity ? A4MegCopy.a4_hylla_baat_skjer : _hvordan(p.type)),
            MegArkRow(title: A4MegCopy.a4_hylla_gyldighet, sub: identity ? A4MegCopy.a4_hylla_baat_gyldig : A4MegCopy.a4_hylla_60_dager),
            MegArkRow(title: A4MegCopy.a4_hylla_poeng_etter, sub: '${A4MegCopy.nf(after)} poeng'),
            if (error != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(error!, style: megInter(12, FontWeight.w700, color: const Color(0xFFB9441A)))),
          ],
        );
      },
      primary: MegArkButton(
        key: const Key('hylla-krev-cta'),
        label: identity ? A4MegCopy.a4_hylla_baat_cta : A4MegCopy.a4_hylla_hent_for(p.pointPrice),
        onTap: () async {
          if (busy) return;
          if (identity && name.text.trim().isEmpty) {
            showBergenToast(context, A4MegCopy.a4_hylla_baat_navn_forst);
            return;
          }
          busy = true;
          final nav = Navigator.of(context);
          final r = await _api.claim(p.id, identityName: identity ? name.text.trim() : null);
          busy = false;
          if (r.claim != null) {
            nav.pop(true);
            if (mounted) showBergenToast(context, A4MegCopy.a4_hylla_hentet(p.name), icon: Icons.check_rounded);
          } else {
            sheetSet?.call(() => error = r.error ?? A4MegCopy.a4_hylla_feil);
          }
        },
      ),
    );
  }

  static String _hvordan(String type) {
    switch (type) {
      case 'voucher':
        return 'Brukes automatisk på neste levering';
      case 'physical':
        return 'Sendes hjem til deg';
      case 'donation':
        return 'Gis til klubben du velger';
      case 'identity':
        return 'Båten din legges i Vågen';
      default:
        return 'Kode vises her';
    }
  }

  void _openVelger() => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AegilVelgerScreen(api: _api))).then((_) => _load());

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: const Color(0xFF173E48),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2A6272), Color(0xFF1E4F5C), Color(0xFF173E48)], stops: [0, .42, 1]),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(top: 0, left: 0, right: 0, child: _Hero(top: top, points: _points, onBack: () => Navigator.of(context).maybePop())),
            Positioned.fill(
              top: top + 136,
              child: _Sheet(
                child: _loading ? const Padding(padding: EdgeInsets.only(top: 60), child: Center(child: CircularProgressIndicator(color: BergenTokens.mint))) : _body(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    final b = _balance;
    final shelf = _shelf;
    final goal = shelf?.goal;
    final prizes = shelf?.prizes ?? const <Prize>[];
    final previews = shelf?.previews ?? const <PrizePreview>[];
    final klare = prizes.where((p) => p.inStock && p.affordable).length;
    final byId = {for (final p in prizes) p.id: p};
    final cheapest = prizes.where((p) => p.inStock).map((p) => p.pointPrice).fold<int?>(null, (a, v) => a == null || v < a ? v : a);

    return ListView(
      key: const Key('hylla-list'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 132),
      children: [
        Text(A4MegCopy.a4_hylla_title, style: BergenTokens.display(27, weight: FontWeight.w800, color: Colors.white, letterSpacingEm: -0.035, height: 1.05)),
        const SizedBox(height: 4),
        Text(A4MegCopy.a4_hylla_sub, style: megInter(12, FontWeight.w700, color: Colors.white.withValues(alpha: .72))),
        if (b != null) ...[
          const SizedBox(height: 12),
          _PaperCard(
            key: const Key('hylla-nivaa'),
            onTap: () => MegSheets.nivaa(context, b, opens: previews),
            padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
            child: Row(
              children: [
                MegMedal(name: b.tierName, size: 36, animate: false),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(text: 'Nivå · ${b.tierName} · ', style: megInter(11.5, FontWeight.w800, color: MegArkInk.ink, height: 1.35)),
                      TextSpan(
                        text: b.nextTierName == null || b.pointsToNextTier == null ? A4MegCopy.a4_meg_hoyeste : A4MegCopy.a4_meg_avstand(b.pointsToNextTier!, b.nextTierName!),
                        style: megInter(11.5, FontWeight.w700, color: MegArkInk.sub, height: 1.35),
                      ),
                    ]),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 18, color: MegArkInk.muted),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        _PaperCard(
          key: const Key('hylla-maal'),
          padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(A4MegCopy.a4_hylla_maalet_ditt, style: megInter(9, FontWeight.w800, color: MegArkInk.faint, letterSpacing: 1.26)),
                        Text(
                          goal == null ? A4MegCopy.a4_hylla_sett_maal : (goal.reached ? A4MegCopy.a4_hylla_klar(goal.label) : A4MegCopy.a4_hylla_til(goal.remaining, goal.label)),
                          style: megInter(11.5, FontWeight.w800, color: MegArkInk.ink, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  if (goal != null) Text('${goal.percent}%', style: megInter(10.5, FontWeight.w800, color: BergenTokens.mint)),
                ],
              ),
              const SizedBox(height: 8),
              _Bar(fraction: goal == null ? 0 : goal.percent / 100, track: MegArkInk.ink.withValues(alpha: .1), colors: const [Color(0xFFF2C14E), Color(0xFFF26D3D)]),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_claims.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 9),
            child: Row(
              children: [
                Text(A4MegCopy.a4_hylla_mine, style: BergenTokens.display(15, weight: FontWeight.w800, color: Colors.white)),
                const SizedBox(width: 8),
                _MintCount('${_claims.length}'),
              ],
            ),
          ),
          SizedBox(
            height: 92,
            child: ListView.separated(
              key: const Key('hylla-mine'),
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.only(top: 2, bottom: 8),
              itemCount: _claims.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final c = _claims[i];
                final prize = byId[c.prizeId];
                return _ClaimTicket(claim: c, art: PrizeArt.of(slug: prize?.slug, name: c.prizeName ?? prize?.name ?? ''), how: _hvordan(prize?.type ?? ''));
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (b != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 8, 2, 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _TinyMedal(name: b.tierName),
                const SizedBox(width: 7),
                Expanded(child: Text(A4MegCopy.a4_hylla_aapent(b.tierName), style: BergenTokens.display(15, weight: FontWeight.w800, color: Colors.white))),
                Text(A4MegCopy.a4_hylla_klare(klare), key: const Key('hylla-klare'), style: megInter(10.5, FontWeight.w800, color: BergenTokens.mint)),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 2, 2, 12),
          child: Text(A4MegCopy.a4_hylla_intro, style: megInter(11, FontWeight.w600, color: Colors.white.withValues(alpha: .62), height: 1.45)),
        ),
        _Grid(
          children: [
            for (var i = 0; i < prizes.length; i++)
              _PrizeCard(
                key: Key('hylla-premie-${prizes[i].id}'),
                prize: prizes[i],
                art: PrizeArt.of(slug: prizes[i].slug, name: prizes[i].name),
                points: _points,
                isGoal: goal?.prizeId == prizes[i].id,
                bobDelay: Duration(milliseconds: (i % 4) * 400),
                onHent: () => _hent(prizes[i]),
                onGoal: () => _setGoal(prizes[i]),
              ),
            _VelgerCard(key: const Key('hylla-velger'), fromPoints: cheapest, onTap: _openVelger),
          ],
        ),
        if (previews.isNotEmpty && b?.nextTierName != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 20, 4, 2),
            child: Text(A4MegCopy.a4_hylla_laast(b!.nextTierName!), style: BergenTokens.display(15, weight: FontWeight.w800, color: Colors.white)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
            child: Text(A4MegCopy.a4_hylla_laast_sub(b.nextTierName!), style: megInter(11, FontWeight.w600, color: Colors.white.withValues(alpha: .62), height: 1.45)),
          ),
          for (final p in previews)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LockedRow(key: Key('hylla-laast-${p.id}'), preview: p, art: PrizeArt.of(slug: p.slug, name: p.name), onTap: () => MegSheets.nivaa(context, b, opens: previews)),
            ),
        ],
        const SizedBox(height: 6),
        _InfoCard(onTap: () => MegSheets.vilkaar(context)),
      ],
    );
  }
}

// ---------------------------------------------------------------- header

class _Hero extends StatelessWidget {
  const _Hero({required this.top, required this.points, required this.onBack});

  final double top;
  final int points;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('hylla-hero'),
      height: top + 150,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF7E93A3), Color(0xFF9FB2BD), Color(0xFF456E7C), Color(0xFF2F5462)], stops: [0, .48, .86, 1]),
            ),
          ),
          Positioned(left: 0, right: 0, top: top, height: 150, child: bergenSvg('meg_torg', fit: BoxFit.cover)),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFFF5F3EF).withValues(alpha: 0), const Color(0xFFF5F3EF).withValues(alpha: .45)]),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: top + 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  key: const Key('hylla-tilbake'),
                  onTap: onBack,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFEFF3F4)]),
                      border: Border.all(color: Colors.white.withValues(alpha: .95)),
                      boxShadow: const [BoxShadow(color: Color(0xFFD2DDE0), offset: Offset(0, 1.5)), BoxShadow(color: Color.fromRGBO(60, 90, 100, .3), offset: Offset(0, 3))],
                    ),
                    child: const Icon(Icons.chevron_left_rounded, color: Color(0xFF1B4A57), size: 24),
                  ),
                ),
                Container(
                  key: const Key('hylla-poeng'),
                  padding: const EdgeInsets.fromLTRB(6, 5, 14, 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFF4EFE2)]),
                    border: Border.all(color: Colors.white.withValues(alpha: .95)),
                    boxShadow: const [BoxShadow(color: Color(0xFFE2DACA), offset: Offset(0, 1.5)), BoxShadow(color: Color.fromRGBO(150, 120, 70, .3), offset: Offset(0, 3))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _Coin(size: 26),
                      const SizedBox(width: 7),
                      Text('${A4MegCopy.nf(points)} poeng', style: BergenTokens.display(14, weight: FontWeight.w800, color: MegArkInk.ink)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 18,
            bottom: 34,
            width: 62,
            child: _Bob(child: Image.asset('assets/images/aegil/voucher.png', width: 62, errorBuilder: (_, __, ___) => const SizedBox.shrink())),
          ),
        ],
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF27596A), Color(0xFF1E4F5C), Color(0xFF173E48)], stops: [0, .48, 1]),
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(center: const Alignment(-.72, -1), radius: .9, colors: [Colors.white.withValues(alpha: .22), Colors.white.withValues(alpha: 0)], stops: const [0, .6]),
                  ),
                ),
              ),
            ),
            const Positioned(top: 70, right: -70, width: 250, height: 250, child: _Glow(color: Color(0xFFF2C14E), alpha: .26)),
            const Positioned(top: 420, left: -80, width: 260, height: 260, child: _Glow(color: Color(0xFF3A7D8C), alpha: .2)),
            child,
          ],
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.alpha});

  final Color color;
  final double alpha;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0)], stops: const [0, .68]),
          ),
        ),
      );
}

// ---------------------------------------------------------------- small parts

/// The paper card (`linear-gradient(180deg,#FFFFFF,#F7F3EA)` on its ridge).
class _PaperCard extends StatelessWidget {
  const _PaperCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(12)});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFF7F3EA)]),
          border: Border.all(color: Colors.white.withValues(alpha: .95)),
          boxShadow: const [BoxShadow(color: Color(0xFFE4DCCB), offset: Offset(0, 1.5)), BoxShadow(color: Color.fromRGBO(150, 120, 70, .24), offset: Offset(0, 3.5))],
        ),
        child: child,
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.fraction, required this.track, required this.colors});

  final double fraction;
  final Color track;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 9,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: track, borderRadius: BorderRadius.circular(99)),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: fraction.clamp(0.0, 1.0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            gradient: LinearGradient(colors: colors),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: .6))),
          ),
        ),
      ),
    );
  }
}

class _MintCount extends StatelessWidget {
  const _MintCount(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: const Color(0xFF5CE0B8).withValues(alpha: .18),
          border: Border.all(color: const Color(0xFF5CE0B8).withValues(alpha: .35)),
        ),
        child: Text(text, style: megInter(10, FontWeight.w800, color: BergenTokens.mint)),
      );
}

class _Coin extends StatelessWidget {
  const _Coin({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(center: Alignment(-.32, -.44), colors: [Color(0xFFFBE8B4), Color(0xFFE0A32C), Color(0xFFB77F1C)], stops: [0, .62, 1]),
          boxShadow: [BoxShadow(color: Color.fromRGBO(120, 80, 10, .6), offset: Offset(0, 2), blurRadius: 4, spreadRadius: -1)],
        ),
        child: size >= 22 ? Center(child: MegMark(color: const Color(0xFF7C5A18), size: size * .55)) : null,
      );
}

class _TinyMedal extends StatelessWidget {
  const _TinyMedal({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final m = medalFor(name);
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(center: const Alignment(-.32, -.48), colors: m.gradient, stops: m.stops),
        border: Border.all(color: m.ring, width: 1.5),
      ),
      child: Center(child: MegMark(color: m.ink, size: 14)),
    );
  }
}

/// Gentle float for the 3D icons and Ægil (design `bob`); still under reduced motion.
class _Bob extends StatefulWidget {
  const _Bob({required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<_Bob> createState() => _BobState();
}

class _BobState extends State<_Bob> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 4400));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (BergenTokens.motion(context, const Duration(seconds: 1)) == Duration.zero) return;
    _c.value = (widget.delay.inMilliseconds / 4400) % 1;
    _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, child) {
          final t = _c.value;
          final y = -3 * (t < .5 ? Curves.easeInOut.transform(t * 2) : Curves.easeInOut.transform((1 - t) * 2));
          return Transform.translate(offset: Offset(0, y), child: child);
        },
        child: widget.child,
      );
}

// ---------------------------------------------------------------- Mine premier

class _ClaimTicket extends StatelessWidget {
  const _ClaimTicket({required this.claim, required this.art, required this.how});

  final PrizeClaim claim;
  final PrizeArt art;
  final String how;

  (String, Color, Color, Color) get _stamp {
    switch (claim.state) {
      case 'claimed':
      case 'applied':
        return ('KLAR', const Color.fromRGBO(63, 143, 95, .18), const Color(0xFF2E6B47), const Color.fromRGBO(63, 143, 95, .5));
      case 'shipped':
        return ('SENDT', const Color.fromRGBO(30, 79, 92, .14), const Color(0xFF1B4A57), const Color.fromRGBO(30, 79, 92, .4));
      case 'delivered':
        return ('LEVERT', const Color.fromRGBO(30, 79, 92, .14), const Color(0xFF1B4A57), const Color.fromRGBO(30, 79, 92, .4));
      case 'expired':
        return ('UTLØPT', const Color.fromRGBO(35, 32, 29, .06), const Color(0xFF8C847C), const Color.fromRGBO(35, 32, 29, .2));
      case 'cancelled':
        return ('ANGRET', const Color.fromRGBO(35, 32, 29, .06), const Color(0xFF8C847C), const Color.fromRGBO(35, 32, 29, .2));
      default:
        return ('BRUKT', const Color.fromRGBO(35, 32, 29, .06), const Color(0xFF8C847C), const Color.fromRGBO(35, 32, 29, .2));
    }
  }

  @override
  Widget build(BuildContext context) {
    final (tx, bg, fg, kant) = _stamp;
    final until = claim.expiresAt == null ? '' : ' · gjelder til ${MegSheets.pretty(claim.expiresAt!.toIso8601String())}';
    const notch = Color(0xFF1E4F5C);

    return Container(
      key: Key('hylla-krav-${claim.id}'),
      width: 214,
      padding: const EdgeInsets.fromLTRB(52, 12, 13, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFDFBF5), Color(0xFFF5F0E3)]),
        border: Border.all(color: Colors.white.withValues(alpha: .95)),
        boxShadow: const [BoxShadow(color: Color(0xFFE4DCCB), offset: Offset(0, 1.5)), BoxShadow(color: Color.fromRGBO(150, 120, 70, .26), offset: Offset(0, 3.5))],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: -12, top: -4, bottom: -4, child: CustomPaint(size: const Size(1.5, 60), painter: _DashV(color: const Color.fromRGBO(35, 32, 29, .22)))),
          Positioned(left: -17, top: -17, child: Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: notch))),
          Positioned(left: -17, bottom: -17, child: Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: notch))),
          Positioned(
            left: -44,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  gradient: art.gradient,
                  boxShadow: const [BoxShadow(color: Color.fromRGBO(35, 32, 29, .5), offset: Offset(0, 3), blurRadius: 6, spreadRadius: -3)],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(claim.prizeName ?? 'Premie', maxLines: 1, overflow: TextOverflow.ellipsis, style: megInter(12.5, FontWeight.w800, color: MegArkInk.ink, height: 1.2)),
                const SizedBox(height: 3),
                Text('$how$until', maxLines: 3, overflow: TextOverflow.ellipsis, style: megInter(10, FontWeight.w600, color: MegArkInk.muted, height: 1.35)),
              ],
            ),
          ),
          Positioned(
            right: -4,
            top: -3,
            child: Transform.rotate(
              angle: -5 * 3.14159 / 180,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6), border: Border.all(color: kant, width: 1.5)),
                child: Text(tx, style: megInter(9, FontWeight.w800, color: fg, letterSpacing: .36)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashV extends CustomPainter {
  const _DashV({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(0, (y + 3).clamp(0, size.height)), p);
      y += 6;
    }
  }

  @override
  bool shouldRepaint(_DashV old) => old.color != color;
}

// ---------------------------------------------------------------- the shelf

/// Two columns, 12px rows / 10px columns, cards of equal height per row.
class _Grid extends StatelessWidget {
  const _Grid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + 2 < children.length ? 12 : 0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: children[i]),
                const SizedBox(width: 10),
                Expanded(child: i + 1 < children.length ? children[i + 1] : const SizedBox.shrink()),
              ],
            ),
          ),
        ),
      );
    }
    return Column(key: const Key('hylla-grid'), children: rows);
  }
}

/// The card standing on its wooden lip.
class _ShelfCard extends StatelessWidget {
  const _ShelfCard({required this.image, required this.body, this.faded = false, this.onTap});

  final Widget image;
  final Widget body;
  final bool faded;
  final VoidCallback? onTap;

  /// `saturate(.35)`
  static const List<double> _saturate35 = [
    .54, .46, .05, 0, 0, //
    .14, .86, .05, 0, 0,
    .14, .46, .45, 0, 0,
    0, 0, 0, 1, 0,
  ];

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFF8F5EE)]),
        border: Border.all(color: Colors.white.withValues(alpha: .95)),
        boxShadow: const [BoxShadow(color: Color(0xFFE4DCCB), offset: Offset(0, 2)), BoxShadow(color: Color.fromRGBO(150, 120, 70, .28), offset: Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [SizedBox(height: 98, child: image), Expanded(child: body)]),
    );
    if (faded) {
      card = Opacity(opacity: .72, child: ColorFiltered(colorFilter: const ColorFilter.matrix(_saturate35), child: card));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: GestureDetector(onTap: onTap, child: card)),
        Container(
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFC9AE85), Color(0xFF8E7048)]),
            boxShadow: [BoxShadow(color: Color.fromRGBO(60, 40, 15, .5), offset: Offset(0, 3), blurRadius: 6, spreadRadius: -3)],
          ),
        ),
      ],
    );
  }
}

class _TileImage extends StatelessWidget {
  const _TileImage({required this.tint, this.icon, this.badge, this.goal = false, this.soldOut = false, this.shine = false, this.bobDelay = Duration.zero});

  final List<Color> tint;
  final Widget? icon;
  final String? badge;
  final bool goal;
  final bool soldOut;
  final bool shine;
  final Duration bobDelay;

  @override
  Widget build(BuildContext context) {
    final base = DecoratedBox(
      decoration: BoxDecoration(gradient: LinearGradient(begin: const Alignment(-.34, -.94), end: const Alignment(.34, .94), colors: tint)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(center: const Alignment(-.4, -.84), radius: 1.1, colors: [Colors.white.withValues(alpha: .6), Colors.white.withValues(alpha: 0)], stops: const [0, .62]),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 98 * .34,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.fromRGBO(40, 28, 12, 0), Color.fromRGBO(40, 28, 12, .16)]),
              ),
            ),
          ),
          if (icon != null) Center(child: _Bob(delay: bobDelay, child: icon!)),
          if (badge != null)
            Positioned(
              top: 7,
              left: 7,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 118),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white.withValues(alpha: .92),
                  boxShadow: const [BoxShadow(color: Color.fromRGBO(35, 32, 29, .35), offset: Offset(0, 2), blurRadius: 5, spreadRadius: -2)],
                ),
                child: Text(badge!, maxLines: 1, overflow: TextOverflow.ellipsis, style: megInter(8.5, FontWeight.w800, color: MegArkInk.ink)),
              ),
            ),
          if (goal)
            Positioned(
              top: 0,
              right: 10,
              child: ClipPath(
                clipper: _RibbonClip(),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(7, 5, 7, 8),
                  decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3F8F5F), Color(0xFF256B43)])),
                  child: Text('MÅL', style: megInter(8.5, FontWeight.w800, color: Colors.white, letterSpacing: .34)),
                ),
              ),
            ),
          if (soldOut)
            Center(
              child: Transform.rotate(
                angle: -9 * 3.14159 / 180,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDFCF9).withValues(alpha: .82),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color.fromRGBO(35, 32, 29, .4), width: 2),
                  ),
                  child: Text('UTSOLGT', style: megInter(9, FontWeight.w800, color: MegArkInk.sub, letterSpacing: .54)),
                ),
              ),
            ),
        ],
      ),
    );
    return shine ? MegShine(period: const Duration(milliseconds: 5500), delay: const Duration(milliseconds: 1200), opacity: .3, bandFraction: .25, child: base) : base;
  }
}

class _RibbonClip extends CustomClipper<Path> {
  @override
  Path getClip(Size s) => Path()
    ..moveTo(0, 0)
    ..lineTo(s.width, 0)
    ..lineTo(s.width, s.height)
    ..lineTo(s.width / 2, s.height * .82)
    ..lineTo(0, s.height)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Coin + "N poeng", shrinking instead of overflowing on narrow cards.
class _PriceRow extends StatelessWidget {
  const _PriceRow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const _Coin(size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(text, maxLines: 1, style: BergenTokens.display(14, weight: FontWeight.w800, color: MegArkInk.ink)),
            ),
          ),
        ],
      );
}

class _PrizeCard extends StatelessWidget {
  const _PrizeCard({super.key, required this.prize, required this.art, required this.points, required this.isGoal, required this.bobDelay, required this.onHent, required this.onGoal});

  final Prize prize;
  final PrizeArt art;
  final int points;
  final bool isGoal;
  final Duration bobDelay;
  final VoidCallback onHent;
  final VoidCallback onGoal;

  @override
  Widget build(BuildContext context) {
    final p = prize;
    final ute = !p.inStock;
    final raad = !ute && p.affordable;
    final laast = !ute && !raad;

    final (String tx, Gradient bg, Color fg, List<BoxShadow> sh) = ute
        ? (
            A4MegCopy.a4_hylla_utsolgt_mnd,
            const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF2EEE6), Color(0xFFE6E0D4)]),
            MegArkInk.faint,
            const <BoxShadow>[],
          )
        : raad
            ? (
                A4MegCopy.a4_hylla_hent,
                const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], stops: [0, .56, 1]),
                Colors.white,
                const [BoxShadow(color: Color(0xFFC4491A), offset: Offset(0, 1.5)), BoxShadow(color: Color.fromRGBO(120, 45, 15, .42), offset: Offset(0, 3.5))],
              )
            : (
                isGoal ? A4MegCopy.a4_hylla_er_maal_kn : A4MegCopy.a4_hylla_sett_som_maal,
                const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFEFF3F4)]),
                const Color(0xFF1B4A57),
                const [BoxShadow(color: Color(0xFFD2DDE0), offset: Offset(0, 1.5)), BoxShadow(color: Color.fromRGBO(60, 90, 100, .3), offset: Offset(0, 3))],
              );

    return _ShelfCard(
      faded: ute,
      image: _TileImage(
        tint: art.tint,
        icon: bergenSvg(art.icon, width: art.width, height: art.height),
        badge: p.partnerName,
        goal: isGoal,
        soldOut: ute,
        shine: raad,
        bobDelay: bobDelay,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(11, 10, 11, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 32),
              child: Text(p.name, style: BergenTokens.display(13, weight: FontWeight.w800, color: MegArkInk.ink, height: 1.2)),
            ),
            const SizedBox(height: 4),
            _PriceRow('${A4MegCopy.nf(p.pointPrice)} poeng'),
            const SizedBox(height: 4),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 28),
                child: Text(p.line ?? '', style: megInter(10.5, FontWeight.w600, color: MegArkInk.muted, height: 1.35)),
              ),
            ),
            if (laast) ...[
              const SizedBox(height: 2),
              Text(A4MegCopy.a4_hylla_igjen((p.pointPrice - points).clamp(0, 1 << 30)), style: megInter(10, FontWeight.w800, color: MegArkInk.sub)),
            ],
            const SizedBox(height: 9),
            GestureDetector(
              key: Key('hylla-kn-${p.id}'),
              onTap: onHent,
              child: Container(
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: bg,
                  border: Border.all(color: Colors.white.withValues(alpha: raad ? .5 : .95)),
                  boxShadow: sh,
                ),
                child: FittedBox(fit: BoxFit.scaleDown, child: Text(tx, style: megInter(12.5, FontWeight.w800, color: fg))),
              ),
            ),
            if (raad) ...[
              const SizedBox(height: 8),
              GestureDetector(
                key: Key('hylla-maal-${p.id}'),
                onTap: onGoal,
                child: Text(
                  isGoal ? A4MegCopy.a4_hylla_er_maal_kn : A4MegCopy.a4_hylla_sett_som_maal,
                  textAlign: TextAlign.center,
                  style: megInter(11, FontWeight.w800, color: isGoal ? MegArkInk.green : MegArkInk.teal),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Ægil velger" (design `velger`): Ægil on the deep teal tile; opens the picker.
class _VelgerCard extends StatelessWidget {
  const _VelgerCard({super.key, required this.onTap, this.fromPoints});

  final VoidCallback onTap;
  final int? fromPoints;

  @override
  Widget build(BuildContext context) {
    return _ShelfCard(
      onTap: onTap,
      image: Stack(
        fit: StackFit.expand,
        children: [
          const _TileImage(tint: PrizeArt.velgerTint, shine: true),
          Positioned(
            top: 6,
            left: 0,
            right: 0,
            child: Center(child: _Bob(child: Image.asset('assets/images/aegil/find.png', width: 76, errorBuilder: (_, __, ___) => const SizedBox.shrink()))),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(11, 10, 11, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 32),
              child: Text(A4MegCopy.a4_hylla_velger, style: BergenTokens.display(13, weight: FontWeight.w800, color: MegArkInk.ink, height: 1.2)),
            ),
            const SizedBox(height: 4),
            _PriceRow(fromPoints == null ? A4MegCopy.a4_hylla_velger_pris_tom : A4MegCopy.a4_hylla_fra(fromPoints!)),
            const SizedBox(height: 4),
            Expanded(child: Text(A4MegCopy.a4_hylla_velger_linje, style: megInter(10.5, FontWeight.w600, color: MegArkInk.muted, height: 1.35))),
            const SizedBox(height: 9),
            GestureDetector(
              onTap: onTap,
              child: Container(
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], stops: [0, .56, 1]),
                  border: Border.all(color: Colors.white.withValues(alpha: .5)),
                  boxShadow: const [BoxShadow(color: Color(0xFFC4491A), offset: Offset(0, 1.5)), BoxShadow(color: Color.fromRGBO(120, 45, 15, .42), offset: Offset(0, 3.5))],
                ),
                child: FittedBox(fit: BoxFit.scaleDown, child: Text(A4MegCopy.a4_hylla_la_aegil, style: megInter(12.5, FontWeight.w800, color: Colors.white))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- locked

class _LockedRow extends StatelessWidget {
  const _LockedRow({super.key, required this.preview, required this.art, required this.onTap});

  final PrizePreview preview;
  final PrizeArt art;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = preview;
    final m = medalFor(p.tierName);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFDFBF6), Color(0xFFF3EFE5)]),
          border: Border.all(color: Colors.white.withValues(alpha: .95)),
          boxShadow: const [BoxShadow(color: Color(0xFFE4DCCB), offset: Offset(0, 1.5)), BoxShadow(color: Color.fromRGBO(150, 120, 70, .2), offset: Offset(0, 3.5))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 78,
                height: 70,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(decoration: BoxDecoration(gradient: art.gradient)),
                    Center(
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Transform.scale(scale: .78, child: bergenSvg(art.icon, width: art.width, height: art.height)),
                      ),
                    ),
                    ColoredBox(color: const Color(0xFFFDFBF6).withValues(alpha: .28)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(center: const Alignment(-.32, -.48), colors: m.gradient, stops: m.stops)),
                        child: Center(child: MegMark(color: m.ink, size: 12)),
                      ),
                      const SizedBox(width: 7),
                      Expanded(child: Text(p.name, style: BergenTokens.display(13.5, weight: FontWeight.w800, color: MegArkInk.ink, height: 1.2))),
                    ],
                  ),
                  if (p.teaser != null && p.teaser!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(p.teaser!, style: megInter(10.5, FontWeight.w600, color: MegArkInk.muted, height: 1.4)),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('${A4MegCopy.nf(p.pointPrice)} poeng', style: megInter(12, FontWeight.w800, color: MegArkInk.teal)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: MegArkInk.ink.withValues(alpha: .07)),
                        child: Text(A4MegCopy.a4_hylla_krav(p.tierName, p.pointsToUnlock), style: megInter(9.5, FontWeight.w800, color: const Color(0xFF4E5A5E))),
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
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('hylla-60-dager'),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE7F0F2), Color(0xFFD5E4E8)]),
          border: Border.all(color: Colors.white.withValues(alpha: .9)),
          boxShadow: const [BoxShadow(color: Color(0xFFC2D5DA), offset: Offset(0, 1.5)), BoxShadow(color: Color.fromRGBO(60, 90, 100, .24), offset: Offset(0, 3))],
        ),
        child: Row(
          children: [
            bergenSvg('meg_varde3d', width: 24, height: 30),
            const SizedBox(width: 11),
            Expanded(child: Text(A4MegCopy.a4_hylla_60, style: megInter(11.5, FontWeight.w700, color: const Color(0xFF173E48), height: 1.45))),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF1E4F5C), size: 18),
          ],
        ),
      ),
    );
  }
}
