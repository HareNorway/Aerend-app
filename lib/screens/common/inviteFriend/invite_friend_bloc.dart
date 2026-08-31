import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../../blocs/bloc.dart';
import '../../../utils/utils.dart';

class InviteFriendBloc extends Bloc {
  late BuildContext context;

  InviteFriendBloc(this.context);

  final _referralCodeController = BehaviorSubject<String>.seeded(prefGetString(prefReferralCode));

  Stream<String> get referralCode => _referralCodeController.stream;

  Function(String) get changeReferralCode => _referralCodeController.sink.add;

  shareReferralCode() {
    final box = context.findRenderObject() as RenderBox?;
    PackageInfo.fromPlatform().then((value) {
      String link = "";
      if (Platform.isAndroid) {
        link = "http://play.google.com/store/apps/details?id=${value.packageName}";
      } else if (Platform.isIOS || Platform.isMacOS) {
        link = "";
      } else {
        link = "";
      }
      String text =
          "${languages.use} (${_referralCodeController.value}) ${languages.referCodeGetDiscount}\n${languages.download} ${value.appName} :- $link";
      Share.share(text, subject: value.appName, sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size);
    });
  }

  @override
  void dispose() {
    _referralCodeController.close();
  }
}
