import 'package:flutter/material.dart';

import '../../../data/aegil/aegil_app_models.dart';
import '../../../data/aegil/aegil_app_repo.dart';
import 'a3_services.dart';
import '../kit/bergen_kit.dart';
import 'meg_copy.dart';

List<AwayItem> _away = const [];

/// Refreshes the cache behind [mensDuVarBorteCard] from `agent/me/away`
/// (≤3 unseen actions). The Hjem calls it on cold start / resume.
Future<List<AwayItem>> refreshMensDuVarBorte({AegilAppApi? api}) async {
  try {
    _away = await (api ?? A3Services.aegil()).away();
  } catch (_) {
    _away = const [];
  }
  return _away;
}

@visibleForTesting
void setMensDuVarBorteForTest(List<AwayItem> items) => _away = items;

/// The cold-start "Mens du var borte" card at the top of the Hjem sheet
/// (seam, design `borte` ≈L2010). Returns null when Ægil has nothing to say.
Widget? mensDuVarBorteCard(BuildContext context) {
  if (_away.isEmpty) return null;
  return _BorteCard(items: _away);
}

class _BorteCard extends StatefulWidget {
  const _BorteCard({required this.items});

  final List<AwayItem> items;

  @override
  State<_BorteCard> createState() => _BorteCardState();
}

class _BorteCardState extends State<_BorteCard> {
  late List<AwayItem> _items = widget.items;

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    return BergenCard(
      key: const Key('borte-card'),
      onDark: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(A3MegCopy.a3_meg_borte_kicker, style: BergenTokens.text(BergenTokens.textMicro, weight: FontWeight.w800, color: BergenTokens.inkMuted).copyWith(letterSpacing: 1.2)),
          Text(_items.length == 3 ? A3MegCopy.a3_meg_borte_title : '${_items.length} ting fra Ægil', style: BergenTokens.display(BergenTokens.textSection, color: BergenTokens.ink)),
          const SizedBox(height: 8),
          for (final a in _items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, size: 16, color: BergenTokens.teal),
                  const SizedBox(width: 8),
                  Expanded(child: Text(a.text, style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w600, color: BergenTokens.ink))),
                  if (a.undoable)
                    TextButton(
                      onPressed: () {
                        setState(() => _items = _items.where((x) => x.id != a.id).toList());
                        _away = _items;
                        showBergenUndo(context, message: 'Angret', onUndo: () => setState(() => _items = [..._items, a]));
                      },
                      child: Text(A3MegCopy.a3_meg_varsler_angre, style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w800, color: BergenTokens.orange)),
                    ),
                ],
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pushNamed('/bergen/meg/varsler'),
            child: Text(A3MegCopy.a3_meg_borte_se, style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w800, color: BergenTokens.orange)),
          ),
        ],
      ),
    );
  }
}
