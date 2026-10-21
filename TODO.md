# TODO

Prioriteret plan for en første GIHC mini-mesh-prototype. Rækkefølgen er
vigtig: lokal kommunikation og dataintegritet kommer før LoRa,
multi-hop-routing og strømoptimering.

## Infrastruktur og offentlig side

- [x] Byg den statiske side med samme Eleventy-mønster som `../gihc`.
- [x] Tilføj dansk og engelsk forside, 404, sikkerhedsheadere og
  socialt previewbillede.
- [x] Tilføj Dockerfile, Nginx-konfiguration og statiske smoke-tests.
- [x] Tilføj Kubernetes-manifester og DNS-script for `mesh.gihc.online`.
- [ ] Opret GitHub-repository og push `main`, så image-workflowet kan køre.
- [ ] Opret A-recorden `mesh.gihc.online` hos Simply.com.
- [ ] Deploy `ghcr.io/gihc-org/gihc-mesh` til k3s-namespace `gihc-mesh`.
- [ ] Kontrollér cert-manager-certifikatet for `mesh.gihc.online`.
- [ ] Kør `./scripts/smoke-test.sh https://mesh.gihc.online`.
- [ ] Pin det første publicerede image med commit-SHA i
  `k8s/deployment.yaml`.

## 0. Beslutninger og afklaring

- [ ] Vælg arbejdstitel. Forslag: **Budstikken**.
- [ ] Beslut om første hardwareplatform. Anbefaling: ESP32-C6.
- [ ] Verificér aktuelle Rust- og ESP-IDF-crates til den valgte ESP32.
- [ ] Verificér iroh-version, platformskrav og de relevante crates.
- [ ] Beslut om første lokale transport. Anbefaling: ESP-NOW.
- [ ] Beslut om hub-platform. Anbefaling: Raspberry Pi Zero 2 W.
- [ ] Skriv en trusselsmodel for børn, delte enheder og tabte nøgler.
- [ ] Fastlæg regler for, hvad der må vises på e-ink i offentlige rum.

**Færdig når:** valgene er noteret i `ANALYSE.md` eller en kort ADR, og
der er indkøbt materiale til højst fem knuder.

## 1. Hardware-spike

- [ ] Få ESP32-C6 til at blinke og skrive log via USB.
- [ ] Læs en knap med debounce.
- [ ] Vis tekst og status på e-ink.
- [ ] Gem og læs en lille struktur fra NVS/flash.
- [ ] Mål strømforbrug i aktiv, idle og deep sleep.
- [ ] Genstart enheden 100 gange og kontrollér, at data overlever.
- [ ] Dokumentér pinout, strømforsyning og batterivalg.

**Færdig når:** én knude kan starte, vise status, tage imod et tryk og
bevare en hændelse efter strømafbrydelse.

## 2. Lokal radiodemo

- [ ] Send en fast pakke mellem to ESP32-knuder via ESP-NOW.
- [ ] Tilføj afsender-id og sekvensnummer.
- [ ] Afvis dubletter med en lille LRU- eller id-tabel.
- [ ] Udvid til tre knuder med en simpel hub- eller star-topologi.
- [ ] Mål rækkevidde indendørs, udendørs og gennem vægge.
- [ ] Log pakketab ved forskellige afstande.
- [ ] Test adfærd, når hubben genstarter.

**Færdig når:** tre knuder kan sende hændelser til en hub, og et
gentaget pakkeforsøg skaber ikke dubletter i loggen.

## 3. Hændelsesformat og signaturer

- [ ] Definér et minimalt, versionsstyret hændelsesformat.
- [ ] Vælg deterministisk serialisering, for eksempel CBOR eller postcard.
- [ ] Generér en nøgle pr. knude.
- [ ] Signér hændelser og verificér signaturen på hubben.
- [ ] Afvis forkert signerede og åbenlyst forældede hændelser.
- [ ] Skriv testvektorer, som både firmware og Rust-hub kan kontrollere.
- [ ] Beskriv, hvordan en knude nulstilles uden at ødelægge identiteten.

**Færdig når:** en ændret byte i en hændelse får hubben til at afvise den,
og gyldige hændelser kan sendes mellem firmware og Rust uden
formatfortolkning.

## 4. Rust-hub og lokal log

- [ ] Opret et lille Rust-workspace med `firmware/` og `hub/` eller en
  tilsvarende struktur.
