# PokeHuntLog

A collection log for hunter pets on Ravencraft (and other 1.12.1 servers). It records every beast you tame and groups your collection as:

- **Type**: Beast
- **Model**: the pet family (Bear, Wolf, Cat, ...)
- **Skin**: the look (Brown Bear, White Bear, ...)

Each skin shows the highest level you've gotten a pet with that skin to, out of 60.

Skins you haven't caught stay hidden. Tick **Show uncaught** to browse all 117 skins, with where to tame each one.

It also adds two hunter helpers:

- **Range icon.** Shows while you target something you can attack, and tells you whether you can shoot it:
  - green **In range**
  - red **Dead zone** (too close to shoot, too far to melee)
  - orange **Melee**
  - grey **Out of range**
- **New skin tooltips.** Hover a wild beast and its tooltip says whether that skin is new to your log or already caught.
- **Family roles.** Every family is labelled Tank, DPS, Balanced, or AoE tank for gorillas, with its health, armour and damage modifiers, abilities and diet on hover.
- **Pet stats.** Attack power, damage, attack speed, health, armour and stats are recorded for each of your pets, along with the abilities it has learned.
- **Search** by skin, creature or zone, and **export** your collection as text.
- **Low ammo warnings** at 200 and 50 shots.
- **Feed reminder.** A happiness face pops up when your pet drops to Content (or only at Unhappy, if you prefer), with a chat message and a sound. Click it to cast Feed Pet, then click a food in your bags.

## Quick start

