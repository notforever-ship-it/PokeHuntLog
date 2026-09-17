-- PokeHuntLog: main window. Left: Type -> Family -> Skin list. Right: details for the selected row.

local HPL = PokeHuntLog

local WIDTH, HEIGHT = 640, 500
local ROW_HEIGHT, NUM_ROWS, ROW_WIDTH = 18, 20, 318
local DETAIL_WIDTH = 236
local MAX_WHERE_LINES = 6

local frame, scroll, detail, emptyText, summaryText, uncaughtCheck, rangeCheck, feedCheck, lockButton
local buttons = {}
HPL.rows = {}
HPL.selected = nil      -- { kind = "skin", id = skinId } or { kind = "pet", pet = petRecord, charKey = key }
HPL.assigning = nil     -- pet record waiting for the player to click a skin

local GOLD = "|cffffd100"
local GREY = "|cff808080"
local GREEN = "|cff40ff40"
local ORANGE = "|cffff9933"
local WHITE = "|cffffffff"
local END = "|r"

local function Backdrop(f, dialog)
  if dialog then
    f:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile = true, tileSize = 32, edgeSize = 32,
      insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
  else
    f:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true, tileSize = 16, edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    f:SetBackdropColor(0, 0, 0, 0.6)
    f:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
  end
end

local function LevelText(level)
  if not level or level <= 0 then return "" end
  local color = (level >= HPL.MAX_LEVEL) and GREEN or WHITE
  return color .. level .. END .. GREY .. "/" .. HPL.MAX_LEVEL .. END
end

------------------------------------------------------------------------------------------------
-- Row list
------------------------------------------------------------------------------------------------

function HPL.BuildRows()
  local rows = {}
  local s = HPL.db.settings
  local collapsed = s.collapsed
  local assigningFamily = HPL.assigning and HPL.assigning.family

  for i = 1, table.getn(HPL.tree) do
    local t = HPL.tree[i]
    local ts = HPL.typeStats[t.name]
    local typeVisible = s.showUncaught or ts.caught > 0 or assigningFamily
    if typeVisible then
      local tkey = "t:" .. t.name
      table.insert(rows, { kind = "type", key = tkey, name = t.name, caught = ts.caught, total = ts.skins })
      if not collapsed[tkey] then
        for j = 1, table.getn(t.families) do
          local f = t.families[j]
          local fs = HPL.familyStats[t.name .. "/" .. f.name]
          local picking = assigningFamily == f.name
          if s.showUncaught or fs.caught > 0 or picking then
            local fkey = "f:" .. t.name .. "/" .. f.name
            table.insert(rows, { kind = "family", key = fkey, name = f.name, caught = fs.caught, total = fs.skins,
              best = fs.bestLevel })
            if not collapsed[fkey] or picking then
              for k = 1, table.getn(f.skins) do
                local id = f.skins[k]
                if HPL.caught[id] or s.showUncaught or picking then
                  table.insert(rows, { kind = "skin", id = id })
                end
              end
            end
          end
        end
      end
    end
  end

  local unknown = HPL.unknownPets or {}
  if table.getn(unknown) > 0 then
    table.insert(rows, { kind = "header", key = "unknown", name = "Pets with unknown skin", total = table.getn(unknown) })
    if not collapsed["unknown"] then
      for i = 1, table.getn(unknown) do
        table.insert(rows, { kind = "pet", pet = unknown[i].pet, charKey = unknown[i].charKey })
      end
    end
  end

  HPL.rows = rows
end

local function IsSelected(r)
  local sel = HPL.selected
  if not sel then return false end
  if r.kind == "skin" then return sel.kind == "skin" and sel.id == r.id end
  if r.kind == "pet" then return sel.kind == "pet" and sel.pet == r.pet end
  return false
end

