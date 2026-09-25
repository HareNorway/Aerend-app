import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/ops/butikk_models.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../kit/bergen_kit.dart';
import 'butikk_copy.dart';

/// `Dreieskiven` (≈L2762 in `Ærend Kunde Bergen.dc.html`): the pointer-driven
/// turntable of the week's display. Drag left or right to spin; the front
/// item shows its price, the heart saves it ("si fra hvis prisen faller"),
/// and the line under the disc is the item's name, quote and who picked it.
///
/// Reused by Kategori Mote, the fashion store page and Gaver.
class Dreieskiven extends StatefulWidget {
  const Dreieskiven({
    super.key,
    required this.items,
    required this.onAdd,
    this.onSave,
    this.onOpen,
    this.quotes = const {},
    this.who,
    this.saved = const {},
  });

  final List<BergenMenuItem> items;
  final ValueChanged<BergenMenuItem> onAdd;
  final ValueChanged<BergenMenuItem>? onSave;
  final ValueChanged<BergenMenuItem>? onOpen;

  /// Optional "«quote»" per item id (the staff line in the design).
  final Map<int, String> quotes;

  /// "Sara · Torgboden Mote" — who picked the display.
  final String? who;

  /// Item ids the customer has saved.
  final Set<int> saved;

  @override
  State<Dreieskiven> createState() => _DreieskivenState();
}

class _DreieskivenState extends State<Dreieskiven> {
  /// Rotation in items: 0 = the first item in front.
  double _turn = 0;
  double _dragStart = 0;
  double _turnAtStart = 0;

  int get _front {
    if (widget.items.isEmpty) return 0;
    final n = widget.items.length;
    return ((-_turn).round() % n + n) % n;
  }

  void _snap() {
    setState(() => _turn = _turn.roundToDouble());
  }

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final items = widget.items;
    if (items.isEmpty) return const SizedBox.shrink();
    final n = items.length;
    final front = items[_front];
    final isSaved = widget.saved.contains(front.id);

