// ignore_for_file: non_constant_identifier_names
import '../../../utils/utils.dart' show resolveSelectedLanguage;

// ── Customer Step 7: level 3, learned patterns and the push invitation ───────
//
// Copy for what the 12/21 Oct design has no words for: «Angre» on a merged
// line's receipt (design: `laIKurven` toast), the pattern rows' lines (design
// `mnLaert`), and the push invitation card for customers who were here
// before Ægil could notify them (Ægil spec §25 P4; not in the design, needs
// sign-off). `cus_*` facade names as the plan's other copy.
abstract final class CusLevel3Copy {
  static bool get _en => resolveSelectedLanguage() == 'en';
  static String _t(String no, String en) => _en ? en : no;

  static String get cus_angre => _t('Angre', 'Undo');
  static String get cus_angret => _t('Angret', 'Undone');
  static String get cus_angre_feil => _t('Fikk ikke angret. Prøv igjen.', 'Could not undo. Try again.');
  static String get cus_angret_toast => _t('Angret · linjen er tatt ut av kurven', 'Undone · the line is out of the basket');

  // Patterns (design `mnLaert`: «Bekreftet — styrer automatikk» / «… · kun forslag til du bekrefter»).
  static String get cus_monster_bekreftet => _t('Bekreftet — styrer automatikk', 'Confirmed — steers automation');
  static String cus_monster_forslag(String support) => _t('$support · kun forslag til du bekrefter', '$support · only a proposal until you confirm');
  static String get cus_monster_stemmer => _t('Stemmer', 'Correct');
  static String get cus_monster_avvist => _t('Greit, det glemmer jeg.', 'Fine, I will forget that.');
  static String get cus_monster_bekreftet_toast => _t('Bekreftet · Ægil bruker det', 'Confirmed · Ægil uses it');

  // The push invitation card.
  static String get cus_invit_kicker => _t('ÆGIL KAN SI FRA', 'ÆGIL CAN LET YOU KNOW');
  static String get cus_invit_tittel => _t('Vil du at Ægil sier fra?', 'Want Ægil to let you know?');
  static String get cus_invit_linje => _t('Ett varsel om dagen når noe er verdt det — et tilbud du liker, maten som pleier å komme. Aldri mellom 21 og 08.', 'One alert a day when something is worth it — an offer you like, the food you usually get. Never between 21:00 and 08:00.');
  static String get cus_invit_ja => _t('Ja takk', 'Yes please');
  static String get cus_invit_nei => _t('Nei takk', 'No thanks');
  static String get cus_invit_ja_toast => _t('Ægil sier fra når det er verdt det', 'Ægil will let you know when it is worth it');
  static String get cus_invit_nei_toast => _t('Greit · Ægil holder seg i ro', 'Fine · Ægil stays quiet');
}
