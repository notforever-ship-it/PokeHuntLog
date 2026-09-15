-- PokeHuntLog: the skin index (bundled + discovered skins) and the collection built from saved pets.

local HPL = PokeHuntLog

HPL.skinsById = {}      -- [skinId] = { id, type, family, model, name, npcs, custom }
HPL.skinByNpcId = {}    -- [npcId] = skinId
HPL.skinsByName = {}    -- [lowercase creature name] = { skinId, ... }
HPL.tree = {}           -- ordered: { { name = type, families = { { name = family, skins = { skinId, ... } } } } }

local function Register(def)
  if HPL.skinsById[def.id] then return end
  HPL.skinsById[def.id] = def
  local npcs = def.npcs or {}
  for i = 1, table.getn(npcs) do
    local npcId, npcName = npcs[i][1], npcs[i][2]
    if npcId and npcId > 0 then
      HPL.skinByNpcId[npcId] = def.id
    end
    if npcName then
      local key = string.lower(npcName)
      if not HPL.skinsByName[key] then HPL.skinsByName[key] = {} end
      table.insert(HPL.skinsByName[key], def.id)
    end
  end
end

local function SortByName(a, b)
  return a.name < b.name
end

function HPL.BuildIndex()
  HPL.skinsById = {}
  HPL.skinByNpcId = {}
  HPL.skinsByName = {}

  local data = PokeHuntLog_Skins or {}
  for i = 1, table.getn(data) do
    local s = data[i]
    Register({ id = s.id, type = "Beast", family = s.family, model = s.model, name = s.name, npcs = s.npcs })
  end
  for id, c in pairs(HPL.db.custom) do
    Register({ id = id, type = c.type or "Beast", family = c.family or "Unknown", model = c.family,
      name = c.name or id, custom = true,
      npcs = { { c.npcId or 0, c.creature or c.name, c.level and tostring(c.level) or "", c.zone or "", "Found in game" } } })
  end

  -- Group into Type -> Family -> Skins, sorted by name.
  local types, typeList = {}, {}
  for id, def in pairs(HPL.skinsById) do
    local t = types[def.type]
    if not t then
      t = { name = def.type, familyMap = {}, families = {} }
      types[def.type] = t
      table.insert(typeList, t)
    end
    local f = t.familyMap[def.family]
    if not f then
      f = { name = def.family, skins = {} }
      t.familyMap[def.family] = f
      table.insert(t.families, f)
    end
    table.insert(f.skins, def)
  end
  table.sort(typeList, SortByName)
  HPL.tree = {}
  for i = 1, table.getn(typeList) do
    local t = typeList[i]
    table.sort(t.families, SortByName)
    local families = {}
    for j = 1, table.getn(t.families) do
      local f = t.families[j]
      table.sort(f.skins, SortByName)
      local ids = {}
      for k = 1, table.getn(f.skins) do
        table.insert(ids, f.skins[k].id)
      end
      table.insert(families, { name = f.name, skins = ids })
    end
    table.insert(HPL.tree, { name = t.name, families = families })
  end
end

-- Work out which skin a creature has. Returns skinId and how it matched ("id", "name", "ambiguous").
function HPL.ResolveSkin(family, creatureName, npcIds)
  if npcIds then
    for i = 1, table.getn(npcIds) do
      local id = HPL.skinByNpcId[npcIds[i]]
      if id and (not family or HPL.skinsById[id].family == family) then
        return id, "id"
      end
    end
  end
  if creatureName then
    local list = HPL.skinsByName[string.lower(creatureName)]
    if list then
      local best, count = nil, 0
      for i = 1, table.getn(list) do
        if not family or HPL.skinsById[list[i]].family == family then
          count = count + 1
          if not best then best = list[i] end
        end
      end
      if best then
        return best, (count > 1) and "ambiguous" or "name"
      end
    end
  end
  return nil
end

-- A tamed beast that isn't in the bundled database becomes its own skin, named after the creature.
function HPL.AddCustomSkin(ctype, family, creatureName, npcId, level, zone)
  local id = "custom:" .. HPL.Key(family) .. ":" .. HPL.Key(creatureName)
  if not HPL.db.custom[id] then
    HPL.db.custom[id] = { type = ctype or "Beast", family = family, name = creatureName, creature = creatureName,
      npcId = npcId, level = level, zone = zone }
    HPL.BuildIndex()
  end
  return id
end

-- Build the collection from every saved pet on every character.
function HPL.RebuildCollection()
  local caught = {}      -- [skinId] = { maxLevel, maxPet, maxChar, firstTime, firstChar, firstZone, firstCreature, pets = { ... } }
  local unknown = {}     -- pets whose skin isn't known: { pet, charKey, index }

  for charKey, list in pairs(HPL.db.pets) do
    for i = 1, table.getn(list) do
      local pet = list[i]
      if pet.skin and HPL.skinsById[pet.skin] then
        local c = caught[pet.skin]
        if not c then
          c = { maxLevel = 0, pets = {} }
          caught[pet.skin] = c
        end
        table.insert(c.pets, { pet = pet, charKey = charKey })
        local level = pet.level or 0
        if level > c.maxLevel then
          c.maxLevel, c.maxPet, c.maxChar = level, pet.name, charKey
        end
        local when = pet.tamed or pet.firstSeen
        if when and (not c.firstTime or when < c.firstTime) then
          c.firstTime, c.firstChar = when, charKey
          c.firstZone, c.firstCreature, c.firstWitnessed = pet.zone, pet.creature, pet.witnessed
        end
      else
        table.insert(unknown, { pet = pet, charKey = charKey, index = i })
      end
    end
  end

  -- Totals per type and family.
  local totals = { skins = 0, caught = 0, families = 0, familiesCaught = 0, bestLevel = 0 }
  local familyStats, typeStats = {}, {}
  for i = 1, table.getn(HPL.tree) do
    local t = HPL.tree[i]
    local ts = { skins = 0, caught = 0 }
    typeStats[t.name] = ts
    for j = 1, table.getn(t.families) do
      local f = t.families[j]
      local fs = { skins = table.getn(f.skins), caught = 0, bestLevel = 0 }
      familyStats[t.name .. "/" .. f.name] = fs
      for k = 1, table.getn(f.skins) do
        local c = caught[f.skins[k]]
        if c then
          fs.caught = fs.caught + 1
          if c.maxLevel > fs.bestLevel then fs.bestLevel = c.maxLevel end
        end
      end
      ts.skins = ts.skins + fs.skins
      ts.caught = ts.caught + fs.caught
      totals.families = totals.families + 1
      if fs.caught > 0 then totals.familiesCaught = totals.familiesCaught + 1 end
      if fs.bestLevel > totals.bestLevel then totals.bestLevel = fs.bestLevel end
    end
    totals.skins = totals.skins + ts.skins
    totals.caught = totals.caught + ts.caught
  end

  HPL.caught = caught
  HPL.unknownPets = unknown
  HPL.totals = totals
  HPL.familyStats = familyStats
  HPL.typeStats = typeStats
end

function HPL.Percent(part, whole)
  if not whole or whole == 0 then return 0 end
  return math.floor(part * 100 / whole + 0.5)
end
