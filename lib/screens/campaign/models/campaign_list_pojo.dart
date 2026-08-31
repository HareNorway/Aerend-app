import '../../common/base_dl.dart';
import '../../../networking/api_constant.dart';

/// Mirrors the response from POST /api/customer/campaigns/active
/// Envelope: { status, message, message_code, campaigns: [...] }
class CampaignListPojo extends BaseModel {
  List<CampaignListItem>? _campaigns;

  List<CampaignListItem> get campaigns => _campaigns ?? [];

  CampaignListPojo.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    if (json['campaigns'] != null) {
      _campaigns = (json['campaigns'] as List)
          .map((e) => CampaignListItem.fromJson(e))
          .toList();
    }
  }
}

class CampaignListItem {
  int id;
  String name;
  String slug;
  String? logoUrl;
  String? heroImageUrl;
  String? clubName;
  int? teamId;
  String? teamName;
  String? teamLogoUrl;
  String salesWindowEnd;
  String distributionDate;
  String? distributionLocation;
  int productCount;
  double minPrice;

  CampaignListItem({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    this.heroImageUrl,
    this.clubName,
    this.teamId,
    this.teamName,
    this.teamLogoUrl,
    required this.salesWindowEnd,
    required this.distributionDate,
    this.distributionLocation,
    required this.productCount,
    required this.minPrice,
  });

  factory CampaignListItem.fromJson(Map<String, dynamic> json) {
    return CampaignListItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      logoUrl: _resolveMediaUrl(json['logo_url']),
      heroImageUrl: _resolveMediaUrl(json['hero_image_url']),
      clubName: json['club_name'],
      teamId: (json['team_id'] as num?)?.toInt(),
      teamName: json['team_name'],
      teamLogoUrl: _resolveMediaUrl(json['team_logo_url']),
      salesWindowEnd: json['sales_window_end'] ?? '',
      distributionDate: json['distribution_date'] ?? '',
      distributionLocation: json['distribution_location'],
      productCount: json['product_count'] ?? 0,
      minPrice: (json['min_price'] as num?)?.toDouble() ?? 0,
    );
  }

  static String? _resolveMediaUrl(dynamic value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    if (raw.startsWith('//')) return 'https:$raw';
    if (raw.startsWith('/')) return '${BaseUrl.domain}${raw.substring(1)}';
    return '${BaseUrl.domain}assets/images/store-images/product-images/$raw';
  }
}
