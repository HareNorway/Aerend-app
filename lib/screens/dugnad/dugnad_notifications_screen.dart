import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../commonView/common_circular_progress_indicator.dart';
import '../../theme/design_scale.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/utils.dart';
import '../common/account/account_widgets.dart';
import '../common/account/settings_design_kit.dart';
import 'dugnad_club_theme.dart';
import 'dugnad_models.dart';
import 'dugnad_notification_nav.dart';
import 'dugnad_notification_prefs_screen.dart';
import 'dugnad_notification_unread.dart';
import 'dugnad_repo.dart';
import 'widgets/dugnad_subpage_shell.dart';

/// Feed categories — API keys (`points` / `campaigns` / …) with design labels.
/// Tones: sosial=amber/gold, kampanje=green, everything else=club colors.
class _NotifCat {
  const _NotifCat({
    required this.id,
    required this.label,
    required this.tone,
  });

  final String id;
  final String label;

  /// `amber` | `green` | `club`
  final String tone;

  static const all = <_NotifCat>[
    _NotifCat(id: 'points', label: 'Poeng', tone: 'club'),
    _NotifCat(id: 'campaigns', label: 'Kampanjer', tone: 'green'),
    _NotifCat(id: 'social', label: 'Sosialt', tone: 'amber'),
    _NotifCat(id: 'system', label: 'System', tone: 'club'),
  ];

  static _NotifCat of(String id) =>
      all.firstWhere((c) => c.id == id, orElse: () => all.last);
}

/// Design `.dgn-row .ic` / `.cat` colors — keyed by category, not API `tone`.
({Color bg, Color fg}) _notifToneColors(
  String tone,
  DugnadClubThemePalette theme,
) {
  switch (tone) {
    case 'amber':
      return (bg: const Color(0xFFFBF1D8), fg: const Color(0xFFA97A12));
    case 'green':
      return (bg: const Color(0xFFEAFAF0), fg: const Color(0xFF1F8A5B));
    default:
      // Club secondary bg + primary text (points, system, unknown).
      return (bg: theme.primaryTint, fg: theme.primaryHover);
  }
}

/// «Varsler» — dugnad in-app feed (design `NotificationsScreen` / `.dgn-*`).
class DugnadNotificationsScreen extends StatefulWidget {
  const DugnadNotificationsScreen({super.key});

  @override
  State<DugnadNotificationsScreen> createState() =>
      _DugnadNotificationsScreenState();
}

class _DugnadNotificationsScreenState extends State<DugnadNotificationsScreen> {
  final DugnadRepo _repo = DugnadRepo();
  final List<DugnadNotificationItem> _items = [];
  final ScrollController _scroll = ScrollController();

  bool _loading = true;
  bool _loadingMore = false;
  int _page = 1;
  int _lastPage = 1;
  String? _error;

