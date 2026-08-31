import 'package:flutter/material.dart';

import '../../../blocs/bloc.dart';
import '../../../commonView/bottom_cart_layout.dart';
import '../../../commonView/common_view.dart';
import '../../../utils/utils.dart';
import '../home/ds_home_dl.dart';
import '../productList/product_list.dart';
import '../storeDetail/store_detail_dl.dart';
import 'ds_sub_category_bloc.dart';
import 'ds_sub_category_shimmer.dart';

class DsSubCategory extends StatefulWidget {
  final CategoryWiseProductListItem? categoryWiseProductList;
  final StoreDetailsPojo? storeDetailsPojo;

  const DsSubCategory({super.key, this.categoryWiseProductList, this.storeDetailsPojo});

  @override
  State<DsSubCategory> createState() => _DsSubCategoryState();
}

class _DsSubCategoryState extends State<DsSubCategory> {
  late DsSubCategoryBloc _bloc;

  @override
  void initState() {
    _bloc = DsSubCategoryBloc(context, widget.categoryWiseProductList, widget.storeDetailsPojo, this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.categoryWiseProductList!.categoryName,
          style: toolbarStyle(),
        ),
      ),
      // body: DsSubCategoryShimmer(),
      body: StreamBuilder<ApiResponse<ProductCategoryPojo>>(
          stream: _bloc.subjectProductCat,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              switch (snapshot.data!.status!) {
                case Status.loading:
                  return const DsSubCategoryShimmer();
                case Status.completed:
                  List<ProductCategoryList> productCategoryList = snapshot.data!.data!.productCategoryList;
                  return DefaultTabController(
                    length: productCategoryList.length,
                    child: Column(
                      children: [
                        TabBar(
                          unselectedLabelColor: colorTextCommon,
                          labelColor: colorPrimary,
                          labelPadding: EdgeInsets.symmetric(horizontal: deviceWidth * 0.03),
                          indicatorColor: colorPrimary,
                          indicatorWeight: deviceAverageSize * 0.005,
                          isScrollable: true,
                          labelStyle: bodyText(textColor: colorPrimary, fontWeight: FontWeight.bold),
                          unselectedLabelStyle: bodyText(textColor: colorMainLightGray, fontWeight: FontWeight.w600),
                          tabs: productCategoryList
                              .map<Widget>((s) => Container(
                                    padding: EdgeInsetsDirectional.only(top: deviceHeight * 0.009, bottom: deviceHeight * 0.009),
                                    child: Text(
                                      s.productCategoryName,
                                      textAlign: TextAlign.start,
                                    ),
                                  ))
                              .toList(),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: productCategoryList
                                .asMap()
                                .map((i, element) {
                                  return MapEntry(
                                    i,
                                    ProductList(
                                      storeDetailsPojo: widget.storeDetailsPojo!,
                                      categoryId: element.productCategoryId,
                                      isAppbar: false,
                                    ),
                                    // SubCatProductList(
                                    //   storeDetailsPojo: widget.storeDetailsPojo,
                                    //   categoryName:element.productCategoryName,
                                    //   categoryId: element.productCategoryId,
                                    // ),
                                  );
                                })
                                .values
                                .toList(),
                          ),
                        ),
                        const BottomCartLayout(),
                      ],
                    ),
                  );
                case Status.error:
                  return Error(
                    onRetryPressed: () {},
                    errorMessage: snapshot.data!.message!,
                  );
              }
            }
            return const DsSubCategoryShimmer();
          }),
    );
  }
}
