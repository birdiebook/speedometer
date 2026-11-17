# Beslut

Varje beslut som formar appen: valt, bortvalt, kostnad och när det omprövas. Koden hänvisar med `// BESLUT Bn`.

## B1 — Egen app, ingen koppling till Idunn

Valt: en egen app i ett eget repo. Analysen av puls mot fart byggs senare in i Idunn, med samma teknik.
Bortvalt: att koppla ihop apparna (App Group eller HealthKit). Skäl: Speedometer rör ingen hälsodata och kan
därför stå som "Data Not Collected" i App Store; en koppling vore en ny väg för hälsodata.
Omprövas: om Idunn behöver något som bara den här appen har.

## B2 — Arbetsnamnet Speedometer

Valt: repot heter Speedometer och hemskärmen visar "Speedometer". Namnet i App Store är
"speedometer - minimalist" (ägaren 2026-11-17, när appen skapades i App Store Connect); det går att byta fram till
första publiceringen.

## B3 — Inget nät, inget konto, ingen reklam

Valt: appen har ingen nätverkskod, ingen analys och inga tredjepartsbibliotek. Platsen läses bara medan appen är
öppen ("When In Use"). Inget spår sparas, bara turens tal (sträcka, tid, max). Skäl: det är hela löftet, och det
ger "Data Not Collected" i App Store.

## B4 — Actions i det publika repot, ingen Codemagic

Valt: tester, appens bygge och TestFlight körs i repots GitHub Actions, som är gratis för publika repon även på
macOS. Bortvalt: Codemagic, vars 500 minuter i månaden delas med de andra apparna. Kostnad: koden är publik.

## B5 — Formen: en visare

Valt: en skärm med en visartavla (skissens variant A). Skalan går 0–60 km/h, eller 0–40 mph (BESLUT B7), över
240°. En orange markering stannar vid turens högsta fart, så att max inte behöver ett eget fält. Under tavlan:
distance, time och avg. Lägena är riding, paused och finding GPS. Appen följer telefonens ljusa och mörka läge.
Bortvalt: en båge (variant B) och en rullande skala (variant C). Skäl: visaren är det som ger känslan av en bil,
och ägaren valde den.

## B6 — Inga knappar

Valt: turen startar när du rullar och pausar när du står still (METOD M3). Håll in var som helst på skärmen för att
nollställa, med en känsel-signal. Skärmen hålls tänd medan appen är öppen. Bortvalt: start- och stoppknapp.

## B7 — Enheten följer telefonens region

Valt: km/h och km där telefonen mäter metriskt, mph och mi i USA och Storbritannien. Ingen inställning.

## B8 — Engelska i appen

Valt: all text i appen är på engelska, för en publik app. Svenska kan läggas till senare.

## B9 — iOS 17

Valt: iOS 17 som lägsta version, för att nå fler telefoner. Inget i första versionen kräver något nyare.

## B10 — Turen överlever att appen stängs

Valt: turens tal sparas på telefonen (UserDefaults) efter varje ändring och läses in när appen startar; bara håll-in
nollställer. Med appen i bakgrunden läses ingen plats, så turen står still då. Bortvalt: plats i bakgrunden i
första versionen (kräver "Always" eller en bakgrundsdeklaration, och mer att förklara i granskningen).
Omprövas: med fart på låsskärmen (Live Activity).

## B11 — Systemets typsnitt, siffror med fast bredd

Valt: SF Pro, med siffror av fast bredd, så att talen inte hoppar i sidled. Skissen använde Inter bara för att
SF Pro inte finns på webben.

## B12 — Ikonen är tavlan

Valt: appikonen är visartavlan ur appen, förenklad så att den går att läsa i 60 px: svart botten, sju stora vita
streck och sex små grå, en vit visare kring 37 på skalan som slutar innanför strecken, navet och den orange
max-markeringen. Inga siffror. Ritas av `tools/ikon.py`, så att den går att ändra som kod.
Bortvalt: siffror och alla små streck, som blir brus i liten storlek.

## B13 — TestFlight i repots Actions

Valt: `testflight.yml` bygger, signerar och laddar upp på GitHubs macOS-maskiner (BESLUT B4), samma väg som
Idunns spegel. Den startas bara för hand från `main`, efter ägarens ja, och kräver grönt för samma commit i både
testerna och appens bygge. Hemligheterna (App Store Connect-nyckeln och signeringsnyckeln) ligger bara i repots
Actions-hemligheter och ges bara till stegen som behöver dem. Byggnumret är senaste TestFlight-bygget + 1.

## B14 — Allt utöver mätaren bakom en meny

Valt (ägaren 2026-11-17): det som kommer utöver mätaren, med uppläsningen av toppfart som första, samlas bakom en
hamburgarmeny: en diskret ikon i ett hörn som öppnar ett blad. Mätarskärmen förblir ren hur mycket som än läggs
till, och ingen ny knapp behövs per funktion. Ikonen läggs till först när menyn har något i sig; en tom meny byggs
inte. Ett kort tryck öppnar menyn, så den krockar inte med håll-in för att nollställa (BESLUT B6).
Bortvalt: en egen ikon per funktion på mätarskärmen, och inställningar i iOS Inställningar-app (för gömt).

## B15 — Ingen PAUSED före första turen

Valt (2026-11-17, efter bygge 2): när turen är tom (ny eller nollställd) visar skärmen bara 0 och enheten, utan
PAUSED och utan "Hold to reset". Orden syns först när det finns en tur som står still. Skäl: appen visade PAUSED
direkt när den öppnades, innan något cyklats, och det väckte frågan vad som var pausat.
