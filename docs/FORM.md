# Formen

Måtten ur skissen (BESLUT B5), för en skärm som är 390 punkter bred. Allt skalas med skärmens bredd.

## Färger

| Roll | Mörkt | Ljust |
|---|---|---|
| Bakgrund | `#000000` | `#FFFFFF` |
| Text, visare, stora streck | `#FFFFFF` | `#000000` |
| Små streck | `#636366` | `#AEAEB2` |
| Etiketter, siffror på skalan, enheter | `#8E8E93` | `#6E6E73` |
| Dämpad siffra (paused, finding GPS) | `#6E6E73` | `#8E8E93` |
| Max-markeringen och PAUSED | `#FFB340` | `#C77700` |
| Linjen över talen | `#1C1C1E` | `#E5E5EA` |

## Tavlan

- En kvadrat på 340 × 340 pt, centrerad i ytan ovanför talen; mitten i (170, 170).
- Skalan: 240° från −120° till +120° (0° rakt upp, medurs), METOD M6. Punkt på radien r vid vinkeln θ:
  `x = 170 + r·sin θ`, `y = 170 − r·cos θ`.
- Stora streck (var 10:e enhet): från r = 150 till r = 132, 2,5 pt, rundade ändar, textfärg.
- Små streck (var 2:a enhet): från r = 150 till r = 141, 1,5 pt, rundade ändar.
- Siffrorna på skalan: r = 112, 17 pt, medium, etikettfärg.
- Visaren: från r = −20 (svansen) till r = 140, 3 pt, rundade ändar, textfärg. Navet: en cirkel med r = 8 i
  textfärg och en med r = 3 i bakgrundsfärg.
- Max-markeringen: en triangel som pekar inåt, spetsen på r = 153 och basen på r = 166, ±2,2° kring max-vinkeln.
  Den syns inte förrän turen har ett max.
- Den digitala farten under navet: överkanten 218 pt ner i tavlan, 64 pt semibold, siffror med fast bredd.
  Under den `KM/H` (eller `MPH`), 12 pt, medium, spärrad 3 pt, etikettfärg.

## Talen

- Under tavlan: en linje på 1 pt, sedan tre lika breda kolumner med 12 pt mellanrum: `DISTANCE`, `TIME`, `AVG`.
- Etikett: 12 pt, medium, spärrad 1,5 pt, etikettfärg. Värde: 26 pt, medium, fast bredd; enheten (`km`, `km/h`)
  12 pt i etikettfärg direkt efter.
- Marginaler: 25 pt på sidorna, 56 pt nedtill.

## Lägena

- **Riding:** som ovan.
- **Paused:** visaren står på 0, den digitala siffran i dämpad färg, under enheten `PAUSED` (12 pt, semibold,
  spärrad 3 pt, orange). Längst ner `Hold to reset`, 13 pt, etikettfärg. Max-markeringen står kvar. Är turen tom (ny eller
  nollställd) visas enheten i stället för `PAUSED` och ingen `Hold to reset` (BESLUT B15).
- **Finding GPS:** visare och nav i små strecks färg, siffran är `–` i dämpad färg, under enheten en prick och
  `FINDING GPS` i etikettfärg. Talen visar `0.0`, `0:00` och `–` för snittet.
- **Location off** (E1): nekas eller begränsad platsåtkomst visar samma layout som finding GPS, men med `LOCATION OFF`
  (12 pt, semibold, spärrad 3 pt, etikettfärg) under enheten i stället för pricken och `FINDING GPS`, och längst ner
  länken `Allow location in Settings` (13 pt, orange) som öppnar appens inställningar.

## Menyn (BESLUT B14)

- Ikonen: tre streck, 20 × 14 pt, 1,75 pt, rundade ändar, etikettfärg, i en tryckyta på 44 × 44 pt i mätarens övre
  högra hörn, med strecken 25 pt från skärmens kant. Talen och tavlan flyttar sig inte för den.
- Bladet: 140 pt högt, med systemets handtag. Bakgrund `#1C1C1E` mörkt, `#FFFFFF` ljust. En rad på minst 64 pt med
  20 pt sidmarginal: `Trail` (17 pt, medium, textfärg), under den `This ride, drawn by speed` (13 pt, etikettfärg),
  längst till höger en vinkel (15 pt, semibold, små strecks färg). Raden öppnar Trail.

## Trail (BESLUT B16)

Ett blad över hela skärmen med systemets handtag, i appens bakgrundsfärg. 25 pt marginal på sidorna, 24 pt nedtill.

- Överst, 28 pt ner: `TRAIL` till vänster (12 pt, medium, spärrad 1,5 pt, etikettfärg) och turens sträcka och tid
  till höger, `12.4 km · 34:12` (12 pt, medium, fast bredd, etikettfärg).
- Spåret fyller ytan mellan raden överst och skalan nederst, 16 pt från båda, med 12 pt luft runt linjen.
  Linjen: 4 pt, rundade ändar och hörn, färgad i tio steg efter farten (METOD M10). Ett glapp (METOD M9) är en rak
  prickad linje, 2 pt, prickar var 6:e pt, i små strecks färg.
- Start: en ring med r = 4,5 pt, 2 pt i etikettfärg, fylld med bakgrundsfärg. Slut (eller där du är nu): en prick med
  r = 5 pt i textfärg med 2 pt kant i bakgrundsfärg.
- Max: tavlans orange triangel, 12 pt lång och 11 pt bred, med spetsen 9 pt från punkten och pekande mot den, och
  maxfarten som heltal bortom den, 25 pt från punkten (13 pt, semibold, orange). Den sitter på tvären mot linjen, så
  att den aldrig ligger på linjen, på den sida som vetter bort från spårets mitt; når den då mer än 46 pt utanför
  ytan vänds den mot mitten.
- Skalan nederst: en stapel på 4 pt med de tio färgerna, under den `0` till vänster och turens max till höger,
  `39 km/h` (12 pt, medium, etikettfärg), 8 pt emellan.
- Fingret på spåret: en ring med r = 10 pt, 2,5 pt i textfärg, fylld med bakgrundsfärg och med en prick på r = 4,5 pt
  i punktens färg. Ovanför (under, nära överkanten) en bubbla i textfärg med 10 pt rundning: farten som heltal
  (19 pt, semibold, bakgrundsfärg) och enheten (12 pt, medium). Delen efter punkten ritas med 28 % opacitet. Raden
  överst visar punktens sträcka och tid i textfärg, och skalan får en markering på 3 × 14 pt i textfärg vid punktens
  fart. När fingret lyfts försvinner allt detta.
- Utan spår (ny eller nollställd tur): bara raden överst och, mitt på sidan, `Your trail appears here once you ride.`
  (13 pt, etikettfärg).

| Steg (långsamt → fort) | Mörkt | Ljust |
|---|---|---|
| 1 | `#525255` | `#CCCBCE` |
| 2 | `#636263` | `#C2BFBF` |
| 3 | `#757372` | `#B8B3B0` |
| 4 | `#878481` | `#AEA7A2` |
| 5 | `#9A9590` | `#A59C93` |
| 6 | `#ACA192` | `#A49383` |
| 7 | `#BFA585` | `#AD8E70` |
| 8 | `#D1AA77` | `#B5885C` |
| 9 | `#E4AE65` | `#BC8244` |
| 10 | `#F6B14F` | `#C47B24` |

Färgerna är mitten av varje steg i en övergång i OKLab: mörkt `#4A4A4E` → `#A39E98` → `#FFB340`, ljust `#D1D1D6` →
`#A0968C` → `#C77700`, alltså från grått till max-markeringens orange.
