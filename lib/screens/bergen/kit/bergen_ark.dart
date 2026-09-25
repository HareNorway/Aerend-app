import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/bergen_tokens.dart';
import 'bergen_cta_3d.dart';
import 'bergen_sheet.dart';
import 'bergen_toast.dart';

/// One row of an Ark (design `.ark-rad`): label, optional value/trailing
/// text, optional leading icon, optional tap.
class BergenArkRow {
  const BergenArkRow({
    required this.label,
    this.value,
    this.trailing,
    this.icon,
    this.onTap,
  });

  final String label;
  final String? value;
  final String? trailing;
  final IconData? icon;
  final VoidCallback? onTap;
}

/// A CTA on an Ark. The primary one renders as the orange 3D button.
class BergenArkAction {
  const BergenArkAction({required this.label, required this.onTap, this.icon});

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
}

/// The generic `Ark {{ kArkTittel }}` sheet (design ≈L7332–7559): title,
/// subtitle, close, an optional copy block with "Kopier", list rows, a body
/// slot, and secondary + primary CTAs. Every branch builds its sheets from
/// this so nobody makes a second sheet component (contract §4.3).
class BergenArk extends StatelessWidget {
  const BergenArk({
    super.key,
    required this.title,
    this.subtitle,
    this.copyText,
    this.copyLabel = 'Kopier',
    this.copiedToast = 'Kopiert',
    this.rows = const [],
    this.body,
    this.primary,
    this.secondary,
    this.onClose,
    this.onDark = false,
  });

  final String title;
  final String? subtitle;

  /// A code or address the person may want on the clipboard.
  final String? copyText;
  final String copyLabel;
  final String copiedToast;
  final List<BergenArkRow> rows;
  final Widget? body;
  final BergenArkAction? primary;
  final BergenArkAction? secondary;
  final VoidCallback? onClose;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final ink = onDark ? Colors.white : BergenTokens.ink;
    final soft = onDark ? BergenTokens.glassBorder : BergenTokens.paperWarm;
    final muted = onDark ? const Color(0xFFDCE9EC) : BergenTokens.inkSecondary;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: BergenTokens.display(
                        BergenTokens.textTitle,
                        color: ink,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: BergenTokens.text(
                          BergenTokens.textBody,
                          weight: FontWeight.w500,
                          color: muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Lukk',
                onPressed: onClose ?? () => Navigator.of(context).maybePop(),
                icon: Icon(Icons.close_rounded, color: ink),
              ),
            ],
          ),
          if (copyText != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
              decoration: BoxDecoration(
                color: onDark ? BergenTokens.glassFill : BergenTokens.paperBright,
                borderRadius: BorderRadius.circular(BergenTokens.radiusButton),
                border: Border.all(color: soft),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      copyText!,
                      style: BergenTokens.display(
                        BergenTokens.textSection,
                        color: ink,
                        letterSpacingEm: .04,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: copyText!));
                      if (context.mounted) {
                        showBergenToast(
                          context,
                          copiedToast,
                          icon: Icons.check_rounded,
                        );
                      }
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: Text(copyLabel),
                    style: TextButton.styleFrom(
                      foregroundColor: BergenTokens.orangeHover,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (rows.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final row in rows)
              _ArkRowTile(row: row, ink: ink, muted: muted, divider: soft),
          ],
          if (body != null) ...[const SizedBox(height: 12), body!],
          if (primary != null || secondary != null) const SizedBox(height: 16),
          if (secondary != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton.icon(
                onPressed: secondary!.onTap,
                icon: secondary!.icon == null
                    ? const SizedBox.shrink()
                    : Icon(secondary!.icon, size: 18),
                label: Text(secondary!.label),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ink,
                  side: BorderSide(color: soft),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      BergenTokens.radiusButton,
                    ),
                  ),
                  textStyle: BergenTokens.display(
                    BergenTokens.textBody,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          if (primary != null)
            BergenCta3d(
              label: primary!.label,
              icon: primary!.icon,
              onPressed: primary!.onTap,
            ),
        ],
      ),
    );
  }
}

class _ArkRowTile extends StatelessWidget {
  const _ArkRowTile({
    required this.row,
    required this.ink,
    required this.muted,
    required this.divider,
  });

  final BergenArkRow row;
  final Color ink;
  final Color muted;
  final Color divider;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: row.onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: divider)),
        ),
        child: Row(
          children: [
            if (row.icon != null) ...[
              Icon(row.icon, size: 18, color: muted),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.label,
                    style: BergenTokens.text(
                      BergenTokens.textBody,
                      weight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                  if (row.value != null)
                    Text(
                      row.value!,
                      style: BergenTokens.text(
                        BergenTokens.textSmall,
                        weight: FontWeight.w500,
                        color: muted,
                      ),
                    ),
                ],
              ),
            ),
            if (row.trailing != null)
              Text(
                row.trailing!,
                style: BergenTokens.text(
                  BergenTokens.textSmall,
                  weight: FontWeight.w700,
                  color: muted,
                ),
              ),
            if (row.onTap != null)
              Icon(Icons.chevron_right_rounded, color: muted),
          ],
        ),
      ),
    );
  }
}

/// Present a [BergenArk] in a [BergenSheet].
Future<T?> showBergenArk<T>(
  BuildContext context, {
  required String title,
  String? subtitle,
  String? copyText,
  List<BergenArkRow> rows = const [],
  Widget? body,
  BergenArkAction? primary,
  BergenArkAction? secondary,
  bool onDark = false,
}) {
  return showBergenSheet<T>(
    context,
    onDark: onDark,
    builder: (ctx) => BergenArk(
      title: title,
      subtitle: subtitle,
      copyText: copyText,
      rows: rows,
      body: body,
      primary: primary,
      secondary: secondary,
      onDark: onDark,
    ),
  );
}
