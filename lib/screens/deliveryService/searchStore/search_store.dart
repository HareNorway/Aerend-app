import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:aerend_customer/screens/common/manageAddress/manage_address_dl.dart';
import 'package:aerend_customer/screens/deliveryService/searchStore/search_store_repo.dart';

import 'package:aerend_customer/screens/deliveryService/storeDetail/add_on_repo.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aerend_customer/screens/deliveryService/storeDetail/widget_size_color.dart';
import 'package:aerend_customer/screens/deliveryService/storeDetail/widget_topping_option.dart';
import 'package:aerend_customer/theme/sc_saas_theme.dart';
import 'package:aerend_customer/utils/discount_star.dart';
import '../../../commonView/surface_decorations.dart';

import 'package:aerend_customer/screens/common/homeMainV1/home_main_v1.dart';
import '../../../commonView/common_circular_progress_indicator.dart';
import '../../../commonView/common_view.dart';
import '../../../networking/api_base_helper.dart';
import '../../../utils/utils.dart';
import '../../common/home/home_dl.dart';
import '../../common/home/item_home_main_category.dart';
import '../home/ds_home_dl.dart';
import '../home/ds_home_shimmer.dart';
import '../home/item_dishes.dart';
import '../home/item_restaurant.dart';
import '../home/item_store_list.dart';
import '../storeDetail/store_detail.dart';
import 'search_dishes_shimmer.dart';
import 'search_store_bloc.dart';
import 'search_store_dl.dart';

class SearchStore extends StatefulWidget {
  final LatLng latLng;
  final String keyword;

  const SearchStore({super.key, required this.latLng, this.keyword = ''});

  @override
  State<StatefulWidget> createState() => _SearchStoreState();
}

