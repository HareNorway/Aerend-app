import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../../blocs/bloc.dart';
import '../../../utils/utils.dart';
import '../base_dl.dart';
import '../homeMainV1/home_main_v1.dart';
import '../login/login.dart';
import 'select_language_and_currency.dart';
import 'select_language_and_currency_dl.dart';
import 'select_language_and_currency_repo.dart';

class SelectLanguageAndCurrencyBloc extends Bloc {
  final SelectLanguageAndCurrencyRepo _languageAndCurrencyRepo = SelectLanguageAndCurrencyRepo();
  BuildContext context;

  State<SelectLanguageAndCurrency> state;

  SelectLanguageAndCurrencyBloc(this.context, this.state) {
    getCurrencyData();
    getLanguageData();
  }

  List<LanguageListItem> spLanguage = [
    LanguageListItem("English", "en"),
    LanguageListItem("Norsk", "no"),//Norwegian
    // LanguageListItem("Svenska", "sv"),//Swedish
    // LanguageListItem("Dansk", "da"),//danish
    // LanguageListItem("Español", "es"),//spanish
  ];
  LanguageListItem? language;
  CurrencyListItem? currency;
  final _languageController = BehaviorSubject<List<LanguageListItem>>();
  final _selectedLanguageController = BehaviorSubject<LanguageListItem>();
  final _selectedCurrencyController = BehaviorSubject<CurrencyListItem>();
  final _languageAndCurrencySubject = BehaviorSubject<ApiResponse<LanguageAndCurrencyResponse>>();
  final BehaviorSubject<ApiResponse<BaseModel>> _updateSubject = BehaviorSubject<ApiResponse<BaseModel>>();

  BehaviorSubject<ApiResponse<BaseModel>> get updateSubject => _updateSubject;

  Stream<List<LanguageListItem>> get streamLanguage => _languageController.stream;

  ValueStream<ApiResponse<LanguageAndCurrencyResponse>> get languageAndCurrencySubject => _languageAndCurrencySubject.stream;

  Stream<LanguageListItem> get streamSelectedLanguage => _selectedLanguageController.stream;

  Stream<CurrencyListItem> get streamSelectedCurrency => _selectedCurrencyController.stream;

  void setSelectedLanguage(LanguageListItem language) {
    this.language = language;
    _selectedLanguageController.sink.add(language);
  }

  void setSelectedCurrency(CurrencyListItem currency) {
    this.currency = currency;
    _selectedCurrencyController.sink.add(currency);
  }

  void setLanguageData(List<LanguageListItem> languageList) {
    _languageController.sink.add(languageList);
  }

  getLanguageData() {
    int index = spLanguage.indexWhere((element) => element.languageCode == prefGetString(prefSelectedLanguageCode));
    if (index == -1) {
      language = spLanguage[0];
    } else {
      language = spLanguage[index];
    }
    setSelectedLanguage(language!);
    _languageController.sink.add(spLanguage);
  }

  getCurrencyData() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _languageAndCurrencySubject.sink.add(ApiResponse.loading());
      try {
        var response = LanguageAndCurrencyResponse.fromJson(await _languageAndCurrencyRepo.getLanguageAndCurrency());

        if (!state.mounted) return;
        String message = getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true)) {
          if ((response.currencyList).isNotEmpty) {
            int index = response.currencyList.indexWhere((element) => element.currencySymbol == prefGetString(prefSelectedCurrency));
            if (index == -1) {
              currency = response.currencyList[0];
            } else {
              currency = response.currencyList[index];
            }
            setSelectedCurrency(currency!);
          }
          _languageAndCurrencySubject.sink.add(ApiResponse.completed(response));
        } else {
          _languageAndCurrencySubject.sink.add(ApiResponse.error(message));
        }
      } catch (e) {
        if (!state.mounted) return;
        openSimpleSnackbar( e.toString());
        _languageAndCurrencySubject.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      if (!state.mounted) return;
      openSimpleSnackbar( languages.internetConnLostTitle);
    }
  }

  updateLanguageAndCurrency(bool isFromHome) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _updateSubject.sink.add(ApiResponse.loading());
      try {
        var response = BaseModel.fromJson(await _languageAndCurrencyRepo.updateCountryAndCurrency(
            language?.languageCode ?? defaultLanguage, currency?.currencySymbol ?? defaultCurrency));

        if (!state.mounted) return;
        String message = getApiMsg(context, response.messageCode, response.message);
        _updateSubject.sink.add(ApiResponse.completed(response));
        if (isApiStatus(context, response.status, message, true)) {
          prefSetString(prefSelectedCurrency, currency?.currencySymbol ?? defaultCurrency);
          setChangedLanguage(context, language!.languageCode, state, nextAction: () {
            openScreenWithClearPrevious(context, isFromHome ? const HomeMainV1() : const Login());
          });
        }
      } catch (e) {
        if (!state.mounted) return;
        openSimpleSnackbar( e.toString());
        _updateSubject.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      if (!state.mounted) return;
      openSimpleSnackbar( languages.internetConnLostTitle);
    }
  }

  void submit(BuildContext context, bool isFromHome) {
    if (!isFromHome) {
      prefSetString(prefSelectedCurrency, currency?.currencySymbol ?? defaultCurrency);
      setChangedLanguage(context, language!.languageCode, state, nextAction: () {
        openScreenWithClearPrevious(context, const Login());
      });
    } else {
      updateLanguageAndCurrency(isFromHome);
    }
  }

  @override
  void dispose() {
    _updateSubject.close();
    _languageController.close();
    _languageAndCurrencySubject.close();
    _selectedLanguageController.close();
    _selectedCurrencyController.close();
  }
}
