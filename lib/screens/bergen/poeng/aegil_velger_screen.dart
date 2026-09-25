import 'package:flutter/material.dart';

import '../../../data/aegil/aegil_app_models.dart';
import '../../../data/points/points_app_repo.dart';
import '../meg/a3_scaffold.dart';
import '../meg/a3_services.dart';
import '../kit/bergen_kit.dart';
import 'poeng_copy.dart';

/// "Ægil velger → Premien Ægil valgte" (design `velger` ≈L6306): the scene
/// with Ægil's pose (rear → find), the reveal card ("Verdi minst 300 kr",
/// the reason), and Hent premien / Bra / Ikke for meg / Hopp over.
/// Data: `points/prizes/pick`.
class AegilVelgerScreen extends StatefulWidget {
  const AegilVelgerScreen({super.key, this.api});

  final PointsAppApi? api;

  @override
  State<AegilVelgerScreen> createState() => _AegilVelgerScreenState();
}

class _AegilVelgerScreenState extends State<AegilVelgerScreen> {
  late final PointsAppApi _api = widget.api ?? A3Services.points();
  AegilPick? _pick;
  bool _revealed = false;

  /// The pose images shipped with the onboarding commit; the "find" pose is
  /// the landing image until a dedicated one is exported.
  static const String _poseRear = 'assets/images/dashboard/rear.png';
  static const String _poseFind = 'assets/images/dashboard/front.png';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pick = await a3Try(_api.pick);
    if (!mounted) return;
    setState(() => _pick = pick);
    Future<void>.delayed(BergenTokens.motion(context, const Duration(milliseconds: 900)), () {
      if (mounted) setState(() => _revealed = true);
    });
  }

  Future<void> _claim() async {
    final id = _pick?.prizeId;
    if (id == null) return;
    final r = await _api.claim(id);
    if (!mounted) return;
    if (r.claim != null) {
      showBergenToast(context, '${_pick?.prizeName} er din', icon: Icons.check_rounded);
      Navigator.of(context).maybePop();
    } else if (r.error != null) {
      showBergenToast(context, r.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pick = _pick;

    return A3Scaffold(
      kicker: A3PoengCopy.a3_poeng_velger_kicker,
      title: A3PoengCopy.a3_poeng_velger_title,
      subtitle: A3PoengCopy.a3_poeng_velger_sub,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 220,
            child: AnimatedSwitcher(
              duration: BergenTokens.motion(context, BergenTokens.motionSheet),
              child: Image.asset(
                _revealed ? _poseFind : _poseRear,
                key: ValueKey(_revealed),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.sailing_rounded, size: 120, color: BergenTokens.mint),
              ),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedOpacity(
            duration: BergenTokens.motion(context, BergenTokens.motionSheet),
            opacity: _revealed ? 1 : 0,
            child: pick == null
                ? const Center(child: CircularProgressIndicator(color: BergenTokens.mint))
                : pick.prize == null
                    ? BergenCard(onDark: true, child: Text(pick.reason, style: BergenTokens.text(BergenTokens.textBody, color: Colors.white)))
                    : BergenCard(
                        onDark: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (pick.prize?['partner_name'] != null)
                              Text((pick.prize!['partner_name'] as String).toUpperCase(), style: BergenTokens.text(BergenTokens.textMicro, weight: FontWeight.w800, color: const Color(0xFF9FD3DE))),
                            Text(pick.prizeName ?? '', style: BergenTokens.display(BergenTokens.textTitle, color: Colors.white)),
                            const SizedBox(height: 4),
                            Text(pick.valueHint ?? A3PoengCopy.a3_poeng_velger_verdi, style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w700, color: BergenTokens.lantern)),
                            const SizedBox(height: 8),
                            Text(pick.reason, style: BergenTokens.text(BergenTokens.textBody, color: const Color(0xFFDCE9EC))),
                            if (pick.pointPrice != null) ...[
                              const SizedBox(height: 8),
                              Text('${pick.pointPrice} ${A3PoengCopy.a3_poeng_poeng}', style: BergenTokens.display(BergenTokens.textBody, color: BergenTokens.lantern)),
                            ],
                          ],
                        ),
                      ),
          ),
          const SizedBox(height: 16),
          if (pick?.prize != null) ...[
            BergenCta3d(label: A3PoengCopy.a3_poeng_velger_hent, icon: Icons.redeem_rounded, onPressed: pick!.affordable ? _claim : null),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () { showBergenToast(context, 'Notert — Ægil husker det', icon: Icons.thumb_up_rounded); Navigator.of(context).maybePop(); }, style: _ghost, child: const Text(A3PoengCopy.a3_poeng_velger_bra))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton(onPressed: () { showBergenToast(context, 'Ægil velger noe annet neste gang'); Navigator.of(context).maybePop(); }, style: _ghost, child: const Text(A3PoengCopy.a3_poeng_velger_ikke))),
              ],
            ),
          ],
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text(pick?.prize == null ? A3PoengCopy.a3_poeng_velger_tilbake : A3PoengCopy.a3_poeng_velger_hopp, style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w700, color: const Color(0xFFDCE9EC))),
          ),
        ],
      ),
    );
  }

  ButtonStyle get _ghost => OutlinedButton.styleFrom(
    foregroundColor: Colors.white,
    side: const BorderSide(color: BergenTokens.glassBorder),
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BergenTokens.radiusButton)),
    textStyle: BergenTokens.display(BergenTokens.textBody, weight: FontWeight.w700),
  );
}
