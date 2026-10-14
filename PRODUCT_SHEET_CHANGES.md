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
