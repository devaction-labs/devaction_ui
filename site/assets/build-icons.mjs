// Gera o sprite SVG só com os ícones aprovados (Hugeicons Stroke Rounded, free/MIT).
// Uso: npm i -D @hugeicons/core-free-icons && node build-icons.mjs icons.json priv/static/images/hugeicons.svg
import fs from "node:fs";
import * as icons from "@hugeicons/core-free-icons";

const [listPath = "icons.json", outPath = "hugeicons.svg"] = process.argv.slice(2);
const list = JSON.parse(fs.readFileSync(listPath, "utf8"));
const toExport = (name) => name.split("-").map((p) => p[0].toUpperCase() + p.slice(1)).join("") + "Icon";
const attr = (k) => k.replace(/[A-Z]/g, (c) => "-" + c.toLowerCase());

let out = '<svg xmlns="http://www.w3.org/2000/svg" style="display:none">\n';
for (const { name } of list) {
  const data = icons[toExport(name)];
  if (!data) throw new Error(`Ícone não existe no pacote free: ${name}`);
  const children = data.map(([tag, a]) =>
    `<${tag} ${Object.entries(a).filter(([k]) => !["key", "stroke", "strokeWidth", "strokeLinecap", "strokeLinejoin"].includes(k))
      .map(([k, v]) => `${attr(k)}="${v}"`).join(" ")}/>`).join("");
  out += `<symbol id="hi-${name}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">${children}</symbol>\n`;
}
fs.writeFileSync(outPath, out + "</svg>\n");
console.log(`${list.length} ícones → ${outPath}`);
