import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../../commonView/common_circular_progress_indicator.dart';
import '../../../../commonView/no_record_found.dart';
import '../../../../networking/api_base_helper.dart';
import '../../../../utils/utils.dart';
import '../../productList/product_list_bloc.dart';
import '../../productList/product_list_dl.dart';
import '../../productList/product_list_shimmer.dart';
import '../store_detail_dl.dart';
import 'item_product.dart';
import 'product_grid_shimmer.dart';

class ProductGridList extends StatefulWidget {
  final StoreDetailsPojo storeDetailsPojo;
  final String categoryName;
  final int categoryId;
  final bool isGrid;

  // const ({Key? key}) : super(key: key);
  const ProductGridList({
    super.key,
    required this.storeDetailsPojo,
    required this.categoryName,
    required this.categoryId,
    required this.isGrid,
  });

  @override
  ProductGridListState createState() => ProductGridListState();
}

class ProductGridListState extends State<ProductGridList> with AutomaticKeepAliveClientMixin<ProductGridList> {
  late ProductListBloc _bloc;
  final PagingController<int, ProductListItem> _pagingController = PagingController(firstPageKey: 1, invisibleItemsThreshold: 1);

  @override
  bool get wantKeepAlive => true;

  getTextController() {
    return _bloc.searchTEC;
  }

  @override
  void didChangeDependencies() {
    _bloc = ProductListBloc(context, widget.storeDetailsPojo.storeId, widget.categoryId, this);
    _pagingController.addPageRequestListener((pageKey) {
      _bloc.getProductList(pageKey, _pagingController);
    });
    _pagingController.notifyPageRequestListeners(1);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _pagingController.dispose();
    _bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<ApiResponse<StoreProductList>>(
        stream: _bloc.subject,
        builder: (context, snapshot) {
          bool shimmerEnable = snapshot.data?.status == Status.loading;
          Widget shimmerView = widget.isGrid ? ProductGridShimmer(enabled: shimmerEnable) : ProductListShimmer(enabled: true, isGrid: widget.isGrid);
          if (snapshot.hasData) {
            switch (snapshot.data?.status ?? Status.loading) {
              case Status.loading:
                return shimmerView;
              case Status.completed:
                if (widget.isGrid) {
                  return PagedGridView(
                    pagingController: _pagingController,
                    builderDelegate: PagedChildBuilderDelegate<ProductListItem>(
                      itemBuilder: (context, item, index) => ItemProduct(
                        productListItem: item,
                        storeDetailsPojo: widget.storeDetailsPojo,
                        isGrid: widget.isGrid,
                      ),
                      newPageProgressIndicatorBuilder: (_) => Container(
                        margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.008),
                        alignment: AlignmentDirectional.center,
                        child: Wrap(
                          children: [
                            CommonCircularProgressIndicator(
                              strokeWidth: deviceHeight * cpiStrokeWidthSmall,
                              size: deviceHeight * cpiSizeSmall,
                              color: colorPrimary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, childAspectRatio: 0.99, crossAxisSpacing: deviceWidth * 0.03, mainAxisSpacing: deviceHeight * 0.01),
                    padding: EdgeInsetsDirectional.only(start: deviceWidth * 0.03, end: deviceWidth * 0.03, bottom: deviceWidth * 0.03),
                  );
                }

                return PagedListView(
                  pagingController: _pagingController,
                  builderDelegate: PagedChildBuilderDelegate<ProductListItem>(
                    itemBuilder: (context, item, index) => ItemProduct(productListItem: item, storeDetailsPojo: widget.storeDetailsPojo),
                    newPageProgressIndicatorBuilder: (_) => Container(
                      margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.008),
                      alignment: AlignmentDirectional.center,
                      child: Wrap(
                        children: [
                          CommonCircularProgressIndicator(
                            strokeWidth: deviceHeight * cpiStrokeWidthSmall,
                            size: deviceHeight * cpiSizeSmall,
                            color: colorPrimary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  padding: EdgeInsetsDirectional.only(start: deviceWidth * 0.03, end: deviceWidth * 0.03, bottom: deviceWidth * 0.03),
                );

              case Status.error:
                return NoRecordFound(
                  message: snapshot.data?.message ?? "",
                );
            }
          } else {
            return Container();
          }
          // return GridView.builder(
          //   itemBuilder: (context, index) {
          //     return const ItemProduct();
          //   },
          //   // itemCount: 10,
          //   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          //       crossAxisCount: 2, childAspectRatio: 0.99, crossAxisSpacing: deviceWidth * 0.03, mainAxisSpacing: deviceHeight * 0.01),
          //   padding: EdgeInsets.symmetric(horizontal: deviceWidth * 0.03),
          // );
        });
  }
}
