import '../campaign_media.dart';

// Mirrors the response from GET /api/public/campaign/{slug}
// Envelope: { status: 200, state: 'live'|'ended'|'upcoming', campaign: {...} }

class CampaignDetailPojo {
  int? status;
  String? state;
  CampaignDetail? campaign;
  String? message;

  CampaignDetailPojo.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    state = json['state'];
    message = json['message'];
    if (json['campaign'] != null) {
      campaign = CampaignDetail.fromJson(json['campaign']);
    }
  }

  bool get isLive => state == 'live';
  bool get isEnded => state == 'ended';
  bool get isUpcoming => state == 'upcoming';
  bool get isNotFound => status == 404;
}

class CampaignDetail {
  int id;
  String name;
  String slug;
  String? description;
  String? logoUrl;
  String? heroImageUrl;
  String? landingHeading;
  String? landingIntroText;
  String? salesWindowStart;
  String? salesWindowEnd;
  String? distributionDate;
  String? distributionLocation;
  CampaignClub? club;
  CampaignTeam? team;
  List<CampaignProduct> products;

  /// Payout config exposed by the API (Chunk 12). Null for ended/upcoming.
  String? clubPayoutType;
  double? clubPayoutValue;
  double totalRevenueNok;
  double? fundraisingGoalNok;
  int? goalPercent;

  CampaignDetail({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.logoUrl,
    this.heroImageUrl,
    this.landingHeading,
    this.landingIntroText,
    this.salesWindowStart,
    this.salesWindowEnd,
    this.distributionDate,
    this.distributionLocation,
    this.club,
    this.team,
    this.products = const [],
    this.clubPayoutType,
    this.clubPayoutValue,
    this.totalRevenueNok = 0,
    this.fundraisingGoalNok,
    this.goalPercent,
  });

  factory CampaignDetail.fromJson(Map<String, dynamic> json) {
    return CampaignDetail(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      logoUrl: _resolveMediaUrl(json['logo_url']),
      heroImageUrl: _resolveMediaUrl(json['hero_image_url']),
      landingHeading: json['landing_heading'],
      landingIntroText: json['landing_intro_text'],
      salesWindowStart: json['sales_window_start'],
      salesWindowEnd: json['sales_window_end'],
      distributionDate: json['distribution_date'],
      distributionLocation: json['distribution_location'],
      club: json['club'] != null ? CampaignClub.fromJson(json['club']) : null,
      team: json['team'] != null ? CampaignTeam.fromJson(json['team']) : null,
      products: json['products'] != null
          ? (json['products'] as List)
              .map((e) => CampaignProduct.fromJson(e))
              .toList()
          : [],
      clubPayoutType: json['club_payout_type'] as String?,
      clubPayoutValue: (json['club_payout_value'] as num?)?.toDouble(),
      totalRevenueNok: (json['total_revenue_nok'] as num?)?.toDouble() ?? 0,
      fundraisingGoalNok: (json['fundraising_goal_nok'] as num?)?.toDouble(),
      goalPercent: (json['goal_percent'] as num?)?.toInt(),
    );
  }

  String get displayHeading => landingHeading ?? name;

  static String? _resolveMediaUrl(dynamic value) => CampaignMedia.resolveUrl(value);
}

class CampaignClub {
  int id;
  String name;
  String? logo;

  CampaignClub({required this.id, required this.name, this.logo});

  factory CampaignClub.fromJson(Map<String, dynamic> json) {
    return CampaignClub(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      logo: CampaignDetail._resolveMediaUrl(json['logo']),
    );
  }
}

class CampaignTeam {
  int id;
  String name;
  String? slug;
  String? logoUrl;

  CampaignTeam({
    required this.id,
    required this.name,
    this.slug,
    this.logoUrl,
  });

  factory CampaignTeam.fromJson(Map<String, dynamic> json) {
    return CampaignTeam(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'],
      logoUrl: CampaignDetail._resolveMediaUrl(json['logo_url']),
    );
  }
}

class CampaignProduct {
  int id;
  String name;
  String? description;
  String? contentsDescription;
  double price;
  List<String> images;
  String? thumbnail;
  int sortOrder;
  bool? isSoldOut;
  int? stockQuantity;
  bool? showStockOnPortal;

  CampaignProduct({
    required this.id,
    required this.name,
    this.description,
    this.contentsDescription,
    required this.price,
    this.images = const [],
    this.thumbnail,
    this.sortOrder = 0,
    this.isSoldOut,
    this.stockQuantity,
    this.showStockOnPortal,
  });

  List<String> get displayImages {
    if (images.isNotEmpty) return images;
    if (thumbnail != null && thumbnail!.isNotEmpty) return [thumbnail!];
    return const [];
  }

  factory CampaignProduct.fromJson(Map<String, dynamic> json) {
    final stockRaw = json['stock_quantity'];
    return CampaignProduct(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      contentsDescription: json['contents_description'],
      price: (json['price'] as num?)?.toDouble() ?? 0,
      images: (json['images'] as List?)
              ?.map((e) => CampaignDetail._resolveMediaUrl(e) ?? '')
              .where((e) => e.isNotEmpty)
              .toList() ??
          [],
      thumbnail: CampaignDetail._resolveMediaUrl(json['thumbnail']),
      sortOrder: json['sort_order'] ?? 0,
      isSoldOut: json['is_sold_out'] == true || json['is_sold_out'] == 1,
      stockQuantity: stockRaw == null ? null : (stockRaw is int ? stockRaw : int.tryParse(stockRaw.toString())),
      showStockOnPortal: json['show_stock_on_portal'] == true || json['show_stock_on_portal'] == 1,
    );
  }
}
