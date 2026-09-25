import 'package:flutter/material.dart';

import '../../../data/aegil/aegil_app_models.dart';
import '../../../data/aegil/aegil_app_repo.dart';
import '../../../data/aegil/aegil_models.dart';
import '../../../data/aegil/aegil_repo.dart';
import '../../../data/aegil/suggestion_models.dart';
import '../../aegil/widgets/aegil_settings_panel.dart';
import '../../aegil/widgets/suggestion_tray.dart';
import '../meg/a3_scaffold.dart';
import '../meg/a3_services.dart';
import '../kit/bergen_kit.dart';
import 'aegil_copy.dart';
import 'minne_screen.dart';

/// Ægil (design `aegil` ≈L4300 → `agForslag`/`agKvittering`/`agFunn`/
/// `agSammen`/`agFiks`/`agIkkeFunnet`/`agAldersblokk`): the header state
/// ("Lytter" → "Leter i Vågen" → "Fant tre valg" …), the greeting, the
/// evening cards, the ask field, and every reply state as a card.
/// Data: `agent/chat`, `agent/me/suggestions`, `agent/door-note`,
/// `agent/photo-order`, settings through agil-2's [AegilRepo].
class AegilScreen extends StatefulWidget {
  const AegilScreen({super.key, this.api, this.repo});

  final AegilAppApi? api;
  final AegilRepo? repo;

  @override
  State<AegilScreen> createState() => _AegilScreenState();
}

class _AegilScreenState extends State<AegilScreen> {
  late final AegilAppApi _api = widget.api ?? A3Services.aegil();
  late final AegilRepo _repo = widget.repo ?? A3Services.aegilRepo();
  final TextEditingController _ask = TextEditingController();

  AegilSettings? _settings;
  List<AegilLevel> _levels = const [];
  final List<AegilTurn> _turns = [];
  bool _busy = false;
  bool _basketAdded = false;

  @override
  void initState() {
    super.initState();
    a3Try(_repo.fetchSettings).then((r) {
      if (!mounted || r == null) return;
      setState(() {
        _settings = r.settings;
        _levels = r.levels;
      });
    });
  }

  @override
  void dispose() {
    _ask.dispose();
    super.dispose();
  }

  String get _headerState {
    if (_busy) return A3AegilCopy.a3_aegil_leter;
    final t = _turns.lastOrNull;
    if (t == null) return A3AegilCopy.a3_aegil_lytter;
    return switch (t.state) {
      'agFunn' => t.cards.length >= 3 ? A3AegilCopy.a3_aegil_fant_tre : A3AegilCopy.a3_aegil_fant_noe,
      'agForslag' => _basketAdded ? A3AegilCopy.a3_aegil_byttet : A3AegilCopy.a3_aegil_fant_noe,
      'agFiks' => A3AegilCopy.a3_aegil_fikser,
      'agSammen' => A3AegilCopy.a3_aegil_sammenlikner,
      'agIkkeFunnet' || 'agAldersblokk' => A3AegilCopy.a3_aegil_beklager,
      _ => A3AegilCopy.a3_aegil_lytter,
    };
  }

