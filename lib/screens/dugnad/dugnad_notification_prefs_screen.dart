import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../commonView/common_circular_progress_indicator.dart';
import '../../theme/design_scale.dart';
import '../../theme/sc_saas_theme.dart';
import '../common/account/account_widgets.dart';
import '../common/account/settings_design_kit.dart';
import 'dugnad_club_theme.dart';
import 'dugnad_models.dart';
import 'dugnad_repo.dart';
import 'widgets/dugnad_subpage_shell.dart';

/// Design `NotifSettingsScreen` / `.dgn-note` + `.dgn-prefs` + `.dgn-foot`.
class DugnadNotificationPrefsScreen extends StatefulWidget {
  const DugnadNotificationPrefsScreen({super.key});

  @override
  State<DugnadNotificationPrefsScreen> createState() =>
      _DugnadNotificationPrefsScreenState();
}

class _PrefCat {
  const _PrefCat({
    required this.id,
    required this.title,
    required this.desc,
    required this.tone,
    required this.iconBuilder,
  });

  final String id;
  final String title;
  final String desc;

  /// `club` | `green` | `amber` | `slate`
  final String tone;
  final Widget Function(Color color, double size) iconBuilder;
}

/// Design Icon `share` — three connected nodes (not iOS/Android share sheet).
const _kShareSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <circle cx="18" cy="5" r="3"/>
  <circle cx="6" cy="12" r="3"/>
  <circle cx="18" cy="19" r="3"/>
  <line x1="8.5" y1="13.5" x2="15.5" y2="17.5"/>
  <line x1="15.5" y1="6.5" x2="8.5" y2="10.5"/>
