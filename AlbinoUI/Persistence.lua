local A = AlbinoUI
local P = {}
A.Persistence = P
P.defaults = {
    schema = 1, locked = true, scale = 1,
    bars = {
        { count = 12, size = 30, spacing = 3, visible = true, fade = false },
        { count = 12, size = 28, spacing = 3, visible = true, fade = false },
    },
    resources = { width = 393, healthHeight = 6, energyHeight = 7, gap = 3, numbers = false,
        comboHeight = 6, comboGap = 3, comboCount = 5, autoCombo = true },
    cooldowns = { size = 28, spacing = 4, showReady = true, spells = { 1766, 1784, 5277, 2983, 1856 } },
    swing = { visible = true, width = 393, height = 3, gap = 2 },
    positions = {
        primary = { x = 0, y = -195 }, secondary = { x = 0, y = -234 },
        resources = { x = 0, y = -140 }, cooldowns = { x = 0, y = -105 }, swing = { x = 0, y = -164 },
    },
}
local function copy(value)
    if type(value) ~= "table" then return value end
    local out = {}; for k, v in pairs(value) do out[k] = copy(v) end; return out
end
P.Copy = copy
local function merge(value, defaults)
    if type(value) ~= "table" then return copy(defaults) end
    for k, v in pairs(defaults) do
        if type(v) == "table" then value[k] = merge(value[k], v)
        elseif type(value[k]) ~= type(v) then value[k] = v end
    end
    return value
end
local function clamp(value, low, high, fallback)
    if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then return fallback end
    return math.max(low, math.min(high, value))
end
function P:Normalize(db)
    -- An intentionally empty spell list is valid; don't merge default array entries back in.
    local spells = type(db) == "table" and type(db.cooldowns) == "table" and copy(db.cooldowns.spells)
    db = merge(db, self.defaults)
    if type(spells) == "table" then db.cooldowns.spells = spells end
    db.schema = 1
    db.scale = clamp(db.scale, 0.5, 2, 1)
    for _, b in ipairs(db.bars) do
        b.count = math.floor(clamp(b.count, 1, 12, 12))
        b.size = clamp(b.size, 18, 64, 30); b.spacing = clamp(b.spacing, 0, 16, 3)
    end
    local r, d = db.resources, self.defaults.resources
    for key, bounds in pairs({ width = {100, 900}, healthHeight = {2, 30}, energyHeight = {2, 30},
        gap = {0, 16}, comboHeight = {2, 24}, comboGap = {0, 16}, comboCount = {1, 10} }) do
        r[key] = clamp(r[key], bounds[1], bounds[2], d[key])
    end
    r.comboCount = math.floor(r.comboCount)
    local c = db.cooldowns
    c.size = clamp(c.size, 18, 64, 28); c.spacing = clamp(c.spacing, 0, 16, 4)
    local clean = {}
    for _, spell in ipairs(c.spells) do
        if #clean >= 24 then break end
        if type(spell) == "number" and spell > 0 and spell < 10000000 then clean[#clean+1] = math.floor(spell) end
    end
    c.spells = clean
    db.swing.width = clamp(db.swing.width, 100, 900, 393)
    db.swing.height = clamp(db.swing.height, 2, 16, 3); db.swing.gap = clamp(db.swing.gap, 0, 16, 2)
    for key, pos in pairs(self.defaults.positions) do
        db.positions[key].x = clamp(db.positions[key].x, -10000, 10000, pos.x)
        db.positions[key].y = clamp(db.positions[key].y, -10000, 10000, pos.y)
    end
    return db
end
function P:Load()
    AlbinoUIDB = self:Normalize(AlbinoUIDB)
    A.db = AlbinoUIDB
end
