-- PaTiDungeon settings and status. Run via PaTiAdmin/tools/check.sh.
local wow = require("wow_api")

local function load()
    return wow.loadAddonFile("Logic.lua", {}).Logic
end

local never = function() return false end

describe("Logic.Migrate", function()
    it("creates defaults and keeps the 0.1.0 position and lock", function()
        local db = load().Migrate({ x = -330, y = 160, locked = true })
        assert.equal(-330, db.x)
        assert.equal(160, db.y)
        assert.is_true(db.locked)
        assert.is_false(db.collapsed)
        assert.equal(1, db.schema)
    end)

    it("keeps saved false values", function()
        local db = load().Migrate({ schema = 1, locked = false, collapsed = false, scale = 1.1 })
        assert.is_false(db.locked)
        assert.equal(1.1, db.scale)
    end)
end)

describe("Logic.RestoreDefaults", function()
    it("keeps the position", function()
        local db = load().RestoreDefaults({ x = 1, collapsed = true })
        assert.equal(1, db.x)
        assert.is_false(db.collapsed)
    end)
end)

describe("Logic.Status", function()
    it("normalises a dungeon in a group", function()
        local status = load().Status({ inInstance = true, name = "Todesminen", instanceType = "party", members = 5,
            inCombat = false, isLeader = true }, never)
        assert.is_true(status.inInstance)
        assert.equal("Todesminen", status.name)
        assert.equal("TYPE_PARTY", status.typeKey)
        assert.equal(5, status.members)
        assert.is_false(status.inCombat)
        assert.is_true(status.isLeader)
    end)

    it("accepts 1/nil flags from older client APIs like 0.1.0 did", function()
        local status = load().Status({ inInstance = 1, inCombat = 1, isLeader = nil }, never)
        assert.is_true(status.inInstance)
        assert.is_true(status.inCombat)
        assert.is_false(status.isLeader)
    end)

    it("keeps an unknown instance type as raw text without a key", function()
        local status = load().Status({ inInstance = true, instanceType = "delve" }, never)
        assert.is_nil(status.typeKey)
        assert.equal("delve", status.rawType)
    end)

    it("turns secret, empty or missing values into unknown", function()
        local secret = {}
        local isSecret = function(value) return rawequal(value, secret) end
        local status = load().Status({ inInstance = secret, name = "", instanceType = secret, members = secret,
            inCombat = nil, isLeader = secret }, isSecret)
        assert.is_false(status.inInstance)
        assert.is_nil(status.name)
        assert.is_nil(status.typeKey)
        assert.equal(0, status.members)
        assert.is_false(status.inCombat)
        assert.is_false(status.isLeader)
    end)
end)

describe("Collapse state", function()
    it("a saved collapsed = true stays; Restore Defaults expands (documented) and keeps the position", function()
        local Logic = load()
        local db = Logic.Migrate({ x = 7, collapsed = true })
        assert.is_true(db.collapsed)
        Logic.RestoreDefaults(db)
        assert.is_false(db.collapsed)
        assert.equal(7, db.x)
    end)
end)

describe("Window settings (panel opacity)", function()
    it("old saves get 75 %; a saved value stays; Restore Defaults resets it; an old snapWindows is ignored", function()
        local M = load()
        local db = M.Migrate({ x = 12, y = 34 })
        assert.equal(0.75, db.opacity)
        assert.equal(12, db.x)
        db = M.Migrate({ opacity = 0.4, snapWindows = false })
        assert.equal(0.4, db.opacity)
        db = M.RestoreDefaults({ opacity = 0.4, snapWindows = false, bindings = {}, bindingRanks = {}, watch = {} })
        assert.equal(0.75, db.opacity)
    end)
end)
