-- PaTiDungeon: instance, group and combat status. Display only; no secure frames.
local addonName, ns = ...
local UI, L, Logic = ns.UI, ns.UI.L, ns.Logic

local DB
local testMode = false

local WIDTH, HEIGHT, PAD = 280, 132, UI.Spacing.MD
local TEST_STATUS = { inInstance = true, typeKey = "TYPE_PARTY", members = 5, inCombat = false, isLeader = true }

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
    local name, instanceType = GetInstanceInfo()
    return Logic.Status({
        inInstance = IsInInstance(),
        name = name,
        instanceType = instanceType,
        members = GetNumGroupMembers and GetNumGroupMembers() or 0,
        inCombat = UnitAffectingCombat("player"),
        isLeader = UnitIsGroupLeader("player"),
    }, isSecret)
end

-- Window ---------------------------------------------------------------------------------------

local window = UI.CreateWindow("PaTiDungeonFrame", "PaTiDungeon", WIDTH, HEIGHT)
window:SetCombatMovable(true) -- no secure children: may be dragged in combat too (PaTiShared)
local body = window:CreateFontString(nil, "OVERLAY", UI.Fonts.Text)
body:SetPoint("TOPLEFT", PAD + 2, -UI.Sizes.HeaderHeight - UI.Spacing.SM)
body:SetPoint("BOTTOMRIGHT", -PAD, PAD)
body:SetJustifyH("LEFT")
body:SetJustifyV("TOP")

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
        L.GROUP:format(status.members),
        L.COMBAT:format(status.inCombat and L.YES or L.NO),
        L.LEADER:format(status.isLeader and L.LEADER_YOU or L.LEADER_OTHER),
    }, "\n"))
end

local function applyLayout()
    body:SetShown(not DB.collapsed)
    window:SetHeight(DB.collapsed and UI.Sizes.HeaderHeight or HEIGHT)
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

local function printDebug()
    local version, build, _, interface = GetBuildInfo()
    local status = readStatus()
    print("|cff68caffPaTiDungeon Debug:|r")
    for _, line in ipairs({
        ("Addon %s %s · PaTiShared UI %s"):format(addonName, addonVersion(), tostring(UI.VERSION)),
        ("WoW %s (build %s, interface %s) · locale %s · UI language %s"):format(tostring(version), tostring(build),
            tostring(interface), GetLocale(), UI.GetLanguage()),
        ("In instance %s · type %s · members %d · combat %s · leader %s · test mode %s"):format(
            tostring(status.inInstance), tostring(status.rawType), status.members, tostring(status.inCombat),
            tostring(status.isLeader), testMode and "on" or "off"),
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
        { text = DB.collapsed and "EXPAND" or "COLLAPSE", onClick = toggleCollapsed },
        { text = "TEST_MODE", checked = testMode, onClick = toggleTestMode },
        { text = "HIDE", onClick = function() setShown(false) end },
    }
end)

-- Events (all rare: zone, group, combat start/end) — a full repaint is cheap here --------------

local events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE", "ZONE_CHANGED_NEW_AREA",
    "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" }) do
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
