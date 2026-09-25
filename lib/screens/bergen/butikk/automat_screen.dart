import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../networking/ops/ops_customer_api.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../kit/bergen_kit.dart';
import 'butikk_copy.dart';

/// `automat` — Poseautomaten (≈L4636 in `Ærend Kunde Bergen.dc.html`) at
/// `/bergen/automat`.
///
/// A claw machine over tonight's real bags (`GET /api/ops/products?kind=pose`):
/// steer the claw with the arrows, pull the lever, the bag lands, "Sikre posen
/// · 99 kr" adds it to the basket. "Ingen nedtelling. Ingen niter." — there is
/// no losing pull; the value floor is on the machine.
class AutomatScreen extends StatefulWidget {
  const AutomatScreen({super.key, this.api});

  final OpsCustomerApi? api;

  @override
  State<AutomatScreen> createState() => _AutomatScreenState();
}

class _AutomatScreenState extends State<AutomatScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>>? _bags;
  int _claw = 0;
  bool _pulling = false;
  Map<String, dynamic>? _won;
  late final AnimationController _drop;

  OpsCustomerApi get _api => widget.api ?? OpsCustomerApi();

  @override
  void initState() {
    super.initState();
    _drop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _load();
  }

  @override
  void dispose() {
    _drop.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final bags = await _api.poser();
    if (!mounted) return;
    setState(() => _bags = bags);
  }

  Future<void> _pull() async {
    final bags = _bags ?? const [];
    if (bags.isEmpty || _pulling) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _pulling = true;
      _won = null;
    });
    final motion = BergenTokens.motion(
      context,
      const Duration(milliseconds: 1400),
    );
    _drop.duration = motion == Duration.zero
        ? const Duration(milliseconds: 1)
        : motion;
    await _drop.forward(from: 0);
    if (!mounted) return;
    setState(() {
      _won = bags[_claw.clamp(0, bags.length - 1)];
      _pulling = false;
    });
    HapticFeedback.heavyImpact();
  }

  Future<void> _secure() async {
    final bag = _won;
    if (bag == null) return;
    final ok = await BergenCart.add(
      context,
      storeId: (bag['store_id'] as num?)?.toInt() ?? 0,
      productId: int.tryParse('${bag['id']}') ?? 0,
    );
    if (ok && mounted) BergenRoutes.push(context, '/bergen/kurv');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final safeTop = MediaQuery.paddingOf(context).top;
    final bags = _bags;
    final priceKr = bags == null || bags.isEmpty
        ? 99
        : ((bags.first['price_ore'] as num?)?.toInt() ?? 9900) ~/ 100;
    final won = _won;

    return Scaffold(
      backgroundColor: BergenTokens.tealDeep,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A6272), Color(0xFF173E48), Color(0xFF0F1F2B)],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16 * s,
            safeTop + 10 * s,
            16 * s,
            40 * s,
          ),
          children: [
            Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                    width: 40 * s,
                    height: 40 * s,
                    decoration: BoxDecoration(
                      color: const Color(0x33000000),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0x40FFFFFF)),
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 20 * s,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                if (bags != null && bags.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10 * s,
                      vertical: 5 * s,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x2E5CE0B8),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0x805CE0B8)),
                    ),
                    child: Text(
                      ButikkCopy.a1_butikk_automat_igjen(bags.length),
                      style: bText(
                        context,
                        10.5,
                        weight: FontWeight.w800,
                        color: BergenTokens.mint,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 14 * s),
            Text(
              ButikkCopy.a1_butikk_automat_title,
              key: const Key('a1_butikk_automat_title'),
              style: bDisplay(
                context,
                26,
                weight: FontWeight.w800,
                color: Colors.white,
              ).copyWith(letterSpacing: -0.6),
            ),
            SizedBox(height: 4 * s),
            Text(
              ButikkCopy.a1_butikk_automat_line,
              style: bText(
                context,
                12.5,
                weight: FontWeight.w600,
                color: const Color(0xFFDCE9EC),
              ),
            ),
            SizedBox(height: 16 * s),
            // ── The machine ──────────────────────────────────────────────
            Container(
              height: 300 * s,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26 * s),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF12333D), Color(0xFF0B2634)],
                ),
                border: Border.all(color: const Color(0x47FFFFFF)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xB304121A),
                    offset: Offset(0, 24),
                    blurRadius: 40,
                    spreadRadius: -20,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: bags == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: BergenTokens.mint,
                      ),
                    )
                  : bags.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(24 * s),
                        child: Text(
                          ButikkCopy.a1_butikk_automat_empty,
                          key: const Key('a1_butikk_automat_empty'),
                          textAlign: TextAlign.center,
                          style: bText(
                            context,
                            13,
                            weight: FontWeight.w700,
                            color: const Color(0xFFDCE9EC),
                          ),
                        ),
                      ),
                    )
                  : AnimatedBuilder(
                      animation: _drop,
                      builder: (context, _) {
                        final n = bags.length;
                        final slotW = 1 / n;
                        final t = Curves.easeInOut.transform(_drop.value);
                        final down = t < .5 ? t * 2 : (1 - t) * 2;
                        return LayoutBuilder(
                          builder: (context, c) {
                            final x = c.maxWidth * (slotW * _claw + slotW / 2);
                            return Stack(
                              children: [
                                // Cable + claw.
                                Positioned(
                                  left: x - 1,
                                  top: 0,
                                  child: Container(
                                    width: 2,
                                    height: (40 + 150 * down) * s,
                                    color: const Color(0xFF9BA19E),
                                  ),
                                ),
                                Positioned(
                                  left: x - 18 * s,
                                  top: (40 + 150 * down) * s,
                                  child: Icon(
                                    Icons.pan_tool_alt_rounded,
                                    size: 36 * s,
                                    color: BergenTokens.lantern,
                                  ),
                                ),
                                // Bags.
                                for (var i = 0; i < n; i++)
                                  Positioned(
                                    left:
                                        c.maxWidth * (slotW * i + slotW / 2) -
                                        30 * s,
                                    bottom:
                                        40 * s +
                                        (i == _claw && _drop.value > .5
                                            ? (1 - down) * 120 * s
                                            : 0),
                                    child: _Bag(
                                      name:
                                          '${bags[i]['store_name'] ?? bags[i]['name'] ?? ''}',
                                      lit: i == _claw,
                                      angle: (i - n / 2) * .06,
                                    ),
                                  ),
                                // Floor label.
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 10 * s,
                                  child: Center(
                                    child: Text(
                                      '$priceKr kr · ${ButikkCopy.a1_butikk_automat_verdi(priceKr * 2 + 52)}',
                                      style: bText(
                                        context,
                                        10.5,
                                        weight: FontWeight.w800,
                                        color: const Color(0xFF9FD3DE),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
            ),
            SizedBox(height: 12 * s),
            // ── Controls ─────────────────────────────────────────────────
            if (won == null) ...[
              Row(
                children: [
                  _Arrow(
                    icon: Icons.chevron_left_rounded,
                    onTap: (bags ?? const []).isEmpty || _pulling
                        ? null
                        : () => setState(() => _claw = math.max(0, _claw - 1)),
                    keyName: 'a1_butikk_automat_left',
                  ),
                  SizedBox(width: 10 * s),
                  Expanded(
                    child: Text(
                      bags == null || bags.isEmpty
                          ? ''
                          : '${bags[_claw.clamp(0, bags.length - 1)]['store_name'] ?? bags[_claw.clamp(0, bags.length - 1)]['name'] ?? ''}',
                      key: const Key('a1_butikk_automat_valg'),
                      textAlign: TextAlign.center,
                      style: bDisplay(
                        context,
                        15,
                        weight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 10 * s),
                  _Arrow(
                    icon: Icons.chevron_right_rounded,
                    onTap: (bags ?? const []).isEmpty || _pulling
                        ? null
                        : () => setState(
                            () => _claw = math.min(
                              (bags?.length ?? 1) - 1,
                              _claw + 1,
                            ),
                          ),
                    keyName: 'a1_butikk_automat_right',
                  ),
                ],
              ),
              SizedBox(height: 8 * s),
              Text(
                ButikkCopy.a1_butikk_automat_styr,
                textAlign: TextAlign.center,
                style: bText(
                  context,
                  11,
                  weight: FontWeight.w600,
                  color: const Color(0xFF9FD3DE),
                ),
              ),
              SizedBox(height: 14 * s),
              BergenCta3d(
                key: const Key('a1_butikk_automat_trekk'),
                label: ButikkCopy.a1_butikk_automat_trekk(priceKr),
                icon: Icons.gavel_rounded,
                onPressed: (bags ?? const []).isEmpty || _pulling
                    ? null
                    : _pull,
              ),
            ] else ...[
              Container(
                key: const Key('a1_butikk_automat_vunnet'),
                padding: EdgeInsets.all(14 * s),
                decoration: BoxDecoration(
                  color: const Color(0x24FFFFFF),
                  borderRadius: BorderRadius.circular(22 * s),
                  border: Border.all(color: const Color(0x80F2C14E)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ButikkCopy.a1_butikk_automat_din,
                      style: bText(
                        context,
                        10,
                        weight: FontWeight.w800,
                        color: BergenTokens.lantern,
                      ),
                    ),
                    Text(
                      '${won['store_name'] ?? won['name'] ?? ''}',
                      style: bDisplay(
                        context,
                        18,
                        weight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      [
                        if (won['pickup_window'] != null)
                          ButikkCopy.a1_butikk_automat_hentes(
                            '${won['pickup_window']}',
                          ),
                        ButikkCopy.a1_butikk_automat_verdi(priceKr * 2 + 52),
                      ].join(' · '),
                      style: bText(
                        context,
                        11.5,
                        weight: FontWeight.w600,
                        color: const Color(0xFFDCE9EC),
                      ),
                    ),
                    SizedBox(height: 10 * s),
                    BergenCta3d(
                      key: const Key('a1_butikk_automat_sikre'),
                      label: ButikkCopy.a1_butikk_automat_sikre(
                        ((won['price_ore'] as num?)?.toInt() ??
                                priceKr * 100) ~/
                            100,
                      ),
                      onPressed: _secure,
                    ),
                    SizedBox(height: 8 * s),
                    Center(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _won = null),
                        child: Text(
                          ButikkCopy.a1_butikk_automat_igjen_cta,
                          style: bText(
                            context,
                            11.5,
                            weight: FontWeight.w800,
                            color: BergenTokens.mint,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 4 * s),
                    Text(
                      ButikkCopy.a1_butikk_automat_avslores,
                      style: bText(
                        context,
                        10.5,
                        weight: FontWeight.w600,
                        color: const Color(0xFF9FD3DE),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 16 * s),
            Center(
              child: Text(
                ButikkCopy.a1_butikk_automat_footer,
                textAlign: TextAlign.center,
                style: bText(
                  context,
                  10.5,
                  weight: FontWeight.w600,
                  color: const Color(0xFF9FD3DE),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bag extends StatelessWidget {
  const _Bag({required this.name, required this.lit, required this.angle});

  final String name;
  final bool lit;
  final double angle;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Transform.rotate(
      angle: angle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60 * s,
            height: 64 * s,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14 * s),
              gradient: LinearGradient(
                colors: lit
                    ? const [Color(0xFF9FE0C8), Color(0xFF5CE0B8)]
                    : const [Color(0xFFE9E2D2), Color(0xFFC9BFA8)],
              ),
              boxShadow: [
                if (lit)
                  const BoxShadow(color: Color(0x805CE0B8), blurRadius: 18),
              ],
            ),
            child: Icon(
              Icons.shopping_bag_rounded,
              size: 30 * s,
              color: BergenTokens.tealDeep,
            ),
          ),
          SizedBox(height: 4 * s),
          SizedBox(
            width: 64 * s,
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: bText(
                context,
                9.5,
                weight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({
    required this.icon,
    required this.onTap,
    required this.keyName,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String keyName;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return GestureDetector(
      key: Key(keyName),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 48 * s,
        height: 48 * s,
        decoration: BoxDecoration(
          color: onTap == null
              ? const Color(0x14FFFFFF)
              : const Color(0x33FFFFFF),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x47FFFFFF)),
        ),
        child: Icon(icon, size: 26 * s, color: Colors.white),
      ),
    );
  }
}
