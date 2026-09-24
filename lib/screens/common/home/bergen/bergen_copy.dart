import '../../../../utils/utils.dart';

/// Copy for the Bergen dashboard (`data-screen-label="Onboarding"`'s sibling
/// `erHjem` in `Design/Ærend Kunde Bergen.dc.html`). Norwegian is the
/// design's copy; English follows the NO/EN toggle, every other locale falls
/// back to Norwegian.
abstract final class BergenCopy {
  static bool get _en => resolveSelectedLanguage() == 'en';

  static String _t(String no, String en) => _en ? en : no;

  // ── Header ────────────────────────────────────────────────────────────────
  static String get deliverTo => _t('Leverer til', 'Deliver to');
  static String get chooseAddress => _t('Velg adresse', 'Choose address');
  static String get addressSheetTitle => _t('Hvor skal ærendet?', 'Where to?');
  static String get addressSheetLine => _t(
    'Butikker og priser følger adressen.',
    'Stores and prices follow the address.',
  );
  static String get currentLocation => _t('Her jeg er', 'Where I am');
  static String get newAddress => _t('Ny adresse', 'New address');
  static String get noAddresses =>
      _t('Ingen lagrede adresser ennå', 'No saved addresses yet');

  // ── Greeting (design `VAER[*].hilsen`) ────────────────────────────────────
  static String greeting(int hour, String? firstName) {
    final who = (firstName == null || firstName.isEmpty) ? '' : ', $firstName';
    if (hour < 5 || hour >= 23) return _t('God natt$who', 'Good night$who');
    if (hour < 10) return _t('God morgen$who', 'Good morning$who');
    if (hour < 17) return _t('God dag$who', 'Good day$who');
    return _t('God kveld$who', 'Good evening$who');
  }

  // ── Hero ──────────────────────────────────────────────────────────────────
  static String get aegilIntro => _t(
    'Jeg har funnet spesialtilbudene dine her i Vågen. Trykk på dem, så fisker jeg dem opp for deg.',
    "I've found your special offers here in Vågen. Tap them and I'll fish them up for you.",
  );
  static String get fjordfiske => 'Fjordfiske';
  static String get newInTown => _t('Ny i bydelen', 'New in town');
  static String get todaysCatch => _t('Dagens napp: +5', "Today's catch: +5");
  static String get inCart => _t('i kurven', 'in cart');
  static String get comingSoon =>
      _t('Kommer snart til Vågen', 'Coming soon to Vågen');

  // ── Napp-kort ─────────────────────────────────────────────────────────────
  static String get bergensk => 'Bergensk';
  static String get addToCart => _t('Legg til', 'Add');
  static String get notNow => _t('Ikke nå', 'Not now');
  static String get neverThis => _t('Aldri dette', 'Never this');
  static String get sunk => _t(
    'Sunket · dukker ikke opp igjen på 72 timer',
    "Sunk · won't surface again for 72 hours",
  );
  static String get aegilRemembers =>
      _t('Ægil husker det', 'Ægil will remember');
  static String get reasonOffer =>
      _t('Ægil fant dette til deg', 'Ægil found this for you');
  static String belowUsual(int kr) =>
      _t('$kr kr under vanlig', '$kr kr below usual');

  // ── Pull handle ───────────────────────────────────────────────────────────
  static String get pullToAsk =>
      _t('Dra ned for å spørre Ægil', 'Pull down to ask Ægil');
  static String get pullMore => _t('Dra litt lenger …', 'Pull a little more …');
  static String get releaseToOpen =>
      _t('Slipp — Ægil åpner', 'Release — Ægil opens');
  static String get allStores =>
      _t('Alle butikker og varer', 'All stores and items');

  // ── Kategorirad ───────────────────────────────────────────────────────────
  static String openNow(int n) => _t('$n åpne nå', '$n open now');
  static String get opensLater => _t('Åpner senere', 'Opens later');
  static String get newTag => _t('Ny', 'New');

