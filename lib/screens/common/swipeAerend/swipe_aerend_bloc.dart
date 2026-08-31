import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:appinio_swiper/appinio_swiper.dart';

import '../../../blocs/bloc.dart';
import '../../../utils/cart_store_conflict_helper.dart';
import '../../../utils/utils.dart';
import 'swipe_aerend_dl.dart';
import 'swipe_aerend_repo.dart';

class SwipeAerendBloc extends Bloc {
  String tag = "SwipeAerendBloc>>>";
  late BuildContext context;
  final State state;
  final AppinioSwiperController controller = AppinioSwiperController();

  SwipeAerendBloc(this.context, this.state) {
    getHareSwipeList();
  }

  final _subject = BehaviorSubject<ApiResponse<HareSwipeListPojo>>();
  final _swipeListController = BehaviorSubject<List<SwipeCardModel>>();
  final _isLoading = BehaviorSubject<bool>.seeded(false);

  Stream<bool> get isLoading => _isLoading;

  BehaviorSubject<ApiResponse<HareSwipeListPojo>> get subject => _subject;
  Stream<List<SwipeCardModel>> get swipeList => _swipeListController.stream;

  getHareSwipeList() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subject.sink.add(ApiResponse.loading());
      try {
        final response = HareSwipeListPojo.fromJson(await SwipeAerendRepo()
            .callHareSwipeApi(
                prefGetLatLng().latitude, prefGetLatLng().longitude));

        if (!state.mounted) return;
        String message =
            getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true,
            showMess: false)) {
          _swipeListController.sink.add(response.swipeList);
          _subject.sink.add(ApiResponse.completed(response));
        } else {
          _subject.sink.add(ApiResponse.error(message));
        }
      } catch (e) {
        logd(tag, e.toString());
        _subject.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      _subject.sink.add(ApiResponse.error(languages.internetConnLostTitle));
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  Future<bool> handleSwipeCard(int storeId, int productId) async {
    if (storeId <= 0 || productId <= 0) {
      logd(tag, 'Invalid swipe cart ids store=$storeId product=$productId');
      if (state.mounted) {
        openSimpleSnackbar(languages.swipeCouldNotAdd);
      }
      return false;
    }

    final deviceToken = prefGetString(prefDeviceToken);
    if (deviceToken.trim().isEmpty) {
      if (state.mounted) {
        openSimpleSnackbar(languages.swipeTokenMissing);
      }
      return false;
    }

    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      if (!state.mounted) return false;
      openSimpleSnackbar(languages.internetConnLostTitle);
      return false;
    }

    _isLoading.sink.add(true);
    try {
      final bool added = await addToCartResolvingStoreConflict(
        context: context,
        storeId: storeId,
        productId: productId,
      );

      if (!state.mounted) return false;

      if (added) {
        return true;
      }

      controller.unswipe();
      return false;
    } catch (e) {
      logd(tag, e.toString());
      if (state.mounted) {
        openSimpleSnackbar(e.toString(), duration: 1);
      }
      return false;
    } finally {
      _isLoading.sink.add(false);
    }
  }

  @override
  void dispose() {
    _subject.close();
    _swipeListController.close();
    _isLoading.close();
  }
}
