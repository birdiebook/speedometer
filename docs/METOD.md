# Metod

Varje mätning, algoritm och konstant, med källa och källans status: mätt · standard · forskning · antagande.
Koden hänvisar med `// METOD Mn`. En konstant utan rad här är en bugg.

## M1 — Positionen och farten ur GPS

Två nivåer. **Position:** `horizontalAccuracy` är minst 0 och högst **100 m**; då vet telefonen var den är, även
inomhus på wifi. **Giltig fart:** `CLLocation.speed` (m/s) är minst 0, `speedAccuracy` är minst 0 och högst
**3 m/s**, och `horizontalAccuracy` är högst **30 m**. Apple anger att farten är ogiltig när `speed` eller
`speedAccuracy` är negativ. Bara giltig fart räknas in i sträcka, tid och max.
Status: Apples dokumentation för fälten (standard); gränserna är antaganden.
Mätt 2026-11-17, första bygget på telefonen: inomhus och stilla gav iOS position men ingen giltig fart, och
appen stod kvar på finding GPS fast GPS fungerade. Därför de två nivåerna; gränsen för fartens noggrannhet höjdes
samtidigt från 2 till 3 m/s, så att en sämre men användbar fart inte pausar turen mitt i farten. Simulatorn
(`simctl location`) ger `speedAccuracy` −1 i varje prov, så den riktiga vägen prövas på telefonen.

## M2 — Utjämningen

Den visade farten jämnas ut exponentiellt med tidskonstanten **τ = 1,0 s**: `v ← v + α (rå − v)` med
`α = 1 − e^(−Δt/τ)`. Visaren rör sig dessutom med en kort fjäder i appen. Status: antagande; tunas på cykeln.

## M3 — Autopausen

Turen pausar när den utjämnade farten varit under **0,8 m/s** (2,9 km/h) i **3 s**, och fortsätter när den
når **1,4 m/s** (5 km/h). Glappet mellan gränserna hindrar att den slår fram och tillbaka vid låg fart.
En position utan giltig fart (M1) betyder stillastående: turen pausar med visaren på 0. Under färd hålls farten
kvar i upp till **3 s** utan giltig fart (ett kort avbrott), sedan pausar turen, även om inga positioner kommer
alls (en tunnel). Kommer ingen position på **15 s** räknas det som att GPS saknas: farten visas inte och turen
står still. Status: antagande. Mätt 2026-11-17 med bygge 2: inomhus kom positionerna glest, och med 5 s växlade
skärmen mellan paused och finding GPS; därför 15 s.

## M4 — Sträckan och tiden

Sträckan är summan av rå fart × Δt över prov medan turen rullar; tiden är summan av Δt. Δt räknas högst som
**3 s**, så att ett glapp i GPS inte lägger till sträcka som inte mätts. Snittet är sträcka / tid.
Status: antagande. Farten (Doppler) ger mindre brus än avstånd mellan positioner vid låg fart.

## M5 — Max

Max är den högsta utjämnade farten under turen, så att en enstaka topp i GPS inte fastnar som max.
Status: antagande.

## M6 — Skalan

0–60 km/h (metriskt) eller 0–40 mph, över 240° från −120° till +120° (0° rakt upp, medurs). Stora streck var
10:e enhet med siffra, små streck var 2:a. Över skalans slut stannar visaren vid slutet; siffran visar den riktiga
farten. Status: antagande, ur skissen.

## M7 — Avrundningen

Den stora siffran visas som heltal. Sträckan och snittet med en decimal. Tiden som `m:ss` under en timme, annars
`h:mm:ss`. Decimaltecken och tal följer appens engelska text (punkt). Status: antagande.

## M8 — Enheterna

1 km/h = 1/3,6 m/s; 1 mph = 0,44704 m/s; 1 mi = 1 609,344 m. Status: standard (definitionerna).
