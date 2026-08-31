import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../theme/sc_saas_theme.dart';
import '../utils/keyboard_done_widget.dart';
import '../utils/utils.dart';

class TextFormFieldCustom extends StatefulWidget {
  final String? hint;
  final bool setError, setBottomError, setPassword, readOnly, setClear;
  final bool useLabelWithBorder;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextDirection? textDirection;
  final TextAlignVertical? textAlignVertical;
  final TextStyle? style;
  final double? radius;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final Widget? suffix, prefix;
  final InputDecoration? decoration;
  final TextEditingController? controller;
  final TextAlign? textAlign;
  final String? Function(String)? validator;
  final Function(String)? onChanged;
  final Function(String)? onSubmit;
  final List<TextInputFormatter>? inputFormatters;
  final Function()? onTap;
  final BoxBorder? boxBorder;
  final int? maxLine, minLine, maxLength;
  final AutovalidateMode? autoValidateMode;

  const TextFormFieldCustom({
    super.key,
    this.hint,
    this.setPassword = false,
    this.radius,
    this.readOnly = false,
    this.textInputAction = TextInputAction.next,
    this.decoration,
    this.textAlignVertical,
    this.textDirection,
    this.backgroundColor = ScSaasThemeTokens.card,
    this.style,
    this.padding,
    this.keyboardType = TextInputType.text,
    this.textAlign = TextAlign.start,
    this.inputFormatters,
    this.suffix,
    this.setClear = false,
    this.prefix,
    this.setError = false,
    this.setBottomError = false,
    this.onChanged,
    this.onSubmit,
    this.controller,
    this.boxBorder,
    this.onTap,
    this.validator,
    this.maxLength,
    this.minLine = 1,
    this.maxLine = 1,
    this.autoValidateMode = AutovalidateMode.disabled,
    this.useLabelWithBorder = false,
  });

  @override
  State<StatefulWidget> createState() => TextFormFieldCustomState();
}

class TextFormFieldCustomState extends State<TextFormFieldCustom> {
  bool _passwordVisible = false;
  bool isError = false;
  bool isClear = false;
  bool isShowClear = false;
  String errorText = "";
  final GlobalKey _passKey = GlobalKey();
  final _formKey = GlobalKey<EditableTextState>();
  final FocusNode phoneNumberFocusNode = FocusNode();
  AutovalidateMode? _autovalidateMode;

  BoxDecoration getBoxDecoration({
    Color? color,
    double radius = 0.0,
    BoxBorder? border,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.all(Radius.circular(radius)),
      color: color ?? ScSaasThemeTokens.card,
      border: border,
    );
  }

