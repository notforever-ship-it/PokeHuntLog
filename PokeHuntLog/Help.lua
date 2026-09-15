-- PokeHuntLog: "How to use" window. Opens once on a hunter's first login, then with the Help button,
-- /petlog help, or Shift-clicking the minimap icon.

local HPL = PokeHuntLog

local GOLD = "|cffffd100"
local GREEN = "|cff40ff40"
local RED = "|cffff4040"
local ORANGE = "|cffff9933"
local GREY = "|cff9d9d9d"
local WHITE = "|cffffffff"
local END = "|r"

local HELP_TEXT = table.concat({
  GOLD .. "Pet log" .. END,
  "- Open it with the " .. WHITE .. "beast icon on your minimap" .. END .. " or " .. WHITE .. "/petlog" .. END .. ".",
  "- Tamed beasts are added automatically. Call each of your pets and visit a stable master once so the pets you already have are added too.",
  "- Tick " .. WHITE .. "Show uncaught" .. END .. " to see every skin and where to tame it.",
  "- A pet under " .. ORANGE .. "Pets with unknown skin" .. END .. ": click it, press " .. WHITE .. "Assign skin" .. END ..
    ", then click its skin in the list.",
  " ",
  GOLD .. "Range icon" .. END,
  "- " .. WHITE .. "Put Auto Shot and Wing Clip on your action bars." .. END .. " Any slot works, even a bar page you never show. " ..
    "Drag the real spells from your spellbook; macros don't count.",
  "- " .. GREEN .. "In range" .. END .. "   " .. RED .. "Dead zone" .. END .. "   " .. ORANGE .. "Melee" .. END .. "   " ..
    GREY .. "Out of range" .. END,
  "- Without Wing Clip (learned at level 12) it can only say " .. RED .. "Too close" .. END .. ".",
  " ",
  GOLD .. "Feed reminder" .. END,
  "- A happiness face pops up when your pet stops being happy. Click it to cast Feed Pet, then click a food in your bags.",
  " ",
  GOLD .. "Moving the icons" .. END,
  "- Press " .. WHITE .. "Unlock icons" .. END .. ", drag the range icon and the feed reminder, then press " ..
    WHITE .. "Lock icons" .. END .. ".",
  " ",
  GOLD .. "Commands" .. END,
  WHITE .. "/petlog" .. END .. " - open the log      " .. WHITE .. "/petlog help" .. END .. " - this window",
  WHITE .. "/petlog move" .. END .. " - unlock or lock the icons",
  WHITE .. "/petlog range" .. END .. ", " .. WHITE .. "/petlog feed" .. END .. " - turn the range icon or feed reminder on/off",
  WHITE .. "/petlog feed unhappy" .. END .. " - only remind when the pet is unhappy",
  WHITE .. "/petlog uncaught" .. END .. " - show or hide skins you haven't caught",
  WHITE .. "/petlog commands" .. END .. " - list every command in chat",
  WHITE .. "/petlog debug on" .. END .. " - show what the addon notices in chat (handy for bug reports)",
}, "\n")

local frame, lockButton

local function LockText()
  return HPL.movingIcons and "Lock icons" or "Unlock icons"
end

function HPL.UpdateLockButtons()
  if lockButton then lockButton:SetText(LockText()) end
  if HPL.UpdateLogLockButton then HPL.UpdateLogLockButton() end
end

local function CreateHelp()
  frame = CreateFrame("Frame", "PokeHuntLogHelpFrame", UIParent)
  frame:SetWidth(500)
  frame:SetHeight(560)
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
  frame:SetFrameStrata("DIALOG")
  frame:SetClampedToScreen(true)
  frame:EnableMouse(true)
  frame:SetMovable(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function() this:StartMoving() end)
  frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
  frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
  })
  frame:Hide()
  table.insert(UISpecialFrames, "PokeHuntLogHelpFrame")

  local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOP", frame, "TOP", 0, -20)
  title:SetText("PokeHuntLog - How to use")

  local close = CreateFrame("Button", "PokeHuntLogHelpCloseButton", frame, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
  close:SetScript("OnClick", function() frame:Hide() end)

  local text = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  text:SetPoint("TOPLEFT", frame, "TOPLEFT", 26, -52)
  text:SetWidth(448)
  text:SetHeight(450)
  text:SetJustifyH("LEFT")
  text:SetJustifyV("TOP")
  text:SetText(HELP_TEXT)

  lockButton = CreateFrame("Button", "PokeHuntLogHelpLockButton", frame, "UIPanelButtonTemplate")
  lockButton:SetWidth(120)
  lockButton:SetHeight(24)
  lockButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 24, 20)
  lockButton:SetScript("OnClick", function() HPL.ToggleMoveIcons() end)

  local ok = CreateFrame("Button", "PokeHuntLogHelpOkButton", frame, "UIPanelButtonTemplate")
  ok:SetWidth(120)
  ok:SetHeight(24)
  ok:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -24, 20)
  ok:SetText("Got it")
  ok:SetScript("OnClick", function() frame:Hide() end)

  local credit = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  credit:SetPoint("BOTTOM", frame, "BOTTOM", 0, 26)
  credit:SetText(GREY .. "Made by " .. END .. "|cffabd473stealthzi" .. END)
end

function HPL.ShowHelp()
  if not frame then CreateHelp() end
  lockButton:SetText(LockText())
  frame:Show()
end

function HPL.ToggleHelp()
  if frame and frame:IsShown() then
    frame:Hide()
  else
    HPL.ShowHelp()
  end
end

-- First login on a hunter: show the help once.
function HPL.MaybeShowFirstHelp()
  if HPL.db.settings.seenHelp or not HPL.IsHunter() then return end
  HPL.db.settings.seenHelp = true
  HPL.ShowHelp()
end