</svg>
''';

Widget Function(Color color, double size) _materialIcon(IconData icon) {
  return (color, size) => Icon(icon, size: size, color: color);
}

Widget Function(Color color, double size) _svgAsset(String asset) {
  return (color, size) => SvgPicture.asset(
        asset,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
}

Widget Function(Color color, double size) _svgString(String raw) {
  return (color, size) => SvgPicture.string(
        raw,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
}

final _kPrefCats = <_PrefCat>[
  _PrefCat(
    id: 'points',
    title: 'Poeng og STØ',
    desc:
        'Poeng du tjener, nye nivåer, merker du låser opp og sesongoppsummeringen.',
    tone: 'club',
    iconBuilder: _materialIcon(Icons.star_rounded),
  ),
  _PrefCat(
    id: 'campaigns',
    title: 'Kampanjer og produkter',
    desc: 'Nye kampanjer fra laget ditt og nye matkasser i klubben.',
    tone: 'green',
    iconBuilder: _svgAsset('assets/svgs/menu/box.svg'),
  ),
  _PrefCat(
    id: 'social',
    title: 'Sosialt',
    desc: 'Verving, venner som blir medlem og bevegelse på topplista.',
    tone: 'amber',
    iconBuilder: _svgString(_kShareSvg),
  ),
  _PrefCat(
    id: 'system',
    title: 'System',
    desc: 'Ukens oppdrag og generelle beskjeder fra Reen Dugnad.',
    tone: 'slate',
    iconBuilder: _materialIcon(Icons.info_outline_rounded),
  ),
];

({Color bg, Color fg}) _prefTone(String tone, DugnadClubThemePalette theme) {
  switch (tone) {
    case 'green':
      return (bg: const Color(0xFFEAFAF0), fg: const Color(0xFF1F8A5B));
    case 'amber':
      return (bg: const Color(0xFFFBF1D8), fg: const Color(0xFFA97A12));
    case 'slate':
      return (bg: const Color(0xFFEEF1F6), fg: const Color(0xFF46536B));
    default:
      // Club secondary bg + primary text (Poeng / STØ).
      return (bg: theme.primaryTint, fg: theme.primaryHover);
  }
}

class _DugnadNotificationPrefsScreenState
    extends State<DugnadNotificationPrefsScreen> {
  final DugnadRepo _repo = DugnadRepo();
  DugnadNotificationPrefs _prefs = const DugnadNotificationPrefs();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final prefs = await _repo.getNotificationPrefs();
    if (!mounted) return;
    setState(() {
      if (prefs != null) _prefs = prefs;
      _loading = false;
    });
  }

  bool _valueFor(String id) => switch (id) {
        'points' => _prefs.points,
        'campaigns' => _prefs.campaigns,
        'social' => _prefs.social,
        'system' => _prefs.system,
        _ => true,
      };

  Future<void> _setCategory(String key, bool value) async {
    final next = switch (key) {
      'points' => _prefs.copyWith(points: value),
      'campaigns' => _prefs.copyWith(campaigns: value),
      'social' => _prefs.copyWith(social: value),
      'system' => _prefs.copyWith(system: value),
      _ => _prefs,
    };
    setState(() {
      _prefs = next;
      _saving = true;
    });
    final saved = await _repo.updateNotificationPrefs(next);
    if (!mounted) return;
    setState(() {
      if (saved != null) _prefs = saved;
      _saving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    return Scaffold(
      backgroundColor: theme.background,
      body: DugnadFixedTypography(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AccountTkHead(
                title: 'Varsler i appen',
                onBack: () => Navigator.maybePop(context),
              ),
              Expanded(
                child: _loading
                    ? Center(
                        child: CommonCircularProgressIndicator(
                          strokeWidth: 2,
                          size: 22,
                          color: theme.primary,
                        ),
                      )
                    : SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          context.dp(18),
                          0,
                          context.dp(18),
                          context.dp(120),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _DgnNote(theme: theme),
                            SizedBox(height: context.dp(14)),
                            for (var i = 0; i < _kPrefCats.length; i++) ...[
                              if (i > 0) SizedBox(height: context.dp(9)),
                              _DgnPrefRow(
                                cat: _kPrefCats[i],
                                enabled: _valueFor(_kPrefCats[i].id),
                                onChanged: _saving
                                    ? null
                                    : (v) =>
                                        _setCategory(_kPrefCats[i].id, v),
                              ),
                            ],
                            SizedBox(height: context.dp(14)),
                            // `.dgn-foot`
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.dp(2),
                              ),
                              child: Text(
                                'Slår du av en kategori, skjules varslene fra feeden og telles ikke som uleste. Du kan slå dem på igjen når som helst.',
                                style: dgText(
                                  12,
                                  FontWeight.w600,
                                  height: 1.5,
                                  color: ScSaasThemeTokens.gray500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.dgn-note` — club-tint plate + white bell tile.
class _DgnNote extends StatelessWidget {
  const _DgnNote({required this.theme});

  final DugnadClubThemePalette theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.dp(14),
        vertical: context.dp(13),
      ),
      decoration: BoxDecoration(
        color: theme.primaryTint,
        borderRadius: BorderRadius.circular(context.dp(15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: context.dp(34),
            height: context.dp(34),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(context.dp(11)),
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: context.dp(17),
              color: theme.primaryHover,
            ),
          ),
          SizedBox(width: context.dp(11)),
          Expanded(
            child: Text(
              'Dette styrer hva som havner i varselfeeden bak klokka. Push-varsler på telefonen styrer du i telefonens egne innstillinger.',
              style: dgText(
                12.5,
                FontWeight.w600,
                height: 1.5,
                color: ScSaasThemeTokens.gray600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `.dgn-prefs .row` — separate white card per category.
class _DgnPrefRow extends StatelessWidget {
  const _DgnPrefRow({
    required this.cat,
    required this.enabled,
    required this.onChanged,
  });

  final _PrefCat cat;
  final bool enabled;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final colors = _prefTone(cat.tone, theme);

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Container(
        padding: EdgeInsets.all(context.dp(14)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.dp(16)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D2D1B5B),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: context.dp(38),
              height: context.dp(38),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.bg,
                borderRadius: BorderRadius.circular(context.dp(12)),
              ),
              child: cat.iconBuilder(colors.fg, context.dp(17)),
            ),
            SizedBox(width: context.dp(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.title,
                    style: dgText(
                      14.5,
                      FontWeight.w800,
                      color: theme.text,
                    ).copyWith(letterSpacing: 14.5 * -0.01),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: context.dp(3)),
                    child: Text(
                      cat.desc,
                      style: dgText(
                        12.5,
                        FontWeight.w600,
                        height: 1.45,
                        color: ScSaasThemeTokens.gray500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: context.dp(12)),
            DrToggle(value: enabled, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
