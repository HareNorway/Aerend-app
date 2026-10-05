import 'package:flutter/material.dart';

import '../../../data/aegil/aegil_app_models.dart';
import '../../../data/aegil/aegil_app_repo.dart';
import 'a3_services.dart';
import '../kit/bergen_kit.dart';
import 'meg_copy.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';

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

  void _lukk() {
    setState(() => _items = const []);
    _away = const [];
  }

  // Launch design "Mens du var borte" (L9017): a teal card with Ægil, a
  // close key, one line per thing and "Se de siste 30 dagene".
  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    const hvit = Color(0xFFF5F3EF);
    return LfOnce(
      // skjermInn .34s cubic(.2,.9,.3,1)
      ms: 340,
      builder: (context, t, child) {
        final e = const Cubic(.2, .9, .3, 1).transform(kfP(t, 0, 340));
        final sk = .985 + .015 * e;
        return Opacity(
          opacity: e,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..translateByDouble(0, 10 * (1 - e), 0, 1)
              ..scaleByDouble(sk, sk, 1, 1),
            child: child,
          ),
        );
      },
      child: CssBox(
        key: const Key('borte-card'),
        radius: BorderRadius.circular(24),
        bg: const [CssLinear(160, [Color(0xFF2A6272), Color(0xFF1E4F5C), Color(0xFF173E48)], [0, .6, 1])],
        shadows: const [CssShadow(0, 24, 44, -22, Color.fromRGBO(8, 24, 32, .6))],
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset('assets/images/dashboard/invitation.png', width: 38, height: 38, fit: BoxFit.contain),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(A3MegCopy.a3_meg_borte_kicker, style: inter(11, weight: FontWeight.w800, color: const Color(0xFFB9CBD5))),
                      Text(
                        _items.length == 3 ? A3MegCopy.a3_meg_borte_title : '${_items.length} ting fra Ægil',
                        style: jakarta(16, color: hvit),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _lukk,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(color: const Color.fromRGBO(255, 255, 255, .14), borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.center,
                    child: Text('✕', style: inter(13, color: hvit)),
                  ),
                ),
              ],
            ),
            for (final a in _items)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color.fromRGBO(255, 255, 255, .14)))),
                child: Text.rich(
                  TextSpan(
                    text: a.text,
                    style: inter(13, color: hvit),
                    children: [
                      if (a.undoable) ...[
                        const TextSpan(text: ' · '),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _items = _items.where((x) => x.id != a.id).toList());
                              _away = _items;
                              showBergenUndo(context, message: 'Angret', onUndo: () => setState(() => _items = [..._items, a]));
                            },
                            child: Text(A3MegCopy.a3_meg_varsler_angre, style: inter(13, weight: FontWeight.w800, color: const Color(0xFF5CE0B8))),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => Navigator.of(context).pushNamed('/bergen/meg/varsler'),
              child: Text(A3MegCopy.a3_meg_borte_se, style: inter(12, weight: FontWeight.w800, color: const Color(0xFF5CE0B8))),
            ),
          ],
        ),
      ),
    );
  }
}
