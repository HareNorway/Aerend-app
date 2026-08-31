import 'package:flutter/material.dart';
import 'package:aerend_customer/theme/sc_saas_theme.dart';

class ModalUi {
  static Widget handle() {
    return Center(
      child: Container(
        width: 44,
        height: 5,
        decoration: BoxDecoration(
          color: ScSaasThemeTokens.border,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  static Widget sheetHeader(
    BuildContext context, {
    required String title,
    VoidCallback? onClose,
    double titleSize = 24,
  }) {
    return Column(
      children: [
        handle(),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                softWrap: true,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (onClose != null)
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: ScSaasThemeTokens.border),
                  ),
                  child: const Icon(Icons.close, size: 22),
                ),
              ),
          ],
        ),
      ],
    );
  }

  static Widget actionRow(
    BuildContext context, {
    required String primaryLabel,
    required VoidCallback onPrimaryPressed,
    String secondaryLabel = 'Cancel',
    VoidCallback? onSecondaryPressed,
  }) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: onSecondaryPressed ?? () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                foregroundColor: ScSaasThemeTokens.primary,
                backgroundColor: ScSaasThemeTokens.rowHover,
                side: const BorderSide(color: ScSaasThemeTokens.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(secondaryLabel),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: onPrimaryPressed,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: ScSaasThemeTokens.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(primaryLabel),
            ),
          ),
        ),
      ],
    );
  }
}
