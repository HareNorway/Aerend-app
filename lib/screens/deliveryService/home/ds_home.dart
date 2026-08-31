import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../commonView/surface_decorations.dart';
import '../../../networking/api_base_helper.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import 'package:aerend_customer/screens/common/manageAddress/manage_address_dl.dart';
import 'package:aerend_customer/commonView/no_record_found.dart';
import 'package:aerend_customer/screens/deliveryService/storeDetail/store_detail.dart';

import 'ds_home_bloc.dart';
import 'ds_home_dl.dart';
import 'ds_home_shimmer.dart';
import 'widgets/purple_hero.dart';
import 'widgets/promo_carousel.dart';
import 'widgets/category_wheel.dart';

class DSHome extends StatefulWidget {
  const DSHome({super.key});

  @override
  State<DSHome> createState() => _DSHomeState();
}

class _DSHomeState extends State<DSHome> {
  late DSHomeBloc _bloc;
  int tabIndex = 0;
  int brandId = 0;
  int storeCatId = 0;

  List<ProductCategoryList> storeCategoryList = [];

  bool get _isReenSportsMode => prefGetBool(prefReenSportsMode);
  int get _activeClubId => prefGetInt(prefActiveSportsClubId);

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    _bloc = DSHomeBloc(context, this);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  // ── Location label from prefs ────────────────────────────────────
  String get _locationLabel {
    try {
      final raw = prefGetString(prefNewDeliveryAddress);
      if (raw.trim().isEmpty) return 'Velg adresse';
      return AddressListItem.fromJson(jsonDecode(raw))
          .address
          .split(',')[0];
    } catch (_) {
      return 'Velg adresse';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScSaasThemeTokens.background,
      body: _buildDSHome(context),
    );
  }

