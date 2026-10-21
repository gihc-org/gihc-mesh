# Indkøbsliste: første mini-mesh-prototype

Denne liste dækker den første hardware-spike og vejen frem til tre knuder.
Den følger anbefalingen om ESP32-C6 og 2,9" e-ink fra [README.md](README.md),
men låser ikke hardwarevalget endeligt. Køb derfor samme eksakte model og
revision ved genbestilling.

Målet er:

- tre fungerende knuder
- en fjerde knude som reservedel og sammenligningsgrundlag
- to hubs, hvor der i første omgang genbruges eksisterende Linux-computere
- bordtest over USB før batteri og solcelle købes

Priserne er vejledende danske detailpriser i DKK uden fragt. Kontrollér
lagerstatus, revision og datablad hos den konkrete forhandler før bestilling.

## Køb nu

| Del | Antal | Krav | Vejledende pris |
| --- | ---: | --- | ---: |
| ESP32-C6-DevKitC-1 | 4 | Samme variant, helst med 8 MB flash. Bekræft pinout og Rust/ESP-IDF-support. | 400-640 |
| 2,9" e-Paper Module | 4 | Sort/hvid, 296×128, SPI og 3,3 V-logik. Køb et modul med driver og datablad, ikke et bart panel. | 720-1.200 |
| Breadboard | 4 | Mindst 400 forbindelsespunkter. | 100-160 |
| Dupont-ledninger | 2 sæt | Blandet han-han, han-hun og hun-hun. | 80-140 |
| USB-C-kabel | 4 | Data- og strømkabel, ikke kun opladning. | 120-200 |
| Tactile-knapper | 10 | 12 mm gennemgående, momentan og NO. | 20-40 |
| Pinheaders | 1 pakke | 2,54 mm han og hun til moduler uden monterede pins. | 20-40 |
| Passive buzzere | 4 | 3,3-5 V, til lydfeedback. Kan udelades i første test. | 20-40 |
| Modstandssortiment | 1 sæt | Almindelige 1/4 W-modstande, især 220 Ω, 1 kΩ og 10 kΩ. | 50-100 |
| Standoffs og monteringsmateriale | 1 sæt | M2/M3, til at holde devkit og display uden løse ledninger. | 80-150 |

**Samlet kernekøb: cirka 1.600-2.700 DKK.**

En ekstra ESP32 og et ekstra display er med vilje taget med. Det gør det
muligt at fortsætte fejlfindingen, hvis en enhed beskadiges, og at afgøre om
en fejl følger knuden eller firmwaren.

## Strøm og måling

Begynd med en certificeret 5 V USB-strømforsyning eller en computerport.
Undgå et batteri i den første bring-up, indtil pinout og strømforbrug er
kendt.

| Del | Antal | Krav | Vejledende pris |
| --- | ---: | --- | ---: |
| USB-strømforsyning | 2 | 5 V, mindst 2 A, certificeret. Kun hvis den ikke findes i forvejen. | 100-200 |
| USB-power-meter | 1 | Kan vise spænding, strøm og akkumuleret energi. | 100-200 |
| Multimeter | 1 | Skal kunne måle µA og mA. Må ikke tilføje for stort spændingsfald i strømområdet. | 300-800 |

Til seriøse deep-sleep-målinger er et professionelt strømprofilværktøj som
Nordic Power Profiler Kit II bedre end et billigt multimeter. Det er ikke
nødvendigt for den første blink- og displaytest.

## Første udvidelse: feltstrøm

Køb først batteri, oplader og solcelle, når der findes målinger for:

- aktiv strøm ved Wi-Fi og ESP-NOW
- strøm i deep sleep
- e-ink-opdateringens varighed og forbrug
- spændingsområdet på den valgte ESP32-C6-udviklingsboard

Den senere indkøbsliste bør mindst indeholde:

- fire beskyttede 18650-celler eller tilsvarende LiFePO4-løsning fra en
  kendt producent
- matchende batteriholdere og mekanisk sikring
- oplader og 5 V-converter med kendt lav hvile-strøm
- solcellepanel, laderegulator og beskyttelse mod dyb afladning
- sikring, polaritetsbeskyttelse og tydelig mærkning af plus og minus

Undgå ubeskyttede løse Li-ion-celler og tilfældige billige opladermoduler.
En almindelig powerbank kan også slukke ved meget lav strømbelastning og er
derfor ikke nødvendigvis egnet til en sove- og deep-sleep-test.

## Hub

Genbrug en laptop eller mini-PC som første hub. Til den anden hub kan en
anden eksisterende Linux-maskine bruges. Køb derfor ikke en Raspberry Pi,
før det er bekræftet, at der mangler en permanent maskine.

Hvis en dedikeret hub er nødvendig:

| Del | Antal | Krav |
| --- | ---: | --- |
| Raspberry Pi Zero 2 W eller tilsvarende | 1 | Skal kunne køre Rust, iroh og en lokal database. |
| microSD-kort | 1 | 32 GB eller mere, gerne high-endurance. |
| USB-strømforsyning | 1 | Korrekt 5 V-forsyning til den valgte hub. |
| Kabinet og køling | 1 | Beskytter kortet og giver stabil drift. |

## Køb ikke endnu

Følgende bør vente på en beslutning eller en måling:

- **SX1262/LoRa:** køb først efter valg af 868 MHz-modul og kontrol af
  danske/EU-regler, antenne og duty cycle.
- **Solcelle og batteri:** køb først efter deep-sleep-målinger.
- **Fem eller flere knuder:** tre knuder er nok til den første
  ESP-NOW-demo.
- **Specialprint:** brug breadboard og udviklingsboards, indtil pinout,
  strøm og mekanik er verificeret.
- **Sensorsæt:** tilføj kun de sensorer, som en konkret øvelse kræver.

## Kontrol før bestilling

1. Vælg én ESP32-C6-model og notér præcis vare-SKU.
2. Vælg én e-ink-model og kontrollér controller, opløsning, farver og
   eksisterende driverbibliotek.
3. Kontrollér at e-ink-modulet kan bruge 3,3 V-logik sammen med ESP32-C6.
4. Kontrollér at alle viste varer faktisk er på lager, og at der kan
   genbestilles samme revision.
5. Vælg en leverandør med datablad og returret frem for en anonym
   markedspladsliste uden modelnummer.
6. Gem ordrebekræftelse, vare-SKU og datablade i projektets dokumentation,
   men ikke personlige betalingsoplysninger.

## Første test efter levering

1. Montér og test én ESP32-C6 alene via USB.
2. Mål strømforbrug med display og radio slukket.
3. Tilslut e-ink og få den til at vise en kendt tekst.
4. Tilføj to knapper og feedback.
5. Gentag med de øvrige knuder og registrér eventuelle
   hardwareforskelle.
6. Først derefter bestilles batterier og strømkonvertere til feltbrug.
