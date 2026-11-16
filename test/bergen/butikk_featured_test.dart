import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/ops/butikk_models.dart';
import 'package:aerend_customer/screens/deliveryService/storeDetail/store_detail_dl.dart';

/// Design 15 Nov Step 14: the store page follows the Partner app's
/// Forhåndsvisning order (`featured_product_ids` on store-details).
Map<String, dynamic> _store({Object? featured}) => {
  'status': 1,
  'store_id': 43,
  'store_name': 'Test',
  'store_cat_name': 'Restaurant',
  'delivery_time': 30,
  if (featured != null) 'featured_product_ids': featured,
  'category_wise_product_list': [
    {
      'category_id': 1,
      'category_name': 'Mat',
      'sub_category_list': [
        {
          'product_list': [
            for (final id in [801, 802, 803, 804])
              {'product_id': id, 'product_name': 'P$id', 'product_amount': 100},
          ],
        },
      ],
    },
    {
      'category_id': 2,
      'category_name': 'Drikke',
      'sub_category_list': [
        {
          'product_list': [
            {'product_id': 805, 'product_name': 'P805', 'product_amount': 40},
          ],
        },
      ],
    },
  ],
};

List<int> _ids(BergenStoreInfo s) => [for (final i in s.featuredFirst) i.id];

void main() {
  test('no featured list keeps the menu order', () {
    final s = BergenStoreInfo.fromPojo(StoreDetailsPojo.fromJson(_store()));
    expect(s.featuredIds, isEmpty);
    expect(_ids(s), [801, 802, 803, 804, 805]);
  });

  test('featured products come first in the saved order, the rest keep menu order', () {
    final s = BergenStoreInfo.fromPojo(StoreDetailsPojo.fromJson(_store(featured: [805, 803])));
    expect(_ids(s), [805, 803, 801, 802, 804]);
    // allItems (used for «Mest bestilt», search, cart lookups) is unchanged.
    expect([for (final i in s.allItems) i.id], [801, 802, 803, 804, 805]);
  });

  test('ids not on the menu, duplicates and string ids are handled', () {
    final s = BergenStoreInfo.fromPojo(StoreDetailsPojo.fromJson(_store(featured: ['804', 999, 804, 'x', 801])));
    expect(s.featuredIds, [804, 999, 804, 801]);
    expect(_ids(s), [804, 801, 802, 803, 805]);
  });

  test('a list of only unknown ids falls back to the menu order', () {
    final s = BergenStoreInfo.fromPojo(StoreDetailsPojo.fromJson(_store(featured: [999])));
    expect(_ids(s), [801, 802, 803, 804, 805]);
  });

  test('hasFeatured is true only when a saved product is on the menu («Utvalgt» heading)', () {
    expect(BergenStoreInfo.fromPojo(StoreDetailsPojo.fromJson(_store())).hasFeatured, isFalse);
    expect(BergenStoreInfo.fromPojo(StoreDetailsPojo.fromJson(_store(featured: [999]))).hasFeatured, isFalse);
    expect(BergenStoreInfo.fromPojo(StoreDetailsPojo.fromJson(_store(featured: [999, 802]))).hasFeatured, isTrue);
  });

  test('toJson round-trips the featured list', () {
    final p = StoreDetailsPojo.fromJson(_store(featured: [802]));
    expect(StoreDetailsPojo.fromJson(p.toJson()).featuredProductIds, [802]);
  });
}
