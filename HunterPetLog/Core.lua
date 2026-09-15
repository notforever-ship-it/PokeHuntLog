-- Hunter Pet Log: shared namespace, saved variables, helpers and slash commands.
-- Target client is WoW 1.12.1 (Lua 5.0): no '#', no '%', no string.match, varargs via 'arg'.

HunterPetLog = {}
local HPL = HunterPetLog

HPL.VERSION = "1.0.0"
HPL.DB_VERSION = 1
HPL.MAX_LEVEL = 60
HPL.TAME_BEAST_SPELL_ID = 1515
HPL.TAME_BEAST_NAME = "Tame Beast"
HPL.TAME_WINDOW = 60          -- seconds between starting Tame Beast and the pet appearing
HPL.PREFIX = "|cffabd473Hunter Pet Log:|r "

HPL.FAMILY_ICONS = {
  ["Bat"] = "Ability_Hunter_Pet_Bat",
  ["Bear"] = "Ability_Hunter_Pet_Bear",
  ["Boar"] = "Ability_Hunter_Pet_Boar",
  ["Carrion Bird"] = "Ability_Hunter_Pet_Vulture",
  ["Cat"] = "Ability_Hunter_Pet_Cat",
  ["Crab"] = "Ability_Hunter_Pet_Crab",
  ["Crocolisk"] = "Ability_Hunter_Pet_Crocolisk",
  ["Gorilla"] = "Ability_Hunter_Pet_Gorilla",
  ["Hyena"] = "Ability_Hunter_Pet_Hyena",
  ["Owl"] = "Ability_Hunter_Pet_Owl",
  ["Raptor"] = "Ability_Hunter_Pet_Raptor",
  ["Scorpid"] = "Ability_Hunter_Pet_Scorpid",
  ["Spider"] = "Ability_Hunter_Pet_Spider",
  ["Tallstrider"] = "Ability_Hunter_Pet_Tallstrider",
  ["Turtle"] = "Ability_Hunter_Pet_Turtle",
  ["Wind Serpent"] = "Ability_Hunter_Pet_WindSerpent",
  ["Wolf"] = "Ability_Hunter_Pet_Wolf",
}
HPL.UNKNOWN_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

function HPL.Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage(HPL.PREFIX .. tostring(msg))
end

function HPL.Debug(msg)
  if HPL.db and HPL.db.settings.debug then
    DEFAULT_CHAT_FRAME:AddMessage("|cff888888[HPL debug]|r " .. tostring(msg))
  end
end

function HPL.FamilyIcon(family)
  local icon = family and HPL.FAMILY_ICONS[family]
  if icon then
    return "Interface\\Icons\\" .. icon
  end
  return HPL.UNKNOWN_ICON
end

-- Lowercase and strip everything but letters and digits, for lookup keys.
function HPL.Key(s)
  if not s then return "" end
  local k = string.gsub(s, "[^%w]", "")
  return string.lower(k)
end

function HPL.CharKey()
  return (UnitName("player") or "?") .. " - " .. (GetRealmName() or "?")
end

function HPL.CharName(charKey)
  if not charKey then return "?" end
  local dash = string.find(charKey, " - ", 1, true)
  if dash then
    return string.sub(charKey, 1, dash - 1)
  end
  return charKey
end

function HPL.IsHunter()
  local _, class = UnitClass("player")
  return class == "HUNTER"
end

function HPL.FormatDate(t)
  if not t then return "?" end
  return date("%d %b %Y", t)
end

-- Run func once after 'seconds'. Uses one shared frame whose OnUpdate is removed when idle.
local timers = {}
local timerFrame = CreateFrame("Frame")
local function TimerUpdate()
  local now = GetTime()
  local i = 1
  while i <= table.getn(timers) do
    local t = timers[i]
    if now >= t.at then
      table.remove(timers, i)
      local ok, err = pcall(t.func)
      if not ok then HPL.Print("error: " .. tostring(err)) end
    else
      i = i + 1
    end
  end
  if table.getn(timers) == 0 then
    timerFrame:SetScript("OnUpdate", nil)
  end
end

function HPL.After(seconds, func)
  table.insert(timers, { at = GetTime() + seconds, func = func })
  timerFrame:SetScript("OnUpdate", TimerUpdate)