function HPL.UpdateList()
  if not frame then return end
  local rows = HPL.rows
  local total = table.getn(rows)
  FauxScrollFrame_Update(scroll, total, NUM_ROWS, ROW_HEIGHT)
  local offset = FauxScrollFrame_GetOffset(scroll)
  local collapsed = HPL.db.settings.collapsed

  for i = 1, NUM_ROWS do
    local btn = buttons[i]
    local r = rows[i + offset]
    btn.entry = r
    if not r then
      btn:Hide()
    else
      local indent, iconPath, label, right, expand = 0, nil, "", "", ""
      btn.icon:SetVertexColor(1, 1, 1)

      if r.kind == "type" or r.kind == "header" then
        expand = collapsed[r.key] and "+" or "-"
        if r.kind == "type" then
          label = GOLD .. r.name .. END
          right = WHITE .. r.caught .. END .. GREY .. " / " .. r.total .. END
        else
          label = ORANGE .. r.name .. END
          right = WHITE .. r.total .. END
        end
      elseif r.kind == "family" then
        indent = 12
        expand = collapsed[r.key] and "+" or "-"
        iconPath = HPL.FamilyIcon(r.name)
        label = (r.caught > 0 and WHITE or GREY) .. r.name .. END
        right = WHITE .. r.caught .. END .. GREY .. "/" .. r.total .. END
        if r.best > 0 then
          right = right .. GREY .. "  best " .. END .. LevelText(r.best)
        end
      elseif r.kind == "skin" then
        indent = 30
        local def = HPL.skinsById[r.id]
        local c = HPL.caught[r.id]
        iconPath = HPL.FamilyIcon(def.family)
        if c then
          label = WHITE .. def.name .. END
          right = LevelText(c.maxLevel)
        else
          label = GREY .. def.name .. END
          btn.icon:SetVertexColor(0.35, 0.35, 0.35)
        end
        if HPL.assigning and HPL.assigning.family == def.family then
          label = GREEN .. "> " .. END .. label
        end
      elseif r.kind == "pet" then
        indent = 12
        iconPath = HPL.FamilyIcon(r.pet.family)
        label = WHITE .. tostring(r.pet.name) .. END .. GREY .. " (" .. tostring(r.pet.family) .. ")" .. END
        right = LevelText(r.pet.level) .. GREY .. "  " .. HPL.CharName(r.charKey) .. END
      end

      btn.expand:SetText(expand)
      btn.expand:SetPoint("LEFT", btn, "LEFT", indent, 0)
      if iconPath then
        btn.icon:SetTexture(iconPath)
        btn.icon:SetPoint("LEFT", btn, "LEFT", indent + (expand ~= "" and 12 or 0), 0)
        btn.icon:Show()
        btn.label:SetPoint("LEFT", btn.icon, "RIGHT", 4, 0)
      else
        btn.icon:Hide()
        btn.label:SetPoint("LEFT", btn, "LEFT", indent + 14, 0)
      end
      btn.label:SetText(label)
      btn.right:SetText(right)
      if IsSelected(r) then btn.selectedTex:Show() else btn.selectedTex:Hide() end
      btn:Show()
    end
  end

  if total == 0 then emptyText:Show() else emptyText:Hide() end
end

local function OnRowClick(btn, mouseButton)
  local r = btn.entry
  if not r then return end
  if mouseButton == "RightButton" and HPL.assigning then
    HPL.assigning = nil
    HPL.RefreshUI()
    return
  end

  if r.kind == "type" or r.kind == "family" or r.kind == "header" then
    local collapsed = HPL.db.settings.collapsed
    if collapsed[r.key] then collapsed[r.key] = nil else collapsed[r.key] = true end
  elseif r.kind == "skin" then
    local pet = HPL.assigning
    local def = HPL.skinsById[r.id]
    if pet then
      if def.family ~= pet.family then
        HPL.Print("pick a " .. tostring(pet.family) .. " skin for " .. tostring(pet.name) .. " (right-click to cancel).")
        return
      end
      pet.skin = r.id
      pet.match = "manual"
      HPL.assigning = nil
      HPL.Print(pet.name .. " is now logged as " .. def.name .. ".")
      HPL.selected = { kind = "skin", id = r.id }
      HPL.Changed()
      return
    end
    HPL.selected = { kind = "skin", id = r.id }
  elseif r.kind == "pet" then
    HPL.selected = { kind = "pet", pet = r.pet, charKey = r.charKey }
  end
  HPL.RefreshUI()
end

------------------------------------------------------------------------------------------------
-- Detail panel
------------------------------------------------------------------------------------------------

local function Line(lines, text)
  table.insert(lines, text)
end

