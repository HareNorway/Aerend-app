import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:aerend_customer/screens/common/homeMainV1/home_main_v1.dart';
import 'package:aerend_customer/screens/common/manageAddress/manage_address_dl.dart';
import 'package:aerend_customer/screens/common/swipeAerend/swipe_aerend_bloc.dart';
import 'package:aerend_customer/commonView/no_record_found.dart';
import 'package:aerend_customer/networking/api_response.dart';
import 'package:aerend_customer/utils/discount_star.dart';
import 'swipe_card.dart';
import 'swipe_aerend_dl.dart';
import 'swipe_buttons.dart';

import '../../../utils/utils.dart';

class SwipeReen extends StatefulWidget {
  const SwipeReen({super.key});

  @override
  State<SwipeReen> createState() => _SwipeAerendState();
}

class _SwipeAerendState extends State<SwipeReen> {
  late AppinioSwiperDirection swipeDirection = AppinioSwiperDirection.none;
  late SwipeAerendBloc bloc;
  int cardIndex = 0;
  double _swipeDragDx = 0;
  bool _cartBusy = false;
  bool _blocReady = false;
  List<SwipeCardModel> _deck = [];
  StreamSubscription<bool>? _cartLoadingSub;

  void _onSwiperControllerChanged() {
    if (!mounted) return;
    final AppinioSwiperState? controllerState = bloc.controller.state;
    AppinioSwiperDirection next = AppinioSwiperDirection.none;
    if (controllerState == AppinioSwiperState.swipeLeft) {
      next = AppinioSwiperDirection.left;
    } else if (controllerState == AppinioSwiperState.swipeRight) {
      next = AppinioSwiperDirection.right;
    }
    if (next != swipeDirection) {
      setState(() => swipeDirection = next);
    }
  }

  void _onSwipePointerMove(PointerMoveEvent event) {
    if (event.delta.dx == 0) return;
    _swipeDragDx += event.delta.dx;
    final AppinioSwiperDirection next;
    if (_swipeDragDx.abs() < 8) {
      next = AppinioSwiperDirection.none;
    } else {
      next = _swipeDragDx > 0
          ? AppinioSwiperDirection.right
          : AppinioSwiperDirection.left;
    }
    if (next != swipeDirection) {
      setState(() => swipeDirection = next);
    }
  }

  void _resetSwipeDirection() {
    _swipeDragDx = 0;
    if (swipeDirection != AppinioSwiperDirection.none) {
      setState(() => swipeDirection = AppinioSwiperDirection.none);
    }
  }

  void _initDeck(List<SwipeCardModel> source) {
    if (_deck.isEmpty && source.isNotEmpty) {
      _deck = List<SwipeCardModel>.from(source);
      cardIndex = 0;
    }
  }

  void _onCardSwiped(int index, AppinioSwiperDirection direction) {
    if (index < 0 || index >= _deck.length) return;

    final SwipeCardModel swipedItem = _deck[index];
    final int removedIndex = index;

    setState(() {
      swipeDirection = AppinioSwiperDirection.none;
      _deck.removeAt(removedIndex);
      if (_deck.isEmpty) {
        cardIndex = 0;
      } else {
        cardIndex = cardIndex.clamp(0, _deck.length - 1);
      }
    });

    if (direction != AppinioSwiperDirection.right) return;

    bloc.handleSwipeCard(swipedItem.storeId, swipedItem.productId).then((ok) {
      if (ok || !mounted) return;
      setState(() {
        final int insertAt = removedIndex.clamp(0, _deck.length);
        _deck.insert(insertAt, swipedItem);
        cardIndex = insertAt.clamp(0, _deck.length - 1);
      });
    });
  }

