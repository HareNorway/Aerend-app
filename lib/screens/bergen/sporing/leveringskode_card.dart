import 'package:flutter/material.dart';

import '../../../data/ops/tracking_models.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../kit/bergen_kit.dart';
import 'sporing_copy.dart';

/// The completion layer (≈L7294–7326 in `Ærend Kunde Bergen.dc.html`):
/// **Bud-identitet**, **Leveringskode** and **Valg som venter**.
///
/// [LeveringskodeCard] replaces the retired `DeliveryCodeCard`
/// (`lib/screens/tracking/`): the 7×7 visual code from `qr_payload` plus the
/// PIN, PIN only offline ("Uten nett vises bare PIN."), the reason line, and
/// "Posen kan ikke settes igjen ved døren."

/// Courier initial + "BankID-verifisert", or the store icon for a
/// partner-delivered order — never a courier name for a partner order.
class BudIdentitetPill extends StatelessWidget {
  const BudIdentitetPill({super.key, required this.tracking});

  final OpsTracking tracking;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final courier = tracking.isPartner ? null : tracking.courier;
    final title = tracking.isPartner
        ? SporingCopy.a1_sporing_leveres_av(tracking.deliveredByLabel)
        : (courier?.firstName ?? SporingCopy.a1_sporing_Budet);
    return Container(
      key: const Key('a1_sporing_bud_pill'),
      padding: EdgeInsets.fromLTRB(6 * s, 6 * s, 14 * s, 6 * s),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3323201D),
            offset: Offset(0, 8),
            blurRadius: 18,
            spreadRadius: -8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34 * s,
            height: 34 * s,
            decoration: const BoxDecoration(
              gradient: kBergenOrangeGradient,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: tracking.isPartner
                ? Icon(
                    Icons.storefront_rounded,
                    key: const Key('a1_sporing_bud_store_icon'),
                    color: Colors.white,
                    size: 18 * s,
                  )
                : (courier?.avatarUrl != null
                      ? Image.network(
                          courier!.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _initial(context, courier),
                        )
                      : _initial(context, courier)),
          ),
          SizedBox(width: 10 * s),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  key: const Key('a1_sporing_bud_navn'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: bText(
                    context,
                    12.5,
                    weight: FontWeight.w800,
                    color: BergenTokens.ink,
                  ),
                ),
                if (!tracking.isPartner && courier != null) ...[
                  if (courier.verified)
                    Row(
                      key: const Key('a1_sporing_bud_verifisert'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          size: 12 * s,
                          color: BergenTokens.mintDeep,
                        ),
                        SizedBox(width: 3 * s),
                        Text(
                          SporingCopy.a1_sporing_bankid,
                          style: bText(
                            context,
                            10,
                            weight: FontWeight.w700,
                            color: BergenTokens.mintDeep,
                          ),
                        ),
                      ],
                    ),
                  if (courier.vehicle != null)
                    Text(
                      courier.onBike
                          ? '🚲 ${courier.vehicle}'
                          : '🚗 ${courier.vehicle}',
                      key: const Key('a1_sporing_bud_kjoretoy'),
                      style: bText(
                        context,
                        10,
                        weight: FontWeight.w700,
                        color: BergenTokens.inkFaint,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _initial(BuildContext context, OpsCourier? c) => Center(
    child: Text(
      (c?.firstName.isNotEmpty ?? false) ? c!.firstName[0].toUpperCase() : 'B',
      style: bText(context, 14, weight: FontWeight.w800, color: Colors.white),
    ),
  );
}

/// The delivery code card.
class LeveringskodeCard extends StatelessWidget {
  const LeveringskodeCard({
    super.key,
    required this.code,
    this.offline = false,
    this.onDark = false,
  });

  final OpsDeliveryCode code;

  /// No connection: the visual code is dropped and only the PIN stays.
  final bool offline;
  final bool onDark;

  /// A stable 7×7 pattern from the payload — the design's "visual code".
  static List<bool> pattern(String payload) {
    var h = 0x811C9DC5;
    for (final unit in payload.codeUnits) {
      h ^= unit;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    final out = <bool>[];
    var x = h == 0 ? 0x9E3779B9 : h;
    for (var i = 0; i < 49; i++) {
      x ^= x << 13 & 0xFFFFFFFF;
      x ^= x >> 17;
      x ^= x << 5 & 0xFFFFFFFF;
      out.add((x & 1) == 1);
    }
    // Corners always set so a partial view still reads as a code.
    for (final i in const [0, 6, 42, 48]) {
      out[i] = true;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final pin = code.pin ?? '';
    final ink = onDark ? Colors.white : BergenTokens.ink;
    final sub = onDark ? const Color(0xFFDCE9EC) : BergenTokens.inkSecondary;
    return BergenCard(
      key: const Key('ops-delivery-code-card'),
      onDark: onDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            SporingCopy.a1_sporing_kode_tittel,
            style: bDisplay(context, 16, weight: FontWeight.w800, color: ink),
          ),
          SizedBox(height: 4 * s),
          Text(
            SporingCopy.reasonCopy(code.reasonCopyKey),
            key: const Key('ops-delivery-code-reason'),
            style: bText(context, 11.5, weight: FontWeight.w600, color: sub),
          ),
          SizedBox(height: 12 * s),
          Row(
            children: [
              if (!offline && code.qrPayload != null) ...[
                _Visual(
                  pattern: pattern(code.qrPayload!),
                  size: 84 * s,
                  onDark: onDark,
                ),
                SizedBox(width: 14 * s),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (pin.isNotEmpty)
                      Text(
                        pin.split('').join(' '),
                        key: const Key('ops-delivery-code-pin'),
                        style: bDisplay(
                          context,
                          30,
                          weight: FontWeight.w800,
                          color: ink,
                        ).copyWith(letterSpacing: 2),
                      ),
                    Text(
                      code.locked
                          ? SporingCopy.a1_sporing_kode_laast
                          : code.verifiedAt != null
                          ? SporingCopy.a1_sporing_kode_bekreftet
                          : offline
                          ? SporingCopy.a1_sporing_kode_offline
                          : SporingCopy.a1_sporing_kode_under,
                      key: Key(
                        offline
                            ? 'ops-delivery-code-offline'
                            : 'ops-delivery-code-under',
                      ),
                      style: bText(
                        context,
                        11,
                        weight: FontWeight.w600,
                        color: sub,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8 * s),
          Row(
            children: [
              Icon(Icons.door_front_door_outlined, size: 14 * s, color: sub),
              SizedBox(width: 6 * s),
              Expanded(
                child: Text(
                  SporingCopy.a1_sporing_kode_no_door,
                  key: const Key('ops-delivery-code-no-leave-at-door'),
                  style: bText(
                    context,
                    10.5,
                    weight: FontWeight.w600,
                    color: sub,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Visual extends StatelessWidget {
  const _Visual({
    required this.pattern,
    required this.size,
    required this.onDark,
  });

  final List<bool> pattern;
  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final cell = size / 7;
    return Container(
      key: const Key('ops-delivery-code-qr'),
      width: size,
      height: size,
      padding: EdgeInsets.all(cell * .25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BergenTokens.paperWarm),
      ),
      child: GridView.count(
        crossAxisCount: 7,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          for (final on in pattern)
            DecoratedBox(
              decoration: BoxDecoration(
                color: on ? BergenTokens.ink : Colors.transparent,
              ),
            ),
        ],
      ),
    );
  }
}

/// "Valg som venter": the store has not looked past the first rung.
class ValgSomVenterCard extends StatelessWidget {
  const ValgSomVenterCard({
    super.key,
    required this.storeName,
    required this.onWait,
    required this.onCancel,
  });

  final String storeName;
  final VoidCallback onWait;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return BergenCard(
      key: const Key('a1_sporing_valg'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            SporingCopy.a1_sporing_valg_tittel(storeName),
            style: bDisplay(
              context,
              15,
              weight: FontWeight.w800,
              color: BergenTokens.ink,
            ),
          ),
          SizedBox(height: 4 * s),
          Text(
            SporingCopy.a1_sporing_valg_line,
            style: bText(
              context,
              11.5,
              weight: FontWeight.w600,
              color: BergenTokens.inkSecondary,
            ),
          ),
          SizedBox(height: 12 * s),
          Row(
            children: [
              Expanded(
                child: BergenCta3d(
                  key: const Key('a1_sporing_valg_vent'),
                  label: SporingCopy.a1_sporing_vent,
                  onPressed: onWait,
                ),
              ),
              SizedBox(width: 8 * s),
              BergenChip(
                key: const Key('a1_sporing_valg_avbestill'),
                label: SporingCopy.a1_sporing_avbestill,
                onTap: onCancel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
