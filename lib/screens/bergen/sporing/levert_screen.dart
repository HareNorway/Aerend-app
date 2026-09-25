import 'package:flutter/material.dart';

import '../../../data/ops/tracking_models.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../../../dialogs/reviewDialog/review_dialog_repo.dart';
import '../kasse/kjop_sekvens.dart';
import '../kit/bergen_kit.dart';
import 'hjelp_sheet.dart';
import 'sporing_copy.dart';

/// `levert` (≈L5881–5940 in `Ærend Kunde Bergen.dc.html`) at
/// `/bergen/levert/{id}`: "18:11 Levert. Håper det smaker. to minutter før
/// tiden", **Poeng for denne ordren** (from `GET /api/points/me/ledger?order=`,
/// guarded — hidden on 404), "Levert til deg · koden ble bekreftet av …",
/// "Takk til {bud}" (courier only), "Hvordan gikk det?" (the existing rating),
/// "Noe galt med bestillingen?" → Hjelp, "Ferdig". The referral ticket shows
/// once, after the screen has settled.
class LevertScreen extends StatefulWidget {
  const LevertScreen({
    super.key,
    this.orderId,
    this.tracking,
    this.api,
    this.rating,
  });

  final int? orderId;
  final OpsTracking? tracking;
  final OpsCustomerApi? api;

  /// Injected in tests.
  final Future<void> Function(int orderId, int stars)? rating;

  @override
  State<LevertScreen> createState() => _LevertScreenState();
}

class _LevertScreenState extends State<LevertScreen> {
  bool _routeRead = false;
  int _id = 0;
  OpsTracking? _tracking;
  bool _missing = false;
  Map<String, dynamic>? _points;
  int _stars = 0;
  bool _rated = false;

