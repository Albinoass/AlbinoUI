local A, C = AlbinoUI, AlbinoUI.Compatibility
local R = { segments = {} }
A.Resources = R
function R:UpdateBar(bar, current, maximum)
    current, maximum = C:Number(current), C:Number(maximum)
    if current and maximum and maximum > 0 then
        bar:SetMinMaxValues(0, maximum); bar:SetValue(current)
        bar.text:SetText(A.db.resources.numbers and string.format("%d / %d", current, maximum) or "")
    else
        bar:SetMinMaxValues(0, 1); bar:SetValue(0); bar.text:SetText(A.db.resources.numbers and "?" or "")
    end
end
function R:Update()
    self:UpdateBar(self.health, UnitHealth("player"), UnitHealthMax("player"))
    self:UpdateBar(self.energy, C:Energy())
    local count, maximum = C:Combo()
    if A.db.resources.autoCombo and maximum ~= self.maximum then
        self.maximum = maximum
        -- Resource frames have no protected descendants, so geometry can update in combat.
        self:Apply()
    end
    for i, segment in ipairs(self.segments) do
        segment.fill:SetShown(i <= count)
    end
end
function R:Apply()
    local r = A.db.resources
    local count = r.autoCombo and (self.maximum or 5) or r.comboCount
    self.frame:SetSize(r.width, r.healthHeight + r.energyHeight + r.comboHeight + 2*r.gap)
    self.health:ClearAllPoints(); self.health:SetPoint("TOPLEFT"); self.health:SetSize(r.width, r.healthHeight)
    self.energy:ClearAllPoints(); self.energy:SetPoint("TOPLEFT", self.health, "BOTTOMLEFT", 0, -r.gap)
    self.energy:SetSize(r.width, r.energyHeight)
    local width = (r.width - (count-1)*r.comboGap) / count
    for i, segment in ipairs(self.segments) do
        segment:ClearAllPoints(); segment:SetPoint("TOPLEFT", self.energy, "BOTTOMLEFT", (i-1)*(width+r.comboGap), -r.gap)
        segment:SetSize(width, r.comboHeight); segment:SetShown(i <= count)
    end
end
function R:Init()
    self.frame = A.Layout:New("resources", "Health / energy / combo points")
    self.health = A.Layout:Bar(self.frame, 0.2, 0.85, 0.3)
    self.energy = A.Layout:Bar(self.frame, 1, 0.85, 0.12)
    self.health.text = A.Layout:Text(self.health, 10)
    self.energy.text = A.Layout:Text(self.energy, 10)
    for i = 1, 10 do
        local segment = CreateFrame("Frame", nil, self.frame)
        A.Layout:Background(segment)
        segment.fill = A.Layout:Background(segment, 1, 0.68, 0.16, 1)
        segment.fill:SetDrawLayer("ARTWORK")
        self.segments[i] = segment
    end
    for _, event in ipairs({"PLAYER_ENTERING_WORLD", "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_POWER_UPDATE",
        "UNIT_POWER_FREQUENT", "UNIT_MAXPOWER", "UNIT_ENERGY", "UNIT_COMBO_POINTS", "PLAYER_COMBO_POINTS",
        "PLAYER_TARGET_CHANGED", "UPDATE_SHAPESHIFT_FORM"}) do
        A:On(event, function(_, unit)
            if not unit or unit == "player" or unit == "target" then R:Update() end
        end)
    end
    self:Update()
end
