/// Where a tapped push goes (backend plan Step 13).
///
/// Two kinds of payload carry a destination of their own:
/// * an admin campaign («Push-varsler»): `type: aerend_push`, a `target`
///   (`home`, `offers`, `swipe`, `category`, `store`, `cart`, `orders`,
///   `profile`) with `target_ref` / `target_name` / `target_slug`, and a
///   `deep_link` such as `aerend://store/12`;
/// * the ops pushes (`OpsPushSender`: order, feed, Ægil), which have only a
///   `deep_link` — `aerend://order/{id}`, `aerend://feed/post/{id}`,
///   `aerend://feed`, `aerend://aegil`. `aerend://partner/...` and
///   `aerend://bud/...` belong to the store / courier apps and are ignored.
///
/// The mapping is pure (payload in, [PushRoute] out) so it can be tested
/// without a navigator; `PushNotificationService` does the opening.
library;

enum PushRouteKind {
  /// The shell on a tab ([PushRoute.tab]; 0 is Hjem, where the offers live).
  shell,

  /// `SwipeReen`.
  swipe,

  /// A `/bergen/...` route ([PushRoute.name], [PushRoute.arguments]).
  bergen,

  /// `PostDetailScreen` for [PushRoute.postId].
  post,

  /// A link meant for another app: nothing is opened.
  ignore,
}

class PushRoute {
  const PushRoute._(this.kind, {this.name, this.arguments = const {}, this.postId, this.tab = 0});

  const PushRoute.shell({int tab = 0}) : this._(PushRouteKind.shell, tab: tab);
  const PushRoute.swipe() : this._(PushRouteKind.swipe);
  const PushRoute.bergen(String name, {Map<String, String> arguments = const {}})
    : this._(PushRouteKind.bergen, name: name, arguments: arguments);
  const PushRoute.post(String postId) : this._(PushRouteKind.post, postId: postId);
  const PushRoute.ignore() : this._(PushRouteKind.ignore);

  final PushRouteKind kind;
  final String? name;
  final Map<String, String> arguments;
  final String? postId;
  final int tab;

  @override
  bool operator ==(Object other) =>
      other is PushRoute &&
      other.kind == kind &&
      other.name == name &&
      other.postId == postId &&
      other.tab == tab &&
      other.arguments.length == arguments.length &&
      arguments.entries.every((e) => other.arguments[e.key] == e.value);

  @override
  int get hashCode => Object.hash(kind, name, postId, tab, arguments.length);

  @override
  String toString() => 'PushRoute($kind, name: $name, args: $arguments, post: $postId, tab: $tab)';
}

abstract final class PushDeepLink {
  static const String campaignType = 'aerend_push';
  static const String scheme = 'aerend://';

  static String _s(Map<String, dynamic> data, String key) => '${data[key] ?? ''}'.trim();

  /// An admin campaign push.
  static bool isCampaign(Map<String, dynamic> data) => _s(data, 'type') == campaignType;

  /// The campaign id to ping as opened, or null.
  static String? campaignId(Map<String, dynamic> data) {
    if (!isCampaign(data)) return null;
    final id = _s(data, 'campaign_id');
    return id.isEmpty ? null : id;
  }

  /// A payload this mapping owns: a campaign, or any `aerend://` link. Such a
  /// payload never falls through to the chat / legacy branches.
  static bool handles(Map<String, dynamic> data) =>
      isCampaign(data) || _s(data, 'deep_link').startsWith(scheme);

  /// The destination for [data]; null when it is not ours or not understood
  /// (the caller keeps its fallback).
  static PushRoute? resolve(Map<String, dynamic> data) {
    if (isCampaign(data)) {
      return _fromTarget(data) ?? fromLink(_s(data, 'deep_link'));
    }
    final link = _s(data, 'deep_link');
    return link.startsWith(scheme) ? fromLink(link) : null;
  }

