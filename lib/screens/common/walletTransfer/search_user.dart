import 'package:flutter/material.dart';

import '../../../commonView/custom_text_field.dart';
import '../../../commonView/no_record_found.dart';
import '../../../networking/api_response.dart';
import '../../../utils/utils.dart';
import 'search_user_shimmer.dart';
import 'wallet_transfer_bloc.dart';
import 'wallet_transfer_dl.dart';

class SearchUser extends StatefulWidget {
  final WalletTransferBloc bloc;

  const SearchUser({super.key, required this.bloc});

  @override
  State<SearchUser> createState() => _SearchUserState();
}

class _SearchUserState extends State<SearchUser> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0,
        automaticallyImplyLeading: true,
        title: Hero(
          tag: "search",
          child: Text(
            languages.searchByContactOrEmail,
            style: toolbarStyle(
              textColor: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(
                Radius.circular(deviceAverageSize * 0.02),
              ),
              border: Border.all(
                color: colorMainView,
                width: deviceAverageSize * 0.002,
              ),
              color: colorWhite,
            ),
            padding: EdgeInsets.all(deviceAverageSize * 0.015),
            margin: EdgeInsetsDirectional.only(
              start: deviceWidth * 0.03,
              end: deviceWidth * 0.03,
              bottom: deviceHeight * 0.012,
              top: deviceHeight * 0.012,
            ),
            child: Row(
              children: [
                const Icon(Icons.search_sharp, color: colorMainLightGray),
                Expanded(
                  child: TextFormFieldCustom(
                    hint: languages.search,
                    textInputAction: TextInputAction.search,
                    controller: widget.bloc.textEditingController,
                    radius: deviceAverageSize * 0.015,
                    validator: (value) {
                      return "";
                    },
                    onSubmit: (search) {
                      if (search.isNotEmpty) {
                        widget.bloc.searchUsers(search);
                      }
                    },
                    setClear: true,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: deviceHeight * 0.015),
              child: StreamBuilder<ApiResponse<UserSearchModel>?>(
                stream: widget.bloc.searchUser,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    switch (snapshot.data?.status) {
                      case Status.loading:
                        return const SearchUserShimmer();
                      case Status.completed:
                        UserSearchModel? data = snapshot.data?.data;
                        List<TransferUserList> transferUserList =
                            data?.transferUserList ?? [];
                        return transferUserList.isNotEmpty
                            ? ListView.separated(
                                itemBuilder: (context, index) {
                                  TransferUserList? transferUserList =
                                      data?.transferUserList[index];
                                  String defaultAvatar =
                                      "assets/images/avatar_user.png";
                                  if (transferUserList?.walletProviderType ==
                                      0) {
                                    defaultAvatar =
                                        "assets/images/avatar_user.png";
                                  } else if (transferUserList
                                          ?.walletProviderType ==
                                      1) {
                                    defaultAvatar =
                                        "assets/images/avatar_store.png";
                                  } else if (transferUserList
                                          ?.walletProviderType ==
                                      2) {
                                    defaultAvatar =
                                        "assets/images/avatar_driver.png";
                                  } else if (transferUserList
                                          ?.walletProviderType ==
                                      3) {
                                    defaultAvatar =
                                        "assets/images/avatar_provider.png";
                                  }

                                  String contactNumber =
                                      "${transferUserList?.countryCode ?? ""} ${transferUserList?.contactNumber ?? " "}";

                                  return InkWell(
                                    onTap: () {
                                      widget.bloc.transferUserList =
                                          transferUserList;
                                      widget
                                              .bloc
                                              .textBeneficialController
                                              .text =
                                          transferUserList?.name ?? "";
                                      widget.bloc.textNumberController.text =
                                          contactNumber;
                                      widget.bloc.textEmailController.text =
                                          transferUserList?.email ?? "";
                                      Navigator.pop(context, transferUserList);
                                    },
                                    child: Container(
                                      margin: EdgeInsets.symmetric(
                                        horizontal: deviceWidth * 0.015,
                                        vertical: deviceHeight * 0.001,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          LoadImageWithPlaceHolder(
                                            width: deviceAverageSize * 0.09,
                                            height: deviceAverageSize * 0.09,
                                            image:
                                                transferUserList
                                                    ?.profileImage ??
                                                "",
                                            borderRadius: BorderRadius.circular(
                                              deviceAverageSize * 0.07,
                                            ),
                                            defaultAssetImage: defaultAvatar,
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal:
                                                    deviceHeight * 0.015,
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    transferUserList?.name ??
                                                        "",
                                                    style: bodyText(
                                                      fontSize:
                                                          textSizeMediumBig,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    contactNumber,
                                                    style: bodyText(),
                                                  ),
                                                  Text(
                                                    transferUserList?.email ??
                                                        "",
                                                    style: bodyText(),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                itemCount: transferUserList.length,
                                separatorBuilder:
                                    (BuildContext context, int index) {
                                      return Divider(
                                        indent: deviceAverageSize * 0.11,
                                        endIndent: deviceAverageSize * 0.015,
                                        thickness: 2,
                                      );
                                    },
                              )
                            : NoRecordFound(message: languages.noRecordFound);
                      case Status.error:
                        return NoRecordFound(
                          message: snapshot.data?.message ?? "",
                        );
                      default:
                        return Container();
                    }
                  }
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: deviceWidth * 0.02,
                    ),
                    child: Center(
                      child: Text(
                        languages.enterContactOrEmailToSearchPerson,
                        textAlign: TextAlign.center,
                        style: bodyText(
                          fontSize: textSizeBig,
                          textColor: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
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
