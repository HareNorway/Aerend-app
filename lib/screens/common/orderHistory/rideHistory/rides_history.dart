import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../../commonView/common_circular_progress_indicator.dart';
import '../../../../commonView/no_record_found.dart';
import '../../../../networking/api_base_helper.dart';
import '../../../../utils/utils.dart';
import 'item_rides_history.dart';
import 'rides_history_bloc.dart';
import 'rides_history_dl.dart';
import 'rides_history_shimmer.dart';

class RideHistory extends StatefulWidget {
  final RidesHistoryBloc bloc;
  final PagingController<int, RidesItem> pagingController;

  const RideHistory({
    super.key,
    required this.bloc,
    required this.pagingController,
  });

  @override
  RideOrderHistoryState createState() => RideOrderHistoryState();
}

class RideOrderHistoryState extends State<RideHistory>
    with AutomaticKeepAliveClientMixin<RideHistory> {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _buildRideHistory();
  }

  _buildRideHistory() {
    return Container(
      color: colorMainBackground,
      child: StreamBuilder<ApiResponse<RidesHistoryPojo>>(
        stream: widget.bloc.subject,
        builder: (context, snap) {
          var isLoading = snap.hasData && snap.data?.status == Status.loading;
          var isError = snap.hasData && snap.data?.status == Status.error;
          Widget simmerView = RideHistoryShimmer(enabled: isLoading);
          RidesHistoryPojo? data = snap.data?.data;
          return (isLoading && data == null)
              ? simmerView
              : !isError
              ? PagedListView<int, RidesItem>(
                  pagingController: widget.pagingController,
                  padding: EdgeInsetsDirectional.only(
                    top: deviceHeight * 0.005,
                    bottom: deviceHeight * 0.1,
                  ),
                  shrinkWrap: true,
                  builderDelegate: PagedChildBuilderDelegate<RidesItem>(
                    itemBuilder: (context, item, index) => ItemRidesHistory(
                      ridesItem: item,
                      pagingController: widget.pagingController,
                    ),
                    newPageProgressIndicatorBuilder: (_) => Container(
                      margin: EdgeInsetsDirectional.only(
                        top: deviceHeight * 0.008,
                        bottom: deviceHeight * 0.008,
                      ),
                      alignment: AlignmentDirectional.center,
                      child: Wrap(
                        children: [
                          CommonCircularProgressIndicator(
                            strokeWidth: deviceHeight * cpiStrokeWidthSmall,
                            size: deviceHeight * cpiSizeSmall,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : NoRecordFound(
                  rippleIconData: CustomIcons.orderHistoryEmpty,
                  message: snap.data?.message ?? "",
                  withRipple: true,
                  rippleImgSize: deviceHeight * 0.1,
                );
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
