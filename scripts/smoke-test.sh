#!/usr/bin/env bash
set -euo pipefail

# Verificerer mini-mesh-siden udefra.
#
# Brug:
#   ./scripts/smoke-test.sh
#   ./scripts/smoke-test.sh http://127.0.0.1:8080

BASE_URL="${1:-https://mesh.gihc.online}"
BASE_URL="${BASE_URL%/}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

echo "==> Tester ${BASE_URL}"

curl -fsS --max-time 20 "${BASE_URL}/" -o "${TMP_DIR}/index.html"
curl -fsS --max-time 20 "${BASE_URL}/en/" -o "${TMP_DIR}/index-en.html"
curl -fsS --max-time 20 "${BASE_URL}/assets/mesh-mark.svg" \
    -o "${TMP_DIR}/mesh-mark.svg" \
    -D "${TMP_DIR}/mark-headers.txt"
curl -fsS --max-time 20 "${BASE_URL}/assets/mesh-og.png" \
    -o "${TMP_DIR}/mesh-og.png" \
    -D "${TMP_DIR}/og-headers.txt"

grep -q '<title>GIHC Mini-Mesh — Budstikken</title>' \
    "${TMP_DIR}/index.html" || fail "forsidens titel mangler"
grep -q 'Et lille net,' "${TMP_DIR}/index.html" \
    || fail "den danske hero-tekst mangler"
grep -q 'ESP32' "${TMP_DIR}/index.html" \
    || fail "ESP32-arkitekturen mangler"
grep -q 'iroh' "${TMP_DIR}/index.html" \
    || fail "iroh-arkitekturen mangler"
grep -q 'https://mesh.gihc.online/' "${TMP_DIR}/index.html" \
    || fail "canonical mesh-adresse mangler"
grep -q 'https://github.com/gihc-org/gihc-mesh/blob/main/README.md' "${TMP_DIR}/index.html" \
    || fail "README-link mangler"
grep -q 'mailto:mail@gihc.online' "${TMP_DIR}/index.html" \
    || fail "e-mailkontakt mangler"
grep -q '<html lang="en">' "${TMP_DIR}/index-en.html" \
    || fail "engelsk sprogkode mangler"
grep -q 'A small network,' "${TMP_DIR}/index-en.html" \
    || fail "engelsk hero-tekst mangler"
grep -q 'href="/"' "${TMP_DIR}/index-en.html" \
    || fail "sprogskift til dansk mangler"
grep -q 'href="/en/"' "${TMP_DIR}/index.html" \
    || fail "sprogskift til engelsk mangler"
grep -qi '^content-type: image/svg+xml' "${TMP_DIR}/mark-headers.txt" \
    || fail "mesh-mark serveres ikke som image/svg+xml"
grep -q '<svg' "${TMP_DIR}/mesh-mark.svg" \
    || fail "mesh-mark er ikke SVG"
grep -qi '^content-type: image/png' "${TMP_DIR}/og-headers.txt" \
    || fail "socialt previewbillede serveres ikke som image/png"
[ "$(head -c 8 "${TMP_DIR}/mesh-og.png" | od -An -tx1 | tr -d ' \n')" = "89504e470d0a1a0a" ] \
    || fail "socialt previewbillede er ikke en PNG"

curl -fsS --max-time 20 "${BASE_URL}/healthz" \
    | grep -qx 'ok' || fail "health endpoint svarer ikke ok"

STATUS="$(curl -sS --max-time 20 -o /dev/null -w '%{http_code}' "${BASE_URL}/not-here")"
[ "$STATUS" = "404" ] || fail "ukendt sti giver HTTP ${STATUS}, forventet 404"

curl -fsS --max-time 20 -D "${TMP_DIR}/headers.txt" \
    -o /dev/null "${BASE_URL}/"
grep -qi '^content-security-policy:' "${TMP_DIR}/headers.txt" \
    || fail "Content-Security-Policy mangler"
grep -qi '^x-content-type-options: nosniff' "${TMP_DIR}/headers.txt" \
    || fail "X-Content-Type-Options mangler"
grep -qi '^x-frame-options: DENY' "${TMP_DIR}/headers.txt" \
    || fail "X-Frame-Options mangler"

if [[ "$BASE_URL" == https://* ]]; then
    curl -fsS --max-time 20 -o /dev/null \
        -w 'TLS verify result: %{ssl_verify_result}\n' "${BASE_URL}/" \
        | grep -q 'TLS verify result: 0' \
        || fail "TLS-certifikatet kunne ikke verificeres"
fi

echo "PASS: dansk og engelsk forside, diagram, dokumentlinks, health, 404, sikkerhedsheadere og TLS er OK"
