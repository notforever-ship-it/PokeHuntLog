// Builds PokeHuntLog/Data/Skins.lua from Petopia Classic (https://www.wow-petopia.com/classic/).
// Only factual data is kept: skin names, creature names, NPC ids, levels, zones.
// Usage: node tools/build-skins.js   (pages are cached in tools/cache, delete it to refetch)

const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "..");
const CACHE = path.join(__dirname, "cache");
const OUT = path.join(ROOT, "PokeHuntLog", "Data", "Skins.lua");
const BASE = "https://www.wow-petopia.com/classic/";

// Petopia family slug -> in-game UnitCreatureFamily() name
const FAMILIES = [
  ["bat", "Bat"], ["bear", "Bear"], ["boar", "Boar"], ["carrionbird", "Carrion Bird"],
  ["cat", "Cat"], ["crab", "Crab"], ["crocolisk", "Crocolisk"], ["gorilla", "Gorilla"],
  ["hyena", "Hyena"], ["owl", "Owl"], ["raptor", "Raptor"], ["scorpid", "Scorpid"],
  ["spider", "Spider"], ["tallstrider", "Tallstrider"], ["turtle", "Turtle"],
  ["windserpent", "Wind Serpent"], ["wolf", "Wolf"],
];

const SKIP_STATUS = /unused|untamable|untameable/i;

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function get(url, cacheName) {
  const file = path.join(CACHE, cacheName);
  if (fs.existsSync(file)) return fs.readFileSync(file, "utf8");
  for (let attempt = 1; ; attempt++) {
    await sleep(300 * attempt);
    try {
      const res = await fetch(url, { headers: { "User-Agent": "Mozilla/5.0 (PokeHuntLog data build)" } });
      if (!res.ok) throw new Error(`${res.status} fetching ${url}`);
      const html = await res.text();
      fs.writeFileSync(file, html);
      return html;
    } catch (e) {
      if (attempt >= 5) throw e;
      console.warn(`  retry ${attempt} for ${url}: ${e.message}`);
      await sleep(2000 * attempt);
    }
  }
}

function decode(s) {
  return s
    .replace(/&#0*39;|&apos;/g, "'")
    .replace(/&quot;/g, '"')
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&#(\d+);/g, (_, n) => String.fromCharCode(Number(n)))
    .trim();
}

function stripTags(s) {
  return decode(s.replace(/<br\s*\/?>/gi, " ").replace(/<[^>]*>/g, " ").replace(/\s+/g, " "));
}

function parseFamily(html, slug) {
  const looks = [];
  const statuses = {};
  const sections = html.split("<h3 class='family_model_subheading").slice(1);
  for (const sec of sections) {
    const modelName = decode((sec.match(/^[^>]*>([^<]*)/) || [, "?"])[1]);
    for (const block of sec.split("<div class='model_looks_big_thumb").slice(1)) {
      const m = block.match(/<a href='look\.php\?id=([^']+)'[^>]*>\s*<img[^>]*alt='([^']*)'/);
      if (!m) continue;
      const status = block.match(/look_status_icon'[^>]*alt='([^']*)'/);
      if (status) {
        statuses[status[1]] = (statuses[status[1]] || 0) + 1;
        if (SKIP_STATUS.test(status[1])) continue;
      }
      looks.push({ id: m[1], name: decode(m[2]), model: modelName, family: slug });
    }
  }
  return { looks, statuses };
}

function parseLook(html) {
  const npcs = [];
  const tameAlts = {};
  for (const row of html.split("<tr class='petstats").slice(1)) {
    const name = row.match(/class='pettablename'>([^<]*)</);
    if (!name) continue;
    const tame = row.match(/class='tameableicon'>\s*<img[^>]*alt='([^']*)'/);
    const alt = tame ? tame[1] : "(none)";
    tameAlts[alt] = (tameAlts[alt] || 0) + 1;
    if (tame && !/can be tamed|hunters only/i.test(alt)) continue;
    const factionTag = /horde/i.test(alt) ? "Horde only" : /alliance/i.test(alt) ? "Alliance only" : "";
    const levelCell = stripTags((row.match(/<td class='level'>([\s\S]*?)<\/td>/) || [, ""])[1]);
    const level = (levelCell.match(/\d+(?:\s*-\s*\d+)?/) || [""])[0].replace(/\s+/g, "");
    const tag = [levelCell.replace(/\d+(?:\s*-\s*\d+)?/, "").trim(), factionTag].filter(Boolean).join(", ");
    const zone = stripTags((row.match(/<td class='zone'>([\s\S]*?)<\/td>/) || [, ""])[1]);
    const npc = row.match(/npc=(\d+)/);
    npcs.push({ id: npc ? Number(npc[1]) : 0, name: decode(name[1]), level, zone, tag });
  }
  return { npcs, tameAlts };
}

function luaStr(s) {
  return '"' + String(s).replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\n/g, " ") + '"';
}

async function main() {
  fs.mkdirSync(CACHE, { recursive: true });
  fs.mkdirSync(path.dirname(OUT), { recursive: true });

  const allStatuses = {};
  const allTameAlts = {};
  const skins = [];

  for (const [slug, apiName] of FAMILIES) {
    const html = await get(`${BASE}family.php?id=${slug}`, `family_${slug}.html`);
    const { looks, statuses } = parseFamily(html, slug);
    Object.entries(statuses).forEach(([k, v]) => (allStatuses[k] = (allStatuses[k] || 0) + v));
    for (const look of looks) {
      const lookHtml = await get(`${BASE}look.php?id=${look.id}`, `look_${look.id}.html`);
      const { npcs, tameAlts } = parseLook(lookHtml);
      Object.entries(tameAlts).forEach(([k, v]) => (allTameAlts[k] = (allTameAlts[k] || 0) + v));
      if (npcs.length === 0) {
        console.warn(`  skip ${look.id} (${look.name}): no tameable NPCs`);
        continue;
      }
      skins.push({ ...look, familyName: apiName, npcs });
    }
    console.log(`${apiName}: ${looks.length} looks`);
  }

  const lines = [];
  lines.push("-- PokeHuntLog skin database.");
  lines.push("-- Generated by tools/build-skins.js from Petopia Classic (https://www.wow-petopia.com/classic/).");
  lines.push("-- Do not edit by hand; rerun the script instead.");
  lines.push("-- Each skin: family, model, skin id, skin name, then NPCs as { npcId, name, level, zone, tag }.");
  lines.push("");
  lines.push("PokeHuntLog_Skins = {}");
  lines.push("");
  lines.push("local function add(family, model, id, name, npcs)");
  lines.push("  table.insert(PokeHuntLog_Skins, { family = family, model = model, id = id, name = name, npcs = npcs })");
  lines.push("end");
  lines.push("");
  for (const s of skins) {
    lines.push(`add(${luaStr(s.familyName)}, ${luaStr(s.model)}, ${luaStr(s.id)}, ${luaStr(s.name)}, {`);
    for (const n of s.npcs) {
      lines.push(`  { ${n.id}, ${luaStr(n.name)}, ${luaStr(n.level)}, ${luaStr(n.zone)}, ${luaStr(n.tag)} },`);
    }
    lines.push("})");
  }
  lines.push("");
  fs.writeFileSync(OUT, lines.join("\n"));

  const npcCount = skins.reduce((a, s) => a + s.npcs.length, 0);
  console.log(`\nWrote ${skins.length} skins, ${npcCount} NPCs -> ${path.relative(ROOT, OUT)}`);
  console.log("Look statuses seen:", allStatuses);
  console.log("Tameable icon alts seen:", allTameAlts);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
