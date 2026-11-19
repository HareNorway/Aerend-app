import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/points/points_app_repo.dart';
import '../../../data/points/points_models.dart';
import '../../../data/points/points_rules.dart';
import '../kit/bergen_kit.dart';
import '../meg/meg_ark.dart';
import '../meg/meg_copy_a4.dart';
import '../meg/mork_rad.dart';
import 'poeng_feil.dart';

/// The prize sheets shared by Premiehylla and Meg (Gap Step 3):
/// - `krev` (L19658, new Bergen): claim a prize. Meg's «Hent premie» opens it
///   for the goal prize, as Premiehylla does for any prize.
/// - `premieVilkaar` (L20250): «Vilkår for premier», dark.
abstract final class PremieArk {
  /// `krev`: what happens, how long it lasts, points after — and the boat asks
  /// for its name first (identity prize).
  static Future<bool?> krev(BuildContext context, {required Prize p, required int poeng, required PointsAppApi api, int? gyldigDager}) {
    final after = (poeng - p.pointPrice).clamp(0, 1 << 30);
    final identity = p.type == 'identity';
    final name = TextEditingController();
    var busy = false;
    String? error;
    StateSetter? sheetSet;

    return showMegArk<bool>(
      context,
      key: const Key('hylla-krev-sheet'),
      title: p.name,
      subtitle: identity ? A4MegCopy.a4_hylla_baat_linje : '${A4MegCopy.nf(p.pointPrice)} poeng${p.partnerName == null ? '' : ' · ${p.partnerName}'}',
      body: (ctx, setState) {
        sheetSet = setState;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (identity)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  key: const Key('hylla-baat-navn'),
                  controller: name,
                  maxLength: 20,
                  onChanged: (_) => setState(() {}),
                  style: BergenTokens.text(15, weight: FontWeight.w800, color: MegArkInk.ink),
                  decoration: InputDecoration(
                    hintText: A4MegCopy.a4_hylla_baat_hint,
                    counterText: '${name.text.length} av 20 tegn',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: .7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: .9), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: .9), width: 1.5),
                    ),
                  ),
                ),
              ),
            MegArkRow(title: A4MegCopy.a4_hylla_dette_skjer, sub: identity ? A4MegCopy.a4_hylla_baat_skjer : hvordan(p.specType)),
            MegArkRow(title: A4MegCopy.a4_hylla_gyldighet, sub: identity ? A4MegCopy.a4_hylla_baat_gyldig : A4MegCopy.a4_hylla_gyldig_dager(gyldigDager ?? 60)),
            // Points plan Step 3 (24des `phKrev`): «Saldo X · Etter: Y poeng» with the bar, then hold-to-claim.
            _SaldoEtter(saldo: poeng, etter: after),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(error!, key: const Key('hylla-krev-feil'), style: megInter(12, FontWeight.w700, color: const Color(0xFFB9441A))),
              ),
            const SizedBox(height: 14),
            PremieHoldKnapp(
              key: const Key('hylla-krev-cta'),
              onFull: () async {
                if (busy) return;
                if (identity && name.text.trim().isEmpty) {
                  showBergenToast(context, A4MegCopy.a4_hylla_baat_navn_forst);
                  return;
                }
                busy = true;
                final nav = Navigator.of(context);
                final r = await api.claim(p.id, identityName: identity ? name.text.trim() : null);
                busy = false;
                if (r.claim != null) {
                  nav.pop(true);
                  if (context.mounted) await PremieFest.vis(context, navn: p.name, under: identity ? A4MegCopy.a4_hylla_baat_skjer : hvordan(p.specType));
                } else {
                  sheetSet?.call(() => error = CusPoengFeil.tekst(r.error, ellers: A4MegCopy.a4_hylla_feil));
                }
              },
            ),
            const SizedBox(height: 9),
            Text(A4MegCopy.a4_hylla_hold_hint, textAlign: TextAlign.center, style: megInter(11, FontWeight.w600, color: MegArkInk.sub)),
          ],
        );
      },
    );
  }

  /// How a premie is delivered (points spec §6.2), by the spec's type; an older server's engine type works too.
  static String hvordan(String type) {
    switch (type) {
      case 'auto':
      case 'voucher':
        return 'Brukes automatisk på neste levering';
      case 'send':
      case 'physical':
        return 'Pakkes og sendes med Posten';
      case 'gave':
      case 'donation':
        return 'Gis til klubben du velger';
      case 'baat':
      case 'identity':
        return 'Båten din legges i Vågen';
      case 'velger':
        return 'Ægil velger en premie til deg';
      default:
        return 'Kode vises her · vis den i butikken';
    }
  }

  /// «Vilkår for premier» (kArk `premieVilkaar`, dark). Rows only from real
  /// rules: Gyldighet (`claim_expiry_days`) and Poeng (`points_expiry_months`)
  /// hide without them. «Utsolgt · kommer tilbake neste måned» since points
  /// plan Step 3 (stock per calendar month).
  static Future<void> vilkaar(BuildContext context, {PointsRules? regler}) {
    final rader = <(String, String, String)>[
      if (regler?.claimExpiryDays case final d?) (MorkIk.klokke, A4MegCopy.a4_premie_vilkaar_gyldighet, A4MegCopy.a4_premie_vilkaar_gyldig(d)),
      (MorkIk.butikk, A4MegCopy.a4_premie_vilkaar_partner, A4MegCopy.a4_premie_vilkaar_partner_sub),
      // Points plan Step 3: stock is a monthly allotment now, refilled on the 1st (points spec §6.1).
      (MorkIk.klokke, A4MegCopy.a4_premie_vilkaar_utsolgt, A4MegCopy.a4_premie_vilkaar_utsolgt_sub),
      if (regler?.pointsExpiryMonths case final m?) (MorkIk.stjerne, A4MegCopy.a4_premie_vilkaar_poeng, A4MegCopy.a4_premie_vilkaar_poeng_sub(m)),
    ];
    return showMegArk<void>(
      context,
      key: const Key('premie-vilkaar-sheet'),
      mork: true,
      // Lys plan §0.2: «Vilkår for premier» stays fjord.
      fjord: true,
      title: A4MegCopy.a4_premie_vilkaar_title,
      subtitle: A4MegCopy.a4_premie_vilkaar_linje,
      body: (ctx, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, r) in rader.indexed) ...[
            if (i > 0) const SizedBox(height: 8),
            MorkRad(delayMs: i * 40.0, ikon: r.$1, navn: r.$2, under: r.$3, onTap: () {}),
          ],
        ],
      ),
      primary: MegArkButton(label: A4MegCopy.a4_meg_lukk, onTap: () => Navigator.of(context).pop()),
    );
  }
}


