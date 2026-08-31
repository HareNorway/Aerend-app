class FeedPage<T> {
  final List<T> items;
  final String? nextCursor;

  const FeedPage({
    required this.items,
    this.nextCursor,
  });

  factory FeedPage.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return FeedPage(
      items: rawItems
          .map((e) => itemFromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['next_cursor'] as String?,
    );
  }
}