local function OverviewText()
  local t = HPL.totals
  local chars = 0
  for _ in pairs(HPL.db.pets) do chars = chars + 1 end
  local lines = {}
  Line(lines, GOLD .. "Skins caught: " .. END .. t.caught .. " / " .. t.skins ..
    " (" .. HPL.Percent(t.caught, t.skins) .. "%)")
  Line(lines, GOLD .. "Families started: " .. END .. t.familiesCaught .. " / " .. t.families)
  Line(lines, GOLD .. "Tames logged: " .. END .. HPL.db.stats.tames)
  Line(lines, GOLD .. "Highest pet level: " .. END .. (t.bestLevel > 0 and LevelText(t.bestLevel) or "-"))
  Line(lines, GOLD .. "Hunters logged: " .. END .. chars)
  Line(lines, " ")
  Line(lines, "Click a skin to see its details. Tick " .. WHITE .. "Show uncaught" .. END ..
    " to browse every skin and where to tame it.")
  if not HPL.db.settings.showUncaught then
    Line(lines, " ")
    Line(lines, GREY .. "Skins you haven't caught are hidden." .. END)
  end
  return table.concat(lines, "\n")
end

local function SkinText(def)
  local c = HPL.caught[def.id]
  local lines = {}
  local modelName = def.model and def.model ~= def.family and (" - " .. def.model) or ""
  Line(lines, GREY .. def.type .. " / " .. def.family .. modelName .. END)
  if def.custom then
    Line(lines, ORANGE .. "Found in game (not in the skin database)" .. END)
  end
  if c then
    Line(lines, GREEN .. "Caught" .. END)
    Line(lines, GOLD .. "Highest level: " .. END .. LevelText(c.maxLevel) ..
      GREY .. "  " .. tostring(c.maxPet) .. ", " .. HPL.CharName(c.maxChar) .. END)
    if c.firstTime then
      local verb = c.firstWitnessed and "First tamed: " or "First logged: "
      local where = c.firstZone and (" in " .. c.firstZone) or ""
      Line(lines, GOLD .. verb .. END .. HPL.FormatDate(c.firstTime) .. " by " .. HPL.CharName(c.firstChar) .. where)
    end
    if c.firstCreature then
      Line(lines, GOLD .. "Tamed from: " .. END .. c.firstCreature)
    end
    local names = {}
    for i = 1, table.getn(c.pets) do
      local p = c.pets[i]
      local from = p.pet.creature and (", " .. p.pet.creature) or ""
      table.insert(names, tostring(p.pet.name) .. " (" .. (p.pet.level or "?") .. from .. ")")
    end
    Line(lines, GOLD .. "Pets: " .. END .. table.concat(names, ", "))
  else
    Line(lines, GREY .. "Not caught yet" .. END)
  end

  local npcs = def.npcs or {}
  if table.getn(npcs) > 0 then
    Line(lines, " ")
    Line(lines, GOLD .. "Where to tame:" .. END)
    for i = 1, math.min(table.getn(npcs), MAX_WHERE_LINES) do
      local n = npcs[i]
      local extra = ""
      if n[3] and n[3] ~= "" then extra = " " .. n[3] end
      if n[5] and n[5] ~= "" then extra = extra .. " " .. ORANGE .. n[5] .. END end
      Line(lines, WHITE .. tostring(n[2]) .. END .. GREY .. extra .. END .. "  " .. GREY .. tostring(n[4]) .. END)
    end
    if table.getn(npcs) > MAX_WHERE_LINES then
      Line(lines, GREY .. "...and " .. (table.getn(npcs) - MAX_WHERE_LINES) .. " more" .. END)
    end
  end
  return table.concat(lines, "\n")
end

