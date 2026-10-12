import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/feed/feed_post.dart';
import '../../../data/feed/feed_store_profile.dart';
import '../../../data/ops/butikk_models.dart';
import '../../../networking/feed/feed_cloudinary_config.dart';
import '../../../networking/feed/feed_repo.dart';
import '../../../networking/ops/ops_butikk_api.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/auth/launch/lf_widgets.dart';
import '../hjem/hjem_harness.dart';
import '../kit/bergen_cart.dart';
import '../kit/bergen_perf.dart';
import '../kit/bergen_routes.dart';
import '../kit/bergen_toast.dart';
import 'utforsk_copy.dart';

/// Butikkprofil (new Bergen L10189–10290, `bpVals` L16721): the store's
/// page in Ærend Feed — the header (back, name, the «bergensk» dot), the
/// logo in its ring (lit when the store posted today), the three numbers
/// (posts, followers, delivery minutes), name, «kategori · gate · avstand»,
/// bio, the open state and the `aerend.no/<slug>` link, «Følg» / «Se
/// menyen» / «Del», the tabs Innlegg / Tilbud / Fra Ærend, and the grid (the
/// first tile large, «NYTT» / «Tilbud» / «Ærend» tags, the price, the
/// likes, a play mark on videos). A tile opens the post viewer.
///
/// Data: the feed (`/v1/stores/:id`, its posts, follow / like) and the store
/// in Laravel (category, address, distance, hours, delivery time, menu for
/// the «Legg i kurven» name). Not shown, as the feed has no such data: the
/// bell (no «notify me about new posts»), «Følges av … du kjenner».
class ButikkProfilScreen extends StatefulWidget {
  const ButikkProfilScreen({super.key, this.storeId, this.repo, this.butikkApi});

  /// The store's id (feed and Laravel share it); else the route's `id`.
  final String? storeId;
  final FeedRepo? repo;
  final OpsButikkApi? butikkApi;

  @override
  State<ButikkProfilScreen> createState() => _ButikkProfilScreenState();
}

enum _Fane { innlegg, tilbud, aerend }

class _ButikkProfilScreenState extends State<ButikkProfilScreen> {
  FeedStoreProfile? _profil;
  List<FeedPost>? _poster;
  BergenStoreInfo? _butikk;
  bool _feil = false;
  bool _folgOpptatt = false;
  _Fane _fane = _Fane.innlegg;

