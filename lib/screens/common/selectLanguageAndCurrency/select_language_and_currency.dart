import 'package:flutter/material.dart';

import '../../../commonView/common_view.dart';
import '../../../networking/api_base_helper.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../../dugnad/widgets/dugnad_rise_in.dart';
import '../../dugnad/widgets/dugnad_subpage_shell.dart';
import '../account/account_widgets.dart';
import '../account/settings_design_kit.dart';
import '../base_dl.dart';
import 'select_language_and_currency_bloc.dart';
import 'select_language_and_currency_dl.dart';
import 'select_language_and_currency_shimmer.dart';

/// «Språk og valuta» — mirrors design `settings-screens.jsx` `LanguageScreen`
/// (`.tk-head` + `.dg-label`/`.dgs-list` språk + `.dg-label`/`.dgs-list` valuta
/// + primary "Lagre valg").
///
/// The first-run variant (`isFromHome == false`, opened from splash) keeps the
/// welcome copy above the two lists and routes to Login instead of Home.
class SelectLanguageAndCurrency extends StatefulWidget {
  final bool isFromHome;

  const SelectLanguageAndCurrency({super.key, this.isFromHome = false});

  @override
  State<StatefulWidget> createState() => _SelectLanguageAndCurrencyState();
}

class _SelectLanguageAndCurrencyState extends State<SelectLanguageAndCurrency> {
  SelectLanguageAndCurrencyBloc? _bloc;

  @override
  void didChangeDependencies() {
    if (_bloc == null && mounted) {
      _bloc = SelectLanguageAndCurrencyBloc(context, this);
    }

    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _bloc!.dispose();
    super.dispose();
  }

  /// `.dgs-list .row .fl` — flag emoji per language code.
  static const Map<String, String> _flags = {
    'en': '🇬🇧',
    'no': '🇳🇴',
    'nb': '🇳🇴',
    'nn': '🇳🇴',
    'da': '🇩🇰',
    'sv': '🇸🇪',
    'es': '🇪🇸',
  };

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
              if (widget.isFromHome)
                AccountTkHead(
                  title: 'Språk og valuta', // TODO(l10n)
                  onBack: () => Navigator.maybePop(context),
                ),
              Expanded(
                child: SingleChildScrollView(
                  // .ae-body { padding: 0 18px 120px }
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!widget.isFromHome) _welcomeHead(),
                      DugnadRiseIn(
                        delay: const Duration(milliseconds: 120),
                        child: _languageSection(),
                      ),
                      const SizedBox(height: 16),
                      DugnadRiseIn(
                        delay: const Duration(milliseconds: 190),
                        child: _currencySection(),
                      ),
                      const SizedBox(height: 16),
                      DugnadRiseIn(
                        delay: const Duration(milliseconds: 260),
                        child: _saveButton(_bloc!),
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

  /// First-run head — `.dg-auth-head` type scale over the pickers.
  Widget _welcomeHead() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Velkommen til Reen Dugnad!', // TODO(l10n)
            textAlign: TextAlign.center,
            style: dgText(26, FontWeight.w800,
                height: 1.12, letterSpacingEm: -0.02),
          ),
          const SizedBox(height: 8),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 268),
              child: Text(
                'Velg språk og valuta før du logger inn.', // TODO(l10n)
                textAlign: TextAlign.center,
                style: dgText(
                  14,
                  FontWeight.w600,
                  height: 1.45,
                  color: ScSaasThemeTokens.primaryHover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// `.dg-label` "Språk" + `.dgs-list` of flag / name / check rows.
  Widget _languageSection() {
    final bloc = _bloc!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DgLabel(languages.selectLanguage),
        StreamBuilder<LanguageListItem>(
          stream: bloc.streamSelectedLanguage,
          initialData: bloc.language,
          builder: (context, snap) {
            final selected = snap.data;
            return DgsList(
              rows: bloc.spLanguage
                  .map(
                    (item) => DgsChoiceRow(
                      glyph: _flags[item.languageCode] ?? '🌐',
                      name: item.languageName,
                      selected: selected?.languageCode == item.languageCode,
                      onTap: () => bloc.setSelectedLanguage(item),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  /// `.dg-label` "Valuta" + `.dgs-list` of symbol / name / check rows.
  Widget _currencySection() {
    final bloc = _bloc!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DgLabel(languages.selectCurrency),
        StreamBuilder<ApiResponse<LanguageAndCurrencyResponse>>(
          stream: bloc.languageAndCurrencySubject,
          builder: (context, snapCurrency) {
            switch (snapCurrency.data?.status) {
              case Status.completed:
                final currencyList = snapCurrency.data?.data?.currencyList ?? [];
                if (currencyList.isEmpty) {
                  return const SelectLanguageAndCurrencyShimmer(enabled: true);
                }
                return StreamBuilder<CurrencyListItem>(
                  stream: bloc.streamSelectedCurrency,
                  initialData: bloc.currency,
                  builder: (context, snapSelected) {
                    final selected = snapSelected.data;
                    return DgsList(
                      rows: currencyList
                          .map(
                            (item) => DgsChoiceRow(
                              glyph: item.currencySymbol,
                              glyphIsSymbol: true,
                              name: item.currencyName,
                              selected:
                                  selected?.currencyId == item.currencyId,
                              onTap: () => bloc.setSelectedCurrency(item),
                            ),
                          )
                          .toList(),
                    );
                  },
                );
              case Status.error:
                return Error(
                  onRetryPressed: () => bloc.getCurrencyData(),
                  errorMessage: snapCurrency.data!.message,
                );
              case Status.loading:
              case null:
                return const SelectLanguageAndCurrencyShimmer(enabled: true);
            }
          },
        ),
      ],
    );
  }

  /// `.ae-btn.ae-btn--primary` — "Lagre valg" (check icon) / first-run login CTA.
  Widget _saveButton(SelectLanguageAndCurrencyBloc bloc) => StreamBuilder(
        stream: bloc.streamSelectedCurrency,
        builder: (context, selectedItemSnapshot) {
          return StreamBuilder<ApiResponse<BaseModel>>(
            stream: bloc.updateSubject.stream,
            builder: (context, snap) {
              final isLoading =
                  snap.hasData && snap.data?.status == Status.loading;
              return DgPrimaryButton(
                label: widget.isFromHome
                    ? 'Lagre valg' // TODO(l10n)
                    : languages.loginToAerend,
                icon: widget.isFromHome ? Icons.check_rounded : null,
                isLoading: isLoading,
                onPressed: (!selectedItemSnapshot.hasData || isLoading)
                    ? null
                    : () => bloc.submit(context, widget.isFromHome),
              );
            },
          );
        },
      );
}