class _SearchStoreState extends State<SearchStore> {
  final TextEditingController _searchController = TextEditingController();
  late SearchStoreBloc _bloc;
  HomeMainV1State? _homeShell;
  bool isSearched = false;
  bool isEmptyBar = true;
  List<int> activeCategoryIdList = [];
  List storeList = [];
  List productList = [];
  int prodQuantity = 1;
  bool inStock = true;
  String addOnsMessage = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      searchFunc(widget.keyword);
    });
  }

  @override
  void didChangeDependencies() {
    _bloc = SearchStoreBloc(context, widget.latLng, this);
    final home = context.findAncestorStateOfType<HomeMainV1State>();
    if (home != _homeShell) {
      _homeShell?.searchLaunchKeyword.removeListener(_applyHomeLaunchKeyword);
      _homeShell = home;
      _homeShell?.searchLaunchKeyword.addListener(_applyHomeLaunchKeyword);
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _homeShell?.searchLaunchKeyword.removeListener(_applyHomeLaunchKeyword);
    _searchController.dispose();
    _bloc.dispose();
    super.dispose();
  }

  void _applyHomeLaunchKeyword() {
    final keyword = _homeShell?.searchLaunchKeyword.value.trim() ?? '';
    if (keyword.isEmpty) return;
    _searchController.text = keyword;
    searchFunc(keyword);
    _homeShell?.searchLaunchKeyword.value = '';
  }

  void searchFunc(value) async {
    final lowerCasedValue = value.trim().toLowerCase();
    if (lowerCasedValue == '') {
      setState(() {
        isSearched = false;
      });
    } else {
      final response = await SearchStoreRepo().callSearchHareApi(
          prefGetLatLng().latitude, prefGetLatLng().longitude, lowerCasedValue);
      setState(() {
        if (response['status'] == 1) {
          storeList = response['store_list'];
          productList = response['product_list'];
          isSearched = true;
        }
      });
    }
  }

  String get _locationLabel {
    try {
      final raw = prefGetString(prefNewDeliveryAddress);
      if (raw.trim().isEmpty) return languages.dugnadSelectAddress;
      return AddressListItem.fromJson(jsonDecode(raw)).address.split(',')[0];
    } catch (_) {
      return languages.dugnadSelectAddress;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScSaasThemeTokens.background,
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: ScSaasThemeTokens.background,
        toolbarHeight: 56,
        title: Text(languages.search, style: aeH2()),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: Column(
          children: [
            // Location row
            Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    color: ScSaasThemeTokens.primary, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(_locationLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: aeCaption(color: ScSaasThemeTokens.primaryHover)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Search field
            Container(
              decoration: AeSurface.card(
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextFormField(
                keyboardType: TextInputType.text,
                controller: _searchController,
                style: aeBody(),
                onChanged: (value) {
                  setState(() {
                    final lowerCasedValue = value.trim().toLowerCase();
                    if (lowerCasedValue == '') {
                      isEmptyBar = true;
                      isSearched = false;
                    } else {
                      isEmptyBar = false;
                    }
                  });
                },
                onFieldSubmitted: searchFunc,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: ScSaasThemeTokens.gray500, size: 20),
                  hintText: languages.heroSearchStoresProducts,
                  hintStyle: aeCaption(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            isSearched ? _buildSearchedView() : _buildDefaultView(context),
          ],
        ),
      ),
    );
  }

  searchStoreList() => StreamBuilder<List<StoreListItem>>(
        stream: _bloc.storeList,
        builder: (context, snap) {
          return StreamBuilder<ApiResponse<DsHomeStoreListPojo>>(
              stream: _bloc.subject,
              builder: (context, snapLoading) {
                var isLoading = snapLoading.hasData &&
                    snapLoading.data?.status == Status.loading;
                var isError = snapLoading.hasData &&
                    snapLoading.data?.status == Status.error;
                var simmerView = DsHomeShimmer(enabled: isLoading);
                return isLoading
                    ? simmerView
                    : !isError
                        ? (snap.data != null && snap.data!.isNotEmpty)
                            ? ListView.builder(
                                shrinkWrap: true,
                                padding:
                                    const EdgeInsetsDirectional.only(top: 0),
                                itemCount: snap.data?.length ?? 0,
                                itemBuilder: (BuildContext context, position) {
                                  return GestureDetector(
                                    child: ItemStoreList(
                                        storeListItem: snap.data![position]),
                                    onTap: () {
                                      openScreen(
                                          context,
                                          StoreDetail(
                                            storeId:
                                                snap.data![position].storeId,
                                            storeName:
                                                snap.data![position].storeName,
                                          ));
                                    },
                                  );
                                },
                              )
                            : noRecordFound(
                                prefGetInt(prefSelectedServiceCateId) == 5
                                    ? languages.noAnyRestaurantFound
                                    : languages.noAnyStoreFound)
                        : noRecordFound(snapLoading.data?.message ?? "");
              });
        },
      );

  Widget _buildDefaultView(BuildContext context) {
    return Flexible(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 15),
            StreamBuilder<ApiResponse<ProductCategoryPojo>>(
                stream: _bloc.subjectProductCat,
                builder: (context, snapshot) {
                  var isLoading = snapshot.hasData &&
                      snapshot.data?.status == Status.loading;
                  Widget shimmer = Container(
                    margin:
                        EdgeInsetsDirectional.only(top: deviceHeight * 0.018),
                    child: DsCategoryShimmer(enabled: isLoading),
                  );

                  List<ProductCategoryList> productCategoryList =
                      snapshot.data?.data?.productCategoryList ?? [];

                  return isLoading
                      ? shimmer
                      : productCategoryList.isNotEmpty
                          ? Wrap(
                              alignment: WrapAlignment.center,
                              children: List.generate(
                                productCategoryList.length,
                                (index) => GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      int productCategoryId =
                                          productCategoryList[index]
                                              .productCategoryId;
                                      if (activeCategoryIdList
                                          .contains(productCategoryId)) {
                                        activeCategoryIdList.remove(
                                            productCategoryList[index]
                                                .productCategoryId);
                                        _searchController.text =
                                            _searchController.text.replaceAll(
                                                ', ${productCategoryList[index].productCategoryName.toLowerCase()}',
                                                '');
                                        _searchController.text =
                                            _searchController.text.replaceAll(
                                                '${productCategoryList[index].productCategoryName.toLowerCase()},',
                                                '');
                                        _searchController.text =
                                            _searchController.text.replaceAll(
                                                productCategoryList[index]
                                                    .productCategoryName
                                                    .toLowerCase(),
                                                '');
                                        _searchController.text =
                                            _searchController.text.trim();
                                        if (_searchController.text.isEmpty) {
                                          isEmptyBar = true;
                                        }
                                      } else {
                                        if (_searchController.text.isEmpty) {
                                          _searchController.text =
                                              productCategoryList[index]
                                                  .productCategoryName
                                                  .toLowerCase();
                                          isEmptyBar = false;
                                        } else {
                                          _searchController.text +=
                                              ', ${productCategoryList[index].productCategoryName.toLowerCase()}';
                                        }
                                        activeCategoryIdList.add(
                                            productCategoryList[index]
                                                .productCategoryId);
                                      }
                                    });
                                  },
                                  child:
                                      _categoryCard(productCategoryList[index]),
                                ),
                              ),
                            )
                          : Container();
                }),
            const SizedBox(height: 8),
            if (!isEmptyBar)
              GestureDetector(
                onTap: () => searchFunc(_searchController.text),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: ScSaasThemeTokens.primary,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: ScSaasThemeTokens.shadowButton,
                  ),
                  child: Text(languages.search, style: aeLabel(color: Colors.white)),
                ),
              ),
            const SizedBox(height: 12),
            ExploreAerend(context)
          ],
        ),
      ),
    );
  }

  Widget _productCard(dynamic productInfo) {
    return GestureDetector(
      onTap: () async {
        var response =
            await AddOnRepo().getToppingsAndOptions(productInfo['product_id']);
        if (!mounted) return;
        if (response['status'] == 1) {
          _orderFoodSheet(
              productInfo,
              response['options_list'],
              response['size_list'],
              response['color_list'],
              response['service_category_id']);
        }
      },
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: 10),
        decoration: AeSurface.card(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(18)),
                  child: LoadImageSimple(
                      image: productInfo['product_image'],
                      height: 120,
                      width: 170,
                      imageFit: BoxFit.cover),
                ),
                if (productInfo['discount_amount'] > 0)
                  DiscountStar(
                      discount: productInfo['discount_percent'], scale: 0.65),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productInfo['product_name'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: aeTitle(),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (productInfo['discount_amount'] > 0)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            '${productInfo['original_amount']} kr',
                            style: aeCaption().copyWith(
                              decoration: TextDecoration.lineThrough,
                              decorationColor: ScSaasThemeTokens.gray500,
                            ),
                          ),
                        ),
                      Text('${productInfo['product_amount']} kr',
                          style: aeLabel()),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryCard(ProductCategoryList productCategory) {
    final bool isActive =
        activeCategoryIdList.contains(productCategory.productCategoryId);
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: isActive ? ScSaasThemeTokens.primary : ScSaasThemeTokens.primaryTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        productCategory.productCategoryName,
        style: aeCaption(
          color: isActive ? Colors.white : ScSaasThemeTokens.primaryHover,
        ).copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildSearchedView() {
    return Flexible(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Row(
              children: [
                Text(languages.products, style: aeH3()),
                const SizedBox(width: 8),
                Text('${productList.length}',
                    style: aeCaption()),
                const Spacer(),
                // TextButton(
                //   onPressed: () {},
                //   child: Container(
                //     padding:
                //         const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                //     decoration: BoxDecoration(
                //       borderRadius: BorderRadius.circular(10.0),
                //       color: Colors.red.withOpacity(0.1),
                //     ),
                //     child: const Text(
                //       'See all',
                //       style: TextStyle(
                //         fontSize: 12,
                //         color: colorPrimary,
                //         fontWeight: FontWeight.bold,
                //       ),
                //     ),
                //   ),
                // )
              ],
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  productList.length,
                  (index) => _productCard(productList[index]),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(languages.searchStores, style: aeH3()),
                const SizedBox(width: 8),
                Text('${storeList.length}',
                    style: aeCaption()),
                const Spacer(),
                // TextButton(
                //   onPressed: () {},
                //   child: Container(
                //     height: 25,
                //     width: 60,
                //     padding:
                //         const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                //     decoration: BoxDecoration(
                //       borderRadius: BorderRadius.circular(10.0),
                //       color: Colors.red.withOpacity(0.1),
                //     ),
                //     child: const Text(
                //       'See all',
                //       style: TextStyle(
                //         fontSize: 12,
                //         color: colorPrimary,
                //         fontWeight: FontWeight.bold,
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
            const SizedBox(height: 20),
            Column(
              children: List.generate(
                  storeList.length, (index) => _storeCard(storeList[index])),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _storeCard(dynamic storeInfo) {
    return GestureDetector(
      onTap: () => openScreenWithResult(
        context,
        StoreDetail(
            storeId: storeInfo['store_id'], storeName: storeInfo['store_name']),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: AeSurface.card(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: LoadImageSimple(
                width: double.infinity,
                height: 120,
                image: storeInfo['store_banner'],
                imageFit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(storeInfo['store_name'], style: aeTitle()),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'NOK ${storeInfo["min_product_value"]} – ${storeInfo['max_product_value']}',
                        style: aeLabel(),
                      ),
                      const Spacer(),
                      Icon(Icons.schedule_rounded,
                          size: 14, color: ScSaasThemeTokens.gray500),
                      const SizedBox(width: 4),
                      Text('${storeInfo['order_delivery_time']} min',
                          style: aeCaption()),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryList(List<ServicesItem> serviceList) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.9, // Adjust this ratio as needed
      ),
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(
        horizontal: deviceWidth * 0.03,
        vertical: deviceHeight * 0.02,
      ),
      itemCount: serviceList.length,
      itemBuilder: (BuildContext context, int position) {
        ServicesItem servicesItem = serviceList[position];
        return GestureDetector(
          onTap: () {
            setSelectedServiceInPref(
                servicesItem.serviceCategoryId,
                servicesItem.serviceCategoryName,
                servicesItem.serviceCategoryIcon);
            openServices(context, serviceList[position].serviceCategoryId);
          },
          child: ItemHomeMainCategory(
            servicesItem: serviceList[position],
            radius: 1,
          ),
        );
      },
    );
  }

  void _orderFoodSheet(dynamic productInfo, List optionList, List sizeList,
      List colorList, int serviceCategoryId) {
    List productImageList = productInfo['product_image_list'];

    List<Widget> sliderList = productImageList
        .map((item) => ClipRRect(
              borderRadius: BorderRadius.circular(20.0),
              child: LoadImageSimple(
                width: deviceWidth,
                height: deviceHeight * 0.33,
                image: item,
                imageFit: BoxFit.contain,
              ),
            ))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: const BoxConstraints(minWidth: double.infinity),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15), topRight: Radius.circular(15))),
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return SizedBox(
            height: deviceHeight * 0.83,
            child: Stack(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: sliderList),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  top: deviceHeight * 0.35,
                  bottom: 80,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                productInfo['product_name'],
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ),
                            // const Icon(
                            //   Icons.share_outlined,
                            //   size: 20,
                            //   color: colorMainLightGray,
                            // )
                          ],
                        ),
                        const SizedBox(height: 15),
                        Text(
                          'NOK ${productInfo['product_amount']}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        LayoutBuilder(builder: (context, constraints) {
                          final textPainter = TextPainter(
                            text: TextSpan(
                                text: productInfo['description'],
                                style: const TextStyle(color: Colors.grey)),
                            maxLines: 2,
                            textDirection: TextDirection.ltr,
                          )..layout(maxWidth: constraints.maxWidth);
                          final isOverflowing = textPainter.didExceedMaxLines;
                          return RichText(
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: isOverflowing
                                      ? productInfo['description'].substring(
                                          0,
                                          textPainter
                                              .getPositionForOffset(Offset(
                                                  constraints.maxWidth - 100,
                                                  textPainter.height))
                                              .offset)
                                      : productInfo['description'],
                                  style: const TextStyle(
                                      color: colorMainLightGray),
                                ),
                                if (isOverflowing)
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: GestureDetector(
                                      onTap: () => _showDescriptionModal(
                                          context, productInfo),
                                      child: Text(
                                        "   ${languages.storeReadMore}",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                        const Divider(),
                        if (addOnsMessage != '')
                          Text(addOnsMessage,
                              style: const TextStyle(color: colorRed)),
                        const SizedBox(height: 8),
                        if (getAddOnsType(categoryId: serviceCategoryId) ==
                            typeSizeColor)
                          SizeColorWidget(
                            sizeOptional: productInfo['size_optional'],
                            colorOptional: productInfo['color_optional'],
                            sizeList: sizeList,
                            colorList: colorList,
                            validate: (value) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                setState(() {
                                  inStock = value;
                                });
                              });
                            },
                          )
                        else if (getAddOnsType(categoryId: serviceCategoryId) ==
                            typeToppingOption)
                          ToppingOptionWidget(
                              optionList: optionList,
                              validate: (value) {
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  setState(() {
                                    addOnsMessage = value;
                                  });
                                });
                              })
                      ],
                    ),
                  ),
                ),
                Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 36,
                        width: 36,
                        padding: const EdgeInsets.all(0),
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            boxShadow: [
                              BoxShadow(
                                color: colorGray.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(1, 5),
                              ),
                            ],
                            borderRadius: BorderRadius.circular(18)),
                        child: Icon(
                          Icons.close,
                          size: 25,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : colorBlack,
                        ),
                      ),
                    )),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            if (prodQuantity > 1) prodQuantity--;
                          });
                        },
                        icon: Icon(
                          Icons.remove_circle,
                          color: prodQuantity > 1
                              ? colorGreen
                              : colorGreen.withOpacity(0.3),
                          size: 27,
                        ),
                      ),
                      Text(
                        '$prodQuantity',
                        style: const TextStyle(color: colorGreen, fontSize: 18),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            prodQuantity++;
                          });
                        },
                        icon: const Icon(Icons.add_circle,
                            color: colorGreen, size: 27),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 30),
                        height: 50,
                        width: deviceWidth * 0.5,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorGreen,
                            foregroundColor: colorWhite,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            textStyle: const TextStyle(fontSize: 20),
                          ),
                          onPressed: !inStock || addOnsMessage != ''
                              ? null
                              : () {
                                  _bloc.addOrderCart(productInfo['store_id'],
                                      productInfo['product_id'], prodQuantity);
                                  Navigator.pop(context);
                                },
                          child: Text(languages.orderNow),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}

