import 'package:flutter/material.dart';

import '../bergen_routes_agil1.dart';
import '../bergen_routes_agil3.dart';
import 'bergen_toast.dart';

/// Named-route plumbing for the `/bergen/...` routes of both branches
/// (AGIL-CONTRACT §3.4).
///
/// A route name may carry a query (`/bergen/utforsk?tab=feed`) or a trailing
/// parameter (`/bergen/butikk/45`). `MaterialApp.routes` matches whole strings,
/// so [bergenRouteBuilder] strips those down to the registered key and hands
/// the rest over as `RouteSettings.arguments` — a `Map<String, String>` of the
/// query merged with the caller's own arguments — the same way for a push from
/// the Hjem and for a push from agil-3's Meg.
///
/// A name nobody has registered yet (the other branch's screen, before merge
/// day) is a toast rather than a crash: the seam is the route name, and the
/// customer should never see a red screen because two branches merge later.
abstract final class BergenRoutes {
  static const String kommerSnart = 'Kommer snart';

  /// The registered key for [name]: query removed, and the last path segment
  /// dropped when it is a parameter the map does not spell.
  static String? resolve(String name) {
    final maps = <String, WidgetBuilder>{
      ...bergenRoutesAgil1(),
      ...bergenRoutesAgil3(),
    };
    final path = name.split('?').first;
    if (maps.containsKey(path)) return path;
    final cut = path.lastIndexOf('/');
    if (cut > 0) {
      final base = path.substring(0, cut);
      if (maps.containsKey(base)) return base;
      // `/bergen/sporing/{id}/hjelp` → `/bergen/sporing/hjelp`.
      final parent = base.lastIndexOf('/');
      if (parent > 0) {
        final rebuilt = '${base.substring(0, parent)}${path.substring(cut)}';
        if (maps.containsKey(rebuilt)) return rebuilt;
      }
    }
    return null;
  }

  /// The arguments a screen reads: the query, a trailing `id` / `slug`
  /// parameter, and whatever the caller passed (caller wins).
  static Map<String, String> arguments(String name, Object? extra) {
    final uri = Uri.parse(name);
    final out = <String, String>{...uri.queryParameters};
    final key = resolve(name);
    final path = name.split('?').first;
    if (key != null && key != path) {
      final tail = path
          .substring(key.length)
          .split('/')
          .where((s) => s.isNotEmpty);
      if (tail.isNotEmpty) {
        final value = tail.first;
        out['id'] = value;
        out['slug'] = value;
      }
    }
    if (extra is Map) {
      for (final e in extra.entries) {
        out['${e.key}'] = '${e.value}';
      }
    } else if (extra is String) {
      out['id'] = extra;
      out['slug'] = extra;
      out['q'] = extra;
    } else if (extra is int) {
      out['id'] = '$extra';
    }
    return out;
  }

  /// A route for [settings], or null when no map knows the name.
  static Route<dynamic>? generate(RouteSettings settings) {
    final name = settings.name ?? '';
    if (!name.startsWith('/bergen/')) return null;
    final key = resolve(name);
    if (key == null) return null;
    final builder = (bergenRoutesAgil1()[key] ?? bergenRoutesAgil3()[key])!;
    return MaterialPageRoute<dynamic>(
      settings: RouteSettings(
        name: name,
        arguments: arguments(name, settings.arguments),
      ),
      builder: builder,
    );
  }

  /// Push [name]; a toast when the screen is not on this tree yet.
  static Future<T?> push<T>(
    BuildContext context,
    String name, {
    Object? arguments,
  }) {
    final route = generate(RouteSettings(name: name, arguments: arguments));
    if (route == null) {
      showBergenToast(context, kommerSnart);
      return Future<T?>.value(null);
    }
    return Navigator.of(context).push<T>(route as Route<T>);
  }

  /// Push [name] when a map knows it; otherwise run [orElse] — the legacy
  /// screen that did the job before the Bergen one landed. Nothing regresses
  /// while a later phase (or the other branch) is still on its way.
  static Future<void> pushOr(
    BuildContext context,
    String name, {
    required VoidCallback orElse,
    Object? arguments,
  }) async {
    final route = generate(RouteSettings(name: name, arguments: arguments));
    if (route == null) {
      orElse();
      return;
    }
    await Navigator.of(context).push<dynamic>(route);
  }

  /// The arguments the current route carries (see [arguments]).
  static Map<String, String> argsOf(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, String>) return args;
    if (args is Map)
      return {for (final e in args.entries) '${e.key}': '${e.value}'};
    if (args is String) return {'id': args, 'slug': args, 'q': args};
    if (args is int) return {'id': '$args'};
    return const {};
  }
}
