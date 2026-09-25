import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/ops/sok_models.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../../../utils/utils.dart';
import '../../common/auth/onboarding_kit.dart';
import '../../common/home/bergen/bergen_home.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../../snurre/snurre_chat_screen.dart';
import '../aegil/aegil_entry.dart';
import '../kit/bergen_kit.dart';
import 'sok_copy.dart';

/// `sok` (≈L4067–4228 in `Ærend Kunde Bergen.dc.html`) at `/bergen/sok`.
///
/// One field, four states the design names: `sokTom` (nothing typed — the
/// Spør Ægil card, recent searches, "Populært nå", the week's mission and the
/// category chips), `sokOnske` (the text reads like an errand — a banner to
/// Ægil), `sokVanlig` (hits, with a "compare on price and delivery" footer to
/// Ægil) and `sokIngen` (no hits — let Ægil find the nearest).
///
/// Results come from the app's existing search endpoints through
/// [OpsCustomerApi.search]; "Populært nå" from `ops.search.trending`; the
/// mission from agil-2's `points.mission` (guarded — hidden on 404).
class SokScreen extends StatefulWidget {
  const SokScreen({super.key, this.initialQuery, this.api});

  /// Overrides the route's `q` argument.
  final String? initialQuery;

  /// Injected in tests.
  final OpsCustomerApi? api;

  static const String prefRecent = 'a1_sok_recent';
  static const int maxRecent = 8;

  /// `onske` (design L7806): four or more words, or an errand word.
  static bool isWish(String q) {
    final ql = q.trim().toLowerCase();
    if (ql.isEmpty) return false;
    final words = ql.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    if (words >= 4) return true;
    if (ql.contains('?')) return true;
    return RegExp(
      r'\b(for|under|til|noe|billig|billigste|uten|med|kr)\b',
    ).hasMatch(ql);
  }

  static List<String> readRecent() {
    final raw = prefGetString(prefRecent);
    if (raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw);
      return list is List
          ? list.map((e) => '$e').where((e) => e.isNotEmpty).toList()
          : const [];
    } catch (_) {
      return const [];
    }
  }

  static void remember(String q) {
    final term = q.trim();
    if (term.length < 2) return;
    final list = [
      term,
      ...readRecent().where((e) => e.toLowerCase() != term.toLowerCase()),
    ];
    prefSetString(prefRecent, jsonEncode(list.take(maxRecent).toList()));
  }

  @override
  State<SokScreen> createState() => _SokScreenState();
}

class _SokScreenState extends State<SokScreen> {
  final TextEditingController _field = TextEditingController();
  final FocusNode _focus = FocusNode();
  Timer? _debounce;
  int _seq = 0;
  bool _routeRead = false;

  SokTreff? _treff;
  bool _searching = false;
  List<String> _recent = const [];
  List<String> _trending = const [];
  Map<String, dynamic>? _mission;

  OpsCustomerApi get _api => widget.api ?? OpsCustomerApi();

  String get _q => _field.text.trim();

  @override
  void initState() {
    super.initState();
    _recent = SokScreen.readRecent();
    _field.addListener(_onChanged);
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeRead) return;
    _routeRead = true;
    final q = widget.initialQuery ?? BergenRoutes.argsOf(context)['q'];
    if (q != null && q.trim().isNotEmpty) {
      _field.text = q.trim();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _field.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final trending = await _api.trending();
    if (mounted) setState(() => _trending = trending);
    final mission = await _api.mission();
    if (mounted)
      setState(() => _mission = mission?['mission'] as Map<String, dynamic>?);
  }

