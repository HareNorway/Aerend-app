import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../commonView/custom_text_field.dart';
import '../../../networking/api_base_helper.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/payment_card.dart';
import '../../../utils/utils.dart';
import '../../../ui/kit/ae_rise_in.dart';
import '../../../ui/kit/ae_subpage_shell.dart';
import '../auth/auth_style.dart';
import '../base_dl.dart';
import 'add_card_bloc.dart';

class AddCard extends StatefulWidget {
  const AddCard({super.key});

  @override
  State<StatefulWidget> createState() => _AddCardState();
}

class _AddCardState extends State<AddCard> {
  AddCardBloc? _bloc;

  @override
  void didChangeDependencies() {
    if (_bloc == null) {
      _bloc = AddCardBloc(context, this);
      _bloc!.cardHolderNameTEC.addListener(_onFieldChanged);
      _bloc!.expiredDateTEC.addListener(_onFieldChanged);
      _bloc!.cvvTEC.addListener(_onFieldChanged);
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _bloc?.dispose();
    super.dispose();
  }

  void _onFieldChanged() => setState(() {});

  String get _digits =>
      (_bloc?.cardNumberTEC.text ?? '').replaceAll(RegExp(r'\D'), '');

  bool get _formValid {
    final bloc = _bloc;
    if (bloc == null) return false;
    final digits = _digits;
    final name = bloc.cardHolderNameTEC.text.trim();
    final exp = bloc.expiredDateTEC.text.trim();
    final cvc = bloc.cvvTEC.text.trim();
    return digits.length >= 15 &&
        name.length > 2 &&
        RegExp(r'^\d{2}/\d{2}(\d{2})?$').hasMatch(exp) &&
        cvc.length >= 3;
  }

  @override
  Widget build(BuildContext context) {
    return AeFixedTypography(
      child: Scaffold(
        backgroundColor: ScSaasThemeTokens.background,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
                child: Form(
                  key: _bloc!.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AeRiseIn(
                        delay: const Duration(milliseconds: 120),
                        child: _cardPreview(),
                      ),
                      const SizedBox(height: 16),
                      AeRiseIn(
                        delay: const Duration(milliseconds: 190),
                        child: _AeField(
                          label: 'Kortnummer', // TODO(l10n)
                          hint: '4242 4242 4242 4242',
                          keyboardType: const TextInputType.numberWithOptions(
                            signed: false,
                            decimal: false,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(19),
                            CardNumberInputFormatter(),
                          ],
                          onChanged: (value) {
                            _bloc!.changeCardNumber(value);
                            setState(() {});
                          },
                          validator: (value) => validateCardNumber(value),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AeRiseIn(
                        delay: const Duration(milliseconds: 260),
                        child: _AeField(
                          label: 'Navn på kortet', // TODO(l10n)
                          hint: languages.hintCardHolderName,
                          controller: _bloc!.cardHolderNameTEC,
                          keyboardType: TextInputType.name,
                          validator: (value) => validateEmptyField(
                            value,
                            languages.enterHolderName,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AeRiseIn(
                        delay: const Duration(milliseconds: 330),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _AeField(
                                label: 'Utløper', // TODO(l10n)
                                hint: '09/28',
                                controller: _bloc!.expiredDateTEC,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(6),
                                  CardMonthInputFormatter(),
                                ],
                                validator: (value) =>
                                    validateExpirationDate(value),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _AeField(
                                label: 'CVC', // TODO(l10n)
                                hint: '123',
                                controller: _bloc!.cvvTEC,
                                password: true,
                                maxLength: 3,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  signed: false,
                                  decimal: false,
                                ),
                                textInputAction: TextInputAction.done,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp('^[0-9]*\$'),
                                  ),
                                ],
                                validator: (value) => validateWithFixLength(
                                  value,
                                  3,
                                  languages.enterCvv,
                                  languages.invalidCvv,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isDemoApp)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            languages.dummyCardNote,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                              color: ScSaasThemeTokens.gray500,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      AeRiseIn(
                        delay: const Duration(milliseconds: 400),
                        child: _saveButton(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// `.tk-head` — back, centred h1, 38px spacer.
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        MediaQuery.paddingOf(context).top + 8,
        22,
        14,
      ),
      child: Row(
        children: [
          AeBackButton(onPressed: () => Navigator.maybePop(context)),
          Expanded(
            child: Text(
              languages.addCard,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 20 * -0.015,
                color: ScSaasThemeTokens.text,
              ),
            ),
          ),
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  /// `.dgp-preview` — live midnight card preview.
  Widget _cardPreview() {
    final digits = _digits;
    final name = _bloc!.cardHolderNameTEC.text.trim();
    final exp = _bloc!.expiredDateTEC.text.trim();
    final brand = digits.isEmpty
        ? '•••'
        : digits.startsWith('4')
            ? 'VISA'
            : 'MC';
    final padded = digits.padRight(16, '•');
    final groups = <String>[
      for (var i = 0; i < 4; i++) padded.substring(i * 4, i * 4 + 4),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        // background: linear-gradient(140deg, #3d2a6b, #2d1b5b)
        gradient: const LinearGradient(
          begin: Alignment(-0.7, -0.75),
          end: Alignment(0.7, 0.75),
          colors: [Color(0xFF3D2A6B), Color(0xFF2D1B5B)],
        ),
        // box-shadow: 0 14px 30px -14px rgba(45,27,91,.8)
        boxShadow: const [
          BoxShadow(
            color: Color(0xCC2D1B5B),
            blurRadius: 30,
            offset: Offset(0, 14),
            spreadRadius: -14,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // .dgp-preview .chip: 34×25, radius 6, gold gradient
              Container(
                width: 34,
                height: 25,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: const LinearGradient(
                    begin: Alignment(-0.7, -0.75),
                    end: Alignment(0.7, 0.75),
                    colors: [Color(0xFFE6C980), Color(0xFFC9A24A)],
                  ),
                ),
              ),
              const Spacer(),
              // .dgp-preview .br: 15/800/.06em top-right
              Text(
                brand,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 15 * 0.06,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          // .dgp-preview .no: 19/700/.12em, padding 20px 0 14px
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 14),
            child: Text(
              groups.join(' '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                letterSpacing: 19 * 0.12,
                color: Colors.white,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          // .dgp-preview .ft: 11.5/700/.05em, opacity .85, space-between
          Row(
            children: [
              Expanded(
                child: Text(
                  name.isEmpty
                      ? 'NAVN PÅ KORTET' // TODO(l10n)
                      : name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 11.5 * 0.05,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                exp.isEmpty ? 'MM/ÅÅ' : exp,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 11.5 * 0.05,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// `.ae-btn--primary` "Lagre kort" — disabled until the form is complete.
  /// Success path pops back to whatever screen opened this one (bloc pops
  /// with `true`; no hard navigation).
  Widget _saveButton() => StreamBuilder<ApiResponse<BaseModel>>(
        stream: _bloc!.subject,
        builder: (context, snapLoading) {
          var isLoading =
              snapLoading.hasData && snapLoading.data?.status == Status.loading;
          return AuthPrimaryButton(
            label: 'Lagre kort', // TODO(l10n)
            isLoading: isLoading,
            onPressed: _formValid ? () => _bloc!.addCard() : null,
          );
        },
      );
}

/// `.ae-field` / `.ae-input` clone of [AuthField] with input-formatter,
/// onChanged and maxLength support (AuthField does not expose those).
class _AeField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController? controller;
  final String? Function(String) validator;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final Function(String)? onChanged;
  final bool password;
  final int? maxLength;

  const _AeField({
    required this.label,
    required this.hint,
    required this.validator,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.inputFormatters,
    this.onChanged,
    this.password = false,
    this.maxLength,
  });

  @override
  State<_AeField> createState() => _AeFieldState();
}

class _AeFieldState extends State<_AeField> {
  bool _focused = false;

  static const _radius = BorderRadius.all(Radius.circular(14));

  OutlineInputBorder _border(Color color) => const OutlineInputBorder(
        borderRadius: _radius,
        borderSide: BorderSide(width: 1.5, color: Colors.transparent),
      ).copyWith(borderSide: BorderSide(width: 1.5, color: color));

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: authLabelStyle(context)),
        const SizedBox(height: 8),
        Focus(
          skipTraversal: true,
          canRequestFocus: false,
          onFocusChange: (value) => setState(() => _focused = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.ease,
            decoration: BoxDecoration(
              borderRadius: _radius,
              boxShadow: _focused
                  ? const [
                      BoxShadow(color: Color(0x1F7F5FC4), spreadRadius: 4),
                    ]
                  : null,
            ),
            child: TextFormFieldCustom(
              decoration: InputDecoration(
                hintText: widget.hint,
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                enabledBorder: _border(Colors.transparent),
                focusedBorder: _border(ScSaasThemeTokens.primary),
                errorBorder: _border(ScSaasThemeTokens.danger),
                focusedErrorBorder: _border(ScSaasThemeTokens.danger),
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: ScSaasThemeTokens.gray500,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
              useLabelWithBorder: false,
              setError: true,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              inputFormatters: widget.inputFormatters,
              onChanged: widget.onChanged,
              maxLength: widget.maxLength,
              style: GoogleFonts.plusJakartaSans(
                color: ScSaasThemeTokens.ink,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              backgroundColor: Colors.white,
              radius: 14,
              textAlignVertical: TextAlignVertical.center,
              controller: widget.controller,
              setPassword: widget.password,
              validator: widget.validator,
            ),
          ),
        ),
      ],
    );
  }
}
