-- PokeHuntLog: notices tames, pet levels, renames and stabled pets.
--
-- Tame detection:
--   * With SuperWoW, UNIT_CASTEVENT tells us the player cast Tame Beast (spell 1515) and on which creature.
--   * Without it, SPELLCAST_START / SPELLCAST_CHANNEL_START with the spell name "Tame Beast" does, and the
--     current target is the beast.
--   Either way the beast's details are remembered, and when a pet with that name appears soon after
--   (UNIT_PET), it counts as a new tame.

local HPL = PokeHuntLog

local pending = nil        -- beast being tamed: { name, family, ctype, level, zone, npcIds, time }
local lastBeast = nil      -- last beast targeted, in case the cast event arrives after the target changed
local renameTo = nil       -- { name, time } set when the player renames their pet
local activeGuid = nil     -- SuperWoW GUID of the pet that was out at the last scan
local retries = 0

local function UnitIsBeastCandidate(unit)
  if not UnitExists(unit) then return false end
  if UnitIsPlayer(unit) or UnitPlayerControlled(unit) then return false end
  return UnitCreatureFamily(unit) ~= nil
end

local function CaptureBeast(unit)
  if not UnitIsBeastCandidate(unit) then return nil end
  local info = {
    name = UnitName(unit),
    family = UnitCreatureFamily(unit),
    ctype = UnitCreatureType(unit),
    level = UnitLevel(unit),
    zone = GetRealZoneText(),
    time = GetTime(),
  }
  local guid = HPL.UnitGuid(unit)
  if guid then
    info.guid = guid
    info.npcIds = HPL.NpcIdsFromGuid(guid)
  end
  return info
end

local function StartTame(unit)
  local info = CaptureBeast(unit or "target")
  if not info and lastBeast and GetTime() - lastBeast.time < 30 then
    info = lastBeast
  end
  if info then
    info.time = GetTime()
    pending = info
    HPL.Debug("taming " .. tostring(info.name) .. " (" .. tostring(info.family) .. ")")
  end
end

local function ValidPetName(name)
  return name and name ~= "" and name ~= "Unknown" and name ~= UNKNOWNOBJECT
end

-- Most recently seen pet of this character with this name and family.
local function FindPet(list, name, family)
  local found
  for i = 1, table.getn(list) do
    local p = list[i]
    if p.name == name and p.family == family then
      if not found or (p.lastSeen or 0) >= (found.lastSeen or 0) then
        found = p
      end
    end
  end
  return found
end

local function Announce(pet, wasCaught)
  if not HPL.db.settings.notify then return end
  local def = pet.skin and HPL.skinsById[pet.skin]
  if def and not wasCaught then
    HPL.RebuildCollection()
    HPL.Print("|cff00ff00New skin collected:|r " .. def.name .. " (" .. def.family .. ")  " ..
      HPL.totals.caught .. "/" .. HPL.totals.skins)
    UIErrorsFrame:AddMessage("New pet skin: " .. def.name, 0.67, 0.83, 0.45, 1.0, 3)
  elseif not def then
    HPL.Print(pet.name .. " (" .. tostring(pet.family) .. ") was added, but its skin couldn't be worked out. " ..
      "Open /petlog to pick it.")
  end
end