  Future<void> _send([String? text, String? intent]) async {
    final q = (text ?? _ask.text).trim();
    if (q.isEmpty && intent == null) return;
    setState(() {
      _busy = true;
      _basketAdded = false;
    });
    _ask.clear();
    final turn = await _api.chat(text: q.isEmpty ? null : q, intent: intent);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (turn != null) _turns.add(turn);
    });
  }

  Future<void> _addBasket(AegilTurn t) async {
    for (final c in t.cards) {
      await _api.add(c.id);
    }
    if (!mounted) return;
    setState(() => _basketAdded = true);
    showBergenUndo(context, message: '${t.basket?.lines.length ?? t.cards.length} varer lagt i kurven', onUndo: () {
      for (final c in t.cards) {
        _api.dismiss(c.id);
      }
      if (mounted) setState(() => _basketAdded = false);
    });
  }

  void _tillatelse() {
    showBergenArk(
      context,
      onDark: true,
      title: A3AegilCopy.a3_aegil_hva_faar,
      subtitle: A3AegilCopy.a3_aegil_tillatelse,
      body: _settings == null
          ? Text(A3AegilCopy.a3_aegil_alle_nivaaer, style: BergenTokens.text(BergenTokens.textSmall, color: A3Ink.sub))
          : AegilSettingsPanel(
              settings: _settings!,
              levels: _levels,
              onLevelChanged: (level) async {
                final r = await _repo.updateSettings({'level': level});
                if (!mounted) return;
                setState(() => _settings = r.settings ?? _settings);
              },
              onToggle: (field, value) async {
                final r = await _repo.updateSettings({field: value});
                if (!mounted) return;
                setState(() => _settings = r.settings ?? _settings);
              },
              onPause: (days) async {
                final r = await _repo.updateSettings({'pause_days': days});
                if (!mounted) return;
                setState(() => _settings = r.settings ?? _settings);
              },
              onResume: () async {
                final r = await _repo.updateSettings({'pause_days': 0});
                if (!mounted) return;
                setState(() => _settings = r.settings ?? _settings);
              },
              onForgetAll: () => Navigator.of(context).pushNamed('/bergen/aegil/minne'),
            ),
      primary: BergenArkAction(label: 'Skjønner', onTap: () => Navigator.of(context).pop()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final level = _settings?.levelName;

    return A3Scaffold(
      title: 'Ægil',
      subtitle: _headerState,
      kicker: level == null ? null : A3AegilCopy.a3_aegil_nivaa(level),
      trailing: IconButton(
        key: const Key('aegil-minne'),
        tooltip: A3AegilCopy.a3_aegil_det_jeg_vet,
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => MinneScreen(api: _api, repo: _repo))),
        icon: const Icon(Icons.psychology_alt_rounded, color: BergenTokens.mint),
      ),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_turns.isEmpty) ...[
            BergenCard(
              onDark: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(A3AegilCopy.a3_aegil_hilsen, style: BergenTokens.text(BergenTokens.textBody, color: Colors.white)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      TextButton(onPressed: _tillatelse, child: Text(A3AegilCopy.a3_aegil_hva_faar, style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w800, color: BergenTokens.orangeLight))),
                      const Spacer(),
                      BergenChip(label: A3AegilCopy.a3_aegil_ja, selected: true, onTap: () => _send(A3AegilCopy.a3_aegil_kveld.first.first)),
                    ],
                  ),
                ],
              ),
            ),
            const A3Kicker(A3AegilCopy.a3_aegil_forslag_kicker),
            for (final k in A3AegilCopy.a3_aegil_kveld)
              A3Row(title: k[0], subtitle: k[1], icon: Icons.nightlight_round, onTap: () => _send(k[0])),
            const A3Kicker(A3AegilCopy.a3_aegil_bla_selv),
            A3Row(title: A3AegilCopy.a3_aegil_sok_kat, icon: Icons.search_rounded, onTap: () => Navigator.of(context).maybePop()),
          ] else
            for (final t in _turns) _turnCard(t),
          if (_busy) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(color: BergenTokens.mint))),
          const SizedBox(height: 12),
          _askBar(),
          const SizedBox(height: 8),
          Text(A3AegilCopy.a3_aegil_allergen, textAlign: TextAlign.center, style: BergenTokens.text(BergenTokens.textMicro, weight: FontWeight.w600, color: A3Ink.muted)),
        ],
      ),
    );
  }

  Widget _askBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            key: const Key('aegil-ask'),
            controller: _ask,
            style: BergenTokens.text(BergenTokens.textBody, color: Colors.white),
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
            decoration: InputDecoration(
              hintText: A3AegilCopy.a3_aegil_spor,
              hintStyle: BergenTokens.text(BergenTokens.textBody, color: A3Ink.muted),
              filled: true,
              fillColor: BergenTokens.glassFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(BergenTokens.radiusButton), borderSide: const BorderSide(color: BergenTokens.glassBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(BergenTokens.radiusButton), borderSide: const BorderSide(color: BergenTokens.glassBorder)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        BergenCta3d(key: const Key('aegil-send'), label: A3AegilCopy.a3_aegil_send, expand: false, onPressed: _busy ? null : _send),
      ],
    );
  }

  Widget _turnCard(AegilTurn t) {
    final children = <Widget>[
      Text(t.reply, style: BergenTokens.text(BergenTokens.textBody, color: Colors.white)),
    ];

    if (t.ageGate || t.state == 'agAldersblokk') {
      children.addAll([
        const SizedBox(height: 8),
        const BergenChip(label: A3AegilCopy.a3_aegil_alder, onDark: true, icon: Icons.lock_clock_rounded),
        const SizedBox(height: 4),
        Text(A3AegilCopy.a3_aegil_alder_sub, style: BergenTokens.text(BergenTokens.textSmall, color: A3Ink.sub)),
        const SizedBox(height: 8),
        BergenCta3d(label: A3AegilCopy.a3_aegil_bankid, onPressed: () => Navigator.of(context).pushNamed('/bergen/meg/konto')),
      ]);
    } else if (t.state == 'agIkkeFunnet') {
      children.addAll([
        const SizedBox(height: 4),
        Text(A3AegilCopy.a3_aegil_ikke_funnet_sub, style: BergenTokens.text(BergenTokens.textSmall, color: A3Ink.sub)),
      ]);
    }

    final basket = t.basket;
    if (basket != null && basket.lines.isNotEmpty) {
      children.addAll([
        const SizedBox(height: 10),
        for (final l in basket.lines)
          Row(
            children: [
              Expanded(child: Text('${l.qty} × ${l.name}', style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w600, color: Colors.white))),
              Text(a3Kr(l.priceOre * l.qty), style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w700, color: A3Ink.sub)),
            ],
          ),
        const SizedBox(height: 6),
        Text('${basket.storeName ?? ''} · ${A3AegilCopy.a3_aegil_varer(basket.lines.length)} · ${a3Kr(basket.subtotalOre)}', style: BergenTokens.text(BergenTokens.textMicro, weight: FontWeight.w800, color: A3Ink.soft)),
        if (basket.derfor != null) ...[
          const SizedBox(height: 4),
          Text('${A3AegilCopy.a3_aegil_derfor} ${basket.derfor}', style: BergenTokens.text(BergenTokens.textSmall, color: A3Ink.sub)),
        ],
        const SizedBox(height: 10),
        if (_basketAdded && t == _turns.last)
          Row(
            children: [
              const BergenChip(label: A3AegilCopy.a3_aegil_kvittering, selected: true, icon: Icons.check_rounded),
              const Spacer(),
              TextButton(onPressed: () => setState(() => _basketAdded = false), child: Text(A3AegilCopy.a3_aegil_angre, style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w800, color: BergenTokens.orangeLight))),
            ],
          )
        else
          Row(
            children: [
              Expanded(flex: 2, child: BergenCta3d(key: const Key('aegil-legg'), label: A3AegilCopy.a3_aegil_legg, icon: Icons.add_shopping_cart_rounded, onPressed: () => _addBasket(t))),
              const SizedBox(width: 8),
              Expanded(child: TextButton(onPressed: () => _send(null, 'bytt_butikk'), child: Text(A3AegilCopy.a3_aegil_bytt_butikk, style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w800, color: BergenTokens.orangeLight)))),
            ],
          ),
      ]);
    }

    if (t.swap != null) {
      children.addAll([
        const SizedBox(height: 8),
        Text('${A3AegilCopy.a3_aegil_grunn} ${t.swap}', style: BergenTokens.text(BergenTokens.textSmall, color: A3Ink.sub)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: BergenCta3d(label: A3AegilCopy.a3_aegil_bytt, expand: true, onPressed: () => _send(null, 'bytt'))),
            const SizedBox(width: 8),
            Expanded(child: TextButton(onPressed: () => showBergenToast(context, 'Beholdt'), child: Text(A3AegilCopy.a3_aegil_behold, style: BergenTokens.text(BergenTokens.textBody, weight: FontWeight.w800, color: A3Ink.sub)))),
          ],
        ),
      ]);
    }

    if (t.comparison != null) {
      final rows = (t.comparison!['rows'] as List?)?.cast<Map>() ?? const [];
      children.addAll([
        const SizedBox(height: 8),
        for (final r in rows)
          Row(
            children: [
              Expanded(child: Text('${r['store'] ?? r['name'] ?? ''}', style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w600, color: Colors.white))),
              if (r['cheapest'] == true) const BergenChip(label: A3AegilCopy.a3_aegil_billigst, selected: true),
              const SizedBox(width: 6),
              Text('${r['total'] ?? ''}', style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w700, color: A3Ink.sub)),
            ],
          ),
        Text(A3AegilCopy.a3_aegil_totaler, style: BergenTokens.text(BergenTokens.textMicro, color: A3Ink.muted)),
      ]);
    }

    if (t.cards.isNotEmpty && basket == null) {
      children.addAll([
        const SizedBox(height: 8),
        const A3Kicker(A3AegilCopy.a3_aegil_funn),
        SuggestionTray(
          suggestions: t.cards,
          onAdd: (s) async {
            await _api.add(s.id);
            if (!mounted) return;
            showBergenToast(context, '${s.headline ?? 'Varen'} lagt til', icon: Icons.check_rounded);
          },
          onDismiss: (s) => _api.dismiss(s.id),
          onNotForMe: (s) => showBergenSheet<void>(
            context,
            builder: (ctx) => NotForMeSheet(
              suggestion: s,
              onChosen: (NotForMeReason reason) {
                Navigator.of(ctx).pop();
                _api.never(s.id, reason.code);
              },
            ),
          ),
        ),
      ]);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BergenCard(key: Key('aegil-turn-${t.state}'), onDark: true, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)),
    );
  }
}
