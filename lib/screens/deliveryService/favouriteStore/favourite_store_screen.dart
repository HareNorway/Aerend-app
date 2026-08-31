import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../networking/api_response.dart';
import '../../../commonView/guest_empty_state.dart';
import '../../../utils/guest_auth_helper.dart';
import '../../../utils/utils.dart';
import '../home/ds_home_dl.dart';
import '../home/ds_home_shimmer.dart';
import '../home/item_restaurant.dart';
import '../storeDetail/store_detail.dart';
import 'favourite_store_bloc.dart';

class FavouriteStoreScreen extends StatefulWidget {
  final LatLng selectedLatLng;

  const FavouriteStoreScreen({super.key, required this.selectedLatLng});

  @override
  State<FavouriteStoreScreen> createState() => _FavouriteStoreScreenState();
}

class _FavouriteStoreScreenState extends State<FavouriteStoreScreen> {
  late FavouriteStoreBloc _bloc;

  @override
  void didChangeDependencies() {
    _bloc = FavouriteStoreBloc(context, this);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isGuestUser()) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          title: Text(
            languages.favoriteRestaurant,
            style: toolbarStyle(),
          ),
        ),
        body: GuestEmptyState(
          title: languages.signInToSaveFavorites,
          message: languages.guestAccountPromptMessage,
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        centerTitle: false,
        titleSpacing: 0,
        title: Text(
          languages.favoriteRestaurant,
          style: toolbarStyle(),
        ),
      ),
      body: Padding(
        padding: EdgeInsetsDirectional.only(
            top: deviceHeight * 0.01, bottom: deviceHeight * 0.01),
        child: StreamBuilder<ApiResponse<FavouriteStorePojo>>(
            stream: _bloc.subjectFavouriteStore,
            builder: (context, snapFavouriteStore) {
              if (snapFavouriteStore.hasData) {
                switch (snapFavouriteStore.data!.status!) {
                  case Status.loading:
                    return const DsHomeShimmer(enabled: true);
                  case Status.completed:
                    List<StoreListItem> storeList =
                        snapFavouriteStore.data?.data?.storeLists ?? [];
                    return PagedListView<int, StoreListItem>(
                      pagingController: _bloc.pagingController,
                      shrinkWrap: true,
                      builderDelegate: PagedChildBuilderDelegate<StoreListItem>(
                        itemBuilder: (context, item, index) {
                          var storeItem = storeList[index];
                          return InkWell(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: deviceWidth * 0.015),
                              child: ItemRestaurant(
                                storeListItem: storeItem,
                              ),
                            ),
                            onTap: () {
                              openScreen(
                                  context,
                                  StoreDetail(
                                    storeId: storeItem.storeId,
                                    storeName: storeItem.storeName,
                                  ));
                            },
                          );
                        },
                      ),
                    );
                  case Status.error:
                    return Container();
                }
              } else {
                return const DsHomeShimmer(enabled: true);
              }
            }),
      ),
    );
  }
}
