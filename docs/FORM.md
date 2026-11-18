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
- Stora streck (var 10:e enhet på startskalan): från r = 150 till r = 132, 2,5 pt, rundade ändar, textfärg.
- Små streck (var 2:a enhet på startskalan): från r = 150 till r = 141, 1,5 pt, rundade ändar.
- Siffrorna på skalan: r = 112, 17 pt, medium, etikettfärg. När skalan växer står strecken kvar och siffrorna byts
  (METOD M6).
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