  // --ae-r-sm = 8px; 1.5px border per design
  OutlineInputBorder outlineFocusedInputBorderStyle = const OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(8)),
    borderSide: BorderSide(width: 1.5, color: ScSaasThemeTokens.primary),
  );
  OutlineInputBorder outlineInputBorderStyle = const OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(8)),
    borderSide: BorderSide(width: 1.5, color: Color(0x00000000)), // transparent
  );
  OutlineInputBorder outlineErrorBorderStyle = const OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(8)),
    borderSide: BorderSide(width: 1.5, color: ScSaasThemeTokens.danger),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color inputTextColor =
        widget.style?.color ?? theme.colorScheme.onSurface;
    final Color labelColor = isDark ? Colors.white70 : ScSaasThemeTokens.muted;
    final Color hintColor = isDark
        ? theme.colorScheme.onSurface.withOpacity(0.55)
        : ScSaasThemeTokens.muted;
    // Prefer an explicit [backgroundColor] (e.g. Reen glass) over theme defaults.
    final Color inputFillColor = widget.backgroundColor ??
        (isDark ? const Color(0xFF1A1A1A) : ScSaasThemeTokens.card);

    InputDecoration? decoration;
    if (widget.useLabelWithBorder) {
      _autovalidateMode = AutovalidateMode.onUserInteraction;
      decoration = InputDecoration(
        border: outlineInputBorderStyle,
        errorBorder: outlineErrorBorderStyle,
        focusedBorder: outlineFocusedInputBorderStyle,
        enabledBorder: outlineInputBorderStyle,
        focusedErrorBorder: outlineErrorBorderStyle,
        fillColor: inputFillColor,
        filled: true,
        labelText: widget.decoration?.labelText ?? "",
        hintText: widget.decoration?.hintText ?? "",
        contentPadding: EdgeInsets.symmetric(
          horizontal: deviceWidth * 0.04,
          vertical: deviceHeight * 0.010,
        ),
        labelStyle: bodyText(
          textColor: labelColor,
          fontSize: textSizeMediumBig,
        ).copyWith(height: deviceHeight * 0.0008),
        hintStyle: bodyText(
          textColor: hintColor,
          fontSize: textSizeMediumBig,
        ).copyWith(height: deviceHeight * 0.0008),
        floatingLabelStyle: bodyText(
          textColor: isDark ? Colors.white : ScSaasThemeTokens.primary,
          fontSize: textSizeMediumBig,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      );
    } else {
      decoration = widget.decoration;
    }

    var eyeButton = GestureDetector(
      child: Container(
        padding: EdgeInsetsDirectional.only(end: deviceWidth * 0.02),
        constraints: const BoxConstraints(),
        child: Icon(
          _passwordVisible ? Icons.visibility_off : Icons.visibility,
          color: (widget.style?.color != null &&
                  (widget.style!.color!.computeLuminance() > 0.6))
              ? Colors.white70
              : (isDark ? Colors.white70 : colorMainLightGray),
          size: deviceAverageSize * 0.035,
        ),
      ),
      onTap: () {
        setState(() {
          _passwordVisible = !_passwordVisible;
        });
      },
    );

    var errorButton = Tooltip(
      key: _passKey,
      message: errorText,
      child: GestureDetector(
        child: Container(
          padding: EdgeInsetsDirectional.only(end: deviceWidth * 0.01),
          constraints: const BoxConstraints(),
          child: Icon(
            Icons.error,
            color: ScSaasThemeTokens.danger,
            size: deviceAverageSize * 0.035,
          ),
        ),
        onTap: () async {
          final dynamic tooltip = _passKey.currentState;
          tooltip.ensureTooltipVisible();
          await Future.delayed(const Duration(seconds: 3));
          tooltip.deactivate();
        },
      ),
    );

    var clearButton = IconButton(
      padding: EdgeInsetsDirectional.only(end: deviceWidth * 0.01),
      constraints: const BoxConstraints(),
      icon: Icon(Icons.close, size: deviceAverageSize * 0.035),
      onPressed: () {
        isClear = false;
        widget.controller?.text = "";
        SchedulerBinding.instance.addPostFrameCallback((_) {
          setState(() {});
        });
      },
    );

    var e = (isError && widget.setError);

    InputDecoration inputDecoration = InputDecoration(
      border: decoration?.border ?? InputBorder.none,
      counterText: '',
      contentPadding:
          decoration?.contentPadding ??
          EdgeInsets.symmetric(
            horizontal: deviceWidth * 0.015,
            vertical: deviceHeight * 0.010,
          ),
      labelText: decoration?.labelText,
      floatingLabelBehavior: decoration?.floatingLabelBehavior,
      labelStyle: decoration?.labelStyle,
      errorStyle: (widget.setBottomError)
          ? null
          : const TextStyle(height: 0, fontSize: 0.0),
      errorMaxLines: 2,
      focusedBorder: decoration?.focusedBorder,
      enabledBorder: decoration?.enabledBorder,
      errorBorder: decoration?.errorBorder,
      focusedErrorBorder: decoration?.focusedErrorBorder,
      floatingLabelStyle: decoration?.floatingLabelStyle,
      // Always set fill so [ThemeData.inputDecorationTheme] (white card) cannot
      // paint over a custom [backgroundColor] (e.g. Reen glass on navy).
      filled: true,
      fillColor: Colors.transparent,
      hintStyle:
          decoration?.hintStyle ??
          bodyText(fontSize: textSizeSmall, textColor: hintColor),
      hintText: widget.hint ?? decoration?.hintText ?? "",
      isDense: decoration?.isDense ?? false,
      suffixIconConstraints: const BoxConstraints(),
      prefixIconConstraints: const BoxConstraints(),
      isCollapsed: decoration?.isCollapsed ?? true,
      alignLabelWithHint: true,
      prefixIcon: widget.prefix,
      prefix: decoration?.prefix,
      suffixIcon: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (e && !widget.setBottomError) errorButton,
          if (widget.setPassword) eyeButton,
          if (widget.suffix != null)
            widget.suffix ?? const SizedBox(width: 0, height: 0),
          if (isClear && widget.setClear) clearButton,
        ],
      ),
    );

    validate(value) {
      if (widget.validator != null) {
        errorText = widget.validator?.call(value) ?? "";
        isError = errorText.isNotEmpty;
        // print("validate => $isError $errorText");
      }
    }

    return Container(
      decoration: getBoxDecoration(
        color: inputFillColor,
        radius: widget.radius ?? 8.0,
        border: widget.boxBorder,
      ),
      // padding: widget.padding ?? textFormFieldPadding,
      child: TextFormField(
        key: _formKey,
        // textDirection: TextDirection.ltr,
        readOnly: widget.readOnly,
        style: (widget.style ?? bodyText(fontSize: textSizeMediumBig)).copyWith(
          color: inputTextColor,
        ),
        cursorColor: widget.style?.color ?? theme.colorScheme.primary,
        textAlignVertical: widget.textAlignVertical,
        textInputAction: widget.textInputAction,
        keyboardType: widget.keyboardType,
        controller: widget.controller,
        textDirection: widget.textDirection,
        textAlign: widget.textAlign!,
        maxLines: widget.maxLine,
        maxLength: widget.maxLength ?? TextField.noMaxLength,
        minLines: widget.minLine,
        obscuringCharacter: "*",
        obscureText: !_passwordVisible && widget.setPassword,
        //This will obscure text dynamically
        inputFormatters: widget.inputFormatters,
        autovalidateMode: widget.setBottomError
            ? AutovalidateMode.onUserInteraction
            : _autovalidateMode ?? widget.autoValidateMode,
        validator: (value) {
          validate(value);
          if (!widget.setBottomError) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() {});
            });
          }
          // print("===> $isError || ${widget.setBottomError}  $errorText ");
          return isError
              ? (widget.setBottomError)
                    ? errorText
                    : ""
              : null;
        },
        onChanged: (value) {
          if (widget.onChanged != null) {
            widget.onChanged!(value);
          }
          isClear = value.isNotEmpty;
          validate(value);
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() {});
          });
        },
        onFieldSubmitted: widget.onSubmit,
        onTap: widget.onTap,
        decoration: inputDecoration,
      ),
    );
  }

  @override
  void initState() {
    _passwordVisible = false;
    if (Platform.isIOS && widget.keyboardType == TextInputType.number) {
      phoneNumberFocusNode.addListener(() {
        bool hasFocus = phoneNumberFocusNode.hasFocus;
        if (hasFocus) {
          showOverlay(context);
        } else {
          removeOverlay();
        }
      });
    }
    super.initState();
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    phoneNumberFocusNode.dispose();
    super.dispose();
  }
}
