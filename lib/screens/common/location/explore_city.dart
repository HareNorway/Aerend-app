import 'package:flutter/material.dart';
import 'package:aerend_customer/networking/api_base_helper.dart';
import 'package:aerend_customer/screens/common/homeMainV1/home_main_v1.dart';

import '../../../utils/utils.dart';
import '../../dugnad/widgets/dugnad_rise_in.dart';
import '../../dugnad/widgets/dugnad_subpage_shell.dart';
import '../account/account_widgets.dart';
import '../account/settings_design_kit.dart';
import './explore_city_bloc.dart';

/// «Velg by» — mirrors design `settings-screens.jsx` `ExploreCityScreen`
/// (`.tk-head` + `.dgm-locwrap` search with GPS button + `.dgx-city` rows).
class ExploreCity extends StatefulWidget {
  const ExploreCity({super.key});

  @override
  ExploreCityState createState() => ExploreCityState();
}

class ExploreCityState extends State<ExploreCity> {
  ExploreCityBloc? bloc;

  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  /// The backend marks the "pick an address" entry with this city name; every
  /// other city is not live yet.
  static const String _liveCityName = 'Velg Adresse';

  @override
  void initState() {
    super.initState();
    bloc = ExploreCityBloc(context, this);
  }

  @override
  void didChangeDependencies() {
    bloc = ExploreCityBloc(context, this);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDgPageBackground,
      body: DugnadFixedTypography(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AccountTkHead(
                title: 'Velg by', // TODO(l10n)
                onBack: () => openScreenWithResult(context, const HomeMainV1()),
              ),
              Expanded(
                child: StreamBuilder<ApiResponse>(
                  stream: bloc!.subject,
                  builder: (context, snapshot) {
                    final status = snapshot.data?.status;
                    if (status == Status.completed) {
                      final cityList =
                          (snapshot.data!.data?["reen_cities"] as List?) ??
                              const [];
                      if (cityList.isEmpty) {
                        return _message(languages.locationMapError);
                      }
                      return _cityList(cityList);
                    }
                    if (status == Status.error) {
                      return _message(languages.locationMapError);
                    }
                    return const ExploreCityShimmer(enabled: true);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _message(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: dgText(14.5, FontWeight.w600),
          ),
        ),
      );

  /// `.ae-body` — `.dgm-locwrap` then a 12px-gapped column of `.dgx-city`.
  Widget _cityList(List<dynamic> cityList) {
    final hits = cityList.where((city) {
      if (_query.isEmpty) return true;
      final haystack =
          '${_cityName(city)}${_cityArea(city)}'.toLowerCase();
      return haystack.contains(_query.toLowerCase());
    }).toList();

    return SingleChildScrollView(
      // .ae-body { padding: 0 18px 120px; gap: 12 }
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DgLocationSearchField(
            controller: _searchController,
            hint: 'Søk etter by …', // TODO(l10n)
            onChanged: (value) => setState(() => _query = value.trim()),
            onLocate: () => _pickCity(_liveCityName),
            locateTooltip: 'Bruk min posisjon', // TODO(l10n)
          ),
          for (var i = 0; i < hits.length; i++) ...[
            const SizedBox(height: 12),
            DugnadRiseIn(
              delay: Duration(milliseconds: 120 + (i * 70)),
              child: _cityRow(hits[i]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _cityRow(dynamic city) {
    final name = _cityName(city);
    final live = name == _liveCityName;
    return DgxCityRow(
      name: name,
      subtitle: _citySubtitle(city),
      live: live,
      soonLabel: 'Snart', // TODO(l10n)
      onTap: () => _pickCity(name),
    );
  }

  /// Unchanged selection behaviour: the live entry opens Home, everything else
  /// shows the "coming soon" dialog.
  void _pickCity(String name) {
    if (name == _liveCityName) {
      openScreenWithResult(context, const HomeMainV1());
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            languages.feed_coming_soon,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(languages.close),
            ),
          ],
        );
      },
    );
  }

  String _cityName(dynamic city) => '${city['city'] ?? ''}';

  /// `.dgx-city .s` — "{area}" and/or "{n} klubber" when the API supplies them.
  String _cityArea(dynamic city) {
    for (final key in const ['area', 'state', 'region', 'county']) {
      final value = city[key];
      if (value != null && '$value'.trim().isNotEmpty) return '$value';
    }
    return '';
  }

  String _citySubtitle(dynamic city) {
    final parts = <String>[];
    final area = _cityArea(city);
    if (area.isNotEmpty) parts.add(area);
    for (final key in const ['clubs', 'club_count', 'total_clubs']) {
      final value = city[key];
      final count = value is num ? value.toInt() : int.tryParse('$value');
      if (count != null && count > 0) {
        parts.add('$count klubber'); // TODO(l10n)
        break;
      }
    }
    return parts.join(' · ');
  }
}

class ExploreCityShimmer extends StatelessWidget {
  final bool enabled;

  const ExploreCityShimmer({super.key, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: deviceWidth,
      child: Center(
        child: LoadImageSimple(
          image: 'assets/images/google-map-loading.png',
          width: deviceWidth / 2,
        ),
      ),
    );
  }
}