  void _onChanged() {
    setState(() {});
    _debounce?.cancel();
    final q = _q;
    if (q.length < 2 || SokScreen.isWish(q)) {
      setState(() {
        _treff = null;
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(q));
  }

  Future<void> _search(String q) async {
    final seq = ++_seq;
    setState(() => _searching = true);
    final result = await _api.search(q);
    if (!mounted || seq != _seq) return;
    setState(() {
      _treff = result;
      _searching = false;
    });
  }

  void _use(String term) {
    _field.text = term;
    _field.selection = TextSelection.collapsed(offset: term.length);
    SokScreen.remember(term);
    setState(() => _recent = SokScreen.readRecent());
  }

  void _submit() {
    final q = _q;
    if (q.isEmpty) return;
    SokScreen.remember(q);
    setState(() => _recent = SokScreen.readRecent());
    if (SokScreen.isWish(q) || (_treff?.isEmpty ?? false)) {
      _askAegil(q);
    }
  }

  void _askAegil([String? draft]) {
    HapticFeedback.selectionClick();
    final q = draft ?? _q;
    BergenRoutes.pushOr(
      context,
      kAegilRoute,
      arguments: {'q': q},
      orElse: () =>
          openScreen(context, SnurreChatScreen(draftFromHomeSearch: q)),
    );
  }

  void _openStore(SokButikk b) => BergenRoutes.pushOr(
    context,
    '/bergen/butikk/${b.id}',
    arguments: {'name': b.name},
    orElse: () => showBergenToast(context, BergenRoutes.kommerSnart),
  );

  void _clearRecent() {
    prefSetString(SokScreen.prefRecent, '');
    setState(() => _recent = const []);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final safeTop = MediaQuery.paddingOf(context).top;
    final q = _q;
    final wish = q.isNotEmpty && SokScreen.isWish(q);
    final vanlig = q.isNotEmpty && !wish;
    final treff = _treff;

    return Scaffold(
      backgroundColor: BergenTokens.teal,
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF7E93A3),
              Color(0xFF9FB2BD),
              Color(0xFF456E7C),
              Color(0xFF1E4F5C),
              Color(0xFF173E48),
            ],
            stops: [0, .14, .22, .34, 1],
          ),
        ),
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            16 * s,
            safeTop + 10 * s,
            16 * s,
            40 * s,
          ),
          children: [
            Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                    width: 40 * s,
                    height: 40 * s,
                    decoration: BoxDecoration(
                      color: const Color(0x33000000),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0x40FFFFFF)),
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 20 * s,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 18 * s),
            Text(
              SokCopy.a1_sok_title,
              key: const Key('a1_sok_title'),
              style: bDisplay(
                context,
                26,
                weight: FontWeight.w800,
                color: Colors.white,
              ).copyWith(letterSpacing: -0.6, height: 1.05),
            ),
            SizedBox(height: 6 * s),
            Text(
              SokCopy.a1_sok_subtitle,
              style: bText(
                context,
                13,
                weight: FontWeight.w600,
                color: const Color(0xFFDCE9EC),
              ),
            ),
            SizedBox(height: 14 * s),
            _Field(
              controller: _field,
              focus: _focus,
              onSubmit: _submit,
              onVoice: () => _focus.requestFocus(),
            ),
            SizedBox(height: 12 * s),
            if (wish) _WishBanner(onAsk: () => _askAegil()),
            if (vanlig && _searching && treff == null)
              Padding(
                padding: EdgeInsets.all(24 * s),
                child: const Center(
                  child: CircularProgressIndicator(color: BergenTokens.mint),
                ),
              ),
            if (vanlig && treff != null && !treff.isEmpty) ...[
              _Results(treff: treff, onStore: _openStore, query: q),
              SizedBox(height: 12 * s),
              _AegilFooter(query: q, onTap: () => _askAegil()),
            ],
            if (vanlig && treff != null && treff.isEmpty && q.length >= 2)
              _NoHits(query: q, onAsk: () => _askAegil()),
            if (q.isEmpty) ...[
              _Categories(),
              SizedBox(height: 12 * s),
              _AegilCard(
                onStart: () => _askAegil(''),
                onWrite: () => _focus.requestFocus(),
                onExample: _use,
              ),
              if (_recent.isNotEmpty) ...[
                SizedBox(height: 12 * s),
                _TermRow(
                  keyName: 'a1_sok_nylig',
                  kicker: SokCopy.a1_sok_nylig,
                  terms: _recent,
                  onTerm: _use,
                  trailing: SokCopy.a1_sok_clear_recent,
                  onTrailing: _clearRecent,
                  icon: Icons.history_rounded,
                ),
              ],
              if (_trending.isNotEmpty) ...[
                SizedBox(height: 12 * s),
                _TermRow(
                  keyName: 'a1_sok_populaert',
                  kicker: SokCopy.a1_sok_populaert,
                  terms: _trending,
                  onTerm: _use,
                  icon: Icons.local_fire_department_rounded,
                ),
              ],
              if (_mission != null) ...[
                SizedBox(height: 12 * s),
                _MissionBanner(
                  mission: _mission!,
                  onSee: () => BergenRoutes.push(context, '/bergen/meg'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ── the field ─────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.focus,
    required this.onSubmit,
    required this.onVoice,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final VoidCallback onSubmit;
  final VoidCallback onVoice;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Container(
      height: 54 * s,
      padding: EdgeInsets.only(left: 14 * s, right: 6 * s),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x5904121A),
            offset: Offset(0, 14),
            blurRadius: 24,
            spreadRadius: -12,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 20 * s, color: BergenTokens.orange),
          SizedBox(width: 9 * s),
          Expanded(
            child: TextField(
              key: const Key('a1_sok_field'),
              controller: controller,
              focusNode: focus,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSubmit(),
              cursorColor: BergenTokens.teal,
              style: bDisplay(
                context,
                15,
                weight: FontWeight.w700,
                color: BergenTokens.ink,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: SokCopy.a1_sok_hint,
                hintStyle: bDisplay(
                  context,
                  14,
                  weight: FontWeight.w600,
                  color: BergenTokens.inkFaint,
                ),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: controller.clear,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6 * s),
                child: Icon(
                  Icons.close_rounded,
                  size: 18 * s,
                  color: BergenTokens.inkMuted,
                ),
              ),
            ),
          GestureDetector(
            key: const Key('a1_sok_voice'),
            behavior: HitTestBehavior.opaque,
            onTap: onVoice,
            child: Container(
              width: 42 * s,
              height: 42 * s,
              decoration: const BoxDecoration(
                gradient: kBergenOrangeGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.mic_rounded, size: 20 * s, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ── wish banner (`sokOnske`, ≈L4090) ──────────────────────────────────────

class _WishBanner extends StatelessWidget {
  const _WishBanner({required this.onAsk});

  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return OnbPressable(
      onTap: onAsk,
      pressScale: .985,
      child: Container(
        key: const Key('a1_sok_onske'),
        padding: EdgeInsets.all(14 * s),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF25606F), Color(0xFF173E48)],
          ),
          borderRadius: BorderRadius.circular(22 * s),
          border: Border.all(color: const Color(0x805CE0B8)),
        ),
        child: Row(
          children: [
            Image.asset(BergenAssets.aegilPopup, width: 44 * s, height: 44 * s),
            SizedBox(width: 12 * s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    SokCopy.a1_sok_onske_title,
                    style: bDisplay(
                      context,
                      15,
                      weight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2 * s),
                  Text(
                    SokCopy.a1_sok_onske_line,
                    style: bText(
                      context,
                      11.5,
                      weight: FontWeight.w600,
                      color: const Color(0xFFDCE9EC),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8 * s),
            BergenCta3d(
              label: SokCopy.a1_sok_onske_cta,
              expand: false,
              onPressed: onAsk,
            ),
          ],
        ),
      ),
    );
  }
}

// ── results (`Søk · treff`, ≈L4109) ───────────────────────────────────────

class _Results extends StatelessWidget {
  const _Results({
    required this.treff,
    required this.onStore,
    required this.query,
  });

  final SokTreff treff;
  final ValueChanged<SokButikk> onStore;
  final String query;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Column(
      key: const Key('a1_sok_treff'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          SokCopy.a1_sok_treff(treff.total),
          style: bText(
            context,
            11,
            weight: FontWeight.w800,
            color: BergenTokens.mint,
          ),
        ),
        if (treff.butikker.isNotEmpty) ...[
          SizedBox(height: 10 * s),
          _SectionLabel(
            label: SokCopy.a1_sok_butikker_label,
            count: SokCopy.a1_sok_butikker(treff.butikker.length),
          ),
          SizedBox(height: 8 * s),
          for (final b in treff.butikker) ...[
            _StoreRow(butikk: b, onTap: () => onStore(b)),
            SizedBox(height: 8 * s),
          ],
        ],
        if (treff.produkter.isNotEmpty) ...[
          SizedBox(height: 6 * s),
          _SectionLabel(
            label: SokCopy.a1_sok_produkter_label,
            count: SokCopy.a1_sok_produkter(treff.produkter.length),
          ),
          SizedBox(height: 8 * s),
          for (final p in treff.produkter) ...[
            _ProductRow(produkt: p),
            SizedBox(height: 8 * s),
          ],
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.count});

  final String label;
  final String count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: bDisplay(
            context,
            15,
            weight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        SizedBox(width: 8 * context.bs),
        Text(
          count,
          style: bText(
            context,
            11,
            weight: FontWeight.w700,
            color: const Color(0xFF9FD3DE),
          ),
        ),
      ],
    );
  }
}

class _StoreRow extends StatelessWidget {
  const _StoreRow({required this.butikk, required this.onTap});

  final SokButikk butikk;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final meta = <String>[
      if (butikk.category != null) butikk.category!,
      if (butikk.etaMinutes != null) SokCopy.a1_sok_eta(butikk.etaMinutes!),
      if (butikk.rating != null) '★ ${butikk.rating}',
      if (butikk.feeText != null) butikk.feeText!,
      if (!butikk.open) SokCopy.a1_sok_closed,
    ];
    return BergenCard(
      onDark: true,
      onTap: onTap,
      padding: EdgeInsets.all(10 * s),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14 * s),
            child: SizedBox(
              width: 52 * s,
              height: 52 * s,
              child: butikk.bannerUrl != null
                  ? Image.network(
                      butikk.bannerUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const ColoredBox(color: Color(0xFF2F6B7B)),
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF2F6B7B), Color(0xFF1B4854)],
                        ),
                      ),
                      child: Icon(
                        Icons.storefront_rounded,
                        color: Colors.white70,
                        size: 24 * s,
                      ),
                    ),
            ),
          ),
          SizedBox(width: 12 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  butikk.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: bDisplay(
                    context,
                    14.5,
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                if (meta.isNotEmpty)
                  Text(
                    meta.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bText(
                      context,
                      11,
                      weight: FontWeight.w600,
                      color: const Color(0xFFDCE9EC),
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: const Color(0x8CFFFFFF),
            size: 20 * s,
          ),
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.produkt});

  final SokProdukt produkt;

  static String kr(double v) =>
      '${v == v.roundToDouble() ? v.toInt() : v.toStringAsFixed(2)} kr';

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return BergenCard(
      onDark: true,
      padding: EdgeInsets.all(10 * s),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14 * s),
            child: SizedBox(
              width: 52 * s,
              height: 52 * s,
              child: produkt.imageUrl != null
                  ? Image.network(
                      produkt.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const ColoredBox(color: Color(0xFFE9A96E)),
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFF6D9B4), Color(0xFFD2854A)],
                        ),
                      ),
                      child: Icon(
                        Icons.restaurant_rounded,
                        color: Colors.white,
                        size: 22 * s,
                      ),
                    ),
            ),
          ),
          SizedBox(width: 12 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  produkt.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: bDisplay(
                    context,
                    14.5,
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  produkt.storeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: bText(
                    context,
                    11,
                    weight: FontWeight.w600,
                    color: const Color(0xFFDCE9EC),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8 * s),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                kr(produkt.price),
                style: bDisplay(
                  context,
                  14,
                  weight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              if (produkt.wasPrice != null)
                Text(
                  kr(produkt.wasPrice!),
                  style: bText(
                    context,
                    10,
                    weight: FontWeight.w600,
                    color: const Color(0xFF9FD3DE),
                  ).copyWith(decoration: TextDecoration.lineThrough),
                ),
            ],
          ),
          SizedBox(width: 8 * s),
          BergenCta3d(
            label: SokCopy.a1_sok_add,
            expand: false,
            onPressed: () => BergenCart.add(
              context,
              storeId: produkt.storeId,
              productId: produkt.id,
            ),
          ),
        ],
      ),
    );
  }
}