-- source: "pet" (UNIT_PET), "name" (UNIT_NAME_UPDATE), "level", "login", "scan"
function HPL.ScanActivePet(source)
  if not HPL.db or not HPL.IsHunter() then return end
  if not UnitExists("pet") then
    HPL.activePet = nil
    activeGuid = nil
    if HPL.RefreshUI then HPL.RefreshUI() end
    return
  end

  local name = UnitName("pet")
  local family = UnitCreatureFamily("pet")
  if not ValidPetName(name) or not family then
    -- Pet details can be missing for a moment while it loads in. Mind-controlled humanoids never get a
    -- family, so give up after a few tries.
    if source ~= "retry" then retries = 0 end
    if retries < 5 then
      retries = retries + 1
      HPL.After(1, function() HPL.ScanActivePet("retry") end)
    end
    return
  end

  local charKey = HPL.CharKey()
  local list = HPL.PetsFor(charKey)
  local level = UnitLevel("pet") or 0
  local ctype = UnitCreatureType("pet") or "Beast"
  local guid = HPL.UnitGuid("pet")
  local now = GetTime()
  local pet = FindPet(list, name, family)
  local active = HPL.activePet
  local sameGuid = not guid or not activeGuid or guid == activeGuid
  activeGuid = guid

  -- Renamed pet: same pet still out, new name. A name change reported before UNIT_PET could also be a
  -- different pet being called, so without the rename popup we also need the same level (and GUID).
  if not pet and active and active.family == family and active.name ~= name then
    local renamed = (renameTo and renameTo.name == name and now - renameTo.time < 30) or
      (source == "name" and level == (active.level or -1) and sameGuid)
    if renamed then
      HPL.Debug("renamed " .. tostring(active.name) .. " to " .. name)
      active.name = name
      pet = active
      renameTo = nil
    end
  end

  if pending and now - pending.time > HPL.TAME_WINDOW then
    pending = nil
  end

  -- If the Tame Beast cast wasn't reported, an unseen pet named exactly like the beast we just
  -- targeted is still a fresh tame.
  local tame = pending
  if not tame and not pet and lastBeast and now - lastBeast.time < 90 then
    tame = lastBeast
  end

  if tame and tame.family == family and tame.name == name then
    -- New tame.
    local skin, how = HPL.ResolveSkin(family, tame.name, tame.npcIds)
    if not skin then
      local npcId = tame.npcIds and tame.npcIds[1]
      skin = HPL.AddCustomSkin(tame.ctype or ctype, family, tame.name, npcId, tame.level, tame.zone)
      how = "custom"
    end
    local wasCaught = HPL.caught[skin] ~= nil
    pet = {
      name = name, family = family, ctype = ctype, creature = tame.name, level = level,
      tamedLevel = tame.level, tamed = time(), zone = tame.zone, witnessed = true,
      npcId = tame.npcIds and tame.npcIds[1], skin = skin, match = how, lastSeen = time(),
    }
    table.insert(list, pet)
    HPL.db.stats.tames = HPL.db.stats.tames + 1
    pending = nil
    lastBeast = nil
    HPL.activePet = pet
    Announce(pet, wasCaught)
  elseif not pet then
    -- A pet we haven't seen before: tamed before the addon was installed, or renamed while it was off.
    local npcIds = HPL.NpcIdsFromGuid(HPL.UnitGuid("pet"))
    local skin, how = HPL.ResolveSkin(family, name, npcIds)
    local wasCaught = skin and HPL.caught[skin] ~= nil
    pet = {
      name = name, family = family, ctype = ctype, level = level, firstSeen = time(), witnessed = false,
      creature = (how == "name" or how == "ambiguous") and name or nil,
      skin = skin, match = how, lastSeen = time(),
    }
    table.insert(list, pet)
    HPL.activePet = pet
    Announce(pet, wasCaught)
  else
    if level > (pet.level or 0) then
      pet.level = level
    end
    pet.lastSeen = time()
    HPL.activePet = pet
  end

  HPL.Changed()
end

-- Stabled pets: record levels and pick up pets the log hasn't seen yet.
local function ScanStable()
  if not HPL.db or not HPL.IsHunter() then return end
  local list = HPL.PetsFor(HPL.CharKey())
  local changed = false
  for slot = 1, 4 do
    -- Vanilla has 2 stable slots; pcall in case this server's client errors past the last one.
    local ok, _, name, level, family = pcall(GetStablePetInfo, slot)
    if ok and ValidPetName(name) and family then
      local pet = FindPet(list, name, family)
      if pet then
        if (level or 0) > (pet.level or 0) then
          pet.level = level
          changed = true
        end
      else
        local skin, how = HPL.ResolveSkin(family, name, nil)
        table.insert(list, {
          name = name, family = family, ctype = "Beast", level = level or 0, firstSeen = time(),
          witnessed = false, creature = skin and name or nil, skin = skin, match = how, lastSeen = time(),
        })
        changed = true
      end
    end
  end
  if changed then HPL.Changed() end
end

