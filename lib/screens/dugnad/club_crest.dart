import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../networking/api_constant.dart';
import '../../utils/utils.dart';
import 'dugnad_club_theme.dart';

/// Club avatar — network logo if present, else colored circle with initials.
///
/// Design spec: dugnad/customer-screens.jsx → Crest component.
/// Parameterized size for different contexts (38/44/56/72).
class ClubCrest extends StatelessWidget {
  final String name;
  final String? logoUrl;
  final double size;
  final Color? backgroundColor;

  const ClubCrest({
    super.key,
    required this.name,
    this.logoUrl,
    this.size = 44,
    this.backgroundColor,
  });

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (name.length >= 2) return name.substring(0, 2).toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String? get _resolvedLogoUrl => resolveClubMediaUrl(logoUrl);

  /// Normalizes API media URLs for local dev (correct host/port, relative paths).
  static String? resolveClubMediaUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;

    final trimmed = raw.trim();
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      final path = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
      return '${BaseUrl.domain}$path';
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return trimmed;

    final apiBase = Uri.tryParse(BaseUrl.domain);
    if (apiBase != null &&
        uri.host == 'localhost' &&
        uri.port == 80 &&
        apiBase.port != 80 &&
        apiBase.port != 443) {
      return uri.replace(port: apiBase.port).toString();
    }

    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final String? resolvedLogo = _resolvedLogoUrl;
    final bool hasLogo = resolvedLogo != null && resolvedLogo.isNotEmpty;
    final Color bg = backgroundColor ?? context.dugnadTheme.primaryHover;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: hasLogo ? Colors.white : bg,
        shape: BoxShape.circle,
        boxShadow: const [
          // .dg-crest: 0 4px 12px -4px rgba(45,27,91,.5)
          BoxShadow(
            color: Color(0x802D1B5B),
            blurRadius: 12,
            offset: Offset(0, 4),
            spreadRadius: -4,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: hasLogo
          ? CachedNetworkImage(
              imageUrl: resolvedLogo,
              width: size,
              height: size,
              fit: BoxFit.contain,
              fadeInDuration: const Duration(milliseconds: 200),
              imageBuilder: (context, imageProvider) => Padding(
                padding: EdgeInsets.all(size * 0.08),
                child: Image(
                  image: imageProvider,
                  width: size,
                  height: size,
                  fit: BoxFit.contain,
                ),
              ),
              // Letter on club color — covers the white crest shell fully.
              placeholder: (_, __) => _initialsFallback(bg, fill: true),
              errorWidget: (_, __, ___) => _initialsFallback(bg, fill: true),
            )
          : _initialsFallback(bg),
    );
  }

  /// Initials letter(s). Pass [fill] when replacing a failed/loading logo so the
  /// club color covers the white crest shell (avoids invisible white-on-white).
  Widget _initialsFallback(Color bg, {bool fill = false}) {
    final double fontSize = size * 0.32;
    final letter = Center(
      child: Text(
        _initials,
        style: aeTitle(color: Colors.white).copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
    if (!fill) return letter;
    return ColoredBox(color: bg, child: letter);
  }
}
