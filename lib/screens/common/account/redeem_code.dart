import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aerend_customer/commonView/modal_ui.dart';
import 'package:aerend_customer/screens/common/home/home_repo.dart';
import 'package:aerend_customer/screens/common/homeMainV1/home_main_v1.dart';
import 'package:aerend_customer/theme/sc_saas_theme.dart';

import '../../../utils/utils.dart';
import '../../dugnad/widgets/dugnad_rise_in.dart';
import '../../dugnad/widgets/dugnad_subpage_shell.dart';
import 'account_widgets.dart';
import 'settings_design_kit.dart';

/// «Innløs kode» — the `.dgr-redeem` half of design `settings-screens.jsx`
/// `ReferralCodeScreen`, on its own page (`.tk-head` + `.dgr-hero` +
/// `.dg-label`/`.dgr-redeem` + `.dg-info`).
class RedeemCode extends StatefulWidget {
  final String? discountCode;
  const RedeemCode({super.key, this.discountCode});

  @override
  State<RedeemCode> createState() => _RedeemCodeState();
}

class _RedeemCodeState extends State<RedeemCode>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final TextEditingController _redeemCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    // Animation disabled to remove blinking effect
    // ..repeat();
    _redeemCodeController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.discountCode != null) {
        checkingRedeemCode(context, discountCode: widget.discountCode);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _redeemCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = _redeemCodeController.text.trim();

    return Scaffold(
      backgroundColor: kDgPageBackground,
      body: DugnadFixedTypography(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AccountTkHead(
                title: languages.redeemCodeTitle,
                onBack: () => openScreenWithResult(
                  context,
                  const HomeMainV1(homeIndex: 3),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  // .ae-body { padding: 0 18px 120px }
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DugnadRiseIn(
                        delay: const Duration(milliseconds: 120),
                        child: DgrHero(
                          icon: Icons.card_giftcard_rounded,
                          title: languages.redeemCodeTitle,
                          subtitle: const [
                            TextSpan(
                              // TODO(l10n)
                              text: 'Har du en rabattkode, et gavekort eller '
                                  'en tilbudskode? Skriv den inn her.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      DugnadRiseIn(
                        delay: const Duration(milliseconds: 190),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const DgLabel('Din kode'), // TODO(l10n)
                            DgRedeemRow(
                              controller: _redeemCodeController,
                              hint: languages.redeemCodeHint,
                              buttonLabel: 'Innløs', // TODO(l10n)
                              onSubmit: value.length < 3
                                  ? null
                                  : () => checkingRedeemCode(context),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const DugnadRiseIn(
                        delay: Duration(milliseconds: 260),
                        child: DgInfoBox(
                          icon: Icons.info_outline_rounded,
                          // TODO(l10n)
                          text: 'Koden trekkes automatisk i kassen på din '
                              'neste bestilling.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void checkingRedeemCode(BuildContext context, {String? discountCode}) async {
    String code = discountCode ?? _redeemCodeController.text.trim();

    _validatingModal();
    final response = await HomeRepo().checkingRedeemCode(code);
    if (!mounted) return;
    Navigator.pop(context);
    if (response['status'] == 1) {
      _discountSuccessModal();
    } else {
      openSimpleSnackbar(response['message']);
      if (response['status'] == 4) logout(context);
      _discountFailModal();
    }
  }

  void _validatingModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          content: SizedBox(
            width: deviceWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ModalUi.handle(),
                AnimatedBuilder(
                  animation: _controller,
                  child: Image.asset(
                    'assets/images/progress.png',
                    width: deviceWidth * 0.15,
                  ),
                  builder: (BuildContext context, Widget? child) {
                    return Transform.rotate(
                      angle: _controller.value * -2.0 * 3.141592653589793,
                      child: child,
                    );
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  "Validating...",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: ScSaasThemeTokens.text,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _discountSuccessModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          content: SizedBox(
            width: deviceWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ModalUi.handle(),
                const Icon(
                  Icons.check_circle,
                  color: ScSaasThemeTokens.accent,
                  size: 70,
                ),
                const SizedBox(height: 15),
                const Text(
                  "Discount Code Applied!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: ScSaasThemeTokens.text,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: deviceWidth * 0.7,
                  child: const Text(
                    "Your discount code has successfully applied.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ScSaasThemeTokens.muted,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ScSaasThemeTokens.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(languages.redeemCodeOkay, style: const TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _discountFailModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          content: SizedBox(
            width: deviceWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ModalUi.handle(),
                SvgPicture.asset('assets/svgs/redeem_fail.svg'),
                const SizedBox(height: 25),
                const Text(
                  "Failed Code!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                    color: ScSaasThemeTokens.text,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: deviceWidth * 0.6,
                  height: 50,
                  child: const Text(
                    "Unfortunately, this code does not work...",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ScSaasThemeTokens.muted,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ScSaasThemeTokens.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      checkingRedeemCode(context);
                    },
                    child: Text(
                      languages.tryAgain,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