  /// `alle` or an API category id (`points`, `campaigns`, …).
  String _filter = 'alle';
  DugnadNotificationPrefs _prefs = const DugnadNotificationPrefs();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _bootstrap();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final prefs = await _repo.getNotificationPrefs();
    if (prefs != null && mounted) _prefs = prefs;
    await _load(reset: true);
    // Opening the feed clears the bell (spec §1.3).
    final ok = await _repo.markNotificationFeedSeen();
    if (ok) DugnadNotificationUnread.clearLocal();
  }

  void _onScroll() {
    if (_loadingMore || _page >= _lastPage) return;
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 120) {
      _loadMore();
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
      });
    }
    final page = await _repo.getNotifications(page: 1);
    if (!mounted) return;
    if (page == null) {
      setState(() {
        _loading = false;
        _error = languages.noRecordFound;
        if (reset) _items.clear();
      });
      return;
    }
    setState(() {
      _items
        ..clear()
        ..addAll(_dedupeNotifications(page.notifications));
      _page = page.currentPage;
      _lastPage = page.lastPage;
      _loading = false;
      _error = null;
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _page >= _lastPage) return;
    setState(() => _loadingMore = true);
    final nextPage = _page + 1;
    final page = await _repo.getNotifications(page: nextPage);
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      if (page != null) {
        _items.addAll(_dedupeNotifications(page.notifications, existing: _items));
        _page = page.currentPage;
        _lastPage = page.lastPage;
      }
    });
  }

  /// Drop duplicate ids and repeated event rows (e.g. two "Du nådde Blue…").
  List<DugnadNotificationItem> _dedupeNotifications(
    List<DugnadNotificationItem> incoming, {
    List<DugnadNotificationItem>? existing,
  }) {
    final seenIds = <int>{
      if (existing != null) ...existing.map((e) => e.id).where((id) => id > 0),
    };
    final seenEvents = <String>{
      if (existing != null)
        for (final e in existing)
          if (_eventDedupeKey(e) != null) _eventDedupeKey(e)!,
    };
    final out = <DugnadNotificationItem>[];
    for (final n in incoming) {
      if (n.id > 0 && !seenIds.add(n.id)) continue;
      final eventKey = _eventDedupeKey(n);
      if (eventKey != null && !seenEvents.add(eventKey)) continue;
      out.add(n);
    }
    return out;
  }

  /// Stable key for event types that must appear once per achievement.
  String? _eventDedupeKey(DugnadNotificationItem n) {
    switch (n.typeKey) {
      case 'tier_upgrade':
        final tier = n.deepLinkPayload?['tier_key']?.toString();
        return 'tier|${tier?.isNotEmpty == true ? tier : n.titleNo}';
      case 'badge_unlocked':
        final badge = n.deepLinkPayload?['badge_key']?.toString();
        return 'badge|${badge?.isNotEmpty == true ? badge : n.titleNo}';
      default:
        return null;
    }
  }

  bool _catEnabled(String id) => switch (id) {
        'points' => _prefs.points,
        'campaigns' => _prefs.campaigns,
        'social' => _prefs.social,
        'system' => _prefs.system,
        _ => true,
      };

  List<_NotifCat> get _visibleCats =>
      _NotifCat.all.where((c) => _catEnabled(c.id)).toList();

  List<DugnadNotificationItem> get _live =>
      _items.where((n) => _catEnabled(n.category)).toList();

  List<DugnadNotificationItem> get _shown {
    final live = _live;
    if (_filter == 'alle') return live;
    return live.where((n) => n.category == _filter).toList();
  }

  int get _unreadCount => _live.where((e) => e.unread).length;

  int _unreadIn(String catId) =>
      _live.where((e) => e.category == catId && e.unread).length;

  Future<void> _openSettings() async {
    await openScreenWithResult(context, const DugnadNotificationPrefsScreen());
    if (!mounted) return;
    final prefs = await _repo.getNotificationPrefs();
    if (prefs != null && mounted) {
      setState(() {
        _prefs = prefs;
        // If the active tab was turned off, fall back to Alle.
        if (_filter != 'alle' && !_catEnabled(_filter)) _filter = 'alle';
      });
    }
  }

  Future<void> _markAllRead() async {
    final ids = _live.where((e) => e.unread).map((e) => e.id).toList();
    if (ids.isEmpty) return;
    HapticFeedback.selectionClick();
    final ok = await _repo.markNotificationsRead(ids: ids);
    if (!mounted || !ok) return;
    setState(() {
      for (var i = 0; i < _items.length; i++) {
        if (_items[i].unread && _catEnabled(_items[i].category)) {
          _items[i] = _items[i].copyWith(
            unread: false,
            readAt: DateTime.now().toIso8601String(),
          );
        }
      }
    });
    DugnadNotificationUnread.clearLocal();
    openSimpleSnackbar('Alle varsler er lest');
  }

  Future<void> _openItem(DugnadNotificationItem item) async {
    if (item.unread) {
      final ok = await _repo.markNotificationsRead(id: item.id);
      if (ok && mounted) {
        final idx = _items.indexWhere((e) => e.id == item.id);
        if (idx >= 0) {
          setState(() {
            _items[idx] = _items[idx].copyWith(
              unread: false,
              readAt: DateTime.now().toIso8601String(),
            );
          });
        }
        await DugnadNotificationUnread.refresh();
      }
    }
    if (!mounted) return;
    openDugnadNotificationDeepLink(context, item);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final unread = _unreadCount;

    return Scaffold(
      backgroundColor: theme.background,
      body: DugnadFixedTypography(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Design: back · centered «Varsler» · settings (always).
              AccountTkHead(
                title: languages.notifications,
                onBack: () => Navigator.maybePop(context),
                trailing: _SettingsCircleButton(onPressed: _openSettings),
              ),
              if (!_loading && _error == null) ...[
                _CategoryTabs(
                  filter: _filter,
                  cats: _visibleCats,
                  unreadAll: unread,
                  unreadIn: _unreadIn,
                  onSelect: (id) => setState(() => _filter = id),
                ),
                if (unread > 0)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.dp(18),
                      0,
                      context.dp(18),
                      context.dp(10),
                    ),
                    child: Row(
                      children: [
                        Text(
                          unread == 1 ? '1 ulest' : '$unread uleste',
                          style: dgText(
                            12,
                            FontWeight.w800,
                            color: ScSaasThemeTokens.gray500,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _markAllRead,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: context.dp(4),
                              horizontal: context.dp(2),
                            ),
                            child: Text(
                              'Merk alle som lest',
                              style: dgText(
                                13,
                                FontWeight.w800,
                                color: theme.primaryHover,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              Expanded(child: _body(theme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(DugnadClubThemePalette theme) {
    if (_loading) {
      return Center(
        child: CommonCircularProgressIndicator(
          strokeWidth: 2,
          size: 22,
          color: theme.primary,
        ),
      );
    }
    if (_error != null && _items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: dgText(14, FontWeight.w600, color: ScSaasThemeTokens.gray500),
          ),
        ),
      );
    }

    final shown = _shown;
    if (shown.isEmpty) {
      return _EmptyState(
        filterAll: _filter == 'alle',
        onPrefs: _openSettings,
      );
    }

    final groups = _groupByDay(shown);
    final offCats =
        _NotifCat.all.where((c) => !_catEnabled(c.id)).map((c) => c.label).toList();

    return RefreshIndicator(
      color: theme.primary,
      onRefresh: () => _load(reset: true),
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          context.dp(18),
          0,
          context.dp(18),
          context.dp(120),
        ),
        itemCount: groups.length +
            (offCats.isNotEmpty ? 1 : 0) +
            (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < groups.length) {
            final g = groups[index];
            return Padding(
              padding: EdgeInsets.only(bottom: context.dp(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      left: context.dp(2),
                      bottom: context.dp(9),
                    ),
                    child: Text(
                      g.day,
                      style: dgText(
                        11.5,
                        FontWeight.w800,
                        color: kDgGray400,
                      ).copyWith(letterSpacing: 11.5 * 0.07),
                    ),
                  ),
                  for (var i = 0; i < g.items.length; i++) ...[
                    if (i > 0) SizedBox(height: context.dp(9)),
                    _DugnadNotificationRow(
                      item: g.items[i],
                      onTap: () => _openItem(g.items[i]),
                    ),
                  ],
                ],
              ),
            );
          }
          final afterGroups = index - groups.length;
          if (offCats.isNotEmpty && afterGroups == 0) {
            return _DisabledCatsBanner(
              labels: offCats,
              onTap: _openSettings,
            );
          }
          return Padding(
            padding: EdgeInsets.symmetric(vertical: context.dp(16)),
            child: Center(
              child: CommonCircularProgressIndicator(
                strokeWidth: 2,
                size: 20,
                color: theme.primary,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DayGroup {
  _DayGroup(this.day, this.items);
  final String day;
  final List<DugnadNotificationItem> items;
}

List<_DayGroup> _groupByDay(List<DugnadNotificationItem> items) {
  final groups = <_DayGroup>[];
  for (final n in items) {
    final day = _dayLabel(n.createdAt);
    if (groups.isNotEmpty && groups.last.day == day) {
      groups.last.items.add(n);
    } else {
      groups.add(_DayGroup(day, [n]));
    }
  }
  return groups;
}

String _dayLabel(String? raw) {
  final dt = _parseWhen(raw);
  if (dt == null) return 'TIDLIGERE';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(dt.year, dt.month, dt.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'I DAG';
  if (diff == 1) return 'I GÅR';
  return 'TIDLIGERE';
}

DateTime? _parseWhen(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  try {
    if (raw.contains('T')) return DateTime.parse(raw).toLocal();
    return getTimeAndDateObj(raw);
  } catch (_) {
    return null;
  }
}

String _relativeWhen(String? raw) {
  final dt = _parseWhen(raw);
  if (dt == null) return '';
  try {
    return timeAgo(dt);
  } catch (_) {
    return '';
  }
}

/// Circular settings control — solid white opaque plate (mock), same size as
/// `.ae-back`, gear at design `17`.
class _SettingsCircleButton extends StatefulWidget {
  const _SettingsCircleButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_SettingsCircleButton> createState() => _SettingsCircleButtonState();
}

class _SettingsCircleButtonState extends State<_SettingsCircleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final size = context.dp(38);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.primary.withValues(alpha: 0.20),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.primaryHover.withValues(alpha: 0.55),
                blurRadius: context.dp(16),
                offset: Offset(0, context.dp(6)),
                spreadRadius: context.dp(-6),
              ),
              BoxShadow(
                color: const Color(0x1A141428),
                blurRadius: context.dp(3),
                offset: Offset(0, context.dp(1)),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.settings_outlined,
            size: context.dp(17),
            color: theme.text,
          ),
        ),
      ),
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({
    required this.filter,
    required this.cats,
    required this.unreadAll,
    required this.unreadIn,
    required this.onSelect,
  });

  final String filter;
  final List<_NotifCat> cats;
  final int unreadAll;
  final int Function(String id) unreadIn;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    // Design `.dgn-filters.scl-filter.scroll` — no fixed height (that was
    // clipping the pills). Padding 2 / 18 / 12 matches CSS.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.fromLTRB(
        context.dp(18),
        context.dp(2),
        context.dp(18),
        context.dp(12),
      ),
      child: Row(
        children: [
          _TabPill(
            label: 'Alle',
            count: unreadAll,
            selected: filter == 'alle',
            onTap: () => onSelect('alle'),
            theme: theme,
          ),
          for (final c in cats) ...[
            SizedBox(width: context.dp(9)),
            _TabPill(
              label: c.label,
              count: unreadIn(c.id),
              selected: filter == c.id,
              onTap: () => onSelect(c.id),
              theme: theme,
            ),
          ],
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    required this.theme,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final DugnadClubThemePalette theme;

  @override
  Widget build(BuildContext context) {
    // Design `.scl-filter button` / `.dgn-filters`:
    // padding 9×16, radius 999, 12.5/800, gap 7 to count badge.
    //
    // Keep an opaque white plate under the fill, and snap the club glow
    // (don't put it on AnimatedContainer). Otherwise the glow briefly
    // shows through while the fill interpolates toward transparent.
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: const Color(0xFFFFFFFF),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: theme.primary.withValues(alpha: 0.7),
                    blurRadius: context.dp(20),
                    offset: Offset(0, context.dp(10)),
                    spreadRadius: context.dp(-12),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x0A2D1B5B),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  opacity: selected ? 1 : 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: theme.shinyGradient),
                  ),
                ),
              ),
              if (!selected)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: ScSaasThemeTokens.gray100,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.dp(16),
                  vertical: context.dp(9),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: dgText(
                        12.5,
                        FontWeight.w800,
                        height: 1.2,
                        color: selected
                            ? Colors.white
                            : ScSaasThemeTokens.gray500,
                      ).copyWith(letterSpacing: 12.5 * -0.01),
                    ),
                    if (count > 0) ...[
                      SizedBox(width: context.dp(7)),
                      Container(
                        constraints:
                            BoxConstraints(minWidth: context.dp(17)),
                        height: context.dp(17),
                        padding: EdgeInsets.symmetric(
                          horizontal: context.dp(5),
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: selected
                              ? Colors.white.withValues(alpha: 0.24)
                              : ScSaasThemeTokens.gray100,
                        ),
                        child: Text(
                          '$count',
                          style: dgText(
                            10.5,
                            FontWeight.w800,
                            height: 1,
                            color: selected
                                ? Colors.white
                                : ScSaasThemeTokens.gray600,
                          ),
                        ),
                      ),
                    ],
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filterAll, required this.onPrefs});

  final bool filterAll;
  final VoidCallback onPrefs;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          context.dp(32),
          0,
          context.dp(32),
          context.dp(80),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: context.dp(66),
              height: context.dp(66),
              decoration: BoxDecoration(
                color: theme.primaryTint,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: context.dp(30),
                color: theme.primaryDisabled,
              ),
            ),
            SizedBox(height: context.dp(16)),
            Text(
              filterAll ? 'Ingen varsler ennå' : 'Ingen varsler her',
              style: dgText(17, FontWeight.w800, color: theme.text),
            ),
            SizedBox(height: context.dp(5)),
            Text(
              filterAll
                  ? 'Vi sier fra når du tjener poeng, laget legger ut noe nytt, eller det skjer noe på topplista.'
                  : 'Denne kategorien er tom akkurat nå. Prøv «Alle».',
              textAlign: TextAlign.center,
              style: dgText(
                13.5,
                FontWeight.w600,
                height: 1.5,
                color: ScSaasThemeTokens.gray500,
              ),
            ),
            if (filterAll) ...[
              SizedBox(height: context.dp(16)),
              TextButton(
                onPressed: onPrefs,
                child: Text(
                  'Varslingsinnstillinger',
                  style: dgText(
                    13.5,
                    FontWeight.w800,
                    color: theme.primaryHover,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DisabledCatsBanner extends StatelessWidget {
  const _DisabledCatsBanner({required this.labels, required this.onTap});

  final List<String> labels;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final joined = labels.length == 1
        ? labels.first
        : '${labels.sublist(0, labels.length - 1).join(', ')} og ${labels.last}';
    return Padding(
      padding: EdgeInsets.only(bottom: context.dp(18)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(context.dp(14)),
          child: Ink(
            padding: EdgeInsets.symmetric(
              horizontal: context.dp(14),
              vertical: context.dp(12),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(context.dp(14)),
              border: Border.all(
                color: const Color(0xFFE3E5EA),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.visibility_off_outlined,
                  size: context.dp(15),
                  color: ScSaasThemeTokens.gray500,
                ),
                SizedBox(width: context.dp(9)),
                Expanded(
                  child: Text(
                    '$joined er slått av',
                    style: dgText(
                      12.5,
                      FontWeight.w700,
                      color: ScSaasThemeTokens.gray500,
                    ),
                  ),
                ),
                Text(
                  'Endre',
                  style: dgText(
                    12.5,
                    FontWeight.w800,
                    color: theme.primaryHover,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DugnadNotificationRow extends StatelessWidget {
  const _DugnadNotificationRow({
    required this.item,
    required this.onTap,
  });

  final DugnadNotificationItem item;
  final VoidCallback onTap;

  IconData get _icon {
    switch (item.iconKey) {
      case 'star':
        return Icons.star_rounded;
      case 'sparkle':
        return Icons.auto_awesome_rounded;
      case 'heart':
        return Icons.favorite_rounded;
      case 'shield':
        return Icons.shield_rounded;
      case 'tag':
      case 'box':
        return Icons.inventory_2_outlined;
      case 'share':
        return Icons.ios_share_rounded;
      case 'trophy':
        return Icons.emoji_events_outlined;
      case 'zap':
        return Icons.bolt_rounded;
      case 'truck':
        return Icons.local_shipping_outlined;
      case 'user':
        return Icons.person_outline_rounded;
      case 'flag':
        return Icons.flag_rounded;
      case 'info':
        return Icons.info_outline_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final when = _relativeWhen(item.createdAt);
    final cat = _NotifCat.of(item.category);
    final colors = _notifToneColors(cat.tone, theme);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.dp(16)),
        boxShadow: item.unread
            ? const [
                BoxShadow(
                  color: Color(0x292D1B5B),
                  blurRadius: 3,
                  offset: Offset(0, 2),
                ),
                BoxShadow(
                  color: Color(0x612D1B5B),
                  blurRadius: 26,
                  offset: Offset(0, 14),
                  spreadRadius: -10,
                ),
              ]
            : const [
                BoxShadow(
                  color: Color(0x242D1B5B),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
                BoxShadow(
                  color: Color(0x4D2D1B5B),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                  spreadRadius: -8,
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        borderRadius: BorderRadius.circular(context.dp(16)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(context.dp(16)),
          child: Padding(
            padding: EdgeInsets.all(context.dp(14)),
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
                child: Icon(_icon, size: context.dp(18), color: colors.fg),
              ),
              SizedBox(width: context.dp(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.titleNo,
                      style: dgText(14.5, FontWeight.w800, color: theme.text)
                          .copyWith(letterSpacing: 14.5 * -0.01),
                    ),
                    if (item.bodyNo.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: context.dp(2)),
                        child: Text(
                          item.bodyNo,
                          style: dgText(
                            12.5,
                            FontWeight.w600,
                            height: 1.45,
                            color: ScSaasThemeTokens.gray500,
                          ),
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.only(top: context.dp(5)),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.dp(7),
                              vertical: context.dp(2),
                            ),
                            decoration: BoxDecoration(
                              color: colors.bg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              cat.label,
                              style: dgText(
                                10.5,
                                FontWeight.w800,
                                color: colors.fg,
                              ).copyWith(letterSpacing: 10.5 * 0.02),
                            ),
                          ),
                          if (when.isNotEmpty) ...[
                            SizedBox(width: context.dp(7)),
                            Flexible(
                              child: Text(
                                when,
                                style: dgText(
                                  11.5,
                                  FontWeight.w700,
                                  color: kDgGray400,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.dp(8)),
              if (item.unread)
                Container(
                  width: context.dp(9),
                  height: context.dp(9),
                  margin: EdgeInsets.only(top: context.dp(4)),
                  decoration: BoxDecoration(
                    color: theme.primary,
                    shape: BoxShape.circle,
                  ),
                )
              else
                Padding(
                  padding: EdgeInsets.only(top: context.dp(4)),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: context.dp(16),
                    color: const Color(0xFFCFD1D7),
                  ),
                ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
