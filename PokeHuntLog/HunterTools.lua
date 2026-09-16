-- PokeHuntLog: range indicator and pet feeding reminder.
--
-- Range: Auto Shot's range check (IsActionInRange) says whether you can shoot. When you can't and the target
-- is within ~10 yards (CheckInteractDistance 3), Wing Clip's range check tells melee range from the dead zone.
-- Both spells are found on your action bars by reading each button's tooltip.
--
-- Feeding: GetPetHappiness() drops from Happy (3) to Content (2) to Unhappy (1). The reminder shows while the
-- pet is below the chosen level and isn't already eating. Clicking it casts Feed Pet.

local HPL = PokeHuntLog

local AUTO_SHOT = "Auto Shot"
local WING_CLIP = "Wing Clip"
local FEED_PET = "Feed Pet"
local FEED_EFFECT_ICON = "Interface\\Icons\\Ability_Hunter_BeastTraining"
local AUTO_SHOT_ICON = "Interface\\Icons\\Ability_Whirlwind"
local HAPPINESS_TEXTURE = "Interface\\PetPaperDollFrame\\UI-PetHappiness"

local RANGE_STATES = {
  range = { text = "In range", r = 0.25, g = 1, b = 0.25 },
  melee = { text = "Melee", r = 1, g = 0.6, b = 0.1 },
  deadzone = { text = "Dead zone", r = 1, g = 0.15, b = 0.15 },
  close = { text = "Too close", r = 1, g = 0.15, b = 0.15 },
  far = { text = "Out of range", r = 0.6, g = 0.6, b = 0.6 },
}

local HAPPINESS = {
  [1] = { text = "Unhappy", r = 1, g = 0.15, b = 0.15, coords = { 0.375, 0.5625, 0, 0.359375 } },
  [2] = { text = "Content", r = 1, g = 0.82, b = 0, coords = { 0.1875, 0.375, 0, 0.359375 } },
  [3] = { text = "Happy", r = 0.25, g = 1, b = 0.25, coords = { 0, 0.1875, 0, 0.359375 } },
}

local rangeFrame, feedFrame
local slots = {}
local slotsDirty = true
local lastSlotScan = 0
local lastSlotResult = ""
local scanTip
local lastHappiness
local warnedAutoShot, warnedWingClip = false, false
HPL.movingIcons = false

------------------------------------------------------------------------------------------------
-- Shared icon frame
------------------------------------------------------------------------------------------------

local function CreateIcon(name, positionKey, defaultY, size)
  local f = CreateFrame("Button", name, UIParent)
  f:SetWidth(size)
  f:SetHeight(size)
  f:SetFrameStrata("MEDIUM")
  f:SetMovable(true)
  f:SetClampedToScreen(true)
  f:RegisterForDrag("LeftButton")

  local pos = HPL.db.settings[positionKey]
  if type(pos) == "table" and pos.point then
    f:SetPoint(pos.point, UIParent, pos.relPoint or pos.point, pos.x or 0, pos.y or 0)
  else
    f:SetPoint("CENTER", UIParent, "CENTER", 0, defaultY)
  end

  f:SetScript("OnDragStart", function()
    if HPL.movingIcons or IsShiftKeyDown() then this:StartMoving() end
  end)
  f:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
    local point, _, relPoint, x, y = this:GetPoint()
    HPL.db.settings[positionKey] = { point = point, relPoint = relPoint, x = x, y = y }
  end)

  f.icon = f:CreateTexture(nil, "ARTWORK")
  f.icon:SetAllPoints(f)

  f.glow = f:CreateTexture(nil, "OVERLAY")
  f.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
  f.glow:SetBlendMode("ADD")
  f.glow:SetWidth(size * 1.9)
  f.glow:SetHeight(size * 1.9)
  f.glow:SetPoint("CENTER", f, "CENTER", 0, 0)

  f.label = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  f.label:SetPoint("TOP", f, "BOTTOM", 0, -3)

  f:Hide()
  return f
end

local function SetColor(f, state)
  f.glow:SetVertexColor(state.r, state.g, state.b)
  f.label:SetTextColor(state.r, state.g, state.b)
end

------------------------------------------------------------------------------------------------
-- Range indicator
------------------------------------------------------------------------------------------------

