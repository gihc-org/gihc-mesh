# GIHC Mini-Mesh

Et lille, robust og familievenligt mesh-netværk til øvelser, lejre og
beredskabsscenarier. Projektet undersøger, hvordan ESP32-enheder kan bruges
som fysiske, solcelledrevne knuder, mens Rust og [iroh](https://iroh.computer/)
håndterer synkronisering mellem lokale hubs.

> **Status:** Idé og systemdesign. Der er endnu ingen firmware eller
> hub-implementering i dette repository.

## Målet

Netværket skal kunne fungere uden internet og uden central infrastruktur.
Deltagerne skal kunne udveksle korte beskeder, check-ins, opgaver og
begivenheder lokalt. Når en hub senere får forbindelse, synkroniseres
historikken med andre GIHC-celler gennem iroh.

Det første scenarie er **Budstikken**: deltagerne får hver en lille
ESP32-enhed med e-ink, knapper og batteri. Under en lejr kan de sende
beskeder, finde poster og registrere fund. Om aftenen samles historikken på
en hub, og den kan senere hentes hjemme eller i en anden celle.

## Arkitektur

```text
┌──────────────┐       ESP-NOW eller BLE       ┌────────────────────┐
│ ESP32-knude  │ <───────────────────────────> │ ESP32-knude        │
│ e-ink/knap   │                               │ sensor/knap        │
└──────┬───────┘                               └─────────┬──────────┘
       │                                                 │
       │             lokal Wi-Fi / UDP                   │
       └──────────────────────┬──────────────────────────┘
                              v
                    ┌────────────────────┐
                    │ Lejr-hub           │
                    │ Rust + lokal log   │
                    └─────────┬──────────┘
                              │ iroh/QUIC
                 når der findes en IP-forbindelse
                              v
                    ┌────────────────────┐
                    │ Hjemme- eller      │
                    │ fælleshub          │
                    └────────────────────┘
```

ESP32 og iroh har hver deres ansvar:

| Lag | Platform | Ansvar |
| --- | --- | --- |
| Brugerflade og sensorer | ESP32 | Knapper, skærm, batteri og lokal log |
| Kort lokal radio | ESP32 | ESP-NOW, BLE eller senere 802.15.4 |
| Lang rækkevidde | ESP32 + SX1262 | LoRa til små telemetri- og beskedpakker |
| Synkronisering | Linux-hub med Rust | iroh, QUIC, content addressing og replikering |

Den vigtigste arkitekturbeslutning er, at **iroh ikke forventes at køre på
selve ESP32 i første version**. iroh-stakken er normalt designet til et
Linux-agtigt Rust-miljø med `std`, Tokio og en del RAM. ESP32-firmwaren
kommunikerer derfor med en lokal Rust-hub, som står for iroh-forbindelser og
synkronisering.

## Foreslået hardware

- ESP32-C6 som knude: Wi-Fi, BLE og 802.15.4 i samme chip.
- 2,9" e-ink til tekst, status og opgaver.
- Et par knapper, en buzzer eller RGB-LED.
- SX1262 LoRa 868 MHz som valgfrit langdistancemodul.
- Beskyttet 18650/LiFePO4-celle og et lille solcelleanlæg.
- Raspberry Pi Zero 2 W, mini-PC eller tilsvarende som hub.

LoRa-modulet er ikke til billeder, tale eller store filer. Det er til korte,
robuste pakker, hvor der er brug for rækkevidde frem for båndbredde.

## Første milestone

En brugbar prototype skal kunne:

1. vise en besked på tre ESP32-knuder
2. acceptere et tryk på en knap og sende en signeret hændelse
3. gemme hændelsen lokalt og videresende den til en Rust-hub
4. køre uden internet i mindst ét døgn
5. synkronisere historikken mellem to hubs med iroh
6. genstarte uden at miste eller duplikere data

Multi-hop, LoRa og strømoptimering kommer først, når denne kæde virker.

## Designprincipper

- **Offline først:** Netværket skal give mening, når internettet er væk.
- **Små fejl:** Hver knude kan genstarte og fortsætte uden at hele netværket
  går ned.
- **Synlig teknik:** Børn og voksne skal kunne se, mærke og forstå, hvad
  enheden gør.
- **Ingen global konsensus:** Vi synkroniserer signerede hændelser og bruger
  enkle konfliktregler. Vi bygger ikke en blockchain.
- **Rigtige færdigheder:** Projektet skal lære radio, strøm, fejlfinding,
  kryptografi og distribuerede systemer gennem leg.

## Ikke i første version

- iroh direkte på ESP32
- realtidslyd eller video over mesh
- generisk internetadgang gennem netværket
- avanceret multi-hop-routing
- billeder og store filer over LoRa
- ubegrænset batterilevetid uden målinger

## Hjemmeside

Projektets offentlige side er planlagt til
[mesh.gihc.online](https://mesh.gihc.online) og følger samme grundmønster
som [GIHC-hjemmesiden](../gihc): Eleventy bygger et statisk site, som
serveres fra et security-hærdet Nginx-image i Kubernetes.

```bash
# Lokal forhåndsvisning
npm ci
npm run dev

# Byg og kontrollér den statiske side
npm run check

# Byg container lokalt
docker build -t ghcr.io/gihc-org/gihc-mesh:latest .

# DNS og deploy (kræver pass, SSH-adgang og åben tunnel til k3s)
./scripts/create-dns-record.sh
ssh -L 16443:localhost:6443 -N -f hetzner-k3s
KUBECTL_SERVER=https://127.0.0.1:16443 ./scripts/deploy.sh

# Verificér den offentlige side
./scripts/smoke-test.sh
```

Siden har dansk forside på `/`, engelsk på `/en/`, socialt previewbillede,
404-side, health endpoint og en selvstændig `gihc-mesh`-workload med
cert-manager, restricted Pod Security og ingress-begrænset netværk.
GitHub Actions bygger og scanner imageet til
`ghcr.io/gihc-org/gihc-mesh` ved push til `main`.

## Dokumentation

- [ANALYSE.md](ANALYSE.md): teknisk analyse, alternativer og risici
- [TODO.md](TODO.md): prioriteret prototypeplan og milepæle
- [INDKOB.md](INDKOB.md): indkøbsliste til den første hardware-prototype
  ([læs også på mesh.gihc.online](https://mesh.gihc.online/indkob/))

## Relation til GIHC

Projektet er beslægtet med [GIHC](../gihc), hvis formål er at gøre
modstandsdygtighed sjov for børn og voksne. Mini-mesh bør derfor både være en
teknisk øvelse og en social aktivitet: man bygger, tester og fejlfinder
sammen.