void _showDescriptionModal(BuildContext context, dynamic item) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          content: SizedBox(
              width: deviceWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      SizedBox(
                        height: 50,
                        child: Center(
                            child: Text(
                          languages.storeProductDetails,
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        )),
                      ),
                      Positioned(
                        left: -10,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.surface,
                              elevation: 1,
                              padding: const EdgeInsets.all(10),
                              shape: const CircleBorder()),
                          child: SvgPicture.asset('assets/svgs/icons/back.svg',
                              height: 18,
                              width: 18,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : null),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 25),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['product_name'] ?? '',
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(item['store_name'],
                                    style: const TextStyle(
                                        fontSize: 14, color: colorMainGray)),
                                if (item['discount_amount'] > 0)
                                  Text(
                                    'NOK ${item['original_amount']}',
                                    style: const TextStyle(
                                      color: colorPrimary,
                                      decoration: TextDecoration.lineThrough,
                                      decorationColor: colorPrimary,
                                      decorationThickness: 2,
                                    ),
                                  ),
                                Text('NOK ${item['product_amount']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold))
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(item['description'] ?? '',
                      style:
                          const TextStyle(fontSize: 14, color: colorMainGray))
                ],
              )),
        );
      });
}

void _showFilterModal(BuildContext context) {
  showModalBottomSheet(
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(15),
        topRight: Radius.circular(15),
      ),
    ),
    context: context,
    builder: (BuildContext context) {
      return Stack(
        children: [
          Container(
            height: deviceHeight * 0.8,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader('Filter', 20),
                const SizedBox(height: 15),
                _buildHeader('Category', 20),
                const SizedBox(height: 10),
                _buildCategoryFilter(),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 10),
                _buildHeader('Filter By', 20),
                const SizedBox(height: 10),
                _buildFilterBy(),
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 10),
                _buildHeader('Price', 20),
                const SizedBox(height: 8),
                _buildPriceFilter(),
                const SizedBox(height: 30),
                _buildApplyButton(context),
              ],
            ),
          ),
          Positioned(
              top: 20,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 36,
                  width: 36,
                  padding: const EdgeInsets.all(0),
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: colorGray.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(1, 5),
                        ),
                      ],
                      borderRadius: BorderRadius.circular(18)),
                  child: Icon(
                    Icons.close,
                    size: 25,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : colorBlack,
                  ),
                ),
              )),
        ],
      );
    },
  );
}

