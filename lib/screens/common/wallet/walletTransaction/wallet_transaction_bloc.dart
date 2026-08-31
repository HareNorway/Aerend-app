import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../../../blocs/bloc.dart';
import '../../../../utils/utils.dart';
import '../my_wallet_repo.dart';
import '../wallet_dl.dart';
import 'wallet_transaction.dart';
import 'wallet_transaction_repo.dart';

class WalletTransactionBloc extends Bloc {
  String tag = "WalletTransBloc>>>";
  BuildContext context;
  double? walletAmount;
  final MyWalletRepo _myWalletRepo = MyWalletRepo();
  final WalletTransactionRepo _walletTransactionRepo = WalletTransactionRepo();

  State<WalletTransaction> state;

  WalletTransactionBloc(this.context, this.walletAmount, this.state) {
    getWalletAmount();
    /*if (walletAmount == null) {
    } else {
      changeWalletAmount(walletAmount);
    }*/
    getTransactionList();
  }

  final _walletAmountController = BehaviorSubject<double>.seeded(0);
  final _subject = BehaviorSubject<ApiResponse<WalletTransactionPojo>>();
  final _subjectGetBalance = BehaviorSubject<ApiResponse<WalletBalancePojo>>();

  BehaviorSubject<ApiResponse<WalletTransactionPojo>> get subject => _subject;

  BehaviorSubject<ApiResponse<WalletBalancePojo>> get subjectGetBalance => _subjectGetBalance;

  Stream<double> get walletAmountStream => _walletAmountController.stream;

  Function(double) get changeWalletAmount => _walletAmountController.sink.add;

  getTransactionList() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subject.sink.add(ApiResponse.loading());
      try {
        var response = WalletTransactionPojo.fromJson(await _walletTransactionRepo.getWalletTransactions());

        if (!state.mounted) return;
        String message = getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true)) {
          if ((response.transactions).isNotEmpty) {
            _subject.sink.add(ApiResponse.completed(response));
          } else {
            _subject.sink.add(ApiResponse.error(languages.noRecordFound));
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
      if(!state.mounted) return;
      openSimpleSnackbar( languages.internetConnLostTitle);
    }
  }

  getWalletAmount() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subjectGetBalance.sink.add(ApiResponse.loading());
      try {
        var response = WalletBalancePojo.fromJson(await _myWalletRepo.getWalletBalance());

        if(!state.mounted) return;
        String message = getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true)) {
          changeWalletAmount(getDoubleFromDynamic(response.walletBalance ?? "0"));
          _subjectGetBalance.sink.add(ApiResponse.completed(response));
        } else {
          _subjectGetBalance.sink.add(ApiResponse.error(message));
        }
      } catch (e) {
        if(!state.mounted) return;
        openSimpleSnackbar( e.toString());
        _subjectGetBalance.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      if(!state.mounted) return;
      openSimpleSnackbar( languages.internetConnLostTitle);
    }
  }

  @override
  void dispose() {
    _subject.close();
    _subjectGetBalance.close();
    _walletAmountController.close();
  }
}