local function PetText(sel)
  local pet = sel.pet
  local lines = {}
  Line(lines, GREY .. tostring(pet.ctype or "Beast") .. " / " .. tostring(pet.family) .. END)
  Line(lines, GOLD .. "Level: " .. END .. LevelText(pet.level))
  Line(lines, GOLD .. "Hunter: " .. END .. HPL.CharName(sel.charKey))
  if pet.creature then
    Line(lines, GOLD .. "Tamed from: " .. END .. pet.creature)
  end
  if pet.firstSeen or pet.tamed then
    Line(lines, GOLD .. "First logged: " .. END .. HPL.FormatDate(pet.tamed or pet.firstSeen))
  end
  Line(lines, " ")
  if HPL.assigning == pet then
    Line(lines, GREEN .. "Click one of the " .. tostring(pet.family) .. " skins in the list." .. END)
    Line(lines, GREY .. "Summon the pet to compare it with the 3D view. Right-click the list to cancel." .. END)
  else
    Line(lines, "The log couldn't tell which skin this pet has. It was probably tamed before the addon " ..
      "was installed, or renamed while it was turned off.")
    Line(lines, " ")
    Line(lines, "Press " .. WHITE .. "Assign skin" .. END .. " and pick the matching " .. tostring(pet.family) ..
      " skin from the list.")
  end
  return table.concat(lines, "\n")
end

function HPL.RefreshModel()
  if not frame or not frame:IsShown() then return end
  local sel = HPL.selected
  local active = HPL.activePet
  local show = false
  if active and UnitExists("pet") and sel then
    if sel.kind == "skin" and active.skin == sel.id then show = true end
    if sel.kind == "pet" and sel.pet == active then show = true end
  end
  if show then
    detail.model:SetUnit("pet")
    detail.model:Show()
    detail.bigIcon:Hide()
    detail.modelHint:Hide()
  else
    detail.model:Hide()
    local family
    if sel and sel.kind == "skin" then family = HPL.skinsById[sel.id].family end
    if sel and sel.kind == "pet" then family = sel.pet.family end
    detail.bigIcon:SetTexture(family and HPL.FamilyIcon(family) or "Interface\\Icons\\Ability_Hunter_BeastTaming")
    if sel and sel.kind == "skin" and not HPL.caught[sel.id] then
      detail.bigIcon:SetVertexColor(0.35, 0.35, 0.35)
    else
      detail.bigIcon:SetVertexColor(1, 1, 1)
    end
    detail.bigIcon:Show()
    if sel then detail.modelHint:Show() else detail.modelHint:Hide() end
  end
end

function HPL.UpdateDetail()
  if not frame then return end
  local sel = HPL.selected
  if sel and sel.kind == "skin" and not HPL.skinsById[sel.id] then sel = nil end
  if sel and sel.kind == "pet" and sel.pet.skin then
    sel = { kind = "skin", id = sel.pet.skin }
  end
  HPL.selected = sel

  detail.assign:Hide()
  detail.forget:Hide()
  if not sel then
    detail.title:SetText("Your collection")
    detail.text:SetText(OverviewText())
  elseif sel.kind == "skin" then
    local def = HPL.skinsById[sel.id]
    detail.title:SetText(def.name)
    detail.text:SetText(SkinText(def))
  else
    detail.title:SetText(tostring(sel.pet.name))
    detail.text:SetText(PetText(sel))
    detail.assign:SetText(HPL.assigning == sel.pet and "Cancel" or "Assign skin")
    detail.assign:Show()
    detail.forget:Show()
  end
  HPL.RefreshModel()
end

function HPL.RefreshUI()
  if not frame or not frame:IsShown() then return end
  summaryText:SetText(GOLD .. "Skins: " .. END .. HPL.totals.caught .. "/" .. HPL.totals.skins ..
    " (" .. HPL.Percent(HPL.totals.caught, HPL.totals.skins) .. "%)" ..
    GOLD .. "     Tames: " .. END .. HPL.db.stats.tames)
  uncaughtCheck:SetChecked(HPL.db.settings.showUncaught)
  rangeCheck:SetChecked(HPL.db.settings.rangeIcon)
  feedCheck:SetChecked(HPL.db.settings.feedReminder)
  HPL.BuildRows()
  HPL.UpdateDetail()
  HPL.UpdateList()
end

------------------------------------------------------------------------------------------------
-- Window creation
------------------------------------------------------------------------------------------------

