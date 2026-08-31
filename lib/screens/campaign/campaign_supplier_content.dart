/// Jens Eide supplier detail copy — mirrors Reen-web-portal `messages/no.json` & `en.json`.
class CampaignSupplierContent {
  CampaignSupplierContent._();

  static bool isNorwegian(String languageCode) =>
      languageCode == 'no' || languageCode == 'nb' || languageCode == 'nn';

  static String historyTitle(String languageCode) =>
      isNorwegian(languageCode) ? 'Historie' : 'History';

  static String historyBody(String languageCode) => isNorwegian(languageCode)
      ? 'Jens Eide AS er en familieeid bedrift etablert i 1946 i Lillesand, bygget på ekte håndverk, pågangsmot og en sterk lokal forankring. Selskapet har utviklet seg fra en liten slakterbutikk med enkle fasiliteter til en moderne virksomhet med full verdikjede – eget slakteri, nedskjæring, produksjon og distribusjon. Gjennom generasjoner har kunnskap og tradisjoner blitt videreført, samtidig som bedriften har investert i moderne anlegg og teknologi. I dag produserer Jens Eide AS et bredt spekter av kvalitetsprodukter innen pølser, pålegg og spekemat, med fokus på dyrevelferd, lokale råvarer og ærlig mat laget fra bunnen av.'
      : 'Jens Eide AS is a family-owned company established in 1946 in Lillesand, built on real craftsmanship, drive and strong local roots. The company has grown from a small butcher shop with simple facilities to a modern business with a full value chain – its own slaughterhouse, cutting, production and distribution. Across generations, knowledge and traditions have been passed on while the company has invested in modern facilities and technology. Today Jens Eide AS produces a wide range of quality products in sausages, deli meats and cured meats, with a focus on animal welfare, local ingredients and honest food made from scratch.';

  static String spekematTitle(String languageCode) =>
      isNorwegian(languageCode) ? 'Spekemat' : 'Cured meats';

  static String spekematBody(String languageCode) => isNorwegian(languageCode)
      ? 'Jens Eide AS produserer spekemat etter italienske prinsipper, der kvaliteten på råvarene står i sentrum og bearbeidingen holdes på et minimum. Produktene lages med grovkvernet kjøtt, nøye utvalgte krydder, salt og sukker, og inneholder minst mulig tilsetningsstoffer. Spekepølsene stoppes og tørkes tradisjonelt på stabbur i seks til åtte uker, noe som gir en rik og moden smak. Sortimentet inkluderer blant annet Rødvinssnabb, Salami Bacon Snabb, salami med grønn pepper, Chorizo Snabb samt varianter med elg og hjort. Resultatet er rene, ekte og smakfulle produkter som egner seg like godt til hverdags som til tapas og spekefat. For best mulig smaksopplevelse anbefales det å servere spekematen temperert.'
      : 'Jens Eide AS produces cured meats following Italian principles, where raw material quality is central and processing is kept to a minimum. Products are made with coarsely ground meat, carefully selected spices, salt and sugar, and contain as few additives as possible. The cured sausages are stuffed and dried traditionally in a stabbur (drying shed) for six to eight weeks, giving a rich, mature flavour. The range includes among others Rødvinssnabb, Salami Bacon Snabb, salami with green pepper, Chorizo Snabb as well as variants with elk and deer. The result is clean, authentic and flavourful products suited to everyday meals as well as tapas and charcuterie boards. For the best taste experience, serve the cured meats at room temperature.';
}
