-- PaTiDungeon: saved settings and status normalisation, no WoW API calls (tested in tests/logic_spec.lua).
local _, ns = ...
local Logic = {}
ns.Logic = Logic

Logic.SCHEMA = 1
Logic.SCALES = { 0.8, 0.9, 1, 1.1, 1.25, 1.5 }

Logic.DEFAULTS = {
    opacity = 0.75, -- panel body opacity (PaTiShared window; 0.3–1)
    theme = "default", -- "default" | "woforever" | "dracula" (PaTiShared UI.THEMES; colours only)
    locked = false,
    collapsed = false,
    scale = 1,
    language = "auto",
    showMap = true,
}

-- Hand-drawn dungeon map (owner 2026-10-17). The client hides the player's position inside instances
-- (WOW_API_COMPAT), so nothing is recorded: the player paints cells on a grid, one sketch per instance.
-- A sketch is { [cell index] = value }; index = (row - 1) * COLS + col; value = "floor" or a mark.
Logic.SKETCH = { COLS = 30, ROWS = 22 }
Logic.MARKS = { boss = true, loot = true, danger = true, exit = true }
Logic.TOOLS = { "floor", "arrow", "boss", "loot", "danger", "exit", "erase" }
-- Arrows show the way you walked (owner 2026-10-17): "arrow0" (up) … "arrow7", clockwise in 45° steps.
Logic.ARROWS = 8

-- The direction 0-7 of an arrow cell, nil for anything else.
function Logic.ArrowDirection(value)
    local direction = type(value) == "string" and tonumber(value:match("^arrow(%d)$"))
    if direction and direction < Logic.ARROWS then return direction end
    return nil
end

-- A mark sits on a floor cell: boss, loot, danger, exit or an arrow.
function Logic.IsMark(value)
    return Logic.MARKS[value] == true or Logic.ArrowDirection(value) ~= nil
end

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
    -- Theme: one of the three PaTiShared themes; a typo or an old value falls back to the default look.
    if db.theme ~= "default" and db.theme ~= "woforever" and db.theme ~= "dracula" then db.theme = "default" end
    db.sketches = Logic.CleanSketches(db.sketches)
    db.schema = Logic.SCHEMA
    return db
end

-- "Restore Defaults": settings back, position and drawn maps kept (sketches are player data, not settings).
function Logic.RestoreDefaults(db)
    for key, value in pairs(Logic.DEFAULTS) do db[key] = value end
    return db
end

-- raw: { inInstance, name, instanceType, instanceID } straight from the API.
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
    }
    if status.name == "" then status.name = nil end
    local instanceType = readable(raw.instanceType, "string")
    status.typeKey = instanceType and Logic.TYPE_KEYS[instanceType]
    status.rawType = instanceType -- shown as-is when there is no locale key for it
    status.instanceID = readable(raw.instanceID, "number")
    return status
end

-- Which sketch belongs to this place: the instance ID (stable across languages), else the name; nil outside an
-- instance (nothing to draw on).
function Logic.SketchKey(status)
    if not status.inInstance then return nil end
    if status.instanceID and status.instanceID > 0 then return "id:" .. status.instanceID end
    if status.name then return "name:" .. status.name end
    return nil
end

function Logic.CellIndex(col, row)
    local size = Logic.SKETCH
    if col < 1 or row < 1 or col > size.COLS or row > size.ROWS then return nil end
    return (row - 1) * size.COLS + col
end

local function validCell(index, value)
    local size = Logic.SKETCH
    return type(index) == "number" and index >= 1 and index <= size.COLS * size.ROWS and index % 1 == 0
        and (value == "floor" or Logic.IsMark(value))
end

-- Saved sketches: keeps every valid cell of every sketch, drops anything a broken save could hold. Idempotent.
function Logic.CleanSketches(value)
    local clean = {}
    if type(value) ~= "table" then return clean end
    for key, sketch in pairs(value) do
        if type(key) == "string" and type(sketch) == "table" then
            local cells = {}
            for index, cell in pairs(sketch) do
                if validCell(index, cell) then cells[index] = cell end
            end
            clean[key] = cells
        end
    end
    return clean
end

-- One painted cell. "erase" empties it, "floor" paints it, a mark sets that mark (a marked cell counts as floor,
-- so dragging floor across it keeps the mark). "arrow" sets an arrow pointing up; on an arrow it turns it 45°
-- clockwise. Returns true when the cell changed (only then it is repainted).
function Logic.ApplyTool(sketch, index, tool)
    if not index then return false end
    local new
    if tool == "arrow" then
        local direction = Logic.ArrowDirection(sketch[index])
        new = "arrow" .. (direction and (direction + 1) % Logic.ARROWS or 0)
    elseif tool == "floor" or Logic.MARKS[tool] then
        new = tool
    elseif tool ~= "erase" then
        return false
    end
    if tool == "floor" and Logic.IsMark(sketch[index]) then return false end
    if sketch[index] == new then return false end
    sketch[index] = new
    return true
end
