import '../../../utils/shared_pref_utill.dart';

/// Points plan Step 7: Fjordløpet's interface texts (game spec §15), bokmål and English. The rules page itself comes
/// from the panel (`game.vilkaar`, in `/game/state`).
abstract final class LopetCopy {
  static bool get _en => resolveSelectedLanguage() == 'en';
  static String _t(String no, String en) => _en ? en : no;

  static String get navn => 'Fjordløpet';
  static String get mensDuVenter => _t('Fjordløpet · mens du venter', 'Fjordløpet · while you wait');
  static String seilaserIgjen(int n) => n == 1 ? _t('1 seilas igjen', '1 run left') : _t('$n seilaser igjen', '$n runs left');
  static String seilaser(int n) => _t('Fjordløpet · $n seilaser', 'Fjordløpet · $n runs');
  static String get hjemKlar => _t('Ægil er klar til å seile', 'Ægil is ready to sail');

  static String get ukensLed => _t('Ukens led', "This week's course");
  static String get settSeil => _t('Sett seil', 'Set sail');
  static String get dinBeste => _t('Din beste denne uken', 'Your best this week');
  static String get ukensBeste => _t('Ukens beste', 'Best this week');
  static String get sjokort => _t('Sjøkortet', 'The chart');
  static String get takeUkjent => _t('Resten ligger i tåka til du har seilt dit.', 'The rest lies in fog until you have sailed there.');
  static String get vest => _t('Redningsvest · én per bestilling', 'Life vest · one per order');
  static String get vilkaar => _t('Vilkår for Fjordløpet', 'Fjordløpet rules');
  static String get lyd => _t('Lyd', 'Sound');

  static List<String> get porter => [_t('Bøye 1', 'Buoy 1'), _t('Bøye 2', 'Buoy 2'), _t('Bryggen', 'The quay')];
  static String omMeter(String port, int m) => _t('$port om $m m', '$port in $m m');

  static String get pause => _t('Pause', 'Paused');
  static String get vedDora => _t('Budet er ved døra', 'Your courier is at the door');
  static String get trengerDeg => _t('Ærendet ditt trenger deg', 'Your order needs you');
  static String get fortsett => _t('Fortsett', 'Resume');
  static String fortsettOm(int n) => _t('Fortsett om $n', 'Resuming in $n');
  static String get tilSporing => _t('Til sporing', 'To tracking');

  static String get over => _t('SEILASEN ER OVER', 'THE RUN IS OVER');
  static String fraRekorden(int m) => _t('$m m fra rekorden din', '$m m from your best');
  static String get nyRekord => _t('Ny rekord denne uken', 'New best this week');
  static String poengVedLevering(int p) => _t('+$p poeng når ærendet er levert', '+$p points when your order is delivered');
  static String seilIgjen(int n) => _t('Seil igjen · $n igjen', 'Sail again · $n left');
  static String get nesteSeilas => _t('Neste seilas ved neste bestilling', 'Your next run comes with your next order');
  static String get snartFremme => _t('Budet er snart fremme', 'Your courier is almost there');
  static String get forsinket => _t('Ærendet er forsinket. Du får en ekstra seilas.', 'Your order is late. You get an extra run.');
  static String get vestTok => _t('Redningsvesten tok støyten', 'Your life vest took the hit');
  static String get stengt => _t('Fjordløpet er åpent mens et ærend er på vei.', 'Fjordløpet is open while an order is on its way.');
  static String minUnna(int m) => _t('Budet er $m min unna', 'Courier $m min away');
}
