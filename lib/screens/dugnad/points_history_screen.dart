import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../commonView/skeleton_loaders/dugnad_subpage_skeletons.dart';
import '../../theme/design_scale.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/utils.dart';
import 'dugnad_models.dart';
import 'dugnad_repo.dart';
import 'points_ledger_display.dart';
import '../../ui/kit/ae_theme.dart';
import '../../ui/kit/ae_rise_in.dart';

class PointsHistoryScreen extends StatefulWidget {
  const PointsHistoryScreen({super.key});

  @override
  State<PointsHistoryScreen> createState() => _PointsHistoryScreenState();
}

class _PointsHistoryScreenState extends State<PointsHistoryScreen> {
  final DugnadRepo _repo = DugnadRepo();
  final List<PointsLedgerEntry> _entries = [];
  int _page = 1;
  int _total = 0;
  bool _loading = true;
  bool _loadingMore = false;

  /// Timestamp of the first paint of real (non-skeleton) content. Rows built
  /// within the entrance window stagger in; rows built later (scrolled back
  /// into view, appended pages) render immediately.
  DateTime? _contentShownAt;

  /// Number of rows that fit the first screenful — never stagger past this.
  static const int _staggerCount = 6;

  bool get _inEntranceWindow {
    final shown = _contentShownAt;
    if (shown == null) return false;
    return DateTime.now().difference(shown) <
        const Duration(milliseconds: 1200);
  }

  @override
  void initState() {
    super.initState();
    _load(page: 1, reset: true);
  }

  Future<void> _load({required int page, required bool reset}) async {
    if (reset) {
      setState(() => _loading = true);
    } else {
      setState(() => _loadingMore = true);
    }
    final result = await _repo.getPointsLedger(page: page);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _loadingMore = false;
      _contentShownAt ??= DateTime.now();
      if (result != null) {
        _page = result.page;
        _total = result.total;
        if (reset) {
          _entries
            ..clear()
            ..addAll(result.entries);
        } else {
          _entries.addAll(result.entries);
        }
      }
    });
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('d. MMM yyyy', 'nb').format(dt);
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.aeTheme.background,
      appBar: AppBar(
        backgroundColor: context.aeTheme.background,
        elevation: 0,
        title: Text(
          languages.dugnadPointsHistoryTitle,
          style: aeH2().copyWith(fontSize: 18),
        ),
        iconTheme: IconThemeData(color: context.aeTheme.text),
      ),
      body: _loading
          ? Padding(
              padding: EdgeInsets.fromLTRB(context.dp(20), context.dp(8), context.dp(20), context.dp(24)),
              child: DugnadPointsHistorySkeleton(),
            )
          : RefreshIndicator(
              onRefresh: () => _load(page: 1, reset: true),
              child: _entries.isEmpty
                  ? ListView(
                      children: [
                        AeRiseIn(
                          delay: const Duration(milliseconds: 120),
                          child: Padding(
                            padding: EdgeInsets.all(context.dp(32)),
                            child: Text(
                              languages.dugnadPointsHistoryEmpty,
                              textAlign: TextAlign.center,
                              style: aeBody(color: ScSaasThemeTokens.gray500),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(context.dp(20), context.dp(8), context.dp(20), context.dp(24)),
                      itemCount: _entries.length + (_entries.length < _total ? 1 : 0),
                      separatorBuilder: (_, __) => SizedBox(height: context.dp(8)),
                      itemBuilder: (context, index) {
                        if (index >= _entries.length) {
                          if (!_loadingMore) {
                            _load(page: _page + 1, reset: false);
                          }
                          return Padding(
                            padding: EdgeInsets.all(context.dp(16)),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final entry = _entries[index];
                        final positive = entry.points >= 0;
                        final display = pointsLedgerDisplay(entry, languages);
                        final row = Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(context.dp(14)),
                            border: Border.all(color: ScSaasThemeTokens.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      display.title,
                                      style: aeBody().copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (display.subtitle != null) ...[
                                      SizedBox(height: context.dp(2)),
                                      Text(
                                        display.subtitle!,
                                        style: aeCaption(
                                          color: ScSaasThemeTokens.gray500,
                                        ),
                                      ),
                                    ],
                                    SizedBox(height: context.dp(2)),
                                    Text(
                                      _formatDate(entry.createdAt),
                                      style: aeCaption(
                                        color: ScSaasThemeTokens.gray500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${positive ? '+' : ''}${entry.points}',
                                style: aeH2().copyWith(
                                  fontSize: 18,
                                  color: positive
                                      ? ScSaasThemeTokens.accent
                                      : ScSaasThemeTokens.danger,
                                ),
                              ),
                            ],
                          ),
                        );
                        if (index >= _staggerCount || !_inEntranceWindow) {
                          return row;
                        }
                        return AeRiseIn(
                          delay: Duration(milliseconds: 120 + index * 70),
                          child: row,
                        );
                      },
                    ),
            ),
    );
  }
}
