import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:aerend_customer/screens/common/payment/payment_screen_webview.dart';
import 'package:aerend_customer/screens/common/selectPaymentMethod/select_payment_method_dl.dart';

import '../../../blocs/bloc.dart';
import '../../../utils/utils.dart';
import '../walletTransfer/wallet_transfer.dart';
import 'my_wallet_repo.dart';
import 'wallet.dart';
import 'walletTransaction/wallet_transaction.dart';
import 'walletTransaction/wallet_transaction_repo.dart';
import 'wallet_dl.dart';

class WalletBloc extends Bloc {
  final MyWalletRepo _myWalletRepo = MyWalletRepo();
  final WalletTransactionRepo _walletTransactionRepo = WalletTransactionRepo();
  BuildContext context;
  bool setError = true;

  State<Wallet> state;

  WalletBloc(this.context, this.state) {
    getWalletAmount();
    getTransactionList();
  }

  TextEditingController addAmountTEC = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final _walletAmountController = BehaviorSubject<double>.seeded(0);
  final _subjectGetBalance = BehaviorSubject<ApiResponse<WalletBalancePojo>>();
  final _subjectAddAmount = BehaviorSubject<ApiResponse<PaymentBaseModel>>();
  final _subjectTransactions =
      BehaviorSubject<ApiResponse<WalletTransactionPojo>>();

  BehaviorSubject<ApiResponse<WalletBalancePojo>> get subjectGetBalance => _subjectGetBalance;

  BehaviorSubject<ApiResponse<PaymentBaseModel>> get subjectAddAmount => _subjectAddAmount;

  BehaviorSubject<ApiResponse<WalletTransactionPojo>> get subjectTransactions =>
      _subjectTransactions;

  /// `.dgw-txns` "Bevegelser" list — same call the transaction sub-screen uses.
  getTransactionList() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (!connectivityResult.contains(ConnectivityResult.none)) {
      _subjectTransactions.sink.add(ApiResponse.loading());
      try {
        var response = WalletTransactionPojo.fromJson(
            await _walletTransactionRepo.getWalletTransactions());

        if (!state.mounted) return;
        // ignore: use_build_context_synchronously
        String message = getApiMsg(context, response.messageCode, response.message);
        // ignore: use_build_context_synchronously
        if (isApiStatus(context, response.status, message, true)) {
          _subjectTransactions.sink.add(ApiResponse.completed(response));
        } else {
          _subjectTransactions.sink.add(ApiResponse.error(message));
        }
      } catch (e) {
        _subjectTransactions.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      _subjectTransactions.sink
          .add(ApiResponse.error(languages.internetConnLostTitle));
    }
  }

  Stream<double> get walletAmount => _walletAmountController.stream;

  Function(double) get changeWalletAmount => _walletAmountController.sink.add;

  openWalletTransactionScreen() {
    openScreen(context, WalletTransaction(walletAmount: _walletAmountController.valueOrNull ?? 0));
  }

  getWalletAmount() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subjectGetBalance.sink.add(ApiResponse.loading());
      try {
        var response = WalletBalancePojo.fromJson(await _myWalletRepo.getWalletBalance());

        if (!state.mounted) return;
        String message = getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true)) {
          changeWalletAmount(getDoubleFromDynamic(response.walletBalance ?? "0"));
          _subjectGetBalance.sink.add(ApiResponse.completed(response));
        } else {
          _subjectGetBalance.sink.add(ApiResponse.error(message));
        }
      } catch (e) {
        if (!state.mounted) return;
        openSimpleSnackbar(e.toString());
        _subjectGetBalance.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  openSelectPaymentScreen() {
    FocusManager.instance.primaryFocus!.unfocus();
    addAmountToWallet(getDoubleFromDynamic(addAmountTEC.text.trim()), 2);
 /*   openScreenWithResult(
        context,
        AddMoneyToWallet(
          walletAmount: getDoubleFromDynamic(addAmountTEC.text.trim()),
        )).then((value) {
      if (value != null) {
        openSimpleSnackbar(languages.walletAddSuccessful);
        setError = false;
        addAmountTEC.clear();
        getWalletAmount();
      }
    });*/
  }

  addAmountToWallet(double amount, int paymentType) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subjectAddAmount.sink.add(ApiResponse.loading());
      try {
        var response = PaymentBaseModel.fromJson(await _myWalletRepo.addWalletBalance(amount, paymentType));

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
              openSimpleSnackbar(languages.walletAddSuccessful);
              setError = false;
              addAmountTEC.clear();
              getWalletAmount();
              getTransactionList();
              _subjectAddAmount.sink.add(ApiResponse.completed(response));
            },
            onFailed: () {
              openSimpleSnackbar(languages.transactionFailed);
              _subjectAddAmount.sink.add(ApiResponse.error(languages.transactionFailed));
            },
          );
          getWalletAmount();
        } else {
          if (response.status != 3) openSimpleSnackbar(message);
          _subjectAddAmount.sink.add(ApiResponse.error(message));
        }
      } catch (e) {
        if (!state.mounted) return;
        openSimpleSnackbar(e.toString());
        _subjectAddAmount.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  double totalWalletAmount() {
    return _walletAmountController.value;
  }

  @override
  void dispose() {
    addAmountTEC.dispose();
    _walletAmountController.close();
    _subjectGetBalance.close();
    _subjectAddAmount.close();
    _subjectTransactions.close();
  }

  openWalletTransfer() {
    openScreenWithResult(
        context,
        WalletTransfer(
          walletAmount: _walletAmountController.value,
        )).then((value) {
      if (value == true) {
        getWalletAmount();
        getTransactionList();
      }
    });
  }
}