end

-- SuperWoW GUIDs look like "0xF13000178A00ABCD": 4 hex digits of type, 6 of creature entry, 6 of spawn counter.
-- Returns possible NPC ids, best guess first, because the exact layout isn't confirmed in game yet.
function HPL.NpcIdsFromGuid(guid)
  if type(guid) ~= "string" then return nil end
  local hex = guid
  local prefix = string.sub(hex, 1, 2)
  if prefix == "0x" or prefix == "0X" then
    hex = string.sub(hex, 3)
  end
  local len = string.len(hex)
  if len < 16 then
    hex = string.rep("0", 16 - len) .. hex
  end
  local ids = {}
  local a = tonumber(string.sub(hex, 5, 10), 16)
  if a and a > 0 then table.insert(ids, a) end
  local b = tonumber(string.sub(hex, 5, 8), 16)
  if b and b > 0 and b ~= a then table.insert(ids, b) end
  return ids
end

function HPL.UnitGuid(unit)
  if not SUPERWOW_VERSION then return nil end
  local exists, guid = UnitExists(unit)
  if exists and type(guid) == "string" then
    return guid
  end
  return nil
end

local function NewDB()
  return {
    version = HPL.DB_VERSION,
    settings = {
      showUncaught = false,
      notify = true,
      minimapAngle = 215,
      minimapHidden = false,
      collapsed = {},
      debug = false,
      rangeIcon = true,
      feedReminder = true,
      feedWhen = "content",   -- "content": remind as soon as the pet isn't happy; "unhappy": only when unhappy
      feedSound = true,
    },
    pets = {},     -- [charKey] = { pet records }
    custom = {},   -- [skinId] = skins discovered in game that aren't in the bundled database
    stats = { tames = 0 },
  }
end

-- Fill in anything missing so older or damaged saved data can't break the addon.
local function UpgradeDB(db)
  local fresh = NewDB()
  for k, v in pairs(fresh) do
    if type(db[k]) ~= type(v) then
      db[k] = v
    end
  end
  for k, v in pairs(fresh.settings) do
    if db.settings[k] == nil then
      db.settings[k] = v
    end
  end
  if type(db.settings.collapsed) ~= "table" then db.settings.collapsed = {} end
  if type(db.stats.tames) ~= "number" then db.stats.tames = 0 end
  db.version = HPL.DB_VERSION
  return db
end

function HPL.PetsFor(charKey)
  local pets = HPL.db.pets[charKey]
  if not pets then
    pets = {}
    HPL.db.pets[charKey] = pets
  end
  return pets
end

-- Called after any change to pets or settings.
function HPL.Changed()
  HPL.RebuildCollection()
  if HPL.RefreshUI then HPL.RefreshUI() end
end

local function FindPetByName(name)
  if not name or name == "" then return nil end
  local want = string.lower(name)
  local found, foundChar, foundIndex
  for charKey, list in pairs(HPL.db.pets) do
    for i = 1, table.getn(list) do
      if string.lower(list[i].name or "") == want then
        if charKey == HPL.CharKey() or not found then
          found, foundChar, foundIndex = list[i], charKey, i
        end
      end
    end
  end
  return found, foundChar, foundIndex
end

