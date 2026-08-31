import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:aerend_customer/screens/common/payment/payment_screen_webview.dart';

import '../../../blocs/bloc.dart';
import '../../../utils/utils.dart';
import '../manageCard/manage_card_dl.dart';
import '../manageCard/manage_card_repo.dart';
import '../wallet/my_wallet_repo.dart';
import '../wallet/wallet_dl.dart';
import 'select_payment_method.dart';
import 'select_payment_method_dl.dart';
import 'select_payment_method_repo.dart';

class SelectPaymentMethodBloc extends Bloc {
  BuildContext context;
  bool showCash, showWallet;
  int index = 0;
  int id;
  double walletAmount = 0, totalPay;
  String payTo;
  final ManageCardRepo _manageCardRepo = ManageCardRepo();
  final MyWalletRepo _myWalletRepo = MyWalletRepo();
  final SelectPaymentMethodRepo _selectPaymentMethodRepo = SelectPaymentMethodRepo();

  State<SelectPaymentMethod> state;

  SelectPaymentMethodBloc(this.context, this.id, this.payTo, this.totalPay, this.showCash, this.showWallet, this.state) {
    showCash = (showCash && showCashPayment);
    showWallet = (showWallet && showWalletPayment);
    if (showWallet) {
      getWalletAmount();
    } else {
      getSelectedPayment();
    }
  }

  final _subject = BehaviorSubject<ApiResponse<CardModel>>();
  final _subjectPay = BehaviorSubject<ApiResponse<PaymentBaseModel>>();
  final _selectedPaymentMethodController = BehaviorSubject<SelectPaymentMethodItem>();
  final _selectPaymentMethodListController = BehaviorSubject<List<SelectPaymentMethodModel>>();

  BehaviorSubject<ApiResponse<CardModel>> get subject => _subject;

  BehaviorSubject<ApiResponse<PaymentBaseModel>> get subjectPay => _subjectPay;

  Stream<SelectPaymentMethodItem> get selectedPaymentMethod => _selectedPaymentMethodController.stream;

  Stream<List<SelectPaymentMethodModel>> get selectPaymentMethodList => _selectPaymentMethodListController.stream;

  Function(SelectPaymentMethodItem) get changeSelectedPaymentMethod => _selectedPaymentMethodController.sink.add;

  Function(List<SelectPaymentMethodModel>) get changeSelectedPaymentMethodList => _selectPaymentMethodListController.sink.add;

  getSelectedPayment() {
    List<SelectPaymentMethodModel> selectPaymentMethodList = [];
    List<SelectPaymentMethodItem> paymentMethodItemList = [];

    if (showCash) {
      index++;
      paymentMethodItemList.add(SelectPaymentMethodItem(id: index, type: paymentTypeCash, name: languages.cash, icon: CustomIcons.cash));
    }
    if (showWallet) {
      index++;
      paymentMethodItemList.add(SelectPaymentMethodItem(id: index, type: paymentTypeWallet, name: "${languages.wallet} (${getAmountWithCurrency(walletAmount)})", icon: CustomIcons.wallet));
    }
    index++;
    paymentMethodItemList.add(SelectPaymentMethodItem(id: index, type: paymentTypeCard, name: languages.stripe, icon: CustomIcons.card));
    selectPaymentMethodList.add(SelectPaymentMethodModel(title: languages.paymentType, selectPaymentMethodList: paymentMethodItemList));
    changeSelectedPaymentMethodList(selectPaymentMethodList);
    if (showCash) {
      SelectPaymentMethodItem selectPaymentMethodItem = paymentMethodItemList.firstWhere((element) => element.type == paymentTypeCash);
      changeSelectedPaymentMethod(selectPaymentMethodItem);
    } else {
      SelectPaymentMethodItem selectPaymentMethodItem = paymentMethodItemList.first;
      changeSelectedPaymentMethod(selectPaymentMethodItem);
    }
  }

  getWalletAmount() async {
    try {
      _subject.sink.add(ApiResponse.loading());
      var response = WalletBalancePojo.fromJson(await _myWalletRepo.getWalletBalance());

      if (!state.mounted) return;
      String message = getApiMsg(context, response.messageCode, response.message);
      if (isApiStatus(context, response.status, message, true, showMess: false)) {
        walletAmount = getDoubleFromDynamic(response.walletBalance ?? "0");
        getSelectedPayment();
        _subject.sink.add(ApiResponse.completed());
      }
    } catch (e) {
      logd(tag, e.toString());
    }
  }

  payForRideApiCall(int paymentType) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subjectPay.sink.add(ApiResponse.loading());
      try {
        var response = PaymentBaseModel.fromJson(await _selectPaymentMethodRepo.payForRide(id, 0, paymentType));

        if (!state.mounted) return;
        String message = getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true)) {
          paymentMethodCheck(
            context,
            paymentType,
            successUrl: response.successUrl,
            failedUrl: response.failedUrl,
            redirectUrl: response.redirectUrl,
            onSuccess: () {
              _subjectPay.sink.add(ApiResponse.completed(response));
              Navigator.pop(context, true);
            },
            onFailed: () {
              openSimpleSnackbar(languages.transactionFailed);
              _subjectPay.sink.add(ApiResponse.error(languages.transactionFailed));
            },
          );
        } else {
          _subjectPay.sink.add(ApiResponse.error(message));
        }
      } catch (e) {
        if (!state.mounted) return;
        openSimpleSnackbar(e.toString());
        _subjectPay.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      _subjectPay.sink.add(ApiResponse.error(languages.internetConnLostTitle));
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  addCardList(List<CardListItem> cardList) {
    List<SelectPaymentMethodModel> selectPaymentMethodList = _selectPaymentMethodListController.value;
    List<SelectPaymentMethodItem> paymentMethodItemList = [];
    int isExist = selectPaymentMethodList.indexWhere((element) => element.showAddCard);
    if (isExist != -1) {
      selectPaymentMethodList.removeAt(isExist);
    }
    index = 0;
    for (var element in selectPaymentMethodList) {
      index = index + element.selectPaymentMethodList.length;
    }
    for (var element in cardList) {
      index++;
      paymentMethodItemList.add(SelectPaymentMethodItem(id: index, type: paymentTypeCard, name: element.cardNumber, cardListItem: element, icon: CustomIcons.card));
    }
    selectPaymentMethodList.add(SelectPaymentMethodModel(title: languages.creditDebitCard, selectPaymentMethodList: paymentMethodItemList, showAddCard: true));
    changeSelectedPaymentMethodList(selectPaymentMethodList);
  }

  payNow() {
    SelectPaymentMethodItem selectPaymentMethodItem = _selectedPaymentMethodController.value;
    switch (selectPaymentMethodItem.type) {
      case paymentTypeCash:
        pay(paymentTypeCash);
        break;
      case paymentTypeCard:
        pay(paymentTypeCard);
        break;
      case paymentTypeWallet:
        if (!(walletAmount >= totalPay)) {
          openSimpleSnackbar(languages.insufficientWalletBalance);
        } else {
          pay(paymentTypeWallet);
        }
        break;
    }
  }

  pay(int paymentType) {
    switch (payTo) {
      case courier:
      case deliveries:
        Navigator.pop(context, {"paymentType": paymentType});
        break;
      case rides:
        payForRideApiCall(paymentType);
        break;
      case wallet:
        break;
    }
  }

  @override
  void dispose() {
    _subject.close();
    _subjectPay.close();
    _selectedPaymentMethodController.close();
    _selectPaymentMethodListController.close();
  }
}
