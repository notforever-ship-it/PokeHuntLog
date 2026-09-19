# PokeHuntLog

A collection log for hunter pets on Ravencraft (and other 1.12.1 servers). It records every beast you tame and groups your collection as:

- **Type**: Beast
- **Model**: the pet family (Bear, Wolf, Cat, ...)
- **Skin**: the look (Brown Bear, White Bear, ...)

Each skin shows the highest level you've gotten a pet with that skin to, out of 60.

Skins you haven't caught stay hidden. Tick **Show uncaught** to browse all 117 skins, with where to tame each one.

It also has:

- **New skin tooltips.** Hover a wild beast and its tooltip says whether that skin is new to your log or already caught.
- **Family roles.** Every family is labelled Tank, DPS, Balanced, or AoE tank for gorillas, with its health, armour and damage modifiers, abilities and diet on hover.
- **Pet stats.** Attack power, damage, attack speed, health, armour and stats are recorded for each of your pets, along with the abilities it has learned.
- **Search** by skin, creature or zone, and **export** your collection as text.
- **Ability list** covering every pet ability: each rank's pet level and training point cost, which families can learn it, and the beasts that teach it.
- **Training panel** showing your pet's unspent training points, what its family can learn, which ability ranks you have unlocked by taming, where to tame the next rank, and what your pet and hunter trainers have waiting.