  static PushRoute? _fromTarget(Map<String, dynamic> data) {
    final ref = _s(data, 'target_ref');
    final name = _s(data, 'target_name');
    final link = _linkParts(_s(data, 'deep_link'));
    switch (_s(data, 'target')) {
      case 'home':
      case 'offers':
        return const PushRoute.shell();
      case 'swipe':
        return const PushRoute.swipe();
      case 'category':
        var slug = _s(data, 'target_slug');
        if (slug.isEmpty && link != null && link.$1 == 'category' && link.$2.isNotEmpty) slug = link.$2.first;
        return _category(slug, id: ref, name: name);
      case 'store':
        var id = ref;
        if (id.isEmpty && link != null && link.$1 == 'store' && link.$2.isNotEmpty) id = link.$2.first;
        return _store(id, name: name);
      case 'cart':
        return const PushRoute.bergen('/bergen/kurv');
      case 'orders':
        return const PushRoute.bergen('/bergen/meg/bestillinger');
      case 'profile':
        return const PushRoute.bergen('/bergen/meg/konto');
    }
    return null;
  }

  /// `aerend://store/12` → (`store`, [`12`]).
  static (String, List<String>)? _linkParts(String link) {
    if (!link.startsWith(scheme)) return null;
    final uri = Uri.tryParse(link);
    if (uri == null) return null;
    return (uri.host.toLowerCase(), uri.pathSegments.where((s) => s.isNotEmpty).toList());
  }

  /// The route for an `aerend://` link alone.
  static PushRoute? fromLink(String link) {
    final parts = _linkParts(link.trim());
    if (parts == null) return null;
    final (host, path) = parts;
    final first = path.isEmpty ? '' : path.first;
    switch (host) {
      case 'home':
      case 'offers':
        return const PushRoute.shell();
      case 'swipe':
        return const PushRoute.swipe();
      case 'category':
        return _category(first);
      case 'store':
        return _store(first);
      case 'cart':
        return const PushRoute.bergen('/bergen/kurv');
      case 'orders':
        return const PushRoute.bergen('/bergen/meg/bestillinger');
      case 'profile':
        return const PushRoute.bergen('/bergen/meg/konto');
      case 'order':
        return int.tryParse(first) == null ? null : PushRoute.bergen('/bergen/sporing/$first');
      case 'feed':
        if (path.isEmpty) return const PushRoute.bergen('/bergen/utforsk?tab=feed');
        if (first == 'post' && path.length > 1 && path[1].isNotEmpty) return PushRoute.post(path[1]);
        return null;
      case 'aegil':
        return const PushRoute.bergen('/bergen/aegil');
      // The store / courier apps' links (driftsvarsler, «Inntekt»).
      case 'partner':
      case 'bud':
        return const PushRoute.ignore();
    }
    return null;
  }

  static PushRoute? _category(String slug, {String id = '', String name = ''}) {
    if (slug.isEmpty && id.isEmpty) return null;
    return PushRoute.bergen(
      '/bergen/kategori/${Uri.encodeComponent(slug.isNotEmpty ? slug : id)}',
      arguments: {
        if (slug.isNotEmpty) 'slug': slug,
        if (int.tryParse(id) != null) 'id': id,
        if (name.isNotEmpty) 'name': name,
      },
    );
  }

  static PushRoute? _store(String id, {String name = ''}) {
    if (int.tryParse(id) == null) return null;
    return PushRoute.bergen('/bergen/butikk/$id', arguments: {if (name.isNotEmpty) 'name': name});
  }

  // ── cold start ──────────────────────────────────────────────────────────

  /// A destination that arrived before the shell was up (a tap that launched
  /// the app: `getInitialMessage` can answer before `runApp`, and Splash
  /// replaces whatever is pushed under it). The shell takes it once it builds.
  static PushRoute? _pending;
  static DateTime? _pendingAt;

  /// How long a held destination stays good: a push tapped long ago should
  /// not jump the customer somewhere at the next unrelated shell build.
  static const Duration pendingTtl = Duration(minutes: 5);

  static void hold(PushRoute route, {DateTime? now}) {
    _pending = route;
    _pendingAt = now ?? DateTime.now();
  }

  static bool get hasPending => _pending != null;

  /// The held destination, once; null when there is none or it went stale.
  static PushRoute? takePending({DateTime? now}) {
    final route = _pending;
    final at = _pendingAt;
    _pending = null;
    _pendingAt = null;
    if (route == null || at == null) return null;
    if ((now ?? DateTime.now()).difference(at) > pendingTtl) return null;
    return route;
  }
}