/// «Saldo X · Etter: Y poeng» and the striped bar of what is left (24des `phKrev`).
class _SaldoEtter extends StatelessWidget {
  const _SaldoEtter({required this.saldo, required this.etter});

  final int saldo;
  final int etter;

  @override
  Widget build(BuildContext context) {
    final andel = saldo <= 0 ? 0.0 : (etter / saldo).clamp(0.0, 1.0);
    return Container(
      key: const Key('hylla-krev-saldo'),
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .55), borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(A4MegCopy.a4_hylla_saldo(saldo), style: megInter(11, FontWeight.w700, color: MegArkInk.sub)),
              const Spacer(),
              Text(A4MegCopy.a4_hylla_etter(etter), style: megInter(13, FontWeight.w800, color: MegArkInk.ink)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Positioned.fill(child: ColoredBox(color: const Color(0xFFF2C14E).withValues(alpha: .25))),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: andel,
                    heightFactor: 1,
                    child: const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF7D57E), Color(0xFFE0A32C)]))),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hold-to-claim (24des `phKrev`): the gold fills over 900 ms while held; let go early and it drains back; full,
/// and [onFull] runs once. A tap alone does nothing — a premie is not claimed by accident.
class PremieHoldKnapp extends StatefulWidget {
  const PremieHoldKnapp({super.key, required this.onFull, this.holdMs = 900});

  final Future<void> Function() onFull;
  final int holdMs;

