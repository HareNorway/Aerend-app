import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../../blocs/bloc.dart';
import '../../../commonView/common_view.dart';
import '../../../commonView/modal_ui.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../base_dl.dart';
import 'wallet_transfer.dart';
import 'wallet_transfer_dl.dart';
import 'wallet_transfer_repo.dart';

class WalletTransferBloc extends Bloc {
  var searchUser = BehaviorSubject<ApiResponse<UserSearchModel>?>();
  var transferToWallet = BehaviorSubject<ApiResponse<BaseModel>>();
  double walletAmount;
  BuildContext context;
  WalletTransferRepo walletTransferRepo = WalletTransferRepo();
  TextEditingController textEditingController = TextEditingController();

  TextEditingController textBeneficialController = TextEditingController();
  TextEditingController textNumberController = TextEditingController();
  TextEditingController textEmailController = TextEditingController();
  TextEditingController textAmountController = TextEditingController();
  TransferUserList? transferUserList;

  final formKey = GlobalKey<FormState>();

  State<WalletTransfer> state;

  WalletTransferBloc(this.context, this.walletAmount, this.state);

  resetUser() {
    textEditingController.text = "";
    transferUserList = null;
    textBeneficialController.text = "";
    textNumberController.text = "";
    textEmailController.text = "";
    textAmountController.text = "";
    // searchUser.add(null);
  }

  searchUsers(String search) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      searchUser.add(ApiResponse.loading());
      try {
        var response = UserSearchModel.fromJson(
          await walletTransferRepo.findUser(search),
        );

        if (!state.mounted) return;
        String message = getApiMsg(
          context,
          response.messageCode,
          response.message,
        );
        if (isApiStatus(
          context,
          response.status,
          message,
          true,
          showMess: false,
        )) {
          searchUser.add(ApiResponse.completed(response));
        } else {
          searchUser.add(ApiResponse.error(message));
        }
      } catch (e) {
        // openSimpleSnackbar( e.toString());
        searchUser.add(ApiResponse.error(e.toString()));
      }
    } else {
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  transferToUser() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      transferToWallet.add(ApiResponse.loading());
      try {
        double amount = getDoubleFromDynamic(textAmountController.text);
        var response = BaseModel.fromJson(
          await walletTransferRepo.transferWalletBalance(
            amount,
            transferUserList?.transferId ?? 0,
            transferUserList?.walletProviderType ?? 0,
          ),
        );

        if (!state.mounted) return;
        String message = getApiMsg(
          context,
          response.messageCode,
          response.message,
        );
        if (isApiStatus(context, response.status, message, true)) {
          walletAmount = walletAmount - amount;
          showTransferDialog(amount);
          resetUser();
          transferToWallet.add(ApiResponse.completed(response));
        } else {
          transferToWallet.add(ApiResponse.error(message));
        }
      } catch (e) {
        if (!state.mounted) return;
        openSimpleSnackbar(e.toString());
        transferToWallet.add(ApiResponse.error(e.toString()));
      }
    } else {
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  showTransferDialog(double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        double iconSize = deviceAverageSize * 0.15;
        return Dialog(
          insetPadding: EdgeInsets.all(deviceAverageSize * 0.03),
          backgroundColor: Colors.transparent,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: ScSaasThemeTokens.card,
                  borderRadius: BorderRadius.circular(deviceAverageSize * 0.02),
                  border: Border.all(color: ScSaasThemeTokens.border),
                ),
                width: double.infinity,
                padding: EdgeInsetsDirectional.only(
                  bottom: deviceHeight * 0.018,
                  top: iconSize / 2,
                  start: deviceWidth * 0.04,
                  end: deviceWidth * 0.04,
                ),
                margin: EdgeInsetsDirectional.only(top: iconSize / 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ModalUi.handle(),
                    const SizedBox(height: 12),
                    Text(
                      languages.success,
                      textAlign: TextAlign.start,
                      style: bodyText(
                        fontSize: 0.045,
                        textColor: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: bodyText(fontSize: textSizeBig),
                        children: [
                          TextSpan(text: "${languages.successTransaction}\n"),
                          TextSpan(
                            text: getAmountWithCurrency(amount),
                            style: bodyText(
                              fontSize: textSizeBig,
                              fontWeight: FontWeight.bold,
                              textColor: ScSaasThemeTokens.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CustomRoundedButton(
                      context,
                      languages.ok,
                      () {
                        Navigator.pop(context);
                        Navigator.pop(context, true);
                      },
                      minWidth: 1,
                      setBorder: false,
                      minHeight: 0.05,
                      textColor: colorWhite,
                      textSize: textSizeSmall,
                      textAlign: TextAlign.center,
                      maxLine: 1,
                      bgColor: ScSaasThemeTokens.primary,
                      margin: EdgeInsetsDirectional.only(
                        top: deviceAverageSize * 0.02,
                        start: deviceAverageSize * 0.02,
                        end: deviceAverageSize * 0.02,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: iconSize,
                width: iconSize,
                padding: EdgeInsets.all(iconSize / 4),
                decoration: BoxDecoration(
                  color: ScSaasThemeTokens.accent,
                  borderRadius: BorderRadius.circular(iconSize / 2),
                ),
                child: Image.asset(
                  "assets/images/check.png",
                  fit: BoxFit.contain,
                  color: colorWhite,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    searchUser.close();
    transferToWallet.close();
  }
}
