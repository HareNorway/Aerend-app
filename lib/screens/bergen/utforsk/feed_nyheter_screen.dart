import 'package:flutter/material.dart';

import '../../../data/feed/feed_tab_item.dart';
import '../../../networking/feed/feed_cloudinary_config.dart';
import '../../../networking/feed/feed_repo.dart';
import '../../common/auth/onboarding_kit.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../../feed/postDetail/post_detail.dart';
import '../../feed/utils/feed_time_ago.dart';
import '../../../utils/utils.dart';
import '../kit/bergen_kit.dart';
import 'utforsk_copy.dart';

/// `feed` — "Nytt fra butikkene" (≈L6643 in `Ærend Kunde Bergen.dc.html`).
///
/// The light-paper list of today's posts from the shops near the customer:
/// time, shop, the «Bergensk» dot, the text, and a «Bestill · N kr» button
/// where the post has a product with a live price, else «Se». Reached from
/// Meg's row (agil-3 pushes `/bergen/utforsk?tab=feed`) and from Utforsk.
///
/// Data: `GET /v1/feed/tabs?tab=naerheten` through [FeedRepo]. A post's price
/// is not on the tab item (the feed service does not carry it), so the CTA
/// opens the post, whose detail resolves the live product — never a stale
/// number quoted on a card.
class FeedNyheterScreen extends StatefulWidget {
  const FeedNyheterScreen({super.key, this.repo, this.bydel});

  /// Injected in tests.
  final FeedRepo? repo;

  /// The chip's district. Null → the address' district or «Bergenhus».
  final String? bydel;

  @override
  State<FeedNyheterScreen> createState() => _FeedNyheterScreenState();
}

