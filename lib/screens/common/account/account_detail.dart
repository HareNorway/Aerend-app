import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aerend_customer/dialogs/forgotPasswordDialog/forgot_password_dialog.dart';
import 'package:aerend_customer/theme/sc_saas_theme.dart';
import 'package:aerend_customer/screens/common/account/account_widgets.dart';
import 'package:aerend_customer/screens/common/account/edit_email.dart';
import 'package:aerend_customer/screens/common/account/edit_phonenumber.dart';
import 'package:aerend_customer/screens/common/account/edit_username.dart';
import 'package:aerend_customer/screens/common/account/edit_profile_picture.dart';
import 'package:aerend_customer/screens/common/account/terms_statement.dart';
import 'package:aerend_customer/screens/common/editProfile/edit_profile_repo.dart';
import 'package:aerend_customer/screens/common/selectLanguageAndCurrency/select_language_and_currency.dart';
import 'package:aerend_customer/screens/common/manageAddress/manage_address_repo.dart';
import 'package:aerend_customer/screens/common/manageAddress/manage_address_dl.dart';
import 'package:aerend_customer/screens/dugnad/dugnad_club_theme.dart';
import 'package:aerend_customer/screens/dugnad/dugnad_sheet.dart';
import 'package:aerend_customer/screens/dugnad/dugnad_state.dart';
import 'package:aerend_customer/screens/dugnad/widgets/dugnad_address_drawer.dart';
import 'package:aerend_customer/screens/dugnad/widgets/dugnad_rise_in.dart';
import 'package:aerend_customer/commonView/modal_ui.dart';

import '../../../utils/utils.dart';

/// "Min konto" — mirrors `MinKontoScreen` in dugnad/account.jsx:
/// `.tk-head` header, `.dga-photo` card, three `.dga-field` rows,
/// "Sikkerhet" + "Vilkår og personvern" `.dg-prof-list` sections and the
/// `.dga-danger` delete card.
class AccountDetail extends StatefulWidget {
  const AccountDetail({super.key});

  @override
  State<AccountDetail> createState() => _AccountDetailState();
}

