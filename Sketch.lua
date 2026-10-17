-- PaTiDungeon: the hand-drawn dungeon map (owner 2026-10-17). The client gives addons no position inside an
-- instance (WOW_API_COMPAT), so nothing is recorded: the player paints cells, sets marks and erases. Plain frames
-- only (no secure children), so drawing is fine in combat. Data rules (cells, tools, saving) live in Logic.lua.
local _, ns = ...
local UI, Logic = ns.UI, ns.Logic

local Sketch = {}
ns.Sketch = Sketch

local CELL = 9 -- px per grid cell; one pixel of it stays free as the grid line
local TOOL_SIZE = UI.Sizes.ButtonHeight
local ICON_INSET = 4
local MARK_SIZE = CELL + 4 -- marks overlap their cell a little so the raid icons stay readable
local CLEAR_CONFIRM_SECONDS = 4
local FLOOR_ALPHA, EMPTY_ALPHA = 0.6, 0.45
local RAID_ICON = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_%d"
-- Blizzard raid target icons: skull, star, cross, triangle — every client has them.
local MARK_ICONS = { boss = 8, loot = 1, danger = 7, exit = 4 }
local TOOL_TIPS = { floor = "TOOL_FLOOR", boss = "TOOL_BOSS", loot = "TOOL_LOOT", danger = "TOOL_DANGER",
    exit = "TOOL_EXIT", erase = "TOOL_ERASE" }

local SIZE = Logic.SKETCH
Sketch.WIDTH = SIZE.COLS * CELL
Sketch.HEIGHT = TOOL_SIZE + UI.Spacing.SM + SIZE.ROWS * CELL

local function toolIcon(button, tool)
    if tool == "erase" then -- an × from two lines (the WoW font has no such glyph)
        for _, degrees in ipairs({ 45, -45 }) do UI.Paint(UI.Line(button, 12, degrees), "SetVertexColor", "Danger") end
        return
    end
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", ICON_INSET, -ICON_INSET)
    icon:SetPoint("BOTTOMRIGHT", -ICON_INSET, ICON_INSET)
    if tool == "floor" then
        icon:SetTexture(UI.WHITE)
        UI.Paint(icon, "SetVertexColor", "Accent", FLOOR_ALPHA)
    else
        icon:SetTexture(RAID_ICON:format(MARK_ICONS[tool]))
    end
end