class _AegilFooter extends StatelessWidget {
  const _AegilFooter({required this.query, required this.onTap});

  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return BergenCard(
      key: const Key('a1_sok_vanlig_footer'),
      onDark: true,
      onTap: onTap,
      padding: EdgeInsets.all(12 * s),
      child: Row(
        children: [
          Image.asset(BergenAssets.aegilPopup, width: 34 * s, height: 34 * s),
          SizedBox(width: 10 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  SokCopy.a1_sok_ask_aegil,
                  style: bText(
                    context,
                    10,
                    weight: FontWeight.w800,
                    color: BergenTokens.mint,
                  ),
                ),
                Text(
                  SokCopy.a1_sok_compare(query),
                  style: bText(
                    context,
                    12.5,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: const Color(0x8CFFFFFF),
            size: 20 * s,
          ),
        ],
      ),
    );
  }
}

// ── no hits (`sokIngen`) ──────────────────────────────────────────────────

class _NoHits extends StatelessWidget {
  const _NoHits({required this.query, required this.onAsk});

  final String query;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return BergenCard(
      key: const Key('a1_sok_ingen'),
      onDark: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            SokCopy.a1_sok_ingen_title(query),
            style: bDisplay(
              context,
              15,
              weight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4 * s),
          Text(
            SokCopy.a1_sok_ingen_line,
            style: bText(
              context,
              12,
              weight: FontWeight.w600,
              color: const Color(0xFFDCE9EC),
            ),
          ),
          SizedBox(height: 12 * s),
          BergenCta3d(label: SokCopy.a1_sok_ingen_cta, onPressed: onAsk),
        ],
      ),
    );
  }
}