  Widget _buildDSHome(BuildContext context) {
    bool isFood = prefGetInt(prefSelectedServiceCateId) == 5;
    return RefreshIndicator(
      onRefresh: () {
        _bloc.selectedLatLng = defaultLatLng;
        return _bloc.refreshScreen();
      },
      child: StreamBuilder(
        stream: _bloc.tabControllerLength,
        builder: (context, snap) {
          return CustomScrollView(
            slivers: [
              // ── Purple gradient hero ──────────────────────────────
              SliverToBoxAdapter(
                child: PurpleHero(
                  locationLabel: _locationLabel,
                  onLocationTap: () => _bloc.gotoSelectLocation(),
                  onSearchTap: () => _bloc.openSearchStoreScreen(),
                ),
              ),

              // ── Promo carousel (from service_slider_data) ────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 8),
                  child: _promoCarousel(),
                ),
              ),

              // ── Category wheel ────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: _categoryWheel(),
                ),
              ),

              // ── Brand category (fashion service only) ─────────────
              if (prefGetInt(prefSelectedServiceCateId) == 6)
                _brandCategory(),

              // ── Section header ────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    "${languages.nearBy} ${isFood ? languages.restaurant : languages.store}",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      letterSpacing: -0.015 * 22,
                      color: ScSaasThemeTokens.text,
                    ),
                  ),
                ),
              ),

              // ── Store list ────────────────────────────────────────
              _viewCategory(isFood),
            ],
          );
        },
      ),
    );
  }

  // ── Promo carousel bound to service_slider_data ─────────────────
  Widget _promoCarousel() {
    return StreamBuilder<ApiResponse<DsHomeStoreListPojo>>(
      stream: _bloc.subject,
      builder: (context, snapshot) {
        final data = snapshot.data?.data;
        if (data == null) return const SizedBox.shrink();

        final sliders = data.serviceSliderData;
        if (sliders.isEmpty) {
          // Static placeholder when no slider data from API.
          return PromoCarousel(
            slides: const [
              PromoSlide(
                title: 'Velkommen til Reen Dugnad',
                eyebrow: 'Ny i byen?',
              ),
            ],
          );
        }

        return PromoCarousel(
          slides: sliders
              .map((s) => PromoSlide(
                    title: s.storeName,
                    eyebrow: 'Anbefalt',
                    imageUrl: s.bannerImage,
                    storeId: s.storeId,
                  ))
              .toList(),
          onSlideTap: (i) {
            final slide = sliders[i];
            if (slide.storeId > 0) {
              openScreen(
                context,
                StoreDetail(
                  storeId: slide.storeId,
                  storeName: slide.storeName,
                ),
              );
            }
          },
        );
      },
    );
  }

  // ── Category wheel bound to store categories ────────────────────
  Widget _categoryWheel() {
    return StreamBuilder<ApiResponse<StoreCategoryPojo>>(
      stream: _bloc.subjectStoreCat,
      builder: (context, snapshot) {
        final bool isLoading =
            snapshot.hasData && snapshot.data?.status == Status.loading;
        if (isLoading) {
          return const SizedBox(
            height: 280,
            child: Center(
              child: CircularProgressIndicator(
                color: ScSaasThemeTokens.primary,
              ),
            ),
          );
        }

        final categories = [
          StoreCategoryList(
            storeCategoryName: 'Alle',
            storeCategoryIcon: prefGetString(prefSelectedServiceCateIcon),
          ),
          ...?snapshot.data?.data?.storeCategoryList,
        ];

        final chips = categories
            .map((c) => CategoryChip(
                  id: c.storeCategoryId,
                  label: c.storeCategoryName,
                  iconUrl: c.storeCategoryIcon,
                ))
            .toList();

        return Center(
          child: CategoryWheel(
            categories: chips,
            onCategoryTap: (index) {
              setState(() {
                storeCatId = categories[index].storeCategoryId;
              });
              _bloc.homeStoreListApiCall(storeCatId, brandId);
            },
          ),
        );
      },
    );
  }

  Widget _brandCategory() {
    return StreamBuilder<ApiResponse<BrandCategoryPojo>>(
      stream: _bloc.subjectBrand,
      builder: (context, snapshot) {
        var isLoading =
            snapshot.hasData && snapshot.data?.status == Status.loading;
        if (isLoading) {
          return SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.018),
              child: DsCategoryShimmer(enabled: true),
            ),
          );
        }

        List<BrandCategoryList> brandCategoryList =
            snapshot.data?.data?.brandCategoryList ?? [];

        return SliverToBoxAdapter(
          child: brandCategoryList.isNotEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(
                        brandCategoryList.length,
                        (index) => GestureDetector(
                          onTap: () {
                            setState(() {
                              if (brandId ==
                                  brandCategoryList[index].brandId) {
                                brandId = 0;
                              } else {
                                brandId =
                                    brandCategoryList[index].brandId;
                              }
                            });
                            _bloc.homeStoreListApiCall(storeCatId, brandId);
                          },
                          child: SizedBox(
                            width: 70,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: brandId ==
                                            brandCategoryList[index].brandId
                                        ? ScSaasThemeTokens.success
                                        : Theme.of(context)
                                            .colorScheme
                                            .surface,
                                    borderRadius:
                                        BorderRadius.circular(100),
                                    boxShadow: ScSaasThemeTokens.shadowCard,
                                  ),
                                  child: SvgPicture.network(
                                    brandCategoryList[index].brandIcon,
                                    placeholderBuilder: (_) =>
                                        const CircularProgressIndicator(),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Flexible(
                                  child: Text(
                                    brandCategoryList[index].brandName,
                                    style: bodyText(fontSize: textSizeSmall),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _viewCategory(bool isFood) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        child: StreamBuilder<ApiResponse<DsHomeStoreListPojo>>(
          stream: _bloc.subject,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              switch (snapshot.data!.status!) {
                case Status.loading:
                  return const DsHomeShimmer(enabled: true);
                case Status.completed:
                  List<StoreListItem> storeList =
                      snapshot.data?.data?.storeList ?? [];
                  bool hasActiveClub = _isReenSportsMode && _activeClubId > 0;
                  if (hasActiveClub && isFood) {
                    storeList = storeList
                        .where((s) => s.storeId == _activeClubId)
                        .toList();
                    if (storeList.isEmpty) {
                      return NoRecordFound(
                        message: _activeClubId > 0
                            ? "Matkasse is not available today."
                            : "No active sports club scheduled for today.",
                        height: deviceAverageSize * 0.18,
                      );
                    }
                  }
                  return Column(
                    children: List.generate(storeList.length, (index) {
                      StoreListItem storeItem = storeList[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: RepaintBoundary(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            child: _storeCard(storeItem),
                            onTap: () {
                              openScreen(
                                context,
                                StoreDetail(
                                  storeId: storeItem.storeId,
                                  storeName: storeItem.storeName,
                                ),
                              );
                            },
                          ),
                        ),
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
        ),
      ),
    );
  }

  String _storeListSubtitle(StoreListItem storeItem) {
    final String desc = storeItem.description.trim();
    final String name = storeItem.storeName.trim();
    if (desc.isNotEmpty && desc.toLowerCase() != name.toLowerCase()) {
      return desc;
    }
    if (storeItem.storeProducts.trim().isNotEmpty) {
      return storeItem.storeProducts;
    }
    if (storeItem.offer.trim().isNotEmpty) {
      return storeItem.offer;
    }
    return storeItem.orderDeliveryTime != null &&
            '${storeItem.orderDeliveryTime}'.isNotEmpty
        ? '${languages.deliveryTime}: ${storeItem.orderDeliveryTime} min'
        : '';
  }

  Widget _storeCard(StoreListItem storeItem) {
    final String subtitle = _storeListSubtitle(storeItem);
    final double avatarSize = 64;

    return Container(
      decoration: AeSurface.card(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            clipBehavior: Clip.antiAlias,
            child: LoadImageSimple(
              image: storeItem.storeBanner,
              width: avatarSize,
              height: avatarSize,
              imageFit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  storeItem.storeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    letterSpacing: -0.005 * 15,
                    color: ScSaasThemeTokens.text,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: ScSaasThemeTokens.gray500,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.star_rounded,
                        size: 16, color: Colors.amber.shade600),
                    const SizedBox(width: 2),
                    Text(
                      storeItem.averageRatings,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: ScSaasThemeTokens.text,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (storeItem.storeStatus == 1) ...[
                      Icon(Icons.schedule_rounded,
                          size: 14, color: ScSaasThemeTokens.gray500),
                      const SizedBox(width: 2),
                      Text(
                        '${storeItem.orderDeliveryTime} min',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ScSaasThemeTokens.gray500,
                        ),
                      ),
                    ] else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: ScSaasThemeTokens.primaryTint,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          languages.closed,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: ScSaasThemeTokens.primaryHover,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
