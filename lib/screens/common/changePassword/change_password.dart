import 'package:flutter/material.dart';

import '../../../commonView/common_view.dart';
import '../../../commonView/custom_text_field.dart';
import '../../../networking/api_base_helper.dart';
import '../../../utils/utils.dart';
import '../base_dl.dart';
import 'change_password_bloc.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  State<StatefulWidget> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  late ChangePasswordBloc _bloc;
  var labelStyle = bodyText(fontSize: textSizeMediumBig, fontWeight: FontWeight.w600, textColor: colorMainLightGray);
  var textStyle = bodyText(fontSize: textSizeMediumBig, fontWeight: FontWeight.w600);
  var formDivider = deviceHeight * 0.025;

  @override
  void didChangeDependencies() {
    _bloc = ChangePasswordBloc(context, this);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorWhite,
      appBar: AppBar(
        titleTextStyle: toolbarStyle(),
        title: Text(languages.changePassword),
        leading: const BackButton(),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                start: deviceWidth * 0.04,
                end: deviceWidth * 0.04,
                bottom: deviceHeight * 0.03,
                top: deviceHeight * 0.025,
              ),
              child: Form(
                key: _bloc.formKey,
                child: Column(
                  children: [
                    TextFormFieldCustom(
                      decoration: InputDecoration(labelText: languages.oldPassword),
                      useLabelWithBorder: true,
                      style: textStyle,
                      controller: _bloc.oldPasswordTEC,
                      setError: true,
                      setPassword: true,
                      validator: (value) {
                        _bloc.buttonHide();
                        return passwordValidate(value);
                      },
                    ),
                    SizedBox(
                      height: formDivider,
                    ),
                    TextFormFieldCustom(
                      decoration: InputDecoration(labelText: languages.newPassword),
                      useLabelWithBorder: true,
                      style: textStyle,
                      controller: _bloc.newPasswordTEC,
                      setError: true,
                      setPassword: true,
                      validator: (value) {
                        _bloc.buttonHide();
                        return passwordValidate(value);
                      },
                    ),
                    SizedBox(height: formDivider),
                    TextFormFieldCustom(
                      decoration: InputDecoration(labelText: languages.reEnterPass),
                      useLabelWithBorder: true,
                      style: textStyle,
                      controller: _bloc.reEnterPasswordTEC,
                      textInputAction: TextInputAction.done,
                      setError: true,
                      setPassword: true,
                      validator: (value) {
                        _bloc.buttonHide();
                        return confirmPasswordValidate(value, _bloc.newPasswordTEC.text);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            fillOverscroll: true,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: StreamBuilder<bool>(
                stream: _bloc.submitValid,
                builder: (context, snapEnable) {
                  bool isEnable = snapEnable.data ?? false;
                  return StreamBuilder<ApiResponse<BaseModel>>(
                    stream: _bloc.subject,
                    builder: (context, snapLoading) {
                      var isLoading = snapLoading.hasData && snapLoading.data!.status == Status.loading;
                      return CustomRoundedButton(
                        context,
                        languages.submit,
                        (isLoading || !isEnable)
                            ? null
                            : () {
                                if (_bloc.formKey.currentState!.validate()) {
                                  _bloc.submit();
                                }
                              },
                        elevation: deviceAverageSize * 0.005,
                        progressStrokeWidth: cpiStrokeWidthSmall,
                        progressSize: cpiSizeSmall,
                        progressColor: colorWhite,
                        setProgress: isLoading,
                        minWidth: double.infinity,
                        maxLine: 1,
                        bgColor: colorPrimary,
                        setBorder: false,
                        textAlign: TextAlign.center,
                        textSize: textSizeLarge,
                        textColor: colorWhite,
                        fontWeight: FontWeight.w700,
                        minHeight: commonBtnHeight,
                        margin: EdgeInsetsDirectional.only(
                          start: deviceWidth * 0.035,
                          end: deviceWidth * 0.035,
                          bottom: deviceHeight * 0.03,
                          top: deviceHeight * 0.02,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
