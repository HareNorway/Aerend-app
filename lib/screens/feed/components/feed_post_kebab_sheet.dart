import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../../networking/feed/feed_repo.dart';
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

/// Ask why, then report. The answer is a short word, never an error page: a
/// second report from the same customer counts once on the server.
Future<void> reportFeedPost(BuildContext context, String postId, {FeedRepo? repo}) async {
  final reason = await showModalBottomSheet<String>(
    context: context,
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(title: Text('Hvorfor rapporterer du innlegget?', style: TextStyle(fontWeight: FontWeight.w700))),
          for (final (key, label) in kFeedReportReasons)
            ListTile(
              key: Key('feed-report-$key'),
              title: Text(label),
              onTap: () => Navigator.pop(sheet, key),
            ),
        ],
      ),
    ),
  );
  if (reason == null || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  try {
    final first = await (repo ?? FeedRepo()).reportPost(postId, reason: reason);
    messenger.showSnackBar(SnackBar(
      content: Text(first ? 'Takk! Vi ser på innlegget.' : 'Du har allerede rapportert dette innlegget.'),
    ));
  } catch (_) {
    messenger.showSnackBar(const SnackBar(content: Text('Kunne ikke sende rapporten. Prøv igjen.')));
  }
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
