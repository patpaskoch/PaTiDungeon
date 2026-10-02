-- PaTiDungeon: saved settings and status normalisation, no WoW API calls (tested in tests/logic_spec.lua).
local _, ns = ...
local Logic = {}
ns.Logic = Logic

Logic.SCHEMA = 1
Logic.SCALES = { 0.8, 0.9, 1, 1.1, 1.25, 1.5 }

Logic.DEFAULTS = {
    opacity = 0.75, -- panel body opacity (PaTiShared window; 0.3–1)
    locked = false,
    collapsed = false,
    scale = 1,
    language = "auto",
}

-- Instance types GetInstanceInfo reports and the locale key that names them.
Logic.TYPE_KEYS = { none = "TYPE_NONE", party = "TYPE_PARTY", raid = "TYPE_RAID", pvp = "TYPE_PVP",
    arena = "TYPE_ARENA", scenario = "TYPE_SCENARIO" }

-- 0.1.0 saved x, y (CENTER offsets) and locked; they are kept as they are, so the window stays where it was.
function Logic.Migrate(db)
    if type(db) ~= "table" then db = {} end -- nil or a broken save (string, number …): start fresh
    for key, value in pairs(Logic.DEFAULTS) do
        if db[key] == nil then db[key] = value end
    end
    -- A broken scale would make SetScale fail on login: only a sane number is kept (saved values elsewhere stay).
    if type(db.scale) ~= "number" or db.scale < 0.5 or db.scale > 2 then db.scale = Logic.DEFAULTS.scale end
    db.schema = Logic.SCHEMA
    return db
end

-- "Restore Defaults": settings back, position kept.
function Logic.RestoreDefaults(db)
    for key, value in pairs(Logic.DEFAULTS) do db[key] = value end
    return db
end

-- raw: { inInstance, name, instanceType, members, inCombat, isLeader } straight from the API.
-- Returns plain, readable values; anything secret or of the wrong type becomes "unknown" (nil / 0 / false)
-- before it is compared (secret-value rule).
function Logic.Status(raw, isSecret)
    local function readable(value, kind)
        if isSecret(value) or type(value) ~= kind then return nil end
        return value
    end
    -- Flags: modern clients return true/false, older ones 1/nil — accept both (as 0.1.0 did).
    local function flag(value)
        if isSecret(value) then return false end
        return value == true or value == 1
    end
    local status = {
        inInstance = flag(raw.inInstance),
        name = readable(raw.name, "string"),
        typeKey = nil,
        members = readable(raw.members, "number") or 0,
        inCombat = flag(raw.inCombat),
        isLeader = flag(raw.isLeader),
    }
    if status.name == "" then status.name = nil end
    local instanceType = readable(raw.instanceType, "string")
    status.typeKey = instanceType and Logic.TYPE_KEYS[instanceType]
    status.rawType = instanceType -- shown as-is when there is no locale key for it
    return status
end