**Looking for the range icon, feed reminder, swing timer or Arcane Shot icon?** Since 2.0 they live in
[Class Toolkit](https://github.com/notforever-ship-it/ClassToolkit), a separate addon with tools for every class. Install it next to PokeHuntLog.

## Quick start

1. **Download** the zip from the [latest release](https://github.com/notforever-ship-it/PokeHuntLog/releases/latest). Copy the `PokeHuntLog` folder inside it into `Interface\AddOns\` in your game folder, then fully restart the game. [Full install steps](#install).
2. **Need instructions in game?** Press **Help** at the bottom of the log, or type `/petlog help`.
3. **Open your log** with `/petlog` or the beast icon on the minimap.
4. **Add the pets you already have** by calling each one and opening the stable at a stable master once. New tames are added automatically.
5. **Want the range icon, feed reminder or swing timer?** Install [Class Toolkit](https://github.com/notforever-ship-it/ClassToolkit) as well.

Found a bug? See [Reporting bugs](#reporting-bugs).

## Install

**With an addon launcher** (RavenLaunch and similar): paste this repo's address, `https://github.com/notforever-ship-it/PokeHuntLog`, into its GitHub addon installer. The addon files sit at the top level of the repo, which is the layout launchers expect.

**By hand:**

1. Download the zip from the [latest release](https://github.com/notforever-ship-it/PokeHuntLog/releases/latest). It contains a ready-made `PokeHuntLog` folder. (If you use **Code → Download ZIP** instead, the folder inside is called `PokeHuntLog-master`; rename it to `PokeHuntLog` or the game won't load it.)
2. Copy that folder into `World of Warcraft\Interface\AddOns\`. The path should end in `Interface\AddOns\PokeHuntLog\PokeHuntLog.toc`.
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

The game doesn't tell addons which skin a pet has. The log works it out from the beast you tamed, so it can't know for pets tamed **before you installed the addon**. Those show up under **Pets with unknown skin**. To sort one out:

1. Click the pet in the list.
2. If the log can tell which beast it came from, by the abilities it knew and its level, it shows a **Best guess** and a **Use guess** button. Press it.
3. Otherwise press **Assign skin** and click the matching skin in the list. It helps to have the pet summoned so you can compare it with the 3D view.

To remove a pet from the log, Shift-click **Forget pet**.

### Hunter tools

The range icon, feed reminder, swing timer, Arcane Shot icon and ammo warnings moved to [Class Toolkit](https://github.com/notforever-ship-it/ClassToolkit) in 2.0. Your old `/petlog range`, `feed`, `swing`, `arcane`, `ammo` and `move` commands now point you there.

### Commands

| Command | What it does |
|---|---|
| `/petlog` | Open or close the log |
| `/petlog help` | Open the How to use window |
| `/petlog version` | Show which version you have |
| `/petlog uncaught` | Show or hide skins you haven't caught |
| `/petlog minimap` | Show or hide the minimap button |
| `/petlog notify` | Turn "new skin" messages on or off |
| `/petlog tooltip` | Turn the "new skin" line on beast tooltips on or off |
| `/petlog export` | Show your collection as text to copy |
| `/petlog training` | Open the Training panel |
| `/petlog trainer` | Turn training reminders on or off |
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
14. [ ] Nothing odd happens when a non-hunter logs in.
15. [ ] The How to use window opens with Help, `/petlog help` or Shift-clicking the minimap icon, and never pops up by itself. All the text fits in the window.
16. [ ] Taming a beast logs it under the right skin, with Tames going up by 1, even though the new pet is named after its family. Its details show the beast it was tamed from.
17. [ ] Hovering a wild beast shows a PokeHuntLog line saying NEW skin, caught, or not in the list.
18. [ ] Collapse all folds the list, and pressing it again opens it.
19. [ ] A non-hunter character has no minimap button.
20. [ ] Families show a role (Bear Tank, Cat DPS, Gorilla AoE tank), and hovering one shows modifiers, abilities and diet.
21. [ ] Calling a pet records its stats: its details show attack power, damage, speed, health and armour a few seconds later, plus what it knows.
22. [ ] Where to tame marks rares, fast beasts and "tameable now" for creatures at or below your level.
23. [ ] The overview shows the skins still to catch in your current zone.
24. [ ] Typing in Search filters the list; clearing it restores everything.
25. [ ] Export shows your collection as text, and Ctrl+C copies it.
26. [ ] The Training panel shows your pet's training points, what it knows, and what its family can learn.
27. [ ] After taming a beast, the panel counts the ability rank it knew as unlocked, and points at a beast for the next rank.
28. [ ] Opening a pet trainer and a hunter trainer once fills their sections of the Training panel, and levelling up reminds you when something is ready. Profession trainers are ignored.
29. [ ] The Training panel's All abilities button lists all 21 abilities with their ranks, and the list scrolls to the end without being cut off.
30. [ ] Taming a beast that teaches two abilities marks both as unlocked.

## Changelog

### 2.0.0

- **PokeHuntLog is the pet log again.** The range icon, feed reminder, swing timer, Arcane Shot icon and ammo warnings moved to [Class Toolkit](https://github.com/notforever-ship-it/ClassToolkit), a new addon with tools for every class, so a Paladin can have the swing timer too. Install both to keep everything.
- The old commands for them (`/petlog range`, `feed`, `swing`, `arcane`, `ammo`, `move`) say where they went, and hunters without Class Toolkit are told once when they log in.
- The Hunter tools button is gone from the log window.

### 1.8.2

- **Fixed a new tame being filed as your old pet** when both had the same default name and level (a Greater Plainstrider taken for an earlier White Tallstrider, both "Tallstrider", level 12). 1.8.0 threw away a tame whenever the game reported the Tame Beast channel as failed, and a successful tame can end that way. That's gone, and a pet with no experience yet now always counts as a new tame.
- **The Training panel no longer shows profession recipes.** Only pet trainers and hunter trainers are remembered, each in its own section, so visiting one no longer wipes the other. Pet trainer abilities are checked against your pet's level rather than yours.

### 1.8.1

- Added `/petlog version`, which prints the version you have in chat. Handy for checking that a launcher update arrived.

### 1.8.0

- **Fixed tames landing in "Pets with unknown skin".** The pet's name often arrives a moment before the game says a new pet appeared, and the log ignored the tame when that happened, filing the pet as unknown. It also let an old pet with the same default name (every new scorpid is called "Scorpid") swallow a new tame. A tame now counts whichever arrives first, and a namesake has to match the tamed beast's level.
- Renaming a pet with SuperWoW now updates the log, and the pet remembers the name it was first called.
- **Best guess for unknown pets:** the log works out which beast a pet came from by the abilities it knew and its level, and offers a **Use guess** button when only one skin fits.
- **Swing timer** for Auto Shot and melee, with the Auto Shot aim marked in red.
- **Arcane Shot icon** that says READY when it's off cooldown, you have the mana and the target is in range.
- New **Hunter tools** button at the bottom left holds the range, feed, swing timer and Arcane Shot switches and the icon lock, which frees up room for a wider Search box.
- Fixed "tameable now" and the teacher order for beasts with a level range starting below 10, like "9-10". Those were read as level 0.

### 1.7.1

- Windows are no longer see-through. The 1.12 dialog background art is partly transparent, so the quest tracker and chat were reading straight through the panels.
- Abilities a pet trainer sells outright (the five resistances, Great Stamina, Natural Armor, Growl) now say so, instead of "no beast in the list teaches this".
- The Training panel is wider, so ability lines no longer wrap "tameable now" onto a line of its own.
- Searching hides families with no matching skin, and shows the ones it keeps as expanded.
- Skins no longer read "Boar - Boars" when the model name is just the family in plural.

### 1.7.0

- **All abilities view** in the Training panel: every ability, each rank with the pet level and training point cost it needs, which families can learn it, and the lowest level beast that teaches it (marked when you are high enough to tame it). Ranks you have already unlocked are marked.
- **Fixed:** beasts that teach more than one ability, such as a Prairie Wolf Alpha with "Bite 2, Furious Howl 1", only counted for the first one. All of them now unlock.

### 1.6.1

- The addon files now sit at the top level of the repo instead of in a `PokeHuntLog` subfolder, so addon launchers can install straight from the GitHub address. Release zips still contain a ready-to-copy `PokeHuntLog` folder.

### 1.6.0

- **Training panel** (the Training button, or `/petlog training`):
  - your pet's unspent training points, and what it already knows
  - every ability its family can learn, with the rank it could train now and what that costs
  - which ranks you have unlocked by taming, and the lowest level beast that knows the next one
  - what your pet trainer offered last time you visited, split into ready now and coming up
- **Reminders** when your pet has unspent training points, and when abilities are waiting at your pet trainer (`/petlog trainer` to turn off).
- Pet ability ranks, the pet level each needs and its training point cost are bundled from Petopia.

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

- The addon itself lives at the repo root (`PokeHuntLog.toc` and the Lua files); `tools/` is development only and is left out of release zips.
- `Data/Skins.lua` and `Data/Families.lua` are generated by `node tools/build-skins.js`, and `Data/Abilities.lua` by `node tools/build-abilities.js`. Downloaded pages are cached in `tools/cache/`; delete that folder to fetch fresh copies.
- `node tools/check-lua.js` parses every addon file as **Lua 5.0**. It fails on syntax errors or 5.1-only features (`#`, `%`, `...`, `string.match`) and lists any unknown global names. Run it before shipping changes, since the game client is the only other way to find these errors.
- `node tools/install.js "<path to Interface\AddOns>"` copies the addon into a game install, replacing only the `PokeHuntLog` folder.

## Credits

Made by stealthzi.

Skin names, creature names, levels, zones and NPC ids come from [Petopia Classic](https://www.wow-petopia.com/classic/), the hunter pet guide. No Petopia images or text are included.

## License

[MIT](LICENSE)
