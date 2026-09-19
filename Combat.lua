-- PokeHuntLog: swing timer bars for Auto Shot and melee, and an Arcane Shot ready icon.
--
-- Knowing when an attack happened:
--   * With SuperWoW, UNIT_CASTEVENT reports Auto Shot (spell 75) and every melee swing ("MAINHAND").
--   * Without it, an Auto Shot is an arrow leaving the quiver while Auto Shot is on and no special shot
--     (which uses ammo too) has just started the global cooldown. A melee swing is a "You hit / You miss /
--     You attack" combat line, or Raptor Strike, which takes the place of the next swing.
-- In 1.12 the last half second before an Auto Shot is the aim: moving then delays the shot, so the bar
-- marks that part in red.

local HPL = PokeHuntLog

local BOOK = "spell"
local AUTO_SHOT_ID = 75
local ARCANE_SHOT = "Arcane Shot"
local AIM_TIME = 0.5
local BAR_WIDTH, BAR_HEIGHT = 180, 14
-- Spells with no cooldown of their own: if one of these is cooling down, it's the global cooldown.
local GCD_PROBES = { "Serpent Sting", "Hunter's Mark" }

local swingFrame, rangedBar, meleeBar, arcaneFrame
local ranged = { start = 0, duration = 0 }
local melee = { start = 0, duration = 0 }
local autoRepeat = false
local ammoSlot, lastAmmo = nil, nil
local lastShot, lastSwing = 0, 0
local spellIndex = {}   -- [spell name] = spellbook index of its highest rank
local arcaneCost = nil
local scanTip

------------------------------------------------------------------------------------------------
-- Spellbook
------------------------------------------------------------------------------------------------

local function ScanSpellbook()
  spellIndex = {}
  local i = 1
  while i < 400 do
    local name = GetSpellName(i, BOOK)
    if not name then break end
    spellIndex[name] = i   -- ranks are listed lowest first, so the last one wins
    i = i + 1
  end

  -- Arcane Shot's mana cost is only in its tooltip ("25 Mana").
  arcaneCost = nil
  local idx = spellIndex[ARCANE_SHOT]
  if idx then
    if not scanTip then
      scanTip = CreateFrame("GameTooltip", "PokeHuntLogSpellTooltip", nil, "GameTooltipTemplate")
    end
    scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
    scanTip:SetSpell(idx, BOOK)
    local line = getglobal("PokeHuntLogSpellTooltipTextLeft2")
    local text = line and line:GetText()
    if text then
      local _, _, cost = string.find(text, "(%d+) Mana")
      arcaneCost = tonumber(cost)
    end
    scanTip:Hide()
  end
end

local function GlobalCooldownJustStarted()
  for i = 1, table.getn(GCD_PROBES) do
    local idx = spellIndex[GCD_PROBES[i]]
    if idx then
      local start, duration = GetSpellCooldown(idx, BOOK)
      return start and start > 0 and duration and duration <= 1.6 and GetTime() - start < 0.5
    end
  end
  return false
end

------------------------------------------------------------------------------------------------
-- Swing timer
------------------------------------------------------------------------------------------------

local function ShotFired()
  local now = GetTime()
  if now - lastShot < 0.4 then return end
  lastShot = now
  ranged.start = now
  ranged.duration = UnitRangedDamage("player") or 0
  if ranged.duration > 0 then
    rangedBar.aim:SetWidth(BAR_WIDTH * math.min(AIM_TIME / ranged.duration, 1))
  end
end

local function Swing()
  local now = GetTime()
  if now - lastSwing < 0.2 then return end
  lastSwing = now
  melee.start = now
  melee.duration = UnitAttackSpeed("player") or 0
end

local function CreateBar(name, label, anchor, y)
  local bar = CreateFrame("StatusBar", name, swingFrame)
  bar:SetWidth(BAR_WIDTH)
  bar:SetHeight(BAR_HEIGHT)
  bar:SetPoint("TOP", anchor, "TOP", 0, y)
  bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  bar:SetMinMaxValues(0, 1)
  bar:SetValue(0)

  bar.bg = bar:CreateTexture(nil, "BACKGROUND")
  bar.bg:SetAllPoints(bar)
  bar.bg:SetTexture(0, 0, 0, 0.55)

  bar.label = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  bar.label:SetPoint("LEFT", bar, "LEFT", 4, 0)
  bar.label:SetText(label)

  bar.time = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  bar.time:SetPoint("RIGHT", bar, "RIGHT", -4, 0)

  bar:Hide()
  return bar
end

local function UpdateRanged(now)
  if ranged.duration <= 0 then
    rangedBar:Hide()
    return
  end
  local left = ranged.start + ranged.duration - now
  if left <= 0 and not autoRepeat then
    rangedBar:Hide()
    return
  end
  rangedBar:SetValue(1 - math.max(left, 0) / ranged.duration)
  if left > AIM_TIME then
    rangedBar:SetStatusBarColor(1, 0.82, 0)
    rangedBar.time:SetText(string.format("%.1f", left))
  elseif left > 0 then
    rangedBar:SetStatusBarColor(1, 0.25, 0.25)
    rangedBar.time:SetText("hold still")
  else
    -- Overdue: out of range, moving, or Auto Shot was just turned back on.
    rangedBar:SetStatusBarColor(0.3, 1, 0.3)
    rangedBar.time:SetText("ready")
  end
  rangedBar.aim:Show()
  rangedBar:Show()