  FeedRepo get _repo => widget.repo ?? FeedRepo();
  String get _id => widget.storeId ?? BergenRoutes.argsOf(context)['id'] ?? '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_profil == null && !_feil && _poster == null) unawaited(_last());
  }

  Future<void> _last() async {
    final id = _id;
    unawaited((widget.butikkApi ?? OpsButikkApi()).store(int.tryParse(id) ?? 0).then((b) {
      if (mounted && b != null) setState(() => _butikk = b);
    }));
    try {
      final p = await _repo.fetchStoreProfile(id);
      if (!mounted) return;
      setState(() => _profil = p);
      final side = await _repo.fetchStorePosts(id, limit: 30);
      if (mounted) setState(() => _poster = side.items);
      // Debug: `bpFane` / `bpPost` from the Hjem harness.
      if (kDebugMode && mounted) {
        final f = HjemHarness.bpFane, n = HjemHarness.bpPost;
        HjemHarness.bpFane = null;
        HjemHarness.bpPost = null;
        if (f != null) setState(() => _fane = _Fane.values.firstWhere((x) => x.name == f, orElse: () => _Fane.innlegg));
        if (n != null) {
          await Future<void>.delayed(const Duration(milliseconds: 900));
          if (mounted) unawaited(_apnePost(n));
        }
      }
    } catch (_) {
      if (mounted) setState(() => _feil = true);
    }
  }

  List<FeedPost> get _egne => [for (final p in _poster ?? const <FeedPost>[]) if (p.publisherType != 'aerend') p];
  List<FeedPost> get _liste => switch (_fane) {
    _Fane.innlegg => _egne,
    _Fane.tilbud => [for (final p in _egne) if (p.postType == 'tilbud') p],
    _Fane.aerend => [for (final p in _poster ?? const <FeedPost>[]) if (p.publisherType == 'aerend') p],
  };

  Future<void> _folg() async {
    final p = _profil;
    if (p == null || _folgOpptatt) return;
    final var0 = p.isFollowing;
    setState(() {
      _folgOpptatt = true;
      _profil = p.copyWith(isFollowing: !var0, followerCount: p.followerCount + (var0 ? -1 : 1));
    });
    try {
      final r = var0 ? await _repo.unfollowStore(_id) : await _repo.followStore(_id);
      if (!mounted) return;
      setState(() => _profil = _profil!.copyWith(isFollowing: r.isFollowing, followerCount: r.followerCount ?? _profil!.followerCount));
      showBergenToast(context, r.isFollowing ? UtforskCopy.a1_bp_folger_toast(p.name) : UtforskCopy.a1_bp_folger_ikke_toast(p.name));
    } catch (_) {
      if (!mounted) return;
      setState(() => _profil = p);
      showBergenToast(context, BergenRoutes.provIgjen);
    } finally {
      if (mounted) setState(() => _folgOpptatt = false);
    }
  }

  void _del(BuildContext anker) {
    final p = _profil;
    if (p == null) return;
    // iOS 26 refuses a share sheet without an anchor.
    final box = anker.findRenderObject() as RenderBox?;
    Share.share('https://aerend.no/${p.slug}', subject: p.name, sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size);
  }

  void _meny() => BergenRoutes.push<dynamic>(context, '/bergen/butikk/$_id', arguments: {'name': _profil?.name ?? ''});

  Future<void> _apnePost(int i) async {
    final liste = _liste;
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        settings: const RouteSettings(name: 'snurre-hide/bergen/butikkprofil/innlegg'),
        transitionDuration: BergenPerf.oneShot(context, 280),
        reverseTransitionDuration: BergenPerf.oneShot(context, 220),
        pageBuilder: (_, _, _) => _PostViser(
          profil: _profil!,
          butikk: _butikk,
          poster: liste,
          start: i,
          fane: _fane,
          repo: _repo,
          onLikt: (oppdatert) {
            if (!mounted) return;
            setState(() => _poster = [for (final p in _poster ?? const <FeedPost>[]) p.id == oppdatert.id ? oppdatert : p]);
          },
        ),
        transitionsBuilder: _bpInn,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _profil;
    return Scaffold(
      backgroundColor: const Color(0xFF12333D),
      body: LfFrame(
        child: DecoratedBox(
          // radial-gradient(90% 40% at 20% 0%, .12) over #22596A → #1A4652 → #12333D.
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF22596A), Color(0xFF1A4652), Color(0xFF12333D)], stops: [0, .38, 1]),
          ),
          child: Stack(
            children: [
              const Positioned(
                left: -80,
                top: -160,
                width: 420,
                height: 360,
                child: CssBox(bg: [CssRadial.closestSide([Color.fromRGBO(255, 255, 255, .12), Color.fromRGBO(255, 255, 255, 0)], stops: [0, .6])]),
              ),
              Column(
                children: [
                  _Hode(navn: p?.name ?? '', onTilbake: () => Navigator.of(context).maybePop()),
                  Expanded(
                    child: p == null
                        ? Center(
                            child: _feil
                                ? Text(BergenRoutes.provIgjen, style: inter(13, color: const Color.fromRGBO(255, 255, 255, .7)))
                                : const CircularProgressIndicator(color: Color(0xFF5CE0B8)),
                          )
                        : CustomScrollView(
                            key: const Key('a1_bp_scroll'),
                            slivers: [
                              SliverToBoxAdapter(child: _topp(p)),
                              SliverPersistentHeader(pinned: true, delegate: _FaneHode(fane: _fane, onVelg: (f) => setState(() => _fane = f))),
                              if (_fane == _Fane.aerend) SliverToBoxAdapter(child: _AerendInfo(navn: p.name)),
                              _rutenett(),
                              const SliverToBoxAdapter(child: SizedBox(height: 120)),
                            ],
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── The top: logo, numbers, name, lines, buttons (L10203–10222) ──────────

  Widget _topp(FeedStoreProfile p) {
    final b = _butikk;
    final idag = (_poster ?? const <FeedPost>[]).any((x) => _iDag(x.publishedAt));
    final egne = _egne.length;
    final linje = [
      if (b?.categoryName != null && b!.categoryName!.isNotEmpty) b.categoryName!,
      if (b?.address != null && b!.address!.isNotEmpty) b.address!.split(',').first.trim(),
      if (b?.distanceKm != null) UtforskCopy.a1_pose_avstand(b!.distanceKm!),
    ].join(' · ');
    final bio = (p.bio?.trim().isNotEmpty ?? false) ? p.bio!.trim() : ((p.description?.trim().isNotEmpty ?? false) ? p.description!.trim() : b?.description?.trim());
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _LogoRing(url: p.logoUrl ?? b?.logoUrl, navn: p.name, lys: idag),
              const SizedBox(width: 18),
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _Tall(n: '${_poster == null ? p.postCount : egne}', navn: UtforskCopy.a1_bp_innlegg)),
                    const SizedBox(width: 4),
                    Expanded(child: _Tall(key: const Key('a1_bp_folgere'), n: UtforskCopy.a1_bp_folgere_tall(p.followerCount), navn: UtforskCopy.a1_bp_folgere)),
                    if (b?.deliveryMinutes != null) ...[
                      const SizedBox(width: 4),
                      Expanded(child: _Tall(n: '${b!.deliveryMinutes}', navn: UtforskCopy.a1_bp_min_levering)),
                    ] else
                      const Expanded(child: SizedBox.shrink()),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(p.name, style: jakarta(15)),
          if (linje.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(linje, style: jakarta(12.5, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .62))),
          ],
          if (bio != null && bio.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(bio, style: inter(13.5, weight: FontWeight.w500, height: 1.45, color: const Color.fromRGBO(255, 255, 255, .92))),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (b != null) _ApenChip(butikk: b),
              Builder(
                builder: (anker) => GestureDetector(
                  onTap: () => _del(anker),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.string(
                        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#7FF0CB" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"><path d="M10 14a4.5 4.5 0 0 0 6.4 0l3-3a4.5 4.5 0 0 0-6.4-6.4l-1 1 M14 10a4.5 4.5 0 0 0-6.4 0l-3 3a4.5 4.5 0 0 0 6.4 6.4l1-1"/></svg>',
                        width: 13,
                        height: 13,
                      ),
                      const SizedBox(width: 5),
                      Text('aerend.no/${p.slug}', style: jakarta(12.5, color: const Color(0xFF7FF0CB))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 12,
                child: LfPress(
                  key: const Key('a1_bp_folg'),
                  dy: 2,
                  ms: 120,
                  onTap: _folg,
                  child: _Knapp(
                    oransje: !p.isFollowing,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(p.isFollowing ? UtforskCopy.a1_bp_folger : UtforskCopy.a1_bp_folg, style: jakarta(14)),
                        if (p.isFollowing) ...[
                          const SizedBox(width: 6),
                          SvgPicture.string(
                            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12.5l4.5 4.5L19 7.5"/></svg>',
                            width: 13,
                            height: 13,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 12,
                child: LfPress(
                  key: const Key('a1_bp_meny'),
                  dy: 2,
                  ms: 120,
                  onTap: _meny,
                  child: _Knapp(child: Center(child: Text(UtforskCopy.a1_bp_se_menyen, style: jakarta(14)))),
                ),
              ),
              const SizedBox(width: 8),
              Builder(
                builder: (anker) => LfPress(
                  key: const Key('a1_bp_del'),
                  dy: 2,
                  ms: 120,
                  onTap: () => _del(anker),
                  child: SizedBox(
                    width: 42,
                    child: _Knapp(
                      child: Center(
                        child: SvgPicture.string(
                          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 15V4 M8 8l4-4 4 4 M5 13v6h14v-6"/></svg>',
                          width: 17,
                          height: 17,
                        ),
                      ),
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

  // ── The grid (L10230–10280) ──────────────────────────────────────────────

  Widget _rutenett() {
    final poster = _poster;
    if (poster == null) {
      return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: Color(0xFF5CE0B8)))));
    }
    final liste = _liste;
    final navn = _profil!.name;
    if (liste.isEmpty) {
      final (t, u) = switch (_fane) {
        _Fane.tilbud => (UtforskCopy.a1_bp_tom_tilbud, UtforskCopy.a1_bp_tom_tilbud_under(navn)),
        _Fane.aerend => (UtforskCopy.a1_bp_tom_aerend(navn), UtforskCopy.a1_bp_tom_aerend_under),
        _Fane.innlegg => (UtforskCopy.a1_bp_tom_innlegg, UtforskCopy.a1_bp_tom_innlegg_under(navn)),
      };
      return SliverToBoxAdapter(
        child: Padding(
          key: const Key('a1_bp_tom'),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
          child: Column(
            children: [
              Text(t, textAlign: TextAlign.center, style: jakarta(15)),
              const SizedBox(height: 4),
              Text(u, textAlign: TextAlign.center, style: inter(13, height: 1.45, color: const Color.fromRGBO(255, 255, 255, .7))),
            ],
          ),
        ),
      );
    }
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: LayoutBuilder(
          builder: (context, box) {
            const gap = 6.0;
            final w = (box.maxWidth - 2 * gap) / 3;
            final stor = liste.length >= 3;
            // CSS grid: the large tile spans columns 1–2 and rows 1–2; the
            // rest flow into the free cells in reading order.
            final plass = <Rect>[];
            if (stor) {
              plass.add(Rect.fromLTWH(0, 0, 2 * w + gap, 2 * w + gap));
              plass.add(Rect.fromLTWH(2 * (w + gap), 0, w, w));
              plass.add(Rect.fromLTWH(2 * (w + gap), w + gap, w, w));
              for (var i = 3; i < liste.length; i++) {
                final k = i - 3;
                plass.add(Rect.fromLTWH((k % 3) * (w + gap), (2 + k ~/ 3) * (w + gap), w, w));
              }
            } else {
              for (var i = 0; i < liste.length; i++) {
                plass.add(Rect.fromLTWH((i % 3) * (w + gap), (i ~/ 3) * (w + gap), w, w));
              }
            }
            final h = plass.map((r) => r.bottom).reduce(math.max);
            return SizedBox(
              height: h,
              child: Stack(
                children: [
                  for (var i = 0; i < liste.length; i++)
                    Positioned.fromRect(
                      rect: plass[i],
                      child: _Flis(key: ValueKey('a1_bp_flis_${liste[i].id}'), post: liste[i], i: i, stor: stor && i == 0, onTap: () => _apnePost(i)),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// `bpInn .32s cubic-bezier(.2,.9,.3,1)`: in from 28 px to the right, fading.
Widget _bpInn(BuildContext context, Animation<double> a, Animation<double> b, Widget child) {
  final c = CurvedAnimation(parent: a, curve: const Cubic(.2, .9, .3, 1));
  return FadeTransition(
    opacity: c,
    child: AnimatedBuilder(animation: c, child: child, builder: (context, child) => Transform.translate(offset: Offset(28 * (1 - c.value), 0), child: child)),
  );
}

/// A route for the profile with its own entrance (registered in
/// `bergen_routes_agil1.dart` as `/bergen/butikkprofil`).
Route<dynamic> butikkProfilRute(RouteSettings settings, WidgetBuilder builder) => PageRouteBuilder<dynamic>(
  settings: settings,
  transitionDuration: const Duration(milliseconds: 320),
  reverseTransitionDuration: const Duration(milliseconds: 240),
  pageBuilder: (context, _, _) => builder(context),
  transitionsBuilder: _bpInn,
);

bool _iDag(DateTime? d) {
  if (d == null) return false;
  final l = d.toLocal(), n = DateTime.now();
  return l.year == n.year && l.month == n.month && l.day == n.day;
}

/// «i dag 14:05», «i går 14:00», «fre 29.08».
String _dato(DateTime? d) {
  if (d == null) return '';
  final l = d.toLocal(), n = DateTime.now();
  String hhmm() => '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  if (_iDag(l)) return UtforskCopy.a1_bp_i_dag(hhmm());
  final igar = n.subtract(const Duration(days: 1));
  if (l.year == igar.year && l.month == igar.month && l.day == igar.day) return UtforskCopy.a1_bp_i_gar(hhmm());
  return '${UtforskCopy.a1_bp_ukedag(l.weekday)} ${l.day.toString().padLeft(2, '0')}.${l.month.toString().padLeft(2, '0')}';
}

String _bildeUrl(FeedPost p) => p.media.isVideo ? p.media.posterUrl(FeedCloudinaryConfig.cloudName) : p.media.cloudinaryUrl(FeedCloudinaryConfig.cloudName);

// ── Pieces ─────────────────────────────────────────────────────────────────

/// The sticky header: back key, the store's name with the «bergensk» dot.
class _Hode extends StatelessWidget {
  const _Hode({required this.navn, required this.onTilbake, this.over});

  final String navn;
  final VoidCallback onTilbake;

  /// The post viewer's kicker over the name («INNLEGG» …).
  final String? over;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return CssBox(
      bg: const [CssLinear(180, [Color.fromRGBO(22, 63, 74, .96), Color.fromRGBO(22, 63, 74, .82)])],
      padding: EdgeInsets.fromLTRB(12, top + 14, 12, 10),
      child: DecoratedBox(
        decoration: const BoxDecoration(),
        child: Row(
          children: [
            LfPress(key: const Key('a1_bp_tilbake'), scale: .94, ms: 140, onTap: onTilbake, child: const _GlassKvadrat(d: 'M15 6l-6 6 6 6', size: 20, stroke: 2.6)),
            const SizedBox(width: 8),
            Expanded(
              child: over != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(over!, style: jakarta(11, em: .08, color: const Color.fromRGBO(255, 255, 255, .6))),
                        Text(navn, maxLines: 1, overflow: TextOverflow.ellipsis, style: jakarta(15.5)),
                      ],
                    )
                  : Row(
                      children: [
                        Flexible(child: Text(navn, maxLines: 1, overflow: TextOverflow.ellipsis, style: jakarta(17, em: -.02))),
                        if (navn.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF2C14E), boxShadow: [BoxShadow(color: Color.fromRGBO(242, 193, 78, .9), blurRadius: 3)]),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The 40 px glass key (back) — `rgba(255,255,255,.2 → .07)`, 14 px corners.
class _GlassKvadrat extends StatelessWidget {
  const _GlassKvadrat({required this.d, required this.size, required this.stroke});

  final String d;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) => CssBox(
    width: 40,
    height: 40,
    radius: BorderRadius.circular(14),
    bg: const [CssLinear(180, [Color.fromRGBO(255, 255, 255, .2), Color.fromRGBO(255, 255, 255, .07)])],
    shadows: const [
      CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .32)),
      CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .12)),
      CssShadow(0, 2.5, 0, 0, Color.fromRGBO(6, 22, 30, .5)),
      CssShadow(0, 8, 12, -8, Color.fromRGBO(3, 16, 24, .8)),
    ],
    child: Center(
      child: SvgPicture.string(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="$stroke" stroke-linecap="round" stroke-linejoin="round"><path d="$d"/></svg>',
        width: size,
        height: size,
      ),
    ),
  );
}

/// The logo (88 px): a 3 px ring — mint when the store posted today — and a
/// 3 px teal border inside it.
class _LogoRing extends StatelessWidget {
  const _LogoRing({required this.url, required this.navn, required this.lys});

  final String? url;
  final String navn;
  final bool lys;

  @override
  Widget build(BuildContext context) {
    final init = navn.trim().isEmpty ? '' : navn.trim()[0].toUpperCase();
    return Container(
      width: 88,
      height: 88,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: lys ? null : const Color.fromRGBO(255, 255, 255, .24),
        gradient: lys ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFB4F9E2), Color(0xFF5CE0B8), Color(0xFF2A6272)], stops: [0, .45, 1]) : null,
      ),
      child: Container(
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: const Color(0xFF1E4F5C), width: 3)),
        clipBehavior: Clip.antiAlias,
        child: url != null && url!.isNotEmpty
            ? CachedNetworkImage(imageUrl: url!, fit: BoxFit.cover, memCacheWidth: 240, errorWidget: (_, _, _) => Center(child: Text(init, style: jakarta(28, color: const Color(0xFF1E4F5C)))))
            : Center(child: Text(init, style: jakarta(28, color: const Color(0xFF1E4F5C)))),
      ),
    );
  }
}

class _Tall extends StatelessWidget {
  const _Tall({super.key, required this.n, required this.navn});

  final String n;
  final String navn;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(n, maxLines: 1, softWrap: false, style: jakarta(18, em: -.02, height: 1.1).copyWith(fontFeatures: const [ui.FontFeature.tabularFigures()])),
      const SizedBox(height: 2),
      Text(navn, maxLines: 1, softWrap: false, overflow: TextOverflow.fade, style: jakarta(12, weight: FontWeight.w600, color: const Color.fromRGBO(255, 255, 255, .72))),
    ],
  );
}

/// «Åpen · stenger 22» / «Stengt · åpner 11» with its dot.
class _ApenChip extends StatelessWidget {
  const _ApenChip({required this.butikk});

  final BergenStoreInfo butikk;

  @override
  Widget build(BuildContext context) {
    String kl(String? t) {
      if (t == null || t.length < 5) return t ?? '';
      final hhmm = t.substring(0, 5);
      return hhmm.endsWith(':00') ? hhmm.substring(0, 2).replaceFirst(RegExp('^0'), '') : hhmm;
    }

    final apen = butikk.open;
    final tekst = apen
        ? ((butikk.closeTime ?? '').isEmpty ? UtforskCopy.a1_bp_apen : UtforskCopy.a1_bp_apen_til(kl(butikk.closeTime)))
        : ((butikk.openTime ?? '').isEmpty ? UtforskCopy.a1_bp_stengt : UtforskCopy.a1_bp_stengt_til(kl(butikk.openTime)));
    final dot = apen ? const Color(0xFF5CE0B8) : const Color.fromRGBO(255, 255, 255, .45);
    return CssBox(
      key: const Key('a1_bp_apen'),
      height: 26,
      radius: BorderRadius.circular(999),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      bg: const [CssSolid(Color.fromRGBO(255, 255, 255, .1))],
      shadows: const [CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .14))],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: dot, boxShadow: [BoxShadow(color: dot, blurRadius: 3)])),
          const SizedBox(width: 6),
          Text(tekst, style: jakarta(12)),
        ],
      ),
    );
  }
}

/// «Følg» (orange 3D) / «Følger» and «Se menyen» / «Del» (glass), 42 px.
class _Knapp extends StatelessWidget {
  const _Knapp({required this.child, this.oransje = false});

  final Widget child;
  final bool oransje;

  @override
  Widget build(BuildContext context) => CssBox(
    height: 42,
    radius: BorderRadius.circular(13),
    bg: [
      oransje
          ? const CssLinear(180, [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], [0, .56, 1])
          : const CssLinear(180, [Color.fromRGBO(255, 255, 255, .2), Color.fromRGBO(255, 255, 255, .07)]),
    ],
    shadows: oransje
        ? const [
            CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .45)),
            CssShadow(0, 3, 0, 0, Color.fromRGBO(160, 60, 20, .6)),
            CssShadow(0, 10, 18, -8, Color.fromRGBO(242, 109, 61, .7)),
          ]
        : const [
            CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .32)),
            CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .12)),
            CssShadow(0, 2.5, 0, 0, Color.fromRGBO(6, 22, 30, .5)),
            CssShadow(0, 8, 12, -8, Color.fromRGBO(3, 16, 24, .8)),
          ],
    child: child,
  );
}

