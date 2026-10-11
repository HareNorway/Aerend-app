import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

/// Line icons for the reasons (24 px grid, 2.2 stroke, as the prototype's).
const Map<String, String> _reasonIcon = {
  'misleading': '<circle cx="12" cy="12" r="8.5"/><path d="M12 7.8v5M12 16.2h.01"/>',
  'wrong_price': '<path d="M3.5 12.2V4.5h7.7l9.3 9.3-7.7 7.7z"/><circle cx="8" cy="9" r="1.4"/>',
  'offensive': '<path d="M4 5h16v11H9l-5 4z"/><path d="M10 8.5l4 4M14 8.5l-4 4"/>',
  'spam': '<rect x="3.5" y="5.5" width="17" height="13" rx="2"/><path d="M4 7l8 6 8-6"/>',
  'other': '<circle cx="6" cy="12" r="1.3"/><circle cx="12" cy="12" r="1.3"/><circle cx="18" cy="12" r="1.3"/>',
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
            leading: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFEAF2F4), Color(0xFFD2E1E5)]),
              ),
              child: SvgPicture.string(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#1E4F5C" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">${_reasonIcon[key] ?? ''}</svg>',
                width: 17,
                height: 17,
              ),
            ),
            trailing: SvgPicture.string(
              '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#8C847C" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M9 5l7 7-7 7"/></svg>',
              width: 14,
              height: 14,
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
