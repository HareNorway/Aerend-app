import 'package:flutter/material.dart';
import '../../../data/feed/feed_store.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import 'feed_avatar.dart';

class FeedSearchResultTile extends StatelessWidget {
  final FeedStore store;
  final VoidCallback onTap;

  const FeedSearchResultTile({
    super.key,
    required this.store,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final letter =
        store.name.isNotEmpty ? store.name[0].toUpperCase() : '?';

    return ListTile(
      onTap: onTap,
      leading: FeedAvatar(
        imageUrl: store.logoUrl,
        fallbackLetter: letter,
        radius: 20,
        backgroundColor: ScSaasThemeTokens.card,
        fallbackTextColor: ScSaasThemeTokens.primary,
        useLetterFallback: true,
      ),
      title: Text(
        store.name,
        style: aeLabel(color: ScSaasThemeTokens.text).copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '@${store.slug}',
        style: aeCaption(color: ScSaasThemeTokens.muted).copyWith(fontSize: 13),
      ),
      trailing: store.isFollowing
          ? Icon(Icons.check_circle, color: ScSaasThemeTokens.primary, size: 20)
          : null,
    );
  }
}
