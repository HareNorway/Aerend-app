import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../../networking/feed/feed_repo.dart';
import '../../bergen/meg/meg_ark.dart';
import '../../bergen/kit/bergen_toast.dart';
import '../../../utils/utils.dart';

/// Why a post is reported (`POST /v1/posts/:id/report`, backend plan
/// Step 9): the wire value, the Norwegian label and a line icon.
const List<(String, String)> kFeedReportReasons = [
  ('misleading', 'Villedende eller feil'),
  ('wrong_price', 'Feil pris'),
  ('offensive', 'Støtende'),
  ('spam', 'Spam'),
  ('other', 'Noe annet'),
];

/// Line icons for the reasons (24 px grid path data, as the prototype's).
const Map<String, String> _reasonIcon = {
  'misleading': 'M3.5 12a8.5 8.5 0 1 0 17 0a8.5 8.5 0 1 0 -17 0M12 7.8v5M12 16.2h.01',
  'wrong_price': 'M3.5 12.2V4.5h7.7l9.3 9.3-7.7 7.7zM6.6 9a1.4 1.4 0 1 0 2.8 0a1.4 1.4 0 1 0 -2.8 0',
  'offensive': 'M4 5h16v11H9l-5 4zM10 8.5l4 4M14 8.5l-4 4',
  'spam': 'M5.5 5.5h13a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2h-13a2 2 0 0 1-2-2v-9a2 2 0 0 1 2-2zM4 7l8 6 8-6',
  'other': 'M6 11.95v.1M12 11.95v.1M18 11.95v.1',
};

/// The reasons sheet — the prototype's Ark (`kVisArk`, [MegArk]): [title],
/// [subtitle], then one row per reason; a tap chooses and sends. The chosen
/// wire value, or null when the sheet is dismissed. Not in the prototype
/// (needs design sign-off): reporting is an app-store requirement.
Future<String?> _askReportReason(BuildContext context, {required String title, required String subtitle}) {
  return showMegArk<String>(
    context,
    title: title,
    subtitle: subtitle,
    body: (sheet, _) => Column(
      children: [
        for (final (key, label) in kFeedReportReasons)
          MegArkRow(
            key: Key('feed-report-$key'),
            title: label,
            onTap: () => Navigator.pop(sheet, key),
            // The design's `harIkon` tile; the chevron key comes with the tap.
            leading: MegArkIkon(_reasonIcon[key] ?? ''),
          ),
      ],
    ),
  );
}

/// Sends the report and says how it went in a toast: [thanks] for the first
/// report, [again] for a repeat, the same failure line for both kinds.
Future<void> _sendReport(BuildContext context, Future<bool> Function() send, {required String thanks, required String again}) async {
  try {
    final first = await send();
    if (!context.mounted) return;
    showBergenToast(context, first ? thanks : again, icon: Icons.outlined_flag);
  } catch (_) {
    if (context.mounted) showBergenToast(context, 'Kunne ikke sende rapporten. Prøv igjen.', icon: Icons.error_outline_rounded);
  }
}

/// Ask why, then report. The answer is a short word, never an error page: a
/// second report from the same customer counts once on the server.
/// In the Bergen sheet and toast, like the screens it is opened from.
Future<void> reportFeedPost(BuildContext context, String postId, {FeedRepo? repo}) async {
  final reason = await _askReportReason(
    context,
    title: 'Hvorfor rapporterer du innlegget?',
    subtitle: 'Ærend ser på det. Butikken får ikke vite hvem som rapporterte.',
  );
  if (reason == null || !context.mounted) return;
  await _sendReport(
    context,
    () => (repo ?? FeedRepo()).reportPost(postId, reason: reason),
    thanks: 'Takk! Vi ser på innlegget.',
    again: 'Du har allerede rapportert dette innlegget.',
  );
}

/// «Rapporter kommentar» (`POST /v1/comments/:id/report`, backend plan
/// Step 13): the post's reasons sheet, then a toast.
Future<void> reportFeedComment(BuildContext context, String commentId, {FeedRepo? repo}) async {
  final reason = await _askReportReason(
    context,
    title: 'Hvorfor rapporterer du kommentaren?',
    subtitle: 'Ærend ser på det. Den som skrev den får ikke vite hvem som rapporterte.',
  );
  if (reason == null || !context.mounted) return;
  await _sendReport(
    context,
    () => (repo ?? FeedRepo()).reportComment(commentId, reason: reason),
    thanks: 'Takk! Vi ser på kommentaren.',
    again: 'Du har allerede rapportert denne kommentaren.',
  );
}

class FeedPostKebabSheet extends StatelessWidget {
  final String postId;
  final FeedRepo repo;

  FeedPostKebabSheet({
    super.key,
    required this.postId,
    FeedRepo? repo,
  }) : repo = repo ?? FeedRepo();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: Text(l10n.feed_post_kebab_report),
            onTap: () {
              // The sheet's parent context outlives the sheet.
              final parent = Navigator.of(context).context;
              Navigator.pop(context);
              reportFeedPost(parent, postId, repo: repo);
            },
          ),
          ListTile(
            leading: const Icon(Icons.link),
            title: Text(l10n.feed_post_kebab_copy_link),
            onTap: () async {
              Navigator.pop(context);
              try {
                final cta = await repo.resolveCta(postId);
                await Clipboard.setData(ClipboardData(text: cta.webUrl));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.feed_post_kebab_link_copied)),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  openSimpleSnackbar(
                    e.toString(),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
