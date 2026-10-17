-- PaTiDungeon: instance status (name, type) and a hand-drawn map per instance. Display only; no secure frames.
-- Group and combat lines removed (owner 2026-10-17): PaTiGroup shows the people, WoW itself shows combat.
local addonName, ns = ...
local UI, L, Logic, Sketch = ns.UI, ns.UI.L, ns.Logic, ns.Sketch

local DB
local testMode = false

local PAD = UI.Spacing.MD
local WIDTH = Sketch.WIDTH + 2 * PAD
local TEXT_HEIGHT = 30 -- two text lines: instance name, type
local HEIGHT = UI.Sizes.HeaderHeight + UI.Spacing.SM + TEXT_HEIGHT + PAD
local MAP_HEIGHT = Sketch.HEIGHT + UI.Spacing.SM
local TEST_STATUS = { inInstance = true, typeKey = "TYPE_PARTY" }

-- Test mode: a short corridor into a room with a boss, read only (never saved).
local function testSketch()
    local sketch = {}
    for col = 3, 14 do sketch[Logic.CellIndex(col, 11)] = "floor" end
    for row = 6, 16 do
        for col = 15, 22 do sketch[Logic.CellIndex(col, row)] = "floor" end
    end
    sketch[Logic.CellIndex(3, 11)] = "exit"
    sketch[Logic.CellIndex(19, 8)] = "boss"
    sketch[Logic.CellIndex(21, 15)] = "loot"
    sketch[Logic.CellIndex(10, 11)] = "danger"
    return sketch
end
local TEST_SKETCH = testSketch()

local function say(key, ...)
    print("|cff68caffPaTiDungeon:|r " .. L[key]:format(...))
end

local function isSecret(value) return issecretvalue ~= nil and issecretvalue(value) == true end

local function addonVersion()
    local getMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    return getMetadata and getMetadata(addonName, "Version") or "?"
end

-- API adapter: raw values, normalised by Logic.Status (which checks for secret values first).
local function readStatus()
    local name, instanceType, _, _, _, _, _, instanceID = GetInstanceInfo()
    return Logic.Status({
        inInstance = IsInInstance(),
        name = name,
        instanceType = instanceType,
        instanceID = instanceID,
    }, isSecret)
end

-- The sketch of the current instance (created on first use), the example in test mode, nil outside an instance.
local function currentSketch()
    if testMode then return TEST_SKETCH end
    if not DB then return nil end
    local key = Logic.SketchKey(readStatus())
    if not key then return nil end
    DB.sketches[key] = DB.sketches[key] or {}
    return DB.sketches[key]
end

-- Window ---------------------------------------------------------------------------------------

local window = UI.CreateWindow("PaTiDungeonFrame", "PaTiDungeon", WIDTH, HEIGHT)
window:SetCombatMovable(true) -- no secure children: may be dragged in combat too (PaTiShared)
local body = window:CreateFontString(nil, "OVERLAY", UI.Fonts.Text)
body:SetPoint("TOPLEFT", PAD + 2, -UI.Sizes.HeaderHeight - UI.Spacing.SM)
body:SetPoint("TOPRIGHT", -PAD, -UI.Sizes.HeaderHeight - UI.Spacing.SM)
body:SetHeight(TEXT_HEIGHT)
body:SetJustifyH("LEFT")
body:SetJustifyV("TOP")

local map = Sketch.Create(window, {
    get = currentSketch,
    readOnly = function() return testMode end,
    emptyText = "MAP_NO_INSTANCE",
})
map:SetPoint("TOPLEFT", body, "BOTTOMLEFT", -2, -UI.Spacing.SM)

local function paint()
    if not DB then return end
    local status = testMode and TEST_STATUS or readStatus()
    local title
    if testMode then title = L.TEST_INSTANCE
    elseif status.inInstance then title = status.name or L.UNKNOWN_INSTANCE
    else title = L.NOT_IN_INSTANCE end
    local typeText = status.typeKey and L[status.typeKey] or status.rawType or "-"
    body:SetText(table.concat({
        title,
        L.TYPE:format(typeText),
    }, "\n"))
    if map:IsShown() then map:Refresh() end
end

local function applyLayout()
    body:SetShown(not DB.collapsed)
    map:SetShown(not DB.collapsed and DB.showMap)
    local height = HEIGHT + (DB.showMap and MAP_HEIGHT or 0)
    window:SetHeight(DB.collapsed and UI.Sizes.HeaderHeight or height)
    window:SetTestMode(testMode)
end

-- Settings -------------------------------------------------------------------------------------

local modal

