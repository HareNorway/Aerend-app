import 'package:flutter/material.dart';

import '../../blocs/bloc.dart';

class AddTipsDialogBloc extends Bloc {
  late BuildContext context;
  late Function(String tip) onSubmit;

  AddTipsDialogBloc(this.context, this.onSubmit);

  final tipController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  submit() {
    if (formKey.currentState!.validate()) {
      onSubmit(tipController.text.trim());
    }
  }

  @override
  void dispose() {
    tipController.dispose();
  }
}
