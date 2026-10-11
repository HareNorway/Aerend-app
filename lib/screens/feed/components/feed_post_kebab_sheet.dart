import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../../networking/feed/feed_repo.dart';
import '../../../theme/bergen_tokens.dart';
import '../../bergen/kit/bergen_sheet.dart';
import '../../bergen/kit/bergen_toast.dart';
import '../../../utils/utils.dart';

/// Why a post is reported (`POST /v1/posts/:id/report`, backend plan
/// Step 9): the wire value and the Norwegian label.
const List<(String, String)> kFeedReportReasons = [
  ('misleading', 'Villedende eller feil'),
  ('wrong_price', 'Feil pris'),
  ('offensive', 'Støtende'),
  ('spam', 'Spam'),
  ('other', 'Noe annet'),
];

/// The reasons sheet: [title], [subtitle], then one row per reason. The
/// chosen wire value, or null when the sheet is dismissed.
Future<String?> _askReportReason(BuildContext context, {required String title, required String subtitle}) {
  return showBergenSheet<String>(
    context,
    builder: (sheet) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            title,
            style: BergenTokens.display(BergenTokens.textSection, color: BergenTokens.ink),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            subtitle,
            style: BergenTokens.text(BergenTokens.textSmall, color: BergenTokens.inkSecondary),
          ),
        ),
        for (final (key, label) in kFeedReportReasons)
          InkWell(
            key: Key('feed-report-$key'),
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.pop(sheet, key),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
              child: Text(label, style: BergenTokens.text(BergenTokens.textBody, weight: FontWeight.w700, color: BergenTokens.ink)),
            ),
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
