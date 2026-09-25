import 'package:flutter/material.dart';

import '../../../data/aegil/aegil_app_models.dart';
import '../../../data/aegil/aegil_app_repo.dart';
import '../../../data/aegil/aegil_models.dart';
import '../../../data/aegil/aegil_repo.dart';
import '../meg/a3_scaffold.dart';
import '../meg/a3_services.dart';
import '../kit/bergen_kit.dart';
import 'aegil_copy.dart';

/// "Det Ægil vet om deg" (design `aegilMinne` ≈L4980): the memory grouped
/// (DU LIKER / BUTIKKER / HUSSTAND / KOSTHOLD / …), each entry with Stemmer,
/// Legg til through the onboarding chips, the trust ledger, and Glem alt.
/// Data: `agent/me/memory`, `agent/me/forget`, `agent/me/trust-ledger`.
class MinneScreen extends StatefulWidget {
  const MinneScreen({super.key, this.api, this.repo});

  final AegilAppApi? api;
  final AegilRepo? repo;

  @override
  State<MinneScreen> createState() => _MinneScreenState();
}

class _MinneScreenState extends State<MinneScreen> {
  late final AegilAppApi _api = widget.api ?? A3Services.aegil();
  late final AegilRepo _repo = widget.repo ?? A3Services.aegilRepo();
  List<MemoryEntry> _memory = const [];
  TrustLedger? _ledger;
  bool _loading = true;
  final Set<int> _confirmed = {};

  static const Map<String, String> _groupOf = {
    'like': 'DU LIKER',
    'likes': 'DU LIKER',
    'product': 'DU LIKER',
    'store': 'BUTIKKER',
    'stores': 'BUTIKKER',
    'household': 'HUSSTAND',
    'diet': 'KOSTHOLD',
    'allergen': 'KOSTHOLD',
    'dinner': 'MIDDAG',
    'rhythm': 'MIDDAG',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await Future.wait<Object?>([a3Try(_repo.fetchMemory), a3Try(_api.trustLedger)]);
    if (!mounted) return;
    setState(() {
      _memory = (r[0] as List<MemoryEntry>?) ?? const [];
      _ledger = r[1] as TrustLedger?;
      _loading = false;
    });
  }

  Future<void> _forgetAll() async {
    final ok = await showBergenArk<bool>(
      context,
      onDark: true,
      title: A3AegilCopy.a3_aegil_minne_glem,
      subtitle: A3AegilCopy.a3_aegil_minne_glem_sub,
      primary: BergenArkAction(label: A3AegilCopy.a3_aegil_minne_glem, onTap: () => Navigator.of(context).pop(true)),
      secondary: BergenArkAction(label: 'Behold', onTap: () => Navigator.of(context).pop(false)),
    );
    if (ok != true) return;
    final done = await _repo.forgetAll();
    if (!mounted) return;
    if (done) {
      showBergenToast(context, 'Ægil har glemt alt', icon: Icons.cleaning_services_rounded);
      _load();
    }
  }

  Future<void> _add() async {
    final ctrl = TextEditingController();
    final value = await showBergenArk<String>(
      context,
      onDark: true,
      title: A3AegilCopy.a3_aegil_minne_legg,
      body: TextField(
        controller: ctrl,
        autofocus: true,
        style: BergenTokens.text(BergenTokens.textBody, color: Colors.white),
        decoration: const InputDecoration(hintText: 'F.eks. «Vi liker rekesalat»'),
      ),
      primary: BergenArkAction(label: 'Lagre', onTap: () => Navigator.of(context).pop(ctrl.text.trim())),
    );
    if (value == null || value.isEmpty) return;
    await _repo.submitChips([OnboardingChip(kind: 'like', value: value, label: value, selected: true)]);
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<MemoryEntry>>{};
    for (final m in _memory) {
      groups.putIfAbsent(_groupOf[m.kind] ?? m.kind.toUpperCase(), () => []).add(m);
    }
    final order = [...A3AegilCopy.a3_aegil_minne_grupper, ...groups.keys.where((k) => !A3AegilCopy.a3_aegil_minne_grupper.contains(k))];

    return A3Scaffold(
      title: A3AegilCopy.a3_aegil_minne_title,
      trailing: TextButton(key: const Key('minne-legg'), onPressed: _add, child: Text(A3AegilCopy.a3_aegil_minne_legg, style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w800, color: BergenTokens.orangeLight))),
      child: _loading
          ? const Padding(padding: EdgeInsets.only(top: 80), child: Center(child: CircularProgressIndicator(color: BergenTokens.mint)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_memory.isEmpty)
                  BergenCard(onDark: true, child: Text(A3AegilCopy.a3_aegil_minne_tom, key: const Key('minne-tom'), style: BergenTokens.text(BergenTokens.textBody, color: Colors.white))),
                for (final g in order)
                  if (groups[g]?.isNotEmpty ?? false) ...[
                    A3Kicker(g),
                    for (final m in groups[g]!)
                      A3Row(
                        title: m.label ?? m.value,
                        subtitle: m.hardConstraint ? 'Absolutt — Ægil bryter aldri denne' : m.source,
                        icon: m.hardConstraint ? Icons.shield_rounded : Icons.bookmark_rounded,
                        trailing: _confirmed.contains(m.id)
                            ? const Icon(Icons.check_circle_rounded, color: BergenTokens.mint)
                            : TextButton(onPressed: () => setState(() => _confirmed.add(m.id)), child: Text(A3AegilCopy.a3_aegil_minne_stemmer, style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w800, color: BergenTokens.mint))),
                      ),
                  ],
                if (_ledger != null) ...[
                  const A3Kicker(A3AegilCopy.a3_aegil_tillit),
                  BergenCard(onDark: true, child: Text('${_ledger!.month} · ${_ledger!.waitRecommended} ganger anbefalte Ægil å vente', style: BergenTokens.text(BergenTokens.textBody, color: Colors.white))),
                  const SizedBox(height: 6),
                  Text('${A3AegilCopy.a3_aegil_tillit_spart(_ledger!.savedKr)} · ${A3AegilCopy.a3_aegil_tillit_funn(_ledger!.findsApplied)} · ${A3AegilCopy.a3_aegil_tillit_mot(_ledger!.againstInterestShown)}', style: BergenTokens.text(BergenTokens.textMicro, weight: FontWeight.w600, color: A3Ink.soft)),
                ],
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  key: const Key('minne-glem'),
                  onPressed: _forgetAll,
                  style: OutlinedButton.styleFrom(foregroundColor: BergenTokens.orangeLight, side: const BorderSide(color: BergenTokens.glassBorder), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BergenTokens.radiusButton))),
                  icon: const Icon(Icons.delete_sweep_rounded),
                  label: const Text(A3AegilCopy.a3_aegil_minne_glem),
                ),
                const SizedBox(height: 6),
                Text(A3AegilCopy.a3_aegil_minne_glem_sub, textAlign: TextAlign.center, style: BergenTokens.text(BergenTokens.textMicro, color: A3Ink.muted)),
              ],
            ),
    );
  }
}
