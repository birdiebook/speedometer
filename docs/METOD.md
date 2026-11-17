# Metod

Varje mätning, algoritm och konstant, med källa och källans status: mätt · standard · forskning · antagande.
Koden hänvisar med `// METOD Mn`. En konstant utan rad här är en bugg.

## M1 — Farten ur GPS

`CLLocation.speed` i m/s; Apple anger ett negativt värde när farten är ogiltig. Ett prov används när farten är
minst 0, `speedAccuracy` är minst 0 och högst **2 m/s**, och `horizontalAccuracy` är minst 0 och högst **30 m**.
Status: Apples dokumentation för fälten (standard); gränserna är antaganden (30 m är samma gräns som Idunns pass ute).

## M2 — Utjämningen

Den visade farten jämnas ut exponentiellt med tidskonstanten **τ = 1,0 s**: `v ← v + α (rå − v)` med
`α = 1 − e^(−Δt/τ)`. Visaren rör sig dessutom med en kort fjäder i appen. Status: antagande; tunas på cykeln.

## M3 — Autopausen

Turen pausar när den utjämnade farten varit under **0,8 m/s** (2,9 km/h) i **3 s**, och fortsätter när den
når **1,4 m/s** (5 km/h). Glappet mellan gränserna hindrar att den slår fram och tillbaka vid låg fart. Kommer
inget giltigt prov på **5 s** räknas det som att GPS saknas: farten visas inte och turen står still.
Status: antagande.

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
