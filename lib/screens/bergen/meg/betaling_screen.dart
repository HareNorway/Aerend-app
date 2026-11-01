// ignore_for_file: non_constant_identifier_names
import 'package:flutter/material.dart';

import '../../../networking/ops/cus_api.dart';
import '../../../utils/utils.dart';
import '../../common/auth/launch/lf_css.dart';
import '../kasse/kasse_stripe.dart';
import '../kit/bergen_kit.dart';

/// Customer v2 Step 4 (Commerce spec §6 stage 2): Meg → «Betaling» — the saved
/// cards an assistant's request is charged on when the customer chose «Lagret
/// kort». The cards live with Stripe (the number never touches Ærend); adding
/// one is Stripe's own sheet in setup mode; the default is the card the request
/// pays with. Behind `cus.ai.linked_checkout`; the legacy card screen stays
/// for the ordinary checkout until then.
abstract final class BetalingCopy {
  static String get cus_bet_tittel => languages.cus_bet_tittel;
  static String get cus_bet_linje => languages.cus_bet_linje;
  static String get cus_bet_lagrede => languages.cus_bet_lagrede;
  static String get cus_bet_ingen => languages.cus_bet_ingen;
  static String get cus_bet_legg_til => languages.cus_bet_legg_til;
  static String get cus_bet_standard => languages.cus_bet_standard;
  static String get cus_bet_bruk_som_standard => languages.cus_bet_bruk_som_standard;
  static String get cus_bet_slett => languages.cus_bet_slett;
  static String cus_bet_slett_sporsmal(String kort) => languages.cus_bet_slett_sporsmal(kort);
  static String cus_bet_utloper(String mm, String yy) => languages.cus_bet_utloper(mm, yy);
  static String get cus_bet_lagt_til => languages.cus_bet_lagt_til;
  static String get cus_bet_avbrutt => languages.cus_bet_avbrutt;
  static String get cus_bet_feil => languages.cus_bet_feil;
  static String get cus_bet_stripe_info => languages.cus_bet_stripe_info;
  static String get cus_bet_avbryt => languages.cus_bet_avbryt;
}

class BetalingScreen extends StatefulWidget {
  const BetalingScreen({super.key, this.api, this.presentSetup});

  final CusApi? api;

  /// Shows Stripe's sheet in setup mode (tests pass their own).
  final Future<void> Function(Map<String, dynamic> setup)? presentSetup;

  @override
  State<BetalingScreen> createState() => _BetalingScreenState();
}

class _BetalingScreenState extends State<BetalingScreen> {
  late final CusApi _api = widget.api ?? CusApi();
  List<CusSavedCard>? _kort;
  bool _travel = false;

  @override
  void initState() {
    super.initState();
    _hent();
  }

  Future<void> _hent() async {
    final k = await _api.savedCards();
    if (mounted) setState(() => _kort = k ?? const []);
  }

  Future<void> _leggTil() async {
    if (_travel) return;
    setState(() => _travel = true);
    try {
      final setup = await _api.savedCardSetup();
      if (setup == null) {
        if (mounted) showBergenToast(context, BetalingCopy.cus_bet_feil, icon: Icons.error_outline_rounded);
        return;
      }
      try {
        await (widget.presentSetup ?? kasseStripeSetupCard)(setup);
      } catch (_) {
        if (mounted) showBergenToast(context, BetalingCopy.cus_bet_avbrutt);
        return;
      }
      await _hent();
      if (mounted) showBergenToast(context, BetalingCopy.cus_bet_lagt_til, icon: Icons.check_rounded);
    } finally {
      if (mounted) setState(() => _travel = false);
    }
  }

  Future<void> _standard(CusSavedCard k) async {
    final list = await _api.savedCardDefault(k.id);
    if (mounted) setState(() => _kort = list ?? _kort);
  }

  Future<void> _slett(CusSavedCard k) async {
    final ja = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(BetalingCopy.cus_bet_slett_sporsmal(k.navn)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(BetalingCopy.cus_bet_avbryt)),
          TextButton(key: const Key('cus-bet-slett-ja'), onPressed: () => Navigator.of(ctx).pop(true), child: Text(BetalingCopy.cus_bet_slett)),
        ],
      ),
    );
    if (ja != true || !mounted) return;
    final list = await _api.savedCardDelete(k.id);
    if (mounted) setState(() => _kort = list ?? _kort);
  }

  @override
  Widget build(BuildContext context) {
    final kort = _kort;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F3EF),
        foregroundColor: const Color(0xFF23201D),
        elevation: 0,
        title: Text(BetalingCopy.cus_bet_tittel, style: inter(18, weight: FontWeight.w800, color: const Color(0xFF23201D))),
      ),
      body: ListView(
        key: const Key('cus-betaling'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(BetalingCopy.cus_bet_linje, style: inter(13.5, color: const Color(0xFF6B655C), height: 1.4)),
          const SizedBox(height: 18),
          Text(BetalingCopy.cus_bet_lagrede.toUpperCase(), style: inter(11, weight: FontWeight.w800, color: const Color(0xFF6B655C), em: .08)),
          const SizedBox(height: 8),
          if (kort == null)
            const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
          else if (kort.isEmpty)
            Text(BetalingCopy.cus_bet_ingen, key: const Key('cus-bet-ingen'), style: inter(14, color: const Color(0xFF6B655C)))
          else
            for (final k in kort) _kortRad(k),
          const SizedBox(height: 14),
          FilledButton.icon(
            key: const Key('cus-bet-legg-til'),
            onPressed: _travel ? null : _leggTil,
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1E4F5C), foregroundColor: Colors.white, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            icon: const Icon(Icons.add_card_rounded, size: 20),
            label: Text(BetalingCopy.cus_bet_legg_til, style: inter(15, weight: FontWeight.w800, color: Colors.white)),
          ),
          const SizedBox(height: 10),
          Text(BetalingCopy.cus_bet_stripe_info, style: inter(12, color: const Color(0xFF8A847A), height: 1.4)),
        ],
      ),
    );
  }

  Widget _kortRad(CusSavedCard k) => Container(
        key: Key('cus-bet-kort-${k.id}'),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: k.isDefault ? const Color(0xFF1E4F5C) : const Color(0xFFE4E0D8), width: k.isDefault ? 1.5 : 1)),
        child: Row(children: [
          const Icon(Icons.credit_card_rounded, color: Color(0xFF1E4F5C)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(k.navn, style: inter(15, weight: FontWeight.w800, color: const Color(0xFF23201D))),
              Text(
                [BetalingCopy.cus_bet_utloper(k.expMonth.toString().padLeft(2, '0'), (k.expYear % 100).toString().padLeft(2, '0')), if (k.isDefault) BetalingCopy.cus_bet_standard].join(' · '),
                style: inter(12, color: k.isDefault ? const Color(0xFF1E4F5C) : const Color(0xFF6B655C)),
              ),
            ]),
          ),
          if (!k.isDefault)
            TextButton(key: Key('cus-bet-standard-${k.id}'), onPressed: () => _standard(k), child: Text(BetalingCopy.cus_bet_bruk_som_standard, style: inter(12.5, weight: FontWeight.w800, color: const Color(0xFF1E4F5C)))),
          IconButton(key: Key('cus-bet-slett-${k.id}'), tooltip: BetalingCopy.cus_bet_slett, onPressed: () => _slett(k), icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFF8A847A))),
        ]),
      );
}
