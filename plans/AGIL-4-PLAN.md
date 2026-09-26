# AGIL-4 — Meg-fanen til design, og Points-hullene bak den

Branch `agil-4` in both repos, cut from `origin/agil-1` after merge day
(Hare-AdminPanel `afeb3e7`, Aerend-app `01b48b8`). agil-1 keeps working on the
feed screens; agil-4 owns what agil-3 owned in the app (`lib/screens/bergen/
{meg,poeng,aegil}/`, `lib/data/{points,aegil}/`, `lib/screens/{points,aegil}/`)
and the Points / Agent customer API in the admin panel (`routes/api_points.php`,
`routes/api_agent.php`, `app/Points`, `app/Http/Controllers/{Points,Agent}`,
`app/model/{Pts*,Agent*,CustomerPref}`). Everything else is append-only per
AGIL-CONTRACT §2.4, and `app/Services/Ops`, `api_ops.php`, `lib/l10n`,
`home_main_v1.dart` are never touched. No pushes; the user pushes.

Design: `designs/21des/Ærend Kunde Bergen.dc.html`, block `meg` ≈L5912–6124
(`Poeng` ≈L5978, `Meg-rader` ≈L6031) and the Ark sheets in `kArkVals`.

## Decisions

- **Tier names are the design's:** Bronse / Sølv / Gull / Platina at
  0 / 1000 / 3000 / 6000 (`config/points.php`), replacing the AGIL-2 mountains
  (0/1000/3000/8000). One config change; the app renders whatever `points/me`
  sends in `tiers[]`.

## Phase 1 — Backend gaps (Hare-AdminPanel) — done, `8d72a84`

- [x] `points/me` carries `tiers[]` (index, name, threshold) for the ladder.
- [x] `POST points/mission/accept` ("Godta"); `mission.accepted` / `accepted_at`.
- [x] `POST points/league/name` (`display_name`, `visibility` alle|bydel|skjult);
      standings rows carry `name` ("Klatrer N" when hidden or unnamed); the
      viewer always sees their own; `league.profile`; opt-in accepts both.
- [x] `GET/POST points/me/prefs`: `always_code`, `mark_notifications_seen`, plus
      `counts.notifications_unseen` and `counts.favourites`.
- [x] `GET/POST/DELETE agent/me/occasions` + `agent:occasion-reminders` (one
      AgentAction per occasion, `lead_days` before, idempotent per year;
      scheduled 08:05).
- [x] `GET /verv/{code}` page so the referral link no longer 404s.
- [x] `favourite-store-lists` returns `total`.
- [x] Registry `tests/fixtures/contract/names.agil4.json`; `MegTabTest` (6 tests);
      `TierTest` / `PointsApiTest` follow the new names.

## Phase 2 — The Meg tab (Aerend-app) — done

- [x] `meg_hero.dart` — the scene (Hjem mountains + Bryggen painter) with Ægil
      and the goal bubble (`maalBoble`).
- [x] Header: "{fornavn} fra Møhlenpris", "Møhlenpris · Bergenhus",
      "Premie: gratis levering" (when a delivery gift claim is open),
      Gullbilletten gold card with Del (copies the link), the settings button.
- [x] `meg_nivaa_card.dart` — medal, DITT NIVÅ, "N poeng til …", the four-rung
      ladder from `tiers[]`, POENG Å BRUKE + "Opptjent i alt", pending line,
      goal bar with %, Hent premien when reached, Premiehylla, Slik får du poeng.
- [x] Meg-rader: Nivå (→ Nivå Ark), Fløyen-ligaen (plass / Bli med),
      UKENS OPPDRAG with Godta / Ikke dette and the "0 av 1" status,
      Gullbilletten with the code.
- [x] Innstillinger-rader: Anledninger (sheet: list, Fjern, Legg til with date
      picker), Ukeshandel (shopping list → Ukens kurv / nivå 4 sheet),
      Så mye kan Ægil gjøre (level, `AegilSettingsPanel` sheet),
      Krev alltid kode ved levering (Ark → Slå på/av → prefs), Adresser
      (first address line → ManageAddress), Betaling (Vipps · card last4 →
      ManageCard), Varsler (unseen count → panel, marks seen), Navn i ligaen
      (name shape + visibility sheet → opt-in + name), Språk (current → picker),
      Favoritter (count), Nytt fra butikkene (→ /bergen/utforsk?tab=feed),
      Hjelp og kontakt (Spør Ægil / Snakk med et menneske / Om Ægil).
- [x] `meg_copy_a4.dart` (`a4_meg_*`), `meg_sheets.dart`, data-layer additions
      (`TierStep`, `CustomerPrefs`, `Mission.accepted`, `LeagueStanding.name`,
      `League.displayName/visibility`, `Occasion`; `PointsAppApi.acceptMission /
      setLeagueName / prefs / updatePrefs`; `AegilAppApi.occasions / addOccasion /
      removeOccasion / shoppingList`); fakes extended.
- [x] Tests `test/meg/a4_meg_tab_test.dart` (9), incl. a 360-px overflow guard.

**Design ledger**

| Block | Design | Differences accepted / to fix |
|---|---|---|
| Hero | ≈L5912 | Brann stadion is not exported; the Hjem mountains + Bryggen skyline stand in. Ægil pose `popup.png`. |
| Header | ≈L5942 | Bydel/region are copy constants (Møhlenpris · Bergenhus) until agil-1 exposes the zone name. |
| Poeng | ≈L5978 | Medals are drawn (radial metal + Æ) rather than the SVG coin; "Opptjent i alt" uses `lifetime`. |
| Meg-rader | ≈L6031 | Ægil sparte deg (Tillitsregnskap) row lives on Det Ægil vet; not repeated here. |
| Krev alltid kode | `kodeInnst` | Shows "Av · kreves over 300 kr" per design; ops hardcodes 1500 kr and does not yet read the preference (Ask of agil-1). |
| Betaling | `betaling` | "Vipps · Visa •• 4471" from the card list; no saved-Vipps method exists. |
| Nytt fra butikkene | — | No unread count (belongs to the feed service). |

## Asks of agil-1 (not done here)

- Read `customer_prefs.always_code` as `customer_requested_code` when
  `DeliveryProofService::assignProof` runs at placement; move the 1500 kr
  constant to a policy key (`proof.value_threshold_ore`, 30000 if 300 kr).
- Zone / bydel name for the Meg header; feed unread count for "Nytt fra
  butikkene"; `MediaQuery.disableAnimations` from the Konto preference.
- Wire the Hjem to `refreshMensDuVarBorte()` / `refreshAegilFindCount()`.

## Deferred

- Weekly basket ("Ukens kurv", nivå 4 Fast bestilling) — needs the Vipps
  recurring agreement and a basket model; the sheet explains it.
- Navn i ligaen inside the Liga screen's standings (the table already prints
  `LeagueStanding.label`).