local function buildSettings()
    modal = UI.CreateModal("PaTiDungeonSettings", function() return "PaTiDungeon " .. L.SETTINGS end, 380)
    local scales = {}
    for _, scale in ipairs(Logic.SCALES) do
        scales[#scales + 1] = { value = scale, text = function() return ("%d %%"):format(scale * 100 + 0.5) end }
    end
    modal:AddSection("GENERAL")
    modal:AddRow("LANGUAGE", UI.CreateLanguageDropdown(modal, DB, 170))
    modal:AddRow("SCALE", UI.CreateDropdown(modal, 170, {
        items = function() return scales end,
        get = function() return DB.scale end,
        set = function(scale) DB.scale = scale; window:SetScale(scale) end,
    }))
    modal:AddControls(UI.CreateCheckbox(modal, "LOCK_WINDOW", {
        get = function() return window:IsLocked() end,
        set = function(locked) window:SetLocked(locked) end,
    }))
    UI.AddWindowSettings(modal, window) -- panel opacity + snapping (PaTiShared)
    modal:Finish(function()
        Logic.RestoreDefaults(DB)
        window:ApplyTheme() -- Restore Defaults: theme back to default
        window:ApplyOpacity()
        UI.SetLanguage(DB.language)
        window:SetLocked(DB.locked)
        window:SetScale(DB.scale)
        applyLayout()
        paint()
    end)
end

local function openSettings()
    if not modal then buildSettings() end
    modal:Show()
end

-- Commands -------------------------------------------------------------------------------------

local function toggleTestMode()
    testMode = not testMode
    applyLayout()
    paint()
end

local function toggleCollapsed()
    DB.collapsed = not DB.collapsed
    applyLayout()
    paint()
end

local function toggleMap()
    DB.showMap = not DB.showMap
    applyLayout()
    paint()
end

local function setShown(shown, quiet) -- no secure frames: fine in combat
    window:SetShown(shown)
    if not shown and not quiet then say("HIDDEN_HINT") end
    return true
end

-- Optional PaTiSuite control panel: the same rules as the commands, without chat lines (false = not possible now).
window.suiteSetShown = function(shown) return setShown(shown, true) end

local function resetPosition()
    DB.point, DB.relativePoint, DB.x, DB.y = nil, nil, nil, nil
    window:Attach(DB, -330, 160)
end

local function count(entries)
    local total = 0
    for _ in pairs(entries or {}) do total = total + 1 end
    return total
end

local function printDebug()
    local version, build, _, interface = GetBuildInfo()
    local status = readStatus()
    print("|cff68caffPaTiDungeon Debug:|r")
    for _, line in ipairs({
        ("Addon %s %s · PaTiShared UI %s"):format(addonName, addonVersion(), tostring(UI.VERSION)),
        ("WoW %s (build %s, interface %s) · locale %s · UI language %s"):format(tostring(version), tostring(build),
            tostring(interface), GetLocale(), UI.GetLanguage()),
        ("In instance %s · type %s · test mode %s"):format(tostring(status.inInstance), tostring(status.rawType),
            testMode and "on" or "off"),
        ("Instance ID %s · map key %s · drawn cells %d · maps saved %d"):format(tostring(status.instanceID),
            tostring(Logic.SketchKey(status)), count(currentSketch()), count(DB.sketches)),
    }) do print("  " .. line) end
end

local COMMANDS = {
    [""] = function() setShown(not window:IsShown()) end,
    show = function() setShown(true) end,
    hide = function() setShown(false) end,
    test = toggleTestMode,
    lock = function() window:SetLocked(true) end,
    unlock = function() window:SetLocked(false) end,
    reset = resetPosition,
    settings = openSettings,
    debug = printDebug,
    version = function() say("VERSION", addonVersion()) end,
}

SLASH_PATIDUNGEON1 = "/patidungeon"
SLASH_PATIDUNGEON2 = "/pd"
SlashCmdList.PATIDUNGEON = function(message)
    local command = COMMANDS[(message or ""):match("^%s*(.-)%s*$"):lower()]
    if command and DB then command() else say("HELP") end
end

window:SetMenu(function()
    if not DB then return {} end
    return {
        { text = "SETTINGS", onClick = openSettings },
        { text = window:IsLocked() and "UNLOCK" or "LOCK", onClick = function() window:SetLocked(not window:IsLocked()) end },
        { text = "SHOW_MAP", checked = DB.showMap, onClick = toggleMap },
        { text = DB.collapsed and "EXPAND" or "COLLAPSE", onClick = toggleCollapsed },
        { text = "TEST_MODE", checked = testMode, onClick = toggleTestMode },
        { text = "HIDE", onClick = function() setShown(false) end },
    }
end)

-- Events (all rare: login, zone changes) — a full repaint is cheap here --------------------------

local events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA" }) do
    events:RegisterEvent(event)
end

events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        PaTiDungeonDB = Logic.Migrate(PaTiDungeonDB)
        DB = PaTiDungeonDB
        UI.SetLanguage(DB.language)
        window:Attach(DB, -330, 160)
        window:SetScale(DB.scale)
        applyLayout()
    end
    if not testMode then paint() end
end)
UI.OnLanguageChanged(paint)
UI.OnThemeChanged(paint) -- state colours follow the theme (static ones repaint themselves, UI.Paint)
