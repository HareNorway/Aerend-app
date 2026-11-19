import 'package:flutter/material.dart';

import '../../../data/points/velger_api.dart';
import '../kit/bergen_kit.dart';

/// Points plan Step 13 (points spec §6.2 baat): the customer's own boat in Vågen on Hjem — only when a person has
/// approved the name and the customer is Platina (`GET points/boat` → `shown`). Nothing otherwise.
class HjemBaat extends StatefulWidget {
  const HjemBaat({super.key, this.api});

  final VelgerApi? api;

  @override
  State<HjemBaat> createState() => _HjemBaatState();
}

class _HjemBaatState extends State<HjemBaat> {
  /// The last answer, so a rebuilt hero shows the boat at once (the hero recreates its children often).
  static String? _sist;

  String? _navn = _sist;

  @override
  void initState() {
    super.initState();
    (widget.api ?? VelgerApi()).boat().then((b) {
      if (b == null) return;
      _sist = b.shown ? b.name : null;
      if (mounted) setState(() => _navn = _sist);
    });
  }

  @override
  Widget build(BuildContext context) {
    final n = _navn;
    if (n == null || n.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: Container(
        key: const Key('hjem-baat'),
        padding: const EdgeInsets.fromLTRB(9, 4, 11, 4),
        decoration: BoxDecoration(color: const Color(0xCC0E3A46), borderRadius: BorderRadius.circular(999), border: Border.all(color: const Color(0x66F7D57E))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sailing_rounded, size: 14, color: Color(0xFFF7D57E)),
            const SizedBox(width: 5),
            Text(n, style: BergenTokens.text(11.5, weight: FontWeight.w800, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
