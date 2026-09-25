import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../theme/bergen_tokens.dart';
import '../kit/bergen_ark.dart';

/// A scenario trigger the demo panel lists (design ≈L7565 `demo`).
class DemoScenario {
  const DemoScenario({required this.id, required this.label, this.run});

  final String id;
  final String label;

  /// Null until a later phase registers the real trigger.
  final Future<void> Function(BuildContext context)? run;
}

/// The debug-only demo panel (AGIL-1 v2 Phase 0). Reached by a 5-tap on the
/// Hjem wordmark; compiled out of release through [kDebugMode]. Phases 2–7
/// register their triggers with [BergenDemoPanel.register]; Sync C lists them
/// as no-ops so the surface exists before anything is wired to it.
abstract final class BergenDemoPanel {
  static const int tapsToOpen = 5;

  static final List<DemoScenario> _scenarios = <DemoScenario>[
    const DemoScenario(id: 'vaer_regn', label: 'Vær: regn'),
    const DemoScenario(id: 'vaer_sol', label: 'Vær: sol'),
    const DemoScenario(id: 'vaer_natt', label: 'Vær: natt'),
    const DemoScenario(id: 'sporing_finner_bud', label: 'Sporing: finner bud'),
    const DemoScenario(
      id: 'sporing_partner',
      label: 'Sporing: butikken leverer',
    ),
    const DemoScenario(id: 'uten_nett', label: 'Uten nett'),
    const DemoScenario(id: 'borte', label: 'Mens du var borte'),
    const DemoScenario(id: 'napp', label: 'Napp på kroken'),
  ];

  static List<DemoScenario> get scenarios => List.unmodifiable(_scenarios);

  /// Replace a listed scenario with a live trigger (or add a new one).
  static void register(DemoScenario scenario) {
    if (!kDebugMode) return;
    final i = _scenarios.indexWhere((s) => s.id == scenario.id);
    if (i == -1) {
      _scenarios.add(scenario);
    } else {
      _scenarios[i] = scenario;
    }
  }

  /// Open the panel. No-op in release.
  static Future<void> open(BuildContext context) async {
    if (!kDebugMode) return;
    await showBergenArk(
      context,
      title: 'Demo',
      subtitle: 'Bare i debug-bygg',
      rows: [
        for (final s in _scenarios)
          BergenArkRow(
            label: s.label,
            trailing: s.run == null ? 'ikke koblet' : null,
            onTap: s.run == null
                ? null
                : () {
                    Navigator.of(context).pop();
                    s.run!(context);
                  },
          ),
      ],
    );
  }
}

/// Counts taps on a child and opens the demo panel at [BergenDemoPanel.tapsToOpen].
/// Wrap the Hjem wordmark in it; in release it is a plain pass-through.
class DemoPanelTapTarget extends StatefulWidget {
  const DemoPanelTapTarget({super.key, required this.child, this.onTap});

  final Widget child;

  /// The child's own tap, forwarded on every tap (the count is a side channel).
  final VoidCallback? onTap;

  @override
  State<DemoPanelTapTarget> createState() => _DemoPanelTapTargetState();
}

class _DemoPanelTapTargetState extends State<DemoPanelTapTarget> {
  int _taps = 0;
  DateTime? _last;

  void _onTap() {
    widget.onTap?.call();
    final now = DateTime.now();
    if (_last == null || now.difference(_last!) > BergenTokens.motionToast) {
      _taps = 0;
    }
    _last = now;
    _taps++;
    if (_taps >= BergenDemoPanel.tapsToOpen) {
      _taps = 0;
      BergenDemoPanel.open(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return widget.child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onTap,
      child: widget.child,
    );
  }
}
