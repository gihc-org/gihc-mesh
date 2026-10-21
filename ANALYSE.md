# Analyse: mini-mesh med ESP32 og iroh

## Resume

Projektet er teknisk meningsfuldt, fordi det kombinerer to lag med forskellige
styrker:

- ESP32 er billig, strømfølsom og har indbyggede radioer til lokal
  kommunikation.
- Rust og iroh giver moderne, krypterede forbindelser og et godt fundament
  for synkronisering mellem hubs.

Kombinationen bliver kun robust, hvis man accepterer, at ESP32-nettet og
iroh-nettet har forskellige roller. iroh er ikke et batteridrevet
radio-mesh-protokol, og ESP32 er ikke en naturlig iroh-runtime.

Den anbefalede arkitektur er derfor:

1. ESP32-knuder kommunikerer lokalt via ESP-NOW, BLE eller LoRa.
2. En lokal Linux-hub samler hændelser og kører iroh.
3. Hubs synkroniserer, når de har en IP-forbindelse.
4. Data modelleres som en append-only log af signerede hændelser.

Det giver et system, der kan bruges helt offline, men som også kan forbinde
GIHC-celler over internettet uden at gøre internettet til en forudsætning.

## Formål og afgrænsning

Mini-mesh skal understøtte GIHCs øvelser i digital beredskab. Det skal være:

- forståeligt nok til, at familier kan deltage i opbygning og test
- billigt nok til, at en celle kan bygge flere knuder
- robust nok til en weekend uden fast strøm og internet
- sikkert nok til, at beskeder ikke kan ændres ubemærket
- åbent nok til at kunne undersøges og repareres lokalt

Det er ikke målet at erstatte internettet, bygge en global platform eller
lave et generelt trådløst netværk med høj båndbredde.

## Iroh på ESP32

Den centrale antagelse er, at iroh i første omgang ikke skal køre på
ESP32. iroh er en Rust-stak bygget omkring QUIC og et almindeligt
operativsystemmiljø med `std`, Tokio og betydeligt mere hukommelse end en
lille mikrocontroller typisk har til rådighed.

Selv om dele af Rust-økosystemet kan bygges til ESP32, er det ikke det samme
som, at iroh-stakken er understøttet og praktisk på målet. En port ville
kombinere tre svære opgaver:

- portabilitet for netværks- og runtime-afhængigheder
- optimering af hukommelse og flash
- et helt nyt lokalt transportlag

Det er et spændende forskningsprojekt, men et dårligt første produktmål.

### Konsekvens

En ESP32-knude sender kompakte applikationshændelser til en hub over et
enkelt lokalt transportlag. Hubben ejer iroh-forbindelsen. Det gør
firmwaren mindre og gør det muligt at udskifte radio- og synkroniseringslag
uafhængigt.

Før implementation af hubben bør den nøjagtige iroh-version og dens
platformskrav verificeres. Antagelsen skal behandles som en arkitekturrisk
og ikke som en evig sandhed om Rust-økosystemet.

## Transportlag

Der er ikke ét transportlag, som er bedst til alle afstande.

| Transport | Rækkevidde | Båndbredde | Strøm | Velegnet til |
| --- | --- | --- | --- | --- |
| ESP-NOW | typisk 10-100 m, mere frit felt | høj nok til små filer | lav til middel | prototyper, lejr og CTF |
| BLE | kort | lav til middel | lav | telefon-onboarding og små data |
| Wi-Fi | kort | høj | høj | hub-forbindelse og større overførsler |
| LoRa 868 MHz | hundreder til flere km | meget lav | lav | korte beskeder og telemetri |

ESP-NOW er det bedste startpunkt, fordi det kræver meget lidt kode og
fungerer på de fleste ESP32-varianter uden ekstra radiohardware. Det er
samtidig ikke et rigtigt multi-hop-mesh: rækkevidden er begrænset, og der
skal en gateway til for at nå en hub.

LoRa giver den relevante beredskabsrækkevidde, men skaber nye krav til
antenner, duty cycle, regulering, pakkestørrelse og strømforbrug. Det bør
være fase to.

Multi-hop-routing bør heller ikke opfindes fra bunden i første iteration.
Det kræver loopdetektion, duplikathåndtering, rutevalg, timeouts og en
strategi for splittede netværk. Start med stjernetopologi og en hub.

## Anbefalet systemarkitektur

### ESP32-knude

Knuden bør have et lille og stabilt ansvar:

- læse knapper og sensorer
- vise status på e-ink eller LED
- skabe og signere lokale hændelser
- gemme en begrænset lokal kø
- sende og modtage pakker via ESP-NOW
- kunne genstarte uden at miste permanent data

Rust-firmware kan bygges med `esp-hal` eller ESP-IDF-baserede crates.
Præcise crate-valg bør afklares med en hardware-spike, fordi ESP32-support
ændrer sig relativt hurtigt.

### Lejr-hub

Hubben er en Linux-maskine tæt på knuderne. Den bør:

- modtage hændelser fra ESP32-knuder
- validere signaturer og afvise dubletter
- opretholde en lokal append-only log
- eksponere en lille statusvisning for undervisere
- køre iroh og replikere med andre hubs
- fungere uden internet

Hub-programmet bør skrives i Rust. Det kan dele protokoltyper med et fælles
Rust-crate, hvis firmwaren kan bruge det uden at trække for mange
afhængigheder ind.

### Hubsynkronisering