/// The tabs (sticky): icon + name, the active one white with a mint bar.
class _FaneHode extends SliverPersistentHeaderDelegate {
  _FaneHode({required this.fane, required this.onVelg});

  final _Fane fane;
  final ValueChanged<_Fane> onVelg;

  static const _faner = [
    (_Fane.innlegg, 'M4 4h7v7H4z M13 4h7v7h-7z M4 13h7v7H4z M13 13h7v7h-7z'),
    (_Fane.tilbud, 'M3.5 12.5V4h8.5l8.5 8.5-8 8z M8 8.5v.01'),
    (_Fane.aerend, 'M3 10.5 19 4v13L3 13.5z M7 14v5'),
  ];

  @override
  double get minExtent => 62;
  @override
  double get maxExtent => 62;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: CssBox(
      bg: const [CssSolid(Color.fromRGBO(22, 63, 74, .9))],
      child: DecoratedBox(
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color.fromRGBO(255, 255, 255, .1)))),
        child: Row(
          children: [
            for (final (f, d) in _faner)
              Expanded(
                child: GestureDetector(
                  key: Key('a1_bp_fane_${f.name}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onVelg(f),
                  child: SizedBox(
                    height: 46,
                    child: Stack(
                      children: [
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.string(
                                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#${f == fane ? 'FFFFFF' : '8CA4AB'}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="$d"/></svg>',
                                width: 16,
                                height: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                switch (f) {
                                  _Fane.innlegg => UtforskCopy.a1_bp_fane_innlegg,
                                  _Fane.tilbud => UtforskCopy.a1_bp_fane_tilbud,
                                  _Fane.aerend => UtforskCopy.a1_bp_fane_aerend,
                                },
                                style: jakarta(12.5, color: f == fane ? Colors.white : const Color.fromRGBO(255, 255, 255, .55)),
                              ),
                            ],
                          ),
                        ),
                        if (f == fane)
                          const Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: FractionallySizedBox(
                              widthFactor: .64,
                              child: SizedBox(
                                height: 3,
                                child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFF5CE0B8), borderRadius: BorderRadius.vertical(top: Radius.circular(2)))),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  @override
  bool shouldRebuild(covariant _FaneHode old) => old.fane != fane;
}

/// «Ærend skriver om butikker i nærheten. {navn} ser innleggene og kan
/// skjule dem.» (the Fra Ærend tab).
class _AerendInfo extends StatelessWidget {
  const _AerendInfo({required this.navn});

  final String navn;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
    child: CssBox(
      radius: BorderRadius.circular(16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      bg: const [CssSolid(Color.fromRGBO(255, 255, 255, .07))],
      shadows: const [CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .12))],
      child: Row(
        children: [
          CssBox(
            width: 28,
            height: 28,
            radius: BorderRadius.circular(9),
            bg: const [CssSolid(Color(0xFF1E4F5C))],
            child: Center(child: Text('Æ', style: jakarta(13, color: const Color(0xFFF5F3EF)))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(UtforskCopy.a1_bp_aerend_info(navn), style: inter(12, height: 1.4, color: const Color.fromRGBO(255, 255, 255, .78)))),
        ],
      ),
    ),
  );
}

/// One tile of the grid: the picture moving slowly (`bpKB`), or the text
/// tile, the scrim, the large tile's sweep (`bpSveip 5.5s`), the tags, the
/// play mark (`bpPlayRing 2.2s`), the large title, the price and the likes.
/// Enters with `bpFlisInn .6s` (80 ms + 70 ms per tile).
class _Flis extends StatelessWidget {
  const _Flis({super.key, required this.post, required this.i, required this.stor, required this.onTap});

  final FeedPost post;
  final int i;
  final bool stor;
  final VoidCallback onTap;

  static const _pos = [Alignment(0, -.16), Alignment(-.56, 0), Alignment(.6, -.1), Alignment(-.24, .44), Alignment(.28, -.4), Alignment(0, .24)];
  static const _ori = [Alignment(-.4, -.4), Alignment(.4, -.2), Alignment(-.2, .4), Alignment(.2, .2), Alignment(-.6, 0), Alignment(.6, -.4)];

  @override
  Widget build(BuildContext context) {
    final p = post;
    final bilde = p.hasMedia;
    final ny = _iDag(p.publishedAt);
    final tilbud = p.postType == 'tilbud';
    final aerend = p.publisherType == 'aerend';
    final video = p.media.isVideo && bilde;
    final r = stor ? 20.0 : 14.0;
    final tittel = (p.headline?.trim().isNotEmpty ?? false) ? p.headline!.trim() : p.caption.trim();
    final kbDur = (13 + (i % 3) * 3) * 1000.0;
    final kbDelay = -i * 2300.0;
    final harTag = ny || tilbud || aerend;
    return LfOnce(
      ms: 600 + 80 + i * 70.0,
      builder: (context, t, child) {
        final e = const Cubic(.2, .9, .3, 1).transform(((t - 80 - i * 70) / 600).clamp(0.0, 1.0));
        return Opacity(opacity: e, child: Transform.translate(offset: Offset(0, 16 * (1 - e)), child: Transform.scale(scale: .92 + .08 * e, child: child)));
      },
      child: LfPress(
        scale: .965,
        ms: 160,
        onTap: onTap,
        child: CssBox(
          radius: BorderRadius.circular(r),
          clip: true,
          bg: const [CssLinear(165, [Color(0xFFF6E7C8), Color(0xFFD9A254)])],
          shadows: const [
            CssShadow(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .14)),
            CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .2)),
            CssShadow(0, 16, 24, -16, Color.fromRGBO(0, 10, 16, .95)),
          ],
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (bilde)
                Positioned(
                  left: -3,
                  top: -3,
                  right: -3,
                  bottom: -3,
                  child: LfLoop(
                    builder: (context, ms, child) {
                      // bpKB alternate: scale 1.04 → 1.17, translate −2.5 % / −2 %.
                      final per = (ms - kbDelay) / kbDur;
                      final k = per.floor().isEven ? per - per.floor() : 1 - (per - per.floor());
                      final e = cssEaseInOut.transform(k);
                      return LayoutBuilder(
                        builder: (context, b) => Transform(
                          alignment: _ori[i % _ori.length],
                          transform: Matrix4.identity()
                            ..translateByDouble(-.025 * b.maxWidth * e, -.02 * b.maxHeight * e, 0, 1)
                            ..scaleByDouble(1.04 + .13 * e, 1.04 + .13 * e, 1, 1),
                          child: child,
                        ),
                      );
                    },
                    child: CachedNetworkImage(
                      imageUrl: _bildeUrl(p),
                      fit: BoxFit.cover,
                      alignment: _pos[i % _pos.length],
                      memCacheWidth: stor ? BergenPerf.decodeWidth : (BergenPerf.decodeWidth ~/ 2),
                      errorWidget: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                )
              else ...[
                const CssBox(bg: [CssRadial([Color.fromRGBO(255, 255, 255, .55), Color.fromRGBO(255, 255, 255, 0)], stops: [0, .6], rx: .9, ry: .7, cx: .2, cy: .1)]),
                Positioned(
                  left: 10,
                  right: 10,
                  top: harTag ? (stor ? 42 : 36) : 10,
                  child: Text(tittel, maxLines: stor ? 4 : 3, overflow: TextOverflow.ellipsis, style: jakarta(stor ? 22 : 12.5, em: -.01, height: 1.18, color: const Color(0xFF23201D))),
                ),
              ],
              Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: stor ? .55 : .48,
                  widthFactor: 1,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.fromRGBO(8, 20, 26, 0), Color.fromRGBO(8, 20, 26, .82)])),
                  ),
                ),
              ),
              if (stor) const _Sveip(),
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                // A flex row the tile clips (overflow:hidden), as in the design.
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Row(
                    children: [
                      if (aerend) ...[const _AerendTag(), const SizedBox(width: 5)],
                      if (ny) ...[const _NyTag(), const SizedBox(width: 5)],
                      if (tilbud) const _TilbudTag(),
                    ],
                  ),
                ),
              ),
              if (video)
                Align(
                  alignment: Alignment(0, bilde ? -.08 : (stor ? .2 : .28)),
                  child: _Play(d: stor ? 56 : 30),
                ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (stor && bilde) ...[
                      Text(
                        tittel,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: jakarta(17, em: -.02, height: 1.15, shadows: const [Shadow(color: Color.fromRGBO(0, 10, 16, .6), blurRadius: 10, offset: Offset(0, 2))]),
                      ),
                      const SizedBox(height: 5),
                    ],
                    Row(
                      children: [
                        if (p.priceOre != null)
                          CssBox(
                            height: stor ? 28 : 22,
                            radius: BorderRadius.circular(999),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            bg: const [CssSolid(Color.fromRGBO(255, 255, 255, .18))],
                            shadows: const [CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .3))],
                            child: Center(
                              child: Text(
                                UtforskCopy.a1_utforsk_pose_price(p.priceOre! ~/ 100),
                                softWrap: false,
                                style: jakarta(stor ? 13.5 : 11.5).copyWith(fontFeatures: const [ui.FontFeature.tabularFigures()]),
                              ),
                            ),
                          ),
                        const Spacer(),
                        SvgPicture.string(
                          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M12 20.6l-7.4-7.3a5 5 0 0 1 7-7.1l.4.4.4-.4a5 5 0 0 1 7 7.1z" fill="${p.isLiked ? '#FF7A4D' : 'none'}" stroke="#FFFFFF" stroke-width="2.4" stroke-linejoin="round"/></svg>',
                          width: 11,
                          height: 11,
                        ),
                        const SizedBox(width: 3),
                        Text('${p.likeCount}', style: jakarta(11, shadows: const [Shadow(color: Color.fromRGBO(0, 10, 16, .7), blurRadius: 6, offset: Offset(0, 1))]).copyWith(fontFeatures: const [ui.FontFeature.tabularFigures()])),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `bpSveip 5.5s 1.4s`: a light band crossing the large tile now and then.
class _Sveip extends StatelessWidget {
  const _Sveip();

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: LayoutBuilder(
      builder: (context, b) => LfLoop(
        builder: (context, ms, child) {
          final p = kfLoop(ms, 1400, 5500);
          final x = p == null ? -1.3 : kf(p, const [0, .58, 1], const [-1.3, -1.3, 3.2], cssEaseInOut);
          return Transform.translate(offset: Offset(x * .45 * b.maxWidth, 0), child: Transform(transform: Matrix4.skewX(-12 * math.pi / 180), child: child));
        },
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: .45,
            heightFactor: 1,
            child: const DecoratedBox(
              decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment(-1, -.2), end: Alignment(1, .2), colors: [Color.fromRGBO(255, 255, 255, 0), Color.fromRGBO(255, 255, 255, .28), Color.fromRGBO(255, 255, 255, 0)])),
            ),
          ),
        ),
      ),
    ),
  );
}