end

local function UpdateMelee(now)
  if melee.duration <= 0 then
    meleeBar:Hide()
    return
  end
  local left = melee.start + melee.duration - now
  -- No swing for a while means you're out of melee: get out of the way.
  if left < -1.5 then
    meleeBar:Hide()
    return
  end
  meleeBar:SetValue(1 - math.max(left, 0) / melee.duration)
  if left > 0 then
    meleeBar:SetStatusBarColor(0.85, 0.85, 0.85)
    meleeBar.time:SetText(string.format("%.1f", left))
  else
    meleeBar:SetStatusBarColor(0.3, 1, 0.3)
    meleeBar.time:SetText("ready")
  end
  meleeBar:Show()
end

------------------------------------------------------------------------------------------------
-- Arcane Shot icon
------------------------------------------------------------------------------------------------

local function ArcaneState(r, g, b, text)
  arcaneFrame.glow:SetVertexColor(r, g, b)
  arcaneFrame.label:SetTextColor(r, g, b)
  arcaneFrame.label:SetText(text)
end

local function UpdateArcane()
  local idx = spellIndex[ARCANE_SHOT]
  if not HPL.db.settings.arcaneReady or not idx or not HPL.IsHunter() or
    not (HPL.HasAttackableTarget and HPL.HasAttackableTarget()) then
    arcaneFrame:Hide()
    return
  end
  arcaneFrame.icon:SetTexture(GetSpellTexture(idx, BOOK))
  local start, duration = GetSpellCooldown(idx, BOOK)
  local left = 0
  if start and start > 0 and duration then left = start + duration - GetTime() end
  local inRange = HPL.AutoShotInRange and HPL.AutoShotInRange()

  if left > 0 then
    arcaneFrame.icon:SetVertexColor(0.4, 0.4, 0.4)
    -- The global cooldown shows too, but a countdown for it would only flicker.
    if duration > 1.6 then
      arcaneFrame.count:SetText(tostring(math.ceil(left)))
    else
      arcaneFrame.count:SetText("")
    end
    ArcaneState(0.6, 0.6, 0.6, "Arcane")
  elseif arcaneCost and (UnitMana("player") or 0) < arcaneCost then
    arcaneFrame.icon:SetVertexColor(0.35, 0.35, 1)
    arcaneFrame.count:SetText("")
    ArcaneState(0.4, 0.5, 1, "no mana")
  elseif inRange == false then
    arcaneFrame.icon:SetVertexColor(0.5, 0.5, 0.5)
    arcaneFrame.count:SetText("")
    ArcaneState(1, 0.25, 0.25, "out of range")
  else
    arcaneFrame.icon:SetVertexColor(1, 1, 1)
    arcaneFrame.count:SetText("")
    ArcaneState(0.3, 1, 0.3, "READY")
  end
  arcaneFrame:Show()
end

------------------------------------------------------------------------------------------------
-- Driver
------------------------------------------------------------------------------------------------

local elapsed = 0
local function OnUpdate()
  if not HPL.db or HPL.movingIcons then return end
  local s = HPL.db.settings

  -- The quiver is checked every frame, so two quick shots can't slip through between looks.
  if s.swingTimer and autoRepeat and ammoSlot and not SUPERWOW_VERSION then
    local count = GetInventoryItemCount("player", ammoSlot)
    if lastAmmo and count and count < lastAmmo and not GlobalCooldownJustStarted() then
      ShotFired()
    end
    lastAmmo = count
  end

  elapsed = elapsed + arg1
  if elapsed < 0.05 then return end
  elapsed = 0

  if s.swingTimer and HPL.IsHunter() then
    local now = GetTime()
    UpdateRanged(now)
    UpdateMelee(now)
  else
    rangedBar:Hide()
    meleeBar:Hide()
  end
  UpdateArcane()
end

-- Called whenever a setting or the icon lock changes.
function HPL.UpdateCombatTools()
  if not swingFrame then return end
  local s = HPL.db.settings
  local moving = HPL.movingIcons
  swingFrame:EnableMouse(moving and s.swingTimer)
  arcaneFrame:EnableMouse(moving and s.arcaneReady)

  if moving and s.swingTimer then
    rangedBar:SetValue(0.7)
    rangedBar:SetStatusBarColor(1, 0.82, 0)
    rangedBar.time:SetText("drag me")
    rangedBar.aim:SetWidth(BAR_WIDTH * 0.2)
    rangedBar.aim:Show()
    rangedBar:Show()
    meleeBar:SetValue(0.4)
    meleeBar:SetStatusBarColor(0.85, 0.85, 0.85)
    meleeBar.time:SetText("")
    meleeBar:Show()
  elseif moving then
    rangedBar:Hide()
    meleeBar:Hide()
  end

  if moving and s.arcaneReady then
    arcaneFrame.icon:SetTexture("Interface\\Icons\\Ability_ImpalingBolt")
    arcaneFrame.icon:SetVertexColor(1, 1, 1)
    arcaneFrame.count:SetText("")
    ArcaneState(0.3, 1, 0.3, "Arcane Shot (drag)")
    arcaneFrame:Show()
  elseif moving then
    arcaneFrame:Hide()
  end
  -- When not moving, OnUpdate takes over on the next frame.
