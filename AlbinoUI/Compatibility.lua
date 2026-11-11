local A = AlbinoUI
local C = {}
A.Compatibility = C

function C:Public(value)
    return not (issecretvalue and issecretvalue(value))
end
function C:Number(value, fallback)
    if self:Public(value) and type(value) == "number" then return value end
    return fallback
end
function C:Flag(value)
    return self:Public(value) and (value == true or value == 1)
end
function C:Remaining(start, duration, now, rate)
    start, duration = self:Number(start, 0), self:Number(duration, 0)
    rate = math.max(0.001, self:Number(rate, 1))
    if start <= 0 or duration <= 0 then return 0 end
    return math.max(0, start + duration / rate - now)
end
function C:TimeText(seconds)
    if seconds <= 0 then return "" end
    if seconds >= 60 then return string.format("%dm", math.ceil(seconds / 60)) end
    return tostring(math.ceil(seconds))
end
function C:Cooldown(widget, start, duration, enabled, rate)
    if not self:Public(start) or not self:Public(duration) or not self:Public(enabled) then
        widget:Hide(); return 0, 0, 1
    end
    start, duration = self:Number(start, 0), self:Number(duration, 0)
    rate = self:Number(rate, 1)
    if not self:Flag(enabled) then start, duration = 0, 0 end
    widget:SetCooldown(start, duration, rate)
    widget:SetShown(duration > 0)
    return start, duration, rate
end
function C:ActionCooldown(slot)
    if GetActionCooldown then return GetActionCooldown(slot) end
    if C_ActionBar and C_ActionBar.GetActionCooldown then
        local cd, duration, enabled, rate = C_ActionBar.GetActionCooldown(slot)
        if type(cd) == "table" then return cd.startTime, cd.duration, cd.isEnabled, cd.modRate end
        return cd, duration, enabled, rate
    end
    return 0, 0, false
end
function C:ActionTexture(slot)
    if GetActionTexture then return GetActionTexture(slot) end
    if C_ActionBar and C_ActionBar.GetActionTexture then return C_ActionBar.GetActionTexture(slot) end
end
function C:ActionUsable(slot)
    if IsUsableAction then return IsUsableAction(slot) end
    if C_ActionBar and C_ActionBar.IsUsableAction then return C_ActionBar.IsUsableAction(slot) end
    return true, false
end
function C:ActionRange(slot)
    if IsActionInRange then return IsActionInRange(slot) end
    if C_ActionBar and C_ActionBar.IsActionInRange then return C_ActionBar.IsActionInRange(slot) end
end
function C:SpellInfo(spell)
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spell)
        if info then return info.name, info.iconID, info.spellID end
    elseif GetSpellInfo then
        local name, _, icon, _, _, _, id = GetSpellInfo(spell)
        return name, icon, id
    end
end
function C:KnownSpell(spell)
    local name, icon, id = self:SpellInfo(spell)
    if not name then return end
    -- Name lookup resolves the learned rank on clients with ranked Rogue spells.
    local learnedName, learnedIcon, learnedID = self:SpellInfo(name)
    if learnedName then name, icon, id = learnedName, learnedIcon, learnedID or id end
    id = id or tonumber(spell)
    if id and IsPlayerSpell and not IsPlayerSpell(id) then return end
    if id and not IsPlayerSpell and IsSpellKnown and not IsSpellKnown(id) then return end
    return name, icon, id or spell
end
function C:SpellCooldown(spell)
    if C_Spell and C_Spell.GetSpellCooldown then
        local cd = C_Spell.GetSpellCooldown(spell)
        if cd then return cd.startTime, cd.duration, cd.isEnabled, cd.modRate end
    elseif GetSpellCooldown then return GetSpellCooldown(spell) end
    return 0, 0, false
end
function C:Energy()
    local power = (Enum and Enum.PowerType and Enum.PowerType.Energy) or 3
    if UnitPower and UnitPowerMax then return UnitPower("player", power), UnitPowerMax("player", power) end
    return nil, nil
end
function C:Combo()
    local power = (Enum and Enum.PowerType and Enum.PowerType.ComboPoints) or 4
    local reportedMax = UnitPowerMax and self:Number(UnitPowerMax("player", power))
    local maximum = reportedMax and reportedMax > 0 and reportedMax or 5
    local count
    -- Use a reported combo-power capability, not an unrelated spell API as a version test.
    if reportedMax and reportedMax > 0 and UnitPower then count = UnitPower("player", power)
    elseif GetComboPoints then count = GetComboPoints("player", "target")
    elseif UnitPower then count = UnitPower("player", power) end
    return self:Number(count, 0), math.min(10, maximum)
end
function C:Build()
    if GetBuildInfo then
        local version, build, _, interface = GetBuildInfo()
        return tostring(version) .. " (" .. tostring(build) .. "), interface " .. tostring(interface)
    end
    return "Build information unavailable"
end
function C:SecureAvailable()
    return type(RegisterStateDriver) == "function" and type(SetOverrideBindingClick) == "function"
        and type(ClearOverrideBindings) == "function" and type(GetBindingKey) == "function"
        and type(PickupAction) == "function" and type(PlaceAction) == "function"
end
