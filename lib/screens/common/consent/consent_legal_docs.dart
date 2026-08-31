// In-gate legal copy — ports `DG_LEGAL_DOCS` from
// `DesignNew/dugnad/legal-support.jsx`. The entity name is Ærend;
// the interim "Reen Dugnad" rebrand was reverted in Chunk 3b.

class ConsentLegalBlock {
  const ConsentLegalBlock({this.h, this.p, this.list});

  final String? h;
  final String? p;
  final List<String>? list;
}

class ConsentLegalDoc {
  const ConsentLegalDoc({
    required this.id,
    required this.title,
    required this.updated,
    required this.blocks,
  });

  final String id;
  final String title;
  final String updated;
  final List<ConsentLegalBlock> blocks;
}

const ConsentLegalDoc kConsentTermsDoc = ConsentLegalDoc(
  id: 'terms',
  title: 'Vilkår for bruk',
  updated: 'Oppdatert 2. april 2026',
  blocks: [
    ConsentLegalBlock(
      h: 'Velkommen til Ærend!',
      p: 'Disse vilkårene beskriver reglene for bruk av Ærends app og leveringstjenester.',
    ),
    ConsentLegalBlock(
      p: 'Ved å bruke appen godtar du disse vilkårene. Er du uenig i noe av det som står her, skal du ikke bruke Ærend.',
    ),
    ConsentLegalBlock(
      h: 'Lisens',
      p: 'Med mindre annet er oppgitt eier Ærend og våre lisensgivere alle immaterielle rettigheter til innholdet i appen. Du kan bruke innholdet til eget personlig bruk, innenfor rammene av disse vilkårene.',
    ),
    ConsentLegalBlock(
      h: 'Du kan ikke',
      list: [
        'Publisere Ærends innhold på nytt',
        'Selge, leie ut eller viderelisensiere innholdet',
        'Kopiere eller duplisere innholdet',
        'Distribuere innholdet videre',
      ],
    ),
    ConsentLegalBlock(
      h: 'Innhold fra brukere',
      p: 'Deler av appen lar brukere legge ut meninger og informasjon. Ærend forhåndsgodkjenner ikke slikt innhold, og det gjenspeiler ikke Ærends syn.',
    ),
    ConsentLegalBlock(
      h: 'Dugnad og klubbandel',
      p: 'Andelen som går til klubben trekkes fra butikkens margin — du betaler aldri mer for å støtte laget ditt.',
    ),
  ],
);

const ConsentLegalDoc kConsentPrivacyDoc = ConsentLegalDoc(
  id: 'privacy',
  title: 'Personvern',
  updated: 'Oppdatert 2. april 2026',
  blocks: [
    ConsentLegalBlock(
      h: 'Hva vi lagrer',
      p: 'Navn, telefonnummer, e-post og leveringsadresse — det vi trenger for å levere bestillingen din og gi klubben din andelen.',
    ),
    ConsentLegalBlock(
      h: 'Hva vi aldri gjør',
      p: 'Vi selger aldri dataene dine. Klubben ser aldri hva du har kjøpt — bare den samlede summen laget har fått.',
    ),
    ConsentLegalBlock(
      h: 'Synlighet på tabellene',
      p: 'Du velger selv om navnet ditt vises på lagtabellene. Du kan bruke visningsnavn eller være helt anonym.',
    ),
    ConsentLegalBlock(
      h: 'Dine rettigheter',
      p: 'Du kan når som helst be om innsyn i, retting av eller sletting av dataene dine fra Min konto.',
    ),
  ],
);

ConsentLegalDoc consentLegalDocById(String id) {
  if (id == kConsentPrivacyDoc.id) return kConsentPrivacyDoc;
  return kConsentTermsDoc;
}