  @override
  State<PremieHoldKnapp> createState() => _PremieHoldKnappState();
}

class _PremieHoldKnappState extends State<PremieHoldKnapp> with SingleTickerProviderStateMixin {
  // The fill is drawn by the controller; the claim is fired by a timer of the same length, so a slowed animation
  // clock (reduced motion, `timeDilation`) never changes how long the customer holds.
  late final AnimationController _c = AnimationController(vsync: this, duration: Duration(milliseconds: widget.holdMs), reverseDuration: const Duration(milliseconds: 250));
  Timer? _t;
  bool _fired = false;
  bool _holder = false;

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  void _ned() {
    if (_fired) return;
    setState(() => _holder = true);
    _c.forward();
    _t?.cancel();
    _t = Timer(Duration(milliseconds: widget.holdMs), () {
      if (!mounted || _fired) return;
      _fired = true;
      _c.value = 1;
      widget.onFull().whenComplete(() {
        if (mounted) {
          _fired = false;
          setState(() => _holder = false);
          _c.reverse();
        }
      });
    });
  }

  void _opp() {
    _t?.cancel();
    setState(() => _holder = false);
    if (!_fired) _c.reverse();
  }

  @override
  Widget build(BuildContext context) {
    // Raw pointer events: a gesture recognizer would cancel the tap when the hold passes the long-press timeout.
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _ned(),
      onPointerUp: (_) => _opp(),
      onPointerCancel: (_) => _opp(),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF1C4A57),
          borderRadius: BorderRadius.circular(99),
          boxShadow: const [BoxShadow(color: Color.fromRGBO(8, 24, 32, .35), offset: Offset(0, 8), blurRadius: 18, spreadRadius: -8)],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _c,
              builder: (_, __) => FractionallySizedBox(
                widthFactor: _c.value,
                heightFactor: 1,
                child: const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF7D57E), Color(0xFFE0A32C)]))),
              ),
            ),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(center: Alignment(-.32, -.44), colors: [Color(0xFFFBE8B4), Color(0xFFE0A32C), Color(0xFFB77F1C)], stops: [0, .62, 1]),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text(_holder ? A4MegCopy.a4_hylla_holder : A4MegCopy.a4_hylla_hold, style: megInter(15, FontWeight.w800, color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The celebration after a claim (24des `phFest`): «PREMIE HENTET», «Den er din!», the premie and how it is used.
abstract final class PremieFest {
  static Future<void> vis(BuildContext context, {required String navn, required String under}) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: A4MegCopy.a4_hylla_fest_kicker,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, _, __) => GestureDetector(
        key: const Key('hylla-fest'),
        onTap: () => Navigator.of(ctx).pop(),
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(center: Alignment(0, -.28), radius: .9, colors: [Color.fromRGBO(52, 112, 128, .97), Color.fromRGBO(8, 24, 32, .97)]),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.card_giftcard_rounded, size: 76, color: Color(0xFFF7D57E)),
                const SizedBox(height: 14),
                Text(A4MegCopy.a4_hylla_fest_kicker, style: megInter(11, FontWeight.w800, color: const Color(0xFF7FF0CB)).copyWith(letterSpacing: 2)),
                const SizedBox(height: 6),
                Text(A4MegCopy.a4_hylla_fest_tittel, style: BergenTokens.display(30, weight: FontWeight.w800, color: Colors.white, letterSpacingEm: -0.03)),
                const SizedBox(height: 6),
                Text(navn, textAlign: TextAlign.center, style: megInter(15, FontWeight.w800, color: const Color(0xFFF7D57E))),
                const SizedBox(height: 4),
                Text(under, textAlign: TextAlign.center, style: megInter(12, FontWeight.w600, color: Colors.white.withValues(alpha: .7))),
                const SizedBox(height: 26),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(99), border: Border.all(color: Colors.white.withValues(alpha: .3))),
                  child: Text(A4MegCopy.a4_hylla_fest_lukk, style: megInter(14, FontWeight.w800, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
      transitionBuilder: (ctx, a, _, child) => FadeTransition(opacity: a, child: child),
    );
  }
}
