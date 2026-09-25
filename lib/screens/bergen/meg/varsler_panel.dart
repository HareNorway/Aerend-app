import 'package:flutter/material.dart';

import '../../common/notifications/notifications_dl.dart';
import '../../common/notifications/notifications_repo.dart';
import 'a3_scaffold.dart';
import '../kit/bergen_kit.dart';
import 'meg_copy.dart';

/// The notifications source the panel reads; tests swap it.
typedef VarslerLoader = Future<List<MassNotificationItem>> Function();

Future<List<MassNotificationItem>> _defaultLoader() async {
  final json = await NotificationsRepo().callNotificationsApi(1, perPage: 30);
  return NotificationsPojo.fromJson(json).massNotificationList;
}

VarslerLoader varslerLoader = _defaultLoader;

/// Varsler (design `varsler` ≈L6076): the filter chips (Alle · Ordre ·
/// Tilbud · Ægil), the list with swipe-to-remove + Angre, "Vis sporing" on
/// order rows, and the empty state "Ingenting nytt siden sist · Fin utsikt."
/// Opens as a sheet from the Meg header, and as `/bergen/meg/varsler`.
Future<void> showVarslerPanel(BuildContext context) => showBergenSheet<void>(
      context,
      builder: (_) => const VarslerBody(asSheet: true),
    );

class VarslerScreen extends StatelessWidget {
  const VarslerScreen({super.key});

  @override
  Widget build(BuildContext context) => const A3Scaffold(title: A3MegCopy.a3_meg_varsler_title, child: VarslerBody());
}

class VarslerBody extends StatefulWidget {
  const VarslerBody({super.key, this.asSheet = false, this.loader});

  final bool asSheet;
  final VarslerLoader? loader;

  @override
  State<VarslerBody> createState() => _VarslerBodyState();
}

class _VarslerBodyState extends State<VarslerBody> {
  List<MassNotificationItem> _items = const [];
  int _filter = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    (widget.loader ?? varslerLoader)().then((l) {
      if (!mounted) return;
      setState(() {
        _items = l;
        _loading = false;
      });
    }).catchError((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  String _kind(MassNotificationItem n) {
    final t = '${n.title} ${n.message}'.toLowerCase();
    if (t.contains('ægil') || t.contains('aegil')) return 'Ægil';
    if (t.contains('ordre') || t.contains('bestilling') || t.contains('levert') || t.contains('på vei')) return 'Ordre';
    if (t.contains('tilbud') || t.contains('%') || t.contains('rabatt')) return 'Tilbud';
    return 'Alle';
  }

  void _remove(MassNotificationItem n) {
    final idx = _items.indexOf(n);
    setState(() => _items = _items.where((x) => x != n).toList());
    showBergenUndo(
      context,
      message: A3MegCopy.a3_meg_varsler_fjernet(n.title),
      onUndo: () {
        if (!mounted) return;
        setState(() => _items = [..._items]..insert(idx.clamp(0, _items.length), n));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final onDark = !widget.asSheet;
    const filters = A3MegCopy.a3_meg_varsler_filtre;
    final visible = _filter == 0 ? _items : _items.where((n) => _kind(n) == filters[_filter]).toList();

    return Column(
      key: const Key('varsler-body'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.asSheet)
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 8),
            child: Row(
              children: [
                Expanded(child: Text(A3MegCopy.a3_meg_varsler_title, style: BergenTokens.display(BergenTokens.textTitle, color: BergenTokens.ink))),
                TextButton(onPressed: () => Navigator.of(context).maybePop(), child: Text(A3MegCopy.a3_meg_varsler_lukk, style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w800, color: BergenTokens.orange))),
              ],
            ),
          ),
        Wrap(
          spacing: 8,
          children: [
            for (var i = 0; i < filters.length; i++)
              BergenChip(key: Key('varsler-filter-$i'), label: filters[i], selected: _filter == i, onDark: onDark, onTap: () => setState(() => _filter = i)),
          ],
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: BergenTokens.mint)))
        else if (visible.isEmpty)
          BergenCard(
            key: const Key('varsler-tom'),
            onDark: onDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(A3MegCopy.a3_meg_varsler_tom, style: BergenTokens.display(BergenTokens.textSection, color: onDark ? Colors.white : BergenTokens.ink)),
                Text(A3MegCopy.a3_meg_varsler_tom_sub, style: BergenTokens.text(BergenTokens.textSmall, color: onDark ? A3Ink.sub : BergenTokens.inkSecondary)),
                const SizedBox(height: 8),
                TextButton(onPressed: () => Navigator.of(context).pushNamed('/bergen/meg/konto'), child: Text(A3MegCopy.a3_meg_varsler_slaa_paa, style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w800, color: BergenTokens.orange))),
              ],
            ),
          )
        else
          for (final n in visible)
            Dismissible(
              key: Key('varsel-${n.id}'),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => _remove(n),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20, bottom: 10),
                child: Text(A3MegCopy.a3_meg_varsler_fjern, style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w800, color: BergenTokens.orange)),
              ),
              child: A3Row(
                onDark: onDark,
                title: n.title,
                subtitle: n.message,
                icon: switch (_kind(n)) { 'Ordre' => Icons.sailing_rounded, 'Tilbud' => Icons.local_offer_rounded, 'Ægil' => Icons.auto_awesome_rounded, _ => Icons.notifications_rounded },
                badge: _kind(n) == 'Ordre' ? A3MegCopy.a3_meg_varsler_vis_sporing : null,
                onTap: _kind(n) == 'Ordre' ? () => Navigator.of(context).pushNamed('/bergen/meg/bestillinger') : null,
                trailing: _kind(n) == 'Ordre' ? null : IconButton(tooltip: A3MegCopy.a3_meg_varsler_fjern, onPressed: () => _remove(n), icon: Icon(Icons.close_rounded, size: 18, color: onDark ? A3Ink.muted : BergenTokens.inkMuted)),
              ),
            ),
        if (widget.asSheet) const SizedBox(height: 8),
      ],
    );
  }
}