Iroh forbinder hubs og kan overføre indhold adresseret ved hash. Den
applikationsmæssige log skal stadig designes separat:

- hver hændelse har et stabilt id
- hver hændelse er signeret af sin oprindelige afsender
- modtageren kender allerede sete id'er og ignorerer dubletter
- replikering er idempotent og kan genoptages
- en hub kan fungere som mellemstation for andre hubs

Der bør ikke være behov for global konsensus. En hændelse kan ikke ændres,
men den kan referere til en tidligere hændelse, hvis man senere vil bygge
tråde eller tilbagekaldelser.

## Datamodel

En enkel hændelse kan bestå af:

```text
version      protokolversion
id           tilfældigt eller indholdsafledt id
author       offentlig nøgle eller kort node-id
seq          lokal sekvens fra afsenderen
kind         check-in, besked, fund, status eller sensor
created_at   afsenderens tid, behandles som usikker
body         kompakt CBOR eller postcard
signature    signatur over de kanoniske felter
```

Felterne skal serialiseres deterministisk, før de signeres. Store filer bør
ikke ligge direkte i hændelsen; de kan gemmes som content-addressed blobs og
refereres via hash.

### Tid og konflikter

En ESP32 uden GNSS eller netværk kan ikke kende den korrekte vægur-tid.
`created_at` må derfor ikke være den eneste sandhed. Brug i stedet:

- sekvensnumre for total orden inden for én afsender
- hændelses-id som stabil tie-breaker
- lokale monotone tællere til diagnostik
- eksplicit usikkerhed, hvis tid vises for brugeren

Til fælles tilstand bør man vælge enkle datatyper:

- grow-only sets til fund og deltagelse
- append-only logs til beskeder og hændelser
- last-writer-wins kun til felter, hvor tab af én version er acceptabelt

Undgå først en generel CRDT-motor. Den kan være nyttig senere, men gør fejl
og hukommelsesforbrug sværere at forstå i en prototype.

## Sikkerhed

I en første prototype er de vigtigste mål:

1. Integritet: en modtager kan kontrollere, at en hændelse kommer fra den
   angivne afsender.
2. Replay-beskyttelse: gamle pakker skal ikke kunne ændre nyere tilstand.
3. Begrænsning: en knude må ikke kunne oversvømme hele nettet.
4. Fortrolighed: private beskeder bør ikke kunne læses af alle mellemled.

På ESP32 kan nøgler gemmes i NVS, men NVS er ikke automatisk et sikkert
hardwaremodul. Til en rigtig udgave bør man overveje flash-kryptering,
secure boot og en klar nøgleceremoni. Til workshops kan papirbackup af
nøgler være en pædagogisk fordel, men det kræver tydelig trusselsmodel.

En offentlig nøgle er ikke en identitet, som børn nødvendigvis skal forstå.
Brugerfladen kan vise navne og farver, mens nøglen kun bruges internt.

## Strøm og drift

Batterilevetid skal måles, ikke gættes.

- Deep sleep er afgørende uden for aktive perioder.
- ESP-NOW kan bruge betydeligt mindre strøm end konstant Wi-Fi.
- E-ink bruger kun strøm ved opdatering.
- LoRa har lav gennemsnitseffekt, men strømforbruget ved transmission er
  ikke nul.
- Solcelle og batteri skal dimensioneres efter vinterforhold og faktisk
  brug, ikke kun en solrig sommerdag.

Prototypen bør logge vågne perioder og fejl på en måde, der kan aflæses
uden at en computer skal tilsluttes hver gang.

## Mulige produkter

### Budstikken

Et bærbart besked- og opgavenetværk til lejre. Dette er den bedste
kombination af social værdi, tydelig demo og teknisk læring.

### Fællesopslagstavlen

En solcelledrevet e-ink-skærm ved lokalet eller lejrpladsen. Enkel at bygge
og let at forstå, men mindre interaktiv.

### Beredskabsbrikken

En statusenhed til familien med knapper og BLE. Relevant i hverdagen, men
kræver en gennemtænkt privatlivsmodel.

### CTF-brikken

Fysiske tokens, der udveksles via ESP-NOW. Meget velegnet til børn og unge,
fordi nærhed og spilleregler gør den korte rækkevidde til en feature.

## Anbefaling

Start med Budstikken i en begrænset form:

- én type ESP32-knude
- e-ink og to knapper
- ESP-NOW i stjernetopologi
- én Linux-hub
- to hubs, der synkroniserer med iroh
- en fast lejrtest med 3-8 knuder

Først når denne kæde er stabil, bør LoRa, multi-hop, større filer og mere
avanceret UI komme til. Det giver et tidligt spilbart system og reducerer
risikoen for, at projektet ender som et løsrevet radioeksperiment.

## Åbne beslutninger

Følgende skal besluttes med en lille hardware- og softwaretest:

- ESP32-C6, ESP32-S3 eller en anden variant?
- ESP-NOW eller BLE som første lokale transport?
- Skal hubben kun være Pi, eller også kunne køre på en laptop?
- Hvor stor en lokal log skal knuden kunne gemme?
- Skal beskeder være private som standard?
- Hvilken iroh-version og hvilke crates bruges til blobs og replikering?
- Hvordan opdateres firmware i felten uden at miste nøgler?

Disse spørgsmål skal ikke blokere den første ESP-NOW-demo, men de skal
afklares, før hardwaren købes i større antal.
