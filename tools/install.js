// Copies the addon from this project into the game's AddOns folder, replacing only its own folder.
// Usage: node tools/install.js [path to Interface\AddOns]

const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "..");
const ADDONS = ["PokeHuntLog"];
const target = path.resolve(process.argv[2] || "E:\\Ravencraft\\twmoa_1181\\Interface\\AddOns");

if (!fs.existsSync(target)) {
  console.error(`AddOns folder not found: ${target}`);
  process.exit(1);
}

for (const name of ADDONS) {
  const src = path.join(ROOT, name);
  if (!fs.existsSync(path.join(src, `${name}.toc`))) {
    console.error(`${name} is missing from the project (was it moved?). Restore it with: git checkout -- "${name}"`);
    process.exit(1);
  }
}

for (const name of ADDONS) {
  const src = path.join(ROOT, name);
  const dest = path.join(target, name);
  fs.rmSync(dest, { recursive: true, force: true });
  fs.cpSync(src, dest, { recursive: true });
  const count = fs.readdirSync(dest, { recursive: true }).filter((f) => fs.statSync(path.join(dest, f)).isFile()).length;
  const version = (fs.readFileSync(path.join(dest, `${name}.toc`), "utf8").match(/## Version:\s*(\S+)/) || [])[1];
  console.log(`Installed ${name} ${version} (${count} files) -> ${dest}`);
}