class _AccountDetailState extends State<AccountDetail>
    with AutomaticKeepAliveClientMixin<AccountDetail> {
  AddressListItem selectedAddress = AddressListItem(address: '');
  List<AddressListItem> addressList = [];

  @override
  void initState() {
    super.initState();
    DugnadState.instance.revision.addListener(_onDugnadChanged);
    DugnadState.instance.syncClubThemeFromApi();
    final savedAddressJson = prefGetString(prefNewDeliveryAddress);
    if (savedAddressJson.isNotEmpty) {
      try {
        selectedAddress = AddressListItem.fromJson(
          jsonDecode(savedAddressJson),
        );
      } catch (_) {}
    }
    ManageAddressRepo().callAddressListApi().then((response) {
      response = AddressListPojo.fromJson(response);
      setState(() {
        addressList = response.addressList;
        if (addressList.isNotEmpty) {
          selectedAddress = addressList.firstWhere(
            (address) =>
                address.addressId == prefGetInt(prefNewDeliveryAddressId),
            orElse: () => addressList[0],
          );
          prefSetString(prefNewDeliveryAddress, jsonEncode(selectedAddress.toJson()));
        } else {
          selectedAddress = AddressListItem(address: '');
          prefSetString(prefNewDeliveryAddress, '');
        }
      });
    });
  }

  void _onDugnadChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    DugnadState.instance.revision.removeListener(_onDugnadChanged);
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  TextStyle _tx(
    double size,
    FontWeight weight, {
    Color? color,
    double? height,
    double? letterSpacingEm,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacingEm != null ? size * letterSpacingEm : null,
      color: color ?? ScSaasThemeTokens.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = context.dugnadTheme;
    final phone = prefGetString(prefContactNumber);
    final phoneValue = phone.isEmpty
        ? ''
        : '${prefGetString(prefCountryCode)} $phone'.trim();
    final email = prefGetString(prefEmail);

    return DugnadClubThemeScope(
      palette: theme,
      child: Scaffold(
        backgroundColor: theme.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AccountTkHead(
                title: languages.accountDetailTitle,
                onBack: () => Navigator.pop(context),
              ),
              Expanded(
                child: ListView(
                  // .ae-body: padding 0 18px 120px, gap 16.
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
                  children: [
                    DugnadRiseIn(
                      delay: const Duration(milliseconds: 120),
                      child: _photoCard(theme),
                    ),
                    const SizedBox(height: 16),
                    DugnadRiseIn(
                      delay: const Duration(milliseconds: 190),
                      child: _accountFieldRow(
                        theme: theme,
                        label: 'Telefonnummer', // TODO(l10n)
                        value: phoneValue,
                        placeholder: 'Legg til telefonnummer', // TODO(l10n)
                        mono: true,
                        onEdit: () => showEditPhoneNumberSheet(context)
                            .then(_refreshIfUpdated),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DugnadRiseIn(
                      delay: const Duration(milliseconds: 260),
                      child: _accountFieldRow(
                        theme: theme,
                        label: languages.email,
                        value: email,
                        placeholder: 'Legg til e-post', // TODO(l10n)
                        onEdit: () =>
                            showEditEmailSheet(context).then(_refreshIfUpdated),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DugnadRiseIn(
                      delay: const Duration(milliseconds: 330),
                      child: _accountFieldRow(
                        theme: theme,
                        label: 'Adresse', // TODO(l10n)
                        value: selectedAddress.address,
                        placeholder: 'Legg til leveringsadresse', // TODO(l10n)
                        onEdit: _openAddressSheet,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DugnadRiseIn(
                      delay: const Duration(milliseconds: 400),
                      child: _section(
                        theme: theme,
                        label: 'Sikkerhet', // TODO(l10n)
                        rows: [
                          _ProfRow(
                            icon: Icons.lock_outline_rounded,
                            title: 'Bytt passord', // TODO(l10n)
                            onTap: () => showForgotPasswordSheet(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    DugnadRiseIn(
                      delay: const Duration(milliseconds: 470),
                      child: _section(
                        theme: theme,
                        label: 'Vilkår og personvern', // TODO(l10n)
                        rows: [
                          _ProfRow(
                            icon: Icons.shield_outlined,
                            title: 'Vilkår for bruk', // TODO(l10n)
                            onTap: () => openScreenWithResult(
                              context,
                              const TermsOfService(),
                            ),
                          ),
                          _ProfRow(
                            icon: Icons.info_outline_rounded,
                            title: 'Tilgjengelighetserklæring', // TODO(l10n)
                            onTap: () => openScreenWithResult(
                              context,
                              const AvaibilityStatement(),
                            ),
                          ),
                          _ProfRow(
                            icon: Icons.lock_outline_rounded,
                            title: 'Personvern', // TODO(l10n)
                            onTap: () => openScreenWithResult(
                              context,
                              const PrivacyPolicy(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    DugnadRiseIn(
                      delay: const Duration(milliseconds: 540),
                      child: _dangerCard(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _refreshIfUpdated(bool? updated) {
    if (updated == true && mounted) setState(() {});
  }

  /// `.dga-photo` — avatar with camera badge, name, hint, `.dga-pen`.
  Widget _photoCard(DugnadClubThemePalette theme) {
    final profileImage = prefGetString(prefProfileImage).trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: ScSaasThemeTokens.shadowCard,
      ),
      child: Row(
        children: [
          _ScalePress(
            pressedScale: 0.94,
            onTap: () async {
              final updated = await openScreenWithResult(
                context,
                const EditProfilePicture(),
              );
              if (updated == true && mounted) setState(() {});
            },
            child: SizedBox(
              width: 58,
              height: 58,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: theme.shinyGradient,
                      shape: BoxShape.circle,
                      boxShadow: theme.shadowButton,
                    ),
                    clipBehavior: Clip.antiAlias,
                    alignment: Alignment.center,
                    child: profileImage.isEmpty
                        ? const Icon(Icons.person_rounded,
                            size: 26, color: Colors.white)
                        : LoadImageWithPlaceHolder(
                            image: profileImage,
                            width: 58,
                            height: 58,
                            defaultAssetImage:
                                'assets/images/avatar_user.png',
                            borderRadius: BorderRadius.circular(29),
                          ),
                  ),
                  // .dga-photo .av .cam
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.text.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.photo_camera_rounded,
                        size: 12,
                        color: theme.primaryHover,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prefGetString(prefUserName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _tx(17, FontWeight.w800,
                      letterSpacingEm: -0.015, color: theme.text),
                ),
                const SizedBox(height: 2),
                Text(
                  'Trykk på bildet for å bytte det', // TODO(l10n)
                  style: _tx(12.5, FontWeight.w600,
                      color: ScSaasThemeTokens.gray500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 13),
          // .dga-pen
          _ScalePress(
            pressedScale: 0.94,
            onTap: () =>
                showEditUserNameSheet(context).then(_refreshIfUpdated),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.background,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                'assets/svgs/icons/edit.svg',
                width: 16,
                colorFilter: ColorFilter.mode(
                  theme.primaryHover,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// `.dga-field` — label + `.dga-fbox` value card with edit chip.
  Widget _accountFieldRow({
    required DugnadClubThemePalette theme,
    required String label,
    required String value,
    required String placeholder,
    required VoidCallback onEdit,
    bool mono = false,
  }) {
    final hasValue = value.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // .dga-flabel
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Text(
            label.toUpperCase(),
            style: _tx(12, FontWeight.w800,
                letterSpacingEm: 0.06, color: ScSaasThemeTokens.gray500),
          ),
        ),
        const SizedBox(height: 7),
        // .dga-fbox
        _ScalePress(
          pressedScale: 0.99,
          onTap: onEdit,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 15, 14, 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: ScSaasThemeTokens.shadowCard,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasValue ? value : placeholder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: hasValue
                        ? _tx(15, FontWeight.w700,
                            letterSpacingEm: mono ? 0.01 : null,
                            color: theme.text)
                            .copyWith(
                            fontFeatures: mono
                                ? const [FontFeature.tabularFigures()]
                                : null,
                          )
                        : _tx(15, FontWeight.w600, color: kAccountGray400),
                  ),
                ),
                const SizedBox(width: 10),
                // .dga-fbox .ed
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: theme.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    'assets/svgs/icons/edit.svg',
                    width: 16,
                    colorFilter: ColorFilter.mode(
                      theme.primaryHover,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// `.dg-label` + `.dg-prof-list` section.
  Widget _section({
    required DugnadClubThemePalette theme,
    required String label,
    required List<_ProfRow> rows,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 4, 2, 8),
          child: Text(
            label.toUpperCase(),
            style: _tx(11, FontWeight.w800,
                letterSpacingEm: 0.08, color: ScSaasThemeTokens.gray500),
          ),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.text.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: ScSaasThemeTokens.gray100,
                  ),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// `.dga-danger` — delete account card.
  Widget _dangerCard() {
    return _ScalePress(
      pressedScale: 0.99,
      onTap: _openDeleteAccountSheet,
      child: Container(
        padding: const EdgeInsets.fromLTRB(15, 14, 14, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(width: 1.5, color: const Color(0x38D9534F)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0x1AD9534F),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.delete_outline_rounded,
                size: 17,
                color: ScSaasThemeTokens.danger,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    languages.accountDelete,
                    style: _tx(15, FontWeight.w800,
                        color: ScSaasThemeTokens.danger),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Fjerner kontoen og alle dataene dine', // TODO(l10n)
                    style: _tx(12.5, FontWeight.w600,
                        color: ScSaasThemeTokens.gray500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right_rounded,
                size: 17, color: kAccountGray400),
          ],
        ),
      ),
    );
  }

  /// Design confirmation sheet → existing feedback/delete flow.
  void _openDeleteAccountSheet() {
    showDugnadSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DeleteAccountSheet(
        title: languages.accountDelete,
        onConfirm: () {
          Navigator.pop(sheetContext);
          _confirmDeleteAccount();
        },
      ),
    );
  }

  /// Same address drawer as Home (`showDugnadAddressDrawer`).
  Future<void> _openAddressSheet() async {
    await showDugnadAddressDrawer(
      context,
      parentContext: context,
      onAddressChanged: _reloadSelectedAddress,
    );
    if (mounted) _reloadSelectedAddress();
  }

  void _reloadSelectedAddress() {
    final savedAddressJson = prefGetString(prefNewDeliveryAddress);
    if (savedAddressJson.isNotEmpty) {
      try {
        if (!mounted) return;
        setState(() {
          selectedAddress = AddressListItem.fromJson(
            jsonDecode(savedAddressJson),
          );
        });
        return;
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => selectedAddress = AddressListItem(address: ''));
  }

  void _confirmDeleteAccount() {
    int feedback = 0;
    List<String> feedbackList = [
      "Found an alternative service",
      "Not satisfied with the product",
      "Privacy concerns",
      "Other",
    ];
    showModalBottomSheet(
      isScrollControlled: true,
      constraints: BoxConstraints(
        minWidth: double.infinity,
        maxHeight: deviceHeight * 0.7,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ModalUi.sheetHeader(
                context,
                title: 'Deleting My Account',
                onClose: () => Navigator.pop(context),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 0.1,
                      blurRadius: 10,
                      offset: const Offset(3, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    LoadImageWithPlaceHolder(
                      image: "assets/images/avatar_user.png",
                      width: 50,
                      height: 50,
                      defaultAssetImage: "assets/images/avatar_user.png",
                      borderRadius: BorderRadius.circular(
                        deviceAverageSize * 0.1,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: EdgeInsetsDirectional.only(
                              start: deviceWidth * 0.04,
                            ),
                            child: Text(
                              prefGetString(prefUserName),
                              textAlign: TextAlign.start,
                              style: headerText(
                                fontWeight: FontWeight.bold,
                                fontSize: textSizeMediumBig,
                              ),
                            ),
                          ),
                          Container(
                            margin: EdgeInsetsDirectional.only(
                              start: deviceWidth * 0.04,
                            ),
                            child: Text(
                              prefGetString(prefEmail),
                              textAlign: TextAlign.start,
                              style: headerText(
                                textColor: colorMainGray,
                                fontSize: textSizeSmall,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 27),
              const Text(
                'Your feedback is important to us and will help us improve our services for the future. Please take a moment to let us know the reason for deleting your account.',
                style: TextStyle(
                  fontSize: 15,
                  color: colorMainLightGray,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 25),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 0.1,
                        blurRadius: 10,
                        offset: const Offset(3, 3),
                      ),
                    ],
                  ),
                  child: StatefulBuilder(
                    builder: (context, setFeedbackState) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          feedbackList.length,
                          (index) => Column(
                            children: [
                              GestureDetector(
                                onTap: () => setFeedbackState(() {
                                  feedback = index;
                                }),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      feedbackList[index],
                                      textAlign: TextAlign.start,
                                      style: headerText(
                                        fontSize: textSizeSmall,
                                      ),
                                    ),
                                    index == feedback
                                        ? const Icon(
                                            Icons.check_circle,
                                            color: colorPrimary,
                                          )
                                        : const Icon(
                                            Icons.circle_outlined,
                                            color: colorMainGray,
                                          ),
                                  ],
                                ),
                              ),
                              if (index < feedbackList.length - 1)
                                const Divider(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: colorWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    textStyle: const TextStyle(fontSize: 20),
                  ),
                  onPressed: () async {
                    final response = await EditProfileRepo().deleteAccountApi();
                    if (response['status'] == 1) {
                      if (!mounted) return;
                      openScreenWithResult(
                        context,
                        const SelectLanguageAndCurrency(),
                      );
                    }
                  },
                  child: Text(languages.accountDeleteMyAccount),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}

/// `.dg-prof-list .row` — 40px club-tint icon chip, title, chevron.
class _ProfRow extends StatelessWidget {
  const _ProfRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    return _ScalePress(
      pressedScale: 0.99,
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.primaryTint,
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: theme.primaryHover),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 14 * -0.01,
                  color: theme.text,
                ),
              ),
            ),
            const SizedBox(width: 13),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: ScSaasThemeTokens.gray300,
            ),
          ],
        ),
      ),
    );
  }
}

/// Scale press feedback (`:active { transform: scale(...) }`) without ink.
class _ScalePress extends StatefulWidget {
  const _ScalePress({
    required this.child,
    required this.onTap,
    this.pressedScale = 0.99,
  });

  final Widget child;
  final VoidCallback onTap;
  final double pressedScale;

  @override
  State<_ScalePress> createState() => _ScalePressState();
}

class _ScalePressState extends State<_ScalePress> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: const Duration(milliseconds: 60),
        curve: Curves.ease,
        child: widget.child,
      ),
    );
  }
}
