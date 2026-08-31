import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../commonView/bottom_cart_layout.dart';
import '../../../commonView/common_circular_progress_indicator.dart';
import '../../../commonView/custom_text_field.dart';
import '../../../commonView/no_record_found.dart';
import '../../../networking/api_base_helper.dart';
import '../../../utils/utils.dart';
import '../storeDetail/product_list/item_product.dart';
import '../storeDetail/store_detail_dl.dart';
import 'product_list_bloc.dart';
import 'product_list_dl.dart';
import 'product_list_shimmer.dart';

class ProductList extends StatefulWidget {
  final StoreDetailsPojo storeDetailsPojo;
  final int categoryId;
  final bool isAppbar;

  const ProductList({super.key, required this.storeDetailsPojo, required this.categoryId, this.isAppbar = true});

  @override
  State<StatefulWidget> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  late ProductListBloc _bloc;

  @override
  void didChangeDependencies() {
    _bloc = ProductListBloc(context, widget.storeDetailsPojo.storeId, widget.categoryId, this);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildProductList(context);

  _buildProductList(BuildContext context) {
    return Scaffold(
      backgroundColor: colorWhite,
      appBar: widget.isAppbar
          ? AppBar(
              centerTitle: false,
              titleSpacing: 0,
              automaticallyImplyLeading: true,
              title: Text(
                languages.search,
                style: toolbarStyle(),
              ),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(deviceHeight * 0.05),
                child: Container(
                  decoration: getBoxDecoration(color: colorGray, radius: deviceAverageSize * 0.015),
                  padding: EdgeInsetsDirectional.only(start: deviceWidth * 0.015, end: deviceWidth * 0.01),
                  margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.03, end: deviceWidth * 0.03, bottom: deviceHeight * 0.012),
                  child: Row(children: [
                    Icon(
                      Icons.search_sharp,
                      color: colorMainLightGray,
                      size: deviceAverageSize * 0.035,
                    ),
                    Expanded(
                        child: TextFormFieldCustom(
                      hint: languages.search,
                      backgroundColor: colorGray,
                      controller: _bloc.searchTEC,
                      radius: deviceAverageSize * 0.015,
                      validator: (value) {
                        return null;
                      },
                      setClear: true,
                    ))
                  ]),
                ),
              ),
            )
          : PreferredSize(
              preferredSize: Size.fromHeight(deviceHeight * 0.1),
              child: Container(
                decoration: getBoxDecoration(
                    radius: deviceAverageSize * 0.015,
                    border: Border.all(
                      width: deviceAverageSize * 0.003,
                      color: colorMainTabDividerColor,
                    )),
                padding: EdgeInsetsDirectional.only(start: deviceWidth * 0.015, end: deviceWidth * 0.01),
                margin: EdgeInsets.symmetric(horizontal: deviceWidth * 0.03, vertical: deviceHeight * 0.012),
                child: Row(children: [
                  Icon(
                    Icons.search_sharp,
                    color: colorMainLightGray,
                    size: deviceAverageSize * 0.035,
                  ),
                  Expanded(
                      child: TextFormFieldCustom(
                    hint: languages.search,
                    controller: _bloc.searchTEC,
                    radius: deviceAverageSize * 0.015,
                    validator: (value) {
                      return null;
                    },
                    setClear: true,
                  ))
                ]),
              ),
            ),
      body: Column(
        children: [
          Expanded(
            child: productData(),
            flex: 1,
          ),
          widget.isAppbar
              ? const Expanded(
                  flex: 0,
                  child: BottomCartLayout(),
                )
              : Container(),
        ],
      ),
    );
  }

  productData() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: StreamBuilder<ApiResponse<StoreProductList>>(
              stream: _bloc.subject,
              builder: (context, snap) {
                if (snap.hasData) {
                  switch (snap.data!.status!) {
                    case Status.loading:
                      return const ProductListShimmer(enabled: true);
                    case Status.completed:
                      return PagedListView<int, ProductListItem>(
                        pagingController: _bloc.pagingController,
                        padding: EdgeInsetsDirectional.only(start: deviceWidth * 0.025, end: deviceWidth * 0.025, top: 0, bottom: 0),
                        shrinkWrap: true,
                        builderDelegate: PagedChildBuilderDelegate<ProductListItem>(
                          itemBuilder: (context, item, index) => ItemProduct(
                            productListItem: item,
                            storeDetailsPojo: widget.storeDetailsPojo,
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
                      );
                    case Status.error:
                      return NoRecordFound(
                        message: snap.data?.message ?? "",
                      );
                  }
                }

                return const ProductListShimmer(enabled: true);
              },
            ),
          ),
        ],
      );
}
