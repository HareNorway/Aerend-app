import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../blocs/bloc.dart';
import '../../screens/common/base_dl.dart';
import '../../utils/utils.dart';
import 'review_dialog_repo.dart';

class ReviewDialogBloc extends Bloc {
  String tag = "ReviewDialog>>>";

  final ReviewDialogRepo _reviewDialogRepo = ReviewDialogRepo();
  late BuildContext context;
  int orderId;
  bool? ratingToDriver;

  State state;

  ReviewDialogBloc(this.context, this.orderId, this.state, {bool this.ratingToDriver = true}) {
    storeCommentController.text = "";
    driverCommentController.text = "";
  }

  final _storeRatingController = BehaviorSubject<double>.seeded(0);
  final _driverRatingController = BehaviorSubject<double>.seeded(0);
  final storeCommentController = TextEditingController();
  final driverCommentController = TextEditingController();
  final _subject = BehaviorSubject<ApiResponse<BaseModel>>();

  BehaviorSubject<ApiResponse<BaseModel>> get subject => _subject;

  Stream<double> get storeRating => _storeRatingController.stream;

  Stream<double> get driverRating => _driverRatingController.stream;

  Function(double) get changeStoreRating => _storeRatingController.sink.add;

  Function(double) get changeDriverRating => _driverRatingController.sink.add;

  isValid() {
    double ratingStoreValue = _storeRatingController.value;
    double ratingDriverValue = _driverRatingController.value;
    String commentStore = storeCommentController.text.trim();
    String commentDriver = driverCommentController.text.trim();

    // openSimpleSnackbar( "${ratingStoreValue == 0 && commentStore.isEmpty}");
    // return false;

    if ((ratingStoreValue == 0 && commentStore.isEmpty) || (ratingToDriver! && ratingDriverValue == 0 && commentDriver.isEmpty)) {
      openSimpleSnackbar( ratingToDriver! ? languages.giveReviewToAnyOne : languages.giveReviewToStore);
      return false;
    } else {
      if (commentStore.isNotEmpty && commentDriver.isNotEmpty) {
        if (ratingStoreValue == 0 && (ratingToDriver! && ratingDriverValue == 0)) {
          openSimpleSnackbar( languages.giveReviewToBoth);
          return false;
        } else if (ratingStoreValue == 0) {
          openSimpleSnackbar( languages.giveReviewToStore);
          return false;
        } else if (ratingToDriver! && ratingDriverValue == 0) {
          openSimpleSnackbar( languages.giveReviewToDriver);
          return false;
        }
      } else if (commentStore.isNotEmpty && ratingStoreValue == 0) {
        openSimpleSnackbar( languages.giveReviewToStore);
        return false;
      } else if (ratingToDriver! && commentDriver.isNotEmpty && ratingDriverValue == 0) {
        openSimpleSnackbar( languages.giveReviewToDriver);
        return false;
      }
    }
    return true;
  }

  submit(Function? onSelected) {
    if (isValid()) {
      callReviewApi(onSelected!);
    }
  }

  callReviewApi(Function onSelected) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subject.sink.add(ApiResponse.loading());
      try {
        var response = BaseModel.fromJson(await _reviewDialogRepo.callOrderRatingApi(orderId, _storeRatingController.value,
            _driverRatingController.value, storeCommentController.text.trim(), driverCommentController.text.trim()));

        if (!state.mounted) return;
        String message = getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true)) {
          _subject.sink.add(ApiResponse.completed(response));
          onSelected(true);
          // Navigator.pop(context, true);
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
      openSimpleSnackbar( languages.internetConnLostTitle);
    }
  }

  @override
  void dispose() {
    _subject.close();
    _storeRatingController.close();
    _driverRatingController.close();
    storeCommentController.dispose();
    driverCommentController.dispose();
  }
}
