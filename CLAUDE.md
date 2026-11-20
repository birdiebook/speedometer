# Speedometer — arbetssätt

Speedometer är en iPhone-app för cykel: en hastighetsmätare med visare som läser telefonens GPS och visar
fart, sträcka, tid och snitt. Inget konto, ingen reklam, inget nät. Hemskärmen visar Speedometer; namnet i
App Store är "speedometer - minimalist" (BESLUT B2). Etapperna står i [PLAN.md](PLAN.md).

## Regler — läs först

- **Repot är publikt.** Ingen e-postadress, ingen lokal sökväg, ingen nyckel och inget personnamn i något som
  committas: kod, dokument, commit-meddelanden. Hemligheter ligger bara i repots Actions-hemligheter.
- **Appen skickar ingenting** (BESLUT B3). Ingen nätverkskod, ingen analys, inga tredjepartsbibliotek. Platsen
  läses med "When In Use": medan appen är öppen, och i bakgrunden under en tur (BESLUT B17). Det som sparas,
  turens tal och spåret för den pågående turen (BESLUT B16), sparas bara på telefonen. Det är det som låter App Store visa "Data Not Collected".
- **Appen är på engelska** (BESLUT B8). Dokumenten här är på svenska; kod och kommentarer på engelska.
- **Extremt enkel** (BESLUT B5, B6, B14): en skärm, inga knappar, ingen inställning; det som kommer till ligger
  bakom menyn, som Trail (BESLUT B16). En ny knapp, en ny skärm eller ett nytt tal kräver ett nytt beslut i
  `docs/BESLUT.md`, inte bara kod.

## Koden

- **Logiken bor i `SpeedKit/`** (Swift-paket, bara Foundation), så att den prövas på Linux: turen, enheterna,
  skalans geometri och formateringen. Testerna bär påhittade GPS-prov.
- **`App/` är ett tunt SwiftUI-skal**: platsen (`CLLocationManager`), mätaren, håll-in och att skärmen hålls tänd.
  Vyerna tar sina värden som argument, så att de går att rita med påhittade värden.
- **Xcode-projektet genereras ur `project.yml`** med XcodeGen och är gitignorerat, liksom `App/Info.plist`.
- **Beslut i `docs/BESLUT.md`, konstanter i `docs/METOD.md`.** Koden hänvisar med `// BESLUT B5` och
  `// METOD M3`. En konstant utan rad i METOD är en bugg.

## Bygget

- **GitHub Actions är gratis här, även macOS** (BESLUT B4: repot är publikt). Codemagic används inte.
- `test.yml` kör SpeedKits tester på Linux (`swift:6.1`, release med `-enable-testing`) och `swiftc -parse` över
  `App/`. `app.yml` kompilerar appen för simulatorn på macOS. Båda lägger sitt utfall på grenen `ci-resultat`:

      git fetch origin ci-resultat
      git show origin/ci-resultat:resultat/<sha>.txt       # testerna
      git show origin/ci-resultat:resultat/<sha>-app.txt   # appens bygge

  Push och läs resultatet innan du tror att Swift-kod fungerar.
- **TestFlight** byggs av `testflight.yml`, bara för hand från `main` och bara efter ägarens ja: varje bygge är
  en leverans. Det kräver grönt för samma commit.
- Arbetssättet som gäller alla appar (bygget, testerna, datan) bor i det privata repot `birdiebook/arbetssatt`;
  `tools/arbetssatt/` är en kopia därifrån.
