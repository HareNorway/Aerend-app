import 'package:flutter/material.dart';
import '../../../data/feed/feed_store_profile.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import 'feed_follow_button.dart';
import 'feed_store_story_avatar.dart';
import 'feed_visit_store_button.dart';

class FeedStoreProfileHeader extends StatelessWidget {
  final FeedStoreProfile profile;
  final bool followInFlight;
  final bool visitInFlight;
  final VoidCallback onFollowTap;
  final VoidCallback onVisitStoreTap;
  final VoidCallback? onStoryTap;

  const FeedStoreProfileHeader({
    super.key,
    required this.profile,
    required this.onFollowTap,
    required this.onVisitStoreTap,
    this.onStoryTap,
    this.followInFlight = false,
    this.visitInFlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final letter =
        profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?';
    final postsLabel = _capitalize(l10n.store_profile_posts);
    final followersLabel = _capitalize(l10n.store_profile_followers);
    final subtitle = _subtitle(profile, l10n);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ScSaasThemeTokens.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ScSaasThemeTokens.border),
        boxShadow: [
          BoxShadow(
            color: ScSaasThemeTokens.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              FeedStoreStoryAvatar(
                imageUrl: profile.logoUrl,
                fallbackLetter: letter,
                hasActiveStory: profile.hasActiveStories,
                onTap: profile.hasActiveStories ? onStoryTap : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    _StatColumn(
                      count: '${profile.postCount}',
                      label: postsLabel,
                    ),
                    const _StatDivider(),
                    _StatColumn(
                      count: '${profile.followerCount}',
                      label: followersLabel,
                    ),
                    const _StatDivider(),
                    const _StatColumn(count: '—', label: 'Following'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            profile.name,
            style: aeH3(color: ScSaasThemeTokens.text),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: aeCaption(color: ScSaasThemeTokens.muted).copyWith(fontSize: 13, height: 1.35),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FeedFollowButton(
                  isFollowing: profile.isFollowing,
                  isInFlight: followInFlight,
                  onTap: onFollowTap,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FeedVisitStoreButton(
                  isLoading: visitInFlight,
                  onTap: onVisitStoreTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _subtitle(FeedStoreProfile profile, AppLocalizations l10n) {
    if (profile.bio != null && profile.bio!.trim().isNotEmpty) {
      return profile.bio!.trim();
    }
    if (profile.description != null && profile.description!.trim().isNotEmpty) {
      return profile.description!.trim();
    }
    if (profile.hasActiveStories) {
      return l10n.feed_store_profile_story_hint;
    }
    return l10n.feed_store_profile_default_hint;
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}

class _StatColumn extends StatelessWidget {
  final String count;
  final String label;

  const _StatColumn({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            count,
            style: aeH2(color: ScSaasThemeTokens.text).copyWith(fontSize: 20),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: aeLabel(color: ScSaasThemeTokens.muted).copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: ScSaasThemeTokens.border,
    );
  }
}