class _NyTag extends StatelessWidget {
  const _NyTag();

  @override
  Widget build(BuildContext context) => LfLoop(
    // bpNyPuls 2.6s: the glow breathing 6 → 16 px.
    builder: (context, ms, child) {
      final k = kf((ms % 2600) / 2600, const [0, .5, 1], const [0, 1, 0], cssEaseInOut);
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: [BoxShadow(color: Color.fromRGBO(92, 224, 184, .45 + .5 * k), blurRadius: 3 + 5 * k)],
        ),
        child: child,
      );
    },
    child: CssBox(
      height: 22,
      radius: BorderRadius.circular(999),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      bg: const [CssLinear(180, [Color(0xFFB4F9E2), Color(0xFF5CE0B8)])],
      child: Center(child: Text(UtforskCopy.a1_bp_nytt, style: jakarta(10.5, em: .06, color: const Color(0xFF0F2B33)))),
    ),
  );
}

class _TilbudTag extends StatelessWidget {
  const _TilbudTag();

  @override
  Widget build(BuildContext context) => CssBox(
    height: 22,
    radius: BorderRadius.circular(999),
    padding: const EdgeInsets.fromLTRB(6, 0, 8, 0),
    bg: const [CssLinear(180, [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], [0, .56, 1])],
    shadows: const [
      CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .4)),
      CssShadow(0, 4, 10, -4, Color.fromRGBO(242, 109, 61, .9)),
    ],
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.string('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#FFFFFF"><path d="M3.5 12.5V4h8.5l8.5 8.5-8 8z"/></svg>', width: 10, height: 10),
        const SizedBox(width: 4),
        Text(UtforskCopy.a1_bp_fane_tilbud, style: jakarta(10.5)),
      ],
    ),
  );
}

