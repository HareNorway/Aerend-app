import 'package:flutter/material.dart';

import '../../../theme/lys/lys_palett.dart';
import '../../../theme/lys/modus_scope.dart';
import 'ai_sheets.dart';
import 'ai_store.dart';

/// Customer plan Step 14: `/bergen/ai/koblede` — the Varsler items «{AI} er
/// nå koblet til» / «koblet fra» / «nådde grensen» land here: a dark host
/// that opens the «Koblede assistenter» sheet and pops when it closes.
class AiKobledeScreen extends StatefulWidget {
  const AiKobledeScreen({super.key});

  @override
  State<AiKobledeScreen> createState() => _AiKobledeScreenState();
}

class _AiKobledeScreenState extends State<AiKobledeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AiStore.instance.load();
      if (!mounted) return;
      await AiArk.flyt(context, 'koblede');
      if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
    });
  }

  @override
  // Lys (app-only host, not in the design): the light screen ground `--lys-ull` behind the sheet.
  Widget build(BuildContext context) => Scaffold(backgroundColor: context.aeM(const Color(0xFF0F2B33), LysPalett.ull), body: const SizedBox.expand());
}