function HPL.PrintDebugInfo()
  HPL.Print("version " .. HPL.VERSION .. ", SuperWoW: " .. tostring(SUPERWOW_VERSION or "no") ..
    ", hunter: " .. tostring(HPL.IsHunter()))
  local function describe(unit)
    if not UnitExists(unit) then
      HPL.Print(unit .. ": none")
      return
    end
    local guid = HPL.UnitGuid(unit)
    local ids = HPL.NpcIdsFromGuid(guid)
    local idText = ids and table.getn(ids) > 0 and table.concat(ids, " or ") or "-"
    local skin = HPL.ResolveSkin(UnitCreatureFamily(unit), UnitName(unit), ids)
    HPL.Print(unit .. ": " .. tostring(UnitName(unit)) .. ", family " .. tostring(UnitCreatureFamily(unit)) ..
      ", type " .. tostring(UnitCreatureType(unit)) .. ", level " .. tostring(UnitLevel(unit)))
    HPL.Print("  guid " .. tostring(guid) .. ", npc id " .. idText .. ", skin " ..
      tostring(skin and HPL.skinsById[skin].name or "unknown"))
  end
  describe("pet")
  describe("target")
  if pending then
    HPL.Print("taming in progress: " .. tostring(pending.name))
  end
end

function HPL.InitTracker()
  local f = CreateFrame("Frame")
  local events = {
    "PLAYER_ENTERING_WORLD", "UNIT_PET", "UNIT_LEVEL", "UNIT_NAME_UPDATE", "LOCALPLAYER_PET_RENAMED",
    "PLAYER_TARGET_CHANGED", "SPELLCAST_START", "SPELLCAST_CHANNEL_START", "PET_STABLE_SHOW",
    "PET_STABLE_UPDATE", "UNIT_MODEL_CHANGED",
  }
  if SUPERWOW_VERSION then
    table.insert(events, "UNIT_CASTEVENT")
  end
  for i = 1, table.getn(events) do
    -- pcall so an event this client doesn't know can't stop the addon loading.
    local ok = pcall(f.RegisterEvent, f, events[i])
    if not ok then HPL.Debug("event not available: " .. events[i]) end
  end

  f:SetScript("OnEvent", function()
    if event == "UNIT_CASTEVENT" then
      -- arg1 caster guid, arg2 target guid, arg3 "START"/"CAST"/"FAIL"/"CHANNEL", arg4 spell id
      if arg4 == HPL.TAME_BEAST_SPELL_ID and arg3 ~= "FAIL" and arg1 == HPL.UnitGuid("player") then
        if type(arg2) == "string" and UnitExists(arg2) then
          StartTame(arg2)
        else
          StartTame("target")
        end
      end
    elseif event == "SPELLCAST_START" then
      if arg1 == HPL.TAME_BEAST_NAME then StartTame("target") end
    elseif event == "SPELLCAST_CHANNEL_START" then
      if arg2 == HPL.TAME_BEAST_NAME or arg1 == HPL.TAME_BEAST_NAME then StartTame("target") end
    elseif event == "PLAYER_TARGET_CHANGED" then
      local info = CaptureBeast("target")
      if info then lastBeast = info end
    elseif event == "UNIT_PET" then
      if arg1 == "player" then HPL.ScanActivePet("pet") end
    elseif event == "UNIT_LEVEL" then
      if arg1 == "pet" then HPL.ScanActivePet("level") end
    elseif event == "UNIT_NAME_UPDATE" then
      if arg1 == "pet" then HPL.ScanActivePet("name") end
    elseif event == "LOCALPLAYER_PET_RENAMED" then
      HPL.After(0.5, function() HPL.ScanActivePet("name") end)
    elseif event == "PLAYER_ENTERING_WORLD" then
      HPL.After(2, function() HPL.ScanActivePet("login") end)
    elseif event == "PET_STABLE_SHOW" or event == "PET_STABLE_UPDATE" then
      ScanStable()
    elseif event == "UNIT_MODEL_CHANGED" then
      if arg1 == "pet" and HPL.RefreshModel then HPL.RefreshModel() end
    end
  end)

  -- The rename popup calls PetRename(name); remember the new name so the rename is matched exactly.
  if type(PetRename) == "function" then
    local original = PetRename
    PetRename = function(newName)
      renameTo = { name = newName, time = GetTime() }
      return original(newName)
    end
  end
end