end

local function CombatLine(text)
  if not text then return end
  if string.find(text, "^You hit ") or string.find(text, "^You crit ") or
    string.find(text, "^You miss ") or string.find(text, "^You attack") then
    Swing()
  end
end

function HPL.InitCombat()
  swingFrame = CreateFrame("Frame", "PokeHuntLogSwingTimer", UIParent)
  swingFrame:SetWidth(BAR_WIDTH)
  swingFrame:SetHeight(BAR_HEIGHT * 2 + 4)
  swingFrame:SetFrameStrata("MEDIUM")
  HPL.MakeDraggable(swingFrame, "swingPosition", -200)
  swingFrame:EnableMouse(false)   -- don't block clicks in the middle of the screen

  rangedBar = CreateBar("PokeHuntLogAutoShotBar", "Auto Shot", swingFrame, 0)
  -- The aim: the last half second before the shot, when moving delays it.
  rangedBar.aim = rangedBar:CreateTexture(nil, "OVERLAY")
  rangedBar.aim:SetTexture(1, 0.1, 0.1, 0.35)
  rangedBar.aim:SetPoint("TOPRIGHT", rangedBar, "TOPRIGHT", 0, 0)
  rangedBar.aim:SetPoint("BOTTOMRIGHT", rangedBar, "BOTTOMRIGHT", 0, 0)
  rangedBar.aim:SetWidth(BAR_WIDTH * 0.2)
  meleeBar = CreateBar("PokeHuntLogMeleeBar", "Melee", swingFrame, -(BAR_HEIGHT + 4))

  arcaneFrame = HPL.CreateIcon("PokeHuntLogArcaneIcon", "arcanePosition", -140, 32)
  arcaneFrame.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  arcaneFrame:EnableMouse(false)
  arcaneFrame.count = arcaneFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  arcaneFrame.count:SetPoint("CENTER", arcaneFrame, "CENTER", 0, 0)
  arcaneFrame.count:SetTextColor(1, 1, 1)
  -- Beside the range icon rather than on top of it, until the player moves either.
  if not HPL.db.settings.arcanePosition then
    arcaneFrame:ClearAllPoints()
    arcaneFrame:SetPoint("CENTER", UIParent, "CENTER", 44, -140)
  end

  local driver = CreateFrame("Frame")
  driver:SetScript("OnUpdate", OnUpdate)

  local f = CreateFrame("Frame")
  local events = { "START_AUTOREPEAT_SPELL", "STOP_AUTOREPEAT_SPELL", "SPELLS_CHANGED", "LEARNED_SPELL_IN_TAB",
    "PLAYER_ENTERING_WORLD", "CHAT_MSG_SPELL_SELF_DAMAGE" }
  if SUPERWOW_VERSION then
    table.insert(events, "UNIT_CASTEVENT")
  else
    table.insert(events, "CHAT_MSG_COMBAT_SELF_HITS")
    table.insert(events, "CHAT_MSG_COMBAT_SELF_MISSES")
  end
  for i = 1, table.getn(events) do
    pcall(f.RegisterEvent, f, events[i])
  end

  f:SetScript("OnEvent", function()
    if event == "UNIT_CASTEVENT" then
      -- arg1 caster guid, arg3 "START"/"CAST"/"FAIL"/"CHANNEL"/"MAINHAND"/"OFFHAND", arg4 spell id
      if arg1 == HPL.UnitGuid("player") then
        if arg3 == "MAINHAND" then
          Swing()
        elseif arg3 == "CAST" and arg4 == AUTO_SHOT_ID then
          ShotFired()
        end
      end
    elseif event == "CHAT_MSG_COMBAT_SELF_HITS" or event == "CHAT_MSG_COMBAT_SELF_MISSES" then
      CombatLine(arg1)
    elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
      -- Raptor Strike takes the place of the next swing, hit or miss.
      if arg1 and string.find(arg1, "^Your Raptor Strike") then Swing() end
    elseif event == "START_AUTOREPEAT_SPELL" then
      autoRepeat = true
      if not ammoSlot then
        local ok, slot = pcall(GetInventorySlotInfo, "AmmoSlot")
        ammoSlot = ok and slot or 0
      end
      lastAmmo = GetInventoryItemCount("player", ammoSlot)
    elseif event == "STOP_AUTOREPEAT_SPELL" then
      autoRepeat = false
    else
      -- spellbook changed, or just logged in
      ScanSpellbook()
    end
  end)
end
