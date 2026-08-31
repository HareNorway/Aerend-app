import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../../blocs/bloc.dart';
import '../../../utils/payment_card.dart';
import '../../../utils/utils.dart';
import '../base_dl.dart';
import 'add_card.dart';
import 'add_card_repo.dart';

class AddCardBloc extends Bloc {
  BuildContext context;
  final AddCardRepo _addCardRepo = AddCardRepo();

  State<AddCard> state;

  AddCardBloc(this.context, this.state);

  TextEditingController cardHolderNameTEC = TextEditingController();
  TextEditingController cardNumberTEC = TextEditingController();
  TextEditingController expiredDateTEC = TextEditingController();
  TextEditingController cvvTEC = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final _cardTypeController = BehaviorSubject<CardType>();
  final _subject = BehaviorSubject<ApiResponse<BaseModel>>();

  BehaviorSubject<ApiResponse<BaseModel>> get subject => _subject;

  Stream<CardType> get cardType => _cardTypeController.stream;

  Function(CardType) get changeCardType => _cardTypeController.sink.add;

  changeCardNumber(String value) {
    cardNumberTEC.text = value;
    String input = CardUtils.getCleanedNumber(value);
    _cardTypeController.sink.add(CardUtils.getCardTypeFrmNumber(input));
  }

  addCard() async {
    FocusManager.instance.primaryFocus!.unfocus();
    if (formKey.currentState?.validate() ?? false) {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        _subject.sink.add(ApiResponse.loading());
        try {
          List<int> expiryDate = CardUtils.getExpiryDate(expiredDateTEC.text);
          var response = BaseModel.fromJson(await _addCardRepo.addCard(cardHolderNameTEC.text.trim(), cardNumberTEC.text.trim().replaceAll(" ", ""),
              expiryDate[0].toString(), expiryDate[1].toString(), cvvTEC.text.trim()));

          if (!state.mounted) return;
          String message = getApiMsg(context, response.messageCode, response.message);
          if (isApiStatus(context, response.status, message, true, showMess: false)) {
            _subject.sink.add(ApiResponse.completed(response));
            Navigator.pop(context, true);
          } else {
            _subject.sink.add(ApiResponse.error(message));
          }
        } catch (e) {
          if (!state.mounted) return;
          openSimpleSnackbar( e.toString());
          _subject.sink.add(ApiResponse.error(e.toString()));
        }
      } else {
        _subject.sink.add(ApiResponse.error(languages.internetConnLostTitle));
        if (!state.mounted) return;
        openSimpleSnackbar( languages.internetConnLostTitle);
      }
    }
  }

  @override
  void dispose() {
    cardHolderNameTEC.dispose();
    cardNumberTEC.dispose();
    cvvTEC.dispose();
    expiredDateTEC.dispose();
    _cardTypeController.close();
    _subject.close();
  }
}
