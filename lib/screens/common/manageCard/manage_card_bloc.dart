import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../../blocs/bloc.dart';
import '../../../utils/utils.dart';
import '../addCard/add_card.dart';
import '../base_dl.dart';
import 'manage_card.dart';
import 'manage_card_dl.dart';
import 'manage_card_repo.dart';

class ManageCardBloc extends Bloc {
  String tag = "ManageCardBloc>>>";

  BuildContext context;
  final ManageCardRepo _manageCardRepo = ManageCardRepo();

  State<ManageCard> state;

  ManageCardBloc(this.context, this.state) {
    getCardList();
  }

  final _subject = BehaviorSubject<ApiResponse<CardModel>>();
  final _subjectDeleteCard = BehaviorSubject<ApiResponse<BaseModel>>();

  BehaviorSubject<ApiResponse<CardModel>> get subject => _subject;

  BehaviorSubject<ApiResponse<BaseModel>> get subjectDeleteCard => _subjectDeleteCard;

  getCardList() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subject.sink.add(ApiResponse.loading());
      try {
        var response = CardModel.fromJson(await _manageCardRepo.getCardList());

        if (!state.mounted) return;
        String message = getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true)) {
          if ((response.cardList).isNotEmpty) {
            _subject.sink.add(ApiResponse.completed(response));
          } else {
            _subject.sink.add(ApiResponse.error(languages.cardListEmptyMsg));
          }
        } else {
          _subject.sink.add(ApiResponse.error(message));
        }
      } catch (e) {
        logd(tag, e.toString());
        _subject.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      _subject.sink.add(ApiResponse.error(languages.internetConnLostTitle));
      if (!state.mounted) return;
      openSimpleSnackbar( languages.internetConnLostTitle);
    }
  }

  openAddCard() {
    openScreenWithResult(context, const AddCard()).then((value) {
      if (value != null) {
        openSimpleSnackbar( languages.cardAddSuccessful);
        getCardList();
      }
    });
  }

  deleteCard(int cardId) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subjectDeleteCard.sink.add(ApiResponse.loading());
      try {
        var response = BaseModel.fromJson(await _manageCardRepo.removeCard(cardId));

        if (!state.mounted) return;
        String message = getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true)) {
          _subjectDeleteCard.sink.add(ApiResponse.completed(response));
          Navigator.pop(context, true);
          openSimpleSnackbar( languages.removeCardSuccessMsg);
          getCardList();
        } else {
          _subjectDeleteCard.sink.add(ApiResponse.error(message));
        }
      } catch (e) {
        if (!state.mounted) return;
        openSimpleSnackbar( e.toString());
        _subjectDeleteCard.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      if (!state.mounted) return;
      Navigator.pop(context, true);
      _subject.sink.add(ApiResponse.error(languages.internetConnLostTitle));
      openSimpleSnackbar( languages.internetConnLostTitle);
    }
  }

  @override
  void dispose() {
    _subject.close();
    _subjectDeleteCard.close();
  }
}
