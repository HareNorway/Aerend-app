import 'package:flutter/material.dart';

import '../../blocs/bloc.dart';
import '../../screens/common/base_dl.dart';

class OrderCancelDialogBloc extends Bloc {
  BuildContext context;
  bool isFromPlacedOrder = false;
  Function(bool, String) onSubmit;
  final formKey = GlobalKey<FormState>();

  OrderCancelDialogBloc(this.context, this.onSubmit);

  final reasonController = TextEditingController();

  final _subject = BehaviorSubject<ApiResponse<BaseModel>>();

  BehaviorSubject<ApiResponse<BaseModel>> get subject => _subject;

  submit() async {
    onSubmit(true, (reasonController.text).trim());
  }

  @override
  void dispose() {
    reasonController.dispose();
    _subject.close();
  }
}
