# Plan

Bandet: **[E1 pågår]** · E2 · E3

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
- Appikonen.
- `testflight.yml` grönt och bygget på telefonen. Provtur på cykeln; konstanterna i METOD M2–M3 tunas.

## E3 — Publiceringen

- Namnet i App Store (BESLUT B2), skärmbilder, integritetsetiketten "Data Not Collected", granskningen.

## Senare, inte beslutat

- Farten på låsskärmen och i Dynamic Island (Live Activity), som kräver plats i bakgrunden (BESLUT B10).
- Samma teknik i Idunn för puls mot fart (BESLUT B1).
