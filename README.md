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
- **Feed reminder.** A happiness face pops up when your pet drops to Content (or only at Unhappy, if you prefer), with a chat message and a sound. Click it to cast Feed Pet, then click a food in your bags.

## Install

1. Copy the `PokeHuntLog` folder into `World of Warcraft\Interface\AddOns\`. The path should end in `Interface\AddOns\PokeHuntLog\PokeHuntLog.toc`.
2. Restart the game, or type `/reload` if it's already running.
3. On the character select screen, click **AddOns** and make sure PokeHuntLog is ticked. If it's greyed out as "out of date", tick **Load out of date AddOns**.

## Use

- Click the **beast taming icon** on the minimap, or type `/petlog`.
  - Left-click opens the log.
  - Right-click shows or hides uncaught skins.
  - Drag the icon to move it around the minimap.
- Your collection is **shared by all your hunters** on this account. Each pet remembers which hunter it belongs to.
- The first time you log in with the addon, **call your pet** and **open the stable** so it picks up the pets you already have.
- Tame something new and you'll get a "New skin collected" message.

### Pets the log can't identify

The game doesn't tell addons which skin a pet has. The log works it out from the name of the beast you tamed. That can't work for pets you **renamed before installing the addon**, so they show up under **Pets with unknown skin**. To sort one out:

1. Click the pet in the list.
2. Press **Assign skin**.
3. Click the matching skin in the list. It helps to have the pet summoned so you can compare it with the 3D view.

To remove a pet from the log, Shift-click **Forget pet**.

### Range icon and feed reminder

- Turn them on or off with the **Range icon** and **Feed reminder** checkboxes at the top of the log.
- The range icon needs **Auto Shot** on one of your action bars to be accurate. Put **Wing Clip** on a bar too and it can tell melee range apart from the dead zone. Hidden bars count.
- To move them, type `/petlog move`, drag them, and type `/petlog move` again to lock them. The feed reminder can also be Shift-dragged at any time.

### Commands

| Command | What it does |
|---|---|
| `/petlog` | Open or close the log |
| `/petlog uncaught` | Show or hide skins you haven't caught |
| `/petlog minimap` | Show or hide the minimap button |
| `/petlog notify` | Turn "new skin" messages on or off |
| `/petlog range` | Turn the range icon on or off |
| `/petlog feed` | Turn the feed reminder on or off |
| `/petlog feed content` / `/petlog feed unhappy` | Remind when the pet is Content or worse (default), or only when Unhappy |
| `/petlog feed sound` | Turn the reminder sound on or off |
| `/petlog move` | Unlock the range icon and feed reminder so you can drag them |
| `/petlog scan` | Re-check your current pet |
| `/petlog unassign <pet name>` | Clear a pet's skin so you can pick it again |
| `/petlog forget <pet name>` | Remove a saved pet |
| `/petlog debug` | Print pet and target details (useful for bug reports) |
| `/petlog reset` | Delete the whole log (asks you to confirm) |

## How it works

- **Tames.** When you cast Tame Beast, the addon remembers the beast (name, family, level, zone). When a pet with that name appears, it's logged as a new tame.
- **SuperWoW.** If you run SuperWoW, the addon also reads the creature's ID, which pins down the skin exactly. Without it, skins are matched by creature name. That's still reliable, because no creature name is shared between two skins in the database.
- **Custom beasts.** A beast that isn't in the database (for example a custom Ravencraft beast) is added as a new skin named after the creature when you tame it.
- **Levels.** Levels are updated whenever your pet levels up, whenever you call it, and whenever you open the stable.
- **Pictures.** The detail panel shows a rotating 3D view of your current pet when you select its skin. Other entries show the family icon. The 1.12 game client can't draw a creature you don't have out.

## In-game test checklist

Nothing has been run in the game yet, so please try these and report anything odd. For bug reports, include the output of `/petlog debug` and any red error text. Error popups only show if **Interface Options → Display Lua Errors** is on; `/console scriptErrors 1` also works.

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
18. [ ] `/petlog move` lets you drag both icons, and they stay where you put them after `/reload`.

## Changelog

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

## For developers

- `PokeHuntLog/Data/Skins.lua` is generated. To rebuild it, run `node tools/build-skins.js`. Downloaded pages are cached in `tools/cache/`; delete that folder to download fresh copies.
- `node tools/check-lua.js` parses every addon file as **Lua 5.0**. It fails on syntax errors or 5.1-only features (`#`, `%`, `...`, `string.match`) and lists any unknown global names. Run it before shipping changes, since the game client is the only other way to find these errors.

## Credits

Skin names, creature names, levels, zones and NPC ids come from [Petopia Classic](https://www.wow-petopia.com/classic/), the hunter pet guide. No Petopia images or text are included.
