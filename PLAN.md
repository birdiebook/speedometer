# Plan

Bandet: E1 klar · **[E2 pågår]** · E3

## E1 — Grunden

Logiken i `SpeedKit/` med tester, appen i `App/` enligt skissen, och CI.

Klart när:
- `test.yml` är GRÖNT på `ci-resultat` för senaste commit: turen, autopausen, sträckan, max, enheterna, skalans
  vinklar och formateringen prövas med påhittade prov (METOD M1–M8).
- `app.yml` är GRÖNT: appen kompilerar för simulatorn.
- Appen har de tre lägena (riding, paused, finding GPS), håll-in nollställer, skärmen hålls tänd och turen
  överlever att appen stängs (BESLUT B5, B6, B10).

## E2 — Till telefonen

- Ägaren: appen i App Store Connect (bundle-id `se.birdiebook.speedometer`) och hemligheterna i repots Actions.
- Appikonen (klar, BESLUT B12).
- `testflight.yml` grönt (BESLUT B13): bygge 1 uppladdat 2026-11-17, första försöket; bygge 2 samma kväll med rättelsen i METOD M1 och M3 (position utan fart
  är stillastående). Kvar: provtur på cykeln.
- **Bygge 3** uppladdat 2026-11-20 efter ägarens ja: 15 s innan finding GPS och paus efter 3 s utan fart även utan
  positioner (METOD M3), ingen PAUSED före första turen (BESLUT B15), och Trail (BESLUT B16): menyn (B14), spåret
  (METOD M9) och sidan (METOD M10, FORM.md). Kvar: provtur på cykeln. Tuna konstanterna i METOD M2–M3 och M9, och
  pröva att stänga Trail med ett svep nedåt (ett svep som börjar på spåret visar farten i stället).

## E3 — Publiceringen

- Skärmbilder, integritetsetiketten "Data Not Collected", granskningen.

## Senare, inte beslutat

- Farten på låsskärmen och i Dynamic Island (Live Activity), som kräver plats i bakgrunden (BESLUT B10).
- Samma teknik i Idunn för puls mot fart (BESLUT B1).
- Uppläsning av ny toppfart (ägarens idé 2026-11-17). Telefonens egen röst, inget nät. Läser toppen när farten
  slutat stiga i ett par sekunder ("Top speed 42"), högst var 30:e sekund och bara när max ökat minst 1 km/h sedan
  förra uppläsningen. Musik sänks medan rösten talar. Av från början; slås på i menyn (BESLUT B14). Byggs tillsammans med låsskärmen, eftersom båda kräver
  plats i bakgrunden. Efter första provturen.
