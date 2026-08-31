import 'package:flutter/material.dart';

import '../../screens/common/auth/auth_style.dart';
import '../../screens/deliveryService/checkout/checkout_dl.dart';
import '../../screens/dugnad/widgets/dugnad_confirm_sheet.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/utils.dart';

/// `.dgd-promo` — lavender row with a dashed purple-300 outline: white code
/// chip (12/800, .04em, purple-700, radius 8, 6×9), title 13.5/800 midnight +
/// sub 11.5/600 gray-500, trailing "Bruk" 12.5/800 purple-700.
class ItemPromoCodeList extends StatelessWidget {
  final Function() onClickApplyPromo;
  final PromoCodeListItem? promocodeListItem;

  const ItemPromoCodeList({
    super.key,
    required this.onClickApplyPromo,
    this.promocodeListItem,
  });

  @override
  Widget build(BuildContext context) {
    final item = promocodeListItem;
    final theme = Theme.of(context).textTheme.bodyMedium;
    final subtitle = (item?.minOrderAmount ?? 0) > 0
        ? '${languages.minOrder} ${getAmountWithCurrency(item!.minOrderAmount)}'
        : (item?.promocodeDescription ?? '');
    final title = (item?.promocodeDescription ?? '').trim().isNotEmpty
        ? item!.promocodeDescription
        : (item?.promocodeName ?? '');

    return AuthPressable(
      onTap: onClickApplyPromo,
      builder: (context, pressed) => DugnadDashedBorder(
        radius: 14,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 13),
          decoration: BoxDecoration(
            color: ScSaasThemeTokens.background, // --ae-lavender
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item?.promocodeName ?? '',
                  style: theme?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 12 * 0.04,
                        color: ScSaasThemeTokens.primaryHover,
                      ) ??
                      const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: ScSaasThemeTokens.primaryHover,
                      ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme?.copyWith(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: ScSaasThemeTokens.text,
                          ) ??
                          const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: ScSaasThemeTokens.text,
                          ),
                    ),
                    if (subtitle.trim().isNotEmpty && subtitle != title)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme?.copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: ScSaasThemeTokens.gray500,
                            ) ??
                            const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: ScSaasThemeTokens.gray500,
                            ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 11),
              Text(
                languages.apply,
                style: theme?.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: ScSaasThemeTokens.primaryHover,
                    ) ??
                    const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: ScSaasThemeTokens.primaryHover,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