local function ScanActionSlots()
  slotsDirty = false
  lastSlotScan = GetTime()
  slots.autoShot, slots.wingClip = nil, nil
  if not scanTip then
    scanTip = CreateFrame("GameTooltip", "PokeHuntLogScanTooltip", nil, "GameTooltipTemplate")
  end
  for slot = 1, 120 do
    if HasAction(slot) then
      scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
      scanTip:SetAction(slot)
      local line = getglobal("PokeHuntLogScanTooltipTextLeft1")
      local text = line and line:GetText()
      if text == AUTO_SHOT and not slots.autoShot then
        slots.autoShot = slot
      elseif text == WING_CLIP and not slots.wingClip then
        slots.wingClip = slot
      end
      scanTip:Hide()
    end
  end
  -- Only mention it when the slots actually changed, or the debug log fills with repeats.
  local result = tostring(slots.autoShot) .. "/" .. tostring(slots.wingClip)
  if result ~= lastSlotResult then
    lastSlotResult = result
    HPL.Debug("action bars: Auto Shot in slot " .. tostring(slots.autoShot) .. ", Wing Clip in slot " .. tostring(slots.wingClip))
  end
end

local function HasAttackableTarget()
  return UnitExists("target") and not UnitIsDead("target") and UnitCanAttack("player", "target")
end

local function RangeState()
  -- Rescanning reads 120 tooltips, so wait a second after the bars change.
  if slotsDirty and GetTime() - lastSlotScan > 1 then ScanActionSlots() end
  if slots.autoShot and IsActionInRange(slots.autoShot) == 1 then
    return "range"
  end
  if CheckInteractDistance("target", 3) then
    if slots.wingClip then
      if IsActionInRange(slots.wingClip) == 1 then return "melee" end
      return "deadzone"
    end
    return "close"
  end
  if slots.autoShot then
    return "far"
  end
  -- Auto Shot isn't on the action bars: follow distance (28 yards) is the closest guess.
  if CheckInteractDistance("target", 4) then return "range" end
  return "far"
end

local rangeElapsed = 0
local function RangeOnUpdate()
  rangeElapsed = rangeElapsed + arg1
  if rangeElapsed < 0.1 then return end
  rangeElapsed = 0
  if HPL.movingIcons then return end
  if not HasAttackableTarget() then
    rangeFrame:Hide()
    return
  end
  local state = RANGE_STATES[RangeState()]
  if not slots.autoShot and not warnedAutoShot then
    warnedAutoShot = true
    HPL.Print("the range icon needs |cffffffffAuto Shot|r on one of your action bars (any slot). Drag it from your spellbook. See /petlog help.")
  elseif slots.autoShot and not slots.wingClip and not warnedWingClip and (UnitLevel("player") or 0) >= 12 then
    warnedWingClip = true
    HPL.Print("put |cffffffffWing Clip|r on an action bar too, so the range icon can tell melee range from the dead zone.")
  end
  rangeFrame.label:SetText(state.text)
  SetColor(rangeFrame, state)
  local texture = slots.autoShot and GetActionTexture(slots.autoShot)
  rangeFrame.icon:SetTexture(texture or AUTO_SHOT_ICON)
  if state == RANGE_STATES.range then
    rangeFrame.icon:SetVertexColor(1, 1, 1)
  else
    rangeFrame.icon:SetVertexColor(0.5, 0.5, 0.5)
  end
end

local function UpdateRange()
  if not rangeFrame then return end
  local s = HPL.db.settings
  if HPL.movingIcons and s.rangeIcon then
    rangeFrame.icon:SetTexture(AUTO_SHOT_ICON)
    rangeFrame.icon:SetVertexColor(1, 1, 1)
    rangeFrame.label:SetText("Range icon (drag)")
    SetColor(rangeFrame, RANGE_STATES.range)
    rangeFrame:Show()
  elseif s.rangeIcon and HPL.IsHunter() and HasAttackableTarget() then
    rangeElapsed = 1
    rangeFrame:Show()
  else
    rangeFrame:Hide()
  end
end

------------------------------------------------------------------------------------------------
-- Feed reminder
------------------------------------------------------------------------------------------------

local function PetIsEating()
  for i = 1, 16 do
    local texture = UnitBuff("pet", i)
    if not texture then break end
    if texture == FEED_EFFECT_ICON then return true end
  end
  return false
end

