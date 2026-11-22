import 'dart:async';

import 'package:flutter/material.dart';

import 'game_haptics.dart';
import 'haptikk_moenster.dart';

/// Fjordløpet haptics plan Step 8 (haptics spec §12 H1, TH1, TH13): the haptics lab — a developer screen behind
/// `LOPET_PERF` (debug / TestFlight builds only; the route does not exist in a store build).
///
/// It shows the tier the device reports, the level switch, one button per pattern, a stepper for the crate row, a
/// slider for the metres left in the pulse and a simulated approach at 9 and 24 m/s. Everything plays through
/// [GameHaptics] with the rules on; «Uten regler» plays each pattern alone (single-pattern tuning). On an emulator it
/// reports a tier and plays nothing — vibration exists only on a phone.
class HaptikkLab extends StatefulWidget {
  const HaptikkLab({super.key, this.haptics});

  /// A [GameHaptics] to use (tests); the lab makes its own otherwise.
  final GameHaptics? haptics;

  static const String rute = '/bergen/lopet/haptikk';

  @override
  State<HaptikkLab> createState() => _HaptikkLabState();
}

/// The spec's names for the patterns (§4), for the lab's buttons only — a developer tool, not customer text.
const Map<HaptikkId, String> kHaptikkLabNavn = {
  HaptikkId.h01: 'Bytte felt',
  HaptikkId.h02: 'Kasse',
  HaptikkId.h03: 'Nære på',
  HaptikkId.h04: 'Vest klar',
  HaptikkId.h05: 'Vest brukt',
  HaptikkId.h06: 'Bøye 1',
  HaptikkId.h07: 'Bøye 2',
  HaptikkId.h08: 'Bryggen',
  HaptikkId.h09: 'Puls',
  HaptikkId.h10: 'Ny rekord',
  HaptikkId.h11: 'Rival forbi',
  HaptikkId.h12: 'Ukens beste',
  HaptikkId.h13: 'Kollisjon',
  HaptikkId.h14: 'Seil!',
  HaptikkId.u01: 'Sett seil',
  HaptikkId.u02: 'Nedtelling',
  HaptikkId.u03: 'Pause',
  HaptikkId.u04: 'Bank',
  HaptikkId.u05: 'Bank-bank',
  HaptikkId.u06: 'Poeng',
  HaptikkId.u07: 'Merke',
  HaptikkId.u08: 'Godt nytt',
  HaptikkId.u09: 'Ikke nå',
  HaptikkId.u10: 'Valg',
  HaptikkId.u11: 'Fanfare',
};

class _HaptikkLabState extends State<HaptikkLab> {
  late final GameHaptics _h = widget.haptics ?? GameHaptics();
  bool _klar = false;
  int _kasse = 1;
  double _meter = 30;
  String _sist = '';
  Timer? _innseiling;

  @override
  void initState() {
    super.initState();
    unawaited(_h.prepare().then((_) {
      if (mounted) setState(() => _klar = true);
    }));
  }

  @override
  void dispose() {
    _innseiling?.cancel();
    if (widget.haptics == null) unawaited(_h.dispose());
    super.dispose();
  }

  void _spill(HaptikkId id) {
    final u = _h.play(id, step: _kasse, metresLeft: _meter);
    if (id == HaptikkId.h13) _h.touch(); // the lab is all touches: no silence after the collision
    setState(() => _sist = '${id.name.toUpperCase()} · ${u.name}');
  }

  /// A simulated approach to «Din beste» from 70 m at [ms] metres per second, through the pulse as in a run.
  void _seilInn(double ms) {
    _innseiling?.cancel();
    _h.newRun();
    var left = 70.0;
    var beats = 0;
    _innseiling = Timer.periodic(const Duration(milliseconds: 16), (t) {
      left -= ms * .016;
      if (_h.pulse(left > 0 ? left : 0)) beats++;
      if (left <= 0) {
        t.cancel();
        if (mounted) setState(() => _sist = 'Innseiling ${ms.round()} m/s · $beats slag');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tier = _klar ? '${_h.tier.name}${_h.tierWhy == null ? '' : ' (${_h.tierWhy})'}' : '…';
    return Scaffold(
      key: const Key('haptikk-lab'),
      appBar: AppBar(title: const Text('Haptikk-lab')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Tier: $tier', key: const Key('haptikk-lab-tier'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<HaptikkNivaaValg>(
            segments: const [
              ButtonSegment(value: HaptikkNivaaValg.full, label: Text('Full')),
              ButtonSegment(value: HaptikkNivaaValg.soft, label: Text('Dempet')),
              ButtonSegment(value: HaptikkNivaaValg.off, label: Text('Av')),
            ],
            selected: {_h.nivaa},
            onSelectionChanged: (v) => setState(() => _h.setLevel(v.first)),
          ),
          SwitchListTile(
            key: const Key('haptikk-lab-regler'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Uten regler (ett mønster alene)'),
            value: _h.utenRegler,
            onChanged: (v) => setState(() => _h.utenRegler = v),
          ),
          Row(children: [
            const Text('Kasse i rad'),
            IconButton(onPressed: () => setState(() => _kasse = (_kasse - 1).clamp(1, 5)), icon: const Icon(Icons.remove)),
            Text('$_kasse'),
            IconButton(onPressed: () => setState(() => _kasse = (_kasse + 1).clamp(1, 5)), icon: const Icon(Icons.add)),
          ]),
          Row(children: [
            Text('Puls ${_meter.round()} m'),
            Expanded(child: Slider(value: _meter, min: 0, max: 60, divisions: 60, onChanged: (v) => setState(() => _meter = v))),
          ]),
          Wrap(spacing: 8, children: [
            OutlinedButton(onPressed: () => _seilInn(9), child: const Text('Innseiling 9 m/s')),
            OutlinedButton(onPressed: () => _seilInn(24), child: const Text('Innseiling 24 m/s')),
          ]),
          const SizedBox(height: 8),
          Text(_sist, key: const Key('haptikk-lab-sist')),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final id in HaptikkId.values)
                FilledButton.tonal(
                  key: Key('haptikk-lab-${id.name}'),
                  onPressed: () => _spill(id),
                  child: Text('${id.name.toUpperCase()} ${kHaptikkLabNavn[id]}'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
