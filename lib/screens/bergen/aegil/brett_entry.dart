import 'package:flutter/material.dart';

import '../../../data/aegil/aegil_app_repo.dart';
import '../../../data/aegil/suggestion_models.dart';
import '../../aegil/widgets/suggestion_tray.dart';
import '../meg/a3_services.dart';
import '../kit/bergen_kit.dart';
import 'aegil_copy.dart';

/// The last count the Brett learned (kept so the Hjem card can render
/// synchronously). [refreshAegilFindCount] fills it from
/// `agent/me/suggestions?context=home`.
int _findCount = 0;

/// How many finds the Ægil-relevanskort on the Hjem shows (seam). agil-1
/// hides the card at 0.
int aegilFindCount() => _findCount;

/// Refreshes [aegilFindCount] from the API; the Hjem calls it on resume.
Future<int> refreshAegilFindCount({AegilAppApi? api}) async {
  try {
    final list = await (api ?? A3Services.aegil()).suggestions(context: 'home');
    _findCount = list.where((s) => !const {'dismissed', 'added', 'never', 'expired', 'used'}.contains(s.state)).length;
  } catch (_) {
    _findCount = 0;
  }
  return _findCount;
}

@visibleForTesting
void setAegilFindCountForTest(int n) => _findCount = n;

/// Ægil-relevanskort tap → the Brett sheet (design `brett` ≈L2205): the
/// suggestion drawer with agil-2's [SuggestionTray] — Legg til / Ikke for meg
/// through `agent/me/suggestions/{id}/add|dismiss|never`.
Future<void> showAegilBrett(BuildContext context, {AegilAppApi? api}) async {
  final a = api ?? A3Services.aegil();
  await showBergenSheet<void>(
    context,
    onDark: false,
    builder: (ctx) => _Brett(api: a),
  );
}

class _Brett extends StatefulWidget {
  const _Brett({required this.api});

  final AegilAppApi api;

  @override
  State<_Brett> createState() => _BrettState();
}

class _BrettState extends State<_Brett> {
  List<Suggestion> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    a3Try(() => widget.api.suggestions(context: 'home')).then((l0) {
      final l = l0 ?? const <Suggestion>[];
      if (!mounted) return;
      setState(() {
        _items = l;
        _loading = false;
        _findCount = l.length;
      });
    });
  }

  void _remove(Suggestion s) => setState(() {
        _items = _items.where((x) => x.id != s.id).toList();
        _findCount = _items.length;
      });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('aegil-brett'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Text(A3AegilCopy.a3_aegil_brett_title, style: BergenTokens.display(BergenTokens.textTitle, color: BergenTokens.ink)),
        const SizedBox(height: 10),
        if (_loading)
          const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: BergenTokens.teal)))
        else
          SuggestionTray(
            suggestions: _items,
            emptyMessage: A3AegilCopy.a3_aegil_brett_tom,
            onAdd: (s) async {
              await widget.api.add(s.id);
              if (!mounted) return;
              _remove(s);
              showBergenToast(this.context, '${s.headline ?? 'Varen'} lagt til', icon: Icons.check_rounded);
            },
            onDismiss: (s) async {
              await widget.api.dismiss(s.id);
              if (mounted) _remove(s);
            },
            onNotForMe: (s) => showBergenSheet<void>(
              context,
              builder: (ctx) => NotForMeSheet(
                suggestion: s,
                onChosen: (reason) async {
                  Navigator.of(ctx).pop();
                  await widget.api.never(s.id, reason.code);
                  if (mounted) _remove(s);
                },
              ),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}