class _AerendTag extends StatelessWidget {
  const _AerendTag();

  @override
  Widget build(BuildContext context) => CssBox(
    height: 22,
    radius: BorderRadius.circular(999),
    padding: const EdgeInsets.fromLTRB(6, 0, 8, 0),
    bg: const [CssSolid(Color.fromRGBO(15, 40, 48, .78))],
    shadows: const [CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .28))],
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Æ', style: jakarta(10, color: Colors.white)),
        const SizedBox(width: 5),
        Text('Ærend', style: jakarta(10.5)),
      ],
    ),
  );
}

/// The play mark: a glass disc with a ring pulsing out (`bpPlayRing 2.2s`).
class _Play extends StatelessWidget {
  const _Play({required this.d});

  final double d;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: d,
    height: d,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: LfLoop(
            builder: (context, ms, child) {
              final p = const Cubic(.2, .6, .3, 1).transform((ms % 2200) / 2200);
              return Opacity(opacity: (.85 * (1 - p)).clamp(0.0, 1.0), child: Transform.scale(scale: 1 + .7 * p, child: child));
            },
            child: const DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.fromBorderSide(BorderSide(color: Color.fromRGBO(255, 255, 255, .8), width: 2)))),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color.fromRGBO(10, 26, 34, .42),
              border: Border.all(color: const Color.fromRGBO(255, 255, 255, .75), width: 1.5),
            ),
            child: Padding(
              padding: EdgeInsets.only(left: d * .08),
              child: Center(child: SvgPicture.string('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#FFFFFF"><path d="M7 4.5v15l12.5-7.5z"/></svg>', width: d * .4, height: d * .4)),
            ),
          ),
        ),
      ],
    ),
  );
}