local function CreateRow(i)
  local btn = CreateFrame("Button", "PokeHuntLogRow" .. i, frame)
  btn:SetWidth(ROW_WIDTH)
  btn:SetHeight(ROW_HEIGHT)
  btn:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
  btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  btn:SetFrameLevel(frame:GetFrameLevel() + 3)

  local hl = btn:CreateTexture(nil, "HIGHLIGHT")
  hl:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
  hl:SetBlendMode("ADD")
  hl:SetAllPoints(btn)

  btn.selectedTex = btn:CreateTexture(nil, "BACKGROUND")
  btn.selectedTex:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
  btn.selectedTex:SetBlendMode("ADD")
  btn.selectedTex:SetVertexColor(1, 0.82, 0)
  btn.selectedTex:SetAllPoints(btn)
  btn.selectedTex:Hide()

  btn.expand = btn:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  btn.expand:SetWidth(12)
  btn.expand:SetPoint("LEFT", btn, "LEFT", 0, 0)

  btn.icon = btn:CreateTexture(nil, "ARTWORK")
  btn.icon:SetWidth(16)
  btn.icon:SetHeight(16)
  btn.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

  btn.right = btn:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  btn.right:SetPoint("RIGHT", btn, "RIGHT", -4, 0)
  btn.right:SetJustifyH("RIGHT")

  btn.label = btn:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  btn.label:SetJustifyH("LEFT")
  btn.label:SetPoint("RIGHT", btn.right, "LEFT", -6, 0)

  btn:SetScript("OnClick", function() OnRowClick(this, arg1) end)
  return btn
end

