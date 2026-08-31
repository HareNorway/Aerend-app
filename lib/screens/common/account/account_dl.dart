import 'package:flutter/material.dart';

class AccountItem {
  IconData icon;
  String name;
  AccountEnum accountEnum;
  double? size;

  AccountItem(this.accountEnum, this.icon, this.name, {this.size});
}

enum AccountEnum {
  myProfile,
  changePassword,
  liveChat,
  manageCard,
  manageAddress,
  emergencyContact,
  inviteFriend,
  helpAndSupport,
  chatWithAdmin,
  preference,
  myCoupons,
  logout
}
