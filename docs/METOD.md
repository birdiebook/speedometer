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

## M2 — Utjämningen och visarens rörelse

Den visade farten jämnas ut exponentiellt med tidskonstanten **τ = 1,0 s**: `v ← v + α (rå − v)` med
`α = 1 − e^(−Δt/τ)`.

Visaren glider sedan till varje nytt värde i stället för att hoppa dit. Varje ändring fördelas jämnt över **1,0 s**,
ungefär tiden till nästa GPS-prov, med mjuk start och mjukt slut på **0,4 s**: visarens fart stiger jämnt, håller
och sjunker jämnt (en trapets), så rörelsen har inga knyck. Ett glid tar 1,4 s, och kommer ett nytt värde under
tiden läggs glidningarna ihop. Vid jämn acceleration blir stegen lika stora, och då vrider sig visaren med jämn fart
hela tiden mellan proven, som i en bil. Den hamnar aldrig utanför värdena den fått, och alltså aldrig förbi
max-markeringen. Den stora siffran och max-markeringen följer samma rörelse, så att de alltid visar samma sak som
visaren. Priset är att visaren ligger i snitt 0,7 s efter den utjämnade farten.
Status: antagande; tunas på cykeln. Mätt 2026-11-18, första provturen (bygge 2): med en kort fjäder (0,35 s) var
visaren framme på en tredjedel av sekunden och stod sedan still till nästa prov, så den hoppade en gång i sekunden.

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

240° från −120° till +120° (0° rakt upp, medurs). Skalan är fast och tätare ju högre farten är: vinkeln är
`−120° + 240° · (2/π) · atan(v / mitten)`, där mitten är **60 km/h** (eller **40 mph**) och står rakt upp. Varje
tiotal blir lite smalare än det förra (0–10 km/h tar 25°, 50–60 km/h 14°), och bågens slut nås aldrig, så skalan har
inget tak. Siffror vid **0, 10, 20, 30, 40, 50, 60, 80, 100, 200, 500** km/h (mph: **0, 10, 20, 30, 40, 50, 60,
100, 200, 500**), med minst 13° mellan grannar. Små streck var **2:a** enhet upp till 60, var **5:e** upp till 100,
var **10:e** upp till 200 och var **50:e** upp till 500, där strecken slutar; mph är tätare upp mot slutet och får
var **20:e** upp till 200 och var **100:e** upp till 500, så att strecken alltid har minst 2° emellan. Bara delen upp till den lägsta siffran
som rymmer turens max, eller farten om den är högre, är tänd, och minst upp till **100 km/h** (**60 mph**). När
turen går förbi tonas nästa streck och siffror in på **0,6 s**; inget som redan syns flyttas. En nollställning
släcker dem igen (BESLUT B16). Över 500 går visaren vidare förbi strecken mot bågens slut.
Status: antagande, efter Saabs hastighetsmätare (ägaren 2026-11-18); tunas på telefonen.

## M7 — Avrundningen

Den stora siffran visas som heltal. Sträckan och snittet med en decimal. Tiden som `m:ss` under en timme, annars
`h:mm:ss`. Decimaltecken och tal följer appens engelska text (punkt). Status: antagande.

## M8 — Enheterna

1 km/h = 1/3,6 m/s; 1 mph = 0,44704 m/s; 1 mi = 1 609,344 m. Status: standard (definitionerna).
