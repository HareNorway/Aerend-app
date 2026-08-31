import 'package:flutter/material.dart';

import '../../../commonView/no_record_found.dart';
import '../../../networking/api_response.dart';
import '../../../utils/utils.dart';
import '../home/ds_home_dl.dart';
import '../home/ds_home_shimmer.dart';
import '../home/item_restaurant.dart';
import '../storeDetail/store_detail.dart';
import 'view_category_bloc.dart';

class ViewCategory extends StatefulWidget {
  final int categoryId;
  final String? categoryName;

  const ViewCategory({super.key, required this.categoryId, this.categoryName});

  @override
  State<StatefulWidget> createState() => _ViewCategoryState();
}

class _ViewCategoryState extends State<ViewCategory> {
  late ViewCategoryBloc _bloc;

  @override
  void initState() {
    _bloc = ViewCategoryBloc(context, widget.categoryId, this);
    super.initState();
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ApiResponse<DsHomeStoreListPojo>>(
      stream: _bloc.subject,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          switch (snapshot.data!.status!) {
            case Status.loading:
              return const DsHomeShimmer(enabled: true);
            case Status.completed:
              List<StoreListItem> storeList =
                  snapshot.data?.data?.storeList ?? [];
              return ListView(
                children: List.generate(storeList.length, (index) {
                  StoreListItem storeItem = storeList[index];
                  return InkWell(
                    child: ItemRestaurant(storeListItem: storeItem),
                    onTap: () {
                      openScreen(
                        context,
                        StoreDetail(
                          storeId: storeItem.storeId,
                          storeName: storeItem.storeName,
                        ),
                      );
                    },
                  );
                }),
              );

            case Status.error:
              return NoRecordFound(
                message: snapshot.data?.message ?? "",
                height: deviceAverageSize * 0.18,
              );
          }
        } else {
          return const DsHomeShimmer(enabled: true);
        }
      },
    );
  }
}
