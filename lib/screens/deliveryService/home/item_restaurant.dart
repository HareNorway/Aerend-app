import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../../../utils/utils.dart';
import 'ds_home_dl.dart';

class ItemRestaurant extends StatelessWidget {
  final StoreListItem storeListItem;

  const ItemRestaurant({super.key, required this.storeListItem});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(deviceWidth * 0.05),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 3,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10.0),
              topRight: Radius.circular(10.0),
              bottomLeft: Radius.zero,
              bottomRight: Radius.zero,
            ),
            child: LoadImageSimple(
              height: 100,
              width: deviceWidth,
              image: storeListItem.storeBanner,
              imageFit: BoxFit.cover,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        storeListItem.storeName,
                        style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 20.0,
                              fontWeight: FontWeight.w600,
                            ) ??
                            const TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.w600,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // const Icon(CupertinoIcons.heart_fill, color: colorPrimary)
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  storeListItem.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                        color: (theme.textTheme.bodySmall?.color ??
                                (isDark ? Colors.white : Colors.black))
                            .withOpacity(0.7),
                      ) ??
                      const TextStyle(
                        color: colorMainTabTextColor,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.smiley_fill,
                      color: Colors.amber,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      storeListItem.averageRatings,
                      style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ) ??
                          const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.circle,
                      size: 6,
                      color: theme.iconTheme.color?.withOpacity(0.6),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'NOK ${storeListItem.productMinAmount} ~ ${storeListItem.productMaxAmount}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ) ??
                            const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (storeListItem.storeStatus == 1)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 18,
                            color: theme.iconTheme.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ' ${storeListItem.orderDeliveryTime} Min',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ) ??
                                const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: colorPrimary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 3, horizontal: 10),
                        child: const Text(
                          'Close',
                          style: TextStyle(fontSize: 12, color: colorWhite),
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