Widget _buildHeader(String title, double fontSize) {
  return Text(
    title,
    style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
  );
}

Widget _buildFilterOption(String label, bool isSelected) {
  return Row(
    children: [
      Icon(
        isSelected ? Icons.check_circle : Icons.circle_outlined,
        color: colorPrimary,
        size: 20,
      ),
      const SizedBox(width: 15),
      Text(
        label,
        style: TextStyle(
          fontSize: 20,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? null : colorMainLightGray,
        ),
      ),
    ],
  );
}

Widget _buildCategoryFilter() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterOption('Restaurant', true),
            const SizedBox(height: 5),
            _buildFilterOption('Beauty', false),
            const SizedBox(height: 5),
            _buildFilterOption('Health', false),
            const SizedBox(height: 5),
            _buildFilterOption('Snack & Drinks', false),
            const SizedBox(height: 5),
            _buildFilterOption('Daily Goods', false),
          ],
        ),
      ),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterOption('Pet', false),
            const SizedBox(height: 5),
            _buildFilterOption('Store', false),
            const SizedBox(height: 5),
            _buildFilterOption('Market', false),
            const SizedBox(height: 5),
            _buildFilterOption('Alcohol', false),
          ],
        ),
      ),
    ],
  );
}

Widget _buildFilterBy() {
  return Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterOption('Open', true),
            const SizedBox(height: 10),
            _buildFilterOption('Self Pickup', false),
          ],
        ),
      ),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterOption('Latest', false),
            const SizedBox(height: 10),
            _buildFilterOption('Popular', false),
          ],
        ),
      ),
    ],
  );
}

