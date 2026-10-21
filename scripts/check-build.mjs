import { access, readFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import path from "node:path";

const outputDir = "_site";
const requiredFiles = [
  "index.html",
  "en/index.html",
  "indkob/index.html",
  "en/indkob/index.html",
  "404.html",
  "assets/styles.css",
  "assets/favicon.svg",
  "assets/gihc-emblem.svg",
  "assets/mesh-mark.svg",
  "assets/mesh-og.png"
];

for (const file of requiredFiles) {
  await access(path.join(outputDir, file));
}

const index = await readFile(path.join(outputDir, "index.html"), "utf8");
const englishIndex = await readFile(path.join(outputDir, "en/index.html"), "utf8");
const shopping = await readFile(path.join(outputDir, "indkob/index.html"), "utf8");
const englishShopping = await readFile(path.join(outputDir, "en/indkob/index.html"), "utf8");
const notFound = await readFile(path.join(outputDir, "404.html"), "utf8");

const expectations = [
  ["dokumentets sprog", index.includes('<html lang="da">')],
  ["sidens titel", index.includes("<title>GIHC Mini-Mesh — Budstikken</title>")],
  ["dansk hero", index.includes("Et lille net,") && index.includes("når det store falder.")],
  ["arkitektur", index.includes("ESP32") && index.includes("iroh") && index.includes("Linux-hub")],
  ["status", index.includes("Idé og systemdesign") && index.includes("3 knuder")],
  ["dansk sprogskift", index.includes('href="/en/"') && index.includes('hreflang="en"')],
  ["engelsk sprogkode", englishIndex.includes('<html lang="en">')],
  ["engelsk hero", englishIndex.includes("A small network,") && englishIndex.includes("when the big one falls.")],
  ["engelsk sprogskift", englishIndex.includes('href="/"') && englishIndex.includes('hreflang="da"')],
  ["canonical", index.includes('<link rel="canonical" href="https://mesh.gihc.online/">')],
  ["socialt previewbillede", index.includes('property="og:image" content="https://mesh.gihc.online/assets/mesh-og.png"') && index.includes('property="og:image:width" content="1200"') && index.includes('property="og:image:height" content="630"')],
  ["Twitter-previewbillede", index.includes('name="twitter:image" content="https://mesh.gihc.online/assets/mesh-og.png"')],
  ["dokumentlinks", index.includes("github.com/gihc-org/gihc-mesh/blob/main/README.md") && index.includes("ANALYSE.md") && index.includes("TODO.md")],
  ["link til indkøbssiden", index.includes('href="/indkob/"')],
  ["dansk indkøbsside", shopping.includes("<title>Indkøbsliste — GIHC Mini-Mesh</title>") && shopping.includes("1.600-2.700 kr.") && shopping.includes("ESP32-C6-DevKitC-1")],
  ["engelsk indkøbsside", englishShopping.includes("<title>Shopping list — GIHC Mini-Mesh</title>") && englishShopping.includes("DKK 1,600-2,700") && englishShopping.includes("ESP32-C6-DevKitC-1")],
  ["indkøbssidens sprogskift", shopping.includes('href="/en/indkob/"') && englishShopping.includes('href="/indkob/"')],
  ["indkøbssidens canonical", shopping.includes('<link rel="canonical" href="https://mesh.gihc.online/indkob/">') && englishShopping.includes('<link rel="canonical" href="https://mesh.gihc.online/en/indkob/">')],
  ["404-indhold", notFound.includes("Knuden findes ikke.")],
  ["ingen Nunjucks-rester", [index, englishIndex, shopping, englishShopping].every((html) => !html.includes("{{") && !html.includes("{%"))]
];

for (const [label, passed] of expectations) {
  if (!passed) {
    throw new Error(`Build check failed: ${label}`);
  }
}

for (const [name, html] of [
  ["dansk", index],
  ["engelsk", englishIndex],
  ["dansk indkøb", shopping],
  ["engelsk indkøb", englishShopping]
]) {
  const ids = [...html.matchAll(/\sid="([^"]+)"/g)].map((match) => match[1]);
  const duplicateIds = ids.filter((id, index) => ids.indexOf(id) !== index);
  if (duplicateIds.length > 0) {
    throw new Error(`Duplicate HTML ids in ${name}: ${[...new Set(duplicateIds)].join(", ")}`);
  }

  for (const match of html.matchAll(/(?:href|src)="(\/[^"#?]+)"/g)) {
    const target = match[1];
    if (target === "/") continue;
    if (!existsSync(path.join(outputDir, target))) {
      throw new Error(`Broken local URL in ${name} HTML: ${target}`);
    }
  }
}

const socialImage = await readFile(path.join(outputDir, "assets/mesh-og.png"));
const pngSignature = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
if (!socialImage.subarray(0, pngSignature.length).equals(pngSignature)) {
  throw new Error("Open Graph image is not a PNG file");
}
const width = socialImage.readUInt32BE(16);
const height = socialImage.readUInt32BE(20);
if (width !== 1200 || height !== 630) {
  throw new Error(`Open Graph image has unexpected dimensions: ${width}x${height}`);
}

console.log("PASS: Eleventy build, dansk og engelsk indhold, links og assets er OK");