  @override
  void dispose() {
    _cartLoadingSub?.cancel();
    if (_blocReady) {
      bloc.controller.removeListener(_onSwiperControllerChanged);
      bloc.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_blocReady) return;
    _blocReady = true;
    bloc = SwipeAerendBloc(context, this);
    bloc.controller.addListener(_onSwiperControllerChanged);
    _cartLoadingSub = bloc.isLoading.listen((loading) {
      if (!mounted) return;
      setState(() => _cartBusy = loading);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        automaticallyImplyLeading: false,
        foregroundColor: isDark ? Colors.white : colorBlack,
        toolbarHeight: 80,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            ElevatedButton(
              onPressed: () =>
                  openScreenWithResult(context, const HomeMainV1()),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  elevation: 1,
                  padding: const EdgeInsets.all(12),
                  shape: const CircleBorder()),
              child: SvgPicture.asset('assets/svgs/icons/back.svg',
                  height: 20, width: 20, color: isDark ? Colors.white : null),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Ærend Explore',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on,
                          color: colorPrimary, size: 18.0),
                      const SizedBox(width: 4.0),
                      Flexible(
                        child: Text(
                          AddressListItem.fromJson(jsonDecode(
                                  prefGetString(prefNewDeliveryAddress)))
                              .address
                              .split(',')[0],
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(
                              fontSize: 14.0,
                              color: colorPrimary,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => openScreenWithResult(
                  context, const HomeMainV1(homeIndex: 1, fromStore: true)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  elevation: 1,
                  padding: const EdgeInsets.all(10),
                  shape: const CircleBorder()),
              child: SvgPicture.asset('assets/svgs/icons/bucket.svg',
                  height: 26, width: 26, color: isDark ? Colors.white : null),
            ),
          ],
        ),
      ),
      body: StreamBuilder<ApiResponse<HareSwipeListPojo>>(
        stream: bloc.subject,
        builder: (context, snap) {
          if (snap.hasData) {
            switch (snap.data?.status) {
              case Status.loading:
                return const Center(child: CircularProgressIndicator());
              case Status.completed:
                return reenSwipeView(context, bloc);
              case Status.error:
                return NoRecordFound(
                  message: snap.data?.message ?? "",
                  height: deviceAverageSize * 0.2,
                );
              default:
                break;
            }
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  reenSwipeView(BuildContext context, SwipeAerendBloc bloc) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: double.infinity,
      width: double.infinity,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: StreamBuilder<List<SwipeCardModel>>(
          stream: bloc.swipeList,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasData && snap.data!.isNotEmpty) {
              _initDeck(snap.data!);
              if (_deck.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final int safeIndex = cardIndex.clamp(0, _deck.length - 1);
              final SwipeCardModel candidate = _deck[safeIndex];
              return Stack(
                children: [
                  Listener(
                    onPointerMove: _onSwipePointerMove,
                    onPointerUp: (_) => _resetSwipeDirection(),
                    onPointerCancel: (_) => _resetSwipeDirection(),
                    child: SizedBox(
                      height: deviceHeight * .6,
                      child: AppinioSwiper(
                        cards: _deck
                            .map((item) => SwipeCard(
                                  key: ValueKey(
                                      "swipe_${item.productId}_${item.storeId}"),
                                  candidate: item,
                                ))
                            .toList(),
                        isDisabled: _cartBusy,
                        unlimitedUnswipe: true,
                        controller: bloc.controller,
                        unswipe: _unswipe,
                        onSwipe: _onCardSwiped,
                        padding: const EdgeInsets.only(
                          left: 10,
                          right: 10,
                          top: 25,
                          bottom: 40,
                        ),
                        onEnd: () async {
                          if (_cartBusy) {
                            await Future.delayed(
                                const Duration(milliseconds: 400));
                          }
                          if (!mounted) return;
                          openScreenWithResult(
                              context,
                              const HomeMainV1(
                                  homeIndex: 1, fromStore: true));
                        },
                      ),
                    ),
                  ),
                  if (cardIndex < _deck.length)
                    Positioned(
                      bottom: 10,
                      left: 10,
                      right: 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            candidate.productName,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DiscountStar(discount: candidate.discountPercent),
                              Flexible(
                                child: RichText(
                                  overflow: TextOverflow.ellipsis,
                                  text: TextSpan(
                                    text: 'NOK ${candidate.amount}  ',
                                    style: const TextStyle(
                                      color: colorPrimary,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    children: <TextSpan>[
                                      TextSpan(
                                        text: 'NOK ${candidate.originalAmount}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: isDark ? Colors.white54 : colorBlack,
                                          decoration: TextDecoration.lineThrough,
                                          decorationThickness: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            width: deviceWidth * 0.7,
                            child:
                                LayoutBuilder(builder: (context, constraints) {
                              final textPainter = TextPainter(
                                text: TextSpan(
                                  text: candidate.description,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                maxLines: 2,
                                textDirection: TextDirection.ltr,
                              )..layout(maxWidth: constraints.maxWidth);
                              final isOverflowing =
                                  textPainter.didExceedMaxLines;
                              return RichText(
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: isOverflowing
                                          ? candidate.description.substring(
                                              0,
                                              textPainter
                                                  .getPositionForOffset(Offset(
                                                      constraints.maxWidth -
                                                          100,
                                                      textPainter.height))
                                                  .offset)
                                          : candidate.description,
                                      style: const TextStyle(
                                          color: colorMainLightGray),
                                    ),
                                    if (isOverflowing)
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.middle,
                                        child: GestureDetector(
                                          onTap: () => _showDescriptionModal(
                                              context, candidate),
                                          child: const Text(
                                            "   Read More",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 30),
                          IconTheme.merge(
                            data: const IconThemeData(size: 40),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                swipeLeftButton(
                                    context, bloc.controller, swipeDirection),
                                const SizedBox(width: 20),
                                swipeRightButton(
                                    context, bloc.controller, swipeDirection),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                ],
              );
            } else {
              return NoRecordFound(
                message: "No Swipe Card found",
                height: deviceAverageSize * 0.2,
              );
            }
          }),
    );
  }

  void _unswipe(bool unswiped) {
    if (unswiped) {
      setState(() {
        cardIndex -= 1;
      });
      print("SUCCESS: card was unswiped");
    } else {
      print("FAIL: no card left to unswipe");
    }
  }

  void _showDescriptionModal(BuildContext context, SwipeCardModel item) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0)),
            content: SizedBox(
                width: deviceWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        const SizedBox(
                          height: 50,
                          child: Center(
                              child: Text(
                            "Product Details",
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
                            child: SvgPicture.asset(
                                'assets/svgs/icons/back.svg',
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  style: const TextStyle(
                                      fontSize: 20, fontWeight: FontWeight.bold)),
                              Text(item.storeName,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(
                                      fontSize: 14, color: colorMainGray))
                            ],
                          ),
                        ),
                        Text('${item.amount}kr',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold))
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(item.description,
                        style:
                            const TextStyle(fontSize: 14, color: colorMainGray))
                  ],
                )),
          );
        });
  }
}
