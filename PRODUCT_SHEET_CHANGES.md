# Product sheet changes (catalogue scraper, branch `agil-6-scraper-app`)

Base: `origin/agil-1` (`c683e09`). Backend counterpart: `agil-6-scraper` in Hare-AdminPanel (`SCRAPER_HANDOFF.md`). Every new API key is additive; with an older backend the sheets behave as before.

## Fixes

| Was | Now |
|---|---|
| `hasSizes` was true for every row: `sizeOptional` defaults a missing `size_optoinal` to 0 | `hasSizes` / `hasColours` only when the raw key is 0 (`ProductListItem.sizeOptionalRaw` / `colorOptionalRaw`); the sheet still needs sizes to exist |
| A variant without `stock` counted as in stock | `BergenVariant.stock` is `bool?`; null = unknown → «Lager ikke bekreftet», still choosable; `inStock` = not known sold out |
| `selection_type == 1` meant both "one choice" and "required" | `BergenOptionGroup.fromJson`: `optional_type` 0 = required, `minimum` / `maximum` bound the group |
| A failed read showed an empty sheet | `optionsResult` / `productDetailResult` return `ButikkResult`; the sheets show «Kunne ikke hente produktet.» + «Prøv igjen» (a 404 on the detail is not an error) |
| A deep-linked product in a fashion store opened the food sheet | opens the Klede sheet, like the Mote list |

## Klede sheet (clothing)

- Colour swatches from hex (`color_list[].hex`, the grid's `colour_hex`, or `colours[].hex`); text chip when no hex. A colour with every size sold out is faded.
- Sizes per chosen colour from the grid (`variants[]`: size, colour, `in_stock`, `stock_qty`, `price_delta_ore`): sold out = greyed and not tappable; switching colour drops a size sold out in the new one.
- «N igjen i din størrelse» when the chosen size has 1–3 left.
- «Lager oppdatert for 2 t siden» when `stock.mode` is `web` (web stock can lag).
- Swipe gallery with dots when `images[]` has more than one (our re-hosted copies).
- Price from `price_ore` / `was_price_ore`, size delta from the grid; formatted with `ButikkCopy.kr` («5 800 kr»).

## Produkt sheet (food)

- Groups enforce min / max / required: a full group refuses another choice with «Du kan velge opptil N»; «Legg til» with a short required group says «Velg {gruppe} først». Rule line «Velg minst N» / «Velg opptil N»; a required multi-choice group shows «Påkrevd» until chosen.
- Bounds come from the legacy group, else from `modifiers[]` of the same name.
- Negative deltas lower the live price; base price from `price_ore` when sent.
- Allergens from `allergen_codes[]` (EU-14, lower-case bokmål codes) in the user's language; else the old `allergens`.

## API fields read (all optional)

`get-topping-option`: `size_list[]/color_list[]` `.stock`, `.stock_qty`, `.hex`; `options_list[]` `.optional_type`, `.minimum`, `.maximum`; `variants[]`.
`ops.customer.product`: `price_ore`, `was_price_ore`, `variants[]`, `colours[]`, `stock {mode, updated_at}`, `images[]`, `modifiers[] {name, required, min, max, options[] {name, delta_ore}}`, `allergen_codes[]`.
Legacy lists: `size_optoinal`, `color_optional` (now always sent).

## Strings

New ARB keys `ops_butikk_scr_*` and `ops_butikk_allergen_*` (EN template + NB); other languages fall back to English. `ButikkCopy` wrappers beside the existing ones; `flutter gen-l10n` regenerated the committed localizations.

## Files

`lib/data/ops/butikk_models.dart`, `lib/networking/ops/ops_butikk_api.dart`, `lib/screens/bergen/butikk/{klede_sheet,produkt_sheet,produkt_launch,butikk_copy,butikk_screen}.dart`, `lib/screens/deliveryService/storeDetail/store_detail_dl.dart` (two raw getters), `lib/l10n/*`.

## Tests

`test/bergen/scraper_product_sheet_test.dart` (14) over real local-backend responses in `test/fixtures/scraper/` (Holzweiler jacket 782: web stock, 8 images, XXL sold out; Pita kebab 785: three required groups, +30 / +20 kr). The existing `test/bergen/butikk_test.dart` (27) still passes.

## Device check (Galaxy A15, 2026-10-16)

Debug `flutter run` against the scraper backend over the LAN (`dev_api_override` = the PC's LAN IP; harness `hjem_state.json` with store 875014, product 782 / 785, guest mode). Screenshots in `docs/scraper-shots/`:

| Screenshot | Result |
|---|---|
| `holzweiler_picker.png` | works (after fix 1): Dk. Brown swatch, XS–XL «På lager», «1 igjen i din størrelse» |
| `holzweiler_soldout.png` | fixed (fix 2): XXL «Utsolgt» faded and not tappable |
| `gallery.png` | works: swipe, image 2 of 8, dots |
| `stock_freshness.png` | works: «Lager oppdatert for 1 d siden» |
| `kebab_modifiers.png` | works: Ekstra kjøtt +30 kr, Ekstra ost +20 kr → «Legg til · 210 kr»; the folded header follows the sum. No negative delta in the test data |
| `allergens.png` | works: no allergens from the source → «Butikken har ikke lagt inn allergener ennå — spør butikken før du bestiller.» |
| `error_state.png` | works: server down → «Kunne ikke hente produktet.» + «Prøv igjen»; server back → retry loads the sizes |

Fixes (`ee6fa7a`, `klede_sheet.dart` and `produkt_sheet.dart` only):

1. Klede sheet overflowed the bottom by 128 px with a gallery, a long description and two rows of sizes: the content now scrolls under a height cap, quantity + «Legg i kurv» stay pinned.
2. A sold-out size looked like the others (it was only untappable): now faded like a sold-out swatch.
3. «Legg i kurv» / «Legg til» added the product while the options were still loading or after they failed, so without a size or required choices: both sheets now wait for the options, with the «Kunne ikke hente produktet.» toast when the read failed.

Seen, not changed (outside the sheet files):

- The shared API client's connect timeout is 3 min (`api_base_helper.dart`): on a network that drops instead of refusing, the error state takes up to 3 min; meanwhile the sheet shows no loading hint.
- «Ofte kjøpt med» under a kebab suggests jackets, and their thumbnails are blank: all imported test products sit in one category (backend gap: no source-category mapping).
- The store page's product cards for the Holzweiler jackets show no picture (restaurant body, not the sheets).
- `assets/json/` (gitignored `service_account.json`) must exist for `flutter run`; an empty folder is enough for the product sheets.

Tests after the fixes: `scraper_product_sheet_test.dart` + `butikk_test.dart` 41/41. Full `flutter test test/`: 735 passed, 4 failed, all outside this branch's files (`contract_names_test` ×2: `/bergen/butikkprofil` not reserved, `/bergen/bestilling` overflow in `hurtig_screen.dart`; `sok_test` nav X; `utforsk_test` Fjordfiske).