class _FeedNyheterScreenState extends State<FeedNyheterScreen> {
  List<FeedTabItem>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final page = await (widget.repo ?? FeedRepo()).fetchFeedTab(
        tab: 'naerheten',
        limit: 30,
        bydel: widget.bydel,
      );
      if (!mounted) return;
      setState(() => _items = page.items);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _items = const <FeedTabItem>[];
        _error = e.toString();
      });
    }
  }

  void _openPost(FeedTabItem item) =>
      openScreen(context, PostDetailScreen(postId: item.id));

  void _openStore(FeedTabItem item) {
    final id = item.store?.id;
    if (id == null) return;
    BergenRoutes.push(
      context,
      '/bergen/butikk/$id',
      arguments: {'name': item.store?.name ?? ''},
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final safeTop = MediaQuery.paddingOf(context).top;
    final bydel = widget.bydel ?? 'Bergenhus';
    final items = _items;

    return Scaffold(
      backgroundColor: BergenTokens.paper,
      body: ListView(
        padding: EdgeInsets.fromLTRB(0, safeTop + 10 * s, 0, 40 * s),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16 * s),
            child: Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                    width: 40 * s,
                    height: 40 * s,
                    decoration: BoxDecoration(
                      color: const Color(0x8CFFFFFF),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0x80FFFFFF)),
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 20 * s,
                      color: BergenTokens.ink,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 11 * s,
                    vertical: 5 * s,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x8CFFFFFF),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0x80FFFFFF)),
                  ),
                  child: Text(
                    UtforskCopy.a1_utforsk_nyheter_chip(bydel),
                    style: bText(
                      context,
                      11,
                      weight: FontWeight.w800,
                      color: BergenTokens.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20 * s, 6 * s, 20 * s, 0),
            child: Text(
              UtforskCopy.a1_utforsk_nyheter_title,
              key: const Key('a1_utforsk_nyheter_title'),
              style: bDisplay(
                context,
                22,
                weight: FontWeight.w800,
                color: BergenTokens.ink,
              ).copyWith(letterSpacing: -0.44),
            ),
          ),
          SizedBox(height: 10 * s),
          if (items == null)
            Padding(
              padding: EdgeInsets.all(30 * s),
              child: const Center(
                child: CircularProgressIndicator(color: BergenTokens.teal),
              ),
            )
          else if (items.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 20 * s,
                vertical: 20 * s,
              ),
              child: Text(
                _error == null
                    ? UtforskCopy.a1_utforsk_nyheter_empty
                    : UtforskCopy.a1_utforsk_nyheter_empty,
                key: const Key('a1_utforsk_nyheter_empty'),
                style: bText(
                  context,
                  13,
                  weight: FontWeight.w600,
                  color: BergenTokens.inkSecondary,
                ),
              ),
            )
          else
            for (final item in items)
              _NyhetCard(
                item: item,
                onOpen: () => _openPost(item),
                onStore: () => _openStore(item),
              ),
          SizedBox(height: 14 * s),
          Center(
            child: Text(
              UtforskCopy.a1_utforsk_nyheter_footer,
              style: bText(
                context,
                10.5,
                weight: FontWeight.w600,
                color: BergenTokens.inkFaint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NyhetCard extends StatelessWidget {
  const _NyhetCard({
    required this.item,
    required this.onOpen,
    required this.onStore,
  });

  final FeedTabItem item;
  final VoidCallback onOpen;
  final VoidCallback onStore;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final image = item.media.cloudinaryUrl(FeedCloudinaryConfig.cloudName);
    final bergensk = (item.bydel ?? '').isNotEmpty || item.store != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(16 * s, 0, 16 * s, 12 * s),
      child: OnbPressable(
        onTap: onOpen,
        pressScale: .99,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22 * s),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2623201D),
                offset: Offset(0, 14),
                blurRadius: 24,
                spreadRadius: -14,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: BergenTokens.paperWarm),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(14 * s, 12 * s, 14 * s, 14 * s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          feedTimeAgo(item.publishedAt, context),
                          style: bText(
                            context,
                            10.5,
                            weight: FontWeight.w700,
                            color: BergenTokens.inkFaint,
                          ),
                        ),
                        SizedBox(width: 8 * s),
                        Expanded(
                          child: Text(
                            item.publisherName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: bDisplay(
                              context,
                              14,
                              weight: FontWeight.w800,
                              color: BergenTokens.ink,
                            ),
                          ),
                        ),
                        if (bergensk)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 7 * s,
                              vertical: 2 * s,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x2EF2C14E),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              UtforskCopy.a1_utforsk_nyheter_bergensk,
                              style: bText(
                                context,
                                9.5,
                                weight: FontWeight.w800,
                                color: const Color(0xFF8A6A12),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 6 * s),
                    Text(
                      item.title,
                      style: bText(
                        context,
                        13.5,
                        weight: FontWeight.w500,
                        color: BergenTokens.inkSecondary,
                      ),
                    ),
                    SizedBox(height: 12 * s),
                    Row(
                      children: [
                        OnbPressable(
                          onTap: onOpen,
                          pressScale: .95,
                          child: Container(
                            height: 38 * s,
                            padding: EdgeInsets.symmetric(horizontal: 16 * s),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF58A55), Color(0xFFE95C2C)],
                              ),
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: const [
                                BoxShadow(
                                  color: 0xBFE95C2C == 0
                                      ? Colors.transparent
                                      : Color(0xBFE95C2C),
                                  offset: Offset(0, 10),
                                  blurRadius: 18,
                                  spreadRadius: -8,
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              item.postType == 'tilbud' ||
                                      item.postType == 'produkt'
                                  ? UtforskCopy.a1_utforsk_nyheter_see
                                  : UtforskCopy.a1_utforsk_nyheter_see,
                              style: bText(
                                context,
                                12,
                                weight: FontWeight.w800,
                                color: BergenTokens.ink,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10 * s),
                        if (item.store != null)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onStore,
                            child: Text(
                              UtforskCopy.a1_utforsk_nyheter_see_store,
                              style: bText(
                                context,
                                12,
                                weight: FontWeight.w800,
                                color: BergenTokens.teal,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
