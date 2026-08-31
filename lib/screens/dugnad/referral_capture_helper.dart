import '../../utils/utils.dart';
import 'dugnad_referral_state.dart';
import 'dugnad_repo.dart';
import 'widgets/dugnad_points_pop.dart';

/// Capture a pending deep-link/manual referral after phone verification.
Future<bool> capturePendingDugnadReferralIfNeeded() async {
  final pending = DugnadReferralState.instance.pending;
  if (pending == null || !isLoggedIn()) return false;

  final repo = DugnadRepo();
  final record = await repo.captureReferral(
    clubSlug: pending.clubSlug,
    referralToken: pending.referralToken,
    referralCode: pending.referralCode,
    captureSource: pending.referralToken != null ? 'link' : 'manual',
  );

  if (record != null) {
    await DugnadReferralState.instance.clearPending();
    final joinPoints = prefGetInt(prefDugnadReferralJoinPoints);
    if (joinPoints > 0 && !prefGetBool(prefShowDugnadWelcomeAfterOnboarding)) {
      DugnadPointsPop.award(joinPoints);
      await prefSetInt(prefDugnadReferralJoinPoints, 0);
    }
    return true;
  }
  return false;
}
