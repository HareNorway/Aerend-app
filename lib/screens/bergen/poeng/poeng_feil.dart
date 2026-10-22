// ignore_for_file: non_constant_identifier_names
import '../../../utils/utils.dart';

/// Customer plan Step 12: the points layer's named 422s (Points spec §4–§7;
/// `PrizeService`, `MissionService`, `LeagueService`, `GoalService`) in the
/// customer's words. Every sheet that claims, cancels, accepts, declines,
/// names or sets a goal shows [tekst] instead of the raw code; an unknown
/// code (or a transport failure) falls back to the caller's own line.
abstract final class CusPoengFeil {
  static bool get _en => resolveSelectedLanguage() == 'en';
  static String _t(String no, String en) => _en ? en : no;

  static const Set<String> koder = {
    'PRIZE_TIER_LOCKED', 'PRIZE_INSUFFICIENT_POINTS', 'PRIZE_SOLD_OUT', 'PRIZE_USER_CAP', 'PRIZE_INACTIVE', 'PRIZE_NOT_FOUND',
    'CLAIM_CANCEL_WINDOW_CLOSED', 'CLAIM_ALREADY_CANCELLED', 'CLAIM_NOT_FOUND', 'CLAIM_NOT_REDEEMABLE',
    'MISSION_DECLINE_LIMIT', 'MISSION_ALREADY_ACTIVE', 'MISSION_NONE_ACTIVE', 'MISSION_NO_TEMPLATE',
    'LEAGUE_NAME_INVALID', 'LEAGUE_MONTH_CLOSED', 'LEAGUE_NOT_OPTED_IN', 'LEAGUE_VISIBILITY_INVALID',
    'GOAL_PRIZE_NOT_FOUND', 'GOAL_TIER_UNKNOWN', 'GOAL_KIND_UNKNOWN',
  };

  /// True when [code] is one the backend names (not a transport message).
  static bool kjent(String? code) => code != null && koder.contains(code);

  /// The line for [code]; [ellers] when the code is unknown or null.
  static String tekst(String? code, {required String ellers}) => switch (code) {
    'PRIZE_TIER_LOCKED' => _t('Denne premien åpner på et høyere nivå. Nivået ditt kommer av poeng du har tjent.', 'This prize opens at a higher tier. Your tier comes from points you have earned.'),
    'PRIZE_INSUFFICIENT_POINTS' => _t('Du har ikke nok poeng ennå. Sett den som mål, så følger Ægil deg dit.', 'Not enough points yet. Set it as your goal and Ægil will follow you there.'),
    'PRIZE_SOLD_OUT' => _t('Denne premien er utsolgt. Hylla fylles på igjen.', 'This prize is sold out. The shelf is restocked.'),
    'PRIZE_USER_CAP' => _t('Du har hentet denne så mange ganger som den kan hentes.', 'You have claimed this one as many times as it allows.'),
    'PRIZE_INACTIVE' || 'PRIZE_NOT_FOUND' => _t('Denne premien er tatt av hylla.', 'This prize has left the shelf.'),
    'CLAIM_CANCEL_WINDOW_CLOSED' => _t('Fristen for å angre har gått ut · premien er på vei.', 'The window to undo has closed · the prize is on its way.'),
    'CLAIM_ALREADY_CANCELLED' => _t('Denne er allerede avbrutt · poengene er tilbake.', 'This one is already cancelled · the points are back.'),
    'CLAIM_NOT_FOUND' || 'CLAIM_NOT_REDEEMABLE' => _t('Fant ikke denne premien lenger.', 'Could not find this prize any more.'),
    'MISSION_DECLINE_LIMIT' => _t('Ett nei i uka · nytt oppdrag kommer mandag.', 'One pass a week · a new mission comes Monday.'),
    'MISSION_ALREADY_ACTIVE' => _t('Du har allerede et oppdrag denne uka.', 'You already have a mission this week.'),
    'MISSION_NONE_ACTIVE' || 'MISSION_NO_TEMPLATE' => _t('Ingen oppdrag akkurat nå · Ægil finner et til deg mandag.', 'No mission right now · Ægil finds one for you Monday.'),
    'LEAGUE_NAME_INVALID' => _t('Det navnet går ikke · prøv et annet, eller vær anonym.', 'That name will not do · try another, or stay anonymous.'),
    'LEAGUE_MONTH_CLOSED' => _t('Måneden er gjort opp · bli med i neste.', 'The month is settled · join the next one.'),
    'LEAGUE_NOT_OPTED_IN' => _t('Du er ikke med i ligaen ennå · bli med først.', 'You are not in the league yet · join first.'),
    'LEAGUE_VISIBILITY_INVALID' => _t('Den synligheten finnes ikke.', 'That visibility does not exist.'),
    'GOAL_PRIZE_NOT_FOUND' || 'GOAL_TIER_UNKNOWN' || 'GOAL_KIND_UNKNOWN' => _t('Det målet finnes ikke lenger · velg et annet på hylla.', 'That goal no longer exists · pick another on the shelf.'),
    _ => ellers,
  };
}
