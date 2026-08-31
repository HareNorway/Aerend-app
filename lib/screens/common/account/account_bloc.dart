import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:aerend_customer/screens/common/login/login_dl.dart';
import 'package:aerend_customer/screens/common/login/login_repo.dart';
import 'package:aerend_customer/screens/common/wallet/my_wallet_repo.dart';
import 'package:aerend_customer/screens/common/wallet/wallet_dl.dart';

import '../../../blocs/bloc.dart';
import '../../../dialogs/simple_dialog_util.dart';
import '../../dugnad/dugnad_sheet.dart';
import '../../../utils/utils.dart';
import '../../dugnad/dugnad_state.dart';
import '../base_dl.dart';
import '../changePassword/change_password.dart';
import '../chatHistory/chat_history.dart';
import '../chatting/chatting.dart';
import '../editProfile/edit_profile.dart';
import '../emergency_contact.dart';
import '../helpAndSupport/help_and_support.dart';
import '../home/home_repo.dart';
import '../inviteFriend/invite_friend.dart';
import '../manageAddress/manage_address.dart';
import '../manageCard/manage_card.dart';
import '../selectLanguageAndCurrency/select_language_and_currency.dart';
import 'account.dart';
import 'account_dl.dart';

class AccountBloc extends Bloc {
  late BuildContext context;
  final HomeRepo _homeRepo = HomeRepo();
  final MyWalletRepo _myWalletRepo = MyWalletRepo();

  final State<Account> state;

  AccountBloc(this.context, this.state) {
    // Seed stream immediately with cached value so the UI doesn't show blank
    final cached = prefGetString(prefAerendCredit);
    if (cached.isNotEmpty) _hareCreditController.sink.add(cached);
    getProfile();
    getDrawerData();
    setUserData();
    if (!DugnadState.instance.isDugnadMode) {
      getWalletBalance();
    }
  }

  final _accountItemController = BehaviorSubject<List<AccountItem>>();
  final _userNameController = BehaviorSubject<String>();
  final _profileImgController = BehaviorSubject<String>();
  final _hareCreditController = BehaviorSubject<String>();
  final _subjectLogout = BehaviorSubject<ApiResponse<BaseModel>>();

  BehaviorSubject<ApiResponse<BaseModel>> get subjectLogout => _subjectLogout;

  Stream<List<AccountItem>> get accountItem => _accountItemController.stream;

  Stream<String> get userName => _userNameController.stream;

  Stream<String> get profileImg => _profileImgController.stream;

  Stream<String> get hareCredit => _hareCreditController.stream;

  Function(List<AccountItem>) get changeAccountItem =>
      _accountItemController.sink.add;

  Function(String) get changeUserName => _userNameController.sink.add;

  Function(String) get changeProfileImg => _profileImgController.sink.add;

  logoutApiCall() async {
    if (!hasValidAuthSession()) {
      _subjectLogout.sink.add(ApiResponse.completed(BaseModel()));
      if (!state.mounted) return;
      logout(context);
      return;
    }

    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      _subjectLogout.sink.add(ApiResponse.completed(BaseModel()));
      if (!state.mounted) return;
      logout(context);
      return;
    }

