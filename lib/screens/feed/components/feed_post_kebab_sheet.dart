import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../../networking/feed/feed_repo.dart';
import '../../../utils/utils.dart';

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
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.feed_coming_soon)),
              );
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