1. **Download** the zip from the [latest release](https://github.com/notforever-ship-it/PokeHuntLog/releases/latest). Copy the `PokeHuntLog` folder inside it into `Interface\AddOns\` in your game folder, then fully restart the game. [Full install steps](#install).
2. **Put Auto Shot and Wing Clip on your action bars.** Any slot works, even a bar page you never show. Drag the real spells from your spellbook; macros don't count. Without them the range icon can't tell where you are. (You learn Wing Clip at level 12.)
3. **Need instructions in game?** Press **Help** at the bottom of the log, or type `/petlog help`.
4. **Open your log** with `/petlog` or the beast icon on the minimap.
5. **Add the pets you already have** by calling each one and opening the stable at a stable master once. New tames are added automatically.
6. **Move the icons:** press **Unlock icons** at the bottom of the log, drag the range icon and feed reminder where you want them, then press **Lock icons**.

Found a bug? See [Reporting bugs](#reporting-bugs).

## Install

1. On GitHub, click **Code → Download ZIP** and unzip it. You can also grab a zip from **Releases**.
2. Copy the `PokeHuntLog` folder from inside it into `World of Warcraft\Interface\AddOns\`. The path should end in `Interface\AddOns\PokeHuntLog\PokeHuntLog.toc`.
3. Fully restart the game. `/reload` doesn't pick up newly added addons.
4. On the character select screen, click **AddOns** and make sure PokeHuntLog is ticked. If it's greyed out as "out of date", tick **Load out of date AddOns**.

## Use

- Click the **beast taming icon** on the minimap, or type `/petlog`.
  - Left-click opens the log.
  - Right-click shows or hides uncaught skins.
  - Drag the icon to move it around the minimap.
- Your collection is **shared by all your hunters** on this account. Each pet remembers which hunter it belongs to.
- The first time you log in with the addon, **call your pet** and **open the stable** so it picks up the pets you already have.
- Tame something new and you'll get a "New skin collected" message.
- For instructions in game, open the **How to use** window with the **Help** button in the log, `/petlog help`, or Shift-clicking the minimap icon.

### Pets the log can't identify

The game doesn't tell addons which skin a pet has. The log works it out from the name of the beast you tamed. That can't work for pets you **renamed before installing the addon**, so they show up under **Pets with unknown skin**. To sort one out:

1. Click the pet in the list.
2. Press **Assign skin**.
3. Click the matching skin in the list. It helps to have the pet summoned so you can compare it with the 3D view.

To remove a pet from the log, Shift-click **Forget pet**.

### Range icon and feed reminder

- Turn them on or off with the **Range icon** and **Feed reminder** checkboxes at the top of the log.
- The range icon needs **Auto Shot** on one of your action bars to be accurate. Put **Wing Clip** on a bar too and it can tell melee range apart from the dead zone. Hidden bars count.
- To move them, press **Unlock icons** at the bottom of the log (or type `/petlog move`), drag them where you want, then press **Lock icons**. The feed reminder can also be Shift-dragged at any time.
- If you target something and Auto Shot isn't on your bars, the addon tells you once in chat. It does the same for Wing Clip from level 12.

### Commands

| Command | What it does |
|---|---|
| `/petlog` | Open or close the log |
| `/petlog help` | Open the How to use window |
| `/petlog uncaught` | Show or hide skins you haven't caught |
| `/petlog minimap` | Show or hide the minimap button |
| `/petlog notify` | Turn "new skin" messages on or off |
| `/petlog tooltip` | Turn the "new skin" line on beast tooltips on or off |
| `/petlog ammo` | Turn low ammo warnings on or off |
| `/petlog export` | Show your collection as text to copy |
| `/petlog range` | Turn the range icon on or off |
| `/petlog feed` | Turn the feed reminder on or off |
| `/petlog feed content` / `/petlog feed unhappy` | Remind when the pet is Content or worse (default), or only when Unhappy |
| `/petlog feed sound` | Turn the reminder sound on or off |
| `/petlog move` | Unlock or lock the range icon and feed reminder (same as the Unlock icons button) |
| `/petlog scan` | Re-check your current pet |
| `/petlog unassign <pet name>` | Clear a pet's skin so you can pick it again |
| `/petlog forget <pet name>` | Remove a saved pet |
| `/petlog debug` | Print pet and target details (useful for bug reports) |
| `/petlog reset` | Delete the whole log (asks you to confirm) |

## How it works

- **Tames.** When you cast Tame Beast, the addon remembers the beast (name, family, level, zone). The pet that appears moments later is logged as that beast, and the beast's name is kept as the pet's "tamed from" name. This works even though the game names new pets after their family (taming a Clattering Scorpid gives a pet called "Scorpid").
- **SuperWoW.** If you run SuperWoW, the addon also reads the creature's ID, which pins down the skin exactly. Without it, skins are matched by creature name. That's still reliable, because no creature name is shared between two skins in the database.
- **Custom beasts.** A beast that isn't in the database (for example a custom Ravencraft beast) is added as a new skin named after the creature when you tame it.
- **Levels.** Levels are updated whenever your pet levels up, whenever you call it, and whenever you open the stable.
- **Pictures.** The detail panel shows a rotating 3D view of your current pet when you select its skin. Other entries show the family icon. The 1.12 game client can't draw a creature you don't have out.

## In-game test checklist

So far the addon has been confirmed to load on Ravencraft, and the log window works. Everything else on this list still needs checking in game, so please try these and report anything odd. For bug reports, include the output of `/petlog debug` and any red error text. Error popups only show if **Interface Options → Display Lua Errors** is on; `/console scriptErrors 1` also works.

1. [ ] The addon loads with no error popup, and the minimap icon appears.
2. [ ] `/petlog` opens the window. It can be dragged, it closes with Escape and the X, and it reopens where you left it.
3. [ ] With no pets logged, the list says "No pets logged yet".
4. [ ] Ticking **Show uncaught** lists Beast → 17 families → skins in grey. Clicking a skin shows "Where to tame".
5. [ ] Calling your existing pet adds it. Unrenamed pets land under the right skin; renamed ones land under "Pets with unknown skin".
6. [ ] Opening the stable adds your stabled pets.
7. [ ] **Assign skin** on an unknown pet, then clicking a skin of the same family, moves it into the collection.
8. [ ] Taming a new beast prints "New skin collected" (for a skin you didn't have), and the tame count goes up by 1.
9. [ ] Selecting the skin of the pet you have out shows it rotating in 3D.
10. [ ] When your pet levels up, the level shown for its skin updates.
11. [ ] Renaming your pet keeps it under the same skin, with no duplicate entry.
12. [ ] Logging in on another hunter shows the same collection, and new pets are tagged with that hunter.
13. [ ] **SuperWoW only:** `/petlog debug` with a beast targeted shows an npc id, and the id matches the creature on Wowhead Classic. If it doesn't, send the output: the GUID parsing may need a one-line fix.
14. [ ] Nothing odd happens when a non-hunter logs in, and the range icon and feed reminder never show for them.
15. [ ] With Auto Shot on a bar, targeting a mob shows the range icon. It reads green In range at shooting distance, red Dead zone just outside melee, orange Melee when touching it (needs Wing Clip on a bar), and grey Out of range when far away.
16. [ ] The range icon hides when you clear your target or the target dies.
17. [ ] When your pet drops from Happy to Content, the happiness face appears with a chat message and sound. Clicking it starts Feed Pet, and the icon hides while the pet eats and once it's Happy again.
18. [ ] **Unlock icons** lets you drag both icons, and the button then says Lock icons. They stay where you put them after `/reload`.
19. [ ] The How to use window opens with Help, `/petlog help` or Shift-clicking the minimap icon, and never pops up by itself. All the text fits in the window.
20. [ ] With Auto Shot removed from your bars, targeting an enemy prints a one-time hint to put it on a bar.
21. [ ] Taming a beast logs it under the right skin, with Tames going up by 1, even though the new pet is named after its family. Its details show the beast it was tamed from.
22. [ ] Hovering a wild beast shows a PokeHuntLog line saying NEW skin, caught, or not in the list.
23. [ ] Collapse all folds the list, and pressing it again opens it.
24. [ ] A non-hunter character has no minimap button.
25. [ ] Families show a role (Bear Tank, Cat DPS, Gorilla AoE tank), and hovering one shows modifiers, abilities and diet.
26. [ ] Calling a pet records its stats: its details show attack power, damage, speed, health and armour a few seconds later, plus what it knows.
27. [ ] Where to tame marks rares, fast beasts and "tameable now" for creatures at or below your level.
28. [ ] The overview shows the skins still to catch in your current zone.
29. [ ] Typing in Search filters the list; clearing it restores everything.
30. [ ] Export shows your collection as text, and Ctrl+C copies it.
31. [ ] Hovering the feed face gives advice, and low ammo warns once at 200 and once at 50 shots.

## Changelog

### 1.5.0

- **Family roles and stats.** Each family shows Tank, DPS, Balanced or AoE tank in the list, and hovering shows its health, armour and damage modifiers, trainable abilities and diet.
- **Pet stats.** Attack power, damage, attack speed, health, armour, strength, agility and stamina are recorded a couple of seconds after a pet is called, plus the abilities it has learned.
- **Rare and fast creatures.** Where to tame now marks rares and elites, shows attack speed for fast beasts (Broken Tooth is 1.0), and flags creatures you are high enough level to tame.
- **Zone progress.** The overview shows how many skins of the zone you are standing in you still need, and names a few.
- **Search box** for skin, creature and zone names.
- **Export** button and `/petlog export` for a text version of your collection.
- **Milestones** in chat at 5, 10, 25, 50, 75 and 100 skins, when a family is completed, and for your first level 60 pet.
- **Feeding advice.** The game never tells addons the hidden happiness number, so the reminder tracks how long your pet has been at its current level: at Content a full meal fits with nothing wasted.
- **Low ammo warnings** at 200 and 50 shots (`/petlog ammo` to turn off).
- **A warning** when you abandon the only pet you have with a given skin.

### 1.4.0

- **Fixed: tames weren't being logged.** New pets are named after their family on this server (a tamed Clattering Scorpid is called "Scorpid"), so matching by name never worked and pets landed under "Pets with unknown skin" with the tame count stuck at 0. Tames are now matched by family and timing.
- Each pet now records the beast it was tamed from, shown in its details and next to the pets on a skin.
- Added the "new skin" line on beast tooltips (`/petlog tooltip` to turn it off).
- Added a **Collapse all** button.
- The minimap button now only appears for hunters.

### 1.3.3

- Fixed the debug log repeating the action bar line over and over. Debug messages stay off unless you turn them on with `/petlog debug on`.

### 1.3.2

- The How to use window no longer pops up when you log in. Open it with the Help button, `/petlog help` or Shift-clicking the minimap icon.

### 1.3.1

- Removed the !PokeBugLog companion addon. If you installed it, you can delete the `!PokeBugLog` folder from `Interface\AddOns\`.

### 1.3.0

- Added a **How to use** window. It opens on your first hunter login, and afterwards with the Help button, `/petlog help` or Shift-clicking the minimap icon.
- Added **Unlock icons / Lock icons** buttons for moving the range icon and feed reminder.
- Added a one-time chat hint when Auto Shot (or Wing Clip, from level 12) isn't on your action bars.

### 1.2.1

- Works with the new **!PokeBugLog** addon: PokeHuntLog's messages and a trail of what it notices (tames, pet scans, stable pets, action bar slots) are saved there for bug reports.

### 1.2.0

- Renamed the addon to **PokeHuntLog**. The folder is now `PokeHuntLog`.
- To update, **delete the old `HunterPetLog` folder** from `Interface\AddOns\` before adding `PokeHuntLog`, or both will load. Then restart the game; `/reload` doesn't pick up a renamed addon.
- Saved data is stored under the new name, so the log starts fresh.

### 1.1.1

- Added "Made by stealthzi" at the bottom of the log window.

### 1.1.0

- Added the range icon: In range, Dead zone, Melee or Out of range while you target something you can attack.
- Added the pet feed reminder: a happiness face with a chat message and sound when your pet stops being happy. Click it to cast Feed Pet.
- Added Range icon and Feed reminder checkboxes to the log window, plus the `/petlog range`, `/petlog feed` and `/petlog move` commands.

### 1.0.0

- First version: the pet collection log (Type → Family → Skin, highest level per skin, uncaught skins hidden, 3D view of your current pet, assigning skins by hand).

## Reporting bugs

1. Type `/console scriptErrors 1` once, so Lua errors pop up on screen.
2. When something goes wrong, screenshot any error box. Also type `/petlog debug` with your pet out or your target selected.
3. [Open an issue](https://github.com/notforever-ship-it/PokeHuntLog/issues) with the screenshot and what you did, what you expected, and what happened.

## For developers

- `PokeHuntLog/Data/Skins.lua` is generated. To rebuild it, run `node tools/build-skins.js`. Downloaded pages are cached in `tools/cache/`; delete that folder to download fresh copies.
- `node tools/check-lua.js` parses every addon file as **Lua 5.0**. It fails on syntax errors or 5.1-only features (`#`, `%`, `...`, `string.match`) and lists any unknown global names. Run it before shipping changes, since the game client is the only other way to find these errors.
- `node tools/install.js "<path to Interface\AddOns>"` copies the addon into a game install, replacing only the `PokeHuntLog` folder.

## Credits

Made by stealthzi.

Skin names, creature names, levels, zones and NPC ids come from [Petopia Classic](https://www.wow-petopia.com/classic/), the hunter pet guide. No Petopia images or text are included.

## License

[MIT](LICENSE)