  OpsCustomerApi get _api => widget.api ?? OpsCustomerApi();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeRead) return;
    _routeRead = true;
    _id =
        widget.orderId ??
        int.tryParse(BergenRoutes.argsOf(context)['id'] ?? '') ??
        0;
    _tracking = widget.tracking;
    if (_tracking == null) {
      _load();
    } else {
      _loadPoints();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showVervebillett(context, orderId: _id, api: _api);
    });
  }

  Future<void> _load() async {
    try {
      final json = await _api.tracking(_id);
      if (!mounted) return;
      setState(() => _tracking = OpsTracking.fromJson(json));
      _loadPoints();
    } catch (_) {
      if (mounted) setState(() => _missing = true);
    }
  }

  Future<void> _loadPoints() async {
    final p = await _api.pointsForOrder(_id);
    if (mounted && p != null) setState(() => _points = p);
  }

  Future<void> _rate(int stars) async {
    setState(() => _stars = stars);
    if (widget.rating != null) {
      await widget.rating!(_id, stars);
    } else {
      try {
        await ReviewDialogRepo().callOrderRatingApi(
          _id,
          stars.toDouble(),
          stars.toDouble(),
          null,
          null,
        );
      } catch (_) {
        // The stars stay; a failed post is not the customer's problem.
      }
    }
    if (mounted) setState(() => _rated = true);
  }

  String _clock(DateTime? t) => t == null ? '' : OpsTracking.hhmm(t);

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final safeTop = MediaQuery.paddingOf(context).top;
    final t = _tracking;
    if (_missing) {
      return Scaffold(
        backgroundColor: BergenTokens.paper,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: BergenTokens.ink,
        ),
        body: Center(
          child: Text(
            SporingCopy.a1_sporing_ikke_funnet,
            style: bText(
              context,
              13,
              weight: FontWeight.w700,
              color: BergenTokens.inkSecondary,
            ),
          ),
        ),
      );
    }
    if (t == null) {
      return const Scaffold(
        backgroundColor: BergenTokens.paper,
        body: Center(
          child: CircularProgressIndicator(color: BergenTokens.teal),
        ),
      );
    }
    final deliveredAt =
        DateTime.tryParse('${t.raw['delivered_at'] ?? ''}')?.toLocal() ??
        DateTime.now();
    final early = t.promisedEnd == null
        ? null
        : t.promisedEnd!.difference(deliveredAt).inMinutes;
    final points = _points;
    final earned =
        (points?['points'] ?? points?['amount'] ?? points?['earned']) as num?;
    final firstTime =
        (points?['first_time_bonus'] ?? points?['first_time']) as num?;
    final leagueGap = points?['league_gap'];
    final storyLine =
        points?['line'] ?? points?['story'] ?? points?['description'];
    final byWhom = t.isPartner
        ? t.deliveredByLabel
        : (t.courier?.firstName ?? SporingCopy.a1_sporing_Budet.toLowerCase());
    final codeConfirmed = t.deliveryCode?.verifiedAt != null;

    return Scaffold(
      backgroundColor: BergenTokens.paper,
      body: ListView(
        padding: EdgeInsets.fromLTRB(16 * s, safeTop + 16 * s, 16 * s, 40 * s),
        children: [
          Text(
            _clock(deliveredAt),
            key: const Key('a1_sporing_levert_klokke'),
            style: bDisplay(
              context,
              40,
              weight: FontWeight.w800,
              color: BergenTokens.ink,
            ).copyWith(letterSpacing: -1),
          ),
          Text(
            '${SporingCopy.a1_sporing_levert_punkt} ${SporingCopy.a1_sporing_haaper}',
            style: bDisplay(
              context,
              22,
              weight: FontWeight.w800,
              color: BergenTokens.ink,
            ),
          ),
          if (early != null && early > 0)
            Text(
              '${_clock(deliveredAt)} · ${SporingCopy.a1_sporing_levert_min_for(early).replaceFirst(RegExp(r'^Levert · |^Delivered · '), '')}',
              key: const Key('a1_sporing_levert_for'),
              style: bText(
                context,
                12.5,
                weight: FontWeight.w700,
                color: BergenTokens.mintDeep,
              ),
            ),
          SizedBox(height: 16 * s),
          if (earned != null)
            Padding(
              padding: EdgeInsets.only(bottom: 12 * s),
              child: BergenCard(
                key: const Key('a1_sporing_poeng'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '+${earned.toInt()}',
                          style: bDisplay(
                            context,
                            30,
                            weight: FontWeight.w800,
                            color: BergenTokens.orange,
                          ),
                        ),
                        SizedBox(width: 6 * s),
                        Flexible(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 5 * s),
                            child: Text(
                              SporingCopy.a1_sporing_poeng_for_ordren,
                              maxLines: 2,
                              style: bText(
                                context,
                                12.5,
                                weight: FontWeight.w700,
                                color: BergenTokens.inkSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (leagueGap is Map)
                      Text(
                        SporingCopy.a1_sporing_liga_gap(
                          ((leagueGap['points'] ?? 0) as num).toInt(),
                          ((leagueGap['place'] ?? 0) as num).toInt(),
                        ),
                        style: bText(
                          context,
                          11.5,
                          weight: FontWeight.w700,
                          color: BergenTokens.teal,
                        ),
                      ),
                    if (firstTime != null && firstTime > 0) ...[
                      SizedBox(height: 6 * s),
                      Text(
                        SporingCopy.a1_sporing_forste_gang(
                          firstTime.toInt(),
                          t.store?.name ?? '',
                        ),
                        style: bText(
                          context,
                          12,
                          weight: FontWeight.w800,
                          color: BergenTokens.ink,
                        ),
                      ),
                      Text(
                        SporingCopy.a1_sporing_en_gang,
                        style: bText(
                          context,
                          10.5,
                          weight: FontWeight.w600,
                          color: BergenTokens.inkFaint,
                        ),
                      ),
                    ],
                    if (storyLine != null) ...[
                      SizedBox(height: 6 * s),
                      Text(
                        '$storyLine',
                        style: bText(
                          context,
                          11.5,
                          weight: FontWeight.w600,
                          color: BergenTokens.inkSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          BergenCard(
            key: const Key('a1_sporing_levert_til_deg'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  codeConfirmed
                      ? SporingCopy.a1_sporing_levert_til_deg(byWhom)
                      : SporingCopy.a1_sporing_levert_til_deg_uten(byWhom),
                  style: bText(
                    context,
                    13,
                    weight: FontWeight.w700,
                    color: BergenTokens.ink,
                  ),
                ),
                if (!t.isPartner && t.courier != null) ...[
                  SizedBox(height: 4 * s),
                  Text(
                    SporingCopy.a1_sporing_takk(t.courier!.firstName),
                    key: const Key('a1_sporing_takk'),
                    style: bText(
                      context,
                      12,
                      weight: FontWeight.w600,
                      color: BergenTokens.inkSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 12 * s),
          BergenCard(
            key: const Key('a1_sporing_vurder'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _rated
                      ? SporingCopy.a1_sporing_takk_vurdering
                      : SporingCopy.a1_sporing_hvordan,
                  style: bDisplay(
                    context,
                    15,
                    weight: FontWeight.w800,
                    color: BergenTokens.ink,
                  ),
                ),
                SizedBox(height: 8 * s),
                Row(
                  children: [
                    for (var i = 1; i <= 5; i++)
                      GestureDetector(
                        key: Key('a1_sporing_stjerne_$i'),
                        behavior: HitTestBehavior.opaque,
                        onTap: _rated ? null : () => _rate(i),
                        child: Padding(
                          padding: EdgeInsets.only(right: 6 * s),
                          child: Icon(
                            i <= _stars
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 32 * s,
                            color: BergenTokens.lantern,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 12 * s),
          BergenCard(
            key: const Key('a1_sporing_noe_galt'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                settings: RouteSettings(name: '/bergen/sporing/$_id/hjelp'),
                builder: (_) =>
                    HjelpScreen(orderId: _id, tracking: t, api: _api),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 12 * s),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    SporingCopy.a1_sporing_noe_galt,
                    style: bText(
                      context,
                      13,
                      weight: FontWeight.w800,
                      color: BergenTokens.ink,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: BergenTokens.inkFaint,
                  size: 20 * s,
                ),
              ],
            ),
          ),
          SizedBox(height: 20 * s),
          BergenCta3d(
            key: const Key('a1_sporing_levert_ferdig'),
            label: SporingCopy.a1_sporing_ferdig,
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ],
      ),
    );
  }
}
