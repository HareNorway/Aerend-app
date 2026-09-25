import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../networking/ops/ops_customer_api.dart';
import '../../../utils/utils.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../kit/bergen_kit.dart';
import 'kasse_copy.dart';

/// The post-purchase sequence (`kjopSteg2–4` ≈L5249 in
/// `Ærend Kunde Bergen.dc.html`).
///
/// Steps 2–3 are placeholders in the design and are implemented as the Vipps
/// return → **Bekreftet** transition ([KjopBekreftetScreen]). Step 4 is
/// **Levert · vervebillett** ([showVervebillett]): "ÆREND-BILLETT {kode} —
/// Gi 100 kr, få 100 kr", Del billetten / Kopier, the code from
/// `GET /api/points/me/referral` (guarded — the card is not shown without
/// it), shown once per order after Levert.
class KjopBekreftetScreen extends StatefulWidget {
  const KjopBekreftetScreen({super.key, required this.orderId});

  final int orderId;

  @override
  State<KjopBekreftetScreen> createState() => _KjopBekreftetScreenState();
}

class _KjopBekreftetScreenState extends State<KjopBekreftetScreen> {
  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
  }

  void _follow() {
    BergenRoutes.pushOr(
      context,
      '/bergen/sporing/${widget.orderId}',
      orElse: () => Navigator.of(context).maybePop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Scaffold(
      backgroundColor: BergenTokens.teal,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: kBergenScreenGradient),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24 * s),
            child: Column(
              key: const Key('a1_kasse_bekreftet'),
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: BergenTokens.motion(
                    context,
                    const Duration(milliseconds: 700),
                  ),
                  curve: const Cubic(.3, 1.3, .5, 1),
                  builder: (context, t, child) => Transform.scale(
                    scale: .6 + .4 * t,
                    child: Opacity(opacity: t.clamp(0, 1), child: child),
                  ),
                  child: Center(
                    child: Container(
                      width: 96 * s,
                      height: 96 * s,
                      decoration: BoxDecoration(
                        color: BergenTokens.mint,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(color: Color(0x805CE0B8), blurRadius: 30),
                        ],
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 52 * s,
                        color: BergenTokens.tealDeep,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20 * s),
                Text(
                  KasseCopy.a1_kasse_bekreftet,
                  textAlign: TextAlign.center,
                  style: bDisplay(
                    context,
                    28,
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 6 * s),
                Text(
                  KasseCopy.a1_kasse_bekreftet_line,
                  textAlign: TextAlign.center,
                  style: bText(
                    context,
                    13.5,
                    weight: FontWeight.w600,
                    color: const Color(0xFFDCE9EC),
                  ),
                ),
                SizedBox(height: 28 * s),
                BergenCta3d(
                  key: const Key('a1_kasse_folg'),
                  label: KasseCopy.a1_kasse_folg,
                  icon: Icons.sailing_rounded,
                  onPressed: _follow,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Step 4: the referral ticket, once per order after Levert. Returns without
/// showing anything when the referral route is not on this tree, or when the
/// order already had its ticket.
Future<void> showVervebillett(
  BuildContext context, {
  required int orderId,
  OpsCustomerApi? api,
}) async {
  final key = 'a1_kasse_billett_$orderId';
  if (prefGetBool(key)) return;
  final json = await (api ?? OpsCustomerApi()).referral();
  final referral = json?['referral'];
  if (referral is! Map) return;
  final code = '${referral['code'] ?? ''}';
  if (code.isEmpty || !context.mounted) return;
  prefSetBool(key, true);
  final kr = ((referral['points_for_me'] as num?)?.toInt() ?? 100);
  final link = '${referral['link'] ?? ''}';
  await showBergenArk<void>(
    context,
    title: KasseCopy.a1_kasse_verv,
    subtitle: KasseCopy.a1_kasse_gi_faa(kr),
    copyText: code,
    body: Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            KasseCopy.a1_kasse_billett_kicker,
            style: BergenTokens.text(
              BergenTokens.textSmall,
              weight: FontWeight.w800,
              color: BergenTokens.inkFaint,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            KasseCopy.a1_kasse_billett_line(kr),
            style: BergenTokens.text(
              BergenTokens.textSmall,
              weight: FontWeight.w600,
              color: BergenTokens.inkSecondary,
            ),
          ),
        ],
      ),
    ),
    primary: BergenArkAction(
      label: KasseCopy.a1_kasse_del_billett,
      icon: Icons.ios_share_rounded,
      onTap: () => Share.share(link.isEmpty ? code : '$code · $link'),
    ),
    secondary: BergenArkAction(
      label: KasseCopy.a1_kasse_lukk,
      onTap: () => Navigator.of(context).pop(),
    ),
  );
}
