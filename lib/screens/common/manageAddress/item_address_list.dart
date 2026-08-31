import 'package:flutter/material.dart';

import '../../../ui/kit/ae_theme.dart';
import '../../../utils/utils.dart';
import '../address_order_chrome.dart';
import '../../../ui/kit/ae_inline_address.dart';
import 'manage_address_dl.dart';

/// Address card plus `.oh-acts` Endre / Slett row beneath it.
class ItemAddressList extends StatelessWidget {
  final AddressListItem addressListItem;
  final VoidCallback onPressEdit;
  final VoidCallback onPressDelete;
  final VoidCallback onPressSelect;
  final bool showSelect;
  final bool isSelected;
  final bool isDefault;
  final bool enabled;

  const ItemAddressList({
    super.key,
    required this.showSelect,
    required this.addressListItem,
    required this.onPressEdit,
    required this.onPressDelete,
    required this.onPressSelect,
    this.isSelected = false,
    this.isDefault = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AeAddressPickCard(
          address: addressListItem,
          selected: isSelected || isDefault,
          enabled: enabled,
          showCheckWhenSelected: false,
          onTap: showSelect ? onPressSelect : null,
        ),
        const SizedBox(height: 8),
        IgnorePointer(
          ignoring: !enabled,
          child: Opacity(
            opacity: enabled ? 1 : 0.55,
            child: AoActionsRow(
              children: [
                AoActionButton(
                  kind: AoActionKind.review,
                  icon: Icons.edit_outlined,
                  label: languages.campaignChange,
                  color: theme.primaryHover,
                  onTap: onPressEdit,
                ),
                AoActionButton(
                  kind: AoActionKind.cancel,
                  icon: Icons.delete_outline_rounded,
                  label: languages.delete,
                  onTap: onPressDelete,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
