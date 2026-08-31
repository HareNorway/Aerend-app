# Skeleton Loader System - Implementation Guide

## Overview
This document outlines the new skeleton loader system that replaces blinking animations with smooth, subtle shimmer-based skeleton UI components throughout the Hare-Customer app.

## Key Changes

### 1. **Blinking Animation Removal**
- ✅ Removed `.repeat()` from RipplesAnimationView (`ripples_animation_view.dart`)
- ✅ Removed `.repeat()` from RedeemCode screen (`redeem_code.dart`)
- ✅ All animations now use subtle shimmer (1500ms period) instead of rapid blinking (800ms)

### 2. **Subtle Shimmer Animation**
- **Period**: 1500ms (instead of 800ms) for smooth, non-blinking effect
- **Base Color**: Light gray (#e5ecf1) from `colorShimmerBg`
- **Highlight Color**: Light white (Colors.grey[100]!)
- **Effect**: Creates a gentle wave-like shimmer that feels smooth and professional

### 3. **New Skeleton Components**

#### Base Components (`skeleton_loaders/base_skeleton.dart`)
```dart
// Individual skeleton elements
BaseSkeleton - Generic shimmer placeholder
TextSkeleton - Text line placeholder
ImageSkeleton - Image/icon placeholder (circular or rectangular)
ButtonSkeleton - Button placeholder
CardSkeleton - Card with image and text lines
ListItemSkeleton - List item with avatar and text
```

#### Screen-Level Skeletons (`skeleton_loaders/screen_skeletons.dart`)
```dart
StoreListSkeleton - Restaurant/store list loading
ProductListSkeleton - Products in grid or list format
DetailPageSkeleton - Full detail page (store/product)
CheckoutSkeleton - Checkout screen
```

## Implementation Examples

### Example 1: Basic Text Loading
```dart
// Before (blinking)
CircularProgressIndicator()

// After (skeleton)
Column(
  children: [
    TextSkeleton(width: double.infinity, height: 18),
    SizedBox(height: 8),
    TextSkeleton(width: double.infinity * 0.7, height: 14),
  ],
)
```

### Example 2: List Item Loading
```dart
// Before
CustomShimmerLayout()

// After (improved with 1500ms period and better structure)
ListView.builder(
  itemCount: 8,
  itemBuilder: (context, index) => ListItemSkeleton(),
)
```

### Example 3: Product List Loading
```dart
// Before
ProductListShimmer(enabled: true)

// After (updated with 1500ms period)
ProductListSkeleton(
  enabled: snapshot.data?.status == Status.loading,
  itemCount: 6,
  isGrid: false,
)
```

### Example 4: Store Detail Loading
```dart
// Before
StoreDetailShimmer(enabled: true)

// After (using new DetailPageSkeleton or updated StoreDetailShimmer with 1500ms)
if (snapshot.data?.status == Status.loading)
  DetailPageSkeleton(enabled: true)
else
  // actual content
```

## Updated Files

### Shimmer Period Updates (800ms → 1500ms)
The following files have been updated to use the subtle 1500ms shimmer:

**Common Shimmer Components:**
- ✅ `custom_shimmer_layout.dart` - General list skeleton

**Home & Discovery:**
- ✅ `home_v1_shimmer.dart` - HomeV1Shimmer, HomeBannerShimmer, FeatureStoreShimmer, InSpotLightShimmer
- ✅ `ds_home_shimmer.dart` - Delivery service home

**Delivery Service:**
- ✅ `store_detail_shimmer.dart` - Store details
- ✅ `product_list_shimmer.dart` - Product lists
- ✅ `checkout_shimmer.dart` - Checkout page
- ✅ `deliveries_order_detail_shimmer.dart` - Order details

**Ride Service:**
- ✅ `ride_detail_shimmer.dart` - Ride details

**Common Features:**
- ✅ `notifications_shimmer.dart` - Notifications list
- ✅ `chat_history_shimmer.dart` - Chat history
- ✅ `help_and_support_shimmer.dart` - Help & support
- ✅ `manage_card_shimmer.dart` - Card management
- ✅ `manage_address_shimmer.dart` - Address management

**Other Files to Update (same pattern):**
- `select_language_and_currency_shimmer.dart`
- `chatting_shimmer.dart`
- `wallet_transaction_shimmer.dart`
- `search_user_shimmer.dart`
- `rides_history_shimmer.dart`
- `deliveries_history_shimmer.dart`
- `select_payment_method_shimmer.dart`
- `ds_sub_category_shimmer.dart`
- `item_store_list_shimmer.dart`
- `add_filter_shimmer.dart`
- `product_grid_shimmer.dart`
- And any other shimmer components

## How to Use New Skeleton Components

### In Your Screens
```dart
import 'package:hare_customer/commonView/skeleton_loaders/base_skeleton.dart';
import 'package:hare_customer/commonView/skeleton_loaders/screen_skeletons.dart';

// In your StreamBuilder or FutureBuilder
StreamBuilder<ApiResponse>(
  stream: bloc.subject,
  builder: (context, snapshot) {
    // Show skeleton while loading
    if (snapshot.data?.status == Status.loading) {
      return ProductListSkeleton(
        enabled: true,
        itemCount: 6,
        isGrid: true,
      );
    }
    
    // Show actual content when loaded
    return YourContentWidget();
  },
)
```

## Performance Considerations

1. **Shimmer Period**: 1500ms is optimal for smooth appearance without feeling sluggish
2. **Disable When Not Needed**: Set `enabled: false` in shimmer components to disable animation
3. **Lazy Loading**: Skeleton components are lightweight and don't impact performance
4. **Memory**: Shimmer uses GPU acceleration - minimal memory overhead

## Best Practices

1. **Match Actual Layout**: Skeleton structure should closely match the actual content structure
2. **Consistent Spacing**: Use same padding/margins in skeletons as actual content
3. **Test on Real Devices**: Verify shimmer smoothness on actual devices, not just emulators
4. **Accessibility**: Ensure loading state is communicated to screen readers
5. **Timeout Handling**: Replace skeleton with error state if loading takes too long

## Migration Checklist

For each screen using loading states:

- [ ] Replace blinking animations with skeleton loaders
- [ ] Update shimmer period to 1500ms
- [ ] Add proper structure to skeleton (match final layout)
- [ ] Test smooth transition from skeleton to content
- [ ] Verify on multiple devices/screen sizes
- [ ] Check for any layout shifts during transition
- [ ] Add accessibility labels/hints for loading state

## File Locations

- Base Components: `/lib/commonView/skeleton_loaders/base_skeleton.dart`
- Screen Skeletons: `/lib/commonView/skeleton_loaders/screen_skeletons.dart`
- Updated Shimmer: `/lib/commonView/custom_shimmer_layout.dart`
- Disabled Blinking: `/lib/commonView/ripplesAnimationView/ripples_animation_view.dart`

## Troubleshooting

### Shimmer Too Fast
- Check if period is still 800ms (should be 1500ms)
- Increase period to 2000ms for slower effect

### Shimmer Too Slow
- Decrease period to 1200ms or 1300ms
- Test with actual network conditions

### Layout Shift When Loading Complete
- Ensure skeleton dimensions match actual content
- Use same padding/margins in both
- Use `AnimatedSwitcher` for smooth transitions

### Skeleton Not Showing
- Verify `enabled: true` is set
- Check if loading state is being triggered correctly
- Ensure import statements are correct

## Future Enhancements

1. Add skeleton for custom layouts using composition
2. Create variant skeletons for different content types
3. Add animation to skeleton transitions
4. Add analytics for loading time tracking
5. Create dark mode skeleton variants