local function UpdateFeed(fromEvent)
  if not feedFrame then return end
  local s = HPL.db.settings

  if HPL.movingIcons and s.feedReminder then
    local look = HAPPINESS[2]
    feedFrame.icon:SetTexCoord(look.coords[1], look.coords[2], look.coords[3], look.coords[4])
    feedFrame.label:SetText("Feed reminder (drag)")
    SetColor(feedFrame, look)
    feedFrame:Show()
    return
  end

  local _, isHunterPet = HasPetUI()
  if not s.feedReminder or not HPL.IsHunter() or not isHunterPet or not UnitExists("pet") or UnitIsDead("pet") then
    feedFrame:Hide()
    lastHappiness = nil
    return
  end

  local happiness = GetPetHappiness()
  local look = happiness and HAPPINESS[happiness]
  if not look then
    feedFrame:Hide()
    return
  end

  local remindAt = (s.feedWhen == "unhappy") and 1 or 2
  if happiness <= remindAt and not PetIsEating() then
    feedFrame.icon:SetTexCoord(look.coords[1], look.coords[2], look.coords[3], look.coords[4])
    feedFrame.label:SetText("Feed " .. (UnitName("pet") or "your pet") .. " (" .. look.text .. ")")
    SetColor(feedFrame, look)
    feedFrame:Show()
    if fromEvent and lastHappiness and happiness < lastHappiness then
      HPL.Debug("pet happiness dropped to " .. look.text)
      HPL.Print("|cffffd100" .. (UnitName("pet") or "Your pet") .. " is " .. string.lower(look.text) ..
        ". Time to feed it!|r")
      UIErrorsFrame:AddMessage((UnitName("pet") or "Your pet") .. " is " .. string.lower(look.text) .. " - feed your pet",
        look.r, look.g, look.b, 1.0, 3)
      if s.feedSound then pcall(PlaySound, "TellMessage") end
    end
  else
    feedFrame:Hide()
  end
  lastHappiness = happiness
end

------------------------------------------------------------------------------------------------
-- Setup
------------------------------------------------------------------------------------------------

function HPL.UpdateHunterTools()
  UpdateRange()
  UpdateFeed(false)
end

function HPL.ToggleMoveIcons()
  HPL.movingIcons = not HPL.movingIcons
  if rangeFrame then rangeFrame:EnableMouse(HPL.movingIcons) end
  if HPL.movingIcons then
    HPL.Print("icons unlocked: drag the range icon and feed reminder where you want them, then press Lock icons.")
  else
    HPL.Print("icons locked.")
  end
  HPL.UpdateHunterTools()
  if HPL.UpdateLockButtons then HPL.UpdateLockButtons() end
end

function HPL.InitHunterTools()
  -- Frames are created for every class (class info may not be ready this early) and only shown to hunters.
  rangeFrame = CreateIcon("PokeHuntLogRangeIcon", "rangePosition", -140, 36)
  rangeFrame.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  rangeFrame:EnableMouse(false)   -- don't block clicks in the middle of the screen
  rangeFrame:SetScript("OnUpdate", RangeOnUpdate)

  feedFrame = CreateIcon("PokeHuntLogFeedReminder", "feedPosition", 180, 40)
  feedFrame.icon:SetTexture(HAPPINESS_TEXTURE)
  feedFrame:EnableMouse(true)
  feedFrame:RegisterForClicks("LeftButtonUp")
  feedFrame:SetScript("OnClick", function()
    if HPL.movingIcons or IsShiftKeyDown() then return end
    if UnitAffectingCombat("player") then
      HPL.Print("you can't feed your pet in combat.")
    else
      CastSpellByName(FEED_PET)
    end
  end)
  feedFrame:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_BOTTOM")
    GameTooltip:SetText("Feed your pet")
    GameTooltip:AddLine("Click to cast Feed Pet, then click a food in your bags.", 1, 1, 1, 1)
    GameTooltip:AddLine("Shift-drag to move.", 0.7, 0.7, 0.7)
    GameTooltip:Show()
  end)
  feedFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)

  local f = CreateFrame("Frame")
  local events = { "PLAYER_TARGET_CHANGED", "ACTIONBAR_SLOT_CHANGED", "UNIT_HAPPINESS", "UNIT_PET", "UNIT_AURA",
    "PLAYER_ENTERING_WORLD", "UNIT_FACTION" }
  for i = 1, table.getn(events) do
    pcall(f.RegisterEvent, f, events[i])
  end
  f:SetScript("OnEvent", function()
    if event == "PLAYER_TARGET_CHANGED" or (event == "UNIT_FACTION" and arg1 == "target") then
      UpdateRange()
    elseif event == "ACTIONBAR_SLOT_CHANGED" then
      slotsDirty = true
    elseif event == "UNIT_HAPPINESS" then
      UpdateFeed(true)
    elseif event == "UNIT_AURA" then
      if arg1 == "pet" then UpdateFeed(false) end
    elseif event == "UNIT_PET" then
      if arg1 == "player" then
        lastHappiness = nil
        HPL.After(1, function() UpdateFeed(false) end)
      end
    elseif event == "PLAYER_ENTERING_WORLD" then
      slotsDirty = true
      HPL.After(2, function() HPL.UpdateHunterTools() end)
    end
  end)
end