Widget _buildPriceFilter() {
  return Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterOption('under NOK 50', true),
            const SizedBox(height: 10),
            _buildFilterOption('NOK 50 to NOK 100', false),
          ],
        ),
      ),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterOption('NOK 100 To NOK 200', false),
            const SizedBox(height: 10),
            _buildFilterOption('over NOK 200', false),
          ],
        ),
      ),
    ],
  );
}

Widget _buildApplyButton(context) {
  return SizedBox(
    height: 45,
    width: double.infinity,
    child: ElevatedButton(
      onPressed: () => Navigator.pop(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: colorGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: const Text(
        'Apply',
        style: TextStyle(
            color: colorWhite, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    ),
  );
}

noRecordFound(String message) => Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        maxLines: 1,
        style: bodyText(
            fontSize: textSizeBig,
            fontWeight: FontWeight.normal),
      ),
    );

class DsSearchDishes extends StatefulWidget {
  final SearchStoreBloc? bloc;

  const DsSearchDishes({super.key, this.bloc});

  @override
  State<DsSearchDishes> createState() => _DsSearchDishesState();
}

class _DsSearchDishesState extends State<DsSearchDishes>
    with AutomaticKeepAliveClientMixin<DsSearchDishes> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    bool isFood = prefGetInt(prefSelectedServiceCateId) == 5;
    return Container(
      padding: EdgeInsetsDirectional.only(
          start: deviceWidth * 0.025,
          end: deviceWidth * 0.025,
          top: deviceHeight * 0.01),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isFood ? languages.searchForFood : languages.searchForProducts,
            textAlign: TextAlign.start,
            style: headerText(),
          ),
          SizedBox(
            height: deviceHeight * 0.012,
          ),
          Expanded(
            child: StreamBuilder<ApiResponse<SearchProductPojo>>(
                stream: widget.bloc?.subjectSearchProduct,
                builder: (context, snapSearchProduct) {
                  if (snapSearchProduct.hasData) {
                    switch (snapSearchProduct.data!.status!) {
                      case Status.loading:
                        return const SearchDishesShimmer(enabled: true);
                      case Status.completed:
                        return PagedListView<int, ProductList>(
                          pagingController: widget.bloc!.pagingController,
                          padding: EdgeInsetsDirectional.only(
                              start: deviceWidth * 0.025,
                              end: deviceWidth * 0.025,
                              top: 0,
                              bottom: 0),
                          shrinkWrap: true,
                          builderDelegate:
                              PagedChildBuilderDelegate<ProductList>(
                            itemBuilder: (context, item, index) {
                              double discountAmount = getDoubleFromDynamic(
                                  item.discountAmount ?? 0);
                              double productAmount =
                                  getDoubleFromDynamic(item.productAmount ?? 0);
                              return GestureDetector(
                                onTap: () {
                                  openScreen(
                                      context,
                                      StoreDetail(
                                        storeId: item.storeId,
                                        storeName: item.storeName,
                                      ));
                                },
                                child: ItemDishes(
                                  name: item.productName,
                                  image: item.productImage,
                                  oldPrice: discountAmount > 0
                                      ? getAmountCurrency(
                                          item.discountAmount ?? 0)
                                      : "",
                                  price: productAmount > 0
                                      ? getAmountCurrency(
                                          item.productAmount ?? 0)
                                      : "",
                                  storeName: item.storeName,
                                ),
                              );
                            },
                            newPageProgressIndicatorBuilder: (_) => Container(
                              margin: EdgeInsetsDirectional.only(
                                  top: deviceHeight * 0.01,
                                  bottom: deviceHeight * 0.01),
                              alignment: AlignmentDirectional.center,
                              child: Wrap(
                                children: [
                                  CommonCircularProgressIndicator(
                                    strokeWidth:
                                        deviceHeight * cpiStrokeWidthSmall,
                                    size: deviceHeight * cpiSizeSmall,
                                    color: colorPrimary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      case Status.error:
                        return noRecordFound(
                            snapSearchProduct.data?.message ?? "");
                    }
                  }

                  return noRecordFound(isFood
                      ? languages.noAnyDishesFound
                      : languages.noAnyProductsFound);
                }),
          )
        ],
      ),
    );
  }
}

class DsSearchRestaurants extends StatefulWidget {
  final SearchStoreBloc? bloc;
  final LatLng latLng;

  const DsSearchRestaurants({super.key, required this.latLng, this.bloc});

  @override
  State<DsSearchRestaurants> createState() => _DsSearchRestaurantsState();
}

class _DsSearchRestaurantsState extends State<DsSearchRestaurants>
    with AutomaticKeepAliveClientMixin<DsSearchRestaurants> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    bool isFood = prefGetInt(prefSelectedServiceCateId) == 5;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: deviceWidth * 0.025, vertical: deviceHeight * 0.01),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isFood ? languages.searchForRestaurants : languages.searchForStore,
            textAlign: TextAlign.start,
            style: headerText(),
          ),
          SizedBox(
            height: deviceHeight * 0.012,
          ),
          Expanded(
            child: StreamBuilder<List<StoreListItem>>(
              stream: widget.bloc!.storeList,
              builder: (context, snap) {
                return StreamBuilder<ApiResponse<DsHomeStoreListPojo>>(
                    stream: widget.bloc!.subject,
                    builder: (context, snapLoading) {
                      var isLoading = snapLoading.hasData &&
                          snapLoading.data?.status == Status.loading;
                      var isError = snapLoading.hasData &&
                          snapLoading.data?.status == Status.error;
                      var simmerView = DsHomeShimmer(enabled: isLoading);
                      return isLoading
                          ? simmerView
                          : !isError
                              ? (snap.data != null &&
                                      (snap.data ?? []).isNotEmpty)
                                  ? ListView.builder(
                                      shrinkWrap: true,
                                      padding: const EdgeInsetsDirectional.only(
                                          top: 0),
                                      itemCount: snap.data?.length ?? 0,
                                      itemBuilder:
                                          (BuildContext context, position) {
                                        return Column(
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal:
                                                      deviceWidth * 0.0225),
                                              child: GestureDetector(
                                                child: ItemRestaurant(
                                                  storeListItem:
                                                      snap.data![position],
                                                ),
                                                onTap: () {
                                                  FocusManager
                                                      .instance.primaryFocus
                                                      ?.unfocus();
                                                  openScreen(
                                                      context,
                                                      StoreDetail(
                                                        storeId: snap
                                                            .data![position]
                                                            .storeId,
                                                        storeName: snap
                                                            .data![position]
                                                            .storeName,
                                                      ));
                                                },
                                              ),
                                            ),
                                            if (position !=
                                                ((snap.data?.length ?? 0) -
                                                    1)) //It's a divider...
                                              Container(
                                                margin: EdgeInsets.symmetric(
                                                    vertical:
                                                        deviceHeight * 0.01,
                                                    horizontal:
                                                        deviceWidth * 0.0225),
                                                color: colorDivider,
                                                height: deviceHeight * 0.001,
                                              ),
                                          ],
                                        );
                                      },
                                    )
                                  : noRecordFound(
                                      prefGetInt(prefSelectedServiceCateId) == 5
                                          ? languages.noAnyRestaurantFound
                                          : languages.noAnyStoreFound)
                              : noRecordFound(snapLoading.data?.message ?? "");
                    });
              },
            ),
          )
        ],
      ),
    );
  }
}
