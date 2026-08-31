import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../../commonView/common_circular_progress_indicator.dart';
import '../../../../commonView/no_record_found.dart';
import '../../../../networking/api_base_helper.dart';
import '../../../../utils/utils.dart';
import 'deliveries_history_bloc.dart';
import 'deliveries_history_dl.dart';
import 'deliveries_history_shimmer.dart';
import 'item_deliveries_history.dart';

class DeliveriesHistory extends StatefulWidget {
  final DeliveriesHistoryBloc bloc;
  final PagingController<int, DeliveriesHistoryItem> pagingController;

  const DeliveriesHistory({
    super.key,
    required this.bloc,
    required this.pagingController,
  });

  @override
  DeliveriesHistoryState createState() => DeliveriesHistoryState();
}

class DeliveriesHistoryState extends State<DeliveriesHistory>
    with AutomaticKeepAliveClientMixin<DeliveriesHistory> {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _buildDeliveriesHistory();
  }

  _buildDeliveriesHistory() {
    return Container(
      color: colorMainBackground,
      child: StreamBuilder<ApiResponse<DeliveriesHistoryPojo>>(
        stream: widget.bloc.subject,
        builder: (context, snap) {
          var isLoading = snap.hasData && snap.data?.status == Status.loading;
          var isError = snap.hasData && snap.data?.status == Status.error;
          Widget simmerView = DeliveriesHistoryShimmer(enabled: isLoading);
          return isLoading
              ? simmerView
              : !isError
              ? PagedListView<int, DeliveriesHistoryItem>(
                  pagingController: widget.pagingController,
                  padding: EdgeInsetsDirectional.only(
                    top: deviceHeight * 0.005,
                    bottom: deviceHeight * 0.1,
                  ),
                  shrinkWrap: true,
                  builderDelegate:
                      PagedChildBuilderDelegate<DeliveriesHistoryItem>(
                        itemBuilder: (context, item, index) =>
                            ItemDeliveriesHistory(
                              deliveriesHistoryItem: item,
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