    _subjectLogout.sink.add(ApiResponse.loading());
    try {
      final response =
          BaseModel.fromJson(await _homeRepo.callLogoutApi());

      if (!state.mounted) return;
      _subjectLogout.sink.add(ApiResponse.completed(response));

      if (response.status != 1 && response.message.isNotEmpty) {
        openSimpleSnackbar(response.message);
      }
      logout(context);
    } catch (e) {
      if (!state.mounted) return;
      _subjectLogout.sink.add(ApiResponse.error(e.toString()));
      logout(context);
    }
  }

  getProfile() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      try {
        var response = LoginPojo.fromJson(await LoginRepo().getProfile());

        if (!state.mounted) return;
        // Refresh profile quietly. Status 4/5 (token mismatch / user not found)
        // must not blank the Dugnad Profile tab — local prefs still render the
        // header while dugnad section loads what it can.
        if (isApiStatus(
          context,
          response.status,
          response.message,
          false,
          showMess: response.status == 1,
        )) {
          await setDataInPref(response);
          // Do not push to _hareCreditController here — getWalletBalance() is
          // the authoritative source and runs concurrently. Pushing here would
          // race and potentially overwrite the correct wallet balance.
          setUserData();
        }
      } catch (_) {
        // Keep cached profile UI; avoid toast spam on Profile open.
      }
    }
  }

  getDrawerData() {
    List<AccountItem> accountItemsList = [
      AccountItem(AccountEnum.myProfile, CustomIcons.myAccountEditProfile,
          languages.myProfile),
      AccountItem(AccountEnum.changePassword,
          CustomIcons.myAccountChangePassword, languages.changePassword),
      // AccountItem(AccountEnum.liveChat, CustomIcons.my_account_live_chat, languages.liveChat),
      AccountItem(AccountEnum.manageAddress, CustomIcons.myAccountManageAddress,
          languages.manageAddress),
      if (showInviteFriends)
        AccountItem(AccountEnum.inviteFriend, CustomIcons.myAccountInviteFriend,
            languages.inviteFriend),
      AccountItem(AccountEnum.helpAndSupport,
          CustomIcons.myAccountHelpAndSupport, languages.helpSupport),
      if (showChatWithAdmin)
        AccountItem(AccountEnum.chatWithAdmin,
            CustomIcons.myAccountChatWithAdmin, languages.chatWithAdmin),
      AccountItem(AccountEnum.preference, CustomIcons.myAccountPreferences,
          languages.preference),
      // AccountItem(AccountEnum.myCoupons, CustomIcons.my_account_my_coupons, languages.myCoupons, size: 0.03),
      if (showEmergencyNumber)
        AccountItem(AccountEnum.emergencyContact,
            CustomIcons.myAccountEmergencyContact, languages.emergencyContact),
      AccountItem(
          AccountEnum.logout, CustomIcons.myAccountLogout, languages.logout)
    ];
    if (prefGetString(prefLoginType) != loginTypeEmail) {
      accountItemsList.removeWhere(
          (element) => element.accountEnum == AccountEnum.changePassword);
    }
    changeAccountItem(accountItemsList);
  }

  openAccountSelectedScreen(AccountEnum accountEnum) {
    switch (accountEnum) {
      case AccountEnum.myProfile:
        openScreenWithResult(context, const EditProfile()).then((value) {
          if (value != null && value) {
            setUserData();
          }
        });
        break;
      case AccountEnum.changePassword:
        openScreen(context, const ChangePassword());
        break;
      case AccountEnum.liveChat:
        openScreen(context, const ChatHistory());
        break;
      case AccountEnum.manageAddress:
        openScreen(context, const ManageAddress());
        break;
      case AccountEnum.inviteFriend:
        openScreen(context, const InviteFriend());
        break;
      case AccountEnum.manageCard:
        openScreen(context, const ManageCard());
        break;
      case AccountEnum.helpAndSupport:
        openScreen(context, const HelpAndSupport());
        break;
      case AccountEnum.chatWithAdmin:
        openScreen(
            context,
            Chatting(
                chatWithId: "a_1",
                chatWithName: languages.admin,
                chatWithImage: "",
                chatWithServicesName: ""));
        break;
      case AccountEnum.preference:
        openScreen(
            context,
            const SelectLanguageAndCurrency(
              isFromHome: true,
            ));
        break;
      /* case AccountEnum.myCoupons:
        openScreen(context, MyCoupons());
        break;*/
      case AccountEnum.emergencyContact:
        openScreen(context, const EmergencyContact());
        break;
      case AccountEnum.logout:
        openLogoutDialog();
        break;
      case AccountEnum.myCoupons:
        break;
    }
  }

  /// `LogoutSheet` (dugnad/dialogs.jsx) — a bottom sheet in the design.
  openLogoutDialog() {
    showDugnadSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return StreamBuilder<ApiResponse<BaseModel>>(
          stream: subjectLogout,
          builder: (context, snapLoading) {
            var isLoading =
                snapLoading.hasData &&
                snapLoading.data?.status == Status.loading;
            return LogoutSheet(
              isLoading: isLoading,
              onConfirm: logoutApiCall,
            );
          },
        );
      },
    );
  }

  setUserData() {
    changeUserName(prefGetString(prefUserName));
    changeProfileImg(prefGetString(prefProfileImage));
  }

  getWalletBalance() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      try {
        var response = WalletBalancePojo.fromJson(await _myWalletRepo.getWalletBalance());
        if (!state.mounted) return;
        if (isApiStatus(
          context,
          response.status,
          response.message,
          false,
          showMess: false,
        )) {
          double balance = getDoubleFromDynamic(response.walletBalance ?? "0");
          String balanceStr = balance.toStringAsFixed(2);
          prefSetString(prefAerendCredit, balanceStr);
          _hareCreditController.sink.add(balanceStr);
        }
      } catch (e) {
        // silently ignore; profile credit shown as fallback
      }
    }
  }

  @override
  void dispose() {
    _accountItemController.close();
    _userNameController.close();
    _profileImgController.close();
    _hareCreditController.close();
    _subjectLogout.close();
  }
}
