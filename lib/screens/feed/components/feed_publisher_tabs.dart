import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/sc_saas_theme.dart';

/// Who published a post: the two customer-facing feed tabs (feed update spec
/// §3.1, `Kunde Bergen` design).
enum FeedPublisherTab {
  /// «Publisert av butikker»
  stores,

  /// «Publisert av Ærend»
  aerend,
}

/// The publisher tab strip.
///
/// The split is a promise, not a filing system: a customer should be able to
/// tell at a glance whether they are reading a shop or reading us. Mixing the
/// two without saying so is how a feed stops being trusted — and it is also
/// why the ranking limits how often our own posts appear in the main feed.
class FeedPublisherTabs extends StatelessWidget {
  const FeedPublisherTabs({
    super.key,
    required this.active,
    required this.onSelected,
  });

  final FeedPublisherTab active;
  final ValueChanged<FeedPublisherTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Padding(
      key: const Key('feed_publisher_tabs'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: <Widget>[
          _Tab(
            label: l10n.feed_tab_stores,
            isActive: active == FeedPublisherTab.stores,
            tabKey: 'feed_tab_stores',
            onTap: () => onSelected(FeedPublisherTab.stores),
          ),
          const SizedBox(width: 8),
          _Tab(
            label: l10n.feed_tab_aerend,
            isActive: active == FeedPublisherTab.aerend,
            tabKey: 'feed_tab_aerend',
            onTap: () => onSelected(FeedPublisherTab.aerend),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.isActive,
    required this.tabKey,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final String tabKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        key: Key(tabKey),
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive
                ? ScSaasThemeTokens.primary
                : ScSaasThemeTokens.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: isActive ? Colors.white : ScSaasThemeTokens.primary,
            ),
          ),
        ),
      ),
    );
  }
}

/// The category chips under the tabs.
///
/// The list comes from config rather than being hard-coded: categories are a
/// commercial decision that changes without an app release, and a chip strip
/// that needs a store review to edit is a chip strip that goes stale.
class FeedCategoryChips extends StatelessWidget {
  const FeedCategoryChips({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  /// `(slug, label)` pairs, in the order they should appear.
  final List<FeedCategory> categories;

  /// Null means "Alle" — no filter.
  final String? selected;

  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      key: const Key('feed_category_chips'),
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              key: const Key('feed_category_all'),
              label: Text(l10n.feed_category_all),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          ...categories.map(
            (FeedCategory c) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                key: Key('feed_category_${c.slug}'),
                label: Text(c.label),
                selected: selected == c.slug,
                onSelected: (_) => onSelected(c.slug),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One category, as the server describes it.
class FeedCategory {
  const FeedCategory({required this.slug, required this.label});

  final String slug;
  final String label;

  static FeedCategory fromJson(Map<String, dynamic> json) => FeedCategory(
        slug: json['slug'].toString(),
        label: (json['label'] ?? json['slug']).toString(),
      );
}