// ── `sokTom`: categories ──────────────────────────────────────────────────

class _Categories extends StatelessWidget {
  /// The design's five categories, in the Hjem's order (the app's category
  /// list carries ids, not slugs; Phase 4's Kategori screen resolves either).
  static const List<String> names = [
    'Restaurant',
    'Fisk',
    'Mote',
    'Interiør',
    'Gaver',
  ];

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              SokCopy.a1_sok_kategorier,
              style: bDisplay(
                context,
                15,
                weight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => BergenRoutes.push(context, '/bergen/utforsk'),
              child: Text(
                SokCopy.a1_sok_alle(names.length),
                style: bText(
                  context,
                  11,
                  weight: FontWeight.w800,
                  color: BergenTokens.mint,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8 * s),
        SizedBox(
          height: 40 * s,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final name in names) ...[
                BergenChip(
                  label: name,
                  onDark: true,
                  onTap: () => BergenRoutes.pushOr(
                    context,
                    '/bergen/kategori/${BergenHomeSlug.of(name)}',
                    arguments: {'name': name},
                    orElse: () =>
                        showBergenToast(context, BergenRoutes.kommerSnart),
                  ),
                ),
                SizedBox(width: 8 * s),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Søk · Spør Ægil (≈L4183) ──────────────────────────────────────────────

class _AegilCard extends StatelessWidget {
  const _AegilCard({
    required this.onStart,
    required this.onWrite,
    required this.onExample,
  });

  final VoidCallback onStart;
  final VoidCallback onWrite;
  final ValueChanged<String> onExample;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Container(
      key: const Key('a1_sok_aegil_card'),
      padding: EdgeInsets.all(14 * s),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF25606F), Color(0xFF173E48)],
        ),
        borderRadius: BorderRadius.circular(24 * s),
        border: Border.all(color: const Color(0x2EFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                BergenAssets.aegilPopup,
                width: 48 * s,
                height: 48 * s,
              ),
              SizedBox(width: 12 * s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      SokCopy.a1_sok_aegil_kicker,
                      style: bText(
                        context,
                        10,
                        weight: FontWeight.w800,
                        color: BergenTokens.mint,
                      ),
                    ),
                    Text(
                      SokCopy.a1_sok_aegil_line,
                      style: bDisplay(
                        context,
                        15,
                        weight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10 * s),
          Wrap(
            spacing: 8 * s,
            runSpacing: 8 * s,
            children: [
              for (final ex in [
                SokCopy.a1_sok_aegil_eks1,
                SokCopy.a1_sok_aegil_eks2,
              ])
                BergenChip(
                  label: '«$ex»',
                  onDark: true,
                  onTap: () => onExample(ex),
                ),
            ],
          ),
          SizedBox(height: 12 * s),
          Row(
            children: [
              Expanded(
                child: BergenCta3d(
                  label: SokCopy.a1_sok_aegil_start,
                  onPressed: onStart,
                ),
              ),
              SizedBox(width: 8 * s),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onWrite,
                child: Container(
                  height: 48 * s,
                  padding: EdgeInsets.symmetric(horizontal: 14 * s),
                  decoration: BoxDecoration(
                    color: const Color(0x24FFFFFF),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0x47FFFFFF)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    SokCopy.a1_sok_aegil_skriv,
                    style: bText(
                      context,
                      12,
                      weight: FontWeight.w800,
                      color: Colors.white,
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
}

// ── Nylig / Populært nå ───────────────────────────────────────────────────

class _TermRow extends StatelessWidget {
  const _TermRow({
    required this.keyName,
    required this.kicker,
    required this.terms,
    required this.onTerm,
    required this.icon,
    this.trailing,
    this.onTrailing,
  });

  final String keyName;
  final String kicker;
  final List<String> terms;
  final ValueChanged<String> onTerm;
  final IconData icon;
  final String? trailing;
  final VoidCallback? onTrailing;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Column(
      key: Key(keyName),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13 * s, color: BergenTokens.lantern),
            SizedBox(width: 5 * s),
            Text(
              kicker,
              style: bText(
                context,
                10,
                weight: FontWeight.w800,
                color: BergenTokens.lantern,
              ),
            ),
            const Spacer(),
            if (trailing != null)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTrailing,
                child: Text(
                  trailing!,
                  style: bText(
                    context,
                    10.5,
                    weight: FontWeight.w800,
                    color: const Color(0xFF9FD3DE),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 8 * s),
        Wrap(
          spacing: 8 * s,
          runSpacing: 8 * s,
          children: [
            for (final t in terms)
              BergenChip(label: t, onDark: true, onTap: () => onTerm(t)),
          ],
        ),
      ],
    );
  }
}

// ── Ukens oppdrag (≈L4215) ────────────────────────────────────────────────

class _MissionBanner extends StatelessWidget {
  const _MissionBanner({required this.mission, required this.onSee});

  final Map<String, dynamic> mission;
  final VoidCallback onSee;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final points = (mission['points'] as num?)?.toInt() ?? 0;
    return BergenCard(
      key: const Key('a1_sok_oppdrag'),
      onDark: true,
      onTap: onSee,
      padding: EdgeInsets.all(12 * s),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  SokCopy.a1_sok_oppdrag_kicker(points),
                  style: bText(
                    context,
                    10,
                    weight: FontWeight.w800,
                    color: BergenTokens.lantern,
                  ),
                ),
                Text(
                  '${mission['title'] ?? ''}',
                  style: bDisplay(
                    context,
                    14.5,
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                if ((mission['body'] ?? '').toString().isNotEmpty)
                  Text(
                    '${mission['body']}',
                    style: bText(
                      context,
                      11.5,
                      weight: FontWeight.w600,
                      color: const Color(0xFFDCE9EC),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 8 * s),
          BergenCta3d(
            label: SokCopy.a1_sok_oppdrag_se,
            expand: false,
            onPressed: onSee,
          ),
        ],
      ),
    );
  }
}
