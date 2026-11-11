local A, C = AlbinoUI, AlbinoUI.Compatibility
local T = { icons = {} }
A.Cooldowns = T
function T:Update()
    local settings = A.db.cooldowns
    for index, icon in ipairs(self.icons) do
        local spell = settings.spells[index]
        local name, texture, resolved
        if spell then name, texture, resolved = C:KnownSpell(spell) end
        icon.learned = name and true or false
        icon.spell = resolved
        local start, duration, enabled, rate = 0, 0, false, 1
        if name then start, duration, enabled, rate = C:SpellCooldown(resolved) end
        -- GCD-only spells don't bounce in and out of the tracker.
        if C:Number(duration, 0) <= 1.5 then start, duration = 0, 0 end
        icon.texture:SetTexture(texture)
        icon.start, icon.duration, icon.rate = C:Cooldown(icon.cooldown, start, duration, enabled, rate)
    end
    self:Tick(true)
end
function T:Tick(reflow)
    local settings, shown = A.db.cooldowns, 0
    local now = GetTime()
    for _, icon in ipairs(self.icons) do
        local remaining = C:Remaining(icon.start, icon.duration, now, icon.rate)
        local visible = icon.learned and (settings.showReady or remaining > 0) or false
        if icon.visible ~= visible then reflow = true end
        icon.visible = visible
        icon:SetShown(visible)
        icon.text:SetText(C:TimeText(remaining))
    end
    if not reflow then return end
    for _, icon in ipairs(self.icons) do
        if icon.visible then
            icon:ClearAllPoints(); icon:SetPoint("LEFT", self.frame, "LEFT", shown*(settings.size+settings.spacing), 0)
            icon:SetSize(settings.size, settings.size)
            shown = shown + 1
        end
    end
    self.frame:SetSize(math.max(settings.size, shown*(settings.size+settings.spacing)-settings.spacing), settings.size)
end
function T:Apply() self:Update() end
function T:Init()
    self.frame = A.Layout:New("cooldowns", "Cooldown tracker")
    for i = 1, 24 do
        local icon = CreateFrame("Frame", nil, self.frame)
        A.Layout:Background(icon)
        icon.texture = icon:CreateTexture(nil, "ARTWORK"); icon.texture:SetAllPoints()
        icon.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate"); icon.cooldown:SetAllPoints()
        if icon.cooldown.SetHideCountdownNumbers then icon.cooldown:SetHideCountdownNumbers(true) end
        local overlay = CreateFrame("Frame", nil, icon); overlay:SetAllPoints()
        overlay:SetFrameLevel(icon.cooldown:GetFrameLevel()+2)
        icon.text = A.Layout:Text(overlay, 13)
        icon:EnableMouse(true)
        icon:SetScript("OnEnter", function(self)
            if self.spell and GameTooltip then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                if GameTooltip.SetSpellByID then GameTooltip:SetSpellByID(self.spell) end
                GameTooltip:Show()
            end
        end)
        icon:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        self.icons[i] = icon
    end
    for _, event in ipairs({"SPELL_UPDATE_COOLDOWN", "SPELLS_CHANGED", "PLAYER_ENTERING_WORLD", "SPELL_UPDATE_CHARGES"}) do
        A:On(event, function() T:Update() end)
    end
    local elapsed = 0
    self.frame:SetScript("OnUpdate", function(_, dt)
        elapsed = elapsed + dt; if elapsed < 0.1 then return end
        elapsed = 0; T:Tick()
    end)
end
