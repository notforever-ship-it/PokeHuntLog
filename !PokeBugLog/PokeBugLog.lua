-- PokeBugLog: saves Lua errors and addon log lines into saved variables, so they can be read from
-- WTF\Account\<account>\SavedVariables\!PokeBugLog.lua after a /reload or logout.
-- The "!" in the folder name makes it load before other addons, so it also catches their load errors.
-- Other addons log through PokeBugLog_Log(source, message).

local ADDON = "!PokeBugLog"
local MAX_ERRORS = 100
local MAX_LINES = 500
local MAX_SESSIONS = 10

-- Saved variables aren't loaded yet while addons load, so collect into this until they are.
local pending = { errors = {}, lines = {} }
local db = nil

local function Now()
  return date("%Y-%m-%d %H:%M:%S")
end

local function Store()
  return db or pending
end

local function Trim(list, max)
  while table.getn(list) > max do
    table.remove(list, 1)
  end
end

local function Stack()
  if type(debugstack) == "function" then
    local ok, stack = pcall(debugstack, 3)
    if ok then return stack end
  end
  return nil
end

local function AddError(message)
  message = tostring(message)
  local list = Store().errors
  for i = 1, table.getn(list) do
    local e = list[i]
    if e.message == message then
      e.count = (e.count or 1) + 1
      e.last = Now()
      return
    end
  end
  local zone = nil
  if type(GetRealZoneText) == "function" then zone = GetRealZoneText() end
  table.insert(list, { message = message, count = 1, first = Now(), last = Now(), zone = zone, stack = Stack() })
  Trim(list, MAX_ERRORS)
end

function PokeBugLog_Log(source, message)
  local list = Store().lines
  table.insert(list, Now() .. " [" .. tostring(source) .. "] " .. tostring(message))
  Trim(list, MAX_LINES)
end

-- Error handler: record, then pass on to the normal handler (the red error box).
local previousHandler = _ERRORMESSAGE
if type(geterrorhandler) == "function" then
  local ok, handler = pcall(geterrorhandler)
  if ok and type(handler) == "function" then previousHandler = handler end
end

local function ErrorHandler(message)
  pcall(AddError, message)
  if previousHandler then
    return previousHandler(message)
  end
end

if type(seterrorhandler) == "function" then
  seterrorhandler(ErrorHandler)
end

local function Init()
  if db then return end
  if type(PokeBugLogDB) ~= "table" then PokeBugLogDB = {} end
  db = PokeBugLogDB
  if type(db.errors) ~= "table" then db.errors = {} end
  if type(db.lines) ~= "table" then db.lines = {} end
  if type(db.sessions) ~= "table" then db.sessions = {} end
  for i = 1, table.getn(pending.errors) do
    table.insert(db.errors, pending.errors[i])
  end
  for i = 1, table.getn(pending.lines) do
    table.insert(db.lines, pending.lines[i])
  end
  Trim(db.errors, MAX_ERRORS)
  Trim(db.lines, MAX_LINES)
  pending = nil
end

local function RecordSession()
  local s = { start = Now() }
  s.character = (UnitName("player") or "?") .. " - " .. (GetRealmName() or "?")
  s.level = UnitLevel("player")
  local _, class = UnitClass("player")
  s.class = class
  s.zone = GetRealZoneText()
  s.superwow = SUPERWOW_VERSION and tostring(SUPERWOW_VERSION) or "no"
  if type(GetBuildInfo) == "function" then
    local ok, version, build = pcall(GetBuildInfo)
    if ok then s.client = tostring(version) .. " (" .. tostring(build) .. ")" end
  end
  local addons = {}
  if type(GetNumAddOns) == "function" then
    for i = 1, GetNumAddOns() do
      local name, _, _, enabled = GetAddOnInfo(i)
      if name and enabled then
        local version
        if type(GetAddOnMetadata) == "function" then
          local ok, v = pcall(GetAddOnMetadata, name, "Version")
          if ok then version = v end
        end
        table.insert(addons, name .. (version and (" " .. version) or ""))
      end
    end
  end
  s.addons = table.concat(addons, ", ")
  table.insert(db.sessions, s)
  Trim(db.sessions, MAX_SESSIONS)
  PokeBugLog_Log("session", "logged in: " .. s.character .. ", level " .. tostring(s.level) .. ", " .. tostring(s.zone))
end

local function Say(text)
  DEFAULT_CHAT_FRAME:AddMessage("|cffff9933PokeBugLog:|r " .. text)
end

local function Slash(msg)
  msg = msg or ""
  local _, _, cmd, rest = string.find(msg, "^%s*(%S*)%s*(.-)%s*$")
  cmd = string.lower(cmd or "")
  local store = Store()
  if cmd == "clear" then
    store.errors = {}
    store.lines = {}
    if db then db.sessions = {} end
    Say("cleared. Type /reload to save.")
  elseif cmd == "errors" then
    local n = table.getn(store.errors)
    if n == 0 then
      Say("no errors recorded.")
    end
    for i = math.max(1, n - 4), n do
      local e = store.errors[i]
      Say("x" .. e.count .. " " .. string.sub(e.message, 1, 200))
    end
  elseif cmd == "" or cmd == "help" then
    Say(table.getn(store.errors) .. " error(s) and " .. table.getn(store.lines) .. " log line(s) recorded.")
    Say("/bug <what happened> - add a note to the log")
    Say("/bug errors - show the last few errors")
    Say("/bug clear - empty the log")
    Say("Type /reload or log out to save it to the file.")
  else
    PokeBugLog_Log("note", msg)
    Say("noted. Type /reload to save it.")
  end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("VARIABLES_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
local sessionRecorded = false
frame:SetScript("OnEvent", function()
  if event == "ADDON_LOADED" and arg1 == ADDON then
    Init()
  elseif event == "VARIABLES_LOADED" then
    Init()
  elseif event == "PLAYER_ENTERING_WORLD" then
    Init()
    if not sessionRecorded then
      sessionRecorded = true
      RecordSession()
    end
  end
end)

SLASH_POKEBUGLOG1 = "/bug"
SLASH_POKEBUGLOG2 = "/pokebug"
SlashCmdList["POKEBUGLOG"] = Slash