  // ── Forundringspose ───────────────────────────────────────────────────────
  static String get surpriseBag => 'FORUNDRINGSPOSE';
  static String get surpriseTitle =>
      _t('Det som er igjen i kveld', "What's left tonight");
  static String surpriseLeft(int n) =>
      _t('$n igjen i kveld', '$n left tonight');
  static String surpriseValue(int kr) =>
      _t('verdi minst $kr kr', 'worth at least $kr kr');
  static String get surpriseUnder =>
      _t('Sandviken Bakeri · hentes 16–18', 'Sandviken Bakeri · pick up 16–18');
  static String get secureOne => _t('Sikre en', 'Grab one');

  // ── Butikker ──────────────────────────────────────────────────────────────
  static String storesIn(String district) =>
      _t('Butikker ${_prep(district)} $district', 'Stores in $district');
  static String _prep(String d) =>
      (d == 'Bryggen' || d == 'Fisketorget' || d == 'Torgallmenningen')
      ? 'på'
      : 'i';
  static String get seeAll => _t('Se alle', 'See all');
  static String get open => _t('Åpen', 'Open');
  static String get closed => _t('Stengt', 'Closed');
  static String get free => _t('Gratis', 'Free');
  static String minutes(int m) => '$m min';
  static String get video => 'VIDEO';
  static String get noStoresYet =>
      _t('Ingen butikker her ennå', 'No stores here yet');

  // ── Utforsk-kort ──────────────────────────────────────────────────────────
  static String get exploreTitle =>
      _t('Fjordfiske, poser og nytt', 'Fjordfiske, bags and news');
  static String get exploreLine => _t(
    '2 nye innlegg fra butikker du følger',
    '2 new posts from stores you follow',
  );
  static String get openBtn => _t('Åpne', 'Open');

  // ── Populært ──────────────────────────────────────────────────────────────
  static String get popularTonight => _t('Populært i kveld', 'Popular tonight');
  static String get bergenhus => 'Bergenhus';
  static String get noProductsYet =>
      _t('Ingen varer her ennå', 'No items here yet');

  // ── Under kaien ───────────────────────────────────────────────────────────
  static String get underQuay => _t('UNDER KAIEN', 'UNDER THE QUAY');
  static String get underQuayLine => _t(
    'Psst — jeg fant tre ting som lå gjemt her.',
    'Psst — I found three things hidden down here.',
  );
  static String get offer => _t('TILBUD', 'OFFER');
  static String get bag => _t('POSE', 'BAG');
  static String get shipping => _t('FRAKT', 'SHIPPING');
  static String get before => _t('før', 'was');
  static String get openBag => _t('Åpne posen', 'Open the bag');
  static String get freeDelivery => _t('Gratis levering', 'Free delivery');
  static String get overTonight => _t('i kveld', 'tonight');
  static String get left2 => _t('2 igjen', '2 left');
  static String get tonight => _t('I kveld', 'Tonight');
  static String get worth => _t('verdi', 'worth');

  // ── Nav ───────────────────────────────────────────────────────────────────
  static String get navHome => _t('Hjem', 'Home');
  static String get navExplore => _t('Utforsk', 'Explore');
  static String get navCart => _t('Kurv', 'Cart');
  static String get navMe => _t('Meg', 'Me');
  static String get searchHint =>
      _t('Søk eller si hva du trenger', 'Search or say what you need');
  static String get searchTip => _t(
    'Søk i Bergen — butikker, varer, bydeler.',
    'Search Bergen — stores, items, districts.',
  );
  static String cartItems(int n) =>
      n == 1 ? _t('1 vare', '1 item') : _t('$n varer', '$n items');

  // ── Toasts ────────────────────────────────────────────────────────────────
  static String addedToCart(String name) =>
      _t('$name er lagt i kurven', '$name added to your cart');
  static String get trackOrder =>
      _t('Bestillingen din er på vei', 'Your order is on its way');
}