local function CreateWindow()
  frame = CreateFrame("Frame", "PokeHuntLogFrame", UIParent)
  frame:SetWidth(WIDTH)
  frame:SetHeight(HEIGHT)
  frame:SetFrameStrata("HIGH")
  frame:SetClampedToScreen(true)
  frame:EnableMouse(true)
  frame:SetMovable(true)
  frame:RegisterForDrag("LeftButton")
  Backdrop(frame, true)
  frame:Hide()

  local pos = HPL.db.settings.position
  if type(pos) == "table" and pos.point then
    frame:SetPoint(pos.point, UIParent, pos.relPoint or pos.point, pos.x or 0, pos.y or 0)
  else
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
  end

  frame:SetScript("OnDragStart", function() this:StartMoving() end)
  frame:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
    local point, _, relPoint, x, y = this:GetPoint()
    HPL.db.settings.position = { point = point, relPoint = relPoint, x = x, y = y }
  end)
  frame:SetScript("OnShow", function() HPL.RefreshUI() end)
  frame:SetScript("OnHide", function() HPL.assigning = nil end)
  table.insert(UISpecialFrames, "PokeHuntLogFrame")

  local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOP", frame, "TOP", 0, -18)
  title:SetText("PokeHuntLog")

  local close = CreateFrame("Button", "PokeHuntLogCloseButton", frame, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
  close:SetScript("OnClick", function() frame:Hide() end)

  local credit = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  credit:SetPoint("BOTTOM", frame, "BOTTOM", 0, 24)
  credit:SetText(GREY .. "Made by " .. END .. "|cffabd473stealthzi" .. END)

  lockButton = CreateFrame("Button", "PokeHuntLogLockButton", frame, "UIPanelButtonTemplate")
  lockButton:SetWidth(110)
  lockButton:SetHeight(22)
  lockButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 18, 18)
  lockButton:SetText(HPL.movingIcons and "Lock icons" or "Unlock icons")
  lockButton:SetScript("OnClick", function() HPL.ToggleMoveIcons() end)
  lockButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_TOP")
    GameTooltip:SetText("Move the range icon and feed reminder")
    GameTooltip:AddLine("Unlock, drag them where you want, then lock again.", 1, 1, 1, 1)
    GameTooltip:Show()
  end)
  lockButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

  local collapseButton = CreateFrame("Button", "PokeHuntLogCollapseButton", frame, "UIPanelButtonTemplate")
  collapseButton:SetWidth(110)
  collapseButton:SetHeight(22)
  collapseButton:SetPoint("LEFT", lockButton, "RIGHT", 8, 0)
  collapseButton:SetText("Collapse all")
  collapseButton:SetScript("OnClick", function() HPL.ToggleCollapseAll() end)

  local helpButton = CreateFrame("Button", "PokeHuntLogHelpButton", frame, "UIPanelButtonTemplate")
  helpButton:SetWidth(110)
  helpButton:SetHeight(22)
  helpButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 18)
  helpButton:SetText("Help")
  helpButton:SetScript("OnClick", function() HPL.ToggleHelp() end)

  summaryText = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  summaryText:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -48)
  summaryText:SetJustifyH("LEFT")

  uncaughtCheck = CreateFrame("CheckButton", "PokeHuntLogUncaughtCheck", frame, "UICheckButtonTemplate")
  uncaughtCheck:SetWidth(24)
  uncaughtCheck:SetHeight(24)
  uncaughtCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 240, -42)
  local checkLabel = getglobal("PokeHuntLogUncaughtCheckText")
  if checkLabel then
    checkLabel:SetText("Show uncaught")
  end
  uncaughtCheck:SetScript("OnClick", function()
    HPL.db.settings.showUncaught = this:GetChecked() and true or false
    HPL.Changed()
  end)

  rangeCheck = CreateFrame("CheckButton", "PokeHuntLogRangeCheck", frame, "UICheckButtonTemplate")
  rangeCheck:SetWidth(24)
  rangeCheck:SetHeight(24)
  rangeCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 370, -42)
  local rangeLabel = getglobal("PokeHuntLogRangeCheckText")
  if rangeLabel then rangeLabel:SetText("Range icon") end
  rangeCheck:SetScript("OnClick", function()
    HPL.db.settings.rangeIcon = this:GetChecked() and true or false
    HPL.UpdateHunterTools()
  end)

  feedCheck = CreateFrame("CheckButton", "PokeHuntLogFeedCheck", frame, "UICheckButtonTemplate")
  feedCheck:SetWidth(24)
  feedCheck:SetHeight(24)
  feedCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 480, -42)
  local feedLabel = getglobal("PokeHuntLogFeedCheckText")
  if feedLabel then feedLabel:SetText("Feed reminder") end
  feedCheck:SetScript("OnClick", function()
    HPL.db.settings.feedReminder = this:GetChecked() and true or false
    HPL.UpdateHunterTools()
  end)

  -- List
  local listBg = CreateFrame("Frame", nil, frame)
  listBg:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -68)
  listBg:SetWidth(ROW_WIDTH + 34)
  listBg:SetHeight(NUM_ROWS * ROW_HEIGHT + 12)
  Backdrop(listBg, false)
  listBg:SetFrameLevel(frame:GetFrameLevel() + 1)

  scroll = CreateFrame("ScrollFrame", "PokeHuntLogListScroll", frame, "FauxScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", listBg, "TOPLEFT", 6, -6)
  scroll:SetWidth(ROW_WIDTH)
  scroll:SetHeight(NUM_ROWS * ROW_HEIGHT)
  scroll:SetFrameLevel(frame:GetFrameLevel() + 2)
  scroll:SetScript("OnVerticalScroll", function()
    FauxScrollFrame_OnVerticalScroll(ROW_HEIGHT, HPL.UpdateList)
  end)

  for i = 1, NUM_ROWS do
    buttons[i] = CreateRow(i)
  end

  emptyText = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  emptyText:SetPoint("TOPLEFT", listBg, "TOPLEFT", 16, -40)
  emptyText:SetWidth(ROW_WIDTH - 20)
  emptyText:SetJustifyH("LEFT")
  emptyText:SetText("No pets logged yet.\n\nTame a beast, or call your pet, and it will show up here.\n\n" ..
    "Tick Show uncaught to browse every skin in the game.")
  emptyText:Hide()

  -- Detail panel
  detail = CreateFrame("Frame", nil, frame)
  detail:SetPoint("TOPLEFT", listBg, "TOPRIGHT", 8, 0)
  detail:SetWidth(DETAIL_WIDTH)
  detail:SetHeight(NUM_ROWS * ROW_HEIGHT + 12)
  Backdrop(detail, false)

  detail.model = CreateFrame("PlayerModel", nil, detail)
  detail.model:SetPoint("TOP", detail, "TOP", 0, -8)
  detail.model:SetWidth(DETAIL_WIDTH - 16)
  detail.model:SetHeight(118)
  detail.model.facing = 0
  detail.model:SetScript("OnUpdate", function()
    this.facing = this.facing + arg1 * 0.6
    this:SetFacing(this.facing)
  end)
  detail.model:Hide()

  detail.bigIcon = detail:CreateTexture(nil, "ARTWORK")
  detail.bigIcon:SetWidth(56)
  detail.bigIcon:SetHeight(56)
  detail.bigIcon:SetPoint("TOP", detail, "TOP", 0, -28)
  detail.bigIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

  detail.modelHint = detail:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  detail.modelHint:SetPoint("TOP", detail.bigIcon, "BOTTOM", 0, -8)
  detail.modelHint:SetWidth(DETAIL_WIDTH - 20)
  detail.modelHint:SetTextColor(0.5, 0.5, 0.5)
  detail.modelHint:SetText("Summon this pet to see it in 3D")

  detail.title = detail:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  detail.title:SetPoint("TOPLEFT", detail, "TOPLEFT", 10, -132)
  detail.title:SetWidth(DETAIL_WIDTH - 20)
  detail.title:SetJustifyH("LEFT")

  detail.text = detail:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  detail.text:SetPoint("TOPLEFT", detail.title, "BOTTOMLEFT", 0, -6)
  detail.text:SetWidth(DETAIL_WIDTH - 20)
  detail.text:SetHeight(NUM_ROWS * ROW_HEIGHT - 160)
  detail.text:SetJustifyH("LEFT")
  detail.text:SetJustifyV("TOP")

  detail.assign = CreateFrame("Button", "PokeHuntLogAssignButton", detail, "UIPanelButtonTemplate")
  detail.assign:SetWidth(104)
  detail.assign:SetHeight(22)
  detail.assign:SetPoint("BOTTOMLEFT", detail, "BOTTOMLEFT", 8, 8)
  detail.assign:SetText("Assign skin")
  detail.assign:SetScript("OnClick", function()
    local sel = HPL.selected
    if not sel or sel.kind ~= "pet" then return end
    if HPL.assigning == sel.pet then
      HPL.assigning = nil
    else
      HPL.assigning = sel.pet
      HPL.db.settings.collapsed["t:" .. (sel.pet.ctype or "Beast")] = nil
    end
    HPL.RefreshUI()
  end)

  detail.forget = CreateFrame("Button", "PokeHuntLogForgetButton", detail, "UIPanelButtonTemplate")
  detail.forget:SetWidth(104)
  detail.forget:SetHeight(22)
  detail.forget:SetPoint("BOTTOMRIGHT", detail, "BOTTOMRIGHT", -8, 8)
  detail.forget:SetText("Forget pet")
  detail.forget:SetScript("OnClick", function()
    local sel = HPL.selected
    if not sel or sel.kind ~= "pet" then return end
    if not IsShiftKeyDown() then
      HPL.Print("hold Shift and click Forget pet to remove " .. tostring(sel.pet.name) .. " from the log.")
      return
    end
    local list = HPL.db.pets[sel.charKey] or {}
    for i = 1, table.getn(list) do
      if list[i] == sel.pet then
        table.remove(list, i)
        break
      end
    end
    if HPL.activePet == sel.pet then HPL.activePet = nil end
    HPL.assigning = nil
    HPL.selected = nil
    HPL.Changed()
  end)
end

-- Collapse every family and type, or open them all again.
function HPL.ToggleCollapseAll()
  local collapsed = HPL.db.settings.collapsed
  local anyOpen = false
  for i = 1, table.getn(HPL.tree) do
    local t = HPL.tree[i]
    if not collapsed["t:" .. t.name] then anyOpen = true end
    for j = 1, table.getn(t.families) do
      if not collapsed["f:" .. t.name .. "/" .. t.families[j].name] then anyOpen = true end
    end
  end
  for i = 1, table.getn(HPL.tree) do
    local t = HPL.tree[i]
    collapsed["t:" .. t.name] = anyOpen or nil
    for j = 1, table.getn(t.families) do
      collapsed["f:" .. t.name .. "/" .. t.families[j].name] = anyOpen or nil
    end
  end
  if anyOpen then collapsed["unknown"] = nil end
  HPL.RefreshUI()
end

function HPL.UpdateLogLockButton()
  if lockButton then
    lockButton:SetText(HPL.movingIcons and "Lock icons" or "Unlock icons")
  end
end

function HPL.ToggleWindow()
  if not HPL.db then return end
  if not frame then CreateWindow() end
  if frame:IsShown() then
    frame:Hide()
  else
    frame:Show()
  end
end
