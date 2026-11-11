local A = AlbinoUI
local L = { frames = {} }
A.Layout = L
local WHITE = "Interface\\Buttons\\WHITE8X8"
function L:Text(parent, size, point, x, y)
    local text = parent:CreateFontString(nil, "OVERLAY")
    text:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", size, "OUTLINE")
    text:SetPoint(point or "CENTER", parent, point or "CENTER", x or 0, y or 0)
    return text
end
function L:Background(frame, r, g, b, alpha)
    local t = frame:CreateTexture(nil, "BACKGROUND")
    t:SetAllPoints(); t:SetTexture(WHITE); t:SetVertexColor(r or 0.04, g or 0.04, b or 0.04, alpha or 0.65)
    return t
end
function L:Bar(parent, r, g, b)
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetStatusBarTexture(WHITE); bar:SetStatusBarColor(r, g, b)
    bar:SetMinMaxValues(0, 1); bar:SetValue(0)
    self:Background(bar)
    return bar
end
function L:New(key, label)
    local frame = CreateFrame("Frame", "AlbinoUI" .. key, UIParent)
    frame:SetMovable(true); frame:SetClampedToScreen(true)
    self.frames[key] = frame
    -- Sibling handle: never covers buttons or intercepts spell dragging.
    local handle = CreateFrame("Button", nil, UIParent)
    frame.handle = handle
    handle:SetHeight(16); handle:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 3)
    handle:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, 3)
    handle:SetFrameStrata("DIALOG"); handle:RegisterForDrag("LeftButton")
    self:Background(handle, 0.12, 0.18, 0.12, 0.8)
    self:Text(handle, 10):SetText(label)
    handle:SetScript("OnDragStart", function()
        if not A:InCombat() and not A.db.locked then frame:StartMoving() end
    end)
    handle:SetScript("OnDragStop", function()
        A:Defer("drag-" .. key, function()
            frame:StopMovingOrSizing(); L:Save(key)
        end)
    end)
    handle:Hide()
    return frame
end
function L:Save(key)
    local frame = self.frames[key]
    local x, y = frame:GetCenter()
    if not x or not y then return end
    local scale = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
    A.db.positions[key] = { x = x * scale - UIParent:GetWidth() / 2,
        y = y * scale - UIParent:GetHeight() / 2 }
end
function L:SetLocked(locked)
    if A:InCombat() then return end
    for key, frame in pairs(self.frames) do
        frame:StopMovingOrSizing()
        if locked and self.unlocked then self:Save(key) end
        frame.handle:SetShown(not locked)
    end
    self.unlocked = not locked
end
function L:Apply()
    if A:InCombat() then return end
    for key, frame in pairs(self.frames) do
        local pos = A.db.positions[key]
        frame:SetScale(A.db.scale)
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", pos.x / A.db.scale, pos.y / A.db.scale)
    end
end
function L:Init()
    A:On("PLAYER_REGEN_DISABLED", function()
        -- Handles are unprotected siblings, not ancestors of secure action buttons.
        for _, frame in pairs(L.frames) do frame.handle:Hide() end
    end)
    A:On("PLAYER_REGEN_ENABLED", function()
        A:Defer("handles", function() L:SetLocked(A.db.locked) end)
    end)
    A:On("PLAYER_LOGOUT", function()
        if not A:InCombat() then for key in pairs(L.frames) do L:Save(key) end end
    end)
end
