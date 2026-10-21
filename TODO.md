# TODO

Prioriteret plan for en første GIHC mini-mesh-prototype. Rækkefølgen er
vigtig: lokal kommunikation og dataintegritet kommer før LoRa,
multi-hop-routing og strømoptimering.

## Handover-prompt

Teksten nedenfor kan indsættes som første besked i en ny Codex-session, når
den kører med de nødvendige tilladelser:

```text
Du overtager arbejdet i /home/kristian/projects/gihc-mesh.

Projektet er GIHC Mini-Mesh: en statisk projektside, systemanalyse og senere
en ESP32/iroh-prototype. Læs README.md, ANALYSE.md og TODO.md, før du ændrer
noget.

Aktuel status:
- Repositoryet bruger branch main og har origin git@github.com:gihc-org/gihc-mesh.git.
- Første commit er pushet. Kontrollér selv HEAD og origin/main; arbejdstræet
  var rent ved overdragelsen.
- Eleventy-siden, Dockerfile, nginx.conf, k8s-manifester, DNS-script,
  deploy-script, smoke-test og GitHub Actions-workflowet er på plads.
- npm run check, npm audit --offline, HTML-kontrol og kubectl kustomize er
  tidligere gennemført uden fejl.
- GitHub Actions-workflowet "Publish mini-mesh image" blev udløst af pushet,
  men resultatet er ikke verificeret i denne session.
- A-recorden mesh.gihc.online er ikke bekræftet oprettet.
- Workloaden er ikke bekræftet deployeret til k3s.

Din opgave er at færdiggøre den offentlige udgivelse af
https://mesh.gihc.online uden at ændre ../gihc.

Gør følgende i rækkefølge:
1. Kontrollér git status, HEAD, origin/main og at arbejdstræet er rent.
2. Kontrollér GitHub Actions-runnet for seneste main. Vent på, at build,
   Trivy-scan og push til ghcr.io/gihc-org/gihc-mesh er gennemført.
3. Kontrollér, at imageet kan hentes af k3s. GHCR-pakken skal enten være
   offentlig, eller der skal være et eksisterende imagePullSecret. Læs eller
   skriv aldrig credentials til output, commits eller logfiler.
4. Kør npm run check, bash -n scripts/*.sh og kubectl kustomize k8s/.
5. Opret A-recorden med ./scripts/create-dns-record.sh. Kontrollér med dig,
   at mesh.gihc.online peger på den forventede VPS.
6. Genbrug en eksisterende k3s-tunnel, hvis den virker. Ellers åbn den
   dokumenterede tunnel på 16443 og deploy med det publicerede SHA-image:

   IMAGE=ghcr.io/gihc-org/gihc-mesh:<publiceret-sha> \
   IMAGE_PULL_POLICY=IfNotPresent \
   KUBECTL_SERVER=https://127.0.0.1:16443 \
   ./scripts/deploy.sh

7. Kontrollér rollout, pods, ingress og certifikatet
   mesh-gihc-online-tls. Kør derefter:

   ./scripts/smoke-test.sh https://mesh.gihc.online

8. Når deployen virker, opdater k8s/deployment.yaml fra :latest til det
   konkrete publicerede SHA-image og imagePullPolicy: IfNotPresent. Commit og
   push ændringen på main.
9. Verificér til sidst Git-status, Actions og den offentlige URL igen.

Afgrænsning:
- Ændr kun /home/kristian/projects/gihc-mesh.
- Ændr ikke ../gihc eller det eksisterende gihc.online-site.
- Commit ikke node_modules, _site, credentials, private nøgler eller lokale
  kubeconfig-filer.
- Slet ikke eksisterende DNS-records, deployments eller tunneler.
- Hvis en ekstern handling fejler, skal du rapportere den præcise kommando og
  fejl i stedet for at antage, at den lykkedes.

Færdigkriterier:
- GitHub Actions-runnet for main er grønt, og imageet findes.
- mesh.gihc.online har korrekt A-record.
- Deploymentet er klar, og TLS-certifikatet er Ready=True.
- https://mesh.gihc.online og /en/ svarer korrekt.
- smoke-testen består.
- deployment.yaml peger på et SHA-image.
- Ændringerne er committet og pushet, og arbejdstræet er rent.
```

## Infrastruktur og offentlig side

- [x] Byg den statiske side med samme Eleventy-mønster som `../gihc`.
- [x] Tilføj dansk og engelsk forside, 404, sikkerhedsheadere og
  socialt previewbillede.
- [x] Tilføj Dockerfile, Nginx-konfiguration og statiske smoke-tests.
- [x] Tilføj Kubernetes-manifester og DNS-script for `mesh.gihc.online`.
- [x] Opret GitHub-repository og push `main`, så image-workflowet kan køre.
- [x] Kontrollér at image-workflowet er grønt og imageet kan hentes.
- [x] Opret A-recorden `mesh.gihc.online` hos Simply.com.
- [x] Deploy `ghcr.io/gihc-org/gihc-mesh` til k3s-namespace `gihc-mesh`.
- [x] Kontrollér cert-manager-certifikatet for `mesh.gihc.online`.
- [x] Kør `./scripts/smoke-test.sh https://mesh.gihc.online`.
- [x] Pin det første publicerede image med commit-SHA i
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