-- options: get() → the current sketch table or nil (outside an instance), readOnly() → true in test mode,
-- emptyText = L key shown when there is nothing to draw on.
function Sketch.Create(parent, options)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(Sketch.WIDTH, Sketch.HEIGHT)
    local state = { tool = "floor" }
    local cells, marks = {}, {}

    -- Toolbar: one button per tool, the chosen one outlined in the accent colour; "Clear" on the right.
    local toolButtons = {}
    local function paintTools()
        for tool, button in pairs(toolButtons) do
            UI.Paint(button, "SetBackdropBorderColor", tool == state.tool and "Accent" or "Border")
        end
    end
    for index, tool in ipairs(Logic.TOOLS) do
        local button = CreateFrame("Button", nil, frame, "BackdropTemplate")
        button:SetSize(TOOL_SIZE, TOOL_SIZE)
        button:SetPoint("TOPLEFT", (index - 1) * (TOOL_SIZE + UI.Spacing.XS), 0)
        UI.ApplyBackdrop(button, "Panel", "Border")
        toolIcon(button, tool)
        UI.SetTooltip(button, TOOL_TIPS[tool])
        button:SetScript("OnClick", function() state.tool = tool; paintTools() end)
        toolButtons[tool] = button
    end
    paintTools()

    local canvas = CreateFrame("Frame", nil, frame)
    canvas:SetPoint("TOPLEFT", 0, -(TOOL_SIZE + UI.Spacing.SM))
    canvas:SetSize(Sketch.WIDTH, SIZE.ROWS * CELL)
    local background = canvas:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    UI.Paint(background, "SetColorTexture", "Background")
    local empty = canvas:CreateFontString(nil, "OVERLAY", UI.Fonts.Muted)
    empty:SetPoint("CENTER")
    empty:SetWidth(Sketch.WIDTH - 2 * UI.Spacing.LG)
    UI.BindText(empty, options.emptyText)

    local function paintCell(index)
        local sketch = options.get()
        local value = sketch and sketch[index]
        local r, g, b = UI.Color(value and "Accent" or "PanelHover")
        cells[index]:SetColorTexture(r, g, b, value and FLOOR_ALPHA or EMPTY_ALPHA)
        local mark = value and MARK_ICONS[value]
        if mark and not marks[index] then
            marks[index] = canvas:CreateTexture(nil, "ARTWORK")
            marks[index]:SetSize(MARK_SIZE, MARK_SIZE)
            marks[index]:SetPoint("CENTER", cells[index], "CENTER")
        end
        if marks[index] then
            marks[index]:SetShown(mark ~= nil)
            if mark then marks[index]:SetTexture(RAID_ICON:format(mark)) end
        end
    end

    -- Built on first need: 660 small textures, created once.
    local function ensureCells()
        if cells[1] then return end
        for row = 1, SIZE.ROWS do
            for col = 1, SIZE.COLS do
                local cell = canvas:CreateTexture(nil, "BORDER")
                cell:SetSize(CELL - 1, CELL - 1)
                cell:SetPoint("TOPLEFT", (col - 1) * CELL, -(row - 1) * CELL)
                cells[Logic.CellIndex(col, row)] = cell
            end
        end
    end

    function frame:Refresh()
        local sketch = options.get()
        empty:SetShown(sketch == nil)
        if not sketch then
            for _, cell in pairs(cells) do cell:Hide() end
            for _, mark in pairs(marks) do mark:Hide() end
            return
        end
        ensureCells()
        for index, cell in pairs(cells) do
            cell:Show()
            paintCell(index)
        end
    end
    UI.OnThemeChanged(function() if frame:IsVisible() then frame:Refresh() end end)

    local function cellUnderCursor()
        local left, top = canvas:GetLeft(), canvas:GetTop()
        if not left then return nil end
        local x, y = GetCursorPosition()
        local scale = canvas:GetEffectiveScale()
        return Logic.CellIndex(math.floor((x / scale - left) / CELL) + 1, math.floor((top - y / scale) / CELL) + 1)
    end

    local function paintAt(tool)
        local sketch = options.get()
        if not sketch or options.readOnly() then return end
        local index = cellUnderCursor()
        if Logic.ApplyTool(sketch, index, tool) then paintCell(index) end
    end

    -- Left = chosen tool, right = erase. Floor and erase follow the held mouse (OnUpdate only while the button is
    -- down); a mark is set once per click, so dragging never spreads skulls.
    local function stopDrag()
        state.dragTool = nil
        canvas:SetScript("OnUpdate", nil)
    end
    canvas:EnableMouse(true)
    canvas:SetScript("OnMouseDown", function(_, button)
        local tool = button == "RightButton" and "erase" or state.tool
        paintAt(tool)
        if tool == "floor" or tool == "erase" then
            state.dragTool = tool
            canvas:SetScript("OnUpdate", function() paintAt(state.dragTool) end)
        end
    end)
    canvas:SetScript("OnMouseUp", stopDrag)
    canvas:SetScript("OnHide", stopDrag)

    -- Clear needs a second click within a few seconds (one click = one action; no accidental loss of a map).
    local clear
    clear = UI.CreateButton(frame, "CLEAR_MAP", nil, function()
        local sketch = options.get()
        if not sketch or options.readOnly() then return end
        local now = GetTime()
        if state.clearAt and now - state.clearAt <= CLEAR_CONFIRM_SECONDS then
            state.clearAt = nil
            for index in pairs(sketch) do sketch[index] = nil end
            UI.BindText(clear.label, "CLEAR_MAP")
            frame:Refresh()
            return
        end
        state.clearAt = now
        UI.BindText(clear.label, "CLEAR_CONFIRM")
    end)
    clear:SetPoint("TOPRIGHT")
    clear:HookScript("OnLeave", function()
        state.clearAt = nil
        UI.BindText(clear.label, "CLEAR_MAP")
    end)
    UI.SetTooltip(clear, "CLEAR_MAP_TIP")

    return frame
end
