import 'package:flutter/material.dart';

import '../../../data/aegil/chat_card_models.dart';
import '../../../theme/reen_pre_club_theme.dart';

/// Chat card types from `designs/Ægil-chatten - tweaks.dc.html` (AGIL-2 Phase 9).
///
/// All of them are read models or small writes the customer could make anywhere else in the
/// app. Nothing here can spend money, change a level or write a hard constraint — those tools
/// are not in the chat allowlist at all.

/// T07 — the shopping list.
class ShoppingListCard extends StatelessWidget {
  const ShoppingListCard({
    super.key,
    required this.items,
    this.onToggle,
    this.onRemove,
  });

  final List<ShoppingListItem> items;
  final void Function(ShoppingListItem item)? onToggle;
  final void Function(ShoppingListItem item)? onRemove;

  @override
  Widget build(BuildContext context) {
    return _card(
      key: const Key('chat-shopping-list'),
      heading: 'HANDLELISTE',
      child: items.isEmpty
          ? const Text(
              'Listen er tom.',
              key: Key('chat-shopping-list-empty'),
              style: TextStyle(fontSize: 12.5, color: AerendBergenAuthTokens.textSoft),
            )
          : Column(
              children: [
                for (final item in items)
                  Row(
                    key: Key('chat-shopping-item-${item.id}'),
                    children: [
                      GestureDetector(
                        key: Key('chat-shopping-toggle-${item.id}'),
                        onTap: onToggle == null ? null : () => onToggle!(item),
                        child: Icon(
                          item.done ? Icons.check_box : Icons.check_box_outline_blank,
                          size: 18,
                          color: item.done
                              ? AerendBergenAuthTokens.mint
                              : AerendBergenAuthTokens.textMuted,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.qty > 1 ? '${item.text} × ${item.qty}' : item.text,
                          style: TextStyle(
                            fontSize: 13,
                            decoration: item.done ? TextDecoration.lineThrough : null,
                            color: item.done
                                ? AerendBergenAuthTokens.textMuted
                                : AerendBergenAuthTokens.ink,
                          ),
                        ),
                      ),
                      // So the customer can tell what Ægil put there from what they typed.
                      if (item.addedByAgent)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Text(
                            'Ægil',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: AerendBergenAuthTokens.mint,
                            ),
                          ),
                        ),
                      if (onRemove != null)
                        IconButton(
                          key: Key('chat-shopping-remove-${item.id}'),
                          icon: const Icon(Icons.close, size: 14,
                              color: AerendBergenAuthTokens.textMuted),
                          onPressed: () => onRemove!(item),
                        ),
                    ],
                  ),
              ],
            ),
    );
  }
}

/// The comparison card.
///
/// Always shows the size, and repeats the backend's note when the packs differ — "cheaper"
/// without "per what?" is how you tell someone a 300 g jar beats a 500 g one.
class ComparisonCard extends StatelessWidget {
  const ComparisonCard({super.key, required this.comparison});

  final Comparison comparison;

  @override
  Widget build(BuildContext context) {
    return _card(
      key: const Key('chat-comparison'),
      heading: 'SAMMENLIGNING',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final product in comparison.products)
            Padding(
              key: Key('chat-comparison-${product.productIdentityId}'),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  if (product.productIdentityId == comparison.cheapestId)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(Icons.star, size: 13,
                          color: AerendBergenAuthTokens.mint),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AerendBergenAuthTokens.ink,
                          ),
                        ),
                        if (product.sizeLabel != null)
                          Text(
                            product.sizeLabel!,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AerendBergenAuthTokens.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (product.priceOre != null)
                    Text(
                      '${(product.priceOre! / 100).round()} kr',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AerendBergenAuthTokens.ink,
                      ),
                    ),
                ],
              ),
            ),
          if (comparison.note != null) ...[
            const SizedBox(height: 8),
            Text(
              comparison.note!,
              key: const Key('chat-comparison-note'),
              style: const TextStyle(
                fontSize: 11.5,
                color: AerendBergenAuthTokens.textSoft,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// T08 — the news card, built from the feed service's read-only post detail.
class NewsCard extends StatelessWidget {
  const NewsCard({
    super.key,
    required this.headline,
    this.storeName,
    this.body,
    this.onOpen,
  });

  final String headline;
  final String? storeName;
  final String? body;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      child: _card(
        key: const Key('chat-news-card'),
        heading: storeName == null ? 'FRA FEEDEN' : storeName!.toUpperCase(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              headline,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AerendBergenAuthTokens.ink,
              ),
            ),
            if (body != null) ...[
              const SizedBox(height: 4),
              Text(
                body!,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: AerendBergenAuthTokens.textSoft,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Hvordan får jeg poeng?"
class PointsExplainerCard extends StatelessWidget {
  const PointsExplainerCard({super.key, required this.explainer});

  final PointsExplainer explainer;

  @override
  Widget build(BuildContext context) {
    return _card(
      key: const Key('chat-points-explainer'),
      heading: 'SLIK FÅR DU POENG',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final rule in explainer.rules)
            Padding(
              key: Key('chat-explainer-${rule.key}'),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rule.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AerendBergenAuthTokens.ink,
                    ),
                  ),
                  Text(
                    rule.body,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AerendBergenAuthTokens.textSoft,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(
            explainer.expiry,
            style: const TextStyle(
              fontSize: 11.5,
              color: AerendBergenAuthTokens.textMuted,
            ),
          ),
          if (explainer.tierNote.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                explainer.tierNote,
                key: const Key('chat-explainer-tier-note'),
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AerendBergenAuthTokens.textSubtitle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// What Ægil says when asked to do something above the customer's level.
///
/// The refusal names the level and what it means, because "I can't do that" teaches nothing.
class LevelRefusalCard extends StatelessWidget {
  const LevelRefusalCard({super.key, required this.refusal, this.onOpenSettings});

  final ToolRefusal refusal;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return _card(
      key: const Key('chat-level-refusal'),
      heading: 'DET KAN IKKE ÆGIL ENNÅ',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            refusal.copy,
            key: const Key('chat-level-refusal-copy'),
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AerendBergenAuthTokens.ink,
            ),
          ),
          if (refusal.isLevelIssue && onOpenSettings != null) ...[
            const SizedBox(height: 10),
            TextButton(
              key: const Key('chat-level-refusal-settings'),
              onPressed: onOpenSettings,
              child: const Text(
                'Åpne innstillinger',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AerendBergenAuthTokens.orange,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Widget _card({required Key key, required String heading, required Widget child}) {
  return Container(
    key: key,
    margin: const EdgeInsets.symmetric(vertical: 6),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AerendBergenAuthTokens.glassFill,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AerendBergenAuthTokens.glassBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: AerendBergenAuthTokens.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    ),
  );
}