- [ ] Vælg en lokal database. Anbefaling: SQLite til første prototype.
- [ ] Implementér append-only tabel for hændelser.
- [ ] Implementér unikke id'er og idempotent indsættelse.
- [ ] Implementér et lille UDP- eller CoAP-modtag til ESP32-knuder.
- [ ] Vis antal modtagne hændelser og seneste aktivitet.
- [ ] Tilføj kommandoer til backup og gendannelse.

**Færdig når:** hubben kan modtage, validere, gemme og vise hændelser, og
en genstart ikke ændrer resultatet.

## 5. Iroh-synkronisering

- [ ] Kør to iroh-hubs på samme LAN.
- [ ] Overfør den lokale hændelseslog uden at miste rækkefølge eller
  integritet.
- [ ] Test afbrudt forbindelse midt i en overførsel.
- [ ] Test genstart af begge hubs og genoptaget synkronisering.
- [ ] Test synkronisering over internettet gennem en egen relay.
- [ ] Kontrollér, at begge hubs ender med samme sæt hændelser.
- [ ] Dokumentér, hvordan data fjernes eller udløber, hvis det er relevant.

**Færdig når:** to hubs har udvekslet en lejrs historik over både LAN og
internet, og en afbrydelse ikke efterlader uopdagede huller.

## 6. Budstikken MVP

- [ ] Implementér tre skærmtilstande: status, besked og opgave.
- [ ] Implementér check-in med ét knaptryk.
- [ ] Implementér en simpel skattejagt med poster og fund.
- [ ] Vis tydelig feedback ved sendt, gemt og afvist hændelse.
- [ ] Tilføj lavt batteri- og fejlstatus.
- [ ] Lav en enkel hub-skærm til underviseren.
- [ ] Lav en fysisk stander eller et armbånd til knuden.
- [ ] Skriv en kort feltvejledning på dansk.

**Færdig når:** en gruppe på mindst fem personer kan gennemføre en
30-minutters øvelse uden at læse teknisk dokumentation.

## 7. Felt-test

- [ ] Test med mindst fem knuder og to hubs.
- [ ] Test i mindst 24 timer uden internet.
- [ ] Test i regn, kulde og direkte sollys.
- [ ] Test med børn i den tiltænkte aldersgruppe.
- [ ] Mål faktisk batterilevetid og antal mistede pakker.
- [ ] Skriv en fejlrapport med data, ikke bare indtryk.
- [ ] Beslut, om ESP-NOW-rækkevidden er tilstrækkelig.

**Færdig når:** resultaterne er dokumenteret, og næste iteration bygger på
målinger.

## 8. Efter MVP

### LoRa

- [ ] Vælg SX1262-modul og kontrollér danske/EU-regler for 868 MHz.
- [ ] Send korte hændelser mellem to ESP32-knuder over LoRa.
- [ ] Mål rækkevidde, pakketab, lufttid og strømforbrug.
- [ ] Definér en kompakt repræsentation af hændelser.
- [ ] Beslut, om LoRa skal være backbone eller kun nødkanal.

### Multi-hop

- [ ] Undersøg modne protokoller, før der skrives egen routing.
- [ ] Definér loopdetektion, TTL og duplikathåndtering.
- [ ] Simulér netværk med tabte knuder og skiftende ruter.
- [ ] Test et lille fysisk netværk med mindst tre hop.

### Drift og sikkerhed

- [ ] Undersøg secure boot og flash-kryptering.
- [ ] Lav nøglebackup og en sikker nulstillingsprocedure.
- [ ] Lav signerede firmwareopdateringer.
- [ ] Begræns pakkehastighed pr. knude.
- [ ] Tilføj privat beskedkryptering, hvis trusselsmodellen kræver det.
- [ ] Lav backup af hubben og test gendannelse.

### Pædagogik

- [ ] Lav en byggevejledning med billeder.
- [ ] Lav tre fejlsøgningsøvelser til workshoppen.
- [ ] Lav et papirværktøj, der forklarer signaturer uden matematik.
- [ ] Lav en CTF-variant af Budstikken.
- [ ] Offentliggør en BOM og en samlet materialepakke.

## Definition of done for første offentlige prototype

- Tre eller flere knuder kan bruges uden internet.
- Hændelser er signerede, idempotente og overlever genstart.
- To hubs kan synkronisere gennem iroh.
- Strømforbrug og rækkevidde er målt i en realistisk felt-test.
- En familie kan gennemføre en demonstration med kort mundtlig
  introduktion.
- Kildekode, hardwarevalg, kendte begrænsninger og testresultater er
  dokumenteret.