// ── The post viewer (L10285–10320) ───────────────────────────────────────────

/// The tab's posts as large cards, opened at the one tapped: the 300 px
/// picture with the store row and the type chip, the like and share keys,
/// the price, the title, the text, and «Legg i kurven · {vare}» (a real cart
/// line when the post sells a product) or «Se menyen».
class _PostViser extends StatefulWidget {
  const _PostViser({
    required this.profil,
    required this.butikk,
    required this.poster,
    required this.start,
    required this.fane,
    required this.repo,
    required this.onLikt,
  });

  final FeedStoreProfile profil;
  final BergenStoreInfo? butikk;
  final List<FeedPost> poster;
  final int start;
  final _Fane fane;
  final FeedRepo repo;
  final ValueChanged<FeedPost> onLikt;

  @override
  State<_PostViser> createState() => _PostViserState();
}

class _PostViserState extends State<_PostViser> {
  late List<FeedPost> _poster = widget.poster;
  final _start = GlobalKey();
  String? _puls;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = _start.currentContext;
      if (c != null) Scrollable.ensureVisible(c, alignment: 0);
    });
  }

  Future<void> _lik(FeedPost p) async {
    final paa = !p.isLiked;
    final ny = FeedPost(
      id: p.id,
      store: p.store,
      caption: p.caption,
      locationName: p.locationName,
      media: p.media,
      likeCount: p.likeCount + (paa ? 1 : -1),
      commentCount: p.commentCount,
      isLiked: paa,
      publishedAt: p.publishedAt,
      publisherType: p.publisherType,
      headline: p.headline,
      postType: p.postType,
      priceOre: p.priceOre,
      storeProductId: p.storeProductId,
    );
    setState(() {
      _poster = [for (final x in _poster) x.id == p.id ? ny : x];
      _puls = paa ? p.id : null;
    });
    widget.onLikt(ny);
    try {
      if (paa) {
        await widget.repo.likePost(p.id);
      } else {
        await widget.repo.unlikePost(p.id);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _poster = [for (final x in _poster) x.id == p.id ? p : x]);
      widget.onLikt(p);
      showBergenToast(context, BergenRoutes.provIgjen);
    }
  }

  String? _vare(FeedPost p) {
    final id = int.tryParse(p.storeProductId ?? '');
    if (id == null) return null;
    for (final m in widget.butikk?.allItems ?? const <BergenMenuItem>[]) {
      if (m.id == id) return m.name;
    }
    return null;
  }

  Future<void> _cta(FeedPost p) async {
    final id = int.tryParse(p.storeProductId ?? '');
    final butikk = int.tryParse(widget.profil.id) ?? 0;
    if (id != null) {
      await BergenCart.add(context, storeId: butikk, productId: id);
      return;
    }
    await BergenRoutes.push<dynamic>(context, '/bergen/butikk/$butikk', arguments: {'name': widget.profil.name});
  }

  void _del(BuildContext anker, FeedPost p) {
    final box = anker.findRenderObject() as RenderBox?;
    Share.share('https://aerend.no/${widget.profil.slug}', subject: widget.profil.name, sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size);
  }

  @override
  Widget build(BuildContext context) {
    final over = switch (widget.fane) {
      _Fane.tilbud => UtforskCopy.a1_bp_over_tilbud,
      _Fane.aerend => UtforskCopy.a1_bp_over_aerend,
      _Fane.innlegg => UtforskCopy.a1_bp_over_innlegg,
    };
    final b = widget.butikk;
    final sted = [
      if (b?.address != null && b!.address!.isNotEmpty) b.address!.split(',').first.trim(),
      if (b?.distanceKm != null) UtforskCopy.a1_pose_avstand(b!.distanceKm!),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFF12333D),
      body: LfFrame(
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1A4652), Color(0xFF12333D)])),
          child: Column(
            children: [
              _Hode(navn: widget.profil.name, over: over, onTilbake: () => Navigator.of(context).maybePop()),
              Expanded(
                child: SingleChildScrollView(
                  key: const Key('a1_bp_viser'),
                  padding: const EdgeInsets.fromLTRB(12, 2, 12, 120),
                  child: Column(
                    children: [
                      for (var i = 0; i < _poster.length; i++)
                        Padding(
                          key: i == widget.start ? _start : null,
                          padding: const EdgeInsets.only(top: 14),
                          child: _ViserKort(
                            post: _poster[i],
                            profil: widget.profil,
                            meta: _poster[i].publisherType == 'aerend' ? UtforskCopy.a1_bp_aerend_skriver(_dato(_poster[i].publishedAt)) : [...sted, _dato(_poster[i].publishedAt)].join(' · '),
                            vare: _vare(_poster[i]),
                            puls: _puls == _poster[i].id,
                            onLik: () => _lik(_poster[i]),
                            onDel: (a) => _del(a, _poster[i]),
                            onCta: () => _cta(_poster[i]),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViserKort extends StatelessWidget {
  const _ViserKort({
    required this.post,
    required this.profil,
    required this.meta,
    required this.vare,
    required this.puls,
    required this.onLik,
    required this.onDel,
    required this.onCta,
  });

  final FeedPost post;
  final FeedStoreProfile profil;
  final String meta;
  final String? vare;
  final bool puls;
  final VoidCallback onLik;
  final ValueChanged<BuildContext> onDel;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    final p = post;
    final tittel = (p.headline?.trim().isNotEmpty ?? false) ? p.headline!.trim() : '';
    final type = p.publisherType == 'aerend'
        ? UtforskCopy.a1_bp_fane_aerend
        : (p.postType == 'tilbud' ? UtforskCopy.a1_bp_fane_tilbud : (p.media.isVideo && p.hasMedia ? UtforskCopy.a1_bp_video : null));
    final kjop = p.storeProductId != null;
    return CssBox(
      radius: BorderRadius.circular(26),
      clip: true,
      bg: const [CssLinear(180, [Color.fromRGBO(255, 255, 255, .14), Color.fromRGBO(255, 255, 255, .06)])],
      shadows: const [
        CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .18)),
        CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .26)),
        CssShadow(0, 20, 32, -22, Color.fromRGBO(4, 18, 26, .9)),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 300,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment(-.26, -.97), end: Alignment(.26, .97), colors: [Color(0xFFF6E7C8), Color(0xFFD9A254)]))),
                if (p.hasMedia)
                  CachedNetworkImage(imageUrl: _bildeUrl(p), fit: BoxFit.cover, memCacheWidth: BergenPerf.decodeWidth, errorWidget: (_, _, _) => const SizedBox.shrink())
                else
                  Positioned(
                    left: 18,
                    right: 18,
                    top: 62,
                    child: Text(tittel.isEmpty ? p.caption : tittel, maxLines: 5, overflow: TextOverflow.ellipsis, style: jakarta(24, em: -.02, height: 1.15, color: const Color(0xFF23201D))),
                  ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color.fromRGBO(10, 24, 32, .5), Color.fromRGBO(10, 24, 32, .1), Color.fromRGBO(10, 24, 32, 0), Color.fromRGBO(10, 24, 32, .25)],
                      stops: [0, .26, .46, 1],
                    ),
                  ),
                ),
                if (p.media.isVideo && p.hasMedia) const Center(child: _Play(d: 56)),
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 10, 16, .7), offset: Offset(0, 6), blurRadius: 6, spreadRadius: -6)],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: profil.logoUrl == null ? Center(child: Text(profil.name.isEmpty ? '' : profil.name[0], style: jakarta(16, color: const Color(0xFF1E4F5C)))) : CachedNetworkImage(imageUrl: profil.logoUrl!, fit: BoxFit.cover, memCacheWidth: 120),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profil.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: jakarta(14.5, shadows: const [Shadow(color: Color.fromRGBO(0, 10, 16, .6), blurRadius: 6, offset: Offset(0, 1))])),
                            Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: jakarta(10.5, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .88), shadows: const [Shadow(color: Color.fromRGBO(0, 10, 16, .6), blurRadius: 5, offset: Offset(0, 1))])),
                          ],
                        ),
                      ),
                      if (type != null)
                        CssBox(
                          height: 24,
                          radius: BorderRadius.circular(999),
                          padding: const EdgeInsets.symmetric(horizontal: 9),
                          bg: const [CssSolid(Color.fromRGBO(10, 26, 34, .55))],
                          child: Center(child: Text(type, style: jakarta(11))),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 11, 15, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    LfPress(
                      key: ValueKey('a1_bp_lik_${p.id}'),
                      dy: 1.5,
                      scale: .96,
                      ms: 140,
                      onTap: onLik,
                      child: CssBox(
                        height: 34,
                        radius: BorderRadius.circular(999),
                        padding: const EdgeInsets.fromLTRB(9, 0, 12, 0),
                        bg: [
                          p.isLiked
                              ? const CssLinear(180, [Color(0xFFFF9466), Color(0xFFE95C2C)])
                              : const CssLinear(180, [Color.fromRGBO(255, 255, 255, .2), Color.fromRGBO(255, 255, 255, .07)]),
                        ],
                        shadows: p.isLiked
                            ? const [CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .45)), CssShadow(0, 2.5, 0, 0, Color(0xFFA63A12))]
                            : const [
                                CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .32)),
                                CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .12)),
                                CssShadow(0, 2.5, 0, 0, Color.fromRGBO(6, 22, 30, .5)),
                              ],
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _HjertePop(
                              puls: puls,
                              child: SvgPicture.string(
                                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M12 20.6l-7.4-7.3a5 5 0 0 1 7-7.1l.4.4.4-.4a5 5 0 0 1 7 7.1z" fill="${p.isLiked ? '#FFFFFF' : 'none'}" stroke="#FFFFFF" stroke-width="2" stroke-linejoin="round"/></svg>',
                                width: 18,
                                height: 18,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text('${p.likeCount}', style: jakarta(12.5).copyWith(fontFeatures: const [ui.FontFeature.tabularFigures()])),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Builder(
                      builder: (anker) => LfPress(
                        dy: 1.5,
                        scale: .96,
                        ms: 140,
                        onTap: () => onDel(anker),
                        child: CssBox(
                          width: 34,
                          height: 34,
                          radius: BorderRadius.circular(999),
                          bg: const [CssLinear(180, [Color.fromRGBO(255, 255, 255, .2), Color.fromRGBO(255, 255, 255, .07)])],
                          shadows: const [
                            CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .32)),
                            CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .12)),
                            CssShadow(0, 2.5, 0, 0, Color.fromRGBO(6, 22, 30, .5)),
                          ],
                          child: Center(
                            child: SvgPicture.string(
                              '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 15V4 M8 8l4-4 4 4 M5 13v6h14v-6"/></svg>',
                              width: 16,
                              height: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (p.priceOre != null)
                      Text(UtforskCopy.a1_utforsk_pose_price(p.priceOre! ~/ 100), style: jakarta(15).copyWith(fontFeatures: const [ui.FontFeature.tabularFigures()])),
                  ],
                ),
                if (tittel.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(tittel, style: jakarta(17, em: -.01, height: 1.25)),
                ],
                if (p.caption.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(p.caption.trim(), style: inter(13.5, height: 1.45, color: const Color.fromRGBO(255, 255, 255, .86))),
                ],
                const SizedBox(height: 12),
                LfPress(
                  key: ValueKey('a1_bp_cta_${p.id}'),
                  dy: 2,
                  ms: 120,
                  onTap: onCta,
                  child: CssBox(
                    height: 46,
                    radius: BorderRadius.circular(15),
                    bg: const [CssLinear(180, [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], [0, .56, 1])],
                    shadows: const [
                      CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .45)),
                      CssShadow(0, 4, 0, 0, Color.fromRGBO(160, 60, 20, .55)),
                      CssShadow(0, 14, 24, -10, Color.fromRGBO(242, 109, 61, .8)),
                    ],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.string(
                          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M5 7h14l-1.3 11H6.3z M9 7V5.5a3 3 0 0 1 6 0V7"/></svg>',
                          width: 16,
                          height: 16,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            kjop ? (vare == null ? UtforskCopy.a1_bp_legg_i_kurven : UtforskCopy.a1_bp_legg_i_kurven_vare(vare!)) : UtforskCopy.a1_bp_se_menyen,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: jakarta(14.5),
                          ),
                        ),
                      ],
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
}

/// `hjertePop .42s cubic-bezier(.3,1.4,.5,1)` on a new like.
class _HjertePop extends StatelessWidget {
  const _HjertePop({required this.puls, required this.child});

  final bool puls;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!puls) return child;
    return LfOnce(
      ms: 420,
      child: child,
      builder: (context, t, child) {
        final p = const Cubic(.3, 1.4, .5, 1).transform((t / 420).clamp(0.0, 1.0));
        final s = kf(p, const [0, .5, 1], const [.6, 1.3, 1]);
        return Transform.scale(scale: s, child: child);
      },
    );
  }
}