local function SlashHandler(msg)
  msg = msg or ""
  local _, _, cmd, rest = string.find(msg, "^%s*(%S*)%s*(.-)%s*$")
  cmd = string.lower(cmd or "")

  if cmd == "" or cmd == "show" then
    HPL.ToggleWindow()
  elseif cmd == "uncaught" then
    HPL.db.settings.showUncaught = not HPL.db.settings.showUncaught
    HPL.Print("uncaught skins are now " .. (HPL.db.settings.showUncaught and "shown" or "hidden") .. ".")
    HPL.Changed()
  elseif cmd == "minimap" then
    HPL.db.settings.minimapHidden = not HPL.db.settings.minimapHidden
    if HPL.UpdateMinimapButton then HPL.UpdateMinimapButton() end
  elseif cmd == "notify" then
    HPL.db.settings.notify = not HPL.db.settings.notify
    HPL.Print("new skin messages " .. (HPL.db.settings.notify and "on" or "off") .. ".")
  elseif cmd == "range" then
    HPL.db.settings.rangeIcon = not HPL.db.settings.rangeIcon
    HPL.Print("range icon " .. (HPL.db.settings.rangeIcon and "on" or "off") .. ".")
    HPL.UpdateHunterTools()
    if HPL.RefreshUI then HPL.RefreshUI() end
  elseif cmd == "feed" then
    local s = HPL.db.settings
    if rest == "content" or rest == "unhappy" then
      s.feedWhen = rest
      s.feedReminder = true
    elseif rest == "sound" then
      s.feedSound = not s.feedSound
      HPL.Print("feed reminder sound " .. (s.feedSound and "on" or "off") .. ".")
    else
      s.feedReminder = not s.feedReminder
    end
    HPL.Print("feed reminder " .. (s.feedReminder and ("on, when your pet is " .. s.feedWhen .. " or worse") or "off") .. ".")
    HPL.UpdateHunterTools()
    if HPL.RefreshUI then HPL.RefreshUI() end
  elseif cmd == "move" then
    HPL.ToggleMoveIcons()
  elseif cmd == "scan" then
    HPL.ScanActivePet("scan")
    HPL.Print("checked your current pet.")
  elseif cmd == "forget" or cmd == "unassign" then
    local pet, charKey, index = FindPetByName(rest)
    if not pet then
      HPL.Print("no saved pet named '" .. rest .. "'.")
    elseif cmd == "forget" then
      table.remove(HPL.db.pets[charKey], index)
      HPL.Print("forgot " .. pet.name .. " (" .. HPL.CharName(charKey) .. ").")
      HPL.Changed()
    else
      pet.skin = nil
      pet.match = "manual"
      HPL.Print(pet.name .. " moved to 'Unknown skin'. Open /petlog to assign it.")
      HPL.Changed()
    end
  elseif cmd == "debug" then
    if rest == "on" or rest == "off" then
      HPL.db.settings.debug = (rest == "on")
      HPL.Print("debug messages " .. rest .. ".")
    else
      HPL.PrintDebugInfo()
    end
  elseif cmd == "reset" then
    if rest == "confirm" then
      HunterPetLogDB = NewDB()
      HPL.db = HunterPetLogDB
      HPL.BuildIndex()
      HPL.Changed()
      HPL.Print("all saved pets and settings were reset.")
    else
      HPL.Print("this deletes your whole pet log. Type '/petlog reset confirm' to do it.")
    end
  else
    HPL.Print("commands:")
    HPL.Print("/petlog - open or close the log")
    HPL.Print("/petlog uncaught - show or hide skins you haven't caught")
    HPL.Print("/petlog minimap - show or hide the minimap button")
    HPL.Print("/petlog notify - turn new skin messages on or off")
    HPL.Print("/petlog range - turn the range icon on or off")
    HPL.Print("/petlog feed - turn the feed reminder on or off")
    HPL.Print("/petlog feed content | unhappy - when the feed reminder shows")
    HPL.Print("/petlog feed sound - turn the feed reminder sound on or off")
    HPL.Print("/petlog move - unlock the range icon and feed reminder so you can drag them")
    HPL.Print("/petlog scan - re-check your current pet")
    HPL.Print("/petlog unassign <pet name> - clear a pet's skin so you can pick it again")
    HPL.Print("/petlog forget <pet name> - remove a saved pet")
    HPL.Print("/petlog debug - print pet and target details (for bug reports)")
    HPL.Print("/petlog reset - delete everything")
  end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function()
  if event ~= "ADDON_LOADED" or arg1 ~= "HunterPetLog" then return end
  loader:UnregisterEvent("ADDON_LOADED")

  if type(HunterPetLogDB) ~= "table" then
    HunterPetLogDB = NewDB()
  end
  HPL.db = UpgradeDB(HunterPetLogDB)

  HPL.BuildIndex()
  HPL.RebuildCollection()
  HPL.InitTracker()
  HPL.InitMinimapButton()
  HPL.InitHunterTools()

  SLASH_HUNTERPETLOG1 = "/petlog"
  SLASH_HUNTERPETLOG2 = "/hpl"
  SlashCmdList["HUNTERPETLOG"] = SlashHandler
end)
