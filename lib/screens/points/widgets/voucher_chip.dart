import 'package:flutter/material.dart';

import '../../../data/points/points_models.dart';
import '../../../theme/bergen_tokens.dart';

/// The chip that appears in checkout when a claimed voucher will be applied to this order.
///
/// Only auto-apply vouchers reach here. A code prize is shown in the shop by the customer, so
/// applying it silently at checkout would be wrong — the backend already refuses to offer one.
class VoucherChip extends StatelessWidget {
  const VoucherChip({super.key, required this.claim, this.onRemove});

  final PrizeClaim claim;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('checkout-voucher-chip'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AerendBergenAuthTokens.mint.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AerendBergenAuthTokens.mint.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_activity_outlined,
            size: 15,
            color: AerendBergenAuthTokens.mintDeep,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              claim.prizeName ?? 'Premie',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AerendBergenAuthTokens.ink,
              ),
            ),
          ),
          if (claim.isGift) ...[
            const SizedBox(width: 6),
            const Text(
              '· gave',
              style: TextStyle(
                fontSize: 11.5,
                color: AerendBergenAuthTokens.textSoft,
              ),
            ),
          ],
          if (onRemove != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              key: const Key('checkout-voucher-remove'),
              onTap: onRemove,
              child: const Icon(
                Icons.close,
                size: 14,
                color: AerendBergenAuthTokens.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
