import 'dart:convert';

import '../../utils/shared_pref_utill.dart';

/// Local pending referral attribution before backend capture at signup.
class PendingDugnadReferral {
  final String clubSlug;
  final String? referralToken;
  final String? referralCode;
  final int? organizationId;
  final String? referrerDisplayName;
  final String? organizationName;
  final String? organizationLogo;

  const PendingDugnadReferral({
    required this.clubSlug,
    this.referralToken,
    this.referralCode,
    this.organizationId,
    this.referrerDisplayName,
    this.organizationName,
    this.organizationLogo,
  });

  bool get hasAttribution =>
      (referralToken != null && referralToken!.isNotEmpty) ||
      (referralCode != null && referralCode!.isNotEmpty);

  Map<String, dynamic> toJson() => {
        'club_slug': clubSlug,
        'referral_token': referralToken,
        'referral_code': referralCode,
        'organization_id': organizationId,
        'referrer_display_name': referrerDisplayName,
        'organization_name': organizationName,
        'organization_logo': organizationLogo,
      };

  factory PendingDugnadReferral.fromJson(Map<String, dynamic> json) {
    return PendingDugnadReferral(
      clubSlug: (json['club_slug'] ?? '').toString(),
      referralToken: json['referral_token']?.toString(),
      referralCode: json['referral_code']?.toString(),
      organizationId: json['organization_id'] is int
          ? json['organization_id'] as int
          : int.tryParse('${json['organization_id']}'),
      referrerDisplayName: json['referrer_display_name']?.toString(),
      organizationName: json['organization_name']?.toString(),
      organizationLogo: json['organization_logo']?.toString(),
    );
  }
}

class DugnadReferralState {
  DugnadReferralState._();
  static final DugnadReferralState instance = DugnadReferralState._();

  PendingDugnadReferral? get pending {
    final raw = prefGetString(prefPendingDugnadReferral);
    if (raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is Map<String, dynamic>) {
        final pending = PendingDugnadReferral.fromJson(map);
        if (pending.hasAttribution && pending.clubSlug.isNotEmpty) {
          return pending;
        }
      }
    } catch (_) {
      /* ignore */
    }
    return null;
  }

  Future<void> savePending(PendingDugnadReferral referral) async {
    await prefSetString(prefPendingDugnadReferral, jsonEncode(referral.toJson()));
  }

  Future<void> clearPending() async {
    await prefSetString(prefPendingDugnadReferral, '');
  }

  Future<void> saveFromValidation({
    required String clubSlug,
    String? referralToken,
    String? referralCode,
    int? organizationId,
    String? referrerDisplayName,
    String? organizationName,
    String? organizationLogo,
  }) async {
    await savePending(
      PendingDugnadReferral(
        clubSlug: clubSlug,
        referralToken: referralToken,
        referralCode: referralCode,
        organizationId: organizationId,
        referrerDisplayName: referrerDisplayName,
        organizationName: organizationName,
        organizationLogo: organizationLogo,
      ),
    );
  }
}