    return Column(
      key: const Key('a1_butikk_dreieskiven'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (d) {
            _dragStart = d.globalPosition.dx;
            _turnAtStart = _turn;
          },
          onHorizontalDragUpdate: (d) {
            final dx = d.globalPosition.dx - _dragStart;
            setState(() => _turn = _turnAtStart + dx / (120 * s));
          },
          onHorizontalDragEnd: (_) => _snap(),
          onHorizontalDragCancel: _snap,
          child: SizedBox(
            height: 236 * s,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // The disc.
                Positioned(
                  bottom: 8 * s,
                  child: Container(
                    width: 300 * s,
                    height: 92 * s,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(
                        Radius.elliptical(150 * s, 46 * s),
                      ),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFFBFAF6), Color(0xFFE9E2D2)],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x4023201D),
                          offset: Offset(0, 14),
                          blurRadius: 24,
                          spreadRadius: -10,
                        ),
                      ],
                    ),
                  ),
                ),
                for (final entry in _ordered(n))
                  _card(context, entry.$1, entry.$2, items[entry.$1] == front),
                // Hint.
                Positioned(
                  top: 0,
                  right: 6 * s,
                  child: Text(
                    ButikkCopy.a1_butikk_skive_hint,
                    style: bText(
                      context,
                      10,
                      weight: FontWeight.w700,
                      color: BergenTokens.inkFaint,
                    ),
                  ),
                ),
                // Heart on the front card.
                if (widget.onSave != null)
                  Positioned(
                    top: 18 * s,
                    left: 6 * s,
                    child: GestureDetector(
                      key: const Key('a1_butikk_skive_heart'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => widget.onSave!(front),
                      child: Container(
                        width: 40 * s,
                        height: 40 * s,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x3323201D),
                              offset: Offset(0, 6),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Icon(
                          isSaved
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isSaved
                              ? BergenTokens.orange
                              : BergenTokens.ink,
                          size: 20 * s,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(height: 10 * s),
        // The front item's line.
        AnimatedSwitcher(
          duration: BergenTokens.motion(context, BergenTokens.motionFast),
          child: Column(
            key: ValueKey(front.id),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                front.name,
                key: const Key('a1_butikk_skive_navn'),
                style: bDisplay(
                  context,
                  18,
                  weight: FontWeight.w800,
                  color: BergenTokens.ink,
                ),
              ),
              if (widget.quotes[front.id] != null)
                Text(
                  '«${widget.quotes[front.id]}»',
                  style: bText(
                    context,
                    12.5,
                    weight: FontWeight.w600,
                    color: BergenTokens.inkSecondary,
                  ),
                ),
              if (widget.who != null)
                Text(
                  widget.who!,
                  style: bText(
                    context,
                    10.5,
                    weight: FontWeight.w800,
                    color: BergenTokens.inkFaint,
                  ),
                ),
              SizedBox(height: 10 * s),
              Row(
                children: [
                  Text(
                    ButikkCopy.kr(front.price),
                    style: bDisplay(
                      context,
                      20,
                      weight: FontWeight.w800,
                      color: BergenTokens.ink,
                    ),
                  ),
                  if (front.wasPrice != null) ...[
                    SizedBox(width: 8 * s),
                    Text(
                      ButikkCopy.kr(front.wasPrice!),
                      style: bText(
                        context,
                        12,
                        weight: FontWeight.w600,
                        color: BergenTokens.inkFaint,
                      ).copyWith(decoration: TextDecoration.lineThrough),
                    ),
                  ],
                  const Spacer(),
                  if (widget.onSave != null)
                    Flexible(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => widget.onSave!(front),
                        child: Padding(
                          padding: EdgeInsets.only(right: 10 * s),
                          child: Text(
                            isSaved
                                ? ButikkCopy.a1_butikk_skive_lagret
                                : ButikkCopy.a1_butikk_skive_lagre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: bText(
                              context,
                              11,
                              weight: FontWeight.w800,
                              color: BergenTokens.teal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  BergenCta3d(
                    label: ButikkCopy.a1_butikk_skive_legg,
                    expand: false,
                    onPressed: () => widget.onAdd(front),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Items with their angle, back to front so the front paints last.
  List<(int, double)> _ordered(int n) {
    final list = <(int, double)>[
      for (var i = 0; i < n; i++) (i, (i + _turn) / n * 2 * math.pi),
    ];
    list.sort((a, b) => math.cos(a.$2).compareTo(math.cos(b.$2)));
    return list;
  }

  Widget _card(BuildContext context, int index, double angle, bool isFront) {
    final s = context.bs;
    final item = widget.items[index];
    final depth = (math.cos(angle) + 1) / 2; // 1 = front, 0 = back
    final x = math.sin(angle) * 118 * s;
    final scale = .62 + .38 * depth;
    final w = 96 * s * scale;
    final h = 128 * s * scale;
    return Positioned(
      left: 195 * s + x - w / 2 - 45 * s,
      bottom: 30 * s + (1 - depth) * 34 * s,
      child: Opacity(
        opacity: .45 + .55 * depth,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: isFront
              ? () => widget.onOpen?.call(item)
              : () => setState(() => _turn = (-index).toDouble()),
          child: Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14 * s),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFFFFF), Color(0xFFE9E2D2)],
              ),
              border: Border.all(
                color: isFront ? BergenTokens.orange : const Color(0xF2FFFFFF),
                width: isFront ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x591E4F5C),
                  offset: Offset(0, 10 * depth),
                  blurRadius: 18,
                  spreadRadius: -8,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (item.imageUrl != null)
                  Image.network(
                    item.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  )
                else
                  Center(
                    child: Icon(
                      Icons.checkroom_rounded,
                      size: 34 * s * scale,
                      color: BergenTokens.teal,
                    ),
                  ),
                if (isFront)
                  Positioned(
                    left: 6 * s,
                    bottom: 6 * s,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 7 * s,
                        vertical: 3 * s,
                      ),
                      decoration: BoxDecoration(
                        color: BergenTokens.ink,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        ButikkCopy.kr(item.price),
                        style: bText(
                          context,
                          10,
                          weight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
